import 'package:urbasign/data/models/signalement.dart';
import 'package:urbasign/data/models/signalement_filtre.dart';
import 'package:urbasign/data/services/api_exception.dart';
import 'package:urbasign/data/services/jeton_annulation.dart';
import 'package:urbasign/data/services/signalement_service.dart';

/// Point d'accès unique aux signalements pour le reste de l'app.
///
/// Ce qu'il ajoute par rapport au service :
/// 1. **Cache** de la liste complète ("Tout") pendant [dureeCache].
/// 2. **Mode hors ligne** : sans réseau, on renvoie les dernières données
///    reçues (filtrées localement) au lieu d'un écran d'erreur.
/// 3. **Anti-doublon** : si deux écrans demandent la liste complète en même
///    temps, une seule requête part sur le réseau.
///
/// Ce repository vit pendant toute la durée de l'app (pas de cycle de vie) :
/// c'est ce qui permet au cache de survivre quand on change d'écran.
///
/// ⚠️ Les listes renvoyées sont NON modifiables : pour les trier,
/// faire une copie d'abord (`[...liste]..sort(...)`).
class SignalementRepository {
  SignalementRepository(this._service);

  final SignalementService _service;

  /// Durée pendant laquelle la liste complète est considérée "fraîche".
  static const Duration dureeCache = Duration(minutes: 2);

  List<Signalement> _cacheComplet = const [];
  DateTime? _dateCache; // null = rien n'a encore été chargé
  Future<List<Signalement>>? _chargementEnCours;

  bool get _cacheEstFrais =>
      _dateCache != null && DateTime.now().difference(_dateCache!) < dureeCache;

  /// Dernière liste complète reçue (vide si rien n'a été chargé).
  List<Signalement> get signalementsEnCache => _cacheComplet;

  /// Signalements filtrés.
  /// - Filtre vide ("Tout") → liste complète, avec cache.
  /// - Sinon → l'API filtre (comme demandé par le sujet).
  /// - [forcerRafraichissement] → ignore le cache ("tirer pour rafraîchir").
  /// - [annulation] → ne s'applique qu'aux requêtes FILTRÉES : la liste
  ///   complète est partagée entre plusieurs écrans, un écran qui se ferme
  ///   ne doit pas l'annuler pour les autres.
  Future<List<Signalement>> getSignalements({
    SignalementFiltre filtre = SignalementFiltre.vide,
    bool forcerRafraichissement = false,
    JetonAnnulation? annulation,
  }) async {
    if (filtre.estVide) return _getListeComplete(forcerRafraichissement);

    try {
      return await _service.recupererSignalements(
        filtre: filtre,
        annulation: annulation,
      );
    } on ApiException catch (erreur) {
      // Pas de réseau mais on a déjà des données → on filtre localement.
      // (Une annulation n'est PAS un problème réseau : elle remonte telle quelle.)
      if (erreur.estProblemeReseau && _dateCache != null) {
        return List.unmodifiable(_cacheComplet.where(filtre.correspond));
      }
      rethrow;
    }
  }

  /// Détail d'un signalement (toujours à jour depuis l'API).
  Future<Signalement> getSignalement(
    int id, {
    JetonAnnulation? annulation,
  }) async {
    try {
      final signalement = await _service.recupererSignalement(
        id,
        annulation: annulation,
      );
      _remplacerDansCache(signalement);
      return signalement;
    } on ApiException catch (erreur) {
      if (erreur.estProblemeReseau) {
        final local = trouverDansCache(id);
        if (local != null) return local;
      }
      if (erreur.type == TypeErreurApi.introuvable) _retirerDuCache(id);
      rethrow;
    }
  }

  /// Cherche un signalement déjà reçu, sans appel réseau.
  /// Permet d'afficher le détail INSTANTANÉMENT, puis de le rafraîchir.
  Signalement? trouverDansCache(int id) {
    for (final signalement in _cacheComplet) {
      if (signalement.id == id) return signalement;
    }
    return null;
  }

  /// Oublie tout (le prochain appel repartira de l'API).
  void viderCache() {
    _cacheComplet = const [];
    _dateCache = null;
  }

  // ---------- Fonctions internes ----------

  Future<List<Signalement>> _getListeComplete(bool forcer) {
    if (!forcer && _cacheEstFrais) return Future.value(_cacheComplet);
    // `??=` : si un chargement est déjà en cours, on réutilise le même.
    return _chargementEnCours ??= _chargerListeComplete().whenComplete(
      () => _chargementEnCours = null,
    );
  }

  Future<List<Signalement>> _chargerListeComplete() async {
    try {
      final liste = await _service.recupererSignalements();
      _cacheComplet = List.unmodifiable(liste);
      _dateCache = DateTime.now();
      return _cacheComplet;
    } on ApiException catch (erreur) {
      if (erreur.estProblemeReseau && _dateCache != null) return _cacheComplet;
      rethrow;
    }
  }

  void _remplacerDansCache(Signalement nouveau) {
    if (_dateCache == null) return;
    _cacheComplet = List.unmodifiable([
      for (final ancien in _cacheComplet)
        ancien.id == nouveau.id ? nouveau : ancien,
    ]);
  }

  void _retirerDuCache(int id) {
    _cacheComplet = List.unmodifiable(_cacheComplet.where((s) => s.id != id));
  }
}

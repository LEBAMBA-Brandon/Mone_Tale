import 'dart:async';

import 'package:tala/data/models/nouveau_signalement.dart';
import 'package:tala/data/models/signalement.dart';
import 'package:tala/data/models/signalement_filtre.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/jeton_annulation.dart';
import 'package:tala/data/services/preferences_formulaire_service.dart';
import 'package:tala/data/services/signalement_service.dart';

/// Point d'accès unique aux signalements pour le reste de l'app.
///
/// Il gère DEUX listes en cache :
/// - "Mes signalements" (collecteur) ;
/// - "Tous les signalements" (admin).
///
/// Ce qu'il ajoute par rapport au service :
/// 1. **Cache** pendant [dureeCache] (pas de requête à chaque retour sur l'écran).
/// 2. **Mode hors ligne** : sans réseau, on renvoie les dernières données reçues.
/// 3. **Mise à jour locale** : après une création, un changement de statut
///    ou une suppression, les listes en cache sont corrigées tout de suite,
///    sans tout recharger.
/// 4. **Vérification** du formulaire AVANT l'envoi.
///
/// ⚠️ Les listes renvoyées sont NON modifiables : pour les trier,
/// faire une copie d'abord (`[...liste]..sort(...)`).
class SignalementRepository {
  SignalementRepository(this._service, this._preferences);

  final SignalementService _service;
  final PreferencesFormulaireService _preferences;

  /// Durée pendant laquelle une liste est considérée "fraîche".
  static const Duration dureeCache = Duration(minutes: 2);

  // "Mes signalements"
  List<Signalement> _mesSignalements = const [];
  DateTime? _dateMes; // null = jamais chargé

  // "Tous les signalements" (admin)
  List<Signalement> _tous = const [];
  DateTime? _dateTous;
  Future<List<Signalement>>? _chargementTous;

  static bool _estFrais(DateTime? date) =>
      date != null && DateTime.now().difference(date) < dureeCache;

  // =====================================================================
  //  COLLECTEUR
  // =====================================================================

  /// Signalements du collecteur connecté (les plus récents d'abord).
  Future<List<Signalement>> getMesSignalements({
    bool forcerRafraichissement = false,
    JetonAnnulation? annulation,
  }) async {
    if (!forcerRafraichissement && _estFrais(_dateMes)) return _mesSignalements;
    try {
      final liste = await _service.recupererMesSignalements(
        annulation: annulation,
      );
      _mesSignalements = List.unmodifiable(liste);
      _dateMes = DateTime.now();
      return _mesSignalements;
    } on ApiException catch (erreur) {
      // Pas de réseau mais déjà des données → on les garde à l'écran.
      if (erreur.estProblemeReseau && _dateMes != null) return _mesSignalements;
      rethrow;
    }
  }

  /// Envoie un nouveau signalement (photo comprise).
  ///
  /// - Formulaire incomplet → [ApiException] de type validation, SANS
  ///   appel réseau (les messages sont dans `erreursChamps`).
  /// - [progression] : de 0.0 à 1.0 pendant l'envoi de la photo.
  Future<Signalement> creerSignalement(
    NouveauSignalement nouveau, {
    void Function(double progression)? progression,
    JetonAnnulation? annulation,
  }) async {
    final erreurs = nouveau.valider();
    if (erreurs.isNotEmpty) throw ApiException.validationLocale(erreurs);

    final cree = await _service.creerSignalement(
      nouveau,
      progression: progression,
      annulation: annulation,
    );

    // Le nouveau signalement apparaît tout de suite en tête des listes.
    if (_dateMes != null) {
      _mesSignalements = List.unmodifiable([cree, ..._mesSignalements]);
    }
    if (_dateTous != null) _tous = List.unmodifiable([cree, ..._tous]);

    // On retient le quartier pour pré-remplir le prochain formulaire.
    unawaited(_preferences.enregistrerDernierQuartierId(nouveau.quartier!.id));
    return cree;
  }

  // =====================================================================
  //  ADMIN
  // =====================================================================

  /// Tous les signalements (écran "Signalements" de l'admin).
  /// - Filtre vide → liste complète, avec cache.
  /// - Sinon → l'API filtre (catégorie, statut…).
  Future<List<Signalement>> getSignalements({
    SignalementFiltre filtre = SignalementFiltre.vide,
    bool forcerRafraichissement = false,
    JetonAnnulation? annulation,
  }) async {
    if (filtre.estVide) return _getTous(forcerRafraichissement);

    try {
      return await _service.recupererSignalements(
        filtre: filtre,
        annulation: annulation,
      );
    } on ApiException catch (erreur) {
      // Pas de réseau mais on a la liste complète → on filtre localement.
      if (erreur.estProblemeReseau && _dateTous != null) {
        return List.unmodifiable(_tous.where(filtre.correspond));
      }
      rethrow;
    }
  }

  /// Signalements d'UN collecteur (page détail "collecteur" de l'admin).
  ///
  /// L'API n'a pas de filtre "auteur" sur `GET /signalements` : on prend
  /// la liste complète (déjà en cache la plupart du temps) et on trie ici.
  Future<List<Signalement>> getSignalementsDuCollecteur(
    int collecteurId, {
    bool forcerRafraichissement = false,
  }) async {
    final tous = await _getTous(forcerRafraichissement);
    return List.unmodifiable(tous.where((s) => s.auteurId == collecteurId));
  }

  /// Nombre de signalements par collecteur : `{ idCollecteur: nombre }`.
  /// Sert à afficher le compteur sur l'icône de chaque collecteur.
  Future<Map<int, int>> compterParAuteur({
    bool forcerRafraichissement = false,
  }) async {
    final tous = await _getTous(forcerRafraichissement);
    final compteurs = <int, int>{};
    for (final signalement in tous) {
      final auteurId = signalement.auteurId;
      if (auteurId == null) continue;
      // `update` : +1 si la clé existe, sinon on la crée à 1.
      compteurs.update(auteurId, (n) => n + 1, ifAbsent: () => 1);
    }
    return compteurs;
  }

  /// Change le statut (Signalé → En cours → Résolu).
  Future<Signalement> changerStatut(Signalement signalement, Statut statut) async {
    if (signalement.statut == statut) return signalement; // rien à faire
    final misAJour = await _service.changerStatut(signalement.id, statut);
    _remplacerDansCaches(misAJour);
    return misAJour;
  }

  /// Supprime un signalement (et sa photo côté serveur).
  Future<void> supprimerSignalement(int id) async {
    await _service.supprimerSignalement(id);
    _retirerDesCaches(id);
  }

  // =====================================================================
  //  COMMUN
  // =====================================================================

  /// Détail d'un signalement, toujours à jour depuis l'API.
  /// Sans réseau : la version en cache, si on l'a.
  Future<Signalement> getSignalement(
    int id, {
    JetonAnnulation? annulation,
  }) async {
    try {
      final signalement = await _service.recupererSignalement(
        id,
        annulation: annulation,
      );
      _remplacerDansCaches(signalement);
      return signalement;
    } on ApiException catch (erreur) {
      if (erreur.estProblemeReseau) {
        final local = trouverDansCache(id);
        if (local != null) return local;
      }
      if (erreur.type == TypeErreurApi.introuvable) _retirerDesCaches(id);
      rethrow;
    }
  }

  /// Cherche un signalement déjà reçu, sans appel réseau.
  /// Permet d'afficher le détail INSTANTANÉMENT, puis de le rafraîchir.
  Signalement? trouverDansCache(int id) {
    for (final signalement in [..._mesSignalements, ..._tous]) {
      if (signalement.id == id) return signalement;
    }
    return null;
  }

  /// Oublie tout. Appelé à la déconnexion (via AuthRepository) : le
  /// collecteur suivant ne doit pas voir les signalements du précédent.
  void viderCache() {
    _mesSignalements = const [];
    _dateMes = null;
    _tous = const [];
    _dateTous = null;
  }

  // ---------- Fonctions internes ----------

  Future<List<Signalement>> _getTous(bool forcer) {
    if (!forcer && _estFrais(_dateTous)) return Future.value(_tous);
    // `??=` : si un chargement est déjà en cours, on réutilise le même
    // (l'écran Signalements et le compteur des collecteurs peuvent
    // demander la liste en même temps : une seule requête part).
    return _chargementTous ??= _chargerTous().whenComplete(
      () => _chargementTous = null,
    );
  }

  Future<List<Signalement>> _chargerTous() async {
    try {
      final liste = await _service.recupererSignalements();
      _tous = List.unmodifiable(liste);
      _dateTous = DateTime.now();
      return _tous;
    } on ApiException catch (erreur) {
      if (erreur.estProblemeReseau && _dateTous != null) return _tous;
      rethrow;
    }
  }

  void _remplacerDansCaches(Signalement nouveau) {
    List<Signalement> remplacer(List<Signalement> liste) => List.unmodifiable([
      for (final ancien in liste) ancien.id == nouveau.id ? nouveau : ancien,
    ]);
    _mesSignalements = remplacer(_mesSignalements);
    _tous = remplacer(_tous);
  }

  void _retirerDesCaches(int id) {
    _mesSignalements = List.unmodifiable(
      _mesSignalements.where((s) => s.id != id),
    );
    _tous = List.unmodifiable(_tous.where((s) => s.id != id));
  }
}

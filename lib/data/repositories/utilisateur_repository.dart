import 'package:tala/data/models/nouveau_collecteur.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/repositories/signalement_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/utilisateur_service.dart';

/// Gestion des collecteurs par l'admin : liste, ajout, suppression.
///
/// Chaque collecteur renvoyé a son [Utilisateur.nombreSignalements]
/// (le compteur affiché sur son icône) :
/// - si l'API l'envoie (`signalements_count`), on le prend tel quel ;
/// - sinon, on le calcule à partir de la liste des signalements.
class UtilisateurRepository {
  UtilisateurRepository(this._service, this._signalements);

  final UtilisateurService _service;
  final SignalementRepository _signalements;

  static const Duration dureeCache = Duration(minutes: 2);

  List<Utilisateur> _collecteurs = const [];
  DateTime? _date;

  bool get _cacheEstFrais =>
      _date != null && DateTime.now().difference(_date!) < dureeCache;

  /// Les collecteurs (sans les admins), triés par nom, avec leur compteur.
  Future<List<Utilisateur>> getCollecteurs({
    bool forcerRafraichissement = false,
  }) async {
    if (!forcerRafraichissement && _cacheEstFrais) return _collecteurs;

    try {
      final utilisateurs = await _service.recupererUtilisateurs();
      var collecteurs = utilisateurs.where((u) => u.estCollecteur).toList();
      collecteurs = await _completerCompteurs(
        collecteurs,
        forcerRafraichissement,
      );
      collecteurs.sort(_parNom);
      _collecteurs = List.unmodifiable(collecteurs);
      _date = DateTime.now();
      return _collecteurs;
    } on ApiException catch (erreur) {
      if (erreur.estProblemeReseau && _date != null) return _collecteurs;
      rethrow;
    }
  }

  /// Un collecteur précis (page détail). D'abord le cache, sinon l'API.
  Future<Utilisateur> getCollecteur(int id) async {
    for (final collecteur in _collecteurs) {
      if (collecteur.id == id) return collecteur;
    }
    return _service.recupererUtilisateur(id);
  }

  /// Formulaire "Ajouter un collecteur".
  /// - Formulaire invalide → [ApiException] validation, sans appel réseau.
  /// - E-mail déjà utilisé → [ApiException] 422 (`erreurPourChamp('email')`).
  Future<Utilisateur> ajouterCollecteur(NouveauCollecteur nouveau) async {
    final erreurs = nouveau.valider();
    if (erreurs.isNotEmpty) throw ApiException.validationLocale(erreurs);

    // Un nouveau collecteur n'a encore aucun signalement.
    final cree = (await _service.creerCollecteur(
      nouveau,
    )).copyWith(nombreSignalements: 0);

    if (_date != null) {
      final liste = <Utilisateur>[..._collecteurs, cree]..sort(_parNom);
      _collecteurs = List.unmodifiable(liste);
    }
    return cree;
  }

  /// Supprime un collecteur.
  /// L'API refuse (409) s'il a déjà des signalements : le message du
  /// serveur ("Cet utilisateur a des signalements…") est dans l'erreur.
  Future<void> supprimerCollecteur(int id) async {
    await _service.supprimerUtilisateur(id);
    _collecteurs = List.unmodifiable(_collecteurs.where((u) => u.id != id));
  }

  /// Oublie tout (appelé à la déconnexion).
  void viderCache() {
    _collecteurs = const [];
    _date = null;
  }

  // ---------- Fonctions internes ----------

  /// Ajoute le nombre de signalements à ceux qui ne l'ont pas.
  Future<List<Utilisateur>> _completerCompteurs(
    List<Utilisateur> collecteurs,
    bool forcer,
  ) async {
    if (collecteurs.every((u) => u.nombreSignalements != null)) {
      return collecteurs; // l'API a déjà tout envoyé
    }
    try {
      final compteurs = await _signalements.compterParAuteur(
        forcerRafraichissement: forcer,
      );
      return [
        for (final u in collecteurs)
          u.nombreSignalements != null
              ? u
              : u.copyWith(nombreSignalements: compteurs[u.id] ?? 0),
      ];
    } on ApiException {
      // Compteur indisponible : on affiche quand même la liste (sans nombre).
      return collecteurs;
    }
  }

  static int _parNom(Utilisateur a, Utilisateur b) =>
      a.nomEtPrenom.toLowerCase().compareTo(b.nomEtPrenom.toLowerCase());
}

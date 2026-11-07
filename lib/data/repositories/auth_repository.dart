import 'dart:async';

import 'package:tala/data/models/modification_compte.dart';
import 'package:tala/data/models/nouveau_collecteur.dart';
import 'package:tala/data/models/session.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/services/api_client.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/auth_service.dart';
import 'package:tala/data/services/preferences_formulaire_service.dart';
import 'package:tala/data/services/session_service.dart';
import 'package:tala/data/services/utilisateur_service.dart';

/// Tout ce qui concerne l'utilisateur CONNECTÉ : connexion, déconnexion,
/// profil, "Mon compte".
///
/// C'est la seule classe qui sait si quelqu'un est connecté. Elle garde la
/// session à 3 endroits, toujours synchronisés :
/// 1. en mémoire ([session]) → lecture instantanée ;
/// 2. dans ApiClient (le token) → ajouté à chaque requête ;
/// 3. dans le téléphone (SessionService) → retrouvée au prochain lancement.
///
/// Elle vit pendant toute la durée de l'app (`Get.put(..., permanent: true)`
/// au J2).
class AuthRepository {
  AuthRepository({
    required this._service,
    required this._utilisateurService,
    required this._client,
    required this._sessionService,
    required this._preferences,
  }) {
    // Au démarrage : on reprend la session enregistrée (lecture SYNCHRONE).
    _session = _sessionService.lireSession();
    _client.definirJeton(_session?.token);
    // Si le serveur répond 401 un jour, ApiClient nous préviendra.
    _client.surSessionExpiree = _gererSessionExpiree;
  }

  final AuthService _service;
  final UtilisateurService _utilisateurService;
  final ApiClient _client;
  final SessionService _sessionService;
  final PreferencesFormulaireService _preferences;

  Session? _session;
  bool _deconnexionEnCours = false;

  /// Fonctions à appeler quand l'utilisateur change (ex : vider les caches
  /// des autres repositories, pour qu'un collecteur ne voie jamais les
  /// données du précédent sur le même téléphone).
  final List<void Function()> _nettoyages = [];

  /// Appelé quand la session expire TOUTE SEULE (token supprimé côté
  /// serveur…). Au J2, on y branchera : "retour à l'écran de connexion".
  void Function()? surDeconnexionForcee;

  // ---------- État ----------

  Session? get session => _session;
  Utilisateur? get utilisateur => _session?.utilisateur;
  bool get estConnecte => _session != null;
  bool get estAdmin => utilisateur?.estAdmin ?? false;

  /// Enregistre une fonction de nettoyage (appelée à chaque déconnexion
  /// et avant chaque nouvelle connexion).
  void ajouterNettoyage(void Function() nettoyage) => _nettoyages.add(nettoyage);

  // ---------- Connexion / déconnexion ----------

  /// Connecte l'utilisateur et renvoie son profil.
  /// Erreurs possibles ([ApiException]) :
  /// - validation (422 ou locale) : e-mail vide ou mal écrit…
  /// - nonAuthentifie (401) : "Email ou mot de passe incorrect."
  /// - pasDeConnexion / delaiDepasse : réseau.
  Future<Utilisateur> connecter({
    required String email,
    required String motDePasse,
  }) async {
    final emailPropre = email.trim().toLowerCase();
    final erreurs = {
      if (ReglesCompte.verifierEmail(emailPropre) case final erreur?)
        'email': erreur,
      if (motDePasse.isEmpty) 'password': 'Mot de passe obligatoire.',
    };
    if (erreurs.isNotEmpty) throw ApiException.validationLocale(erreurs);

    final session = await _service.connexion(
      email: emailPropre,
      motDePasse: motDePasse,
    );

    _nettoyer(); // un autre utilisateur était peut-être connecté avant
    _session = session;
    _client.definirJeton(session.token);
    await _sessionService.enregistrerSession(session);
    unawaited(_preferences.enregistrerDernierEmail(emailPropre));
    return session.utilisateur;
  }

  /// Déconnecte l'utilisateur.
  /// Même SANS réseau, la déconnexion locale a lieu : on ne bloque jamais
  /// quelqu'un qui veut se déconnecter.
  Future<void> deconnecter() async {
    _deconnexionEnCours = true;
    try {
      if (_client.aUnJeton) await _service.deconnexion();
    } on ApiException {
      // Pas de réseau ou token déjà expiré : tant pis pour le serveur,
      // le token sera inutilisable de toute façon une fois oublié ici.
    } finally {
      await _fermerSession();
      _deconnexionEnCours = false;
    }
  }

  /// Dernier e-mail utilisé (pré-remplit l'écran de connexion).
  Future<String?> lireDernierEmail() => _preferences.lireDernierEmail();

  // ---------- Profil ----------

  /// Recharge le profil depuis l'API (`/auth/me`).
  /// Sert aussi à vérifier, au démarrage, que le token est encore valable.
  Future<Utilisateur> rafraichirProfil() async {
    final profil = await _service.recupererProfil();
    await _mettreAJourUtilisateur(profil);
    return profil;
  }

  /// "Mon compte" : modifie nom, prénom, e-mail ou mot de passe.
  ///
  /// ⚠️ La route `PATCH /users/{id}` est réservée à l'admin dans l'API :
  /// un collecteur ne peut PAS modifier son compte lui-même. On le bloque
  /// ici avec un message clair, au lieu d'une erreur 403 obscure.
  Future<Utilisateur> modifierMonCompte(ModificationCompte modification) async {
    final actuel = utilisateur;
    if (actuel == null) {
      throw const ApiException(
        type: TypeErreurApi.nonAuthentifie,
        message: "Vous n'êtes pas connecté.",
      );
    }
    if (!actuel.estAdmin) {
      throw const ApiException.actionInterdite(
        'Seul un administrateur peut modifier un compte. '
        'Contactez votre administrateur.',
      );
    }
    if (modification.estVide) return actuel; // rien à envoyer

    final erreurs = modification.valider();
    if (erreurs.isNotEmpty) throw ApiException.validationLocale(erreurs);

    final modifie = await _utilisateurService.modifierUtilisateur(
      actuel.id,
      modification,
    );
    await _mettreAJourUtilisateur(modifie);
    if (modification.email != null) {
      unawaited(_preferences.enregistrerDernierEmail(modifie.email));
    }
    return modifie;
  }

  // ---------- Fonctions internes ----------

  Future<void> _mettreAJourUtilisateur(Utilisateur nouveau) async {
    final session = _session;
    if (session == null) return;
    final miseAJour = session.avecUtilisateur(nouveau);
    _session = miseAJour;
    await _sessionService.enregistrerSession(miseAJour);
  }

  /// Le serveur a répondu 401 sur une route protégée.
  void _gererSessionExpiree() {
    // Déjà déconnecté, ou déconnexion volontaire en cours : rien à faire.
    if (_session == null || _deconnexionEnCours) return;
    unawaited(_fermerSession());
    surDeconnexionForcee?.call();
  }

  Future<void> _fermerSession() async {
    _session = null;
    _client.definirJeton(null);
    _nettoyer();
    await _sessionService.effacerSession();
  }

  void _nettoyer() {
    for (final nettoyage in _nettoyages) {
      nettoyage();
    }
  }
}

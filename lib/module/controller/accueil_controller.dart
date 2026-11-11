import 'dart:async';

import 'package:get/get.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/repositories/auth_repository.dart';
import 'package:tala/data/services/api_exception.dart';

/// Controller de l'écran d'accueil : il ne gère QUE la barre de navigation
/// (quel onglet est affiché). Chaque onglet a son propre controller.
///
/// Onglets :
/// - collecteur : 0 Mes signalements · 1 Ajouter · 2 Profil
/// - admin      : 0 Signalements · 1 Ajouter un collecteur · 2 Collecteurs · 3 Profil
///
/// Cycle de vie :
/// - onReady → vérifie en arrière-plan que la session est toujours valable
///             et met le profil à jour (si l'admin a changé un nom…)
class AccueilController extends GetxController {
  AccueilController(this._auth);

  final AuthRepository _auth;

  // Numéros des onglets (évite les "nombres magiques" dans le code).
  static const int ongletListe = 0; // Mes signalements / Signalements
  static const int ongletAjout = 1; // Ajouter / Ajouter un collecteur
  static const int ongletCollecteurs = 2; // admin seulement
  int get ongletProfil => estAdmin ? 3 : 2;

  /// Onglet affiché.
  final onglet = ongletListe.obs;

  /// Onglets déjà ouverts au moins une fois. Un onglet n'est construit
  /// (et son controller créé) qu'à sa PREMIÈRE ouverture : l'app démarre
  /// plus vite et on ne demande pas le GPS avant d'ouvrir "Ajouter".
  final ongletsOuverts = <int>{ongletListe}.obs;

  Utilisateur? get utilisateur => _auth.utilisateur;
  bool get estAdmin => _auth.estAdmin;

  @override
  void onReady() {
    super.onReady();
    unawaited(_verifierSession());
  }

  void changerOnglet(int index) {
    ongletsOuverts.add(index);
    onglet.value = index;
  }

  Future<void> _verifierSession() async {
    try {
      await _auth.rafraichirProfil();
    } on ApiException {
      // Pas de réseau : on continue avec le profil enregistré.
      // Token expiré (401) : ApiClient a déjà prévenu AuthRepository,
      // qui renvoie vers l'écran de connexion.
    }
  }
}

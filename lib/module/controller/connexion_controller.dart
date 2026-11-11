import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:tala/data/repositories/auth_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Controller de l'écran de connexion (e-mail + mot de passe).
///
/// Cycle de vie :
/// - onInit  → crée les champs, pré-remplit le dernier e-mail utilisé
/// - onClose → libère les champs
class ConnexionController extends GetxController {
  ConnexionController(this._auth);

  final AuthRepository _auth;

  late final TextEditingController champEmail;
  late final TextEditingController champMotDePasse;
  late final FocusNode focusMotDePasse;

  final chargement = false.obs;

  /// Erreurs par champ ("email", "password") → affichées sous les champs.
  final erreurs = <String, String>{}.obs;

  /// Erreur générale (mauvais identifiants, pas de réseau…)
  /// → affichée dans un encadré rouge au-dessus du bouton.
  final erreurGenerale = RxnString();

  @override
  void onInit() {
    super.onInit();
    champEmail = TextEditingController();
    champMotDePasse = TextEditingController();
    focusMotDePasse = FocusNode();
    unawaited(_preremplirEmail());
  }

  @override
  void onClose() {
    champEmail.dispose();
    champMotDePasse.dispose();
    focusMotDePasse.dispose();
    super.onClose();
  }

  /// Dès qu'on retape dans un champ, son erreur disparaît.
  void effacerErreur(String champ) {
    erreurs.remove(champ);
    erreurGenerale.value = null;
  }

  /// Touche "Suivant" du clavier sur l'e-mail → on passe au mot de passe.
  void allerAuMotDePasse() => focusMotDePasse.requestFocus();

  Future<void> seConnecter() async {
    if (chargement.value) return; // évite les doubles appuis
    FocusManager.instance.primaryFocus?.unfocus(); // ferme le clavier
    erreurs.clear();
    erreurGenerale.value = null;
    chargement.value = true;

    try {
      await _auth.connecter(
        email: champEmail.text,
        motDePasse: champMotDePasse.text,
      );
      // `offAllNamed` : on vide l'historique. Le bouton retour ne doit pas
      // ramener à l'écran de connexion.
      Get.offAllNamed<void>(AppRoutes.accueil);
    } on ApiException catch (e) {
      if (e.type == TypeErreurApi.validation) {
        // Une erreur par champ, au bon endroit.
        erreurs.assignAll({
          for (final champ in e.erreursChamps.keys)
            champ: ?e.erreurPourChamp(champ),
        });
      } else {
        erreurGenerale.value = e.message;
      }
      // Mot de passe faux : on le vide pour pouvoir le retaper directement.
      if (e.type == TypeErreurApi.nonAuthentifie) champMotDePasse.clear();
    } finally {
      chargement.value = false;
    }
  }

  Future<void> _preremplirEmail() async {
    final email = await _auth.lireDernierEmail();
    if (isClosed || email == null || champEmail.text.isNotEmpty) return;
    champEmail.text = email;
  }
}

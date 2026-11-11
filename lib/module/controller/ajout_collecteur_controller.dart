import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/nouveau_collecteur.dart';
import 'package:tala/data/repositories/utilisateur_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/module/controller/accueil_controller.dart';

/// Onglet "Ajouter un collecteur" de l'admin (maquette : Nom, Prénom,
/// E-mail, Mot de passe + boutons Annuler / Enregistrer).
///
/// Cycle de vie :
/// - onInit  → crée les 4 champs
/// - onClose → les libère
class AjoutCollecteurController extends GetxController {
  AjoutCollecteurController(this._repository, this._accueil);

  final UtilisateurRepository _repository;
  final AccueilController _accueil;

  late final TextEditingController champNom;
  late final TextEditingController champPrenom;
  late final TextEditingController champEmail;
  late final TextEditingController champMotDePasse;

  final erreurs = <String, String>{}.obs;
  final enregistrement = false.obs;

  @override
  void onInit() {
    super.onInit();
    champNom = TextEditingController();
    champPrenom = TextEditingController();
    champEmail = TextEditingController();
    champMotDePasse = TextEditingController();
  }

  @override
  void onClose() {
    champNom.dispose();
    champPrenom.dispose();
    champEmail.dispose();
    champMotDePasse.dispose();
    super.onClose();
  }

  void effacerErreur(String champ) => erreurs.remove(champ);

  Future<void> enregistrer() async {
    if (enregistrement.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    erreurs.clear();
    enregistrement.value = true;

    try {
      final cree = await _repository.ajouterCollecteur(
        NouveauCollecteur(
          nom: champNom.text,
          prenom: champPrenom.text,
          email: champEmail.text,
          motDePasse: champMotDePasse.text,
        ),
      );
      Notifications.succes('${cree.nomEtPrenom} peut maintenant se connecter.',
          titre: 'Collecteur ajouté');
      vider();
      // On montre la liste, où le nouveau collecteur apparaît.
      _accueil.changerOnglet(AccueilController.ongletCollecteurs);
    } on ApiException catch (e) {
      if (e.type == TypeErreurApi.validation) {
        // Ex : "email déjà utilisé" (erreur 422 de l'API) → sous le champ.
        erreurs.assignAll({
          for (final champ in e.erreursChamps.keys)
            champ: ?e.erreurPourChamp(champ),
        });
      } else {
        Notifications.erreur(e.message);
      }
    } finally {
      enregistrement.value = false;
    }
  }

  /// Bouton "Annuler" : vide le formulaire.
  void vider() {
    champNom.clear();
    champPrenom.clear();
    champEmail.clear();
    champMotDePasse.clear();
    erreurs.clear();
  }
}

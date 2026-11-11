import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/modification_compte.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/repositories/auth_repository.dart';
import 'package:tala/data/repositories/utilisateur_repository.dart';
import 'package:tala/data/services/api_exception.dart';

/// Page "Modifier mes informations" (collecteur ET admin).
///
/// Cycle de vie :
/// - onInit  → crée les champs, pré-remplis avec les valeurs actuelles
/// - onClose → les libère
class ModifierProfilController extends GetxController {
  ModifierProfilController(this._auth, this._utilisateurs);

  final AuthRepository _auth;
  final UtilisateurRepository _utilisateurs;

  late final bool modeCollecteur;

  /// Le compte affiché dans le formulaire.
  Utilisateur? _cible;

  String get titre =>
      modeCollecteur ? 'Modifier le collecteur' : 'Modifier mes informations';

  late final TextEditingController champNom;
  late final TextEditingController champPrenom;
  late final TextEditingController champEmail;
  late final TextEditingController champNouveauMotDePasse;

  final erreurs = <String, String>{}.obs;
  final enregistrement = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Un id dans l'adresse = mode collecteur.
    final id = int.tryParse(Get.parameters['id'] ?? '');
    modeCollecteur = id != null;

    // Le collecteur est envoyé par sa fiche (arguments) : formulaire
    // pré-rempli tout de suite, sans requête.
    final argument = Get.arguments;
    _cible = modeCollecteur
        ? (argument is Utilisateur && argument.id == id ? argument : null)
        : _auth.utilisateur;

    champNom = TextEditingController(text: _cible?.nom);
    champPrenom = TextEditingController(text: _cible?.prenom);
    champEmail = TextEditingController(text: _cible?.email);
    champNouveauMotDePasse = TextEditingController();
  }

  @override
  void onClose() {
    champNom.dispose();
    champPrenom.dispose();
    champEmail.dispose();
    champNouveauMotDePasse.dispose();
    super.onClose();
  }

  void effacerErreur(String champ) => erreurs.remove(champ);

  void annuler() => Get.back<void>();

  Future<void> enregistrer() async {
    final actuel = _cible;
    if (actuel == null || enregistrement.value) return;
    FocusManager.instance.primaryFocus?.unfocus();

    // On n'envoie QUE ce qui a changé (null = "ne pas changer").
    String? siChange(String nouveau, String ancien) =>
        nouveau.trim() == ancien ? null : nouveau;
    final nouveauMotDePasse = champNouveauMotDePasse.text;
    final modification = ModificationCompte(
      nom: siChange(champNom.text, actuel.nom),
      prenom: siChange(champPrenom.text, actuel.prenom),
      email: siChange(champEmail.text, actuel.email),
      motDePasse: nouveauMotDePasse.isEmpty ? null : nouveauMotDePasse,
    );
    if (modification.estVide) {
      Notifications.info('Aucune modification à enregistrer.');
      return;
    }

    enregistrement.value = true;
    erreurs.clear();
    try {
      final modifie = modeCollecteur
          ? await _utilisateurs.modifierCollecteur(actuel.id, modification)
          : await _auth.modifierMonCompte(modification);
      // D'abord fermer la page EN RENVOYANT le compte modifié…
      Get.back<Utilisateur>(result: modifie);
      // …puis le message (voir problème 2).
      Notifications.succes(
        modeCollecteur
            ? 'Les informations du collecteur ont été mises à jour.'
            : 'Vos informations ont été mises à jour.',
      );
    } on ApiException catch (e) {
      if (e.type == TypeErreurApi.validation) {
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
}

import 'dart:async';

import 'package:get/get.dart';
import 'package:tala/core/widget/dialogue_confirmation.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/signalement.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/data/repositories/auth_repository.dart';
import 'package:tala/data/repositories/signalement_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/jeton_annulation.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Page détail d'un signalement ("Mes signalements" du collecteur, et
/// liste de l'admin).
///
/// L'ADMIN a en plus : changer le statut, supprimer le signalement.
///
/// Cycle de vie :
/// - onInit  → lit l'id dans l'adresse, affiche TOUT DE SUITE les données
///             déjà connues (argument ou cache), puis charge la version à jour
/// - onClose → annule la requête si on est reparti avant la réponse
class DetailSignalementController extends GetxController {
  DetailSignalementController(this._repository, this._auth);

  final SignalementRepository _repository;
  final AuthRepository _auth;

  final signalement = Rxn<Signalement>();
  final chargement = false.obs;
  final erreur = Rxn<ApiException>();

  /// Statut en cours d'envoi (affiche un petit chargement sur sa puce).
  final statutEnCours = Rxn<Statut>();
  final suppressionEnCours = false.obs;

  int? _id;
  JetonAnnulation? _jeton;

  bool get estAdmin => _auth.estAdmin;
  bool get estIntrouvable => erreur.value?.type == TypeErreurApi.introuvable;

  @override
  void onInit() {
    super.onInit();
    // "/signalement/12" → Get.parameters['id'] = "12"
    _id = int.tryParse(Get.parameters['id'] ?? '');

    final id = _id;
    final argument = Get.arguments;
    if (argument is Signalement && argument.id == id) {
      signalement.value = argument; // envoyé par la liste
    } else if (id != null) {
      signalement.value = _repository.trouverDansCache(id); // ou null
    }
    unawaited(charger());
  }

  @override
  void onClose() {
    _jeton?.annuler();
    super.onClose();
  }

  /// (Re)charge depuis l'API. Utilisé aussi par "tirer pour rafraîchir".
  Future<void> charger() async {
    final id = _id;
    if (id == null) {
      erreur.value = const ApiException(
        type: TypeErreurApi.introuvable,
        message: "Ce signalement n'existe pas.",
      );
      return;
    }

    _jeton?.annuler();
    final jeton = JetonAnnulation();
    _jeton = jeton;
    chargement.value = true;
    erreur.value = null;
    try {
      signalement.value = await _repository.getSignalement(
        id,
        annulation: jeton,
      );
    } on ApiException catch (e) {
      if (e.estAnnulation) return;
      if (e.type == TypeErreurApi.introuvable) signalement.value = null;
      erreur.value = e;
      if (signalement.value != null) Notifications.erreur(e.message);
    } finally {
      if (identical(_jeton, jeton)) chargement.value = false;
    }
  }

  // ---------- Admin ----------

  /// Signalé → En cours → Résolu (ou retour en arrière si erreur de clic).
  Future<void> changerStatut(Statut statut) async {
    final actuel = signalement.value;
    if (!estAdmin || actuel == null || actuel.statut == statut) return;
    if (statutEnCours.value != null) return; // un changement à la fois

    statutEnCours.value = statut;
    try {
      signalement.value = await _repository.changerStatut(actuel, statut);
      signalement
          .refresh(); // même raison : sinon la puce et le badge ne bougent pas
      Notifications.succes('Statut : ${statut.libelle}.');
    } on ApiException catch (e) {
      Notifications.erreur(e.message);
    } finally {
      statutEnCours.value = null;
    }
  }

  Future<void> supprimer() async {
    final actuel = signalement.value;
    if (!estAdmin || actuel == null || suppressionEnCours.value) return;

    final confirme = await DialogueConfirmation.demander(
      titre: 'Supprimer ce signalement ?',
      message:
          'Le signalement n° ${actuel.id} et sa photo seront supprimés '
          'définitivement.',
      libelleConfirmer: 'Supprimer',
      danger: true,
    );
    if (!confirme) return;

    suppressionEnCours.value = true;
    try {
      await _repository.supprimerSignalement(actuel.id);
      // 1) D'abord quitter la page…
      retour();
      // 2) …PUIS le message. Dans l'autre ordre, Get.back() fermerait
      //    le message au lieu de la page.
      Notifications.succes('Signalement supprimé.');
    } on ApiException catch (e) {
      Notifications.erreur(e.message);
    } finally {
      suppressionEnCours.value = false;
    }
  }

  /// Retour à la liste. Si la page a été ouverte sans rien "derrière",
  /// on ouvre l'accueil.
  void retour() {
    final navigateur = Get.key.currentState;
    if (navigateur != null && navigateur.canPop()) {
      Get.back<void>();
    } else {
      Get.offAllNamed<void>(AppRoutes.accueil);
    }
  }
}

import 'dart:async';

import 'package:get/get.dart';
import 'package:tala/core/widget/dialogue_confirmation.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/signalement.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/repositories/signalement_repository.dart';
import 'package:tala/data/repositories/utilisateur_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Page détail d'un collecteur (admin) : ses infos + SES signalements.
///
/// Cycle de vie :
/// - onInit → lit l'id dans l'adresse, affiche le collecteur reçu en
///            argument, puis charge ses signalements
class DetailCollecteurController extends GetxController {
  DetailCollecteurController(this._utilisateurs, this._signalements);

  final UtilisateurRepository _utilisateurs;
  final SignalementRepository _signalements;

  final collecteur = Rxn<Utilisateur>();
  final signalements = <Signalement>[].obs;
  final chargement = false.obs;
  final erreur = Rxn<ApiException>();
  final suppressionEnCours = false.obs;

  int? _id;

  @override
  void onInit() {
    super.onInit();
    _id = int.tryParse(Get.parameters['id'] ?? '');
    final argument = Get.arguments;
    if (argument is Utilisateur && argument.id == _id) {
      collecteur.value = argument;
    }
    unawaited(charger());
  }

  Future<void> charger({bool forcer = false}) async {
    final id = _id;
    if (id == null) return;
    chargement.value = true;
    erreur.value = null;
    try {
      // Les 2 requêtes partent EN MÊME TEMPS (Future.wait) au lieu de
      // l'une après l'autre : c'est plus rapide.
      final resultats = await Future.wait([
        _utilisateurs.getCollecteur(id),
        _signalements.getSignalementsDuCollecteur(
          id,
          forcerRafraichissement: forcer,
        ),
      ]);
      final infos = resultats[0] as Utilisateur;
      final liste = resultats[1] as List<Signalement>;
      signalements.assignAll(liste);
      // Le compteur affiché correspond à la liste réellement chargée.
      collecteur.value = infos.copyWith(nombreSignalements: liste.length);
    } on ApiException catch (e) {
      erreur.value = e;
      if (collecteur.value != null) Notifications.erreur(e.message);
    } finally {
      chargement.value = false;
    }
  }

  /// Ouvre le formulaire et affiche le résultat au retour.
  Future<void> modifier() async {
    final actuel = collecteur.value;
    if (actuel == null) return;
    // toNamed attend la fermeture du formulaire et récupère le
    // Get.back(result: modifie) — même principe que "Ajuster la position".
    final modifie = await Get.toNamed<Utilisateur>(
      AppRoutes.versModificationCollecteur(actuel.id),
      arguments: actuel,
    );
    if (modifie == null) return; // Annuler ou retour
    collecteur.value = modifie;
  }

  Future<void> ouvrirSignalement(Signalement signalement) async {
    await Get.toNamed<void>(
      AppRoutes.versSignalement(signalement.id),
      arguments: signalement,
    );
    unawaited(charger());
  }

  /// L'API refuse (409) si le collecteur a déjà des signalements : on le
  /// dit AVANT de demander confirmation, c'est plus clair.
  Future<void> supprimer() async {
    final actuel = collecteur.value;
    if (actuel == null || suppressionEnCours.value) return;

    if (signalements.isNotEmpty) {
      Notifications.erreur(
        'Impossible : ${actuel.nomEtPrenom} a déjà des signalements.',
      );
      return;
    }

    final confirme = await DialogueConfirmation.demander(
      titre: 'Supprimer ce collecteur ?',
      message: '${actuel.nomEtPrenom} ne pourra plus se connecter à tala.',
      libelleConfirmer: 'Supprimer',
      danger: true,
    );
    if (!confirme) return;

    suppressionEnCours.value = true;
    try {
      await _utilisateurs.supprimerCollecteur(actuel.id);
      // 1) D'abord quitter la page…
      Get.back<void>();
      // 2) …PUIS le message. Dans l'autre ordre
      Notifications.succes('Collecteur supprimé.');
    } on ApiException catch (e) {
      Notifications.erreur(e.message); // ex : 409 renvoyé par l'API
    } finally {
      suppressionEnCours.value = false;
    }
  }
}

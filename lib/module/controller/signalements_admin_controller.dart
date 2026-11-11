import 'dart:async';

import 'package:get/get.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/signalement.dart';
import 'package:tala/data/models/signalement_filtre.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/data/repositories/signalement_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/jeton_annulation.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Onglet "Signalements" de l'admin : TOUS les signalements, filtrables
/// par catégorie (comme sur la maquette) et par statut, avec le total.
///
/// Cycle de vie :
/// - onInit  → 1er chargement + surveillance de l'onglet actif (`ever`)
/// - onClose → annule la requête en cours, arrête la surveillance
class SignalementsAdminController extends GetxController {
  SignalementsAdminController(this._repository, this._accueil);

  final SignalementRepository _repository;
  final AccueilController _accueil;

  final signalements = <Signalement>[].obs;
  final chargement = false.obs;
  final erreur = Rxn<ApiException>();

  /// Filtre envoyé à l'API (catégorie ET statut peuvent se combiner).
  final filtre = SignalementFiltre.vide.obs;

  JetonAnnulation? _jeton;
  Worker? _surveillanceOnglet;

  @override
  void onInit() {
    super.onInit();
    unawaited(charger());
    _surveillanceOnglet = ever<int>(_accueil.onglet, (index) {
      if (index == AccueilController.ongletListe) unawaited(charger());
    });
  }

  @override
  void onClose() {
    _jeton?.annuler();
    _surveillanceOnglet?.dispose();
    super.onClose();
  }

  Future<void> charger({bool forcer = false}) async {
    _jeton?.annuler();
    final jeton = JetonAnnulation();
    _jeton = jeton;

    chargement.value = true;
    erreur.value = null;
    try {
      signalements.assignAll(
        await _repository.getSignalements(
          filtre: filtre.value,
          forcerRafraichissement: forcer,
          annulation: jeton,
        ),
      );
    } on ApiException catch (e) {
      if (e.estAnnulation) return;
      erreur.value = e;
      if (signalements.isNotEmpty) Notifications.erreur(e.message);
    } finally {
      if (identical(_jeton, jeton)) chargement.value = false;
    }
  }

  /// `null` = "Tout". La même puce touchée 2 fois → retour à "Tout".
  void choisirCategorie(Categorie? categorie) {
    final actuelle = filtre.value.categorie;
    _appliquer(
      filtre.value.copyWith(
        categorie: () => actuelle == categorie ? null : categorie,
      ),
    );
  }

  void choisirStatut(Statut? statut) {
    final actuel = filtre.value.statut;
    _appliquer(
      filtre.value.copyWith(statut: () => actuel == statut ? null : statut),
    );
  }

  void _appliquer(SignalementFiltre nouveau) {
    if (filtre.value == nouveau) return;
    filtre.value = nouveau;
    unawaited(charger());
  }

  Future<void> ouvrirDetail(Signalement signalement) async {
    await Get.toNamed<void>(
      AppRoutes.versSignalement(signalement.id),
      arguments: signalement,
    );
    // Au retour : statut changé ou signalement supprimé → on relit le cache.
    unawaited(charger());
  }
}

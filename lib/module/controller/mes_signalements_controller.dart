import 'dart:async';

import 'package:get/get.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/signalement.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/data/repositories/signalement_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/jeton_annulation.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Onglet "Mes signalements" du collecteur.
///
/// Cycle de vie :
/// - onInit  → 1er chargement + surveillance de l'onglet actif (`ever`)
/// - onClose → annule la requête en cours et arrête la surveillance
class MesSignalementsController extends GetxController {
  MesSignalementsController(this._repository, this._accueil);

  final SignalementRepository _repository;
  final AccueilController _accueil;

  final signalements = <Signalement>[].obs;
  final chargement = false.obs;
  final erreur = Rxn<ApiException>();

  /// Filtre par statut, calculé sur le téléphone (`null` = Tout).
  /// Permet au collecteur de voir vite ce qui est déjà résolu.
  final statut = Rxn<Statut>();

  JetonAnnulation? _jeton;
  Worker? _surveillanceOnglet;

  /// Liste affichée = liste complète filtrée par statut.
  List<Signalement> get signalementsAffiches {
    final filtre = statut.value;
    if (filtre == null) return signalements;
    return signalements.where((s) => s.statut == filtre).toList();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(charger());

    // `ever` = "à chaque fois que cette valeur change, appelle…".
    // Quand le collecteur revient sur cet onglet (ex : juste après avoir
    // envoyé un signalement), on relit la liste. Le repository l'a déjà
    // mise à jour dans son cache : c'est instantané, sans requête.
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

  /// [forcer] = true pour "tirer pour rafraîchir" (ignore le cache).
  Future<void> charger({bool forcer = false}) async {
    _jeton?.annuler();
    final jeton = JetonAnnulation();
    _jeton = jeton;

    chargement.value = true;
    erreur.value = null;
    try {
      signalements.assignAll(
        await _repository.getMesSignalements(
          forcerRafraichissement: forcer,
          annulation: jeton,
        ),
      );
    } on ApiException catch (e) {
      if (e.estAnnulation) return;
      erreur.value = e;
      // Liste déjà affichée → simple notification, on garde la liste.
      if (signalements.isNotEmpty) Notifications.erreur(e.message);
    } finally {
      if (identical(_jeton, jeton)) chargement.value = false;
    }
  }

  /// Touche la même puce une 2e fois → retour à "Tout".
  void choisirStatut(Statut? choix) =>
      statut.value = statut.value == choix ? null : choix;

  void allerAuFormulaire() =>
      _accueil.changerOnglet(AccueilController.ongletAjout);

  Future<void> ouvrirDetail(Signalement signalement) async {
    // `arguments` : le détail s'affiche instantanément avec ces données.
    await Get.toNamed<void>(
      AppRoutes.versSignalement(signalement.id),
      arguments: signalement,
    );
    // Au retour, on relit le cache (le statut a pu changer).
    unawaited(charger());
  }
}

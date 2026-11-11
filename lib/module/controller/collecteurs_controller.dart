import 'dart:async';

import 'package:get/get.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/repositories/utilisateur_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Onglet "Collecteurs" de l'admin : la liste, chaque collecteur avec son
/// nombre de signalements sur son icône, et une recherche.
///
/// Cycle de vie :
/// - onInit  → 1er chargement, surveillance de l'onglet, debounce recherche
/// - onClose → arrête les "workers" (surveillance + debounce)
class CollecteursController extends GetxController {
  CollecteursController(this._repository, this._accueil);

  final UtilisateurRepository _repository;
  final AccueilController _accueil;

  final collecteurs = <Utilisateur>[].obs;
  final chargement = false.obs;
  final erreur = Rxn<ApiException>();

  /// Texte tapé dans la recherche (mis à jour à chaque lettre).
  final saisie = ''.obs;

  /// Texte RÉELLEMENT utilisé pour filtrer (mis à jour par le debounce).
  final recherche = ''.obs;

  final List<Worker> _workers = [];

  /// Collecteurs dont le nom ou le prénom contient la recherche.
  /// (Pas l'e-mail : il est masqué à l'écran, un résultat trouvé "par
  /// l'e-mail" paraîtrait incompréhensible.)
  List<Utilisateur> get collecteursAffiches {
    final texte = recherche.value.trim().toLowerCase();
    if (texte.isEmpty) return collecteurs;
    return collecteurs
        .where((c) => c.nomEtPrenom.toLowerCase().contains(texte))
        .toList();
  }

  /// Total des signalements de tous les collecteurs (en-tête de liste).
  int get totalSignalements =>
      collecteurs.fold(0, (total, c) => total + (c.nombreSignalements ?? 0));

  @override
  void onInit() {
    super.onInit();
    unawaited(charger());
    _workers
      ..add(
        ever<int>(_accueil.onglet, (index) {
          if (index == AccueilController.ongletCollecteurs) {
            unawaited(charger());
          }
        }),
      )
      // `debounce` : on attend 400 ms sans frappe avant de filtrer.
      // (Ici le filtre est local donc rapide, mais la liste ne "saute"
      // plus à chaque lettre : plus agréable à lire.)
      ..add(
        debounce<String>(
          saisie,
          (texte) => recherche.value = texte,
          time: const Duration(milliseconds: 300),
        ),
      );
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }

  Future<void> charger({bool forcer = false}) async {
    chargement.value = true;
    erreur.value = null;
    try {
      collecteurs.assignAll(
        await _repository.getCollecteurs(forcerRafraichissement: forcer),
      );
    } on ApiException catch (e) {
      erreur.value = e;
      if (collecteurs.isNotEmpty) Notifications.erreur(e.message);
    } finally {
      chargement.value = false;
    }
  }

  void surRecherche(String texte) => saisie.value = texte;

  void allerAuFormulaire() =>
      _accueil.changerOnglet(AccueilController.ongletAjout);

  Future<void> ouvrirDetail(Utilisateur collecteur) async {
    await Get.toNamed<void>(
      AppRoutes.versCollecteur(collecteur.id),
      arguments: collecteur,
    );
    // Au retour : collecteur supprimé ? → on relit le cache.
    unawaited(charger());
  }
}

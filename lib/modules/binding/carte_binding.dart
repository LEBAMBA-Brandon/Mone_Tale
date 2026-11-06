import 'package:get/get.dart';
import 'package:mono/modules/controller/carte_controller.dart';

/// Dépendances de l'écran Carte.
///
/// `lazyPut` : le controller n'est créé qu'au moment où l'écran en a
/// besoin (→ onInit), et il est supprimé quand l'écran disparaît (→ onClose).
/// `Get.find()` récupère les repositories déjà créés par InitialBinding.
class CarteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CarteController>(
      () => CarteController(
        signalementRepository: Get.find(),
        rechercheRepository: Get.find(),
        quartierRepository: Get.find(),
        localisationService: Get.find(),
        stockage: Get.find(),
      ),
    );
  }
}

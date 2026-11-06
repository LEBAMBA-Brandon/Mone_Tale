import 'package:get/get.dart';
import 'package:mono/modules/controller/detail_signalement_controller.dart';

/// Dépendances de l'écran Détail d'un signalement.
class DetailSignalementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailSignalementController>(
      () => DetailSignalementController(Get.find()),
    );
  }
}

import 'package:get/get.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/controller/ajout_collecteur_controller.dart';
import 'package:tala/module/controller/ajout_signalement_controller.dart';
import 'package:tala/module/controller/choix_position_controller.dart';
import 'package:tala/module/controller/collecteurs_controller.dart';
import 'package:tala/module/controller/connexion_controller.dart';
import 'package:tala/module/controller/detail_collecteur_controller.dart';
import 'package:tala/module/controller/detail_signalement_controller.dart';
import 'package:tala/module/controller/mes_signalements_controller.dart';
import 'package:tala/module/controller/modifier_profil_controller.dart';
import 'package:tala/module/controller/profil_controller.dart';
import 'package:tala/module/controller/signalements_admin_controller.dart';

// Un binding par route : il enregistre les controllers de l'écran.
//
// `Get.lazyPut` = "crée-le seulement quand quelqu'un le demande"
// (au premier `Get.find`, donc quand l'écran se construit).
// Quand on quitte la route, GetX supprime ses controllers → onClose().

class ConnexionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ConnexionController(Get.find()));
  }
}

/// L'accueil enregistre les controllers de TOUS ses onglets (collecteur
/// et admin), mais en "lazy" : seuls ceux des onglets réellement ouverts
/// sont créés. Un collecteur ne crée donc jamais les controllers admin.
class AccueilBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AccueilController(Get.find()));

    // Communs
    Get.lazyPut(
      () => ProfilController(
        auth: Get.find(),
        theme: Get.find(),
        stockage: Get.find(),
        accueil: Get.find(),
      ),
    );

    // Collecteur
    Get.lazyPut(() => MesSignalementsController(Get.find(), Get.find()));
    Get.lazyPut(
      () => AjoutSignalementController(
        signalements: Get.find(),
        quartiers: Get.find(),
        localisation: Get.find(),
        photos: Get.find(),
        accueil: Get.find(),
      ),
    );

    // Admin
    Get.lazyPut(() => SignalementsAdminController(Get.find(), Get.find()));
    Get.lazyPut(() => AjoutCollecteurController(Get.find(), Get.find()));
    Get.lazyPut(() => CollecteursController(Get.find(), Get.find()));
  }
}

class DetailSignalementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DetailSignalementController(Get.find(), Get.find()));
  }
}

class DetailCollecteurBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DetailCollecteurController(Get.find(), Get.find()));
  }
}

class ModifierProfilBinding extends Bindings {
  @override
  void dependencies() {
    // Get.find() trouve AuthRepository puis UtilisateurRepository,
    // créés une fois pour toutes dans InitialBinding.
    Get.lazyPut(() => ModifierProfilController(Get.find(), Get.find()));
  }
}

class ChoixPositionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChoixPositionController(Get.find()));
  }
}

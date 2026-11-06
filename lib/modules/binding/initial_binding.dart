import 'package:get/get.dart';
import 'package:mono/data/repositories/quartier_repository.dart';
import 'package:mono/data/repositories/recherche_repository.dart';
import 'package:mono/data/repositories/signalement_repository.dart';
import 'package:mono/data/services/api_client.dart';
import 'package:mono/data/services/localisation_service.dart';
import 'package:mono/data/services/quartier_service.dart';
import 'package:mono/data/services/recherche_recente_service.dart';
import 'package:mono/data/services/signalement_service.dart';
import 'package:mono/data/services/stockage_local_service.dart';
import 'package:mono/modules/controller/theme_controller.dart';

/// Dépendances GLOBALES, créées UNE fois au démarrage de l'application.
///
/// `permanent: true` → GetX ne les supprime jamais. Indispensable pour les
/// repositories : leur cache survit quand on passe d'un écran à l'autre.
///
/// L'ordre compte : on crée d'abord ce dont les autres ont besoin
/// (client HTTP → services → repositories → controllers).
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1) Services : accès aux sources de données.
    final client = Get.put(ApiClient(), permanent: true);
    final stockage = Get.put(StockageLocalService(), permanent: true);
    Get.put(LocalisationService(), permanent: true);

    // 2) Repositories : point d'entrée unique pour les controllers.
    final signalementRepository = Get.put(
      SignalementRepository(SignalementService(client)),
      permanent: true,
    );
    final quartierRepository = Get.put(
      QuartierRepository(QuartierService(client)),
      permanent: true,
    );
    Get.put(
      RechercheRepository(
        signalementRepository: signalementRepository,
        quartierRepository: quartierRepository,
        rechercheRecenteService: RechercheRecenteService(),
      ),
      permanent: true,
    );

    // 3) Controller global : le thème concerne toute l'application.
    Get.put(ThemeController(stockage), permanent: true);
  }
}

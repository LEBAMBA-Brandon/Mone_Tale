import 'package:get/get.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/repositories/auth_repository.dart';
import 'package:tala/data/repositories/quartier_repository.dart';
import 'package:tala/data/repositories/signalement_repository.dart';
import 'package:tala/data/repositories/utilisateur_repository.dart';
import 'package:tala/data/services/api_client.dart';
import 'package:tala/data/services/auth_service.dart';
import 'package:tala/data/services/localisation_service.dart';
import 'package:tala/data/services/photo_service.dart';
import 'package:tala/data/services/preferences_formulaire_service.dart';
import 'package:tala/data/services/quartier_service.dart';
import 'package:tala/data/services/session_service.dart';
import 'package:tala/data/services/signalement_service.dart';
import 'package:tala/data/services/stockage_local_service.dart';
import 'package:tala/data/services/utilisateur_service.dart';
import 'package:tala/module/controller/theme_controller.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Dépendances GLOBALES, créées UNE fois au démarrage de l'application.
///
/// `permanent: true` → GetX ne les supprime jamais. Indispensable :
/// - AuthRepository garde la session pendant toute la vie de l'app ;
/// - les caches des repositories survivent aux changements d'écran.
///
/// L'ordre compte : client HTTP → services → repositories → controllers.
///
/// ⚠️ Les middlewares utilisent `Get.find<AuthRepository>()` : ce binding
/// doit donc s'exécuter AVANT la première route (`initialBinding` dans
/// main.dart, c'est le cas).
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1) Services
    final client = Get.put(ApiClient(), permanent: true);
    final stockage = Get.put(StockageLocalService(), permanent: true);
    final preferences = PreferencesFormulaireService();
    final utilisateurService = UtilisateurService(client);
    Get.put(LocalisationService(), permanent: true);
    Get.put(PhotoService(), permanent: true);

    // 2) Repositories
    final signalements = Get.put(
      SignalementRepository(SignalementService(client), preferences),
      permanent: true,
    );
    Get.put(
      QuartierRepository(QuartierService(client), preferences),
      permanent: true,
    );
    final utilisateurs = Get.put(
      UtilisateurRepository(utilisateurService, signalements),
      permanent: true,
    );
    final auth = Get.put(
      AuthRepository(
        service: AuthService(client),
        utilisateurService: utilisateurService,
        client: client,
        sessionService: SessionService(),
        preferences: preferences,
      ),
      permanent: true,
    );

    // 3) Branchements de la session
    // À chaque déconnexion : on oublie les données de l'utilisateur.
    auth
      ..ajouterNettoyage(signalements.viderCache)
      ..ajouterNettoyage(utilisateurs.viderCache)
      // Token refusé par le serveur (expiré, supprimé…) → retour à la
      // connexion, avec un message pour comprendre pourquoi.
      ..surDeconnexionForcee = () {
        Get.offAllNamed<void>(AppRoutes.connexion);
        Notifications.erreur(
          'Votre session a expiré. Veuillez vous reconnecter.',
        );
      };

    // 4) Controller global : le thème concerne toute l'application.
    Get.put(ThemeController(stockage), permanent: true);
  }
}

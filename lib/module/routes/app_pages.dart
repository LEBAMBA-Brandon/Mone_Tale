import 'package:get/get.dart';
import 'package:tala/module/binding/ecrans_binding.dart';
import 'package:tala/module/middleware/auth_middleware.dart';
import 'package:tala/module/middleware/id_valide_middleware.dart';
import 'package:tala/module/routes/app_routes.dart';
import 'package:tala/module/screens/accueil/accueil_screen.dart';
import 'package:tala/module/screens/choix_position/choix_position_screen.dart';
import 'package:tala/module/screens/connexion/connexion_screen.dart';
import 'package:tala/module/screens/detail_collecteur/detail_collecteur_screen.dart';
import 'package:tala/module/screens/detail_signalement/detail_signalement_screen.dart';
import 'package:tala/module/screens/page_introuvable_screen.dart';
import 'package:tala/module/screens/profil/modifier_profil_screen.dart';
import 'package:tala/module/screens/profil/page_info_screen.dart';

/// Association route → écran + binding + middlewares.
///
/// Quand on ouvre une route, GetX :
/// 1. exécute les middlewares, du plus petit `priority` au plus grand
///    (ils peuvent rediriger ailleurs) ;
/// 2. exécute le binding (enregistre les controllers) ;
/// 3. construit l'écran.
/// Quand on quitte l'écran, GetX supprime ses controllers → onClose().
abstract final class AppPages {
  static final GetPage<dynamic> introuvable = GetPage(
    name: AppRoutes.introuvable,
    page: () => const PageIntrouvableScreen(),
  );

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.connexion,
      page: () => const ConnexionScreen(),
      binding: ConnexionBinding(),
      middlewares: [InviteMiddleware()],
    ),
    GetPage(
      name: AppRoutes.accueil,
      page: () => const AccueilScreen(),
      binding: AccueilBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.detailSignalement,
      page: () => const DetailSignalementScreen(),
      binding: DetailSignalementBinding(),
      middlewares: [AuthMiddleware(), IdValideMiddleware('signalement')],
    ),
    GetPage(
      name: AppRoutes.detailCollecteur,
      page: () => const DetailCollecteurScreen(),
      binding: DetailCollecteurBinding(),
      middlewares: [
        AuthMiddleware(),
        AdminMiddleware(),
        IdValideMiddleware('collecteur'),
      ],
    ),
    GetPage(
      name: AppRoutes.modifierCollecteur,
      page: () => const ModifierProfilScreen(), // même formulaire
      binding: ModifierProfilBinding(),
      middlewares: [
        AuthMiddleware(),
        AdminMiddleware(), // un collecteur est renvoyé à l'accueil
        IdValideMiddleware(
          'collecteur',
        ), // "/collecteur/abc/modifier" → introuvable
      ],
    ),
    GetPage(
      name: AppRoutes.choixPosition,
      page: () => const ChoixPositionScreen(),
      binding: ChoixPositionBinding(),
      middlewares: [AuthMiddleware()],
      // L'écran "monte" depuis le bas, comme une feuille qu'on referme.
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    // Pages de texte : pas de controller, pas besoin d'être connecté.
    GetPage(name: AppRoutes.info, page: () => const PageInfoScreen()),
    introuvable,
  ];
}

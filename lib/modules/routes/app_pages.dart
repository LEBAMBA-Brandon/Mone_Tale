import 'package:get/get.dart';
import 'package:mono/modules/binding/carte_binding.dart';
import 'package:mono/modules/binding/detail_signalement_binding.dart';
import 'package:mono/modules/middleware/detail_signalement_middleware.dart';
import 'package:mono/modules/routes/app_routes.dart';
import 'package:mono/modules/screens/carte/carte_screen.dart';
import 'package:mono/modules/screens/detail_signalement/detail_signalement_screen.dart';
import 'package:mono/modules/screens/page_introuvable_screen.dart';

/// Association route → écran + binding (+ middlewares).
///
/// Quand on ouvre une route, GetX :
/// 1. exécute les middlewares (peut rediriger ailleurs) ;
/// 2. exécute le binding (enregistre le controller) ;
/// 3. construit l'écran.
/// Quand on quitte l'écran, GetX supprime le controller → onClose().
abstract final class AppPages {
  static final GetPage<dynamic> introuvable = GetPage(
    name: AppRoutes.introuvable,
    page: () => const PageIntrouvableScreen(),
  );

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.carte,
      page: () => const CarteScreen(),
      binding: CarteBinding(),
    ),
    GetPage(
      name: AppRoutes.detail,
      page: () => const DetailSignalementScreen(),
      binding: DetailSignalementBinding(),
      middlewares: [DetailSignalementMiddleware()],
      // Le détail "monte" depuis le bas, comme une feuille.
      transition: Transition.downToUp,
    ),
    introuvable,
  ];
}

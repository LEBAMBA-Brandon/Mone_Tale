import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mono/modules/routes/app_routes.dart';

/// Garde de la route "/signalement/:id".
///
/// Un middleware s'exécute AVANT la création de l'écran et de son controller.
/// Ici : si l'id est absent ou invalide (ex : "/signalement/abc", lien web
/// mal recopié), on redirige vers la page "introuvable" au lieu d'ouvrir
/// un écran de détail qui ne pourra rien afficher.
class DetailSignalementMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final id = _extraireId(route);
    if (id == null || id <= 0) {
      return const RouteSettings(name: AppRoutes.introuvable);
    }
    return null; // null = on laisse passer
  }

  /// "/signalement/12" → 12 ; tout autre format → null.
  static int? _extraireId(String? route) {
    if (route == null) return null;
    final segments = Uri.tryParse(route)?.pathSegments ?? const <String>[];
    if (segments.length < 2 || segments.first != 'signalement') return null;
    return int.tryParse(segments[1]);
  }
}

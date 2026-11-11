import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Garde des routes avec un id : "/signalement/:id", "/collecteur/:id".
///
/// Si l'id est absent ou invalide ("/signalement/abc"), on affiche la page
/// "introuvable" au lieu d'ouvrir un écran qui ne pourra rien afficher.
///
/// [segment] = premier morceau de l'adresse ("signalement", "collecteur") :
/// le même middleware sert pour les deux routes.
class IdValideMiddleware extends GetMiddleware {
  IdValideMiddleware(this.segment) : super(priority: 3);

  final String segment;

  @override
  RouteSettings? redirect(String? route) {
    final id = _extraireId(route);
    if (id == null || id <= 0) {
      return const RouteSettings(name: AppRoutes.introuvable);
    }
    return null; // null = on laisse passer
  }

  /// "/signalement/12" → 12 ; tout autre format → null.
  int? _extraireId(String? route) {
    if (route == null) return null;
    final segments = Uri.tryParse(route)?.pathSegments ?? const <String>[];
    if (segments.length < 2 || segments.first != segment) return null;
    return int.tryParse(segments[1]);
  }
}

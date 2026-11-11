import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:tala/data/repositories/auth_repository.dart';
import 'package:tala/module/routes/app_routes.dart';

// Les 3 gardes de tala. Un middleware s'exécute AVANT la création de
// l'écran et de son controller : il peut laisser passer (`null`) ou
// rediriger ailleurs.
//
// `redirect` est SYNCHRONE (pas d'await possible) : c'est pour ça que la
// session est lue avec GetStorage (lecture instantanée) dans
// AuthRepository.
//
// `priority` : quand une route a plusieurs middlewares, le plus petit
// nombre passe en premier (connecté ? → admin ? → id valide ?).

/// Écrans réservés aux utilisateurs CONNECTÉS.
/// Pas connecté → écran de connexion.
class AuthMiddleware extends GetMiddleware {
  AuthMiddleware() : super(priority: 1);

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthRepository>();
    return auth.estConnecte
        ? null
        : const RouteSettings(name: AppRoutes.connexion);
  }
}

/// Écran de connexion : inutile si on est DÉJÀ connecté.
/// Déjà connecté → accueil directement (l'app s'ouvre sans redemander
/// le mot de passe).
class InviteMiddleware extends GetMiddleware {
  InviteMiddleware() : super(priority: 1);

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthRepository>();
    return auth.estConnecte
        ? const RouteSettings(name: AppRoutes.accueil)
        : null;
  }
}

/// Écrans réservés à l'ADMIN (ex : détail d'un collecteur).
/// Un collecteur qui y arrive (lien recopié…) est renvoyé à l'accueil.
///
/// ⚠️ Ce n'est que du confort : la VRAIE sécurité est dans l'API
/// (`can:admin`), qui refuse de toute façon les requêtes d'un collecteur.
class AdminMiddleware extends GetMiddleware {
  AdminMiddleware() : super(priority: 2);

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthRepository>();
    return auth.estAdmin ? null : const RouteSettings(name: AppRoutes.accueil);
  }
}

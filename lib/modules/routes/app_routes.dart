/// Noms des routes (écrans) de l'application.
/// Toujours passer par ces constantes : une faute de frappe dans
/// une route écrite "en dur" ne serait détectée qu'à l'exécution.
abstract final class AppRoutes {
  static const String carte = '/';

  /// `:id` = paramètre lu avec `Get.parameters['id']`.
  static const String detail = '/signalement/:id';

  static const String introuvable = '/introuvable';

  /// Construit la route du détail : `versDetail(12)` → "/signalement/12".
  static String versDetail(int id) => '/signalement/$id';
}

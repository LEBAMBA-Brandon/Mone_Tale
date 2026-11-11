/// Noms des routes (écrans) de tala.
/// Toujours passer par ces constantes : une faute de frappe dans une route
/// écrite "en dur" ne serait détectée qu'à l'exécution.
abstract final class AppRoutes {
  static const String connexion = '/connexion';

  /// Écran principal avec la barre de navigation. Ses onglets changent
  /// selon le rôle (collecteur : 3 onglets, admin : 4).
  static const String accueil = '/accueil';

  /// `:id` = paramètre lu avec `Get.parameters['id']`.
  static const String detailSignalement = '/signalement/:id';
  static const String detailCollecteur = '/collecteur/:id';

  /// Carte plein écran pour ajuster la position d'un signalement.
  static const String choixPosition = '/choix-position';

  /// "Modifier mes informations" (depuis le Profil).
  static const String modifierProfil = '/profil/modifier';

  /// Aide, conditions d'utilisation, politique de confidentialité.
  static const String info = '/info/:page';

  static const String introuvable = '/introuvable';

  /// `versSignalement(12)` → "/signalement/12".
  static String versSignalement(int id) => '/signalement/$id';

  /// `versCollecteur(3)` → "/collecteur/3".
  static String versCollecteur(int id) => '/collecteur/$id';

  /// `versInfo('aide')` → "/info/aide".
  static String versInfo(String page) => '/info/$page';

  /// L'admin modifie un collecteur.
  static const String modifierCollecteur = '/collecteur/:id/modifier';

  static String versModificationCollecteur(int id) =>
      '/collecteur/$id/modifier';
}

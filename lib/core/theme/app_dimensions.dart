/// Toutes les tailles de l'application au même endroit.
///
/// Pourquoi ? Écrire `16` partout, c'est risquer d'avoir 15 ici et 17 là.
/// Avec `AppEspacements.l`, toute l'app garde le même rythme visuel,
/// et on peut tout ajuster en changeant une seule valeur.
abstract final class AppEspacements {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class AppRayons {
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;

  /// Bords complètement arrondis (forme "pilule").
  static const double rond = 999;
}

abstract final class AppTailles {
  /// Taille minimale d'une zone tactile (norme d'accessibilité Android/iOS).
  static const double toucheMin = 48;

  static const double iconeS = 16;
  static const double iconeM = 20;
  static const double iconeL = 24;
  static const double iconeXl = 32;

  static const double hauteurBarreRecherche = 52;

  /// Taille d'un marqueur de signalement sur la carte.
  static const double marqueur = 44;

  /// Largeur max du contenu sur tablette (évite des lignes de texte trop longues).
  static const double largeurMaxContenu = 640;

  /// Largeur max d'un formulaire (connexion, ajout) : au-delà, des champs
  /// très larges sont moins agréables à lire et à remplir.
  static const double largeurMaxFormulaire = 480;

  /// Avatar d'un collecteur (rond avec ses initiales).
  static const double avatar = 44;

  /// Miniature de la photo dans une carte de liste.
  static const double miniature = 88;

  /// Hauteur de la petite carte (choix de la position, page détail).
  static const double miniCarte = 220;
}

abstract final class AppDurees {
  static const Duration rapide = Duration(milliseconds: 150);
  static const Duration normale = Duration(milliseconds: 250);
  static const Duration lente = Duration(milliseconds: 400);

  /// Délai d'attente après la dernière lettre tapée avant de lancer la recherche.
  static const Duration debounceRecherche = Duration(milliseconds: 400);
}

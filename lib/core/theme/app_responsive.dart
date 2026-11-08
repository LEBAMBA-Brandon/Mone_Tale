import 'package:flutter/widgets.dart';

/// Les grandes familles de tailles d'écran.
enum TailleEcran {
  /// < 280 px : montre, écran divisé, fenêtre très réduite (ex : 150 px).
  minuscule,

  /// 280 → 599 px : téléphone en portrait (le cas le plus courant).
  compact,

  /// 600 → 1023 px : tablette, téléphone en paysage.
  moyen,

  /// ≥ 1024 px : grande tablette, navigateur web.
  large,
}

abstract final class AppResponsive {
  static const double seuilMinuscule = 280;
  static const double seuilMoyen = 600;
  static const double seuilLarge = 1024;

  static TailleEcran depuisLargeur(double largeur) {
    if (largeur < seuilMinuscule) return TailleEcran.minuscule;
    if (largeur < seuilMoyen) return TailleEcran.compact;
    if (largeur < seuilLarge) return TailleEcran.moyen;
    return TailleEcran.large;
  }

  /// Marge à gauche et à droite du contenu selon la largeur disponible.
  static double margeHorizontale(double largeur) =>
      switch (depuisLargeur(largeur)) {
        TailleEcran.minuscule => 8,
        TailleEcran.compact => 16,
        TailleEcran.moyen => 24,
        TailleEcran.large => 32,
      };
}

/// À utiliser dans un `LayoutBuilder` : on raisonne sur la place RÉELLEMENT
/// disponible pour le widget (pas sur la taille de tout l'écran).
/// ```dart
/// LayoutBuilder(builder: (context, contraintes) {
///   if (contraintes.estMinuscule) return VersionCompacte();
///   return VersionNormale();
/// })
/// ```
extension ContraintesResponsive on BoxConstraints {
  TailleEcran get tailleEcran => AppResponsive.depuisLargeur(maxWidth);
  bool get estMinuscule => maxWidth < AppResponsive.seuilMinuscule;
  bool get estAuMoinsMoyen => maxWidth >= AppResponsive.seuilMoyen;
}

/// Taille de TOUT l'écran (utile pour les décisions globales d'un écran).
extension ContexteResponsive on BuildContext {
  double get largeurEcran => MediaQuery.sizeOf(this).width;
  TailleEcran get tailleEcran => AppResponsive.depuisLargeur(largeurEcran);
}

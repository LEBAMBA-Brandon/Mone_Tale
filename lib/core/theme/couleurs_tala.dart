import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_couleurs.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/gravite.dart';
import 'package:tala/data/models/statut.dart';

/// Couleurs propres à tala, rangées DANS le thème Flutter.
///
/// Le `ColorScheme` de Material ne connaît que primary, secondary, error…
/// Une `ThemeExtension` permet d'y ajouter nos couleurs "métier" (barre jaune,
/// succès, position de l'utilisateur…) qui changent automatiquement avec le thème.
///
/// Utilisation dans un widget : `context.couleurs.barre`
@immutable
class CouleursTala extends ThemeExtension<CouleursTala> {
  const CouleursTala({
    required this.barre,
    required this.surBarre,
    required this.succes,
    required this.surSucces,
    required this.avertissement,
    required this.surAvertissement,
    required this.positionUtilisateur,
    required this.ombre,
    required this.squelette,
    required this.surfaceFlottante,
  });

  /// Version thème clair (couleurs foncées).
  static const CouleursTala clair = CouleursTala(
    barre: AppCouleurs.jauneFonce,
    surBarre: AppCouleurs.texteSurJaune,
    succes: AppCouleurs.vertFonce,
    surSucces: AppCouleurs.blanc,
    avertissement: Color(0xFFB45309),
    surAvertissement: AppCouleurs.blanc,
    positionUtilisateur: AppCouleurs.positionUtilisateur,
    ombre: Color(0x33000000),
    squelette: Color(0xFFE5E7E2),
    surfaceFlottante: AppCouleurs.blanc,
  );

  /// Version thème sombre (couleurs claires).
  static const CouleursTala sombre = CouleursTala(
    barre: AppCouleurs.jauneClair,
    surBarre: AppCouleurs.texteSurJaune,
    succes: AppCouleurs.vertClair,
    surSucces: AppCouleurs.surVertClair,
    avertissement: Color(0xFFFFB74D),
    surAvertissement: AppCouleurs.texteSurJaune,
    positionUtilisateur: Color(0xFF64B5F6),
    ombre: Color(0x99000000),
    squelette: Color(0xFF2B2E2B),
    surfaceFlottante: Color(0xFF222522),
  );

  /// Fond de l'AppBar et de la barre de navigation (jaune).
  final Color barre;

  /// Texte et icônes posés sur [barre].
  final Color surBarre;

  final Color succes;
  final Color surSucces;
  final Color avertissement;
  final Color surAvertissement;

  /// Point bleu "Vous êtes ici" sur la carte.
  final Color positionUtilisateur;

  /// Ombre des éléments qui flottent au-dessus de la carte.
  final Color ombre;

  /// Couleur des zones "en cours de chargement" (image pas encore reçue…).
  final Color squelette;

  /// Fond des éléments posés SUR la carte (barre de recherche, filtres,
  /// boutons) : blanc en clair, gris très foncé en sombre.
  final Color surfaceFlottante;

  // ---------- Couleurs métier ----------

  Color categorie(Categorie categorie) => switch (categorie) {
    Categorie.voirie => AppCouleurs.voirie,
    Categorie.ordures => AppCouleurs.ordures,
    Categorie.eclairagePublic => AppCouleurs.eclairagePublic,
    Categorie.caniveauInondation => AppCouleurs.caniveauInondation,
    Categorie.autre => AppCouleurs.autre,
  };

  Color gravite(Gravite gravite) => switch (gravite) {
    Gravite.faible => AppCouleurs.graviteFaible,
    Gravite.moyenne => AppCouleurs.graviteMoyenne,
    Gravite.critique => AppCouleurs.graviteCritique,
  };

  Color statut(Statut statut) => switch (statut) {
    Statut.signale => AppCouleurs.statutSignale,
    Statut.enCours => AppCouleurs.statutEnCours,
    Statut.resolu => AppCouleurs.statutResolu,
  };

  /// Choisit automatiquement un texte blanc ou noir lisible sur [fond].
  static Color texteSur(Color fond) =>
      ThemeData.estimateBrightnessForColor(fond) == Brightness.dark
      ? Colors.white
      : AppCouleurs.texteSurJaune;

  /// Éclaircit une couleur sur fond sombre (ex : violet sur noir = peu lisible).
  static Color adapterAuFond(Color couleur, {required bool fondSombre}) =>
      fondSombre ? Color.lerp(couleur, Colors.white, 0.4)! : couleur;

  // ---------- Obligatoire pour une ThemeExtension ----------

  @override
  CouleursTala copyWith({
    Color? barre,
    Color? surBarre,
    Color? succes,
    Color? surSucces,
    Color? avertissement,
    Color? surAvertissement,
    Color? positionUtilisateur,
    Color? ombre,
    Color? squelette,
    Color? surfaceFlottante,
  }) {
    return CouleursTala(
      barre: barre ?? this.barre,
      surBarre: surBarre ?? this.surBarre,
      succes: succes ?? this.succes,
      surSucces: surSucces ?? this.surSucces,
      avertissement: avertissement ?? this.avertissement,
      surAvertissement: surAvertissement ?? this.surAvertissement,
      positionUtilisateur: positionUtilisateur ?? this.positionUtilisateur,
      ombre: ombre ?? this.ombre,
      squelette: squelette ?? this.squelette,
      surfaceFlottante: surfaceFlottante ?? this.surfaceFlottante,
    );
  }

  /// Transition douce entre clair et sombre quand on change de thème.
  @override
  CouleursTala lerp(ThemeExtension<CouleursTala>? other, double t) {
    if (other is! CouleursTala) return this;
    return CouleursTala(
      barre: Color.lerp(barre, other.barre, t)!,
      surBarre: Color.lerp(surBarre, other.surBarre, t)!,
      succes: Color.lerp(succes, other.succes, t)!,
      surSucces: Color.lerp(surSucces, other.surSucces, t)!,
      avertissement: Color.lerp(avertissement, other.avertissement, t)!,
      surAvertissement: Color.lerp(
        surAvertissement,
        other.surAvertissement,
        t,
      )!,
      positionUtilisateur: Color.lerp(
        positionUtilisateur,
        other.positionUtilisateur,
        t,
      )!,
      ombre: Color.lerp(ombre, other.ombre, t)!,
      squelette: Color.lerp(squelette, other.squelette, t)!,
      surfaceFlottante: Color.lerp(
        surfaceFlottante,
        other.surfaceFlottante,
        t,
      )!,
    );
  }
}

/// Raccourcis pour écrire moins de code dans les widgets.
///
/// ⚠️ Noms volontairement en français : GetX ajoute déjà `context.theme`,
/// `context.textTheme`, `context.isDarkMode`… Utiliser les mêmes noms
/// créerait une erreur "ambiguous" à la compilation.
extension ContexteTheme on BuildContext {
  /// Couleurs Material (primary, error, surface…).
  ColorScheme get schema => Theme.of(this).colorScheme;

  /// Styles de texte du thème.
  TextTheme get textes => Theme.of(this).textTheme;

  /// Couleurs tala (barre, succès, catégories…).
  CouleursTala get couleurs =>
      Theme.of(this).extension<CouleursTala>() ??
      (estSombre ? CouleursTala.sombre : CouleursTala.clair);

  /// `true` si le thème sombre est actif.
  bool get estSombre => Theme.of(this).brightness == Brightness.dark;
}

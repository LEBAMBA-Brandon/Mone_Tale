import 'package:flutter/material.dart';
import 'package:mono/data/models/categorie.dart';
import 'package:mono/data/models/gravite.dart';
import 'package:mono/data/models/statut.dart';
import 'package:mono/data/models/type_filtre.dart';

/// Icônes communes de l'application.
abstract final class AppIcons {
  /// Filtre "Tout" (tous les signalements).
  static const IconData tout = Icons.apps_rounded;
  static const IconData autourDeMoi = Icons.my_location;
  static const IconData recherche = Icons.search;
  static const IconData historique = Icons.history;
  static const IconData quartier = Icons.location_city;
  static const IconData periode = Icons.calendar_month_outlined;
  static const IconData menuFerme = Icons.arrow_drop_down;
  static const IconData menuOuvert = Icons.arrow_drop_up;
  static const IconData coche = Icons.check;
}

/// `categorie.icone` → l'icône de la catégorie.
/// (Une "extension" ajoute une propriété à une classe sans la modifier :
/// le modèle de la couche data reste indépendant de l'interface.)
extension IconeCategorie on Categorie {
  IconData get icone => switch (this) {
    Categorie.voirie => Icons.add_road,
    Categorie.ordures => Icons.delete_outline,
    Categorie.eclairagePublic => Icons.lightbulb_outline,
    Categorie.caniveauInondation => Icons.water_drop_outlined,
    Categorie.autre => Icons.report_problem_outlined,
  };
}

extension IconeGravite on Gravite {
  IconData get icone => switch (this) {
    Gravite.faible => Icons.info_outline,
    Gravite.moyenne => Icons.warning_amber_rounded,
    Gravite.critique => Icons.error_outline,
  };
}

extension IconeStatut on Statut {
  IconData get icone => switch (this) {
    Statut.signale => Icons.flag_outlined,
    Statut.enCours => Icons.construction,
    Statut.resolu => Icons.check_circle_outline,
  };
}

extension IconeTypeFiltre on TypeFiltre {
  IconData get icone => switch (this) {
    TypeFiltre.tout => AppIcons.tout,
    TypeFiltre.statut => Icons.flag_outlined,
    TypeFiltre.gravite => Icons.priority_high_rounded,
    TypeFiltre.quartier => AppIcons.quartier,
    TypeFiltre.periode => AppIcons.periode,
  };
}

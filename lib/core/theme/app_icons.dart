import 'package:flutter/material.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/gravite.dart';
import 'package:tala/data/models/role.dart';
import 'package:tala/data/models/statut.dart';

/// Icônes communes de tala, au même endroit : si on veut changer l'icône
/// "Ajouter", on la change ici et toute l'app suit.
abstract final class AppIcons {
  // ---------- Barre de navigation ----------
  // Collecteur : ⚠️ Mes signalements · ➕ Ajouter · 👤 Profil
  // Admin      : ⚠️ Signalements · 👤+ Ajouter · 👥 Collecteurs · 👤 Profil
  // (version "outlined" = onglet inactif, version pleine = onglet actif)
  static const IconData signalements = Icons.warning_amber_rounded;
  static const IconData signalementsActif = Icons.warning_rounded;
  static const IconData ajouter = Icons.add_circle_outline;
  static const IconData ajouterActif = Icons.add_circle;
  static const IconData ajouterCollecteur = Icons.person_add_alt_outlined;
  static const IconData ajouterCollecteurActif = Icons.person_add_alt_1;
  static const IconData collecteurs = Icons.groups_outlined;
  static const IconData collecteursActif = Icons.groups;
  static const IconData profil = Icons.person_outline;
  static const IconData profilActif = Icons.person;

  // ---------- Formulaires ----------
  static const IconData email = Icons.alternate_email;
  static const IconData motDePasse = Icons.lock_outline;
  static const IconData afficher = Icons.visibility_outlined;
  static const IconData masquer = Icons.visibility_off_outlined;
  static const IconData nom = Icons.badge_outlined;
  static const IconData description = Icons.notes;
  static const IconData quartier = Icons.location_city;
  static const IconData position = Icons.my_location;
  static const IconData photo = Icons.photo_camera_outlined;
  static const IconData galerie = Icons.photo_library_outlined;
  static const IconData reprendre = Icons.cameraswitch_outlined;

  // ---------- Actions ----------
  static const IconData envoyer = Icons.send_rounded;
  static const IconData enregistrer = Icons.check;
  static const IconData modifier = Icons.edit_outlined;
  static const IconData supprimer = Icons.delete_outline;
  static const IconData deconnexion = Icons.logout;
  static const IconData themeClair = Icons.light_mode_outlined;
  static const IconData themeSombre = Icons.dark_mode_outlined;
  static const IconData themeSysteme = Icons.brightness_auto_outlined;
  static const IconData suivant = Icons.chevron_right;

  // ---------- Profil ----------
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData aide = Icons.help_outline;
  static const IconData conditions = Icons.gavel_outlined;
  static const IconData confidentialite = Icons.privacy_tip_outlined;
  static const IconData partager = Icons.share_outlined;

  // ---------- Infos ----------
  static const IconData date = Icons.event_outlined;
  static const IconData auteur = Icons.person_outline;
  static const IconData tout = Icons.apps_rounded;
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

extension IconeRole on Role {
  IconData get icone => switch (this) {
    Role.admin => Icons.admin_panel_settings_outlined,
    Role.collecteur => Icons.badge_outlined,
  };
}

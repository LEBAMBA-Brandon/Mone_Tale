import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_responsive.dart';

/// Un onglet de la barre de navigation.
class OngletNavigation {
  const OngletNavigation({
    required this.libelle,
    required this.icone,
    required this.iconeActive,
    this.compteur,
  });

  final String libelle;

  /// Icône "contour" (onglet inactif) et icône pleine (onglet actif).
  final IconData icone;
  final IconData iconeActive;

  /// Pastille avec un nombre sur l'icône (`null` ou 0 = pas de pastille).
  final int? compteur;
}

/// Barre de navigation JAUNE en bas de l'écran (couleurs dans app_theme).
///
/// La MÊME barre sert au collecteur (3 onglets) et à l'admin (4 onglets) :
/// seule la liste [onglets] change.
/// ```dart
/// BarreNavigation(
///   indexActif: controller.onglet.value,
///   onChange: controller.changerOnglet,
///   onglets: const [
///     OngletNavigation(libelle: 'Mes signalements', icone: AppIcons.signalements, iconeActive: AppIcons.signalementsActif),
///     OngletNavigation(libelle: 'Ajouter', icone: AppIcons.ajouter, iconeActive: AppIcons.ajouterActif),
///     OngletNavigation(libelle: 'Compte', icone: AppIcons.compte, iconeActive: AppIcons.compteActif),
///   ],
/// )
/// ```
class BarreNavigation extends StatelessWidget {
  const BarreNavigation({
    super.key,
    required this.onglets,
    required this.indexActif,
    required this.onChange,
  });

  final List<OngletNavigation> onglets;
  final int indexActif;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    // Écran minuscule : seul l'onglet actif garde son texte, sinon les
    // 4 libellés de l'admin se chevaucheraient.
    final minuscule = context.tailleEcran == TailleEcran.minuscule;

    return NavigationBar(
      selectedIndex: indexActif,
      onDestinationSelected: onChange,
      labelBehavior: minuscule
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final onglet in onglets)
          NavigationDestination(
            tooltip: onglet.libelle,
            label: onglet.libelle,
            icon: _avecCompteur(Icon(onglet.icone), onglet.compteur),
            selectedIcon: _avecCompteur(
              Icon(onglet.iconeActive),
              onglet.compteur,
            ),
          ),
      ],
    );
  }

  Widget _avecCompteur(Widget icone, int? compteur) {
    if (compteur == null || compteur <= 0) return icone;
    return Badge(
      label: Text(compteur > 99 ? '99+' : '$compteur'),
      child: icone,
    );
  }
}

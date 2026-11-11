import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_responsive.dart';

/// Un onglet de la navigation.
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

/// Navigation ADAPTATIVE de tala : elle change de forme selon la largeur.
///
/// - Téléphone (< 1024 px) : barre JAUNE en bas (NavigationBar).
/// - Ordinateur / grand écran (≥ 1024 px) : barre JAUNE sur le CÔTÉ
///   gauche (NavigationRail). Le contenu prend alors toute la largeur
///   restante, au lieu d'une barre étirée sur 1500 px avec 4 icônes
///   perdues au milieu.
///
/// C'est le principe "Material adaptive" de Google : même app, même code,
/// mais la navigation se place là où elle est la plus pratique.
///
/// ```dart
/// NavigationAdaptative(
///   onglets: [...],
///   indexActif: controller.onglet.value,
///   onChange: controller.changerOnglet,
///   child: IndexedStack(...),
/// )
/// ```
class NavigationAdaptative extends StatelessWidget {
  const NavigationAdaptative({
    super.key,
    required this.onglets,
    required this.indexActif,
    required this.onChange,
    required this.child,
  });

  final List<OngletNavigation> onglets;
  final int indexActif;
  final ValueChanged<int> onChange;

  /// Contenu de l'onglet actif.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final taille = context.tailleEcran;

    // ---------- Grand écran : barre sur le côté ----------
    if (taille == TailleEcran.large) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: indexActif,
              onDestinationSelected: onChange,
              // Libellés à côté des icônes : il y a la place.
              extended: context.largeurEcran >= 1280,
              labelType: context.largeurEcran >= 1280
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              groupAlignment: -0.9, // onglets en haut
              destinations: [
                for (final onglet in onglets)
                  NavigationRailDestination(
                    icon: _avecCompteur(Icon(onglet.icone), onglet.compteur),
                    selectedIcon: _avecCompteur(
                      Icon(onglet.iconeActive),
                      onglet.compteur,
                    ),
                    label: Text(onglet.libelle),
                  ),
              ],
            ),
            // Expanded : le contenu prend TOUTE la largeur restante.
            Expanded(child: child),
          ],
        ),
      );
    }

    // ---------- Téléphone / tablette : barre en bas ----------
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: indexActif,
        onDestinationSelected: onChange,
        // Écran minuscule : seul l'onglet actif garde son texte, sinon les
        // 4 libellés de l'admin se chevaucheraient.
        labelBehavior: taille == TailleEcran.minuscule
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
      ),
    );
  }

  static Widget _avecCompteur(Widget icone, int? compteur) {
    if (compteur == null || compteur <= 0) return icone;
    return Badge(
      label: Text(compteur > 99 ? '99+' : '$compteur'),
      child: icone,
    );
  }
}

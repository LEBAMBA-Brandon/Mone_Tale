import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';

/// Liste déroulante AVEC RECHERCHE (ex : choisir le quartier).
///
/// On peut toucher pour dérouler la liste, ou taper "nze" pour ne garder
/// que "Nzeng-Ayong" : pratique quand il y a des dizaines de quartiers.
///
/// Générique (`<T>`) : marche avec des Quartier, des Commune, etc.
/// ```dart
/// ChampListe<Quartier>(
///   libelle: 'Quartier',
///   options: controller.quartiers,
///   valeur: controller.quartier.value,
///   libelleOption: (q) => q.nom,
///   onChoix: controller.choisirQuartier,
/// )
/// ```
class ChampListe<T> extends StatelessWidget {
  const ChampListe({
    super.key,
    required this.libelle,
    required this.options,
    required this.libelleOption,
    required this.onChoix,
    this.valeur,
    this.icone,
    this.erreur,
    this.actif = true,
  });

  final String libelle;
  final List<T> options;
  final String Function(T option) libelleOption;
  final ValueChanged<T?> onChoix;
  final T? valeur;
  final IconData? icone;
  final String? erreur;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      // Quand la valeur change "de l'extérieur" (ex : dernier quartier
      // pré-rempli), une nouvelle clé force le champ à l'afficher.
      key: ValueKey(valeur),
      initialSelection: valeur,
      enabled: actif,
      label: Text(libelle),
      leadingIcon: icone == null ? null : Icon(icone),
      errorText: erreur,
      // Prend toute la largeur disponible (comme les autres champs).
      expandedInsets: EdgeInsets.zero,
      // Liste pas trop haute : le clavier prend déjà de la place.
      menuHeight: 280,
      // Permet de taper pour filtrer la liste.
      enableFilter: true,
      requestFocusOnTap: true,
      onSelected: onChoix,
      dropdownMenuEntries: [
        for (final option in options)
          DropdownMenuEntry<T>(
            value: option,
            label: libelleOption(option),
            style: MenuItemButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppEspacements.l),
            ),
          ),
      ],
    );
  }
}

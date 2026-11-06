import 'package:flutter/material.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_icons.dart';
import 'package:mono/core/theme/couleurs_mono.dart';

/// Puce qui ouvre une liste déroulante (ex : "Tout ▾").
///
/// Elle a la même forme que les puces de filtre, mais en couleur pleine
/// pour bien la distinguer : c'est elle qui décide quelles puces sont
/// affichées à côté.
///
/// `<T>` = widget "générique" : il marche avec n'importe quel type de
/// valeur (ici TypeFiltre, mais il pourrait servir pour autre chose).
class PuceMenu<T> extends StatelessWidget {
  const PuceMenu({
    super.key,
    required this.valeur,
    required this.options,
    required this.libelle,
    required this.icone,
    required this.onChoix,
    this.titre = 'Filtrer par',
    this.compacte = false,
  });

  /// Option actuellement choisie.
  final T valeur;

  /// Toutes les options de la liste.
  final List<T> options;

  /// Comment afficher une option (texte et icône).
  final String Function(T option) libelle;
  final IconData Function(T option) icone;

  final ValueChanged<T> onChoix;

  /// Début de l'info-bulle : "Filtrer par : Tout".
  final String titre;

  /// true → seulement l'icône et la flèche (écrans minuscules).
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    final couleurTexte = schema.onPrimaryContainer;

    // MenuAnchor = un bouton + un menu qui s'ouvre juste en dessous.
    return MenuAnchor(
      alignmentOffset: const Offset(0, AppEspacements.xs),
      menuChildren: [
        for (final option in options)
          MenuItemButton(
            leadingIcon: Icon(icone(option), size: AppTailles.iconeM),
            // Coche devant l'option déjà choisie.
            trailingIcon: option == valeur
                ? Icon(
                    AppIcons.coche,
                    size: AppTailles.iconeM,
                    color: schema.primary,
                  )
                : null,
            onPressed: () => onChoix(option), // le menu se ferme tout seul
            child: Text(
              libelle(option),
              style: option == valeur
                  ? TextStyle(
                      color: schema.primary,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
          ),
      ],
      // `menu` permet d'ouvrir/fermer le menu. Le builder est relancé à
      // chaque ouverture/fermeture → la flèche change de sens.
      builder: (context, menu, child) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: ActionChip(
          tooltip: '$titre : ${libelle(valeur)}',
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
          elevation: 1,
          shadowColor: context.couleurs.ombre,
          backgroundColor: schema.primaryContainer,
          side: BorderSide(color: schema.primary),
          avatar: Icon(
            icone(valeur),
            size: AppTailles.iconeS + 2,
            color: couleurTexte,
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compacte)
                // Flexible + ellipsis : un libellé trop long est coupé avec "…"
                // au lieu de déborder (pas de bandes jaunes et noires).
                Flexible(
                  child: Text(
                    libelle(valeur),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Icon(
                menu.isOpen ? AppIcons.menuOuvert : AppIcons.menuFerme,
                size: AppTailles.iconeM,
                color: couleurTexte,
              ),
            ],
          ),
          labelStyle: context.textes.labelLarge?.copyWith(
            color: couleurTexte,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

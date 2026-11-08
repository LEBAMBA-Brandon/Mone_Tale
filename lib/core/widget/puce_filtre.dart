import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/couleurs_tala.dart';

/// Puce de filtre sous la barre de recherche ("Tout", "Voirie", "Ordures"…).
///
/// - Sélectionnée → remplie avec [couleur] (la couleur de la catégorie),
///   texte blanc ou noir choisi automatiquement pour rester lisible.
/// - Non sélectionnée → fond blanc/gris foncé, icône de la couleur.
/// - Largeur max 200 px : un libellé trop long est coupé avec "…".
class PuceFiltre extends StatelessWidget {
  const PuceFiltre({
    super.key,
    required this.libelle,
    required this.selectionnee,
    required this.onSelection,
    this.icone,
    this.couleur,
  });

  final String libelle;
  final bool selectionnee;
  final VoidCallback onSelection;
  final IconData? icone;

  /// Couleur de la catégorie (par défaut : le vert de l'application).
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    final couleurActive = couleur ?? schema.primary;
    final texteActif = CouleursTala.texteSur(couleurActive);
    // Sur fond sombre, on éclaircit l'icône pour qu'elle reste visible.
    final couleurIcone = CouleursTala.adapterAuFond(
      couleurActive,
      fondSombre: context.estSombre,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: FilterChip(
        selected: selectionnee,
        onSelected: (_) => onSelection(),
        showCheckmark: false,
        tooltip: libelle,
        elevation: 1,
        shadowColor: context.couleurs.ombre,
        backgroundColor: context.couleurs.surfaceFlottante,
        selectedColor: couleurActive,
        side: BorderSide(
          color: selectionnee ? couleurActive : schema.outlineVariant,
        ),
        avatar: icone == null
            ? null
            : Icon(
                icone,
                size: AppTailles.iconeS + 2,
                color: selectionnee ? texteActif : couleurIcone,
              ),
        label: Text(libelle, maxLines: 1, overflow: TextOverflow.ellipsis),
        labelStyle: context.textes.labelLarge?.copyWith(
          color: selectionnee ? texteActif : schema.onSurface,
        ),
      ),
    );
  }
}

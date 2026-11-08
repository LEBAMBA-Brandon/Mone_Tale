import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/puce_filtre.dart';

/// Un titre + des puces pour choisir UNE valeur parmi quelques-unes
/// (catégorie, gravité, statut).
///
/// Plus rapide qu'une liste déroulante sur le terrain : tout est visible,
/// un seul appui suffit. Les puces passent à la ligne toutes seules (Wrap),
/// donc ça marche aussi sur un écran de 150 px.
/// ```dart
/// SelecteurChoix<Categorie>(
///   titre: 'Catégorie',
///   options: Categorie.values,
///   valeur: controller.categorie.value,
///   libelle: (c) => c.libelle,
///   icone: (c) => c.icone,
///   couleur: (c) => context.couleurs.categorie(c),
///   onChoix: controller.choisirCategorie,
///   erreur: controller.erreurs['categorie'],
/// )
/// ```
class SelecteurChoix<T> extends StatelessWidget {
  const SelecteurChoix({
    super.key,
    required this.titre,
    required this.options,
    required this.libelle,
    required this.onChoix,
    this.valeur,
    this.icone,
    this.couleur,
    this.erreur,
  });

  final String titre;
  final List<T> options;
  final String Function(T option) libelle;
  final ValueChanged<T> onChoix;
  final T? valeur;
  final IconData Function(T option)? icone;

  /// Couleur de chaque puce (ex : couleur de la catégorie).
  final Color Function(T option)? couleur;
  final String? erreur;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    final erreur = this.erreur;

    // Semantics : le lecteur d'écran annonce "Catégorie" avant les puces.
    return Semantics(
      container: true,
      label: titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: context.textes.titleSmall?.copyWith(
              color: erreur == null ? schema.onSurface : schema.error,
            ),
          ),
          const SizedBox(height: AppEspacements.s),
          Wrap(
            spacing: AppEspacements.s,
            runSpacing: AppEspacements.s,
            children: [
              for (final option in options)
                PuceFiltre(
                  libelle: libelle(option),
                  icone: icone?.call(option),
                  couleur: couleur?.call(option),
                  selectionnee: option == valeur,
                  onSelection: () => onChoix(option),
                ),
            ],
          ),
          if (erreur != null) ...[
            const SizedBox(height: AppEspacements.xs),
            Text(
              erreur,
              style: context.textes.bodySmall?.copyWith(color: schema.error),
            ),
          ],
        ],
      ),
    );
  }
}

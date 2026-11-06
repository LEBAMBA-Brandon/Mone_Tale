import 'package:flutter/material.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/couleurs_mono.dart';

/// Une ligne de la fiche détail : icône + libellé + valeur.
/// (Description, Catégorie, Gravité, Quartier, Auteur, Date, Statut)
///
/// - Large (≥ 300 px) : libellé à gauche, valeur à droite.
/// - Étroit (< 300 px) : libellé AU-DESSUS de la valeur.
/// - La valeur peut être un texte ([valeur]) ou un widget ([enfant], ex : un badge).
///
/// ⚠️ À placer dans un parent à largeur limitée (Column, ListView…).
class LigneInfo extends StatelessWidget {
  const LigneInfo({
    super.key,
    required this.icone,
    required this.libelle,
    this.valeur,
    this.enfant,
    this.maxLignes,
  }) : assert(valeur != null || enfant != null, 'Donner valeur OU enfant');

  final IconData icone;
  final String libelle;
  final String? valeur;
  final Widget? enfant;

  /// `null` = texte complet (ex : la description). Sinon coupé avec "…".
  final int? maxLignes;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;

    final pastilleIcone = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: schema.primaryContainer,
        borderRadius: BorderRadius.circular(AppRayons.s),
      ),
      child: Icon(
        icone,
        size: AppTailles.iconeM,
        color: schema.onPrimaryContainer,
      ),
    );

    final titre = Text(
      libelle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textes.labelLarge?.copyWith(
        color: schema.onSurfaceVariant,
      ),
    );

    final contenu =
        enfant ??
        Text(
          valeur!,
          maxLines: maxLignes,
          overflow: maxLignes == null ? null : TextOverflow.ellipsis,
          style: context.textes.bodyLarge,
        );

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppEspacements.s),
        child: LayoutBuilder(
          builder: (context, contraintes) {
            final empile = contraintes.maxWidth < 300;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pastilleIcone,
                const SizedBox(width: AppEspacements.m),
                if (empile)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titre,
                        const SizedBox(height: AppEspacements.xxs),
                        contenu,
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    width: 110,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppEspacements.s),
                      child: titre,
                    ),
                  ),
                  const SizedBox(width: AppEspacements.s),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppEspacements.s - 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: contenu,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

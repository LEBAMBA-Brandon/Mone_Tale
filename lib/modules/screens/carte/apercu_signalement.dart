import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_formats.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/badge_info.dart';
import 'package:mono/core/widget/image_reseau.dart';
import 'package:mono/data/models/signalement.dart';
import 'package:mono/modules/controller/carte_controller.dart';

/// Carte d'aperçu en bas de l'écran (comme Google Maps) après un appui sur
/// une épingle. Un appui sur l'aperçu ouvre le détail complet.
///
/// Sous 260 px de large, la miniature de la photo est masquée.
class ApercuSignalement extends GetView<CarteController> {
  const ApercuSignalement({super.key, required this.signalement});

  final Signalement signalement;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    final description = signalement.description.isEmpty
        ? 'Sans description'
        : signalement.description;

    return Semantics(
      button: true,
      label: 'Voir le détail du signalement',
      child: Material(
        color: context.couleurs.surfaceFlottante,
        elevation: 4,
        shadowColor: context.couleurs.ombre,
        borderRadius: BorderRadius.circular(AppRayons.l),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => controller.ouvrirDetail(signalement),
          child: LayoutBuilder(
            builder: (context, contraintes) {
              final avecPhoto = contraintes.maxWidth >= 260;
              return Padding(
                padding: const EdgeInsets.all(AppEspacements.m),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (avecPhoto) ...[
                      SizedBox.square(
                        dimension: 84,
                        child: ImageReseau(
                          url: signalement.photoUrl,
                          ratio: null,
                          rayon: AppRayons.m,
                          description: 'Photo du signalement',
                        ),
                      ),
                      const SizedBox(width: AppEspacements.m),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wrap : les badges passent à la ligne s'il manque de place.
                          Wrap(
                            spacing: AppEspacements.xs + 2,
                            runSpacing: AppEspacements.xs,
                            children: [
                              BadgeCategorie(signalement.categorie),
                              BadgeStatut(signalement.statut),
                            ],
                          ),
                          const SizedBox(height: AppEspacements.s),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textes.titleSmall,
                          ),
                          const SizedBox(height: AppEspacements.xs),
                          Text(
                            '${signalement.nomQuartier} · '
                            '${AppFormats.depuis(signalement.dateCreation)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textes.bodySmall?.copyWith(
                              color: schema.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Fermer l'aperçu",
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close),
                          onPressed: controller.deselectionner,
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: schema.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

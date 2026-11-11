import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/puce_filtre.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/module/controller/detail_signalement_controller.dart';

/// Panneau "Gestion" de l'admin en bas du détail :
/// - 3 puces pour changer le statut (Signalé → En cours → Résolu) ;
/// - bouton rouge "Supprimer".
class PanneauAdmin extends GetView<DetailSignalementController> {
  const PanneauAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;

    return Obx(() {
      final actuel = controller.signalement.value?.statut;
      final enCours = controller.statutEnCours.value;
      final suppression = controller.suppressionEnCours.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestion', style: context.textes.titleMedium),
          const SizedBox(height: AppEspacements.s),
          Text(
            'Statut',
            style: context.textes.labelLarge?.copyWith(
              color: schema.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppEspacements.xs),
          Wrap(
            spacing: AppEspacements.s,
            runSpacing: AppEspacements.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final statut in Statut.values)
                PuceFiltre(
                  libelle: statut.libelle,
                  icone: statut.icone,
                  couleur: context.couleurs.statut(statut),
                  selectionnee: actuel == statut,
                  // Ignoré pendant un envoi (un changement à la fois).
                  onSelection: () => controller.changerStatut(statut),
                ),
              if (enCours != null)
                const SizedBox.square(
                  dimension: AppTailles.iconeM,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppEspacements.l),
          OutlinedButton.icon(
            onPressed: suppression ? null : controller.supprimer,
            style: OutlinedButton.styleFrom(
              foregroundColor: schema.error,
              side: BorderSide(color: schema.error),
              minimumSize: const Size.fromHeight(AppTailles.toucheMin),
            ),
            icon: suppression
                ? const SizedBox.square(
                    dimension: AppTailles.iconeM,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.supprimer),
            label: const Text('Supprimer ce signalement'),
          ),
        ],
      );
    });
  }
}

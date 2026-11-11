import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/data/models/gravite.dart';
import 'package:tala/module/controller/ajout_signalement_controller.dart';
import 'package:tala/module/screens/commun/mini_carte.dart';

/// Zone "Position" du formulaire :
/// - recherche GPS en cours → message + cercle ;
/// - position trouvée → petite carte + précision ("GPS ±12 m") ;
/// - GPS imprécis (> 30 m) → avertissement "vérifiez la position" ;
/// - toujours 2 boutons : relancer le GPS, ou ajuster sur la carte.
class SectionPosition extends GetView<AjoutSignalementController> {
  const SectionPosition({super.key});

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;

    return Obx(() {
      final position = controller.brouillon.value.position;
      final gps = controller.positionGps.value;
      final enCours = controller.localisationEnCours.value;
      final manuelle = controller.positionManuelle.value;
      final erreur = controller.erreurs['latitude'];

      final String texteEtat;
      if (enCours) {
        texteEtat = 'Recherche de votre position…';
      } else if (position == null) {
        texteEtat = 'Position inconnue';
      } else if (manuelle) {
        texteEtat = 'Position placée sur la carte';
      } else {
        texteEtat = 'Position GPS ${gps?.precisionLisible ?? ''}'.trim();
      }
      final imprecise = !manuelle && (gps?.estImprecise ?? false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Position',
            style: context.textes.titleSmall?.copyWith(
              color: erreur == null ? schema.onSurface : schema.error,
            ),
          ),
          const SizedBox(height: AppEspacements.s),

          // Aperçu : la carte si on a une position, sinon un cadre vide.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRayons.l),
            child: SizedBox(
              height: AppTailles.miniCarte * 0.7,
              child: position == null
                  ? ColoredBox(
                      color: context.couleurs.squelette,
                      child: Center(
                        child: enCours
                            ? const CircularProgressIndicator()
                            : Icon(
                                Icons.location_off_outlined,
                                size: AppTailles.iconeXl,
                                color: schema.onSurfaceVariant,
                              ),
                      ),
                    )
                  : MiniCarte(
                      point: position,
                      categorie: controller.brouillon.value.categorie,
                      critique:
                          controller.brouillon.value.gravite == Gravite.critique,
                    ),
            ),
          ),
          const SizedBox(height: AppEspacements.s),

          Row(
            children: [
              Icon(
                manuelle ? Icons.touch_app_outlined : AppIcons.position,
                size: AppTailles.iconeM,
                color: imprecise ? context.couleurs.avertissement : schema.primary,
              ),
              const SizedBox(width: AppEspacements.s),
              Expanded(
                child: Text(
                  texteEtat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textes.bodyMedium,
                ),
              ),
            ],
          ),
          if (imprecise)
            Padding(
              padding: const EdgeInsets.only(top: AppEspacements.xs),
              child: Text(
                'Position approximative : vérifiez-la sur la carte.',
                style: context.textes.bodySmall?.copyWith(
                  color: context.couleurs.avertissement,
                ),
              ),
            ),
          if (erreur != null)
            Padding(
              padding: const EdgeInsets.only(top: AppEspacements.xs),
              child: Text(
                erreur,
                style: context.textes.bodySmall?.copyWith(color: schema.error),
              ),
            ),
          const SizedBox(height: AppEspacements.s),

          // Wrap : les 2 boutons passent l'un sous l'autre si l'écran est étroit.
          Wrap(
            spacing: AppEspacements.s,
            runSpacing: AppEspacements.xs,
            children: [
              OutlinedButton.icon(
                onPressed: enCours ? null : controller.localiser,
                icon: const Icon(AppIcons.position),
                label: const Text('GPS'),
              ),
              OutlinedButton.icon(
                onPressed: controller.ajusterPosition,
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Ajuster sur la carte'),
              ),
            ],
          ),
        ],
      );
    });
  }
}

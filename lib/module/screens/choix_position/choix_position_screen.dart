import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/bouton_carte.dart';
import 'package:tala/core/widget/bouton_principal.dart';
import 'package:tala/core/widget/marqueur_signalement.dart';
import 'package:tala/core/widget/tuiles_carte.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/module/controller/choix_position_controller.dart';

/// Carte plein écran pour placer le signalement à la main.
///
/// L'épingle reste FIXE au centre ; on fait glisser la carte dessous,
/// puis "Valider cette position".
class ChoixPositionScreen extends GetView<ChoixPositionController> {
  const ChoixPositionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final depart = controller.depart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placer le signalement'),
        leading: IconButton(
          tooltip: 'Annuler',
          icon: const Icon(Icons.close),
          onPressed: controller.annuler,
        ),
      ),
      body: Stack(
        children: [
          // 1) La carte (elle bouge).
          Positioned.fill(
            child: FlutterMap(
              mapController: controller.carte,
              options: MapOptions(
                initialCenter: LatLng(depart.latitude, depart.longitude),
                initialZoom: ChoixPositionController.zoomInitial,
                minZoom: 5,
                maxZoom: 19,
                backgroundColor: context.couleurs.squelette,
                // Pas de rotation : la carte reste orientée vers le nord.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (camera, parUnGeste) =>
                    controller.surDeplacement(camera),
              ),
              children: const [
                TuilesCarte(),
                AttributionCarte(alignement: AttributionAlignment.bottomLeft),
              ],
            ),
          ),

          // 2) L'épingle FIXE au centre. IgnorePointer : les doigts passent
          //    "à travers" pour faire glisser la carte.
          IgnorePointer(
            child: Center(
              // On remonte l'épingle de la moitié de sa taille : c'est sa
              // POINTE (en bas) qui doit être au centre, pas son milieu.
              child: Transform.translate(
                offset: const Offset(0, -AppTailles.marqueur / 2),
                child: const MarqueurSignalement(
                  categorie: Categorie.autre,
                  selectionne: true,
                ),
              ),
            ),
          ),

          // 3) Consigne en haut.
          Positioned(
            top: AppEspacements.m,
            left: AppEspacements.m,
            right: AppEspacements.m,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppEspacements.m),
                child: Text(
                  "Faites glisser la carte pour mettre la pointe de l'épingle "
                  'sur le problème.',
                  textAlign: TextAlign.center,
                  style: context.textes.bodyMedium,
                ),
              ),
            ),
          ),

          // 4) En bas : recentrer sur le GPS + valider.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppEspacements.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Obx(
                      () => BoutonCarte(
                        icone: AppIcons.position,
                        infobulle: 'Ma position',
                        chargement: controller.localisationEnCours.value,
                        onPressed: controller.recentrer,
                      ),
                    ),
                    const SizedBox(height: AppEspacements.m),
                    BoutonPrincipal(
                      libelle: 'Valider cette position',
                      icone: AppIcons.enregistrer,
                      pleineLargeur: true,
                      onPressed: controller.valider,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

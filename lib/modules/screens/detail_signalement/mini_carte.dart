import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/marqueur_signalement.dart';
import 'package:mono/core/widget/tuiles_carte.dart';
import 'package:mono/data/models/gravite.dart';
import 'package:mono/data/models/signalement.dart';

/// Petite carte figée en haut du détail, centrée sur le signalement.
class MiniCarte extends StatelessWidget {
  const MiniCarte({
    super.key,
    required this.signalement,
    this.partieCachee = 0,
  });

  final Signalement signalement;

  /// Hauteur du bas de la carte recouverte par la feuille de détail
  /// (pour remonter la mention OpenStreetMap et la garder visible).
  final double partieCachee;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(signalement.latitude, signalement.longitude);
    const zone = AppTailles.marqueur * 1.3;

    return FlutterMap(
      // Nouvelle clé = nouvelle carte, bien centrée si le signalement change.
      key: ValueKey(signalement.id),
      options: MapOptions(
        initialCenter: point,
        initialZoom: 16,
        backgroundColor: context.couleurs.squelette,
        // Carte "photo" : ni déplacement ni zoom (c'est un aperçu).
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        const TuilesCarte(),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: zone,
              height: zone,
              alignment: Alignment.topCenter,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MarqueurSignalement(
                  categorie: signalement.categorie,
                  selectionne: true,
                  critique: signalement.gravite == Gravite.critique,
                ),
              ),
            ),
          ],
        ),
        AttributionCarte(
          alignement: AttributionAlignment.bottomRight,
          decalageBas: partieCachee,
        ),
      ],
    );
  }
}

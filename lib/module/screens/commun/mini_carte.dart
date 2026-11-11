import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/marqueur_signalement.dart';
import 'package:tala/core/widget/tuiles_carte.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/coordonnees.dart';

/// Petite carte FIGÉE centrée sur un point (aperçu, pas de déplacement).
///
/// Sert à 2 endroits :
/// - le formulaire "Ajouter" (où sera placé le signalement) ;
/// - la page détail d'un signalement.
class MiniCarte extends StatelessWidget {
  const MiniCarte({
    super.key,
    required this.point,
    this.categorie,
    this.critique = false,
    this.partieCachee = 0,
  });

  final Coordonnees point;

  /// Couleur et icône de l'épingle (`null` = pas encore choisie).
  final Categorie? categorie;
  final bool critique;

  /// Hauteur du bas de la carte recouverte par autre chose (pour garder
  /// la mention OpenStreetMap visible).
  final double partieCachee;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(point.latitude, point.longitude);
    const zone = AppTailles.marqueur * 1.3;

    return FlutterMap(
      // Nouvelle clé = nouvelle carte, bien centrée quand le point change.
      key: ValueKey(point),
      options: MapOptions(
        initialCenter: position,
        initialZoom: 16,
        backgroundColor: context.couleurs.squelette,
        // Carte "photo" : ni déplacement ni zoom.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        const TuilesCarte(),
        MarkerLayer(
          markers: [
            Marker(
              point: position,
              width: zone,
              height: zone,
              // La POINTE de l'épingle sur le point exact.
              alignment: Alignment.topCenter,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MarqueurSignalement(
                  categorie: categorie ?? Categorie.autre,
                  selectionne: true,
                  critique: critique,
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

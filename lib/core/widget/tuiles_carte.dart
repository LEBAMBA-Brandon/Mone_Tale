import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tala/core/theme/couleurs_tala.dart';

/// Fond de carte OpenStreetMap, pour les petites cartes de tala :
/// choix de la position dans "Ajouter un signalement" et page détail.
///
/// ⚠️ Règles d'utilisation d'OpenStreetMap (gratuit) :
/// 1. identifier l'application ([_identifiantApp]) ;
/// 2. afficher la mention "© Contributeurs OpenStreetMap" ([AttributionCarte]).
class TuilesCarte extends StatelessWidget {
  const TuilesCarte({super.key});

  static const String _adresseTuiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  /// ⚠️ Mets ici le `applicationId` de android/app/build.gradle.kts.
  static const String _identifiantApp = 'com.example.tala';

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: _adresseTuiles,
      userAgentPackageName: _identifiantApp,
      maxNativeZoom: 19,
      // Thème sombre : couleurs des tuiles inversées (carte "de nuit").
      tileBuilder: context.estSombre ? darkModeTileBuilder : null,
    );
  }
}

/// Mention obligatoire "© Contributeurs OpenStreetMap".
class AttributionCarte extends StatelessWidget {
  const AttributionCarte({
    super.key,
    this.alignement = AttributionAlignment.bottomLeft,
    this.decalageBas = 0,
  });

  final AttributionAlignment alignement;

  /// Remonte la mention si quelque chose recouvre le bas de la carte.
  final double decalageBas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: decalageBas),
      child: RichAttributionWidget(
        alignment: alignement,
        showFlutterMapAttribution: false,
        attributions: const [
          TextSourceAttribution('Contributeurs OpenStreetMap'),
        ],
      ),
    );
  }
}

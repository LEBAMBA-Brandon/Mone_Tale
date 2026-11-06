import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/marqueur_signalement.dart';
import 'package:mono/core/widget/marqueur_user.dart';
import 'package:mono/core/widget/tuiles_carte.dart';
import 'package:mono/data/models/gravite.dart';
import 'package:mono/modules/controller/carte_controller.dart';

/// La carte OpenStreetMap avec les signalements (regroupés) et la position.
class CarteFond extends GetView<CarteController> {
  const CarteFond({super.key});

  /// Zone tactile autour de chaque épingle (un peu plus grande que l'épingle,
  /// pour laisser la place à l'animation de sélection).
  static const double _zoneMarqueur = AppTailles.marqueur * 1.3;

  @override
  Widget build(BuildContext context) {
    final centre = controller.centreInitial;

    return FlutterMap(
      mapController: controller.carte,
      options: MapOptions(
        initialCenter: LatLng(centre.latitude, centre.longitude),
        initialZoom: CarteController.zoomInitial,
        minZoom: CarteController.zoomMin,
        maxZoom: CarteController.zoomMax,
        backgroundColor: context.couleurs.squelette,
        onMapReady: controller.carteEstPrete,
        onTap: (position, point) => controller.toucherCarte(),
        // Pas de rotation : une carte qui tourne désoriente l'utilisateur.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        const TuilesCarte(),
        Obx(() => MarkerClusterLayerWidget(options: _optionsGroupes())),
        Obx(() {
          final position = controller.positionUtilisateur.value;
          if (position == null) return const SizedBox.shrink();
          return MarkerLayer(
            markers: [
              Marker(
                point: LatLng(position.latitude, position.longitude),
                width: 60,
                height: 60,
                child: const MarqueurUtilisateur(),
              ),
            ],
          );
        }),
        const AttributionCarte(),
      ],
    );
  }

  MarkerClusterLayerOptions _optionsGroupes() {
    final idSelection = controller.selection.value?.id;

    return MarkerClusterLayerOptions(
      markers: [
        for (final s in controller.signalements)
          Marker(
            // La clé permet de retrouver le signalement lors d'un appui.
            key: ValueKey<int>(s.id),
            point: LatLng(s.latitude, s.longitude),
            width: _zoneMarqueur,
            height: _zoneMarqueur,
            // topCenter = l'épingle est AU-DESSUS du point : sa pointe
            // touche la position exacte.
            alignment: Alignment.topCenter,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MarqueurSignalement(
                categorie: s.categorie,
                selectionne: s.id == idSelection,
                critique: s.gravite == Gravite.critique,
              ),
            ),
          ),
      ],
      // Regroupement : rayon en pixels dans lequel les épingles fusionnent.
      maxClusterRadius: 60,
      size: const Size(48, 48),
      // À partir de ce zoom, plus aucun regroupement.
      disableClusteringAtZoom: 17,
      maxZoom: CarteController.zoomMax,
      padding: const EdgeInsets.all(64),
      showPolygon: false,
      // Appui sur une bulle → zoom sur son contenu.
      zoomToBoundsOnClick: true,
      centerMarkerOnClick: false,
      onMarkerTap: (marqueur) {
        final cle = marqueur.key;
        if (cle is ValueKey<int>) controller.selectionnerParId(cle.value);
      },
      builder: (context, marqueurs) => _BulleGroupe(nombre: marqueurs.length),
    );
  }
}

/// Bulle verte "12" qui remplace plusieurs épingles proches.
class _BulleGroupe extends StatelessWidget {
  const _BulleGroupe({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    return Semantics(
      label: '$nombre signalements regroupés. Touchez pour zoomer.',
      button: true,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppEspacements.s - 2),
        decoration: BoxDecoration(
          color: schema.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: context.couleurs.ombre,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // FittedBox : "999+" rétrécit au lieu de déborder de la bulle.
        child: FittedBox(
          child: Text(
            nombre > 99 ? '99+' : '$nombre',
            style: context.textes.labelLarge?.copyWith(
              color: schema.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

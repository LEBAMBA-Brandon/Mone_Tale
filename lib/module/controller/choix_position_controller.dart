import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/coordonnees.dart';
import 'package:tala/data/services/localisation_service.dart';

/// Carte plein écran pour placer le point du signalement À LA MAIN
/// (quand le GPS est imprécis).
///
/// Principe (comme les applis de taxi) : l'épingle reste FIXE au centre de
/// l'écran, et c'est la carte qu'on fait glisser dessous. La position
/// choisie = le centre de la carte.
///
/// Cycle de vie :
/// - onInit  → position de départ (reçue en argument) + carte
/// - onClose → libère la carte
class ChoixPositionController extends GetxController {
  ChoixPositionController(this._localisation);

  final LocalisationService _localisation;

  late final MapController carte;
  late final Coordonnees depart;

  /// Centre actuel de la carte = position qui sera choisie.
  final centre = Coordonnees.libreville.obs;
  final localisationEnCours = false.obs;

  static const double zoomInitial = 17;

  @override
  void onInit() {
    super.onInit();
    carte = MapController();
    final argument = Get.arguments;
    depart = argument is Coordonnees && argument.estValide
        ? argument
        : Coordonnees.libreville;
    centre.value = depart;
  }

  @override
  void onClose() {
    carte.dispose();
    super.onClose();
  }

  /// Appelé par la carte à chaque déplacement.
  void surDeplacement(MapCamera camera) {
    centre.value = Coordonnees(
      latitude: camera.center.latitude,
      longitude: camera.center.longitude,
    );
  }

  /// Recentre la carte sur le GPS.
  Future<void> recentrer() async {
    if (localisationEnCours.value) return;
    localisationEnCours.value = true;
    try {
      final position = await _localisation.obtenirPositionActuelle();
      if (isClosed) return;
      final point = position.coordonnees;
      carte.move(LatLng(point.latitude, point.longitude), zoomInitial);
    } on LocalisationException catch (e) {
      Notifications.erreur(e.message);
    } finally {
      if (!isClosed) localisationEnCours.value = false;
    }
  }

  /// Ferme l'écran en RENVOYANT la position choisie au formulaire
  /// (`await Get.toNamed(...)` la reçoit dans AjoutSignalementController).
  void valider() => Get.back<Coordonnees>(result: centre.value);

  void annuler() => Get.back<void>();
}

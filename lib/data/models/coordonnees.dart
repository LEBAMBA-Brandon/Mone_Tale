import 'dart:math' as math;

/// Une position GPS (latitude / longitude).
///
/// On utilise notre propre classe plutôt que celle d'un package
/// (geolocator, flutter_map…) pour que la couche `data` ne dépende
/// d'aucune librairie de carte.
class Coordonnees {
  const Coordonnees({required this.latitude, required this.longitude});

  /// Centre de Libreville : position par défaut de la carte.
  static const Coordonnees libreville = Coordonnees(
    latitude: 0.4162,
    longitude: 9.4673,
  );

  final double latitude;
  final double longitude;

  /// `false` si les coordonnées sont hors limites ou valent (0, 0)
  /// (valeur typique d'une donnée manquante). Un point invalide
  /// ne doit pas être affiché sur la carte.
  bool get estValide =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);

  /// Distance "à vol d'oiseau" en mètres (formule de Haversine).
  /// Utile pour "Autour de moi" (ex : signalements à moins de 500 m).
  double distanceEnMetres(Coordonnees autre) {
    const rayonTerreEnMetres = 6371000.0;
    final dLat = _versRadians(autre.latitude - latitude);
    final dLng = _versRadians(autre.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_versRadians(latitude)) *
            math.cos(_versRadians(autre.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return rayonTerreEnMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Centre (moyenne) d'un ensemble de points valides.
  /// Sert à centrer la carte sur un quartier, qui n'a pas de coordonnées en base.
  /// Renvoie `null` s'il n'y a aucun point valide.
  static Coordonnees? centreDe(Iterable<Coordonnees> points) {
    var total = 0;
    var sommeLatitudes = 0.0;
    var sommeLongitudes = 0.0;
    for (final point in points) {
      if (!point.estValide) continue;
      sommeLatitudes += point.latitude;
      sommeLongitudes += point.longitude;
      total++;
    }
    if (total == 0) return null;
    return Coordonnees(
      latitude: sommeLatitudes / total,
      longitude: sommeLongitudes / total,
    );
  }

  static double _versRadians(double degres) => degres * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is Coordonnees &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'Coordonnees($latitude, $longitude)';
}

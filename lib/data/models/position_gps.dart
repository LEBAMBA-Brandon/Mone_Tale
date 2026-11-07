import 'package:tala/data/models/coordonnees.dart';

/// Une position GPS + sa précision.
///
/// Le sujet demande de pouvoir « ajuster la position à la main sur une
/// petite carte si le GPS est imprécis » : la précision permet de
/// prévenir le collecteur ("Position approximative (±45 m), vérifiez-la").
class PositionGps {
  const PositionGps({required this.coordonnees, required this.precisionMetres});

  /// Au-delà de cette marge d'erreur, on conseille d'ajuster à la main.
  static const double seuilPrecisionMetres = 30;

  final Coordonnees coordonnees;

  /// Rayon d'incertitude en mètres (plus c'est petit, mieux c'est).
  final double precisionMetres;

  bool get estImprecise => precisionMetres > seuilPrecisionMetres;

  /// "±12 m"
  String get precisionLisible => '±${precisionMetres.round()} m';

  @override
  String toString() => 'PositionGps($coordonnees, $precisionLisible)';
}

import 'package:urbasign/data/models/coordonnees.dart';
import 'package:urbasign/data/models/quartier.dart';
import 'package:urbasign/data/models/signalement.dart';

/// Un résultat de la barre de recherche (comme les suggestions de Google Maps).
///
/// `sealed` = il n'existe QUE deux sortes de résultats, listées dans ce fichier.
/// Avantage : dans un `switch`, Dart vérifie qu'on a bien traité les deux cas.
/// ```dart
/// switch (resultat) {
///   case ResultatQuartier(): // centrer la carte sur le quartier
///   case ResultatSignalement(): // ouvrir le détail du signalement
/// }
/// ```
sealed class ResultatRecherche {
  const ResultatRecherche();

  /// Ligne principale de la suggestion.
  String get titre;

  /// Ligne secondaire (plus petite, grisée).
  String get sousTitre;

  /// Où centrer la carte quand on choisit ce résultat (`null` = impossible).
  Coordonnees? get position;
}

/// Résultat "quartier" : on centre la carte sur ses signalements.
final class ResultatQuartier extends ResultatRecherche {
  const ResultatQuartier({
    required this.quartier,
    required this.nombreSignalements,
    this.centre,
  });

  final Quartier quartier;
  final int nombreSignalements;

  /// Centre des signalements du quartier (`null` s'il n'en a aucun).
  final Coordonnees? centre;

  @override
  String get titre => quartier.nom;

  @override
  String get sousTitre {
    final nombre = switch (nombreSignalements) {
      0 => 'Aucun signalement',
      1 => '1 signalement',
      final n => '$n signalements',
    };
    final localisation = quartier.localisation;
    return localisation == null ? nombre : '$nombre · $localisation';
  }

  @override
  Coordonnees? get position => centre;
}

/// Résultat "signalement" : on ouvre directement son détail.
final class ResultatSignalement extends ResultatRecherche {
  const ResultatSignalement(this.signalement);

  final Signalement signalement;

  @override
  String get titre => signalement.description.isEmpty
      ? signalement.categorie.libelle
      : signalement.description;

  @override
  String get sousTitre =>
      '${signalement.categorie.libelle} · ${signalement.nomQuartier}';

  @override
  Coordonnees? get position =>
      signalement.coordonnees.estValide ? signalement.coordonnees : null;
}

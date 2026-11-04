import 'package:urbasign/data/models/json_parser.dart';

/// Un quartier de Libreville (Nzeng-Ayong, Akébé, Louis…).
///
/// Selon la route, l'API ne renvoie pas les mêmes informations :
/// - `GET /quartiers` → avec l'arrondissement
/// - `GET /quartiers/{id}` → avec l'arrondissement ET la commune
/// - dans un signalement → seulement `id` et `nom_quartier`
/// C'est pour ça que les champs de localisation sont facultatifs (`?`).
class Quartier {
  const Quartier({
    required this.id,
    required this.nom,
    this.arrondissementId,
    this.nomArrondissement,
    this.nomCommune,
  });

  factory Quartier.fromJson(Map<String, dynamic> json) {
    // Objets imbriqués : { "arrondissement": { ..., "commune": { ... } } }
    final arrondissement = JsonParser.lireMap(json['arrondissement']);
    final commune = JsonParser.lireMap(arrondissement?['commune']);

    return Quartier(
      id: JsonParser.lireInt(json['id']),
      nom:
          JsonParser.lireStringOuNull(json['nom_quartier']) ??
          'Quartier inconnu',
      arrondissementId:
          JsonParser.lireIntOuNull(json['arrondissement_id']) ??
          JsonParser.lireIntOuNull(arrondissement?['id']),
      nomArrondissement: JsonParser.lireStringOuNull(
        arrondissement?['nom_arrondissement'],
      ),
      nomCommune: JsonParser.lireStringOuNull(commune?['nom_commune']),
    );
  }

  final int id;
  final String nom;
  final int? arrondissementId;
  final String? nomArrondissement;
  final String? nomCommune;

  /// Texte lisible, ex : "2e arrondissement · Libreville".
  /// `null` si on ne connaît ni l'arrondissement ni la commune.
  String? get localisation {
    final morceaux = [
      if (nomArrondissement != null) '$nomArrondissement arrondissement',
      if (nomCommune != null) nomCommune!,
    ];
    return morceaux.isEmpty ? null : morceaux.join(' · ');
  }

  /// Deux quartiers sont égaux s'ils ont le même id.
  @override
  bool operator ==(Object other) => other is Quartier && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Quartier($id, $nom)';
}

import 'package:urbasign/data/models/auteur.dart';
import 'package:urbasign/data/models/categorie.dart';
import 'package:urbasign/data/models/coordonnees.dart';
import 'package:urbasign/data/models/gravite.dart';
import 'package:urbasign/data/models/json_parser.dart';
import 'package:urbasign/data/models/quartier.dart';
import 'package:urbasign/data/models/statut.dart';

/// Un signalement de problème urbain, tel que renvoyé par l'API.
///
/// Exemple de JSON reçu :
/// ```json
/// {
///   "id": 31, "latitude": 0.4162, "longitude": 9.4673,
///   "description": "Gros trou au carrefour", "categorie": "Voirie",
///   "gravite": "Critique", "statut": "Signalé", "quartier_id": 4,
///   "photo_url": "http://.../storage/signalements/abc.jpg",
///   "date_creation": "2026-10-31T22:50:12.000000Z",
///   "auteur": { "id": 1, "nom": "Admin", "prenom": "User" },
///   "quartier": { "id": 4, "nom_quartier": "Nzeng-Ayong" }
/// }
/// ```
class Signalement {
  const Signalement({
    required this.id,
    required this.coordonnees,
    required this.description,
    required this.categorie,
    required this.gravite,
    required this.statut,
    this.photoUrl,
    this.dateCreation,
    this.auteur,
    this.quartierId,
    this.quartier,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    final auteurJson = JsonParser.lireMap(json['auteur']);
    final quartierJson = JsonParser.lireMap(json['quartier']);
    final quartier = quartierJson == null
        ? null
        : Quartier.fromJson(quartierJson);

    return Signalement(
      id: JsonParser.lireInt(json['id']),
      coordonnees: Coordonnees(
        latitude: JsonParser.lireDouble(json['latitude']),
        longitude: JsonParser.lireDouble(json['longitude']),
      ),
      description: JsonParser.lireString(json['description']).trim(),
      categorie: Categorie.depuisApi(
        JsonParser.lireStringOuNull(json['categorie']),
      ),
      gravite: Gravite.depuisApi(JsonParser.lireStringOuNull(json['gravite'])),
      statut: Statut.depuisApi(JsonParser.lireStringOuNull(json['statut'])),
      photoUrl: JsonParser.lireStringOuNull(json['photo_url']),
      dateCreation: JsonParser.lireDate(json['date_creation']),
      auteur: auteurJson == null ? null : Auteur.fromJson(auteurJson),
      quartierId: JsonParser.lireIntOuNull(json['quartier_id']) ?? quartier?.id,
      quartier: quartier,
    );
  }

  final int id;
  final Coordonnees coordonnees;
  final String description;
  final Categorie categorie;
  final Gravite gravite;
  final Statut statut;

  /// URL complète de la photo (construite par l'API). `null` si pas de photo.
  final String? photoUrl;

  /// Date de création, déjà convertie à l'heure locale du téléphone.
  final DateTime? dateCreation;

  final Auteur? auteur;
  final int? quartierId;
  final Quartier? quartier;

  // ---------- Raccourcis pratiques pour l'interface ----------

  double get latitude => coordonnees.latitude;
  double get longitude => coordonnees.longitude;

  bool get aUnePhoto => photoUrl != null;
  bool get estResolu => statut == Statut.resolu;

  String get nomQuartier => quartier?.nom ?? 'Quartier inconnu';
  String get nomAuteur => auteur?.nomComplet ?? 'Auteur inconnu';

  /// Deux signalements sont égaux s'ils ont le même id.
  /// Utile pour savoir quel marqueur est sélectionné sur la carte.
  @override
  bool operator ==(Object other) => other is Signalement && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Signalement($id, ${categorie.valeurApi}, $nomQuartier)';
}

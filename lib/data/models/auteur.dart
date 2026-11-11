import 'package:tala/data/models/json_parser.dart';

/// L'auteur (collecteur) d'un signalement.
/// L'API ne renvoie volontairement que l'id, le nom et le prénom (pas l'email).
class Auteur {
  const Auteur({required this.id, required this.nom, required this.prenom});

  /// Construit un [Auteur] à partir du JSON :
  /// `{ "id": 1, "nom": "Mba", "prenom": "Jean" }`
  factory Auteur.fromJson(Map<String, dynamic> json) => Auteur(
    id: JsonParser.lireInt(json['id']),
    nom: JsonParser.lireString(json['nom']).trim(),
    prenom: JsonParser.lireString(json['prenom']).trim(),
  );

  final int id;
  final String nom;
  final String prenom;

  /// "Prénom Nom", ou "Auteur inconnu" si les deux sont vides.
  String get nomEtPrenom {
    final complet = '$nom $prenom'.trim();
    return complet.isEmpty ? 'Auteur inconnu' : complet;
  }

  /// Initiales pour un avatar (ex : "JM"), ou "?" si inconnu.
  String get initiales {
    final lettres = [
      nom,
      prenom,
    ].where((mot) => mot.isNotEmpty).map((mot) => mot[0].toUpperCase()).join();
    return lettres.isEmpty ? '?' : lettres;
  }

  @override
  bool operator ==(Object other) => other is Auteur && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

import 'package:tala/data/models/json_parser.dart';
import 'package:tala/data/models/role.dart';

/// Un utilisateur de tala (admin ou collecteur).
///
/// JSON renvoyé par l'API (`GET /users`, `GET /auth/me`, connexion) :
/// ```json
/// {
///   "id": 3, "nom": "Mba", "prenom": "Jean",
///   "email": "jean@urbasign.ga", "role": "collecteur",
///   "created_at": "2026-11-02T10:15:00.000000Z",
///   "signalements_count": 12
/// }
/// ```
/// Le mot de passe n'est JAMAIS renvoyé (`#[Hidden]` dans le modèle Laravel).
class Utilisateur {
  const Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.dateCreation,
    this.nombreSignalements,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) => Utilisateur(
    id: JsonParser.lireInt(json['id']),
    nom: JsonParser.lireString(json['nom']).trim(),
    prenom: JsonParser.lireString(json['prenom']).trim(),
    email: JsonParser.lireString(json['email']).trim(),
    role: Role.depuisApi(JsonParser.lireStringOuNull(json['role'])),
    dateCreation: JsonParser.lireDate(json['created_at']),
    // Présent seulement si l'API fait `withCount('signalements')`.
    nombreSignalements: JsonParser.lireIntOuNull(json['signalements_count']),
  );

  final int id;
  final String nom;
  final String prenom;
  final String email;
  final Role role;
  final DateTime? dateCreation;

  /// Nombre de signalements créés (affiché sur l'icône du collecteur).
  /// `null` = pas encore connu.
  final int? nombreSignalements;

  bool get estAdmin => role == Role.admin;
  bool get estCollecteur => role == Role.collecteur;

  /// "Prénom Nom", ou l'email si le nom est vide.
  String get nomEtPrenom {
    final complet = '$nom $prenom'.trim();
    return complet.isEmpty ? 'Sans nom' : complet;
  }

  /// Initiales pour l'avatar (ex : "JM"), ou "?" si inconnu.
  String get initiales {
    final lettres = [
      nom,
      prenom,
    ].where((mot) => mot.isNotEmpty).map((mot) => mot[0].toUpperCase()).join();
    return lettres.isEmpty ? '?' : lettres;
  }

  /// Convertit en JSON, avec les MÊMES clés que l'API.
  /// Sert à enregistrer l'utilisateur connecté dans le téléphone :
  /// on pourra le relire avec [Utilisateur.fromJson].
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'role': role.valeurApi,
    if (dateCreation != null)
      'created_at': dateCreation!.toUtc().toIso8601String(),
    if (nombreSignalements != null) 'signalements_count': nombreSignalements,
  };

  /// Copie en changeant certains champs (les objets restent "immuables").
  Utilisateur copyWith({
    String? nom,
    String? prenom,
    String? email,
    Role? role,
    int? nombreSignalements,
  }) {
    return Utilisateur(
      id: id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      role: role ?? this.role,
      dateCreation: dateCreation,
      nombreSignalements: nombreSignalements ?? this.nombreSignalements,
    );
  }

  @override
  String toString() => 'Utilisateur($id, $nomEtPrenom, ${role.valeurApi})';
}

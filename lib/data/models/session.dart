import 'package:tala/data/models/json_parser.dart';
import 'package:tala/data/models/utilisateur.dart';

/// La session de l'utilisateur connecté : son token Sanctum + son profil.
///
/// Le JSON a EXACTEMENT la forme de la réponse de `POST /auth/login` :
/// ```json
/// { "token": "12|AbCdEf...", "user": { "id": 1, "nom": "...", ... } }
/// ```
/// Avantage : la même fonction [Session.fromJson] lit la réponse de l'API
/// ET la session enregistrée dans le téléphone.
class Session {
  const Session({required this.token, required this.utilisateur});

  factory Session.fromJson(Map<String, dynamic> json) {
    final userJson = JsonParser.lireMap(json['user']) ?? const {};
    return Session(
      token: JsonParser.lireString(json['token']).trim(),
      utilisateur: Utilisateur.fromJson(userJson),
    );
  }

  /// À envoyer dans chaque requête protégée :
  /// `Authorization: Bearer <token>`.
  final String token;
  final Utilisateur utilisateur;

  /// `false` si le token ou l'utilisateur manque (données abîmées).
  bool get estValide => token.isNotEmpty && utilisateur.id > 0;

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': utilisateur.toJson(),
  };

  /// Même token, profil mis à jour (après "Mon compte" ou `/auth/me`).
  Session avecUtilisateur(Utilisateur nouveau) =>
      Session(token: token, utilisateur: nouveau);

  /// ⚠️ On n'affiche JAMAIS le token en entier dans les logs.
  @override
  String toString() => 'Session(${utilisateur.email}, token: ***)';
}

import 'package:flutter/foundation.dart';
import 'package:tala/data/models/session.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/services/api_client.dart';
import 'package:tala/data/services/api_config.dart';
import 'package:tala/data/services/api_exception.dart';

/// Appels à l'API pour la connexion / déconnexion.
/// Pas de stockage ici : c'est AuthRepository qui garde la session.
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  /// `POST /api/auth/login` → token + profil.
  /// Mauvais identifiants → [ApiException] 401 avec le message de l'API
  /// ("Email ou mot de passe incorrect.").
  Future<Session> connexion({
    required String email,
    required String motDePasse,
  }) async {
    final json = await _client.postObjet(
      ApiConfig.connexion,
      donnees: {'email': email, 'password': motDePasse},
    );
    final session = Session.fromJson(json);
    if (!session.estValide) throw const ApiException.reponseInvalide();
    return session;
  }

  /// `GET /api/auth/me` → profil à jour de l'utilisateur connecté.
  /// Sert aussi à vérifier que le token est encore valable.
  Future<Utilisateur> recupererProfil() async {
    final json = await _client.getObjet(ApiConfig.profil);
    try {
      return Utilisateur.fromJson(json);
    } catch (erreur) {
      debugPrint('Profil illisible : $erreur');
      throw const ApiException.reponseInvalide();
    }
  }

  /// `POST /api/auth/logout` → supprime le token CÔTÉ SERVEUR
  /// (même si quelqu'un l'a copié, il ne marchera plus).
  Future<void> deconnexion() => _client.post(ApiConfig.deconnexion);
}

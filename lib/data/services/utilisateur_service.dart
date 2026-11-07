import 'package:flutter/foundation.dart';
import 'package:tala/data/models/modification_compte.dart';
import 'package:tala/data/models/nouveau_collecteur.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/services/api_client.dart';
import 'package:tala/data/services/api_config.dart';
import 'package:tala/data/services/api_exception.dart';

/// Appels à l'API concernant les utilisateurs.
/// ⚠️ Toutes ces routes sont réservées à l'ADMIN (`can:admin` côté Laravel) :
/// un collecteur recevra une erreur 403.
class UtilisateurService {
  UtilisateurService(this._client);

  final ApiClient _client;

  /// `GET /api/users` : admins ET collecteurs, triés par nom.
  Future<List<Utilisateur>> recupererUtilisateurs() async {
    final donnees = await _client.getListe(ApiConfig.utilisateurs);
    final resultat = <Utilisateur>[];
    for (final json in donnees) {
      try {
        resultat.add(Utilisateur.fromJson(json));
      } catch (erreur) {
        debugPrint('Utilisateur ignoré (JSON invalide) : $erreur');
      }
    }
    return resultat;
  }

  /// `GET /api/users/{id}`.
  Future<Utilisateur> recupererUtilisateur(int id) async =>
      _convertir(await _client.getObjet(ApiConfig.utilisateur(id)));

  /// `POST /api/users` : crée un collecteur.
  /// E-mail déjà pris → [ApiException] 422 avec `erreurPourChamp('email')`.
  Future<Utilisateur> creerCollecteur(NouveauCollecteur nouveau) async =>
      _convertir(
        await _client.postObjet(
          ApiConfig.utilisateurs,
          donnees: nouveau.versJson(),
        ),
      );

  /// `PATCH /api/users/{id}` : seuls les champs modifiés sont envoyés.
  Future<Utilisateur> modifierUtilisateur(
    int id,
    ModificationCompte modification,
  ) async => _convertir(
    await _client.patchObjet(
      ApiConfig.utilisateur(id),
      donnees: modification.versJson(),
    ),
  );

  /// `DELETE /api/users/{id}`.
  /// L'API refuse (409) si l'utilisateur a déjà des signalements,
  /// et (422) si on essaie de supprimer son propre compte.
  Future<void> supprimerUtilisateur(int id) =>
      _client.delete(ApiConfig.utilisateur(id));

  Utilisateur _convertir(Map<String, dynamic> json) {
    try {
      return Utilisateur.fromJson(json);
    } catch (erreur) {
      debugPrint('Utilisateur illisible : $erreur');
      throw const ApiException.reponseInvalide();
    }
  }
}

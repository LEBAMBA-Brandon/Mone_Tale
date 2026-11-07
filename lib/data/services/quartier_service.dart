import 'package:flutter/foundation.dart';
import 'package:tala/data/models/quartier.dart';
import 'package:tala/data/services/api_client.dart';
import 'package:tala/data/services/api_config.dart';

/// Appels à l'API concernant les quartiers.
/// Sert à la liste des quartiers du formulaire "Ajouter un signalement".
class QuartierService {
  QuartierService(this._client);

  final ApiClient _client;

  /// `GET /api/quartiers` : tous les quartiers avec leur arrondissement.
  Future<List<Quartier>> recupererQuartiers() async {
    final donnees = await _client.getListe(ApiConfig.quartiers);
    final resultat = <Quartier>[];
    for (final json in donnees) {
      try {
        resultat.add(Quartier.fromJson(json));
      } catch (erreur) {
        debugPrint('Quartier ignoré (JSON invalide) : $erreur');
      }
    }
    return resultat;
  }
}

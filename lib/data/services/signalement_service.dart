import 'package:flutter/foundation.dart';
import 'package:mono/data/models/signalement.dart';
import 'package:mono/data/models/signalement_filtre.dart';
import 'package:mono/data/services/api_client.dart';
import 'package:mono/data/services/api_config.dart';
import 'package:mono/data/services/api_exception.dart';
import 'package:mono/data/services/jeton_annulation.dart';

/// Appels à l'API concernant les signalements (lecture seule pour le visiteur).
///
/// Rôle : faire la requête HTTP et convertir le JSON en [Signalement].
/// Pas de cache ni de logique ici : c'est le travail du repository.
class SignalementService {
  SignalementService(this._client);

  final ApiClient _client;

  /// `GET /api/signalements` avec les filtres éventuels.
  Future<List<Signalement>> recupererSignalements({
    SignalementFiltre filtre = SignalementFiltre.vide,
    JetonAnnulation? annulation,
  }) async {
    final donnees = await _client.getListe(
      ApiConfig.signalements,
      parametres: filtre.versParametresRequete(),
      annulation: annulation,
    );
    return _convertirListe(donnees);
  }

  /// `GET /api/signalements/{id}` : détail d'un signalement.
  Future<Signalement> recupererSignalement(
    int id, {
    JetonAnnulation? annulation,
  }) async {
    final donnees = await _client.getObjet(
      ApiConfig.signalement(id),
      annulation: annulation,
    );
    try {
      return Signalement.fromJson(donnees);
    } catch (erreur) {
      debugPrint('Signalement $id illisible : $erreur');
      throw const ApiException.reponseInvalide();
    }
  }

  /// Convertit chaque élément ; un élément illisible est IGNORÉ
  /// (on ne bloque pas toute la carte à cause d'un seul signalement).
  List<Signalement> _convertirListe(List<Map<String, dynamic>> donnees) {
    final resultat = <Signalement>[];
    for (final json in donnees) {
      try {
        resultat.add(Signalement.fromJson(json));
      } catch (erreur) {
        debugPrint('Signalement ignoré (JSON invalide) : $erreur');
      }
    }
    return resultat;
  }
}

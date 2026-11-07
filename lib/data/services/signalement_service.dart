import 'package:flutter/foundation.dart';
import 'package:tala/data/models/nouveau_signalement.dart';
import 'package:tala/data/models/signalement.dart';
import 'package:tala/data/models/signalement_filtre.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/data/services/api_client.dart';
import 'package:tala/data/services/api_config.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/jeton_annulation.dart';

/// Appels à l'API concernant les signalements.
///
/// Rôle : faire la requête HTTP et convertir le JSON en [Signalement].
/// Pas de cache ni de logique ici : c'est le travail du repository.
class SignalementService {
  SignalementService(this._client);

  final ApiClient _client;

  // ---------- Lecture ----------

  /// `GET /api/signalements` (+ filtres) : TOUS les signalements (admin).
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

  /// `GET /api/signalements/mes-signalements` : ceux du collecteur connecté.
  Future<List<Signalement>> recupererMesSignalements({
    JetonAnnulation? annulation,
  }) async {
    final donnees = await _client.getListe(
      ApiConfig.mesSignalements,
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
    return _convertir(donnees);
  }

  // ---------- Écriture ----------

  /// `POST /api/signalements` en multipart : champs texte + photo.
  /// [progression] : de 0.0 à 1.0 pendant l'envoi de la photo.
  Future<Signalement> creerSignalement(
    NouveauSignalement nouveau, {
    void Function(double progression)? progression,
    JetonAnnulation? annulation,
  }) async {
    final donnees = await _client.envoyerFormulaire(
      ApiConfig.signalements,
      champs: nouveau.versChamps(),
      fichiers: {'photo': nouveau.photo!.chemin},
      progression: progression,
      annulation: annulation,
    );
    return _convertir(donnees);
  }

  /// `PATCH /api/signalements/{id}/statut` (admin).
  Future<Signalement> changerStatut(int id, Statut statut) async {
    final donnees = await _client.patchObjet(
      ApiConfig.statutSignalement(id),
      donnees: {'statut': statut.valeurApi},
    );
    return _convertir(donnees);
  }

  /// `DELETE /api/signalements/{id}` (admin). Supprime aussi la photo.
  Future<void> supprimerSignalement(int id) =>
      _client.delete(ApiConfig.signalement(id));

  // ---------- Conversion ----------

  Signalement _convertir(Map<String, dynamic> json) {
    try {
      return Signalement.fromJson(json);
    } catch (erreur) {
      debugPrint('Signalement illisible : $erreur');
      throw const ApiException.reponseInvalide();
    }
  }

  /// Un élément illisible est IGNORÉ (on ne bloque pas toute la liste
  /// à cause d'un seul signalement).
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

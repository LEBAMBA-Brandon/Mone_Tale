import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mono/data/models/json_parser.dart';
import 'package:mono/data/services/api_config.dart';
import 'package:mono/data/services/api_exception.dart';
import 'package:mono/data/services/jeton_annulation.dart';

/// Client HTTP unique de l'application (un "emballage" autour de dio).
///
/// Il centralise :
/// - l'adresse du serveur et les délais d'attente ;
/// - l'en-tête `Accept: application/json` (pour que Laravel réponde en JSON) ;
/// - la conversion de TOUTES les erreurs en [ApiException] ;
/// - l'annulation des requêtes via [JetonAnnulation].
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.delaiConnexion,
              receiveTimeout: ApiConfig.delaiReception,
              headers: const {'Accept': 'application/json'},
              responseType: ResponseType.json,
            ),
          ) {
    // En mode debug seulement : affiche chaque requête dans la console.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          logPrint: (ligne) => debugPrint(ligne.toString()),
        ),
      );
    }
  }

  final Dio _dio;

  /// Requête GET brute. Renvoie le JSON décodé (liste, objet…).
  /// [annulation] : permet d'arrêter la requête (ex : dans onClose).
  Future<Object?> get(
    String chemin, {
    Map<String, dynamic>? parametres,
    JetonAnnulation? annulation,
  }) async {
    try {
      final reponse = await _dio.get<Object?>(
        chemin,
        queryParameters: parametres,
        cancelToken: annulation?.jetonDio,
      );
      return reponse.data;
    } on DioException catch (erreur) {
      throw ApiException.depuisDio(erreur);
    }
  }

  /// GET qui doit renvoyer une LISTE d'objets (ex : `GET /signalements`).
  /// Accepte aussi le format paginé de Laravel `{ "data": [ ... ] }`.
  Future<List<Map<String, dynamic>>> getListe(
    String chemin, {
    Map<String, dynamic>? parametres,
    JetonAnnulation? annulation,
  }) async {
    final donnees = await get(
      chemin,
      parametres: parametres,
      annulation: annulation,
    );
    final liste = donnees is Map ? donnees['data'] : donnees;
    if (liste is! List) throw const ApiException.reponseInvalide();
    return JsonParser.lireListeDeMaps(liste);
  }

  /// GET qui doit renvoyer UN objet (ex : `GET /signalements/31`).
  Future<Map<String, dynamic>> getObjet(
    String chemin, {
    Map<String, dynamic>? parametres,
    JetonAnnulation? annulation,
  }) async {
    final donnees = await get(
      chemin,
      parametres: parametres,
      annulation: annulation,
    );
    final objet = JsonParser.lireMap(donnees);
    if (objet == null) throw const ApiException.reponseInvalide();
    return objet;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tala/data/models/json_parser.dart';
import 'package:tala/data/services/api_config.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/jeton_annulation.dart';

/// Client HTTP unique de l'application (un "emballage" autour de dio).
///
/// Par rapport à mono, il sait en plus :
/// - **ajouter le token** (`Authorization: Bearer …`) à chaque requête ;
/// - **prévenir** quand le serveur répond 401 (session expirée) ;
/// - **écrire** : POST / PATCH / DELETE ;
/// - **envoyer une photo** (formulaire multipart) en suivant la progression.
///
/// Toutes les erreurs sont converties en [ApiException] : c'est le SEUL
/// fichier de l'app qui connaît dio.
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
    // Un "intercepteur" est appelé pour CHAQUE requête et CHAQUE erreur :
    // on écrit le code du token une seule fois, ici, au lieu de le répéter
    // dans tous les services.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final jeton = _jeton;
          if (jeton != null) options.headers['Authorization'] = 'Bearer $jeton';
          handler.next(options); // on laisse partir la requête
        },
        onError: (erreur, handler) {
          // 401 sur une route protégée = token expiré ou supprimé.
          // Sauf pour la connexion, où 401 = mauvais mot de passe.
          final estConnexion = erreur.requestOptions.path == ApiConfig.connexion;
          if (erreur.response?.statusCode == 401 &&
              _jeton != null &&
              !estConnexion) {
            surSessionExpiree?.call();
          }
          handler.next(erreur); // l'erreur continue jusqu'à notre try/catch
        },
      ),
    );

    // En mode debug seulement : affiche chaque requête dans la console.
    // ⚠️ requestBody: false → le mot de passe de la connexion n'apparaît
    // JAMAIS dans la console. requestHeader: false → le token non plus.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          logPrint: (ligne) => debugPrint(ligne.toString()),
        ),
      );
    }
  }

  final Dio _dio;

  /// Token de l'utilisateur connecté (`null` = personne).
  String? _jeton;

  /// Appelé quand le serveur dit que la session n'est plus valable.
  /// Branché par AuthRepository (qui déconnecte l'utilisateur).
  void Function()? surSessionExpiree;

  bool get aUnJeton => _jeton != null;

  /// Donne le token à utiliser (`null` à la déconnexion).
  void definirJeton(String? jeton) => _jeton = jeton;

  // =====================================================================
  //  LECTURE
  // =====================================================================

  /// Requête GET brute. Renvoie le JSON décodé (liste, objet…).
  /// [annulation] : permet d'arrêter la requête (ex : dans onClose).
  Future<Object?> get(
    String chemin, {
    Map<String, dynamic>? parametres,
    JetonAnnulation? annulation,
  }) {
    return _executer(
      () => _dio.get<Object?>(
        chemin,
        queryParameters: parametres,
        cancelToken: annulation?.jetonDio,
      ),
    );
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
    return _versObjet(donnees);
  }

  // =====================================================================
  //  ÉCRITURE
  // =====================================================================

  /// POST avec un corps JSON. Renvoie l'objet JSON de la réponse.
  Future<Map<String, dynamic>> postObjet(
    String chemin, {
    Map<String, dynamic>? donnees,
    JetonAnnulation? annulation,
  }) async {
    final reponse = await _executer(
      () => _dio.post<Object?>(
        chemin,
        data: donnees,
        cancelToken: annulation?.jetonDio,
      ),
    );
    return _versObjet(reponse);
  }

  /// POST dont la réponse ne nous intéresse pas (ex : déconnexion).
  Future<void> post(String chemin, {Map<String, dynamic>? donnees}) async {
    await _executer(() => _dio.post<Object?>(chemin, data: donnees));
  }

  /// PATCH : modification PARTIELLE (on n'envoie que ce qui change).
  Future<Map<String, dynamic>> patchObjet(
    String chemin, {
    required Map<String, dynamic> donnees,
    JetonAnnulation? annulation,
  }) async {
    final reponse = await _executer(
      () => _dio.patch<Object?>(
        chemin,
        data: donnees,
        cancelToken: annulation?.jetonDio,
      ),
    );
    return _versObjet(reponse);
  }

  /// DELETE. Laravel répond "204 No Content" : rien à lire.
  Future<void> delete(String chemin) async {
    await _executer(() => _dio.delete<Object?>(chemin));
  }

  /// Envoie un formulaire AVEC FICHIER (`multipart/form-data`),
  /// comme le "form-data" de Postman.
  ///
  /// - [champs] : les champs texte (`categorie`, `latitude`…).
  /// - [fichiers] : nom du champ → chemin du fichier (`photo` → `/…/IMG.jpg`).
  /// - [progression] : appelée pendant l'envoi avec une valeur de 0.0 à 1.0
  ///   (pour une barre de progression).
  Future<Map<String, dynamic>> envoyerFormulaire(
    String chemin, {
    required Map<String, String> champs,
    required Map<String, String> fichiers,
    void Function(double progression)? progression,
    JetonAnnulation? annulation,
  }) async {
    final FormData formulaire;
    try {
      formulaire = FormData.fromMap({
        ...champs,
        for (final MapEntry(key: champ, value: cheminFichier)
            in fichiers.entries)
          champ: await MultipartFile.fromFile(
            cheminFichier,
            filename: cheminFichier.split(RegExp(r'[/\\]')).last,
          ),
      });
    } catch (erreur) {
      // Le fichier a disparu (cache vidé…) ou n'est pas lisible.
      debugPrint('Fichier illisible : $erreur');
      throw const ApiException(
        type: TypeErreurApi.inconnue,
        message: 'La photo est introuvable sur le téléphone. Reprenez-la.',
      );
    }

    final reponse = await _executer(
      () => _dio.post<Object?>(
        chemin,
        data: formulaire,
        cancelToken: annulation?.jetonDio,
        options: Options(sendTimeout: ApiConfig.delaiEnvoi),
        onSendProgress: (envoye, total) {
          if (total > 0) progression?.call(envoye / total);
        },
      ),
    );
    return _versObjet(reponse);
  }

  // =====================================================================
  //  OUTILS INTERNES
  // =====================================================================

  /// Lance la requête et convertit TOUTE erreur dio en [ApiException].
  /// Écrit une seule fois au lieu d'un try/catch dans chaque méthode.
  Future<Object?> _executer(Future<Response<Object?>> Function() requete) async {
    try {
      final reponse = await requete();
      return reponse.data;
    } on DioException catch (erreur) {
      throw ApiException.depuisDio(erreur);
    }
  }

  Map<String, dynamic> _versObjet(Object? donnees) {
    final objet = JsonParser.lireMap(donnees);
    if (objet == null) throw const ApiException.reponseInvalide();
    return objet;
  }
}

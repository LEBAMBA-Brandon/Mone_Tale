import 'package:dio/dio.dart';
import 'package:mono/data/models/json_parser.dart';

/// Les différentes sortes d'erreurs possibles avec l'API.
/// Au J2/J3, l'interface choisira l'icône et le bouton selon le type
/// (ex : "Réessayer" pour un problème réseau).
enum TypeErreurApi {
  pasDeConnexion,
  delaiDepasse,
  nonAuthentifie, // 401
  accesRefuse, // 403
  introuvable, // 404
  conflit, // 409
  validation, // 422
  tropDeRequetes, // 429
  serveur, // 500 et plus
  reponseInvalide, // le serveur a renvoyé autre chose que du JSON attendu
  annulee,
  inconnue,
}

/// Erreur "propre" de l'API, avec un message en français prêt à afficher.
///
/// Toutes les erreurs techniques (dio, réseau, JSON…) sont converties
/// en [ApiException]. Le reste de l'app n'a donc qu'UN type d'erreur à gérer.
class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.codeHttp,
    this.erreursChamps = const {},
  });

  /// Le serveur a répondu, mais pas dans le format attendu.
  const ApiException.reponseInvalide()
    : type = TypeErreurApi.reponseInvalide,
      message =
          'Le serveur a renvoyé une réponse inattendue. Réessayez plus tard.',
      codeHttp = null,
      erreursChamps = const {};

  /// Convertit une erreur de dio en [ApiException].
  factory ApiException.depuisDio(DioException erreur) {
    return switch (erreur.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const ApiException(
        type: TypeErreurApi.delaiDepasse,
        message:
            'Le serveur met trop de temps à répondre. Vérifiez votre connexion et réessayez.',
      ),
      DioExceptionType.connectionError => const ApiException(
        type: TypeErreurApi.pasDeConnexion,
        message:
            'Impossible de joindre le serveur. Vérifiez votre connexion internet.',
      ),
      DioExceptionType.cancel => const ApiException(
        type: TypeErreurApi.annulee,
        message: 'La requête a été annulée.',
      ),
      DioExceptionType.badCertificate => const ApiException(
        type: TypeErreurApi.inconnue,
        message: 'Connexion au serveur refusée (certificat invalide).',
      ),
      DioExceptionType.badResponse => ApiException._depuisReponse(
        erreur.response,
      ),
      // "unknown" : souvent un JSON illisible, sinon un problème réseau.
      DioExceptionType.unknown =>
        erreur.error is FormatException
            ? const ApiException.reponseInvalide()
            : const ApiException(
                type: TypeErreurApi.pasDeConnexion,
                message:
                    'Impossible de joindre le serveur. Vérifiez votre connexion internet.',
              ),
    };
  }

  /// Le serveur a répondu avec un code d'erreur (4xx / 5xx).
  factory ApiException._depuisReponse(Response<dynamic>? reponse) {
    final code = reponse?.statusCode;
    final corps = JsonParser.lireMap(reponse?.data);
    final messageServeur = JsonParser.lireStringOuNull(corps?['message']);
    final erreursChamps = _lireErreursChamps(corps?['errors']);

    return switch (code) {
      401 => ApiException(
        type: TypeErreurApi.nonAuthentifie,
        codeHttp: code,
        message: 'Votre session a expiré. Veuillez vous reconnecter.',
      ),
      403 => ApiException(
        type: TypeErreurApi.accesRefuse,
        codeHttp: code,
        message: "Vous n'avez pas les droits pour effectuer cette action.",
      ),
      404 => ApiException(
        type: TypeErreurApi.introuvable,
        codeHttp: code,
        message: 'Élément introuvable. Il a peut-être été supprimé.',
      ),
      409 => ApiException(
        type: TypeErreurApi.conflit,
        codeHttp: code,
        message:
            messageServeur ??
            'Action impossible : conflit avec des données existantes.',
      ),
      422 => ApiException(
        type: TypeErreurApi.validation,
        codeHttp: code,
        erreursChamps: erreursChamps,
        message:
            _premierMessage(erreursChamps) ??
            messageServeur ??
            'Certaines informations sont invalides.',
      ),
      429 => ApiException(
        type: TypeErreurApi.tropDeRequetes,
        codeHttp: code,
        message: 'Trop de requêtes. Patientez quelques secondes.',
      ),
      final int c when c >= 500 => ApiException(
        type: TypeErreurApi.serveur,
        codeHttp: c,
        message: 'Le serveur rencontre un problème. Réessayez plus tard.',
      ),
      _ => ApiException(
        type: TypeErreurApi.inconnue,
        codeHttp: code,
        message:
            'Une erreur inattendue est survenue${code != null ? ' (code $code)' : ''}.',
      ),
    };
  }

  final TypeErreurApi type;

  /// Message en français, prêt à afficher à l'utilisateur.
  final String message;

  /// Code HTTP (404, 422, 500…) quand le serveur a répondu.
  final int? codeHttp;

  /// Erreurs de validation Laravel (422), champ par champ.
  /// Ex : { "photo": ["La photo ne doit pas dépasser 1 Mo."] }
  final Map<String, List<String>> erreursChamps;

  /// `true` si le problème vient du réseau (utile pour proposer "Réessayer"
  /// ou se rabattre sur les données en cache).
  bool get estProblemeReseau =>
      type == TypeErreurApi.pasDeConnexion ||
      type == TypeErreurApi.delaiDepasse;

  /// `true` si la requête a été annulée volontairement (onClose, changement
  /// de filtre…). Ce n'est PAS une vraie erreur : le controller doit
  /// l'ignorer, sans afficher de message.
  bool get estAnnulation => type == TypeErreurApi.annulee;

  /// Premier message d'erreur d'un champ précis (ou `null`).
  String? erreurPourChamp(String champ) {
    final messages = erreursChamps[champ];
    if (messages == null || messages.isEmpty) return null;
    return messages.first;
  }

  /// Lit le bloc "errors" renvoyé par Laravel en cas de 422.
  static Map<String, List<String>> _lireErreursChamps(Object? valeur) {
    final erreurs = JsonParser.lireMap(valeur);
    if (erreurs == null) return const {};
    final resultat = <String, List<String>>{};
    erreurs.forEach((champ, messages) {
      if (messages is List) {
        resultat[champ] = messages.map((m) => m.toString()).toList();
      } else if (messages != null) {
        resultat[champ] = [messages.toString()];
      }
    });
    return resultat;
  }

  static String? _premierMessage(Map<String, List<String>> erreurs) {
    for (final messages in erreurs.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return null;
  }

  @override
  String toString() => 'ApiException($type, code: $codeHttp) : $message';
}

import 'package:flutter/foundation.dart';

/// Configuration de l'API : adresse du serveur, délais et routes.
///
/// ⚠️ L'adresse dépend de l'endroit où tourne l'app :
/// - Émulateur Android  → 10.0.2.2 (= le "localhost" du PC vu depuis l'émulateur)
/// - Navigateur / PC    → localhost
/// - Vrai téléphone     → l'IP du PC sur le Wi-Fi (ex : 192.168.1.10)
///
/// Pour un vrai téléphone, on passe l'adresse au lancement, sans toucher au code :
/// `flutter run --dart-define=API_URL=http://192.168.1.10:8000/api`
abstract final class ApiConfig {
  /// Adresse passée avec `--dart-define=API_URL=...` (vide si non fournie).
  static const String _urlPersonnalisee = String.fromEnvironment('API_URL');

  /// Adresse de base de l'API (sans "/" à la fin).
  static String get baseUrl {
    if (_urlPersonnalisee.isNotEmpty) return _urlPersonnalisee;
    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  /// Temps max pour établir la connexion avec le serveur.
  static const Duration delaiConnexion = Duration(seconds: 10);

  /// Temps max pour recevoir la réponse complète.
  static const Duration delaiReception = Duration(seconds: 20);

  // ---------- Routes utilisées par l'app visiteur ----------
  static const String signalements = '/signalements';
  static String signalement(int id) => '/signalements/$id';
  static const String quartiers = '/quartiers';
}

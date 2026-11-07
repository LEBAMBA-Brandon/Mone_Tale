import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tala/data/models/preference_theme.dart';

/// Petits réglages de l'app enregistrés avec **GetStorage** (le thème).
///
/// - Lecture SYNCHRONE (sans await) → le thème est connu avant le premier écran.
/// - Une erreur de stockage ne bloque jamais l'app : on renvoie une valeur
///   par défaut.
///
/// ⚠️ Appeler `await StockageLocalService.initialiser();` dans `main()`
/// AVANT `runApp()`, sinon les lectures renvoient toujours la valeur par
/// défaut (et la session ne serait pas retrouvée : voir SessionService).
class StockageLocalService {
  StockageLocalService({GetStorage? boite}) : _boite = boite ?? GetStorage();

  final GetStorage _boite;

  static const String _cleTheme = 'tala.theme';

  /// À appeler UNE seule fois au démarrage, avant runApp().
  /// Ouvre la "boîte" GetStorage partagée par StockageLocalService
  /// ET SessionService.
  static Future<void> initialiser() async {
    try {
      await GetStorage.init();
    } catch (erreur) {
      debugPrint('GetStorage indisponible : $erreur');
    }
  }

  /// Thème choisi par l'utilisateur (par défaut : celui du téléphone).
  PreferenceTheme lirePreferenceTheme() {
    try {
      return PreferenceTheme.depuisStockage(_boite.read<String>(_cleTheme));
    } catch (_) {
      return PreferenceTheme.systeme;
    }
  }

  Future<void> enregistrerPreferenceTheme(PreferenceTheme preference) async {
    try {
      await _boite.write(_cleTheme, preference.valeurStockee);
    } catch (erreur) {
      debugPrint('Écriture GetStorage impossible ($_cleTheme) : $erreur');
    }
  }
}

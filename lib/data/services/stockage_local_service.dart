import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mono/data/models/coordonnees.dart';
import 'package:mono/data/models/preference_theme.dart';

/// Petits réglages de l'app enregistrés avec **GetStorage**.
///
/// - Lecture SYNCHRONE (sans await) → le thème est connu avant le premier écran.
/// - Une erreur de stockage ne bloque jamais l'app : on renvoie une valeur
///   par défaut.
///
/// ⚠️ Appeler `await StockageLocalService.initialiser();` dans `main()`
/// AVANT `runApp()`, sinon les lectures renvoient toujours la valeur par défaut.
class StockageLocalService {
  StockageLocalService({GetStorage? boite}) : _boite = boite ?? GetStorage();

  final GetStorage _boite;

  static const String _cleTheme = 'mono.theme';
  static const String _cleLatitude = 'mono.derniere_latitude';
  static const String _cleLongitude = 'mono.derniere_longitude';

  /// À appeler UNE seule fois au démarrage, avant runApp().
  static Future<void> initialiser() async {
    try {
      await GetStorage.init();
    } catch (erreur) {
      debugPrint('GetStorage indisponible : $erreur');
    }
  }

  // ---------- Thème ----------

  /// Thème choisi par l'utilisateur (par défaut : celui du téléphone).
  PreferenceTheme lirePreferenceTheme() {
    try {
      return PreferenceTheme.depuisStockage(_boite.read<String>(_cleTheme));
    } catch (_) {
      return PreferenceTheme.systeme;
    }
  }

  Future<void> enregistrerPreferenceTheme(PreferenceTheme preference) =>
      _ecrire(_cleTheme, preference.valeurStockee);

  // ---------- Dernière position connue ----------

  /// Dernière position de l'utilisateur (bouton "Autour de moi").
  /// Sert à centrer la carte tout de suite au prochain lancement,
  /// sans attendre le GPS. `null` si inconnue ou invalide.
  Coordonnees? lireDernierePosition() {
    try {
      // `num` accepte à la fois les int et les double stockés.
      final latitude = _boite.read<num>(_cleLatitude)?.toDouble();
      final longitude = _boite.read<num>(_cleLongitude)?.toDouble();
      if (latitude == null || longitude == null) return null;
      final position = Coordonnees(latitude: latitude, longitude: longitude);
      return position.estValide ? position : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> enregistrerDernierePosition(Coordonnees position) async {
    if (!position.estValide) return;
    await _ecrire(_cleLatitude, position.latitude);
    await _ecrire(_cleLongitude, position.longitude);
  }

  /// Écriture protégée : une erreur est affichée en console, sans planter.
  Future<void> _ecrire(String cle, Object valeur) async {
    try {
      await _boite.write(cle, valeur);
    } catch (erreur) {
      debugPrint('Écriture GetStorage impossible ($cle) : $erreur');
    }
  }
}

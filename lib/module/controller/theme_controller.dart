import 'package:get/get.dart';
import 'package:tala/core/theme/app_theme.dart';
import 'package:tala/data/models/preference_theme.dart';
import 'package:tala/data/services/stockage_local_service.dart';

/// Gère le thème clair / sombre / système de toute l'application.
/// Le choix est enregistré avec GetStorage : il est conservé au redémarrage.
class ThemeController extends GetxController {
  ThemeController(this._stockage);

  final StockageLocalService _stockage;

  /// Choix actuel (observé par l'écran "Compte").
  final preference = PreferenceTheme.systeme.obs;

  @override
  void onInit() {
    super.onInit();
    // Lecture synchrone (GetStorage) : aucune attente.
    preference.value = _stockage.lirePreferenceTheme();
  }

  /// Applique un choix (Système, Clair ou Sombre) et l'enregistre.
  Future<void> definir(PreferenceTheme choix) async {
    if (preference.value == choix) return;
    preference.value = choix;
    // Change le thème tout de suite, sans redémarrer l'app.
    Get.changeThemeMode(choix.themeMode);
    await _stockage.enregistrerPreferenceTheme(choix);
  }
}

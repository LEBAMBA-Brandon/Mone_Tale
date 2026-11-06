import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_theme.dart';
import 'package:mono/data/models/preference_theme.dart';
import 'package:mono/data/services/stockage_local_service.dart';

/// Gère le thème clair / sombre de toute l'application.
/// Le choix est enregistré avec GetStorage : il est conservé au redémarrage.
class ThemeController extends GetxController {
  ThemeController(this._stockage);

  final StockageLocalService _stockage;

  /// Choix actuel (observé par l'interface si besoin).
  final preference = PreferenceTheme.systeme.obs;

  @override
  void onInit() {
    super.onInit();
    // Lecture synchrone (GetStorage) : aucune attente.
    preference.value = _stockage.lirePreferenceTheme();
  }

  /// Passe du clair au sombre (ou l'inverse) selon ce qui est AFFICHÉ.
  Future<void> basculer() async {
    final nouvelle = Get.isDarkMode
        ? PreferenceTheme.clair
        : PreferenceTheme.sombre;
    preference.value = nouvelle;
    Get.changeThemeMode(nouvelle.themeMode);
    await _stockage.enregistrerPreferenceTheme(nouvelle);
  }

  /// Revenir au réglage du téléphone.
  Future<void> suivreLeSysteme() async {
    preference.value = PreferenceTheme.systeme;
    Get.changeThemeMode(ThemeMode.system);
    await _stockage.enregistrerPreferenceTheme(PreferenceTheme.systeme);
  }
}

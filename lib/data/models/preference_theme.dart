/// Choix de thème de l'utilisateur, enregistré sur le téléphone.
///
/// On n'utilise pas directement `ThemeMode` de Flutter ici pour que la
/// couche data ne dépende pas de l'interface. La conversion vers
/// `ThemeMode` se fera dans core/theme (J3).
enum PreferenceTheme {
  systeme('systeme'), // suit le réglage du téléphone
  clair('clair'),
  sombre('sombre');

  const PreferenceTheme(this.valeurStockee);

  /// Texte enregistré dans GetStorage.
  final String valeurStockee;

  /// Valeur inconnue ou absente → [PreferenceTheme.systeme].
  static PreferenceTheme depuisStockage(String? valeur) {
    for (final preference in PreferenceTheme.values) {
      if (preference.valeurStockee == valeur) return preference;
    }
    return PreferenceTheme.systeme;
  }
}

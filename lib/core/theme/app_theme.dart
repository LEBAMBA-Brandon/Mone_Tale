import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mono/core/theme/app_couleurs.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/data/models/preference_theme.dart';

/// Les deux thèmes de l'application.
///
/// Utilisation (au J3, dans main.dart) :
/// ```dart
/// GetMaterialApp(
///   theme: AppTheme.clair,
///   darkTheme: AppTheme.sombre,
///   themeMode: stockage.lirePreferenceTheme().themeMode,
/// )
/// ```
/// Grâce à ce thème, un simple `FilledButton` est déjà vert et arrondi,
/// une `AppBar` est déjà jaune : pas besoin de répéter les styles partout.
abstract final class AppTheme {
  static ThemeData get clair => _construire(
    schema: _schemaClair,
    couleurs: CouleursMono.clair,
    fond: AppCouleurs.blanc,
  );

  static ThemeData get sombre => _construire(
    schema: _schemaSombre,
    couleurs: CouleursMono.sombre,
    fond: AppCouleurs.noir,
  );

  // ---------- Schémas de couleurs Material 3 ----------

  static const ColorScheme _schemaClair = ColorScheme(
    brightness: Brightness.light,
    primary: AppCouleurs.vertFonce,
    onPrimary: AppCouleurs.blanc,
    primaryContainer: AppCouleurs.vertFonceConteneur,
    onPrimaryContainer: AppCouleurs.surVertFonceConteneur,
    secondary: AppCouleurs.jauneFonce,
    onSecondary: AppCouleurs.texteSurJaune,
    secondaryContainer: AppCouleurs.jauneFonceConteneur,
    onSecondaryContainer: AppCouleurs.surJauneFonceConteneur,
    error: AppCouleurs.rougeFonce,
    onError: AppCouleurs.blanc,
    errorContainer: AppCouleurs.rougeFonceConteneur,
    onErrorContainer: AppCouleurs.surRougeFonceConteneur,
    surface: AppCouleurs.blanc,
    onSurface: Color(0xFF1A1C19),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F8F5),
    surfaceContainer: Color(0xFFF1F3EE),
    surfaceContainerHigh: Color(0xFFEBEDE8),
    surfaceContainerHighest: Color(0xFFE5E7E2),
    onSurfaceVariant: Color(0xFF44483F),
    outline: Color(0xFF74796D),
    outlineVariant: Color(0xFFC4C8BB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2F312D),
    onInverseSurface: Color(0xFFF0F1EC),
    inversePrimary: AppCouleurs.vertClair,
    // Désactive la teinte verte que Material 3 ajoute aux surfaces surélevées.
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme _schemaSombre = ColorScheme(
    brightness: Brightness.dark,
    primary: AppCouleurs.vertClair,
    onPrimary: AppCouleurs.surVertClair,
    primaryContainer: AppCouleurs.vertClairConteneur,
    onPrimaryContainer: AppCouleurs.vertFonceConteneur,
    secondary: AppCouleurs.jauneClair,
    onSecondary: AppCouleurs.texteSurJaune,
    secondaryContainer: AppCouleurs.jauneClairConteneur,
    onSecondaryContainer: AppCouleurs.jauneFonceConteneur,
    error: AppCouleurs.rougeClair,
    onError: AppCouleurs.surRougeClair,
    errorContainer: AppCouleurs.rougeClairConteneur,
    onErrorContainer: AppCouleurs.rougeFonceConteneur,
    surface: AppCouleurs.noir,
    onSurface: Color(0xFFE6E8E3),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    surfaceContainerLow: Color(0xFF121412),
    surfaceContainer: Color(0xFF1A1C1A),
    surfaceContainerHigh: Color(0xFF222522),
    surfaceContainerHighest: Color(0xFF2B2E2B),
    onSurfaceVariant: Color(0xFFC2C7BC),
    outline: Color(0xFF8C9287),
    outlineVariant: Color(0xFF42473F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E8E3),
    onInverseSurface: Color(0xFF2F312D),
    inversePrimary: AppCouleurs.vertFonce,
    surfaceTint: Colors.transparent,
  );

  // ---------- Construction du thème complet ----------

  static ThemeData _construire({
    required ColorScheme schema,
    required CouleursMono couleurs,
    required Color fond,
  }) {
    final base = ThemeData(useMaterial3: true, colorScheme: schema);

    final textes = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    // Bordure des champs de saisie selon leur état.
    OutlineInputBorder bordure(Color couleur, [double epaisseur = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRayons.m),
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    final formeBouton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRayons.m),
    );
    const paddingBouton = EdgeInsets.symmetric(
      horizontal: AppEspacements.xl,
      vertical: AppEspacements.m,
    );
    const tailleMinBouton = Size(AppTailles.toucheMin, AppTailles.toucheMin);

    return base.copyWith(
      scaffoldBackgroundColor: fond,
      textTheme: textes,
      extensions: <ThemeExtension<dynamic>>[couleurs],

      // AppBar JAUNE, texte et icônes sombres (lisibles dans les 2 thèmes).
      appBarTheme: AppBarThemeData(
        backgroundColor: couleurs.barre,
        foregroundColor: couleurs.surBarre,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        iconTheme: IconThemeData(color: couleurs.surBarre),
        actionsIconTheme: IconThemeData(color: couleurs.surBarre),
        titleTextStyle: textes.titleLarge?.copyWith(color: couleurs.surBarre),
        // Icônes de la barre d'état (heure, batterie) en sombre sur le jaune.
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      // Barre de navigation JAUNE (utilisée dans urbacollector).
      // L'onglet actif est une pastille vert foncé avec une icône blanche,
      // bien visible sur le jaune dans les 2 thèmes.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: couleurs.barre,
        indicatorColor: AppCouleurs.vertFonce,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (etats) => IconThemeData(
            color: etats.contains(WidgetState.selected)
                ? AppCouleurs.blanc
                : couleurs.surBarre,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (etats) => textes.labelMedium?.copyWith(
            color: couleurs.surBarre,
            fontWeight: etats.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),

      // Boutons VERTS.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: schema.primary,
          foregroundColor: schema.onPrimary,
          minimumSize: tailleMinBouton,
          padding: paddingBouton,
          shape: formeBouton,
          textStyle: textes.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: schema.primary,
          minimumSize: tailleMinBouton,
          padding: paddingBouton,
          shape: formeBouton,
          side: BorderSide(color: schema.primary),
          textStyle: textes.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: schema.primary,
          minimumSize: tailleMinBouton,
          shape: formeBouton,
          textStyle: textes.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: schema.primary,
          minimumSize: tailleMinBouton,
          padding: paddingBouton,
          shape: formeBouton,
          textStyle: textes.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: schema.primary,
        foregroundColor: schema.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRayons.l),
        ),
      ),

      // Champs de saisie.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: schema.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppEspacements.l,
          vertical: AppEspacements.m + 2,
        ),
        border: bordure(schema.outlineVariant),
        enabledBorder: bordure(schema.outlineVariant),
        focusedBorder: bordure(schema.primary, 2),
        errorBorder: bordure(schema.error),
        focusedErrorBorder: bordure(schema.error, 2),
        disabledBorder: bordure(schema.outlineVariant.withValues(alpha: 0.5)),
        hintStyle: textes.bodyLarge?.copyWith(color: schema.onSurfaceVariant),
        prefixIconColor: schema.onSurfaceVariant,
        suffixIconColor: schema.onSurfaceVariant,
        // Un message d'erreur long passe à la ligne au lieu d'être coupé.
        errorMaxLines: 3,
        helperMaxLines: 2,
      ),

      // Puces de filtre ("Tout", "Voirie"…).
      chipTheme: ChipThemeData(
        backgroundColor: couleurs.surfaceFlottante,
        selectedColor: schema.primary,
        side: BorderSide(color: schema.outlineVariant),
        shape: const StadiumBorder(),
        showCheckmark: false,
        labelStyle: textes.labelLarge?.copyWith(color: schema.onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspacements.s,
          vertical: AppEspacements.xs,
        ),
        iconTheme: IconThemeData(
          size: AppTailles.iconeS + 2,
          color: schema.primary,
        ),
      ),

      cardTheme: CardThemeData(
        color: schema.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRayons.l),
          side: BorderSide(color: schema.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),

      // Feuille du bas (détail d'un signalement par-dessus la carte).
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: schema.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: schema.outlineVariant,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRayons.xl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: schema.inverseSurface,
        contentTextStyle: textes.bodyMedium?.copyWith(
          color: schema.onInverseSurface,
        ),
        actionTextColor: schema.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRayons.m),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: schema.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRayons.xl),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: schema.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: schema.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppEspacements.l,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: schema.primary),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: schema.primary,
        selectionColor: schema.primary.withValues(alpha: 0.3),
        selectionHandleColor: schema.primary,
      ),
    );
  }
}

/// Convertit le choix enregistré (couche data) en ThemeMode de Flutter.
/// `stockage.lirePreferenceTheme().themeMode`
extension PreferenceThemeVersThemeMode on PreferenceTheme {
  ThemeMode get themeMode => switch (this) {
    PreferenceTheme.systeme => ThemeMode.system,
    PreferenceTheme.clair => ThemeMode.light,
    PreferenceTheme.sombre => ThemeMode.dark,
  };
}

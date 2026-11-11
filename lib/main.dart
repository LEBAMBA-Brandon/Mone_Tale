import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_theme.dart';
import 'package:tala/data/services/stockage_local_service.dart';
import 'package:tala/module/binding/initial_binding.dart';
import 'package:tala/module/routes/app_pages.dart';
import 'package:tala/module/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GetStorage doit être prêt AVANT de lire le thème ET la session…
  await StockageLocalService.initialiser();
  // …et le thème doit être connu AVANT le 1er écran (pas de "clignotement").
  final themeMode = StockageLocalService().lirePreferenceTheme().themeMode;

  runApp(TalaApp(themeMode: themeMode));
}

class TalaApp extends StatelessWidget {
  const TalaApp({super.key, required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'tala',
      debugShowCheckedModeBanner: false,

      // Thèmes
      theme: AppTheme.clair,
      darkTheme: AppTheme.sombre,
      themeMode: themeMode,

      // Interface Material en français (boutons système, calendrier…)
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Navigation GetX.
      // On vise TOUJOURS l'accueil : si personne n'est connecté,
      // AuthMiddleware redirige vers l'écran de connexion.
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.accueil,
      getPages: AppPages.pages,
      unknownRoute: AppPages.introuvable,
      defaultTransition: Transition.cupertino,

      // Texte du téléphone très grand : respecté jusqu'à 130 %, au-delà
      // les écrans deviendraient illisibles.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

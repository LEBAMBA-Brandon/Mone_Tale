import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_theme.dart';
import 'package:mono/data/services/stockage_local_service.dart';
import 'package:mono/modules/binding/initial_binding.dart';
import 'package:mono/modules/routes/app_pages.dart';
import 'package:mono/modules/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GetStorage doit être prêt AVANT de lire le thème…
  await StockageLocalService.initialiser();
  // …et le thème doit être connu AVANT le 1er écran (pas de "clignotement").
  final themeMode = StockageLocalService().lirePreferenceTheme().themeMode;

  runApp(MonoApp(themeMode: themeMode));
}

class MonoApp extends StatelessWidget {
  const MonoApp({super.key, required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mono',
      debugShowCheckedModeBanner: false,

      // Thèmes
      theme: AppTheme.clair,
      darkTheme: AppTheme.sombre,
      themeMode: themeMode,

      // Interface Material en français
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Navigation GetX
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.carte,
      getPages: AppPages.pages,
      unknownRoute: AppPages.introuvable,
      defaultTransition: Transition.cupertino,

      // Si l'utilisateur a réglé un texte ÉNORME dans son téléphone, on le
      // respecte jusqu'à 130 % : au-delà, les écrans deviendraient illisibles.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

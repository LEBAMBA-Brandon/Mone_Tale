import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/widget/etat_message.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Affichée pour une route inconnue ou un lien avec un id invalide.
class PageIntrouvableScreen extends StatelessWidget {
  const PageIntrouvableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: SafeArea(
        child: EtatMessage.vide(
          icone: Icons.search_off,
          titre: 'Page introuvable',
          message: "Ce lien ne correspond à aucune page de l'application.",
          libelleAction: "Retour à l'accueil",
          onAction: () => Get.offAllNamed<void>(AppRoutes.accueil),
        ),
      ),
    );
  }
}

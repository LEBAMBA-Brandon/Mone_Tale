import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mono/core/widget/etat_message.dart';
import 'package:mono/modules/routes/app_routes.dart';

/// Affichée pour une route inconnue ou un lien de signalement invalide.
class PageIntrouvableScreen extends StatelessWidget {
  const PageIntrouvableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: SafeArea(
        child: EtatMessage.vide(
          icone: Icons.wrong_location_outlined,
          titre: 'Page introuvable',
          message: 'Ce lien ne correspond à aucun signalement.',
          libelleAction: 'Retour à la carte',
          onAction: () => Get.offAllNamed<void>(AppRoutes.carte),
        ),
      ),
    );
  }
}

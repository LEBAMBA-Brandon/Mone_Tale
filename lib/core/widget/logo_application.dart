import 'package:flutter/material.dart';
import 'package:mono/core/theme/couleurs_mono.dart';

/// Logo mono (l'épingle rouge avec le panneau d'alerte).
class LogoApplication extends StatelessWidget {
  const LogoApplication({super.key, this.taille = 40});

  /// Chemin de l'image (déclarée dans pubspec.yaml → assets/images/).
  static const String chemin = 'assets/images/mono_logo.png';

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      chemin,
      width: taille,
      height: taille,
      fit: BoxFit.contain,
      semanticLabel: 'Logo mono',
      // Si l'image est introuvable (oubli dans pubspec.yaml…), on affiche
      // une icône au lieu du gros carré rouge d'erreur de Flutter.
      errorBuilder: (context, erreur, trace) =>
          Icon(Icons.location_on, size: taille, color: context.schema.error),
    );
  }
}

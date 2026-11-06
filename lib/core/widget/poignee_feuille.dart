import 'package:flutter/material.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/couleurs_mono.dart';

/// Petite barre grise en haut d'une feuille qu'on peut faire glisser
/// (le détail d'un signalement qui monte par-dessus la carte).
class PoigneeFeuille extends StatelessWidget {
  const PoigneeFeuille({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Faire glisser pour agrandir ou fermer',
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppEspacements.m),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.schema.outlineVariant,
            borderRadius: BorderRadius.circular(AppRayons.rond),
          ),
        ),
      ),
    );
  }
}

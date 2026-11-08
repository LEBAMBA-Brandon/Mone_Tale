import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/couleurs_tala.dart';

/// Cercle de chargement centré, avec un message facultatif.
///
/// S'il y a très peu de hauteur (< 100 px), seul le cercle est affiché
/// (plus petit) pour ne jamais déborder.
class IndicateurChargement extends StatelessWidget {
  const IndicateurChargement({super.key, this.message});

  /// Ex : "Chargement des signalements…"
  final String? message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final petit = contraintes.maxHeight < 100 || contraintes.maxWidth < 120;
        final taille = petit ? 20.0 : 32.0;

        final cercle = SizedBox.square(
          dimension: taille,
          child: CircularProgressIndicator(
            strokeWidth: petit ? 2 : 3,
            semanticsLabel: message ?? 'Chargement',
          ),
        );

        if (petit || message == null) return Center(child: cercle);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppEspacements.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                cercle,
                const SizedBox(height: AppEspacements.m),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textes.bodyMedium?.copyWith(
                    color: context.schema.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

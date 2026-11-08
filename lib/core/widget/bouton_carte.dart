import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/theme/couleurs_tala.dart';

/// Bouton rond flottant posé sur la carte (ex : "Autour de moi").
///
/// - Avec un [libelle] → pilule "icône + texte".
/// - Sur un écran minuscule (< 280 px), le texte est masqué
///   automatiquement : il ne reste que l'icône (avec une infobulle).
class BoutonCarte extends StatelessWidget {
  const BoutonCarte({
    super.key,
    required this.icone,
    required this.onPressed,
    this.libelle,
    this.chargement = false,
    this.infobulle,
  });

  final IconData icone;
  final VoidCallback? onPressed;
  final String? libelle;
  final bool chargement;

  /// Texte affiché en appui long (et lu par le lecteur d'écran).
  final String? infobulle;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    final afficherLibelle =
        libelle != null && context.largeurEcran >= AppResponsive.seuilMinuscule;

    final bouton = Material(
      color: context.couleurs.surfaceFlottante,
      elevation: 3,
      shadowColor: context.couleurs.ombre,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: chargement ? null : onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppTailles.toucheMin,
            minHeight: AppTailles.toucheMin,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: afficherLibelle ? AppEspacements.l : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (chargement)
                  SizedBox.square(
                    dimension: AppTailles.iconeM,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Chargement',
                      color: schema.primary,
                    ),
                  )
                else
                  Icon(icone, color: schema.primary),
                if (afficherLibelle) ...[
                  const SizedBox(width: AppEspacements.s),
                  Text(
                    libelle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textes.labelLarge?.copyWith(
                      color: schema.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final message = infobulle ?? libelle;
    if (message == null) return bouton;
    return Tooltip(message: message, child: bouton);
  }
}

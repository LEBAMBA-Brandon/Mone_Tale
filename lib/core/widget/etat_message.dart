import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/bouton_principal.dart';

/// Écran d'état "à la place du contenu" : erreur, liste vide, hors ligne.
///
/// Exemples :
/// ```dart
/// EtatMessage.erreur(message: erreur.message, onReessayer: controller.charger)
/// EtatMessage.vide(titre: 'Aucun signalement', message: 'Essayez un autre filtre.')
/// EtatMessage.horsLigne(onReessayer: controller.charger)
/// ```
/// S'adapte à la place disponible : en dessous de 260 px de haut ou de
/// 280 px de large, il passe en version compacte. Il est aussi scrollable :
/// il ne déborde JAMAIS, même dans un cadre de 150 × 150 px.
class EtatMessage extends StatelessWidget {
  const EtatMessage({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.libelleAction,
    this.onAction,
    this.estErreur = false,
  });

  /// Une erreur avec un bouton "Réessayer".
  const EtatMessage.erreur({
    super.key,
    required String this.message,
    VoidCallback? onReessayer,
    this.titre = 'Un problème est survenu',
  }) : icone = Icons.error_outline,
       libelleAction = 'Réessayer',
       onAction = onReessayer,
       estErreur = true;

  /// Rien à afficher (ex : aucun signalement pour ce filtre).
  const EtatMessage.vide({
    super.key,
    required this.titre,
    this.message,
    this.libelleAction,
    this.onAction,
    this.icone = Icons.inbox_outlined,
  }) : estErreur = false;

  /// Pas de connexion internet.
  const EtatMessage.horsLigne({super.key, VoidCallback? onReessayer})
    : icone = Icons.wifi_off_rounded,
      titre = 'Pas de connexion',
      message = 'Vérifiez votre connexion internet puis réessayez.',
      libelleAction = 'Réessayer',
      onAction = onReessayer,
      estErreur = true;

  final IconData icone;
  final String titre;
  final String? message;
  final String? libelleAction;
  final VoidCallback? onAction;
  final bool estErreur;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;

    return LayoutBuilder(
      builder: (context, contraintes) {
        final compact =
            contraintes.maxHeight < 260 ||
            contraintes.maxWidth < AppResponsive.seuilMinuscule;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              compact ? AppEspacements.s : AppEspacements.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icone,
                    size: compact ? AppTailles.iconeXl : 56,
                    color: estErreur ? schema.error : schema.onSurfaceVariant,
                  ),
                  SizedBox(
                    height: compact ? AppEspacements.s : AppEspacements.l,
                  ),
                  Text(
                    titre,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? context.textes.titleSmall
                        : context.textes.titleMedium,
                  ),
                  if (message != null) ...[
                    SizedBox(
                      height: compact ? AppEspacements.xs : AppEspacements.s,
                    ),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      maxLines: compact ? 3 : 6,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? context.textes.bodySmall
                                  : context.textes.bodyMedium)
                              ?.copyWith(color: schema.onSurfaceVariant),
                    ),
                  ],
                  if (onAction != null && libelleAction != null) ...[
                    SizedBox(
                      height: compact ? AppEspacements.s : AppEspacements.xl,
                    ),
                    BoutonPrincipal(
                      libelle: libelleAction!,
                      icone: estErreur ? Icons.refresh : null,
                      onPressed: onAction,
                      // En compact, un bouton texte prend moins de place.
                      variante: compact
                          ? VarianteBouton.texte
                          : VarianteBouton.plein,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

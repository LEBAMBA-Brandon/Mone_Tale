import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';

/// Les 3 apparences possibles du bouton.
enum VarianteBouton {
  /// Fond vert plein : l'action principale de l'écran (une seule par écran).
  plein,

  /// Bordure verte : action secondaire.
  contour,

  /// Texte vert seul : action discrète ("Annuler"…).
  texte,
}

/// Bouton de l'application avec état de chargement intégré.
///
/// - [chargement] = true → affiche un petit cercle qui tourne, et les
///   appuis sont IGNORÉS (évite d'envoyer 2 fois la même action).
/// - Le texte ne déborde jamais : il est coupé avec "…" si la place manque.
/// - [pleineLargeur] : prend toute la largeur (à utiliser dans une Column).
/// - [progression] (0.0 → 1.0) : pendant un envoi long (photo), le cercle
///   se remplit et le pourcentage s'affiche : "Envoi… 45 %".
class BoutonPrincipal extends StatelessWidget {
  const BoutonPrincipal({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.icone,
    this.chargement = false,
    this.pleineLargeur = false,
    this.variante = VarianteBouton.plein,
    this.progression,
  });

  final String libelle;

  /// `null` → bouton désactivé (grisé).
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool chargement;
  final bool pleineLargeur;
  final VarianteBouton variante;

  /// `null` = chargement sans durée connue (le cercle tourne).
  final double? progression;

  static void _ignorer() {}

  @override
  Widget build(BuildContext context) {
    // Pendant le chargement, le bouton garde ses couleurs (il n'est pas grisé)
    // mais ne fait rien quand on appuie dessus.
    final action = onPressed == null
        ? null
        : (chargement ? _ignorer : onPressed);
    final progression = this.progression;
    final contenu = _ContenuBouton(
      // Pendant l'envoi : "Envoyer" devient "Envoyer… 45 %".
      libelle: chargement && progression != null
          ? '$libelle… ${(progression * 100).round()} %'
          : libelle,
      icone: icone,
      chargement: chargement,
      progression: progression,
    );

    final bouton = switch (variante) {
      VarianteBouton.plein => FilledButton(onPressed: action, child: contenu),
      VarianteBouton.contour => OutlinedButton(
        onPressed: action,
        child: contenu,
      ),
      VarianteBouton.texte => TextButton(onPressed: action, child: contenu),
    };

    if (!pleineLargeur) return bouton;
    return SizedBox(width: double.infinity, child: bouton);
  }
}

class _ContenuBouton extends StatelessWidget {
  const _ContenuBouton({
    required this.libelle,
    required this.icone,
    required this.chargement,
    required this.progression,
  });

  final String libelle;
  final IconData? icone;
  final bool chargement;
  final double? progression;

  @override
  Widget build(BuildContext context) {
    // Le bouton transmet sa couleur de texte via IconTheme : le cercle de
    // chargement prend donc automatiquement la bonne couleur.
    final couleur = IconTheme.of(context).color;

    final Widget? prefixe = chargement
        ? SizedBox.square(
            dimension: AppTailles.iconeM - 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: couleur,
              // value null = cercle qui tourne ; 0.0 → 1.0 = cercle qui se remplit.
              value: progression?.clamp(0.0, 1.0),
              semanticsLabel: 'Chargement',
            ),
          )
        : (icone == null ? null : Icon(icone, size: AppTailles.iconeM));

    final texte = Text(
      libelle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    return LayoutBuilder(
      builder: (context, contraintes) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefixe != null) ...[
            prefixe,
            const SizedBox(width: AppEspacements.s),
          ],
          // Flexible = le texte se réduit (avec "…") au lieu de déborder.
          // Seulement possible si la largeur est limitée, sinon Flutter plante.
          if (contraintes.hasBoundedWidth) Flexible(child: texte) else texte,
        ],
      ),
    );
  }
}

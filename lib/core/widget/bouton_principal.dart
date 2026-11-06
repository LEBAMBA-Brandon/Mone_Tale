import 'package:flutter/material.dart';
import 'package:mono/core/theme/app_dimensions.dart';

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
class BoutonPrincipal extends StatelessWidget {
  const BoutonPrincipal({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.icone,
    this.chargement = false,
    this.pleineLargeur = false,
    this.variante = VarianteBouton.plein,
  });

  final String libelle;

  /// `null` → bouton désactivé (grisé).
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool chargement;
  final bool pleineLargeur;
  final VarianteBouton variante;

  static void _ignorer() {}

  @override
  Widget build(BuildContext context) {
    // Pendant le chargement, le bouton garde ses couleurs (il n'est pas grisé)
    // mais ne fait rien quand on appuie dessus.
    final action = onPressed == null
        ? null
        : (chargement ? _ignorer : onPressed);
    final contenu = _ContenuBouton(
      libelle: libelle,
      icone: icone,
      chargement: chargement,
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
  });

  final String libelle;
  final IconData? icone;
  final bool chargement;

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

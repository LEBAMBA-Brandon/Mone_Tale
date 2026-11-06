import 'package:flutter/material.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_icons.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/data/models/categorie.dart';
import 'package:mono/data/models/gravite.dart';
import 'package:mono/data/models/statut.dart';

/// Petite étiquette colorée en forme de pilule (ex : "Critique", "Résolu").
/// La couleur du texte (blanc ou noir) est choisie automatiquement
/// pour rester lisible sur la couleur de fond.
class BadgeInfo extends StatelessWidget {
  const BadgeInfo({
    super.key,
    required this.libelle,
    required this.couleur,
    this.icone,
  });

  final String libelle;
  final Color couleur;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final texte = CouleursMono.texteSur(couleur);

    return ConstrainedBox(
      // Largeur max : le texte peut être coupé avec "…" sans jamais déborder.
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspacements.s + 2,
          vertical: AppEspacements.xs,
        ),
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(AppRayons.rond),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: AppTailles.iconeS - 2, color: texte),
              const SizedBox(width: AppEspacements.xs),
            ],
            Flexible(
              child: Text(
                libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textes.labelMedium?.copyWith(
                  color: texte,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de la catégorie, avec sa couleur et son icône.
class BadgeCategorie extends StatelessWidget {
  const BadgeCategorie(this.categorie, {super.key});
  final Categorie categorie;

  @override
  Widget build(BuildContext context) => BadgeInfo(
    libelle: categorie.libelle,
    icone: categorie.icone,
    couleur: context.couleurs.categorie(categorie),
  );
}

/// Badge de la gravité (vert / ambre / rouge).
class BadgeGravite extends StatelessWidget {
  const BadgeGravite(this.gravite, {super.key});
  final Gravite gravite;

  @override
  Widget build(BuildContext context) => BadgeInfo(
    libelle: gravite.libelle,
    icone: gravite.icone,
    couleur: context.couleurs.gravite(gravite),
  );
}

/// Badge du statut (bleu / ambre / vert).
class BadgeStatut extends StatelessWidget {
  const BadgeStatut(this.statut, {super.key});
  final Statut statut;

  @override
  Widget build(BuildContext context) => BadgeInfo(
    libelle: statut.libelle,
    icone: statut.icone,
    couleur: context.couleurs.statut(statut),
  );
}

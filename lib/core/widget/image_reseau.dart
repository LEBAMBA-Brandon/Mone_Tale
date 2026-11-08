import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/couleurs_tala.dart';

/// Photo venant de l'API, avec tous les cas gérés :
/// - pas d'URL → "Aucune photo"
/// - en cours de téléchargement → fond gris + cercle de progression
/// - erreur (serveur éteint, fichier supprimé…) → "Photo indisponible"
/// - succès → apparition en fondu
///
/// Optimisation : l'image est décodée à la taille AFFICHÉE (`cacheWidth`),
/// pas à sa taille d'origine (une photo de téléphone fait souvent 4000 px).
/// Ça divise fortement la mémoire utilisée.
class ImageReseau extends StatelessWidget {
  const ImageReseau({
    super.key,
    required this.url,
    this.ratio = 4 / 3,
    this.rayon = AppRayons.l,
    this.fit = BoxFit.cover,
    this.description,
  });

  final String? url;

  /// Rapport largeur / hauteur. `null` → c'est le parent qui impose la taille.
  final double? ratio;
  final double rayon;
  final BoxFit fit;

  /// Texte lu par le lecteur d'écran (accessibilité).
  final String? description;

  @override
  Widget build(BuildContext context) {
    final contenu = ClipRRect(
      borderRadius: BorderRadius.circular(rayon),
      child: ColoredBox(
        color: context.couleurs.squelette,
        child: LayoutBuilder(builder: _construireImage),
      ),
    );

    if (ratio == null) return contenu;
    return AspectRatio(aspectRatio: ratio!, child: contenu);
  }

  Widget _construireImage(BuildContext context, BoxConstraints contraintes) {
    final adresse = url;
    if (adresse == null || adresse.isEmpty) {
      return const _Remplacement(
        icone: Icons.no_photography_outlined,
        texte: 'Aucune photo',
      );
    }

    final largeur = contraintes.hasBoundedWidth ? contraintes.maxWidth : null;
    final hauteur = contraintes.hasBoundedHeight ? contraintes.maxHeight : null;
    final largeurPixels = largeur == null
        ? null
        : (largeur * MediaQuery.devicePixelRatioOf(context)).round();

    return Image.network(
      adresse,
      width: largeur,
      height: hauteur,
      fit: fit,
      cacheWidth: largeurPixels,
      semanticLabel: description,
      gaplessPlayback: true,
      // Apparition en fondu quand l'image arrive.
      frameBuilder: (context, enfant, frame, dejaEnCache) {
        if (dejaEnCache) return enfant;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppDurees.normale,
          child: enfant,
        );
      },
      loadingBuilder: (context, enfant, progression) {
        if (progression == null) return enfant; // chargement terminé
        final total = progression.expectedTotalBytes;
        return Center(
          child: SizedBox.square(
            dimension: AppTailles.iconeL,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: 'Chargement de la photo',
              value: total == null
                  ? null
                  : progression.cumulativeBytesLoaded / total,
            ),
          ),
        );
      },
      errorBuilder: (context, erreur, trace) => const _Remplacement(
        icone: Icons.broken_image_outlined,
        texte: 'Photo indisponible',
      ),
    );
  }
}

/// Icône + texte à la place de l'image. Si la place est très petite,
/// on n'affiche que l'icône.
class _Remplacement extends StatelessWidget {
  const _Remplacement({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final couleur = context.schema.onSurfaceVariant;
    return LayoutBuilder(
      builder: (context, contraintes) {
        final petit = contraintes.maxHeight < 80 || contraintes.maxWidth < 100;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppEspacements.s),
            child: petit
                ? Icon(icone, color: couleur, semanticLabel: texte)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icone, color: couleur, size: AppTailles.iconeXl),
                      const SizedBox(height: AppEspacements.xs),
                      Text(
                        texte,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textes.bodySmall?.copyWith(
                          color: couleur,
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

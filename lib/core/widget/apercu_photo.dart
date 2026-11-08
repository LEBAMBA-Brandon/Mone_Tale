import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/data/models/photo_signalement.dart';

/// Zone "Photo" du formulaire "Ajouter un signalement".
///
/// - Pas encore de photo → grand cadre avec "Prendre une photo"
///   (+ "Galerie" si [onGalerie] est donné, utile sur l'émulateur).
/// - Photo prise → aperçu + poids ("320 Ko") + bouton "Reprendre".
/// - [erreur] → cadre et message en rouge.
///
/// ⚠️ `Image.file` lit un fichier du téléphone : tala est une app mobile
/// (Android/iOS), ce widget ne marche pas sur le web.
class ApercuPhoto extends StatelessWidget {
  const ApercuPhoto({
    super.key,
    required this.photo,
    required this.onPrendre,
    this.onGalerie,
    this.onRetirer,
    this.chargement = false,
    this.erreur,
  });

  final PhotoSignalement? photo;
  final VoidCallback onPrendre;
  final VoidCallback? onGalerie;
  final VoidCallback? onRetirer;

  /// `true` pendant que l'appareil photo s'ouvre / la photo est traitée.
  final bool chargement;
  final String? erreur;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    final erreur = this.erreur;
    final photo = this.photo;

    final cadre = AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: schema.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRayons.l),
          border: Border.all(
            color: erreur != null ? schema.error : schema.outlineVariant,
            width: erreur != null ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: chargement
            ? const Center(child: CircularProgressIndicator())
            : (photo == null ? _videAvecBoutons(context) : _image(context, photo)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cadre,
        if (erreur != null) ...[
          const SizedBox(height: AppEspacements.xs),
          Text(
            erreur,
            style: context.textes.bodySmall?.copyWith(color: schema.error),
          ),
        ],
      ],
    );
  }

  /// Cadre vide : un grand bouton facile à toucher, même avec des gants.
  Widget _videAvecBoutons(BuildContext context) {
    final schema = context.schema;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPrendre,
        child: LayoutBuilder(
          builder: (context, contraintes) {
            final petit = contraintes.maxHeight < 140;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppEspacements.s),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.photo,
                      size: petit ? AppTailles.iconeXl : 56,
                      color: schema.primary,
                    ),
                    if (!petit) ...[
                      const SizedBox(height: AppEspacements.s),
                      Text(
                        'Prendre une photo',
                        textAlign: TextAlign.center,
                        style: context.textes.titleMedium?.copyWith(
                          color: schema.primary,
                        ),
                      ),
                    ],
                    if (onGalerie != null)
                      TextButton.icon(
                        onPressed: onGalerie,
                        icon: const Icon(AppIcons.galerie),
                        label: const Text('Galerie'),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _image(BuildContext context, PhotoSignalement photo) {
    final schema = context.schema;
    return LayoutBuilder(
      builder: (context, contraintes) => Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(photo.chemin),
            fit: BoxFit.cover,
            // Décodée à la taille affichée : économise la mémoire.
            cacheWidth: (contraintes.maxWidth *
                    MediaQuery.devicePixelRatioOf(context))
                .round(),
            semanticLabel: 'Photo du signalement',
            errorBuilder: (context, erreur, trace) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: schema.onSurfaceVariant,
              ),
            ),
          ),
          // Bandeau du bas : poids + actions, sur un dégradé sombre pour
          // rester lisible quelle que soit la photo.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB3000000)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppEspacements.m,
                  AppEspacements.l,
                  AppEspacements.xs,
                  AppEspacements.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        photo.tailleLisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textes.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reprendre la photo',
                      onPressed: onPrendre,
                      icon: const Icon(AppIcons.reprendre, color: Colors.white),
                    ),
                    if (onRetirer != null)
                      IconButton(
                        tooltip: 'Retirer la photo',
                        onPressed: onRetirer,
                        icon: const Icon(AppIcons.supprimer, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

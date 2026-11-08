import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/badge_info.dart';
import 'package:tala/core/widget/image_reseau.dart';
import 'package:tala/data/models/signalement.dart';

/// Un signalement dans une liste ("Mes signalements", écran admin).
///
/// Comme sur la maquette : la photo à gauche, les infos à droite
/// (catégorie, statut, description, quartier, date).
///
/// - [afficherAuteur] : l'admin voit QUI a fait le signalement ;
///   inutile pour le collecteur (c'est forcément lui).
/// - Écran minuscule (< 280 px) : la photo passe AU-DESSUS des infos.
class CarteSignalement extends StatelessWidget {
  const CarteSignalement({
    super.key,
    required this.signalement,
    this.onTap,
    this.afficherAuteur = false,
  });

  final Signalement signalement;
  final VoidCallback? onTap;
  final bool afficherAuteur;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppEspacements.m),
          child: LayoutBuilder(
            builder: (context, contraintes) {
              final photo = ImageReseau(
                url: signalement.photoUrl,
                ratio: 1,
                rayon: AppRayons.m,
                description: 'Photo : ${signalement.categorie.libelle}',
              );
              final infos = _Infos(
                signalement: signalement,
                afficherAuteur: afficherAuteur,
              );

              if (contraintes.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    photo,
                    const SizedBox(height: AppEspacements.s),
                    infos,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(dimension: AppTailles.miniature, child: photo),
                  const SizedBox(width: AppEspacements.m),
                  // Expanded : les infos prennent le reste de la largeur,
                  // et les textes trop longs sont coupés avec "…".
                  Expanded(child: infos),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Infos extends StatelessWidget {
  const _Infos({required this.signalement, required this.afficherAuteur});

  final Signalement signalement;
  final bool afficherAuteur;

  @override
  Widget build(BuildContext context) {
    final discret = context.textes.bodySmall?.copyWith(
      color: context.schema.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap : si les 2 badges ne tiennent pas sur une ligne,
        // le 2e passe dessous (pas de débordement).
        Wrap(
          spacing: AppEspacements.xs,
          runSpacing: AppEspacements.xs,
          children: [
            BadgeCategorie(signalement.categorie),
            BadgeStatut(signalement.statut),
          ],
        ),
        const SizedBox(height: AppEspacements.s),
        Text(
          signalement.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textes.bodyMedium,
        ),
        const SizedBox(height: AppEspacements.xs),
        Text(
          '${signalement.nomQuartier} · ${AppFormats.depuis(signalement.dateCreation)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: discret,
        ),
        if (afficherAuteur) ...[
          const SizedBox(height: AppEspacements.xxs),
          Row(
            children: [
              Icon(
                AppIcons.auteur,
                size: AppTailles.iconeS,
                color: context.schema.onSurfaceVariant,
              ),
              const SizedBox(width: AppEspacements.xs),
              Expanded(
                child: Text(
                  signalement.nomAuteur,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: discret,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

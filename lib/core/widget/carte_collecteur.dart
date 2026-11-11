import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/avatar_utilisateur.dart';
import 'package:tala/data/models/utilisateur.dart';

/// Un collecteur dans la liste de l'admin : avatar avec son nombre de
/// signalements, nom et prénom, e-mail. Un appui ouvre sa page détail.
class CarteCollecteur extends StatelessWidget {
  const CarteCollecteur({super.key, required this.collecteur, this.onTap});

  final Utilisateur collecteur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nombre = collecteur.nombreSignalements;
    final discret = context.textes.bodySmall?.copyWith(
      color: context.schema.onSurfaceVariant,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspacements.m,
            vertical: AppEspacements.m,
          ),
          child: Row(
            children: [
              AvatarUtilisateur(utilisateur: collecteur, afficherCompteur: true),
              const SizedBox(width: AppEspacements.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collecteur.nomEtPrenom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textes.titleMedium,
                    ),
                    const SizedBox(height: AppEspacements.xxs),
                    Text(
                      // E-mail masqué (donnée personnelle).
                      AppFormats.emailMasque(collecteur.email),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: discret,
                    ),
                    if (nombre != null)
                      Text(
                        AppFormats.pluriel(nombre, 'signalement'),
                        maxLines: 1,
                        style: discret,
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(AppIcons.suivant, color: context.schema.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

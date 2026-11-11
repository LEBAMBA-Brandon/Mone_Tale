import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';

/// Une section du Profil : un titre ("Mon contenu", "Compte"…) et une
/// carte qui contient des lignes cliquables séparées par un trait.
/// ```dart
/// SectionMenu(
///   titre: 'Compte',
///   elements: [
///     ElementMenu(icone: AppIcons.notifications, titre: 'Notifications', ...),
///     ElementMenu(icone: AppIcons.modifier, titre: 'Modifier mes informations', onTap: ...),
///   ],
/// )
/// ```
class SectionMenu extends StatelessWidget {
  const SectionMenu({super.key, required this.titre, required this.elements});

  final String titre;
  final List<Widget> elements;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppEspacements.xs,
            bottom: AppEspacements.s,
          ),
          child: Text(
            titre,
            style: context.textes.titleSmall?.copyWith(
              color: context.schema.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < elements.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                elements[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une ligne de menu : icône, titre, sous-titre facultatif, et à droite
/// une flèche (par défaut) ou un autre widget ([fin], ex : un interrupteur).
class ElementMenu extends StatelessWidget {
  const ElementMenu({
    super.key,
    required this.icone,
    required this.titre,
    this.sousTitre,
    this.onTap,
    this.fin,
    this.couleur,
  });

  final IconData icone;
  final String titre;
  final String? sousTitre;
  final VoidCallback? onTap;

  /// Widget à droite. `null` → une flèche ">" si la ligne est cliquable.
  final Widget? fin;

  /// Couleur de l'icône et du titre (ex : rouge pour "Se déconnecter").
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final sousTitre = this.sousTitre;
    return ListTile(
      onTap: onTap,
      minTileHeight: AppTailles.toucheMin + AppEspacements.s,
      leading: Icon(icone, color: couleur ?? context.schema.primary),
      title: Text(
        titre,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: couleur == null ? null : TextStyle(color: couleur),
      ),
      subtitle: sousTitre == null
          ? null
          : Text(sousTitre, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing:
          fin ??
          (onTap == null
              ? null
              : Icon(AppIcons.suivant, color: context.schema.onSurfaceVariant)),
    );
  }
}

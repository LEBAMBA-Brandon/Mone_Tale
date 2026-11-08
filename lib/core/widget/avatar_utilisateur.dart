import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/data/models/utilisateur.dart';

/// Rond avec les initiales d'un utilisateur ("MJ" pour Mba Jean),
/// et en option une pastille avec son nombre de signalements.
///
/// Les utilisateurs n'ont pas de photo dans l'API : les initiales
/// permettent quand même de les reconnaître d'un coup d'œil.
class AvatarUtilisateur extends StatelessWidget {
  const AvatarUtilisateur({
    super.key,
    required this.utilisateur,
    this.taille = AppTailles.avatar,
    this.afficherCompteur = false,
  });

  final Utilisateur utilisateur;
  final double taille;

  /// `true` → pastille "12" en haut à droite (si le nombre est connu).
  final bool afficherCompteur;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    final nombre = utilisateur.nombreSignalements;

    final rond = Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: schema.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        utilisateur.initiales,
        maxLines: 1,
        style: TextStyle(
          color: schema.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          // La taille du texte suit celle du rond.
          fontSize: taille * 0.38,
        ),
      ),
    );

    final Widget avatar = (!afficherCompteur || nombre == null)
        ? rond
        // `Badge` (Material 3) : pastille posée sur un widget.
        // Au-delà de 99, on affiche "99+" pour que la pastille reste petite.
        : Badge(
            label: Text(nombre > 99 ? '99+' : '$nombre'),
            offset: const Offset(4, -4),
            child: rond,
          );

    // Le lecteur d'écran lit une phrase claire au lieu de "M J 12".
    return Semantics(
      label: afficherCompteur && nombre != null
          ? '${utilisateur.nomEtPrenom}, '
                '${AppFormats.pluriel(nombre, 'signalement')}'
          : utilisateur.nomEtPrenom,
      excludeSemantics: true,
      child: avatar,
    );
  }
}

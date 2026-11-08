import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_responsive.dart';

/// Centre le contenu et limite sa largeur, avec des marges adaptées à
/// l'écran (8 px sur un écran minuscule → 32 px sur grand écran).
///
/// Sur téléphone, ça ne change presque rien. Sur tablette, ça évite un
/// formulaire étiré sur 1200 px de large, difficile à lire et à remplir.
/// ```dart
/// ContenuLimite(
///   largeurMax: AppTailles.largeurMaxFormulaire,
///   child: Column(children: [...]),
/// )
/// ```
/// ⚠️ Ne fait pas défiler : à mettre DANS un SingleChildScrollView ou une
/// ListView si le contenu peut être plus haut que l'écran.
class ContenuLimite extends StatelessWidget {
  const ContenuLimite({
    super.key,
    required this.child,
    this.largeurMax = AppTailles.largeurMaxContenu,
    this.margeVerticale = AppEspacements.l,
  });

  final Widget child;
  final double largeurMax;
  final double margeVerticale;

  @override
  Widget build(BuildContext context) {
    final marge = AppResponsive.margeHorizontale(context.largeurEcran);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeurMax),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: marge,
            vertical: margeVerticale,
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_icons.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/data/models/categorie.dart';
import 'package:mono/data/models/gravite.dart';

/// Épingle d'un signalement sur la carte, colorée selon sa catégorie,
/// avec l'icône de la catégorie dans un rond blanc.
///
/// - [selectionne] → l'épingle grossit (animation) : on voit lequel est ouvert.
/// - [critique] → petit point rouge en haut à droite.
///
/// Au J3, avec flutter_map :
/// `Marker(width: 56, height: 56, alignment: Alignment.topCenter, child: MarqueurSignalement(...))`
/// (`topCenter` = la POINTE de l'épingle est posée sur la position GPS)
class MarqueurSignalement extends StatelessWidget {
  const MarqueurSignalement({
    super.key,
    required this.categorie,
    this.selectionne = false,
    this.critique = false,
    this.taille = AppTailles.marqueur,
  });

  final Categorie categorie;
  final bool selectionne;
  final bool critique;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final couleur = context.couleurs.categorie(categorie);
    final diametreRond = taille * 0.42;

    return Semantics(
      label: 'Signalement ${categorie.libelle}${critique ? ', critique' : ''}',
      button: true,
      selected: selectionne,
      child: AnimatedScale(
        scale: selectionne ? 1.25 : 1,
        duration: AppDurees.rapide,
        curve: Curves.easeOutBack,
        // Grossit depuis la pointe : l'épingle reste au bon endroit.
        alignment: Alignment.bottomCenter,
        child: SizedBox.square(
          dimension: taille,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // 1) L'OMBRE : une copie noire, floue et décalée de 2 px vers
              //    le bas, dessinée EN PREMIER (donc derrière tout le reste).
              //    ⚠️ On n'utilise pas `Icon(shadows: ...)` : une icône est un
              //    caractère de police, et les ombres de texte sont mal
              //    rendues sur certains téléphones (ombre peinte par-dessus).
              Transform.translate(
                offset: const Offset(0, 2),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Icon(
                    Icons.location_on,
                    size: taille,
                    color: const Color(0x55000000),
                  ),
                ),
              ),

              // 2) L'épingle colorée.
              Icon(Icons.location_on, size: taille, color: couleur),

              // 3) Le rond blanc avec l'icône de la catégorie.
              Positioned(
                top: taille * 0.14,
                child: Container(
                  width: diametreRond,
                  height: diametreRond,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categorie.icone,
                    size: taille * 0.26,
                    color: couleur,
                  ),
                ),
              ),

              // 4) Le point rouge "critique".
              if (critique)
                Positioned(
                  top: taille * 0.06,
                  right: taille * 0.12,
                  child: Container(
                    width: taille * 0.24,
                    height: taille * 0.24,
                    decoration: BoxDecoration(
                      color: context.couleurs.gravite(Gravite.critique),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

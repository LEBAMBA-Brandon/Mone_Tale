import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/apercu_photo.dart';
import 'package:tala/core/widget/bouton_principal.dart';
import 'package:tala/core/widget/champ_liste.dart';
import 'package:tala/core/widget/champ_texte.dart';
import 'package:tala/core/widget/selecteur_choix.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/gravite.dart';
import 'package:tala/data/models/nouveau_signalement.dart';
import 'package:tala/data/models/quartier.dart';
import 'package:tala/module/controller/ajout_signalement_controller.dart';
import 'package:tala/module/screens/collecteur/section_position.dart';

/// Onglet "Ajouter un signalement" du collecteur.
///
/// Ordre des champs = ordre des gestes sur le terrain :
/// 1. Photo (on la prend en arrivant)
/// 2. Position (déjà trouvée par le GPS)
/// 3. Catégorie, 4. Gravité (un appui chacune)
/// 5. Quartier (souvent déjà rempli)
/// 6. Description (la seule chose à taper)
///
/// Grand écran (≥ 840 px) : 2 colonnes, photo + position à gauche,
/// le reste à droite.
class AjoutSignalementVue extends GetView<AjoutSignalementController> {
  const AjoutSignalementVue({super.key});

  static const _espace = SizedBox(height: AppEspacements.xl);

  @override
  Widget build(BuildContext context) {
    // Partie "terrain" : ce qu'on voit (photo + position).
    final terrain = <Widget>[
      // Chaque zone a SON Obx : taper la description ne reconstruit
      // pas la photo, et inversement.
      Obx(
        () => ApercuPhoto(
          photo: controller.brouillon.value.photo,
          chargement: controller.photoEnCours.value,
          erreur: controller.erreurs['photo'],
          onPrendre: controller.prendrePhoto,
          onGalerie: controller.choisirDansGalerie,
          onRetirer: controller.brouillon.value.photo == null
              ? null
              : controller.retirerPhoto,
        ),
      ),
      _espace,
      const SectionPosition(),
    ];

    // Partie "description" : ce qu'on choisit et écrit.
    final details = <Widget>[
      Obx(
        () => SelecteurChoix<Categorie>(
          titre: 'Catégorie',
          options: Categorie.values,
          valeur: controller.brouillon.value.categorie,
          libelle: (c) => c.libelle,
          icone: (c) => c.icone,
          couleur: (c) => context.couleurs.categorie(c),
          erreur: controller.erreurs['categorie'],
          onChoix: controller.choisirCategorie,
        ),
      ),
      _espace,
      Obx(
        () => SelecteurChoix<Gravite>(
          titre: 'Gravité',
          options: Gravite.values,
          valeur: controller.brouillon.value.gravite,
          libelle: (g) => g.libelle,
          icone: (g) => g.icone,
          couleur: (g) => context.couleurs.gravite(g),
          erreur: controller.erreurs['gravite'],
          onChoix: controller.choisirGravite,
        ),
      ),
      _espace,
      const _ChampQuartier(),
      _espace,
      Obx(
        () => ChampTexte(
          libelle: 'Description',
          controller: controller.champDescription,
          icone: AppIcons.description,
          indication: "Ex : nid-de-poule profond devant l'école",
          longueurMax: NouveauSignalement.longueurMaxDescription,
          lignesMin: 2,
          lignesMax: 5,
          majuscules: TextCapitalization.sentences,
          erreur: controller.erreurs['description'],
          onChange: controller.surDescription,
        ),
      ),
      _espace,
      Obx(
        () => BoutonPrincipal(
          libelle: 'Envoyer',
          icone: AppIcons.envoyer,
          pleineLargeur: true,
          chargement: controller.envoiEnCours.value,
          progression: controller.progression.value,
          onPressed: controller.envoyer,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau signalement')),
      body: LayoutBuilder(
        builder: (context, contraintes) {
          final marge = AppResponsive.margeHorizontale(contraintes.maxWidth);
          // Grand écran : 2 colonnes qui occupent toute la largeur.
          final deuxColonnes = contraintes.maxWidth >= 840;

          return SingleChildScrollView(
            // Le clavier se ferme quand on fait défiler le formulaire.
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: marge,
              vertical: AppEspacements.l,
            ),
            child: deuxColonnes
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: terrain,
                        ),
                      ),
                      const SizedBox(width: AppEspacements.xxl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: details,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...terrain, _espace, ...details],
                  ),
          );
        },
      ),
    );
  }
}

/// Liste des quartiers avec recherche, + états chargement / erreur.
class _ChampQuartier extends GetView<AjoutSignalementController> {
  const _ChampQuartier();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final quartiers = controller.quartiers;
      final erreur = controller.erreurs['quartier_id'];

      // Liste pas encore reçue (chargement ou erreur réseau).
      if (quartiers.isEmpty) {
        if (controller.chargementQuartiers.value) {
          return const ChampTexte(
            libelle: 'Chargement des quartiers…',
            icone: AppIcons.quartier,
            actif: false,
          );
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                erreur ?? 'Aucun quartier disponible.',
                style: context.textes.bodyMedium?.copyWith(
                  color: context.schema.error,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.rechargerQuartiers,
              child: const Text('Réessayer'),
            ),
          ],
        );
      }

      return ChampListe<Quartier>(
        libelle: 'Quartier',
        icone: AppIcons.quartier,
        options: quartiers,
        valeur: controller.brouillon.value.quartier,
        libelleOption: (q) => q.nom,
        erreur: erreur,
        onChoix: controller.choisirQuartier,
      );
    });
  }
}

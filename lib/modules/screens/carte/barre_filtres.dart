import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_formats.dart';
import 'package:mono/core/theme/app_icons.dart';
import 'package:mono/core/theme/app_responsive.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/puce_filtre.dart';
import 'package:mono/core/widget/puce_menu.dart';
import 'package:mono/data/models/categorie.dart';
import 'package:mono/data/models/gravite.dart';
import 'package:mono/data/models/signalement_filtre.dart';
import 'package:mono/data/models/statut.dart';
import 'package:mono/data/models/type_filtre.dart';
import 'package:mono/modules/controller/carte_controller.dart';

/// Barre de filtres sous la recherche :
///
///   [ Tout ▾ ] │ Voirie  Ordures  Éclairage public …
///       │            └── puces du type choisi (une seule active à la fois)
///       └── liste déroulante : Tout, Statut, Gravité, Quartier, Période
///
/// Aucune puce active = tous les signalements sont affichés.
class BarreFiltres extends GetView<CarteController> {
  const BarreFiltres({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      // LayoutBuilder : on regarde la place RÉELLE donnée à la barre.
      child: LayoutBuilder(
        builder: (context, contraintes) => Obx(() {
          final type = controller.typeFiltre.value;
          final filtre = controller.filtre.value;
          final puces = _puces(context, type, filtre);

          return Row(
            children: [
              PuceMenu<TypeFiltre>(
                valeur: type,
                options: TypeFiltre.values,
                libelle: (option) => option.libelle,
                icone: (option) => option.icone,
                onChoix: controller.choisirTypeFiltre,
                // Fenêtre minuscule (ex : 150 px) : icône seule, pour
                // laisser de la place aux puces.
                compacte: contraintes.estMinuscule,
              ),
              const _Separateur(),
              // Expanded : la liste prend toute la place restante
              // (sans lui, un ListView dans un Row = erreur "unbounded width").
              Expanded(
                child: ListView.separated(
                  // Nouvelle clé à chaque type → la liste repart du début
                  // au lieu de garder l'ancienne position de défilement.
                  key: ValueKey(type),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: AppEspacements.s),
                  itemCount: puces.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppEspacements.s),
                  itemBuilder: (context, index) => Center(child: puces[index]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Les puces à afficher selon le type choisi dans la liste déroulante.
  /// `switch` sur un enum : Dart vérifie qu'aucun type n'est oublié.
  List<Widget> _puces(
    BuildContext context,
    TypeFiltre type,
    SignalementFiltre filtre,
  ) {
    final couleurs = context.couleurs;
    return switch (type) {
      TypeFiltre.tout => [
        for (final categorie in Categorie.values)
          PuceFiltre(
            libelle: categorie.libelle,
            icone: categorie.icone,
            couleur: couleurs.categorie(categorie),
            selectionnee: filtre.categorie == categorie,
            onSelection: () => controller.choisirCategorie(categorie),
          ),
      ],
      TypeFiltre.statut => [
        for (final statut in Statut.values)
          PuceFiltre(
            libelle: statut.libelle,
            icone: statut.icone,
            couleur: couleurs.statut(statut),
            selectionnee: filtre.statut == statut,
            onSelection: () => controller.choisirStatut(statut),
          ),
      ],
      TypeFiltre.gravite => [
        for (final gravite in Gravite.values)
          PuceFiltre(
            libelle: gravite.libelle,
            icone: gravite.icone,
            couleur: couleurs.gravite(gravite),
            selectionnee: filtre.gravite == gravite,
            onSelection: () => controller.choisirGravite(gravite),
          ),
      ],
      TypeFiltre.quartier => _pucesQuartiers(filtre),
      TypeFiltre.periode => [
        for (final periode in controller.periodes)
          PuceFiltre(
            libelle: AppFormats.mois(periode.debut),
            icone: AppIcons.periode,
            selectionnee: filtre.dateDebut == periode.debut,
            onSelection: () => controller.choisirPeriode(periode),
          ),
      ],
    };
  }

  /// Les quartiers arrivent du réseau : on gère "en cours" et "vide".
  List<Widget> _pucesQuartiers(SignalementFiltre filtre) {
    if (controller.quartiers.isEmpty) {
      return [
        if (controller.chargementQuartiers.value)
          const _PuceInfo(texte: 'Chargement des quartiers…', chargement: true)
        else
          const _PuceInfo(texte: 'Aucun quartier disponible'),
      ];
    }
    return [
      for (final quartier in controller.quartiers)
        PuceFiltre(
          libelle: quartier.nom,
          icone: AppIcons.quartier,
          selectionnee: filtre.quartierId == quartier.id,
          onSelection: () => controller.choisirQuartier(quartier),
        ),
    ];
  }
}

/// Petit trait vertical entre la liste déroulante et les puces.
class _Separateur extends StatelessWidget {
  const _Separateur();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: AppEspacements.s),
      color: context.schema.outlineVariant,
    );
  }
}

/// Puce d'information, non cliquable ("Chargement…", "Aucun quartier…").
class _PuceInfo extends StatelessWidget {
  const _PuceInfo({required this.texte, this.chargement = false});

  final String texte;
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Chip(
        elevation: 1,
        shadowColor: context.couleurs.ombre,
        backgroundColor: context.couleurs.surfaceFlottante,
        avatar: chargement
            ? const SizedBox.square(
                dimension: AppTailles.iconeS,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.info_outline,
                size: AppTailles.iconeS + 2,
                color: context.schema.onSurfaceVariant,
              ),
        label: Text(texte, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

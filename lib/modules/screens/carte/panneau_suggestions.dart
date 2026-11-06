import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_icons.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/indicateur_chargement.dart';
import 'package:mono/data/models/resultat_recherche.dart';
import 'package:mono/data/repositories/recherche_repository.dart';
import 'package:mono/modules/controller/carte_controller.dart';

/// Panneau sous la barre de recherche, quand elle est active :
/// - texte vide → recherches récentes (ou un conseil) ;
/// - texte saisi → suggestions (quartiers puis signalements).
class PanneauSuggestions extends GetView<CarteController> {
  const PanneauSuggestions({super.key, required this.hauteurMax});

  /// Hauteur max (calculée pour ne jamais passer sous le clavier).
  final double hauteurMax;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.couleurs.surfaceFlottante,
      elevation: 3,
      shadowColor: context.couleurs.ombre,
      borderRadius: BorderRadius.circular(AppRayons.l),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: hauteurMax),
        child: Obx(() {
          final terme = controller.terme.value.trim();
          if (terme.length < RechercheRepository.longueurMinimale) {
            return _RecherchesRecentes(
              recentes: controller.recherchesRecentes.toList(),
            );
          }
          return _Resultats(
            terme: terme,
            resultats: controller.resultats.toList(),
            enCours: controller.rechercheEnCours.value,
          );
        }),
      ),
    );
  }
}

class _RecherchesRecentes extends GetView<CarteController> {
  const _RecherchesRecentes({required this.recentes});

  final List<String> recentes;

  @override
  Widget build(BuildContext context) {
    if (recentes.isEmpty) {
      return const _MessagePanneau(
        icone: Icons.travel_explore,
        texte:
            'Recherchez un quartier (ex : Nzeng-Ayong) '
            'ou un problème (ex : trou, lampadaire).',
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppEspacements.xs),
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppEspacements.l,
            right: AppEspacements.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recherches récentes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textes.labelLarge?.copyWith(
                    color: context.schema.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.effacerHistorique,
                child: const Text('Tout effacer'),
              ),
            ],
          ),
        ),
        for (final recherche in recentes)
          ListTile(
            dense: true,
            leading: const Icon(AppIcons.historique),
            title: Text(
              recherche,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => controller.choisirRechercheRecente(recherche),
            trailing: IconButton(
              tooltip: "Retirer de l'historique",
              icon: const Icon(Icons.close, size: AppTailles.iconeS + 2),
              onPressed: () => controller.supprimerRechercheRecente(recherche),
            ),
          ),
      ],
    );
  }
}

class _Resultats extends GetView<CarteController> {
  const _Resultats({
    required this.terme,
    required this.resultats,
    required this.enCours,
  });

  final String terme;
  final List<ResultatRecherche> resultats;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    if (resultats.isEmpty) {
      if (enCours) {
        return const SizedBox(height: 96, child: IndicateurChargement());
      }
      return _MessagePanneau(
        icone: Icons.search_off,
        texte:
            'Aucun résultat pour « $terme ». '
            'Vérifiez l\'orthographe ou essayez un autre mot.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppEspacements.xs),
      itemCount: resultats.length,
      separatorBuilder: (context, index) => const Divider(indent: 72),
      itemBuilder: (context, index) {
        final resultat = resultats[index];
        return ListTile(
          leading: _IconeResultat(resultat: resultat),
          title: Text(
            resultat.titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            resultat.sousTitre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => controller.choisirResultat(resultat),
        );
      },
    );
  }
}

/// Rond coloré à gauche d'une suggestion.
class _IconeResultat extends StatelessWidget {
  const _IconeResultat({required this.resultat});

  final ResultatRecherche resultat;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    // `switch` sur une classe sealed : les 2 cas sont obligatoirement traités.
    final (fond, couleurIcone, icone) = switch (resultat) {
      ResultatQuartier() => (
        schema.primaryContainer,
        schema.onPrimaryContainer,
        Icons.place_outlined,
      ),
      ResultatSignalement(:final signalement) => (
        context.couleurs.categorie(signalement.categorie),
        Colors.white,
        signalement.categorie.icone,
      ),
    };

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
      child: Icon(icone, color: couleurIcone, size: AppTailles.iconeM),
    );
  }
}

class _MessagePanneau extends StatelessWidget {
  const _MessagePanneau({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppEspacements.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: context.schema.primary),
          const SizedBox(width: AppEspacements.m),
          Expanded(
            child: Text(
              texte,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: context.textes.bodyMedium?.copyWith(
                color: context.schema.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

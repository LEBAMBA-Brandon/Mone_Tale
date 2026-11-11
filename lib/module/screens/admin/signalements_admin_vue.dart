import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/carte_signalement.dart';
import 'package:tala/core/widget/etat_message.dart';
import 'package:tala/core/widget/puce_filtre.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/module/controller/signalements_admin_controller.dart';
import 'package:tala/module/screens/commun/barre_puces.dart';
import 'package:tala/module/screens/commun/vue_liste.dart';

/// Onglet "Signalements" de l'admin (maquette : filtre par catégorie,
/// photo + infos, nombre total de signalements).
class SignalementsAdminVue extends GetView<SignalementsAdminController> {
  const SignalementsAdminVue({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signalements')),
      body: Obx(() {
        final liste = controller.signalements;
        final filtreActif = !controller.filtre.value.estVide;

        return VueListe(
          chargement: controller.chargement.value,
          erreur: controller.erreur.value,
          nombre: liste.length,
          onRafraichir: () => controller.charger(forcer: true),
          messageChargement: 'Chargement des signalements…',
          entete: _Filtres(total: liste.length),
          constructeur: (context, index) => CarteSignalement(
            signalement: liste[index],
            afficherAuteur: true, // l'admin voit QUI a signalé
            onTap: () => controller.ouvrirDetail(liste[index]),
          ),
          vide: EtatMessage.vide(
            icone: AppIcons.signalements,
            titre: filtreActif
                ? 'Aucun signalement pour ces filtres'
                : "Aucun signalement pour l'instant",
            message: filtreActif
                ? null
                : 'Les signalements des collecteurs apparaîtront ici.',
          ),
        );
      }),
    );
  }
}

/// 2 rangées de puces (catégorie, statut) + le total.
class _Filtres extends GetView<SignalementsAdminController> {
  const _Filtres({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final filtre = controller.filtre.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BarrePuces(
          puces: [
            PuceFiltre(
              libelle: 'Toutes catégories',
              icone: AppIcons.tout,
              selectionnee: filtre.categorie == null,
              onSelection: () => controller.choisirCategorie(null),
            ),
            for (final categorie in Categorie.values)
              PuceFiltre(
                libelle: categorie.libelle,
                icone: categorie.icone,
                couleur: context.couleurs.categorie(categorie),
                selectionnee: filtre.categorie == categorie,
                onSelection: () => controller.choisirCategorie(categorie),
              ),
          ],
        ),
        BarrePuces(
          puces: [
            PuceFiltre(
              libelle: 'Tous statuts',
              icone: AppIcons.tout,
              selectionnee: filtre.statut == null,
              onSelection: () => controller.choisirStatut(null),
            ),
            for (final statut in Statut.values)
              PuceFiltre(
                libelle: statut.libelle,
                icone: statut.icone,
                couleur: context.couleurs.statut(statut),
                selectionnee: filtre.statut == statut,
                onSelection: () => controller.choisirStatut(statut),
              ),
          ],
        ),
        const SizedBox(height: AppEspacements.xs),
        Text(
          'Total : ${AppFormats.pluriel(total, 'signalement')}',
          style: context.textes.titleSmall,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/carte_signalement.dart';
import 'package:tala/core/widget/etat_message.dart';
import 'package:tala/core/widget/puce_filtre.dart';
import 'package:tala/data/models/statut.dart';
import 'package:tala/module/controller/mes_signalements_controller.dart';
import 'package:tala/module/screens/commun/barre_puces.dart';
import 'package:tala/module/screens/commun/vue_liste.dart';

/// Onglet "Mes signalements" du collecteur (maquette : photo + infos).
class MesSignalementsVue extends GetView<MesSignalementsController> {
  const MesSignalementsVue({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes signalements')),
      body: Obx(() {
        final liste = controller.signalementsAffiches;
        final filtre = controller.statut.value;

        return VueListe(
          chargement: controller.chargement.value,
          erreur: controller.erreur.value,
          nombre: liste.length,
          onRafraichir: () => controller.charger(forcer: true),
          messageChargement: 'Chargement de vos signalements…',
          entete: _Entete(total: liste.length),
          constructeur: (context, index) => CarteSignalement(
            signalement: liste[index],
            onTap: () => controller.ouvrirDetail(liste[index]),
          ),
          vide: filtre == null
              ? EtatMessage.vide(
                  icone: AppIcons.signalements,
                  titre: "Aucun signalement pour l'instant",
                  message: 'Les problèmes que vous signalez apparaîtront ici.',
                  libelleAction: 'Ajouter un signalement',
                  onAction: controller.allerAuFormulaire,
                )
              : EtatMessage.vide(
                  icone: filtre.icone,
                  titre: 'Aucun signalement « ${filtre.libelle} »',
                  libelleAction: 'Voir tout',
                  onAction: () => controller.choisirStatut(null),
                ),
        );
      }),
    );
  }
}

/// Filtres par statut + nombre affiché.
class _Entete extends GetView<MesSignalementsController> {
  const _Entete({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final actuel = controller.statut.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BarrePuces(
          puces: [
            PuceFiltre(
              libelle: 'Tout',
              icone: AppIcons.tout,
              selectionnee: actuel == null,
              onSelection: () => controller.choisirStatut(null),
            ),
            for (final statut in Statut.values)
              PuceFiltre(
                libelle: statut.libelle,
                icone: statut.icone,
                couleur: context.couleurs.statut(statut),
                selectionnee: actuel == statut,
                onSelection: () => controller.choisirStatut(statut),
              ),
          ],
        ),
        Text(
          AppFormats.pluriel(total, 'signalement'),
          style: context.textes.labelLarge?.copyWith(
            color: context.schema.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/carte_collecteur.dart';
import 'package:tala/core/widget/champ_texte.dart';
import 'package:tala/core/widget/etat_message.dart';
import 'package:tala/module/controller/collecteurs_controller.dart';
import 'package:tala/module/screens/commun/vue_liste.dart';

/// Onglet "Collecteurs" de l'admin : chaque collecteur avec son nombre de
/// signalements sur son icône. Un appui ouvre sa page détail.
class CollecteursVue extends GetView<CollecteursController> {
  const CollecteursVue({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collecteurs')),
      body: Obx(() {
        final liste = controller.collecteursAffiches;
        final recherche = controller.recherche.value.trim();

        return VueListe(
          chargement: controller.chargement.value,
          erreur: controller.erreur.value,
          nombre: liste.length,
          onRafraichir: () => controller.charger(forcer: true),
          messageChargement: 'Chargement des collecteurs…',
          // Cartes plus petites que celles des signalements → plus de colonnes.
          largeurIdealeElement: 340,
          entete: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppEspacements.s),
              // Sur grand écran, un champ de 1400 px serait pénible à lire :
              // la recherche garde une largeur raisonnable, à gauche.
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTailles.largeurMaxFormulaire,
                  ),
                  child: ChampTexte(
                    libelle: 'Rechercher',
                    icone: Icons.search,
                    indication: 'Nom ou prénom',
                    actionClavier: TextInputAction.search,
                    onChange: controller.surRecherche,
                  ),
                ),
              ),
              const SizedBox(height: AppEspacements.m),
              Text(
                '${AppFormats.pluriel(controller.collecteurs.length, 'collecteur')}'
                ' · ${AppFormats.pluriel(controller.totalSignalements, 'signalement')}',
                style: context.textes.titleSmall,
              ),
            ],
          ),
          constructeur: (context, index) => CarteCollecteur(
            collecteur: liste[index],
            onTap: () => controller.ouvrirDetail(liste[index]),
          ),
          vide: recherche.isNotEmpty
              ? EtatMessage.vide(
                  icone: Icons.search_off,
                  titre: 'Aucun résultat pour « $recherche »',
                )
              : EtatMessage.vide(
                  icone: AppIcons.collecteurs,
                  titre: 'Aucun collecteur',
                  message: 'Ajoutez un collecteur pour qu’il puisse signaler.',
                  libelleAction: 'Ajouter un collecteur',
                  onAction: controller.allerAuFormulaire,
                ),
        );
      }),
    );
  }
}

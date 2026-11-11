import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/avatar_utilisateur.dart';
import 'package:tala/core/widget/carte_signalement.dart';
import 'package:tala/core/widget/etat_message.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/module/controller/detail_collecteur_controller.dart';
import 'package:tala/module/screens/commun/vue_liste.dart';

/// Page détail d'un collecteur (admin) : ses infos + la liste de SES
/// signalements. Bouton 🗑 dans la barre du haut pour le supprimer.
class DetailCollecteurScreen extends GetView<DetailCollecteurController> {
  const DetailCollecteurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.collecteur.value?.nomEtPrenom ?? 'Collecteur',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier ce collecteur',
            onPressed: controller.modifier,
            icon: const Icon(AppIcons.modifier),
          ),
          Obx(
            () => IconButton(
              tooltip: 'Supprimer ce collecteur',
              onPressed: controller.suppressionEnCours.value
                  ? null
                  : controller.supprimer,
              icon: const Icon(AppIcons.supprimer),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final collecteur = controller.collecteur.value;
        final liste = controller.signalements;

        return VueListe(
          chargement: controller.chargement.value,
          erreur: controller.erreur.value,
          nombre: liste.length,
          onRafraichir: () => controller.charger(forcer: true),
          messageChargement: 'Chargement des signalements…',
          entete: collecteur == null ? null : _EnTete(collecteur: collecteur),
          constructeur: (context, index) => CarteSignalement(
            signalement: liste[index],
            onTap: () => controller.ouvrirSignalement(liste[index]),
          ),
          vide: const EtatMessage.vide(
            icone: AppIcons.signalements,
            titre: 'Aucun signalement',
            message: "Ce collecteur n'a encore rien signalé.",
          ),
        );
      }),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.collecteur});

  final Utilisateur collecteur;

  @override
  Widget build(BuildContext context) {
    final discret = context.textes.bodyMedium?.copyWith(
      color: context.schema.onSurfaceVariant,
    );
    final date = collecteur.dateCreation;
    final nombre = collecteur.nombreSignalements;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspacements.s),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppEspacements.l),
          child: Row(
            children: [
              AvatarUtilisateur(
                utilisateur: collecteur,
                taille: 64,
                afficherCompteur: true,
              ),
              const SizedBox(width: AppEspacements.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collecteur.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textes.titleSmall,
                    ),
                    if (nombre != null)
                      Text(
                        AppFormats.pluriel(nombre, 'signalement'),
                        style: discret,
                      ),
                    if (date != null)
                      Text(
                        'Depuis le ${AppFormats.jour(date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: discret,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

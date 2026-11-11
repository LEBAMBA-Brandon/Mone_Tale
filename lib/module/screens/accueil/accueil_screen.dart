import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/widget/barre_navigation.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/screens/admin/ajout_collecteur_vue.dart';
import 'package:tala/module/screens/admin/collecteurs_vue.dart';
import 'package:tala/module/screens/admin/signalements_admin_vue.dart';
import 'package:tala/module/screens/collecteur/ajout_signalement_vue.dart';
import 'package:tala/module/screens/collecteur/mes_signalements_vue.dart';
import 'package:tala/module/screens/profil/profil_vue.dart';

/// Écran principal après la connexion : la navigation (en bas sur
/// téléphone, sur le côté sur ordinateur) et l'onglet choisi.
///
/// Les onglets dépendent du RÔLE :
/// - collecteur : ⚠️ Mes signalements · ➕ Ajouter · 👤 Profil
/// - admin      : ⚠️ Signalements · 👤+ Ajouter · 👥 Collecteurs · 👤 Profil
///
/// IndexedStack : les onglets déjà ouverts restent EN MÉMOIRE. Un
/// formulaire à moitié rempli n'est pas perdu si on passe sur un autre
/// onglet et qu'on revient.
class AccueilScreen extends GetView<AccueilController> {
  const AccueilScreen({super.key});

  static const List<OngletNavigation> _ongletsCollecteur = [
    OngletNavigation(
      libelle: 'Mes signalements',
      icone: AppIcons.signalements,
      iconeActive: AppIcons.signalementsActif,
    ),
    OngletNavigation(
      libelle: 'Ajouter',
      icone: AppIcons.ajouter,
      iconeActive: AppIcons.ajouterActif,
    ),
    OngletNavigation(
      libelle: 'Profil',
      icone: AppIcons.profil,
      iconeActive: AppIcons.profilActif,
    ),
  ];

  static const List<OngletNavigation> _ongletsAdmin = [
    OngletNavigation(
      libelle: 'Signalements',
      icone: AppIcons.signalements,
      iconeActive: AppIcons.signalementsActif,
    ),
    OngletNavigation(
      libelle: 'Ajouter',
      icone: AppIcons.ajouterCollecteur,
      iconeActive: AppIcons.ajouterCollecteurActif,
    ),
    OngletNavigation(
      libelle: 'Collecteurs',
      icone: AppIcons.collecteurs,
      iconeActive: AppIcons.collecteursActif,
    ),
    OngletNavigation(
      libelle: 'Profil',
      icone: AppIcons.profil,
      iconeActive: AppIcons.profilActif,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final admin = controller.estAdmin;
    final onglets = admin ? _ongletsAdmin : _ongletsCollecteur;
    final vues = admin
        ? const <Widget>[
            SignalementsAdminVue(),
            AjoutCollecteurVue(),
            CollecteursVue(),
            ProfilVue(),
          ]
        : const <Widget>[
            MesSignalementsVue(),
            AjoutSignalementVue(),
            ProfilVue(),
          ];

    return Obx(() {
      final actif = controller.onglet.value;
      return PopScope(
        // Bouton retour d'Android : sur un autre onglet, on revient
        // d'abord au 1er onglet au lieu de quitter l'application.
        canPop: actif == AccueilController.ongletListe,
        onPopInvokedWithResult: (aQuitte, resultat) {
          if (!aQuitte) controller.changerOnglet(AccueilController.ongletListe);
        },
        // Barre en bas (téléphone) ou sur le côté (ordinateur).
        child: NavigationAdaptative(
          onglets: onglets,
          indexActif: actif,
          onChange: controller.changerOnglet,
          child: IndexedStack(
            index: actif,
            children: [
              for (var i = 0; i < vues.length; i++)
                // Un onglet jamais ouvert n'est pas construit : son
                // controller n'est donc pas encore créé (lazyPut).
                controller.ongletsOuverts.contains(i)
                    ? vues[i]
                    : const SizedBox.shrink(),
            ],
          ),
        ),
      );
    });
  }
}

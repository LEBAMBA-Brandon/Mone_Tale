import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_formats.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/app_infos.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/avatar_utilisateur.dart';
import 'package:tala/core/widget/badge_info.dart';
import 'package:tala/core/widget/section_menu.dart';
import 'package:tala/data/models/preference_theme.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/controller/profil_controller.dart';

/// Onglet "Profil" (collecteur et admin) :
///
///   [en-tête : avatar, nom, e-mail MASQUÉ, rôle]
///   Mon contenu   : Signalements · Ajouter · Collecteurs (admin)
///   Compte        : Notifications (oui/non) · Modifier mes informations
///   Informations  : Aide · Conditions · Confidentialité · Partager (collecteur)
///   Se déconnecter
///
/// Sur grand écran (≥ 900 px) : 2 colonnes pour occuper toute la largeur.
/// Le thème (Auto / Clair / Sombre) est dans le menu en haut à droite.
class ProfilVue extends GetView<ProfilController> {
  const ProfilVue({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: const [_MenuTheme()],
      ),
      body: LayoutBuilder(
        builder: (context, contraintes) {
          final marge = AppResponsive.margeHorizontale(contraintes.maxWidth);
          final deuxColonnes = contraintes.maxWidth >= 900;
          const espace = SizedBox(height: AppEspacements.xl);

          final colonneGauche = <Widget>[
            const _EnTete(),
            espace,
            const _SectionMonContenu(),
            espace,
            const _SectionCompte(),
          ];
          final colonneDroite = <Widget>[
            // "Informations" : seulement pour le collecteur (demande du plan).
            if (!controller.estAdmin) ...[const _SectionInformations(), espace],
            const _SectionDeconnexion(),
          ];

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: marge,
              vertical: AppEspacements.l,
            ),
            child: deuxColonnes
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(children: colonneGauche)),
                      const SizedBox(width: AppEspacements.xl),
                      Expanded(child: Column(children: colonneDroite)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...colonneGauche, espace, ...colonneDroite],
                  ),
          );
        },
      ),
    );
  }
}

/// Avatar + nom + e-mail masqué + rôle.
class _EnTete extends GetView<ProfilController> {
  const _EnTete();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final utilisateur = controller.utilisateur.value;
      if (utilisateur == null) return const SizedBox.shrink();
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppEspacements.l),
          child: Row(
            children: [
              AvatarUtilisateur(utilisateur: utilisateur, taille: 64),
              const SizedBox(width: AppEspacements.l),
              Expanded(child: _Identite(utilisateur: utilisateur)),
            ],
          ),
        ),
      );
    });
  }
}

class _Identite extends StatelessWidget {
  const _Identite({required this.utilisateur});

  final Utilisateur utilisateur;

  @override
  Widget build(BuildContext context) {
    final discret = context.textes.bodyMedium?.copyWith(
      color: context.schema.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          utilisateur.nomEtPrenom,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textes.titleLarge,
        ),
        const SizedBox(height: AppEspacements.xxs),
        Text(
          // 🔒 Jamais l'e-mail en clair à l'écran : "a***n@user.com".
          AppFormats.emailMasque(utilisateur.email),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: discret,
        ),
        const SizedBox(height: AppEspacements.s),
        BadgeRole(utilisateur.role),
      ],
    );
  }
}

/// Raccourcis vers les autres onglets.
class _SectionMonContenu extends GetView<ProfilController> {
  const _SectionMonContenu();

  @override
  Widget build(BuildContext context) {
    final admin = controller.estAdmin;
    return SectionMenu(
      titre: 'Mon contenu',
      elements: [
        ElementMenu(
          icone: AppIcons.signalements,
          titre: admin ? 'Signalements' : 'Mes signalements',
          sousTitre: admin
              ? 'Tous les signalements des collecteurs'
              : 'Les problèmes que vous avez signalés',
          onTap: () => controller.allerA(AccueilController.ongletListe),
        ),
        ElementMenu(
          icone: admin ? AppIcons.ajouterCollecteur : AppIcons.ajouter,
          titre: admin ? 'Ajouter un collecteur' : 'Ajouter un signalement',
          onTap: () => controller.allerA(AccueilController.ongletAjout),
        ),
        // La liste des collecteurs est réservée à l'admin (l'API la
        // refuse aux collecteurs : erreur 403).
        if (admin)
          ElementMenu(
            icone: AppIcons.collecteurs,
            titre: 'Collecteurs',
            sousTitre: 'Comptes et nombre de signalements',
            onTap: () => controller.allerA(AccueilController.ongletCollecteurs),
          ),
      ],
    );
  }
}

class _SectionCompte extends GetView<ProfilController> {
  const _SectionCompte();

  @override
  Widget build(BuildContext context) {
    return SectionMenu(
      titre: 'Compte',
      elements: [
        Obx(() {
          final actives = controller.notificationsActives.value;
          return ElementMenu(
            icone: AppIcons.notifications,
            titre: 'Notifications',
            sousTitre: actives ? 'Acceptées' : 'Refusées',
            // Toute la ligne est cliquable, pas seulement l'interrupteur.
            onTap: () => controller.choisirNotifications(!actives),
            fin: Switch(
              value: actives,
              onChanged: controller.choisirNotifications,
            ),
          );
        }),
        if (controller.estAdmin)
          ElementMenu(
            icone: AppIcons.modifier,
            titre: 'Modifier mes informations',
            sousTitre: 'Nom, prénom, e-mail, mot de passe',
            onTap: controller.ouvrirModification,
          ),
      ],
    );
  }
}

class _SectionInformations extends GetView<ProfilController> {
  const _SectionInformations();

  @override
  Widget build(BuildContext context) {
    return SectionMenu(
      titre: 'Informations',
      elements: [
        ElementMenu(
          icone: AppIcons.aide,
          titre: PageInfo.aide.titre,
          onTap: () => controller.ouvrirInfo(PageInfo.aide),
        ),
        ElementMenu(
          icone: AppIcons.conditions,
          titre: PageInfo.conditions.titre,
          onTap: () => controller.ouvrirInfo(PageInfo.conditions),
        ),
        ElementMenu(
          icone: AppIcons.confidentialite,
          titre: PageInfo.confidentialite.titre,
          onTap: () => controller.ouvrirInfo(PageInfo.confidentialite),
        ),
        ElementMenu(
          icone: AppIcons.partager,
          titre: "Partager l'application",
          onTap: controller.partager,
        ),
      ],
    );
  }
}

class _SectionDeconnexion extends GetView<ProfilController> {
  const _SectionDeconnexion();

  @override
  Widget build(BuildContext context) {
    final rouge = context.schema.error;
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionMenu(
            titre: 'Session',
            elements: [
              ElementMenu(
                icone: AppIcons.deconnexion,
                titre: 'Se déconnecter',
                couleur: rouge,
                onTap: controller.deconnexionEnCours.value
                    ? null
                    : controller.deconnecter,
                fin: controller.deconnexionEnCours.value
                    ? const SizedBox.square(
                        dimension: AppTailles.iconeM,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppEspacements.m),
          Text(
            '${AppInfos.nom} · version ${AppInfos.version}',
            textAlign: TextAlign.center,
            style: context.textes.bodySmall?.copyWith(
              color: context.schema.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton en haut à droite : Auto / Clair / Sombre.
class _MenuTheme extends GetView<ProfilController> {
  const _MenuTheme();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final actuel = controller.preferenceTheme.value;
      return PopupMenuButton<PreferenceTheme>(
        tooltip: 'Apparence',
        initialValue: actuel,
        onSelected: controller.choisirTheme,
        icon: Icon(_icone(actuel)),
        itemBuilder: (context) => [
          for (final choix in PreferenceTheme.values)
            PopupMenuItem(
              value: choix,
              child: Row(
                children: [
                  Icon(_icone(choix), size: AppTailles.iconeM),
                  const SizedBox(width: AppEspacements.m),
                  Text(_libelle(choix)),
                ],
              ),
            ),
        ],
      );
    });
  }

  static IconData _icone(PreferenceTheme choix) => switch (choix) {
    PreferenceTheme.systeme => AppIcons.themeSysteme,
    PreferenceTheme.clair => AppIcons.themeClair,
    PreferenceTheme.sombre => AppIcons.themeSombre,
  };

  static String _libelle(PreferenceTheme choix) => switch (choix) {
    PreferenceTheme.systeme => 'Comme le téléphone',
    PreferenceTheme.clair => 'Thème clair',
    PreferenceTheme.sombre => 'Thème sombre',
  };
}

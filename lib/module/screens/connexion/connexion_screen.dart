import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/bouton_principal.dart';
import 'package:tala/core/widget/champ_texte.dart';
import 'package:tala/core/widget/contenu_limite.dart';
import 'package:tala/core/widget/logo_application.dart';
import 'package:tala/module/controller/connexion_controller.dart';

/// Écran de connexion (e-mail + mot de passe), commun aux collecteurs
/// et à l'admin : l'API renvoie le rôle, et l'accueil s'adapte.
class ConnexionScreen extends StatelessWidget {
  const ConnexionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, contraintes) {
          // ---------- Grand écran : bandeau | formulaire ----------
          // L'écran entier est utilisé : la moitié gauche présente l'app,
          // la moitié droite contient le formulaire.
          if (contraintes.maxWidth >= 900) {
            return const Row(
              children: [
                Expanded(child: _Bandeau()),
                Expanded(child: _ZoneFormulaire(afficherLogo: false)),
              ],
            );
          }
          // ---------- Téléphone / tablette ----------
          return const _ZoneFormulaire(afficherLogo: true);
        },
      ),
    );
  }
}

/// Formulaire centré, qui défile si le clavier cache une partie de l'écran.
/// Il garde une largeur de formulaire (480 px max) : des champs de 1000 px
/// de large seraient pénibles à remplir.
class _ZoneFormulaire extends StatelessWidget {
  const _ZoneFormulaire({required this.afficherLogo});

  final bool afficherLogo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: ContenuLimite(
            largeurMax: AppTailles.largeurMaxFormulaire,
            child: _Formulaire(afficherLogo: afficherLogo),
          ),
        ),
      ),
    );
  }
}

/// Moitié gauche sur grand écran : couleur de la barre, logo, slogan.
class _Bandeau extends StatelessWidget {
  const _Bandeau();

  @override
  Widget build(BuildContext context) {
    final couleurTexte = context.couleurs.surBarre;
    return ColoredBox(
      color: context.couleurs.barre,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEspacements.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoApplication(taille: 160),
                const SizedBox(height: AppEspacements.xl),
                Text(
                  'tala',
                  style: context.textes.displaySmall?.copyWith(
                    color: couleurTexte,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppEspacements.s),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'Signalez les problèmes de la ville et suivez leur '
                    'traitement.',
                    textAlign: TextAlign.center,
                    style: context.textes.titleMedium?.copyWith(
                      color: couleurTexte,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Formulaire extends GetView<ConnexionController> {
  const _Formulaire({required this.afficherLogo});

  final bool afficherLogo;

  @override
  Widget build(BuildContext context) {
    // AutofillGroup : le téléphone peut proposer l'e-mail et le
    // mot de passe enregistrés (gestionnaire de mots de passe).
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sur grand écran, le logo est déjà dans le bandeau de gauche.
          if (afficherLogo) ...[
            const Center(child: LogoApplication(taille: 96)),
            const SizedBox(height: AppEspacements.l),
          ],
          Text(
            'Connexion',
            textAlign: TextAlign.center,
            style: context.textes.headlineSmall,
          ),
          const SizedBox(height: AppEspacements.xs),
          Text(
            'Espace collecteurs et administrateurs',
            textAlign: TextAlign.center,
            style: context.textes.bodyMedium?.copyWith(
              color: context.schema.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppEspacements.xl),
          // Un Obx par zone : seule la partie qui change se reconstruit.
          Obx(
            () => ChampTexte(
              libelle: 'E-mail',
              controller: controller.champEmail,
              icone: AppIcons.email,
              typeClavier: TextInputType.emailAddress,
              actionClavier: TextInputAction.next,
              indicesRemplissage: const [AutofillHints.email],
              erreur: controller.erreurs['email'],
              onChange: (_) => controller.effacerErreur('email'),
              onSoumis: (_) => controller.allerAuMotDePasse(),
            ),
          ),
          const SizedBox(height: AppEspacements.l),
          Obx(
            () => ChampMotDePasse(
              controller: controller.champMotDePasse,
              focus: controller.focusMotDePasse,
              erreur: controller.erreurs['password'],
              onChange: (_) => controller.effacerErreur('password'),
              // Touche "OK" du clavier = bouton "Se connecter".
              onSoumis: (_) => controller.seConnecter(),
            ),
          ),
          Obx(() {
            final message = controller.erreurGenerale.value;
            if (message == null) {
              return const SizedBox(height: AppEspacements.xl);
            }
            return _EncadreErreur(message: message);
          }),
          Obx(
            () => BoutonPrincipal(
              libelle: 'Se connecter',
              icone: Icons.login,
              pleineLargeur: true,
              chargement: controller.chargement.value,
              onPressed: controller.seConnecter,
            ),
          ),
        ],
      ),
    );
  }
}

/// Encadré rouge pour une erreur qui ne concerne pas un champ précis
/// ("Email ou mot de passe incorrect.", "Pas de connexion internet…").
class _EncadreErreur extends StatelessWidget {
  const _EncadreErreur({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppEspacements.l),
      // liveRegion : le lecteur d'écran annonce l'erreur dès qu'elle apparaît.
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppEspacements.m),
          decoration: BoxDecoration(
            color: schema.errorContainer,
            borderRadius: BorderRadius.circular(AppRayons.m),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: schema.onErrorContainer),
              const SizedBox(width: AppEspacements.s),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: schema.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

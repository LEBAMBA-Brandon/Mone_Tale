import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/bouton_principal.dart';
import 'package:tala/core/widget/champ_texte.dart';
import 'package:tala/module/controller/ajout_collecteur_controller.dart';

/// Onglet "Ajouter un collecteur" de l'admin (maquette : Nom, Prénom,
/// E-mail, Mot de passe + Annuler / Enregistrer).
class AjoutCollecteurVue extends GetView<AjoutCollecteurController> {
  const AjoutCollecteurVue({super.key});

  static const _espace = SizedBox(height: AppEspacements.l);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un collecteur')),
      body: LayoutBuilder(
        builder: (context, contraintes) {
          final marge = AppResponsive.margeHorizontale(contraintes.maxWidth);
          // Grand écran : les champs vont par 2 (Nom | Prénom, E-mail | Mot
          // de passe) pour utiliser toute la largeur.
          final parDeux = contraintes.maxWidth >= 720;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: marge,
              vertical: AppEspacements.l,
            ),
            child: AutofillGroup(
              child: Obx(() {
                final nom = ChampTexte(
                  libelle: 'Nom',
                  controller: controller.champNom,
                  icone: AppIcons.nom,
                  actionClavier: TextInputAction.next,
                  majuscules: TextCapitalization.characters,
                  indicesRemplissage: const [AutofillHints.familyName],
                  erreur: controller.erreurs['nom'],
                  onChange: (_) => controller.effacerErreur('nom'),
                );
                final prenom = ChampTexte(
                  libelle: 'Prénom',
                  controller: controller.champPrenom,
                  icone: AppIcons.nom,
                  actionClavier: TextInputAction.next,
                  majuscules: TextCapitalization.words,
                  indicesRemplissage: const [AutofillHints.givenName],
                  erreur: controller.erreurs['prenom'],
                  onChange: (_) => controller.effacerErreur('prenom'),
                );
                final email = ChampTexte(
                  libelle: 'E-mail',
                  controller: controller.champEmail,
                  icone: AppIcons.email,
                  typeClavier: TextInputType.emailAddress,
                  actionClavier: TextInputAction.next,
                  indicesRemplissage: const [AutofillHints.email],
                  erreur: controller.erreurs['email'],
                  onChange: (_) => controller.effacerErreur('email'),
                );
                final motDePasse = ChampMotDePasse(
                  controller: controller.champMotDePasse,
                  nouveau: true,
                  erreur: controller.erreurs['password'],
                  onChange: (_) => controller.effacerErreur('password'),
                  onSoumis: (_) => controller.enregistrer(),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Le collecteur pourra se connecter avec cet e-mail et ce '
                      'mot de passe. Communiquez-les-lui en main propre.',
                      style: context.textes.bodyMedium?.copyWith(
                        color: context.schema.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppEspacements.xl),
                    if (parDeux) ...[
                      _paire(nom, prenom),
                      _espace,
                      _paire(email, motDePasse),
                    ] else ...[
                      nom,
                      _espace,
                      prenom,
                      _espace,
                      email,
                      _espace,
                      motDePasse,
                    ],
                    const SizedBox(height: AppEspacements.xl),
                    _Boutons(
                      enregistrement: controller.enregistrement.value,
                      aDroite: parDeux,
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  /// 2 champs côte à côte, de même largeur.
  static Widget _paire(Widget gauche, Widget droite) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: gauche),
      const SizedBox(width: AppEspacements.l),
      Expanded(child: droite),
    ],
  );
}

/// "Annuler" et "Enregistrer" côte à côte, ou l'un sous l'autre sur un
/// écran minuscule.
class _Boutons extends GetView<AjoutCollecteurController> {
  const _Boutons({required this.enregistrement, required this.aDroite});

  final bool enregistrement;

  /// Grand écran : boutons de taille normale, alignés à droite.
  final bool aDroite;

  @override
  Widget build(BuildContext context) {
    final annuler = BoutonPrincipal(
      libelle: 'Annuler',
      variante: VarianteBouton.contour,
      pleineLargeur: !aDroite,
      onPressed: enregistrement ? null : controller.vider,
    );
    final enregistrer = BoutonPrincipal(
      libelle: 'Enregistrer',
      icone: AppIcons.enregistrer,
      pleineLargeur: !aDroite,
      chargement: enregistrement,
      onPressed: controller.enregistrer,
    );

    if (aDroite) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [annuler, const SizedBox(width: AppEspacements.m), enregistrer],
      );
    }
    return LayoutBuilder(
      builder: (context, contraintes) {
        if (contraintes.estMinuscule) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              enregistrer,
              const SizedBox(height: AppEspacements.s),
              annuler,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: annuler),
            const SizedBox(width: AppEspacements.m),
            Expanded(child: enregistrer),
          ],
        );
      },
    );
  }
}

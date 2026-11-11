import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_icons.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/bouton_principal.dart';
import 'package:tala/core/widget/champ_texte.dart';
import 'package:tala/module/controller/modifier_profil_controller.dart';

/// "Modifier mes informations" (collecteur et admin).
///
/// 2 blocs : Identité (nom, prénom, e-mail) et Mot de passe (facultatif).
/// Téléphone : l'un sous l'autre. Grand écran (≥ 840 px) : côte à côte.
class ModifierProfilScreen extends GetView<ModifierProfilController> {
  const ModifierProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.titre),
      ), // plus "const" : le texte varie
      body: LayoutBuilder(
        builder: (context, contraintes) {
          final marge = AppResponsive.margeHorizontale(contraintes.maxWidth);
          final cote = contraintes.maxWidth >= 840;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: marge,
              vertical: AppEspacements.l,
            ),
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (cote)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _BlocIdentite()),
                        SizedBox(width: AppEspacements.xxl),
                        Expanded(child: _BlocMotDePasse()),
                      ],
                    )
                  else ...const [
                    _BlocIdentite(),
                    SizedBox(height: AppEspacements.xxl),
                    _BlocMotDePasse(),
                  ],
                  const SizedBox(height: AppEspacements.xxl),
                  _Boutons(
                    enregistrement: controller.enregistrement.value,
                    aDroite: cote,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BlocIdentite extends GetView<ModifierProfilController> {
  const _BlocIdentite();

  static const _espace = SizedBox(height: AppEspacements.l);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Identité', style: context.textes.titleMedium),
          _espace,
          ChampTexte(
            libelle: 'Nom',
            controller: controller.champNom,
            icone: AppIcons.nom,
            actionClavier: TextInputAction.next,
            erreur: controller.erreurs['nom'],
            onChange: (_) => controller.effacerErreur('nom'),
          ),
          _espace,
          ChampTexte(
            libelle: 'Prénom',
            controller: controller.champPrenom,
            icone: AppIcons.nom,
            actionClavier: TextInputAction.next,
            erreur: controller.erreurs['prenom'],
            onChange: (_) => controller.effacerErreur('prenom'),
          ),
          _espace,
          ChampTexte(
            libelle: 'E-mail',
            controller: controller.champEmail,
            icone: AppIcons.email,
            typeClavier: TextInputType.emailAddress,
            actionClavier: TextInputAction.next,
            erreur: controller.erreurs['email'],
            onChange: (_) => controller.effacerErreur('email'),
          ),
        ],
      ),
    );
  }
}

class _BlocMotDePasse extends GetView<ModifierProfilController> {
  const _BlocMotDePasse();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mot de passe', style: context.textes.titleMedium),
          const SizedBox(height: AppEspacements.xs),
          Text(
            'Laissez vide pour garder votre mot de passe actuel.',
            style: context.textes.bodySmall?.copyWith(
              color: context.schema.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppEspacements.l),
          ChampMotDePasse(
            controller: controller.champNouveauMotDePasse,
            libelle: 'Nouveau mot de passe',
            nouveau: true,
            erreur: controller.erreurs['password'],
            onChange: (_) => controller.effacerErreur('password'),
            onSoumis: (_) => controller.enregistrer(),
          ),
        ],
      ),
    );
  }
}

class _Boutons extends GetView<ModifierProfilController> {
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
      onPressed: enregistrement ? null : controller.annuler,
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
        children: [
          annuler,
          const SizedBox(width: AppEspacements.m),
          enregistrer,
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
  }
}

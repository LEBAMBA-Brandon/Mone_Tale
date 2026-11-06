import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_icons.dart';
import 'package:mono/core/theme/app_responsive.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/barre_recherche.dart';
import 'package:mono/core/widget/bouton_carte.dart';
import 'package:mono/core/widget/etat_message.dart';
import 'package:mono/modules/controller/carte_controller.dart';
import 'package:mono/modules/controller/theme_controller.dart';
import 'package:mono/modules/screens/carte/apercu_signalement.dart';
import 'package:mono/modules/screens/carte/barre_filtres.dart';
import 'package:mono/modules/screens/carte/carte_fond.dart';
import 'package:mono/modules/screens/carte/panneau_suggestions.dart';

/// Écran principal : la carte des signalements.
///
/// Organisation en couches (Stack), du fond vers le dessus :
/// 1. la carte ;
/// 2. l'écran d'erreur (seulement si AUCUNE donnée) ;
/// 3. en haut : recherche + filtres (ou suggestions) ;
/// 4. en bas : boutons + aperçu du signalement sélectionné.
///
/// Responsive : sur tablette (≥ 600 px), les panneaux font 420 px max et
/// sont alignés à gauche, comme sur Google Maps.
class CarteScreen extends GetView<CarteController> {
  const CarteScreen({super.key});

  static const double _largeurPanneauLarge = 420;

  @override
  Widget build(BuildContext context) {
    // Icônes de la barre d'état lisibles sur la carte (sombres sur carte claire).
    final styleBarreEtat =
        (context.estSombre
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent);

    // Construit UNE fois : quand seul `canPop` change, Flutter réutilise ce
    // widget tel quel (la carte n'est pas reconstruite pour rien).
    final page = Scaffold(
      // Le clavier passe PAR-DESSUS la carte au lieu de la compresser.
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(builder: _construire),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: styleBarreEtat,
      child: Obx(
        () => PopScope(
          // Bouton retour d'Android : ferme d'abord la recherche ou l'aperçu
          // au lieu de quitter l'application.
          canPop:
              !controller.rechercheOuverte.value &&
              controller.selection.value == null,
          onPopInvokedWithResult: (aQuitte, _) {
            if (!aQuitte) controller.gererRetour();
          },
          child: page,
        ),
      ),
    );
  }

  Widget _construire(BuildContext context, BoxConstraints contraintes) {
    final marge = AppResponsive.margeHorizontale(contraintes.maxWidth);
    final large = contraintes.estAuMoinsMoyen;
    final largeurDisponible = math.max(0.0, contraintes.maxWidth - 2 * marge);
    final largeurPanneau = large
        ? math.min(_largeurPanneauLarge, largeurDisponible)
        : largeurDisponible;
    // Les suggestions ne doivent jamais passer sous le clavier.
    final clavier = MediaQuery.viewInsetsOf(context).bottom;
    final hauteurSuggestions = math.max(
      140.0,
      contraintes.maxHeight - clavier - 200,
    );

    return Stack(
      children: [
        const Positioned.fill(child: CarteFond()),
        const Positioned.fill(child: _ErreurSansDonnees()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(marge, AppEspacements.s, marge, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: largeurPanneau,
                  child: _ZoneHaute(hauteurSuggestions: hauteurSuggestions),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(marge, 0, marge, AppEspacements.l),
              child: _ZoneBasse(largeurPanneau: largeurPanneau, large: large),
            ),
          ),
        ),
      ],
    );
  }
}

/// Haut de l'écran : barre de recherche + (filtres OU suggestions).
class _ZoneHaute extends GetView<CarteController> {
  const _ZoneHaute({required this.hauteurSuggestions});

  final double hauteurSuggestions;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ouverte = controller.rechercheOuverte.value;
      final rienATrouver =
          !controller.chargement.value &&
          controller.erreur.value == null &&
          controller.signalements.isEmpty;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BarreRecherche(
            controleur: controller.champRecherche,
            focusNode: controller.focusRecherche,
            onChanged: controller.surSaisie,
            onSubmitted: controller.validerRecherche,
            onEffacer: controller.effacerRecherche,
            // Recherche ouverte → flèche retour à la place du logo.
            onRetour: ouverte ? controller.fermerRecherche : null,
            enRecherche: controller.rechercheEnCours.value,
          ),
          const SizedBox(height: AppEspacements.s),
          if (ouverte)
            PanneauSuggestions(hauteurMax: hauteurSuggestions)
          else ...[
            const BarreFiltres(),
            if (controller.chargement.value)
              const _BarreProgression()
            else if (rienATrouver)
              _BulleAucunSignalement(filtre: controller.libelleFiltreActif),
          ],
        ],
      );
    });
  }
}

/// Fine barre de progression sous les filtres pendant un chargement.
class _BarreProgression extends StatelessWidget {
  const _BarreProgression();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppEspacements.xs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRayons.rond),
        child: const LinearProgressIndicator(
          minHeight: 3,
          semanticsLabel: 'Chargement des signalements',
        ),
      ),
    );
  }
}

/// Petite bulle "aucun signalement" (la carte reste visible et utilisable).
class _BulleAucunSignalement extends StatelessWidget {
  const _BulleAucunSignalement({required this.filtre});

  /// Nom du filtre actif ("Voirie", "Nov. 2026"…), `null` = aucun filtre.
  final String? filtre;

  @override
  Widget build(BuildContext context) {
    final texte = filtre == null
        ? 'Aucun signalement pour le moment.'
        : 'Aucun signalement « $filtre » pour le moment.';

    return Padding(
      padding: const EdgeInsets.only(top: AppEspacements.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: context.couleurs.surfaceFlottante,
          elevation: 2,
          shadowColor: context.couleurs.ombre,
          borderRadius: BorderRadius.circular(AppRayons.rond),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppEspacements.m,
              vertical: AppEspacements.s,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppTailles.iconeS + 2,
                  color: context.schema.onSurfaceVariant,
                ),
                const SizedBox(width: AppEspacements.s),
                Flexible(
                  child: Text(
                    texte,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textes.bodySmall,
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

/// Bas de l'écran : boutons flottants + aperçu du signalement sélectionné.
class _ZoneBasse extends GetView<CarteController> {
  const _ZoneBasse({required this.largeurPanneau, required this.large});

  final double largeurPanneau;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final selection = controller.selection.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          BoutonCarte(
            icone: context.estSombre
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            infobulle: context.estSombre
                ? 'Passer en thème clair'
                : 'Passer en thème sombre',
            onPressed: themeController.basculer,
          ),
          const SizedBox(height: AppEspacements.s),
          BoutonCarte(
            icone: AppIcons.autourDeMoi,
            libelle: 'Autour de moi',
            chargement: controller.localisationEnCours.value,
            onPressed: controller.autourDeMoi,
          ),
          // L'aperçu apparaît / disparaît en douceur.
          AnimatedSize(
            duration: AppDurees.normale,
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: selection == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppEspacements.m),
                    child: Align(
                      alignment: large
                          ? Alignment.bottomLeft
                          : Alignment.bottomCenter,
                      child: SizedBox(
                        width: largeurPanneau,
                        child: ApercuSignalement(
                          key: ValueKey(selection.id),
                          signalement: selection,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

/// Erreur affichée PAR-DESSUS la carte, seulement quand on n'a AUCUNE donnée
/// (ex : premier lancement sans réseau). La recherche et les filtres
/// restent utilisables au-dessus.
class _ErreurSansDonnees extends GetView<CarteController> {
  const _ErreurSansDonnees();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final erreur = controller.erreur.value;
      if (erreur == null || controller.signalements.isNotEmpty) {
        return const SizedBox.shrink();
      }
      void reessayer() => controller.charger(forcer: true);

      return ColoredBox(
        color: context.schema.scrim.withValues(alpha: 0.35),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppEspacements.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 340),
              child: Material(
                color: context.couleurs.surfaceFlottante,
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRayons.xl),
                clipBehavior: Clip.antiAlias,
                child: erreur.estProblemeReseau
                    ? EtatMessage.horsLigne(onReessayer: reessayer)
                    : EtatMessage.erreur(
                        message: erreur.message,
                        onReessayer: reessayer,
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

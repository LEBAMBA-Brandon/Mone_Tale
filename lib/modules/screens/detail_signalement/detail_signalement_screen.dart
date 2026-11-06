import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_formats.dart';
import 'package:mono/core/theme/app_responsive.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/badge_info.dart';
import 'package:mono/core/widget/bouton_carte.dart';
import 'package:mono/core/widget/etat_message.dart';
import 'package:mono/core/widget/image_reseau.dart';
import 'package:mono/core/widget/indicateur_chargement.dart';
import 'package:mono/core/widget/ligne_info.dart';
import 'package:mono/data/models/signalement.dart';
import 'package:mono/modules/controller/detail_signalement_controller.dart';
import 'package:mono/modules/screens/detail_signalement/mini_carte.dart';

/// Détail d'un signalement (modèle écran "User", 2e écran) :
/// mini-carte en haut, feuille arrondie par-dessus avec la photo et
/// Description, Catégorie, Gravité, Quartier, Auteur, Date, Statut.
///
/// - Tirer vers le bas → rafraîchir.
/// - Toucher la photo → plein écran avec zoom.
/// - Sur tablette, le contenu fait 640 px max et reste centré.
class DetailSignalementScreen extends GetView<DetailSignalementController> {
  const DetailSignalementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final styleBarreEtat =
        (context.estSombre
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: styleBarreEtat,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, contraintes) {
            // 30 % de la hauteur pour la carte, entre 140 et 280 px.
            final hauteurCarte = (contraintes.maxHeight * 0.3).clamp(
              140.0,
              280.0,
            );
            final marge = AppResponsive.margeHorizontale(contraintes.maxWidth);

            return Stack(
              children: [
                // 1) Mini-carte (légèrement recouverte par la feuille).
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: hauteurCarte + AppRayons.xl,
                  child: Obx(() {
                    final s = controller.signalement.value;
                    if (s == null) {
                      return ColoredBox(color: context.couleurs.squelette);
                    }
                    return MiniCarte(
                      signalement: s,
                      partieCachee: AppRayons.xl,
                    );
                  }),
                ),
                // 2) Feuille de détail défilante.
                Positioned.fill(
                  child: RefreshIndicator(
                    onRefresh: controller.charger,
                    edgeOffset: hauteurCarte,
                    child: SingleChildScrollView(
                      // Permet de "tirer pour rafraîchir" même si le contenu est court.
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: hauteurCarte),
                      child: _Feuille(
                        hauteurMin: math.max(
                          0,
                          contraintes.maxHeight - hauteurCarte,
                        ),
                        marge: marge,
                      ),
                    ),
                  ),
                ),
                // 3) Bouton retour flottant.
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppEspacements.m),
                      child: BoutonCarte(
                        icone: Icons.arrow_back,
                        infobulle: 'Retour',
                        onPressed: controller.retour,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Feuille extends GetView<DetailSignalementController> {
  const _Feuille({required this.hauteurMin, required this.marge});

  final double hauteurMin;
  final double marge;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: hauteurMin),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRayons.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: context.couleurs.ombre,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTailles.largeurMaxContenu,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              marge,
              AppEspacements.l,
              marge,
              AppEspacements.xl + MediaQuery.paddingOf(context).bottom,
            ),
            child: Obx(() => _contenu(context)),
          ),
        ),
      ),
    );
  }

  Widget _contenu(BuildContext context) {
    final s = controller.signalement.value;
    if (s == null) return SizedBox(height: 320, child: _etatSansDonnees());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rafraîchissement en cours alors qu'on affiche déjà des données.
        if (controller.chargement.value)
          const Padding(
            padding: EdgeInsets.only(bottom: AppEspacements.s),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _Photo(url: s.photoUrl),
        const SizedBox(height: AppEspacements.l),
        Text(
          'Signalement n° ${s.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textes.titleLarge,
        ),
        const SizedBox(height: AppEspacements.xxs),
        Text(
          AppFormats.depuis(s.dateCreation),
          style: context.textes.bodyMedium?.copyWith(
            color: context.schema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppEspacements.m),
        const Divider(),
        const SizedBox(height: AppEspacements.xs),
        ..._lignes(s),
      ],
    );
  }

  List<Widget> _lignes(Signalement s) {
    final quartier = [
      s.nomQuartier,
      s.quartier?.localisation,
    ].whereType<String>().join(' · ');
    return [
      LigneInfo(
        icone: Icons.description_outlined,
        libelle: 'Description',
        valeur: s.description.isEmpty ? 'Aucune description' : s.description,
      ),
      LigneInfo(
        icone: Icons.category_outlined,
        libelle: 'Catégorie',
        enfant: BadgeCategorie(s.categorie),
      ),
      LigneInfo(
        icone: Icons.priority_high,
        libelle: 'Gravité',
        enfant: BadgeGravite(s.gravite),
      ),
      LigneInfo(
        icone: Icons.place_outlined,
        libelle: 'Quartier',
        valeur: quartier,
      ),
      LigneInfo(
        icone: Icons.person_outline,
        libelle: 'Auteur',
        valeur: s.nomAuteur,
      ),
      LigneInfo(
        icone: Icons.event_outlined,
        libelle: 'Date',
        valeur: AppFormats.date(s.dateCreation),
      ),
      LigneInfo(
        icone: Icons.flag_outlined,
        libelle: 'Statut',
        enfant: BadgeStatut(s.statut),
      ),
    ];
  }

  /// Chargement, introuvable, hors ligne ou erreur.
  Widget _etatSansDonnees() {
    final erreur = controller.erreur.value;
    if (controller.chargement.value) {
      return const IndicateurChargement(message: 'Chargement du signalement…');
    }
    if (controller.estIntrouvable) {
      return EtatMessage.vide(
        icone: Icons.search_off,
        titre: 'Signalement introuvable',
        message: 'Il a peut-être été supprimé.',
        libelleAction: 'Retour à la carte',
        onAction: controller.retour,
      );
    }
    if (erreur != null && erreur.estProblemeReseau) {
      return EtatMessage.horsLigne(onReessayer: controller.charger);
    }
    return EtatMessage.erreur(
      message: erreur?.message ?? 'Une erreur inattendue est survenue.',
      onReessayer: controller.charger,
    );
  }
}

/// Photo du signalement ; un appui l'ouvre en plein écran (zoom possible).
class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final image = ImageReseau(
      url: url,
      ratio: 16 / 10,
      description: 'Photo du signalement',
    );
    if (url == null) return image;

    return Semantics(
      button: true,
      label: 'Agrandir la photo',
      child: GestureDetector(
        onTap: () => _agrandir(context),
        child: Stack(
          children: [
            image,
            Positioned(
              right: AppEspacements.s,
              bottom: AppEspacements.s,
              child: Container(
                padding: const EdgeInsets.all(AppEspacements.xs + 2),
                decoration: const BoxDecoration(
                  color: Color(0x99000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.zoom_out_map,
                  color: Colors.white,
                  size: AppTailles.iconeM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _agrandir(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    url!,
                    fit: BoxFit.contain,
                    semanticLabel: 'Photo du signalement',
                    errorBuilder: (context, erreur, trace) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: IconButton(
                  tooltip: 'Fermer',
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

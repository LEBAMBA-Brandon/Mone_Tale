import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/widget/etat_message.dart';
import 'package:tala/core/widget/indicateur_chargement.dart';
import 'package:tala/data/services/api_exception.dart';

/// Squelette commun à TOUTES les listes de tala (mes signalements,
/// signalements admin, collecteurs, signalements d'un collecteur).
///
/// Il gère les 5 états d'une liste, toujours de la même façon :
/// 1. 1er chargement (rien à montrer)   → cercle + message ;
/// 2. erreur sans données               → "Pas de connexion" ou "Réessayer" ;
/// 3. liste vide                        → message [vide] ;
/// 4. liste remplie                     → les éléments ;
/// 5. rechargement avec données         → fine barre en haut, liste gardée.
///
/// + "tirer vers le bas pour rafraîchir".
///
/// 📐 TOUTE la largeur de l'écran est utilisée : les éléments se rangent en
/// COLONNES selon la place disponible (1 sur téléphone, 2 sur tablette,
/// 3 ou plus sur ordinateur). Chaque carte garde ainsi une largeur
/// confortable (≈ 360 à 560 px) au lieu d'être étirée sur 1500 px.
///
/// L'[entete] (filtres, total…) reste TOUJOURS visible, même en cas
/// d'erreur : on peut changer de filtre sans être bloqué.
class VueListe extends StatelessWidget {
  const VueListe({
    super.key,
    required this.chargement,
    required this.erreur,
    required this.nombre,
    required this.constructeur,
    required this.onRafraichir,
    required this.vide,
    this.entete,
    this.messageChargement = 'Chargement…',
    this.largeurIdealeElement = 420,
  });

  final bool chargement;
  final ApiException? erreur;

  /// Nombre d'éléments à afficher.
  final int nombre;

  /// Construit l'élément n° `index`.
  final Widget Function(BuildContext context, int index) constructeur;
  final Future<void> Function() onRafraichir;
  final Widget vide;
  final Widget? entete;
  final String messageChargement;

  /// Largeur minimale souhaitée pour un élément : sert à calculer le
  /// nombre de colonnes (largeur disponible ÷ cette valeur).
  final double largeurIdealeElement;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final marge = AppResponsive.margeHorizontale(contraintes.maxWidth);
        final largeurUtile = contraintes.maxWidth - 2 * marge;
        // Ex : 1400 px utiles ÷ 420 → 3 colonnes ; téléphone → 1 colonne.
        final colonnes = (largeurUtile / largeurIdealeElement).floor().clamp(
          1,
          4,
        );
        final lignes = (nombre / colonnes).ceil();
        final entete = this.entete;

        return RefreshIndicator(
          onRefresh: onRafraichir,
          child: CustomScrollView(
            // Permet de tirer pour rafraîchir même si la liste est courte.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (entete != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    marge,
                    AppEspacements.s,
                    marge,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(child: entete),
                ),
              if (chargement && nombre > 0)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (nombre == 0)
                // Remplit la hauteur restante (message centré).
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: _etatSansElement(),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    marge,
                    AppEspacements.s,
                    marge,
                    AppEspacements.xxl,
                  ),
                  // Une "ligne" = jusqu'à [colonnes] éléments côte à côte.
                  // (Pas de GridView : il impose une hauteur FIXE aux cartes,
                  // ce qui couperait le texte si le téléphone l'affiche en grand.)
                  sliver: SliverList.separated(
                    itemCount: lignes,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppEspacements.s),
                    itemBuilder: (context, ligne) => _ligne(
                      context,
                      debut: ligne * colonnes,
                      colonnes: colonnes,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Une ligne de la grille. Les cases vides de la dernière ligne gardent
  /// leur place (Spacer) pour que toutes les cartes aient la même largeur.
  Widget _ligne(
    BuildContext context, {
    required int debut,
    required int colonnes,
  }) {
    if (colonnes == 1) return constructeur(context, debut);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < colonnes; i++) ...[
          if (i > 0) const SizedBox(width: AppEspacements.s),
          Expanded(
            child: debut + i < nombre
                ? constructeur(context, debut + i)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _etatSansElement() {
    final erreur = this.erreur;
    if (chargement) return IndicateurChargement(message: messageChargement);
    if (erreur != null) {
      return erreur.estProblemeReseau
          ? EtatMessage.horsLigne(onReessayer: onRafraichir)
          : EtatMessage.erreur(
              message: erreur.message,
              onReessayer: onRafraichir,
            );
    }
    return vide;
  }
}

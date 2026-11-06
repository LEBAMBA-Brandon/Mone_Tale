import 'package:flutter/material.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/couleurs_mono.dart';
import 'package:mono/core/widget/logo_application.dart';

/// Barre de recherche flottante "façon Google Maps".
///
/// Le [controleur] (TextEditingController) et le [focusNode] sont créés
/// dans le controller GetX (`onInit`) et libérés dans `onClose`.
/// Le debounce() est aussi dans le controller : ce widget ne fait qu'afficher.
///
/// - Logo à gauche (ou flèche retour si [onRetour] est donné).
/// - Pendant une recherche : petit cercle de chargement.
/// - Texte saisi → bouton ✕ pour effacer, sinon une loupe.
/// - Écran minuscule (< 200 px de large) → le logo est masqué.
class BarreRecherche extends StatelessWidget {
  const BarreRecherche({
    super.key,
    required this.controleur,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onEffacer,
    this.onRetour,
    this.enRecherche = false,
    this.indication = 'Rechercher un quartier, un problème…',
  });

  final TextEditingController controleur;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEffacer;

  /// Si donné → flèche "retour" à gauche (ex : fermer les suggestions).
  final VoidCallback? onRetour;
  final bool enRecherche;
  final String indication;

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;

    return Material(
      color: context.couleurs.surfaceFlottante,
      elevation: 3,
      shadowColor: context.couleurs.ombre,
      borderRadius: BorderRadius.circular(AppRayons.rond),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppTailles.hauteurBarreRecherche,
        ),
        child: LayoutBuilder(
          builder: (context, contraintes) {
            final afficherLogo = contraintes.maxWidth >= 200;
            return Row(
              children: [
                if (onRetour != null)
                  IconButton(
                    tooltip: 'Retour',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onRetour,
                  )
                else if (afficherLogo)
                  const Padding(
                    padding: EdgeInsets.only(
                      left: AppEspacements.m,
                      right: AppEspacements.xs,
                    ),
                    child: LogoApplication(taille: 26),
                  )
                else
                  const SizedBox(width: AppEspacements.m),
                Expanded(
                  child: TextField(
                    controller: controleur,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    maxLines: 1,
                    style: context.textes.bodyLarge,
                    decoration: InputDecoration(
                      hintText: indication,
                      hintMaxLines: 1,
                      // On annule le style "champ de formulaire" du thème :
                      // ici, c'est la pilule autour qui fait office de bordure.
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppEspacements.s,
                        vertical: AppEspacements.m + 2,
                      ),
                    ),
                  ),
                ),
                if (enRecherche)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppEspacements.s),
                    child: SizedBox.square(
                      dimension: AppTailles.iconeM - 2,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Recherche en cours',
                      ),
                    ),
                  ),
                // Se reconstruit seulement quand le texte change.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controleur,
                  builder: (context, valeur, _) {
                    if (valeur.text.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppEspacements.l),
                        child: Icon(
                          Icons.search,
                          color: schema.onSurfaceVariant,
                        ),
                      );
                    }
                    return IconButton(
                      tooltip: 'Effacer',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controleur.clear();
                        onEffacer?.call();
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

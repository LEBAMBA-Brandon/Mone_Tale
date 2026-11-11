import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/app_dimensions.dart';
import 'package:tala/core/theme/app_infos.dart';
import 'package:tala/core/theme/app_responsive.dart';
import 'package:tala/core/theme/couleurs_tala.dart';
import 'package:tala/core/widget/etat_message.dart';
import 'package:tala/module/screens/profil/textes_info.dart';

/// Page de texte : Aide, Conditions d'utilisation ou Politique de
/// confidentialité. La page à afficher vient de l'adresse :
/// "/info/aide" → Get.parameters['page'] = "aide".
///
/// Un texte se lit mal sur des lignes de 1500 px : la colonne de texte
/// garde une largeur de lecture confortable (≈ 760 px), centrée.
class PageInfoScreen extends StatelessWidget {
  const PageInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final page = PageInfo.depuisSlug(Get.parameters['page']);

    return Scaffold(
      appBar: AppBar(title: Text(page?.titre ?? 'Page introuvable')),
      body: page == null
          ? const EtatMessage.vide(
              icone: Icons.search_off,
              titre: 'Page introuvable',
            )
          : _Contenu(sections: TextesInfo.pour(page)),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.sections});

  final List<SectionTexte> sections;

  @override
  Widget build(BuildContext context) {
    final marge = AppResponsive.margeHorizontale(context.largeurEcran);
    final discret = context.textes.bodySmall?.copyWith(
      color: context.schema.onSurfaceVariant,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: marge, vertical: AppEspacements.l),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          // SelectionArea : on peut sélectionner et copier le texte.
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in sections) ...[
                  Text(section.titre, style: context.textes.titleMedium),
                  const SizedBox(height: AppEspacements.s),
                  for (final paragraphe in section.paragraphes) ...[
                    Text(paragraphe, style: context.textes.bodyMedium),
                    const SizedBox(height: AppEspacements.s),
                  ],
                  const SizedBox(height: AppEspacements.l),
                ],
                Text(
                  'Dernière mise à jour : ${TextesInfo.miseAJour}',
                  style: discret,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

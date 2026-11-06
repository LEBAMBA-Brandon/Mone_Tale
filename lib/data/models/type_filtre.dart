/// Ce que propose la liste déroulante des filtres de la carte.
///
/// Un seul type à la fois : choisir "Statut" remplace les puces des
/// catégories par celles des statuts. L'icône de chaque type est dans
/// `core/theme/app_icons.dart` (un modèle ne dépend pas de l'interface).
enum TypeFiltre {
  tout(libelle: 'Tout'),
  statut(libelle: 'Statut'),
  gravite(libelle: 'Gravité'),
  quartier(libelle: 'Quartier'),
  periode(libelle: 'Période');

  const TypeFiltre({required this.libelle});

  /// Texte affiché dans la liste déroulante.
  final String libelle;
}

/// Les catégories de problèmes urbains.
///
/// - [valeurApi] : texte EXACT attendu et renvoyé par l'API Laravel
///   (majuscules et accents compris). Ne jamais le modifier sans modifier l'API.
/// - [libelle] : texte affiché à l'utilisateur.
///
/// La couleur et l'icône de chaque catégorie seront définies dans
/// `core/theme` (J3) : un modèle ne doit pas dépendre de l'interface.
enum Categorie {
  voirie(valeurApi: 'Voirie', libelle: 'Voirie'),
  ordures(valeurApi: 'Ordures', libelle: 'Ordures'),
  eclairagePublic(valeurApi: 'Éclairage public', libelle: 'Éclairage public'),
  caniveauInondation(
    valeurApi: 'Caniveau/Inondation',
    libelle: 'Caniveau / Inondation',
  ),
  autre(valeurApi: 'Autre', libelle: 'Autre');

  const Categorie({required this.valeurApi, required this.libelle});

  final String valeurApi;
  final String libelle;

  /// Convertit le texte de l'API en [Categorie].
  /// Valeur inconnue (ex : l'API ajoute une catégorie plus tard)
  /// → [Categorie.autre], au lieu de faire planter l'app.
  static Categorie depuisApi(String? valeur) {
    for (final categorie in Categorie.values) {
      if (categorie.valeurApi == valeur) return categorie;
    }
    return Categorie.autre;
  }
}

/// Informations générales sur l'application (Profil, partage, pages
/// d'information).
abstract final class AppInfos {
  static const String nom = 'tala';
  static const String version = '1.0.0';
  static const String editeur = 'BI-TECH Services';

  /// Lien de téléchargement de l'APK.
  /// ⚠️ À REMPLIR quand l'APK sera en ligne (Google Drive, Play Store…).
  /// Vide = le message de partage n'a pas de lien.
  static const String lienTelechargement = '';

  /// Texte envoyé par le bouton "Partager l'application".
  static String get messagePartage {
    const base =
        'Je signale les problèmes de la ville (voirie, ordures, éclairage, '
        'caniveaux) avec $nom.';
    return lienTelechargement.isEmpty
        ? '$base Demandez le lien d’installation à votre administrateur.'
        : '$base Installez-la ici : $lienTelechargement';
  }
}

/// Les pages d'information du Profil (texte fixe).
/// [slug] = morceau d'adresse : "/info/aide", "/info/conditions"…
enum PageInfo {
  aide(slug: 'aide', titre: 'Aide'),
  conditions(slug: 'conditions', titre: "Conditions d'utilisation"),
  confidentialite(
    slug: 'confidentialite',
    titre: 'Politique de confidentialité',
  );

  const PageInfo({required this.slug, required this.titre});

  final String slug;
  final String titre;

  /// "aide" → PageInfo.aide ; inconnu → null.
  static PageInfo? depuisSlug(String? slug) {
    for (final page in PageInfo.values) {
      if (page.slug == slug) return page;
    }
    return null;
  }
}

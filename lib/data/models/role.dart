/// Rôle d'un utilisateur de tala.
///
/// - [admin] : voit tous les signalements, change leur statut,
///   ajoute et gère les collecteurs.
/// - [collecteur] : crée des signalements et voit les siens.
enum Role {
  admin(valeurApi: 'admin', libelle: 'Administrateur'),
  collecteur(valeurApi: 'collecteur', libelle: 'Collecteur');

  const Role({required this.valeurApi, required this.libelle});

  /// Texte EXACT utilisé par l'API (`User::ROLES` côté Laravel).
  final String valeurApi;

  /// Texte affiché à l'écran.
  final String libelle;

  /// Valeur inconnue → [Role.collecteur].
  /// Sécurité : en cas de doute, on donne le MOINS de droits possible.
  /// (De toute façon, c'est l'API qui vérifie vraiment les droits.)
  static Role depuisApi(String? valeur) {
    for (final role in Role.values) {
      if (role.valeurApi == valeur) return role;
    }
    return Role.collecteur;
  }
}

/// Niveau de gravité d'un signalement.
///
/// [niveau] permet de trier (1 = le moins grave, 3 = le plus grave).
enum Gravite {
  faible(valeurApi: 'Faible', libelle: 'Faible', niveau: 1),
  moyenne(valeurApi: 'Moyenne', libelle: 'Moyenne', niveau: 2),
  critique(valeurApi: 'Critique', libelle: 'Critique', niveau: 3);

  const Gravite({
    required this.valeurApi,
    required this.libelle,
    required this.niveau,
  });

  final String valeurApi;
  final String libelle;
  final int niveau;

  /// Valeur inconnue → [Gravite.faible] (on ne plante pas).
  static Gravite depuisApi(String? valeur) {
    for (final gravite in Gravite.values) {
      if (gravite.valeurApi == valeur) return gravite;
    }
    return Gravite.faible;
  }
}

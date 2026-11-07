/// Avancement du traitement d'un signalement.
enum Statut {
  signale(valeurApi: 'Signalé', libelle: 'Signalé'),
  enCours(valeurApi: 'En cours', libelle: 'En cours'),
  resolu(valeurApi: 'Résolu', libelle: 'Résolu');

  const Statut({required this.valeurApi, required this.libelle});

  final String valeurApi;
  final String libelle;

  /// Valeur inconnue → [Statut.signale] (le statut par défaut de l'API).
  static Statut depuisApi(String? valeur) {
    for (final statut in Statut.values) {
      if (statut.valeurApi == valeur) return statut;
    }
    return Statut.signale;
  }
}

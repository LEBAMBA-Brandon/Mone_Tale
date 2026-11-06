/// Une période de dates, utilisée par le filtre "Période" de la carte.
///
/// [debut] et [fin] sont des JOURS (l'heure ne compte pas) et [fin] est
/// INCLUS : la période de novembre va du 1er au 30 novembre.
class Periode {
  const Periode({required this.debut, required this.fin});

  /// Le mois [mois] de l'année [annee], du 1er au dernier jour.
  ///
  /// Astuce : le "jour 0" d'un mois = le dernier jour du mois d'avant.
  /// DateTime(2026, 12, 0) → 30 novembre 2026. Plus besoin de savoir
  /// si un mois a 28, 30 ou 31 jours.
  factory Periode.mois(int annee, int mois) =>
      Periode(debut: DateTime(annee, mois), fin: DateTime(annee, mois + 1, 0));

  /// Les [nombre] derniers mois, du mois en cours au plus ancien.
  ///
  /// DateTime corrige seul les mois "hors limites" :
  /// DateTime(2026, 0) = décembre 2025, DateTime(2026, -1) = novembre 2025.
  /// [maintenant] sert pour les tests (sinon : la date du jour).
  static List<Periode> derniersMois(int nombre, {DateTime? maintenant}) {
    final reference = maintenant ?? DateTime.now();
    return List.unmodifiable([
      for (var i = 0; i < nombre; i++)
        Periode.mois(reference.year, reference.month - i),
    ]);
  }

  final DateTime debut;
  final DateTime fin;

  // Égalité "par valeur" : deux périodes aux mêmes dates sont égales.
  @override
  bool operator ==(Object other) =>
      other is Periode && other.debut == debut && other.fin == fin;

  @override
  int get hashCode => Object.hash(debut, fin);

  @override
  String toString() => 'Periode($debut → $fin)';
}

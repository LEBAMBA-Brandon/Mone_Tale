/// Formats d'affichage en français (dates), sans package externe.
abstract final class AppFormats {
  static const List<String> _mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  /// "31 oct. 2026 à 22h50"
  static String date(DateTime? date) {
    if (date == null) return 'Date inconnue';
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${jour(date)} à ${heure}h$minute';
  }

  /// "31 oct. 2026"
  static String jour(DateTime date) =>
      '${date.day} ${_mois[date.month - 1]} ${date.year}';

  /// "Nov. 2026" (pour les puces de période).
  /// Première lettre en majuscule : "août" → "Août".
  static String mois(DateTime date) {
    final nom = _mois[date.month - 1];
    return '${nom[0].toUpperCase()}${nom.substring(1)} ${date.year}';
  }

  /// Accorde un mot avec un nombre, à la française :
  /// 0 signalement, 1 signalement, 12 signalements.
  /// (En français, 0 s'écrit au singulier.)
  static String pluriel(int nombre, String singulier, [String? pluriel]) =>
      '$nombre ${nombre <= 1 ? singulier : (pluriel ?? '${singulier}s')}';

  /// "À l'instant", "Il y a 5 min", "Il y a 3 h", "Hier", "Il y a 4 jours",
  /// puis la date complète au-delà d'une semaine.
  static String depuis(DateTime? date, {DateTime? maintenant}) {
    if (date == null) return 'Date inconnue';
    final ecart = (maintenant ?? DateTime.now()).difference(date);
    if (ecart.isNegative || ecart.inMinutes < 1) return "À l'instant";
    if (ecart.inMinutes < 60) return 'Il y a ${ecart.inMinutes} min';
    if (ecart.inHours < 24) return 'Il y a ${ecart.inHours} h';
    if (ecart.inDays == 1) return 'Hier';
    if (ecart.inDays < 7) return 'Il y a ${ecart.inDays} jours';
    return jour(date);
  }
}

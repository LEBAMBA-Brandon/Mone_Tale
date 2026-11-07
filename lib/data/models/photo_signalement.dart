/// Photo prise (ou choisie) pour un signalement, prête à être envoyée.
class PhotoSignalement {
  const PhotoSignalement({required this.chemin, required this.tailleOctets});

  /// Taille maximale acceptée par l'API : `max:1024` (en Ko) dans
  /// StoreSignalementRequest → 1 Mo.
  static const int tailleMaxOctets = 1024 * 1024;

  /// Emplacement du fichier sur le téléphone.
  final String chemin;

  /// Poids du fichier, en octets.
  final int tailleOctets;

  bool get estTropLourde => tailleOctets > tailleMaxOctets;

  /// Poids lisible : "820 Ko", "1,3 Mo".
  String get tailleLisible {
    if (tailleOctets < 1024 * 1024) {
      return '${(tailleOctets / 1024).ceil()} Ko';
    }
    final mo = tailleOctets / (1024 * 1024);
    return '${mo.toStringAsFixed(1).replaceAll('.', ',')} Mo';
  }

  /// Nom du fichier seul ("IMG_2026.jpg"), pour l'envoi à l'API.
  /// `[/\\]` : marche avec les chemins Android (/) ET Windows (\).
  String get nomFichier => chemin.split(RegExp(r'[/\\]')).last;

  @override
  String toString() => 'PhotoSignalement($nomFichier, $tailleLisible)';
}

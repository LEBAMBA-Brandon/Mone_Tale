import 'package:mono/data/models/coordonnees.dart';
import 'package:mono/data/models/quartier.dart';
import 'package:mono/data/models/resultat_recherche.dart';
import 'package:mono/data/models/signalement.dart';
import 'package:mono/data/repositories/quartier_repository.dart';
import 'package:mono/data/repositories/signalement_repository.dart';
import 'package:mono/data/services/api_exception.dart';
import 'package:mono/data/services/recherche_recente_service.dart';

/// Tout ce qui concerne la barre de recherche "façon Google Maps" :
/// les suggestions ET l'historique des recherches récentes.
///
/// La recherche se fait **dans les données déjà chargées** (pas de requête
/// à chaque lettre tapée) : c'est instantané et ça marche hors ligne.
/// Le `debounce()` (attendre que l'utilisateur arrête de taper) sera
/// dans le controller au J2.
///
/// Exemples :
/// - "nzeng"     → le quartier Nzeng-Ayong + ses signalements
/// - "eclairage" → trouve "Éclairage public" (les accents sont ignorés)
/// - "trou glass" → les signalements contenant "trou" ET situés à Glass
class RechercheRepository {
  RechercheRepository({
    required this._signalementRepository,
    required this._quartierRepository,
    required this._rechercheRecenteService,
  });

  final SignalementRepository _signalementRepository;
  final QuartierRepository _quartierRepository;
  final RechercheRecenteService _rechercheRecenteService;

  /// En dessous de ce nombre de caractères, on ne cherche pas.
  static const int longueurMinimale = 2;

  /// Renvoie les suggestions : d'abord les quartiers, puis les signalements.
  /// Lève une [ApiException] seulement si AUCUNE donnée n'a jamais pu être
  /// chargée (ex : premier lancement sans réseau).
  Future<List<ResultatRecherche>> rechercher(
    String terme, {
    int limite = 10,
  }) async {
    final mots = _decouperEnMots(terme);
    if (mots.isEmpty) return const [];

    final signalements = await _signalementRepository.getSignalements();
    final quartiers = await _quartiersDisponibles(signalements);

    // 1) Quartiers correspondants. Ceux qui COMMENCENT par le texte
    //    tapé passent en premier.
    final quartiersTrouves =
        quartiers
            .where((q) => _contientTousLesMots(normaliser(q.nom), mots))
            .toList()
          ..sort(
            (a, b) => _priorite(
              a.nom,
              mots.first,
            ).compareTo(_priorite(b.nom, mots.first)),
          );

    final resultatsQuartiers = [
      for (final quartier in quartiersTrouves)
        _resultatPourQuartier(quartier, signalements),
    ];

    // 2) Signalements dont la description, la catégorie ou le quartier
    //    contiennent tous les mots tapés.
    final resultatsSignalements = [
      for (final signalement in signalements)
        if (_contientTousLesMots(_texteRecherchable(signalement), mots))
          ResultatSignalement(signalement),
    ];

    return [
      ...resultatsQuartiers,
      ...resultatsSignalements,
    ].take(limite).toList();
  }

  // ---------- Recherches récentes ----------

  Future<List<String>> getRecherchesRecentes() =>
      _rechercheRecenteService.lire();

  /// À appeler quand l'utilisateur valide une recherche ou choisit un résultat.
  Future<List<String>> enregistrerRecherche(String terme) =>
      _rechercheRecenteService.ajouter(terme);

  Future<List<String>> supprimerRecherche(String terme) =>
      _rechercheRecenteService.supprimer(terme);

  Future<void> effacerHistorique() => _rechercheRecenteService.toutEffacer();

  // ---------- Outils ----------

  /// Met un texte en minuscules, sans accents, et remplace la ponctuation
  /// par des espaces. Ex : "Nzeng-Ayong" → "nzeng ayong",
  /// "Éclairage public" → "eclairage public".
  static String normaliser(String texte) {
    final buffer = StringBuffer();
    for (final caractere in texte.toLowerCase().split('')) {
      buffer.write(_sansAccents[caractere] ?? caractere);
    }
    return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static const Map<String, String> _sansAccents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  /// "  Trou  Glass " → ["trou", "glass"]. Liste vide si trop court.
  List<String> _decouperEnMots(String terme) {
    final propre = normaliser(terme);
    if (propre.length < longueurMinimale) return const [];
    return propre.split(' ');
  }

  bool _contientTousLesMots(String texte, List<String> mots) =>
      mots.every(texte.contains);

  /// 0 = le nom commence par le mot tapé (prioritaire), 1 = sinon.
  int _priorite(String nom, String premierMot) =>
      normaliser(nom).startsWith(premierMot) ? 0 : 1;

  String _texteRecherchable(Signalement signalement) => normaliser(
    '${signalement.description} '
    '${signalement.categorie.libelle} '
    '${signalement.nomQuartier}',
  );

  ResultatQuartier _resultatPourQuartier(
    Quartier quartier,
    List<Signalement> signalements,
  ) {
    final duQuartier = signalements
        .where((s) => s.quartierId == quartier.id)
        .toList();
    return ResultatQuartier(
      quartier: quartier,
      nombreSignalements: duQuartier.length,

      // 1er choix : le vrai centre du quartier (fourni par l'API).
      // Sinon : la moyenne de ses signalements.
      centre:
          quartier.centre ??
          Coordonnees.centreDe(duQuartier.map((s) => s.coordonnees)),
    );
  }

  /// Quartiers depuis l'API. En cas d'échec, on les déduit des signalements
  /// déjà reçus : la recherche continue de fonctionner.
  Future<List<Quartier>> _quartiersDisponibles(
    List<Signalement> signalements,
  ) async {
    try {
      return await _quartierRepository.getQuartiers();
    } on ApiException {
      final parId = <int, Quartier>{
        for (final s in signalements)
          if (s.quartier != null) s.quartier!.id: s.quartier!,
      };
      return parId.values.toList();
    }
  }
}

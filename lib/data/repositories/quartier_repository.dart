import 'package:tala/data/models/quartier.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/preferences_formulaire_service.dart';
import 'package:tala/data/services/quartier_service.dart';

/// Point d'accès unique aux quartiers (liste du formulaire "Ajouter un
/// signalement").
///
/// Les quartiers ne changent presque jamais : on les charge UNE fois,
/// puis on les garde en mémoire tant que l'app est ouverte.
class QuartierRepository {
  QuartierRepository(this._service, this._preferences);

  final QuartierService _service;
  final PreferencesFormulaireService _preferences;

  List<Quartier>? _cache;
  Future<List<Quartier>>? _chargementEnCours;

  /// Tous les quartiers, triés par ordre alphabétique.
  Future<List<Quartier>> getQuartiers({bool forcerRafraichissement = false}) {
    final cache = _cache;
    if (!forcerRafraichissement && cache != null) return Future.value(cache);
    return _chargementEnCours ??= _charger().whenComplete(
      () => _chargementEnCours = null,
    );
  }

  /// Quartier déjà chargé, sans appel réseau (ou `null`).
  Quartier? trouverParId(int id) {
    for (final quartier in _cache ?? const <Quartier>[]) {
      if (quartier.id == id) return quartier;
    }
    return null;
  }

  /// Dernier quartier utilisé par le collecteur sur ce téléphone,
  /// pour le pré-sélectionner dans le formulaire. `null` si aucun.
  Future<Quartier?> getDernierQuartierUtilise() async {
    final id = await _preferences.lireDernierQuartierId();
    if (id == null) return null;
    try {
      await getQuartiers(); // remplit le cache si besoin
      return trouverParId(id); // null si le quartier a été supprimé
    } on ApiException {
      return null; // pas grave : le collecteur choisira lui-même
    }
  }

  Future<List<Quartier>> _charger() async {
    final liste = await _service.recupererQuartiers();
    final triee = [...liste]
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    final resultat = List<Quartier>.unmodifiable(triee);
    _cache = resultat;
    return resultat;
  }
}

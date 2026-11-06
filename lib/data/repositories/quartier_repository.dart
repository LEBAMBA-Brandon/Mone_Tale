import 'package:mono/data/models/quartier.dart';
import 'package:mono/data/services/quartier_service.dart';

/// Point d'accès unique aux quartiers.
///
/// Les quartiers ne changent presque jamais : on les charge UNE fois,
/// puis on les garde en mémoire tant que l'app est ouverte.
class QuartierRepository {
  QuartierRepository(this._service);

  final QuartierService _service;

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

  Future<List<Quartier>> _charger() async {
    final liste = await _service.recupererQuartiers();
    final triee = [...liste]
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    final resultat = List<Quartier>.unmodifiable(triee);
    _cache = resultat;
    return resultat;
  }
}

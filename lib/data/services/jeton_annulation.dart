import 'package:dio/dio.dart';

/// Permet d'annuler une requête en cours.
///
/// Deux cas d'usage dans les controllers (J2) :
/// 1. Dans `onClose()` : l'utilisateur a quitté l'écran → on annule tout.
/// 2. Quand l'utilisateur change de filtre très vite : on annule la requête
///    du filtre précédent pour ne garder que la dernière.
///
/// ⚠️ Un jeton annulé ne peut PAS être réutilisé : toute nouvelle requête
/// avec ce jeton serait annulée immédiatement. Après `annuler()`, il faut
/// créer un nouveau `JetonAnnulation()`.
///
/// C'est un petit "emballage" autour du `CancelToken` de dio, pour que les
/// controllers n'aient pas besoin de connaître dio.
class JetonAnnulation {
  final CancelToken _jetonDio = CancelToken();

  bool get estAnnule => _jetonDio.isCancelled;

  void annuler([String raison = 'Écran fermé']) {
    if (!estAnnule) _jetonDio.cancel(raison);
  }

  /// Réservé à ApiClient (ne pas utiliser ailleurs).
  CancelToken get jetonDio => _jetonDio;
}

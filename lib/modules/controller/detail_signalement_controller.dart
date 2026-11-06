import 'package:get/get.dart';
import 'package:mono/core/widget/notifications.dart';
import 'package:mono/data/models/signalement.dart';
import 'package:mono/data/repositories/signalement_repository.dart';
import 'package:mono/data/services/api_exception.dart';
import 'package:mono/data/services/jeton_annulation.dart';
import 'package:mono/modules/routes/app_routes.dart';

/// Controller de l'écran Détail d'un signalement.
///
/// Cycle de vie :
/// - onInit  → lit l'id dans l'URL, affiche TOUT DE SUITE les données déjà
///             connues (argument ou cache), puis demande la version à jour à l'API
/// - onClose → annule la requête si l'utilisateur est reparti avant la réponse
class DetailSignalementController extends GetxController {
  DetailSignalementController(this._repository);

  final SignalementRepository _repository;

  final signalement = Rxn<Signalement>();
  final chargement = false.obs;
  final erreur = Rxn<ApiException>();

  int? _id;
  JetonAnnulation? _jeton;

  bool get estIntrouvable => erreur.value?.type == TypeErreurApi.introuvable;

  @override
  void onInit() {
    super.onInit();
    // "/signalement/12" → Get.parameters['id'] = "12"
    _id = int.tryParse(Get.parameters['id'] ?? '');

    final id = _id;
    final argument = Get.arguments;
    if (argument is Signalement && argument.id == id) {
      signalement.value = argument; // envoyé par la carte
    } else if (id != null) {
      signalement.value = _repository.trouverDansCache(id); // ou null
    }
    charger();
  }

  @override
  void onClose() {
    _jeton?.annuler();
    super.onClose();
  }

  /// (Re)charge depuis l'API. Utilisé aussi par "tirer pour rafraîchir".
  Future<void> charger() async {
    final id = _id;
    if (id == null) {
      erreur.value = const ApiException(
        type: TypeErreurApi.introuvable,
        message: "Ce signalement n'existe pas.",
      );
      return;
    }

    _jeton?.annuler();
    final jeton = JetonAnnulation();
    _jeton = jeton;
    chargement.value = true;
    erreur.value = null;
    try {
      signalement.value = await _repository.getSignalement(
        id,
        annulation: jeton,
      );
    } on ApiException catch (e) {
      if (e.estAnnulation) return;
      if (e.type == TypeErreurApi.introuvable) signalement.value = null;
      erreur.value = e;
      // On a déjà quelque chose à montrer → simple notification.
      if (signalement.value != null) Notifications.erreur(e.message);
    } finally {
      if (identical(_jeton, jeton)) chargement.value = false;
    }
  }

  /// Retour à la carte. Si la page a été ouverte directement (lien web),
  /// il n'y a rien "derrière" : on ouvre alors la carte.
  void retour() {
    final navigateur = Get.key.currentState;
    if (navigateur != null && navigateur.canPop()) {
      Get.back<void>();
    } else {
      Get.offAllNamed<void>(AppRoutes.carte);
    }
  }
}

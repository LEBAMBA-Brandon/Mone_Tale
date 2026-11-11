import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tala/core/theme/app_infos.dart';
import 'package:tala/core/widget/dialogue_confirmation.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/preference_theme.dart';
import 'package:tala/data/models/utilisateur.dart';
import 'package:tala/data/repositories/auth_repository.dart';
import 'package:tala/data/services/stockage_local_service.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/controller/theme_controller.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Onglet "Profil" (collecteur ET admin) :
/// - Mon contenu  → raccourcis vers les autres onglets ;
/// - Compte       → notifications (accepter / refuser), modifier mes infos ;
/// - Informations → aide, conditions, confidentialité, partager (collecteur) ;
/// - Se déconnecter.
///
/// Cycle de vie :
/// - onInit → lit l'utilisateur connecté et le choix des notifications
class ProfilController extends GetxController {
  ProfilController({
    required this._auth,
    required this._theme,
    required this._stockage,
    required this._accueil,
  });

  final AuthRepository _auth;
  final ThemeController _theme;
  final StockageLocalService _stockage;
  final AccueilController _accueil;

  final utilisateur = Rxn<Utilisateur>();

  /// L'utilisateur a-t-il ACCEPTÉ les notifications ? (non par défaut)
  final notificationsActives = false.obs;
  final deconnexionEnCours = false.obs;

  bool get estAdmin => _auth.estAdmin;
  Rx<PreferenceTheme> get preferenceTheme => _theme.preference;

  @override
  void onInit() {
    super.onInit();
    utilisateur.value = _auth.utilisateur;
    notificationsActives.value = _stockage.lireNotificationsActives();
  }

  // ---------- Mon contenu ----------

  /// Raccourci vers un onglet (0 = liste, 1 = ajouter, 2 = collecteurs).
  void allerA(int onglet) => _accueil.changerOnglet(onglet);

  // ---------- Compte ----------

  /// Interrupteur "Notifications" : accepter (true) ou refuser (false).
  ///
  /// Pour l'instant on enregistre seulement le CHOIX (GetStorage).
  /// Quand Firebase sera branché, c'est ici qu'on demandera la permission
  /// au téléphone et qu'on enverra (ou supprimera) le jeton FCM à l'API.
  Future<void> choisirNotifications(bool accepter) async {
    notificationsActives.value = accepter;
    await _stockage.enregistrerNotificationsActives(accepter);
    Notifications.info(
      accepter
          ? 'Notifications activées : vous serez prévenu des changements.'
          : 'Notifications désactivées.',
    );
  }

  Future<void> ouvrirModification() async {
    await Get.toNamed<void>(AppRoutes.modifierProfil);
    // Au retour : le nom ou l'e-mail a peut-être changé.
    utilisateur.value = _auth.utilisateur;
    utilisateur.refresh(); // Utilisateur compare aussi par id seulement
  }

  // ---------- Informations ----------

  void ouvrirInfo(PageInfo page) =>
      Get.toNamed<void>(AppRoutes.versInfo(page.slug));

  /// Ouvre la fenêtre de partage du téléphone (WhatsApp, SMS, e-mail…).
  Future<void> partager() async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: AppInfos.messagePartage, subject: AppInfos.nom),
      );
    } catch (erreur) {
      debugPrint('Partage impossible : $erreur');
      Notifications.erreur('Le partage est indisponible sur cet appareil.');
    }
  }

  // ---------- Thème (menu en haut à droite) ----------

  void choisirTheme(PreferenceTheme choix) => _theme.definir(choix);

  // ---------- Déconnexion ----------

  Future<void> deconnecter() async {
    final confirme = await DialogueConfirmation.demander(
      titre: 'Se déconnecter ?',
      message: 'Il faudra saisir à nouveau votre e-mail et votre mot de passe.',
      libelleConfirmer: 'Se déconnecter',
    );
    if (!confirme) return;

    deconnexionEnCours.value = true;
    await _auth.deconnecter(); // marche même sans réseau
    // Vide l'historique : "retour" ne doit pas ramener dans l'app.
    Get.offAllNamed<void>(AppRoutes.connexion);
  }
}

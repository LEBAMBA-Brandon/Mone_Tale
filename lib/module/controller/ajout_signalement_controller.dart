import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:tala/core/widget/notifications.dart';
import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/coordonnees.dart';
import 'package:tala/data/models/gravite.dart';
import 'package:tala/data/models/nouveau_signalement.dart';
import 'package:tala/data/models/photo_signalement.dart';
import 'package:tala/data/models/position_gps.dart';
import 'package:tala/data/models/quartier.dart';
import 'package:tala/data/repositories/quartier_repository.dart';
import 'package:tala/data/repositories/signalement_repository.dart';
import 'package:tala/data/services/api_exception.dart';
import 'package:tala/data/services/jeton_annulation.dart';
import 'package:tala/data/services/localisation_service.dart';
import 'package:tala/data/services/photo_service.dart';
import 'package:tala/module/controller/accueil_controller.dart';
import 'package:tala/module/routes/app_routes.dart';

/// Onglet "Ajouter un signalement" du collecteur.
///
/// Objectif du sujet : un signalement complet en MOINS D'UNE MINUTE.
/// - la position GPS est cherchée toute seule à l'ouverture ;
/// - le dernier quartier utilisé est déjà sélectionné ;
/// - catégorie et gravité se choisissent en un appui (puces).
///
/// Tout le formulaire tient dans UN objet [brouillon] (NouveauSignalement).
/// Chaque choix crée une COPIE modifiée (`copyWith`) : l'écran se met à
/// jour tout seul grâce à `.obs`.
///
/// Cycle de vie :
/// - onInit  → champ description, quartiers, photo perdue (Android)
/// - onReady → localisation GPS automatique
/// - onClose → annule l'envoi en cours, libère le champ texte
class AjoutSignalementController extends GetxController {
  AjoutSignalementController({
    required this._signalements,
    required this._quartiers,
    required this._localisation,
    required this._photos,
    required this._accueil,
  });

  final SignalementRepository _signalements;
  final QuartierRepository _quartiers;
  final LocalisationService _localisation;
  final PhotoService _photos;
  final AccueilController _accueil;

  late final TextEditingController champDescription;

  /// Le formulaire en cours de saisie.
  final brouillon = NouveauSignalement.vide.obs;

  /// Erreurs par champ ("photo", "categorie", "quartier_id"…).
  final erreurs = <String, String>{}.obs;

  final quartiers = <Quartier>[].obs;
  final chargementQuartiers = false.obs;

  /// Dernière position GPS (avec sa précision) ; `null` tant qu'on n'a rien.
  final positionGps = Rxn<PositionGps>();

  /// `true` si le collecteur a placé le point lui-même sur la carte.
  final positionManuelle = false.obs;
  final localisationEnCours = false.obs;

  final photoEnCours = false.obs;

  final envoiEnCours = false.obs;

  /// Progression de l'envoi de 0.0 à 1.0 (`null` hors envoi).
  final progression = RxnDouble();

  JetonAnnulation? _jetonEnvoi;

  @override
  void onInit() {
    super.onInit();
    champDescription = TextEditingController();
    unawaited(_chargerQuartiers());
    unawaited(_recupererPhotoPerdue());
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(localiser());
  }

  @override
  void onClose() {
    _jetonEnvoi?.annuler();
    champDescription.dispose();
    super.onClose();
  }

  // =====================================================================
  //  POSITION
  // =====================================================================

  Future<void> localiser() async {
    if (localisationEnCours.value) return;
    localisationEnCours.value = true;
    try {
      final position = await _localisation.obtenirPositionActuelle();
      if (isClosed) return;
      positionGps.value = position;
      positionManuelle.value = false;
      _modifier(
        brouillon.value.copyWith(position: () => position.coordonnees),
        'latitude',
      );
    } on LocalisationException catch (e) {
      Notifications.erreur(
        e.message,
        libelleAction: e.necessiteParametres ? 'Paramètres' : null,
        onAction: e.necessiteParametres
            ? () => _localisation.ouvrirParametres(e)
            : null,
      );
    } finally {
      if (!isClosed) localisationEnCours.value = false;
    }
  }

  /// Ouvre la carte plein écran pour placer le point à la main.
  Future<void> ajusterPosition() async {
    final depart = brouillon.value.position ?? Coordonnees.libreville;
    // `toNamed` attend que l'écran se ferme et récupère son résultat
    // (`Get.back(result: ...)` dans ChoixPositionController).
    final choisie = await Get.toNamed<Coordonnees>(
      AppRoutes.choixPosition,
      arguments: depart,
    );
    if (choisie == null || isClosed) return; // annulé
    positionManuelle.value = true;
    _modifier(brouillon.value.copyWith(position: () => choisie), 'latitude');
  }

  // =====================================================================
  //  PHOTO
  // =====================================================================

  Future<void> prendrePhoto() => _obtenirPhoto(_photos.prendrePhoto);

  Future<void> choisirDansGalerie() => _obtenirPhoto(_photos.choisirDansGalerie);

  void retirerPhoto() =>
      brouillon.value = brouillon.value.copyWith(photo: () => null);

  /// [source] = la fonction à appeler (appareil photo ou galerie).
  Future<void> _obtenirPhoto(
    Future<PhotoSignalement?> Function() source,
  ) async {
    if (photoEnCours.value) return;
    photoEnCours.value = true;
    try {
      final photo = await source();
      if (photo == null || isClosed) return; // annulé
      _modifier(brouillon.value.copyWith(photo: () => photo), 'photo');
    } on PhotoException catch (e) {
      erreurs['photo'] = e.message;
    } finally {
      if (!isClosed) photoEnCours.value = false;
    }
  }

  Future<void> _recupererPhotoPerdue() async {
    final photo = await _photos.recupererPhotoPerdue();
    if (photo == null || isClosed) return;
    brouillon.value = brouillon.value.copyWith(photo: () => photo);
    Notifications.info('Votre photo a été récupérée.');
  }

  // =====================================================================
  //  CHOIX
  // =====================================================================

  void choisirCategorie(Categorie categorie) => _modifier(
    brouillon.value.copyWith(categorie: () => categorie),
    'categorie',
  );

  void choisirGravite(Gravite gravite) => _modifier(
    brouillon.value.copyWith(gravite: () => gravite),
    'gravite',
  );

  void choisirQuartier(Quartier? quartier) => _modifier(
    brouillon.value.copyWith(quartier: () => quartier),
    'quartier_id',
  );

  /// Appelé à chaque lettre tapée dans la description.
  void surDescription(String texte) =>
      _modifier(brouillon.value.copyWith(description: texte), 'description');

  /// Remplace le brouillon et efface l'erreur du champ modifié.
  void _modifier(NouveauSignalement nouveau, String champ) {
    brouillon.value = nouveau;
    erreurs.remove(champ);
  }

  Future<void> _chargerQuartiers() async {
    chargementQuartiers.value = true;
    try {
      quartiers.assignAll(await _quartiers.getQuartiers());
      // Pré-sélectionne le dernier quartier utilisé (s'il n'y en a pas déjà un).
      final dernier = await _quartiers.getDernierQuartierUtilise();
      if (!isClosed && dernier != null && brouillon.value.quartier == null) {
        brouillon.value = brouillon.value.copyWith(quartier: () => dernier);
      }
    } on ApiException catch (e) {
      if (!isClosed) erreurs['quartier_id'] = e.message;
    } finally {
      if (!isClosed) chargementQuartiers.value = false;
    }
  }

  Future<void> rechargerQuartiers() {
    erreurs.remove('quartier_id');
    return _chargerQuartiers();
  }

  // =====================================================================
  //  ENVOI
  // =====================================================================

  Future<void> envoyer() async {
    if (envoiEnCours.value) return;
    FocusManager.instance.primaryFocus?.unfocus();

    // 1) Vérification sur le téléphone : pas de réseau pour une erreur évidente.
    final erreursLocales = brouillon.value.valider();
    if (erreursLocales.isNotEmpty) {
      erreurs.assignAll(erreursLocales);
      Notifications.erreur('Il manque des informations (en rouge).');
      return;
    }

    // 2) Envoi avec progression.
    final jeton = JetonAnnulation();
    _jetonEnvoi = jeton;
    envoiEnCours.value = true;
    progression.value = 0;
    try {
      await _signalements.creerSignalement(
        brouillon.value,
        progression: (p) => progression.value = p,
        annulation: jeton,
      );
      if (isClosed) return;
      Notifications.succes('Signalement envoyé. Merci !');
      _reinitialiser();
      // Retour à la liste, où le nouveau signalement apparaît en premier.
      _accueil.changerOnglet(AccueilController.ongletListe);
    } on ApiException catch (e) {
      if (e.estAnnulation || isClosed) return;
      if (e.type == TypeErreurApi.validation) {
        erreurs.assignAll({
          for (final champ in e.erreursChamps.keys)
            champ: ?e.erreurPourChamp(champ),
        });
      }
      // Le brouillon est GARDÉ : le collecteur peut réessayer sans tout
      // ressaisir (ex : réseau coupé pendant l'envoi).
      Notifications.erreur(
        e.message,
        libelleAction: e.estProblemeReseau ? 'Réessayer' : null,
        onAction: e.estProblemeReseau ? envoyer : null,
      );
    } finally {
      if (!isClosed) {
        envoiEnCours.value = false;
        progression.value = null;
      }
    }
  }

  /// Formulaire vidé pour le signalement suivant. On GARDE le quartier
  /// (souvent le même) et on relance le GPS (le lieu a sûrement changé).
  void _reinitialiser() {
    brouillon.value = NouveauSignalement(quartier: brouillon.value.quartier);
    champDescription.clear();
    erreurs.clear();
    positionGps.value = null;
    positionManuelle.value = false;
    unawaited(localiser());
  }
}

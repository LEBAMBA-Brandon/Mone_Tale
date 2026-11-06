import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/app_formats.dart';
import 'package:mono/core/widget/notifications.dart';
import 'package:mono/data/models/categorie.dart';
import 'package:mono/data/models/coordonnees.dart';
import 'package:mono/data/models/gravite.dart';
import 'package:mono/data/models/periode.dart';
import 'package:mono/data/models/quartier.dart';
import 'package:mono/data/models/resultat_recherche.dart';
import 'package:mono/data/models/signalement.dart';
import 'package:mono/data/models/signalement_filtre.dart';
import 'package:mono/data/models/statut.dart';
import 'package:mono/data/models/type_filtre.dart';
import 'package:mono/data/repositories/quartier_repository.dart';
import 'package:mono/data/repositories/recherche_repository.dart';
import 'package:mono/data/repositories/signalement_repository.dart';
import 'package:mono/data/services/api_exception.dart';
import 'package:mono/data/services/jeton_annulation.dart';
import 'package:mono/data/services/localisation_service.dart';
import 'package:mono/data/services/stockage_local_service.dart';
import 'package:mono/modules/routes/app_routes.dart';

/// Controller de l'écran Carte (écran principal de l'app visiteur).
///
/// Cycle de vie :
/// - onInit  → création des outils (champ texte, carte, debounce),
///             calcul des périodes + 1er chargement
/// - onReady → (écran affiché) point bleu si la localisation est déjà autorisée
/// - onClose → annulation des requêtes + libération de tous les outils
class CarteController extends GetxController {
  CarteController({
    required this._signalementRepository,
    required this._rechercheRepository,
    required this._quartierRepository,
    required LocalisationService localisationService,
    required this._stockage,
  }) : _localisation = localisationService;

  final SignalementRepository _signalementRepository;
  final RechercheRepository _rechercheRepository;
  final QuartierRepository _quartierRepository;
  final LocalisationService _localisation;
  final StockageLocalService _stockage;

  // ---------- Réglages de la carte ----------
  static const double zoomInitial = 13;
  static const double zoomMin = 5;
  static const double zoomMax = 19;
  static const double zoomQuartier = 15;
  static const double zoomPosition = 16;
  static const double zoomSignalement = 17;

  /// Rayon de "Autour de moi", en mètres.
  static const double rayonAutourDeMoi = 500;

  /// Nombre de mois proposés par le filtre "Période".
  static const int nombrePeriodes = 6;

  // ---------- Outils (créés dans onInit, libérés dans onClose) ----------
  late final TextEditingController champRecherche;
  late final FocusNode focusRecherche;
  late final MapController carte;
  late final Coordonnees centreInitial;
  Worker? _workerRecherche;
  JetonAnnulation? _jetonChargement;
  bool _carteEstPrete = false;

  // ---------- État observé par l'écran ----------
  final signalements = <Signalement>[].obs;
  final chargement = false.obs;
  final erreur = Rxn<ApiException>();

  // ---------- Filtres ----------
  /// Choix de la liste déroulante : décide QUELLES puces sont affichées
  /// à côté ("Tout" → catégories, "Statut" → statuts…).
  final typeFiltre = TypeFiltre.tout.obs;

  /// Le filtre envoyé à l'API. Un seul champ rempli à la fois,
  /// ou aucun ([SignalementFiltre.vide]) = tous les signalements.
  final filtre = SignalementFiltre.vide.obs;

  /// Quartiers proposés par le filtre "Quartier" (chargés à la demande).
  final quartiers = <Quartier>[].obs;
  final chargementQuartiers = false.obs;

  /// Les [nombrePeriodes] derniers mois, du plus récent au plus ancien.
  /// Ne change pas pendant l'utilisation : pas besoin de `.obs`.
  late final List<Periode> periodes;

  /// Signalement touché sur la carte (affiche l'aperçu en bas).
  final selection = Rxn<Signalement>();

  final terme = ''.obs;
  final resultats = <ResultatRecherche>[].obs;
  final rechercheEnCours = false.obs;
  final rechercheOuverte = false.obs;
  final recherchesRecentes = <String>[].obs;

  final positionUtilisateur = Rxn<Coordonnees>();
  final localisationEnCours = false.obs;

  // =====================================================================
  //  CYCLE DE VIE
  // =====================================================================

  @override
  void onInit() {
    super.onInit();
    champRecherche = TextEditingController();
    focusRecherche = FocusNode()..addListener(_surChangementFocus);
    carte = MapController();
    periodes = Periode.derniersMois(nombrePeriodes);

    // Dernière position connue (GetStorage) → la carte s'ouvre au bon endroit.
    centreInitial = _stockage.lireDernierePosition() ?? Coordonnees.libreville;

    // debounce : on attend que l'utilisateur ARRÊTE de taper pendant 400 ms
    // avant de chercher (au lieu de chercher à chaque lettre).
    _workerRecherche = debounce<String>(
      terme,
      _rechercher,
      time: AppDurees.debounceRecherche,
    );

    unawaited(_chargerRecherchesRecentes());
    unawaited(charger());
  }

  @override
  void onReady() {
    super.onReady();
    // L'écran est affiché : on peut s'occuper de la localisation sans
    // retarder l'apparition de la carte.
    unawaited(_afficherPositionSiDejaAutorise());
  }

  @override
  void onClose() {
    _jetonChargement?.annuler(); // plus besoin de la réponse
    _workerRecherche?.dispose();
    focusRecherche
      ..removeListener(_surChangementFocus)
      ..dispose();
    champRecherche.dispose();
    carte.dispose();
    super.onClose();
  }

  // =====================================================================
  //  CHARGEMENT
  // =====================================================================

  /// Charge les signalements selon le filtre actuel.
  /// [forcer] → ignore le cache (bouton "Réessayer").
  Future<void> charger({bool forcer = false}) async {
    // Si une requête est encore en cours (ex : filtre changé très vite),
    // on l'annule : seule la DERNIÈRE compte.
    _jetonChargement?.annuler();
    final jeton = JetonAnnulation();
    _jetonChargement = jeton;

    chargement.value = true;
    erreur.value = null;
    try {
      final liste = await _signalementRepository.getSignalements(
        filtre: filtre.value,
        forcerRafraichissement: forcer,
        annulation: jeton,
      );
      if (jeton.estAnnule) return; // une requête plus récente a pris le relais

      // On ne garde que les points affichables sur la carte.
      signalements.assignAll(liste.where((s) => s.coordonnees.estValide));

      // L'aperçu ouvert n'est plus dans la liste → on le ferme.
      final actuel = selection.value;
      if (actuel != null && !signalements.contains(actuel)) {
        selection.value = null;
      }
    } on ApiException catch (e) {
      if (e.estAnnulation || jeton.estAnnule) return;
      erreur.value = e;
      // Des données sont déjà affichées → simple notification
      // (l'écran d'erreur complet ne s'affiche que s'il n'y a rien).
      if (signalements.isNotEmpty) {
        Notifications.erreur(
          e.message,
          libelleAction: 'Réessayer',
          onAction: () => charger(forcer: true),
        );
      }
    } finally {
      if (identical(_jetonChargement, jeton)) chargement.value = false;
    }
  }

  // =====================================================================
  //  FILTRES
  // =====================================================================

  /// Choix dans la liste déroulante ("Tout", "Statut", "Gravité"…).
  ///
  /// On ne peut filtrer que sur UN critère à la fois : changer de type
  /// efface donc le filtre précédent et réaffiche tous les signalements.
  void choisirTypeFiltre(TypeFiltre type) {
    if (typeFiltre.value == type) return;
    typeFiltre.value = type;
    if (type == TypeFiltre.quartier) unawaited(_chargerQuartiers());
    _appliquerFiltre(SignalementFiltre.vide);
  }

  // Puce touchée → on filtre sur elle seule.
  // La MÊME puce touchée une 2e fois → on la désélectionne (tous les signalements).
  void choisirCategorie(Categorie categorie) =>
      _basculerFiltre(SignalementFiltre(categorie: categorie));

  void choisirStatut(Statut statut) =>
      _basculerFiltre(SignalementFiltre(statut: statut));

  void choisirGravite(Gravite gravite) =>
      _basculerFiltre(SignalementFiltre(gravite: gravite));

  void choisirQuartier(Quartier quartier) =>
      _basculerFiltre(SignalementFiltre(quartierId: quartier.id));

  void choisirPeriode(Periode periode) => _basculerFiltre(
    SignalementFiltre(dateDebut: periode.debut, dateFin: periode.fin),
  );

  /// Retour à "Tout", sans aucun filtre.
  void reinitialiserFiltres() {
    typeFiltre.value = TypeFiltre.tout;
    _appliquerFiltre(SignalementFiltre.vide);
  }

  /// Nom du filtre actif pour les messages ("Voirie", "En cours",
  /// "Nov. 2026"…). `null` = aucun filtre.
  String? get libelleFiltreActif {
    final actuel = filtre.value;
    // `if (x case final y?)` : "si x n'est pas null, appelle-le y".
    if (actuel.categorie case final categorie?) return categorie.libelle;
    if (actuel.statut case final statut?) return statut.libelle;
    if (actuel.gravite case final gravite?) {
      return 'Gravité ${gravite.libelle.toLowerCase()}';
    }
    if (actuel.quartierId case final id?) {
      for (final quartier in quartiers) {
        if (quartier.id == id) return quartier.nom;
      }
      return 'Quartier choisi';
    }
    if (actuel.dateDebut case final debut?) return AppFormats.mois(debut);
    return null;
  }

  /// Même filtre que l'actuel → on l'enlève ; sinon → on le prend.
  void _basculerFiltre(SignalementFiltre nouveau) {
    _appliquerFiltre(
      filtre.value == nouveau ? SignalementFiltre.vide : nouveau,
    );
  }

  void _appliquerFiltre(SignalementFiltre nouveau) {
    // `==` est redéfini dans SignalementFiltre : deux filtres identiques
    // sont égaux → pas de rechargement inutile.
    if (filtre.value == nouveau) return;
    filtre.value = nouveau;
    selection.value = null;
    unawaited(charger());
  }

  /// Charge la liste des quartiers pour leurs puces.
  /// Le repository les garde en cache : seul le 1er appel touche le réseau.
  Future<void> _chargerQuartiers() async {
    if (chargementQuartiers.value) return; // déjà en cours
    chargementQuartiers.value = true;
    try {
      final liste = await _quartierRepository.getQuartiers();
      if (isClosed) return; // l'écran a été quitté entre-temps
      quartiers.assignAll(liste);
    } on ApiException {
      if (isClosed || quartiers.isNotEmpty) return;
      // Pas de réseau : on reprend les quartiers des signalements déjà
      // reçus (un Map par id pour ne pas avoir de doublons).
      final parId = <int, Quartier>{
        for (final signalement in signalements)
          if (signalement.quartier case final quartier?) quartier.id: quartier,
      };
      quartiers.assignAll(
        parId.values.toList()
          ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase())),
      );
    } finally {
      if (!isClosed) chargementQuartiers.value = false;
    }
  }

  // =====================================================================
  //  RECHERCHE
  // =====================================================================

  /// Appelé à chaque lettre tapée (le debounce fait le reste).
  void surSaisie(String texte) => terme.value = texte;

  /// Touche "Rechercher" du clavier : on prend le premier résultat.
  void validerRecherche(String texte) {
    if (resultats.isNotEmpty) {
      choisirResultat(resultats.first);
    } else {
      unawaited(_enregistrerRecherche(texte));
    }
  }

  /// Bouton ✕ de la barre de recherche.
  void effacerRecherche() {
    terme.value = '';
    resultats.clear();
    rechercheEnCours.value = false;
  }

  void fermerRecherche() {
    focusRecherche.unfocus();
    rechercheOuverte.value = false;
  }

  /// Suggestion choisie dans la liste.
  void choisirResultat(ResultatRecherche resultat) {
    final texte = champRecherche.text.trim();
    fermerRecherche();
    unawaited(_enregistrerRecherche(texte.isEmpty ? resultat.titre : texte));

    // `switch` sur une classe `sealed` : Dart vérifie qu'on traite TOUS les cas.
    switch (resultat) {
      case ResultatQuartier(:final centre):
        if (centre == null) {
          Notifications.info(
            'Aucun signalement dans ce quartier pour le moment.',
          );
          return;
        }
        _deplacerCarte(centre, zoomQuartier);
      case ResultatSignalement(:final signalement):
        selectionner(signalement);
    }
  }

  /// Recherche récente touchée : on la relance immédiatement.
  void choisirRechercheRecente(String recherche) {
    champRecherche.value = TextEditingValue(
      text: recherche,
      selection: TextSelection.collapsed(offset: recherche.length),
    );
    terme.value = recherche;
    unawaited(_rechercher(recherche)); // sans attendre le debounce
  }

  Future<void> supprimerRechercheRecente(String recherche) async {
    recherchesRecentes.assignAll(
      await _rechercheRepository.supprimerRecherche(recherche),
    );
  }

  Future<void> effacerHistorique() async {
    await _rechercheRepository.effacerHistorique();
    recherchesRecentes.clear();
  }

  Future<void> _rechercher(String texte) async {
    if (texte.trim().length < RechercheRepository.longueurMinimale) {
      resultats.clear();
      rechercheEnCours.value = false;
      return;
    }
    rechercheEnCours.value = true;
    try {
      final trouves = await _rechercheRepository.rechercher(texte);
      // L'utilisateur a continué à taper : ce résultat est déjà périmé.
      if (texte != terme.value) return;
      resultats.assignAll(trouves);
    } on ApiException {
      if (texte == terme.value) resultats.clear();
    } finally {
      if (texte == terme.value) rechercheEnCours.value = false;
    }
  }

  Future<void> _chargerRecherchesRecentes() async {
    recherchesRecentes.assignAll(
      await _rechercheRepository.getRecherchesRecentes(),
    );
  }

  Future<void> _enregistrerRecherche(String texte) async {
    if (texte.trim().length < RechercheRepository.longueurMinimale) return;
    recherchesRecentes.assignAll(
      await _rechercheRepository.enregistrerRecherche(texte),
    );
  }

  void _surChangementFocus() {
    rechercheOuverte.value = focusRecherche.hasFocus;
    if (focusRecherche.hasFocus) selection.value = null;
  }

  // =====================================================================
  //  SÉLECTION ET NAVIGATION
  // =====================================================================

  /// Affiche l'aperçu d'un signalement et centre la carte dessus.
  /// [zoomer] = false → on garde le zoom actuel (cas d'un appui sur l'épingle).
  void selectionner(Signalement signalement, {bool zoomer = true}) {
    fermerRecherche();
    // Le filtre actuel cacherait ce signalement (ex : il vient de la
    // recherche) → retour sur "Tout" pour qu'il reste visible.
    if (!filtre.value.correspond(signalement)) reinitialiserFiltres();
    selection.value = signalement;
    final zoom = zoomer ? math.max(_zoomActuel, zoomSignalement) : _zoomActuel;
    _deplacerCarte(signalement.coordonnees, zoom);
  }

  /// Appui sur une épingle (on retrouve le signalement grâce à sa clé).
  void selectionnerParId(int id) {
    for (final signalement in signalements) {
      if (signalement.id == id) {
        selectionner(signalement, zoomer: false);
        return;
      }
    }
  }

  void deselectionner() => selection.value = null;

  /// Appui sur une zone vide de la carte.
  void toucherCarte() {
    if (rechercheOuverte.value) {
      fermerRecherche();
    } else {
      deselectionner();
    }
  }

  /// Bouton retour d'Android : ferme d'abord la recherche, puis l'aperçu.
  void gererRetour() {
    if (rechercheOuverte.value) {
      fermerRecherche();
    } else if (selection.value != null) {
      deselectionner();
    }
  }

  void ouvrirDetail(Signalement signalement) {
    // `arguments` : le détail s'affiche instantanément avec ces données,
    // puis se met à jour depuis l'API.
    Get.toNamed<void>(
      AppRoutes.versDetail(signalement.id),
      arguments: signalement,
    );
  }

  // =====================================================================
  //  LOCALISATION
  // =====================================================================

  Future<void> autourDeMoi() async {
    if (localisationEnCours.value) return; // évite les doubles appuis
    localisationEnCours.value = true;
    try {
      final position = await _localisation.obtenirPositionActuelle();
      positionUtilisateur.value = position;
      unawaited(_stockage.enregistrerDernierePosition(position));
      _deplacerCarte(position, zoomPosition);

      final proches = signalements
          .where(
            (s) => s.coordonnees.distanceEnMetres(position) <= rayonAutourDeMoi,
          )
          .length;
      Notifications.info(switch (proches) {
        0 => 'Aucun signalement à moins de 500 m.',
        1 => '1 signalement à moins de 500 m.',
        final n => '$n signalements à moins de 500 m.',
      });
    } on LocalisationException catch (e) {
      Notifications.erreur(
        e.message,
        libelleAction: e.necessiteParametres ? 'Paramètres' : null,
        onAction: e.necessiteParametres
            ? () => _localisation.ouvrirParametres(e)
            : null,
      );
    } finally {
      localisationEnCours.value = false;
    }
  }

  /// Au démarrage : point bleu seulement si l'utilisateur a DÉJÀ autorisé
  /// (on ne lui demande rien tant qu'il n'a pas touché "Autour de moi").
  Future<void> _afficherPositionSiDejaAutorise() async {
    if (!await _localisation.estDejaAutorise()) return;
    try {
      final position = await _localisation.obtenirPositionActuelle();
      if (isClosed) return; // l'écran a été quitté entre-temps
      positionUtilisateur.value = position;
      unawaited(_stockage.enregistrerDernierePosition(position));
    } on LocalisationException {
      // Silencieux : ce n'est qu'un bonus au démarrage.
    }
  }

  // =====================================================================
  //  CARTE
  // =====================================================================

  /// Appelé par la carte quand elle est prête (avant, on ne peut pas la déplacer).
  void carteEstPrete() => _carteEstPrete = true;

  double get _zoomActuel => _carteEstPrete ? carte.camera.zoom : zoomInitial;

  void _deplacerCarte(Coordonnees position, double zoom) {
    if (!_carteEstPrete) return;
    carte.move(LatLng(position.latitude, position.longitude), zoom);
  }
}

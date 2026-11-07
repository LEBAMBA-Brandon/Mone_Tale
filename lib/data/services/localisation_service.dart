import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tala/data/models/coordonnees.dart';
import 'package:tala/data/models/position_gps.dart';

/// Les raisons pour lesquelles on peut ne pas obtenir la position.
enum TypeErreurLocalisation {
  serviceDesactive, // le GPS du téléphone est éteint
  permissionRefusee, // l'utilisateur a dit "Non" (on pourra redemander)
  permissionRefuseeDefinitivement, // "Ne plus demander" → paramètres obligatoires
  delaiDepasse, // pas de signal GPS à temps
  inconnue,
}

/// Erreur de localisation avec un message en français prêt à afficher.
class LocalisationException implements Exception {
  const LocalisationException(this.type, this.message);

  final TypeErreurLocalisation type;
  final String message;

  /// `true` si l'utilisateur doit aller dans les paramètres pour régler
  /// le problème (au J3 : afficher un bouton "Ouvrir les paramètres").
  /// Dans tous les cas, le collecteur peut aussi placer le point à la main
  /// sur la petite carte.
  bool get necessiteParametres =>
      type == TypeErreurLocalisation.serviceDesactive ||
      type == TypeErreurLocalisation.permissionRefuseeDefinitivement;

  @override
  String toString() => 'LocalisationException($type) : $message';
}

/// Récupère la position GPS du collecteur pour placer le signalement.
///
/// Pas de repository pour la localisation : il n'y a qu'une seule source
/// (le GPS) et rien à combiner ni à mettre en cache. Le controller
/// pourra utiliser ce service directement.
class LocalisationService {
  /// Temps max d'attente du GPS.
  static const Duration _delaiMax = Duration(seconds: 15);

  /// Renvoie la position actuelle AVEC sa précision,
  /// ou lève une [LocalisationException].
  Future<PositionGps> obtenirPositionActuelle() async {
    await _verifierAutorisations();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, // signalement = position précise
          timeLimit: _delaiMax,
        ),
      );
      return _versPositionGps(position);
    } on TimeoutException {
      // Pas de signal à temps : on tente la dernière position connue.
      final derniere = await _derniereConnue();
      if (derniere != null) return derniere;
      throw const LocalisationException(
        TypeErreurLocalisation.delaiDepasse,
        "Impossible d'obtenir votre position. Placez-vous à découvert, "
        'ou placez le point vous-même sur la carte.',
      );
    } on LocationServiceDisabledException {
      throw const LocalisationException(
        TypeErreurLocalisation.serviceDesactive,
        'La localisation est désactivée. Activez-la dans les paramètres du téléphone.',
      );
    } on PermissionDeniedException {
      throw const LocalisationException(
        TypeErreurLocalisation.permissionRefusee,
        "Autorisez l'accès à votre position pour localiser le signalement.",
      );
    } catch (erreur) {
      debugPrint('Erreur de localisation : $erreur');
      throw const LocalisationException(
        TypeErreurLocalisation.inconnue,
        "Votre position n'a pas pu être déterminée.",
      );
    }
  }

  /// `true` si la permission est DÉJÀ accordée et le GPS allumé.
  /// Ne demande RIEN à l'utilisateur (aucune fenêtre ne s'affiche).
  /// Sert à lancer le GPS dès l'ouverture du formulaire, sans fenêtre surprise.
  Future<bool> estDejaAutorise() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Ouvre le bon écran de paramètres selon l'erreur rencontrée.
  Future<bool> ouvrirParametres(LocalisationException erreur) {
    if (erreur.type == TypeErreurLocalisation.serviceDesactive) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }

  /// Vérifie que le GPS est allumé et que l'app a la permission.
  /// Demande la permission si elle n'a pas encore été donnée.
  Future<void> _verifierAutorisations() async {
    final serviceActif = await Geolocator.isLocationServiceEnabled();
    if (!serviceActif) {
      throw const LocalisationException(
        TypeErreurLocalisation.serviceDesactive,
        'La localisation est désactivée. Activez-la dans les paramètres du téléphone.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        throw const LocalisationException(
          TypeErreurLocalisation.permissionRefusee,
          "Autorisez l'accès à votre position pour localiser le signalement.",
        );
      case LocationPermission.deniedForever:
        throw const LocalisationException(
          TypeErreurLocalisation.permissionRefuseeDefinitivement,
          "L'accès à votre position est bloqué. Autorisez-le dans les paramètres de l'application.",
        );
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return; // tout est bon
    }
  }

  /// Dernière position connue du téléphone (pas disponible sur le web).
  /// Souvent moins précise : la précision renvoyée le dira, et
  /// l'interface proposera d'ajuster le point.
  Future<PositionGps?> _derniereConnue() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return _versPositionGps(position);
    } catch (_) {
      return null;
    }
  }

  /// Convertit la position de geolocator en NOTRE modèle
  /// (la couche data ne dépend pas des classes de geolocator).
  PositionGps _versPositionGps(Position position) => PositionGps(
    coordonnees: Coordonnees(
      latitude: position.latitude,
      longitude: position.longitude,
    ),
    precisionMetres: position.accuracy,
  );
}

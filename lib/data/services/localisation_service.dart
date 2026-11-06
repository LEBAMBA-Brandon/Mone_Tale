import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mono/data/models/coordonnees.dart';

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
  bool get necessiteParametres =>
      type == TypeErreurLocalisation.serviceDesactive ||
      type == TypeErreurLocalisation.permissionRefuseeDefinitivement;

  @override
  String toString() => 'LocalisationException($type) : $message';
}

/// Récupère la position GPS de l'utilisateur (bouton "Autour de moi").
///
/// Pas de repository pour la localisation : il n'y a qu'une seule source
/// (le GPS) et rien à combiner ni à mettre en cache. Le controller
/// pourra utiliser ce service directement.
class LocalisationService {
  /// Temps max d'attente du GPS.
  static const Duration _delaiMax = Duration(seconds: 15);

  /// Renvoie la position actuelle, ou lève une [LocalisationException].
  Future<Coordonnees> obtenirPositionActuelle() async {
    await _verifierAutorisations();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _delaiMax,
        ),
      );
      return Coordonnees(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      // Pas de signal à temps : on tente la dernière position connue.
      final derniere = await _derniereConnue();
      if (derniere != null) return derniere;
      throw const LocalisationException(
        TypeErreurLocalisation.delaiDepasse,
        "Impossible d'obtenir votre position. Placez-vous à découvert et réessayez.",
      );
    } on LocationServiceDisabledException {
      throw const LocalisationException(
        TypeErreurLocalisation.serviceDesactive,
        'La localisation est désactivée. Activez-la dans les paramètres du téléphone.',
      );
    } on PermissionDeniedException {
      throw const LocalisationException(
        TypeErreurLocalisation.permissionRefusee,
        'Autorisez l\'accès à votre position pour utiliser « Autour de moi ».',
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
  /// Sert à afficher le point bleu au démarrage sans déranger.
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
          'Autorisez l\'accès à votre position pour utiliser « Autour de moi ».',
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
  Future<Coordonnees?> _derniereConnue() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return Coordonnees(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}

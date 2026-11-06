import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mono/core/theme/app_dimensions.dart';
import 'package:mono/core/theme/couleurs_mono.dart';

enum _TypeNotification { succes, erreur, info }

/// Messages temporaires en bas de l'écran (snackbars GetX).
///
/// Utilisable PARTOUT, même dans un controller (pas besoin de `context`) :
/// ```dart
/// Notifications.erreur(erreur.message, libelleAction: 'Réessayer', onAction: charger);
/// Notifications.succes('Signalement envoyé');
/// Notifications.info('Vous êtes hors ligne : données en cache.');
/// ```
/// Un seul message à la fois : le précédent est fermé avant d'afficher le suivant.
abstract final class Notifications {
  static void succes(String message, {String? titre}) =>
      _afficher(_TypeNotification.succes, message, titre: titre);

  static void erreur(
    String message, {
    String? titre,
    String? libelleAction,
    VoidCallback? onAction,
  }) => _afficher(
    _TypeNotification.erreur,
    message,
    titre: titre,
    libelleAction: libelleAction,
    onAction: onAction,
  );

  static void info(String message, {String? titre}) =>
      _afficher(_TypeNotification.info, message, titre: titre);

  static void _afficher(
    _TypeNotification type,
    String message, {
    String? titre,
    String? libelleAction,
    VoidCallback? onAction,
  }) {
    if (Get.isSnackbarOpen) unawaited(Get.closeCurrentSnackbar());

    // Get.theme = le thème actuel (clair ou sombre), sans avoir de context.
    final theme = Get.theme;
    final schema = theme.colorScheme;
    final couleurs = theme.extension<CouleursMono>();

    final (fond, texte, icone) = switch (type) {
      _TypeNotification.succes => (
        couleurs?.succes ?? schema.primary,
        couleurs?.surSucces ?? schema.onPrimary,
        Icons.check_circle_outline,
      ),
      _TypeNotification.erreur => (
        schema.error,
        schema.onError,
        Icons.error_outline,
      ),
      _TypeNotification.info => (
        schema.inverseSurface,
        schema.onInverseSurface,
        Icons.info_outline,
      ),
    };

    Get.showSnackbar(
      GetSnackBar(
        titleText: titre == null
            ? null
            : Text(
                titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: texte, fontWeight: FontWeight.w700),
              ),
        messageText: Text(
          message,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: texte),
        ),
        icon: Icon(icone, color: texte),
        shouldIconPulse: false,
        backgroundColor: fond,
        borderRadius: AppRayons.m,
        margin: const EdgeInsets.all(AppEspacements.m),
        // Sur tablette, la notification ne prend pas toute la largeur.
        maxWidth: 560,
        snackPosition: SnackPosition.BOTTOM,
        isDismissible: true,
        // Une erreur reste un peu plus longtemps (le temps de la lire).
        duration: type == _TypeNotification.erreur
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3),
        mainButton: (libelleAction != null && onAction != null)
            ? TextButton(
                onPressed: () {
                  unawaited(Get.closeCurrentSnackbar());
                  onAction();
                },
                child: Text(
                  libelleAction,
                  style: TextStyle(color: texte, fontWeight: FontWeight.w700),
                ),
              )
            : null,
      ),
    );
  }
}

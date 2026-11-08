import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tala/core/theme/couleurs_tala.dart';

/// Fenêtre "Êtes-vous sûr ?" avant une action importante
/// (supprimer, se déconnecter…).
///
/// Utilisable PARTOUT, même dans un controller (pas besoin de context) :
/// ```dart
/// if (await DialogueConfirmation.demander(
///   titre: 'Supprimer ce signalement ?',
///   message: 'La photo sera aussi supprimée. Cette action est définitive.',
///   libelleConfirmer: 'Supprimer',
///   danger: true,
/// )) { ... }
/// ```
/// Renvoie `true` seulement si l'utilisateur confirme.
/// Toucher à côté ou "Annuler" → `false`.
class DialogueConfirmation extends StatelessWidget {
  const DialogueConfirmation({
    super.key,
    required this.titre,
    required this.message,
    this.libelleConfirmer = 'Confirmer',
    this.libelleAnnuler = 'Annuler',
    this.danger = false,
  });

  final String titre;
  final String message;
  final String libelleConfirmer;
  final String libelleAnnuler;

  /// `true` → bouton de confirmation ROUGE (action destructrice).
  final bool danger;

  static Future<bool> demander({
    required String titre,
    required String message,
    String libelleConfirmer = 'Confirmer',
    String libelleAnnuler = 'Annuler',
    bool danger = false,
  }) async {
    final reponse = await Get.dialog<bool>(
      DialogueConfirmation(
        titre: titre,
        message: message,
        libelleConfirmer: libelleConfirmer,
        libelleAnnuler: libelleAnnuler,
        danger: danger,
      ),
    );
    // `null` si l'utilisateur a fermé la fenêtre sans choisir.
    return reponse ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final schema = context.schema;
    return AlertDialog(
      title: Text(titre),
      // Scrollable : un long message ne déborde pas sur un petit écran.
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Get.back<bool>(result: false),
          child: Text(libelleAnnuler),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: schema.error,
                  foregroundColor: schema.onError,
                )
              : null,
          onPressed: () => Get.back<bool>(result: true),
          child: Text(libelleConfirmer),
        ),
      ],
    );
  }
}

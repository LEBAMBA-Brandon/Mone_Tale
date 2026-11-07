import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Se souvient des dernières valeurs saisies, avec **SharedPreferences**,
/// pour faire gagner du temps sur le terrain :
/// - le dernier e-mail utilisé → pré-rempli à l'écran de connexion ;
/// - le dernier quartier choisi → pré-sélectionné dans "Ajouter un
///   signalement" (un collecteur travaille souvent dans le même quartier).
///
/// Le sujet veut un signalement créé « en moins d'une minute » :
/// chaque champ déjà rempli compte.
///
/// Ce sont des données "de confort" : si la lecture échoue, on renvoie
/// `null` et l'app continue normalement.
class PreferencesFormulaireService {
  static const String _cleEmail = 'tala.dernier_email';
  static const String _cleQuartier = 'tala.dernier_quartier_id';

  SharedPreferences? _prefs;

  /// Ouvre la mémoire une seule fois, puis réutilise la même instance.
  Future<SharedPreferences> _obtenirPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ---------- Dernier e-mail ----------

  Future<String?> lireDernierEmail() async {
    try {
      return (await _obtenirPrefs()).getString(_cleEmail);
    } catch (erreur) {
      debugPrint('Lecture du dernier e-mail impossible : $erreur');
      return null;
    }
  }

  Future<void> enregistrerDernierEmail(String email) async {
    try {
      await (await _obtenirPrefs()).setString(_cleEmail, email.trim());
    } catch (erreur) {
      debugPrint('Sauvegarde du dernier e-mail impossible : $erreur');
    }
  }

  // ---------- Dernier quartier ----------

  Future<int?> lireDernierQuartierId() async {
    try {
      return (await _obtenirPrefs()).getInt(_cleQuartier);
    } catch (erreur) {
      debugPrint('Lecture du dernier quartier impossible : $erreur');
      return null;
    }
  }

  Future<void> enregistrerDernierQuartierId(int id) async {
    try {
      await (await _obtenirPrefs()).setInt(_cleQuartier, id);
    } catch (erreur) {
      debugPrint('Sauvegarde du dernier quartier impossible : $erreur');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enregistre les recherches récentes dans la mémoire du téléphone
/// (elles restent après la fermeture de l'app).
///
/// C'est une fonctionnalité "de confort" : si la lecture ou l'écriture
/// échoue, on ne bloque JAMAIS l'app, on renvoie simplement une liste vide.
class RechercheRecenteService {
  RechercheRecenteService({this.nombreMax = 8});

  /// Clé sous laquelle la liste est rangée dans le téléphone.
  static const String _cle = 'mono.recherches_recentes';

  /// Nombre maximum de recherches gardées (les plus anciennes sont supprimées).
  final int nombreMax;

  SharedPreferences? _prefs;

  /// Ouvre la mémoire une seule fois, puis réutilise la même instance.
  Future<SharedPreferences> _obtenirPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Recherches récentes, de la plus récente à la plus ancienne.
  Future<List<String>> lire() async {
    try {
      final prefs = await _obtenirPrefs();
      return prefs.getStringList(_cle) ?? const [];
    } catch (erreur) {
      debugPrint('Lecture des recherches récentes impossible : $erreur');
      return const [];
    }
  }

  /// Ajoute une recherche en tête de liste et renvoie la nouvelle liste.
  /// - Les espaces en trop sont nettoyés.
  /// - Moins de 2 caractères → ignoré.
  /// - Si elle existe déjà (même sans tenir compte des majuscules),
  ///   elle remonte en tête au lieu d'être dupliquée.
  Future<List<String>> ajouter(String terme) async {
    final propre = terme.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (propre.length < 2) return lire();

    final liste = List<String>.of(await lire());
    liste.removeWhere(
      (recherche) => recherche.toLowerCase() == propre.toLowerCase(),
    );
    liste.insert(0, propre);

    final limitee = liste.take(nombreMax).toList();
    await _sauvegarder(limitee);
    return limitee;
  }

  /// Supprime une recherche précise et renvoie la nouvelle liste.
  Future<List<String>> supprimer(String terme) async {
    final liste = List<String>.of(await lire());
    liste.removeWhere(
      (recherche) => recherche.toLowerCase() == terme.trim().toLowerCase(),
    );
    await _sauvegarder(liste);
    return liste;
  }

  /// Efface tout l'historique.
  Future<void> toutEffacer() => _sauvegarder(const []);

  Future<void> _sauvegarder(List<String> liste) async {
    try {
      final prefs = await _obtenirPrefs();
      await prefs.setStringList(_cle, liste);
    } catch (erreur) {
      debugPrint('Sauvegarde des recherches récentes impossible : $erreur');
    }
  }
}

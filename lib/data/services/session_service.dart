import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tala/data/models/json_parser.dart';
import 'package:tala/data/models/session.dart';

/// Garde la session (token + profil) dans le téléphone avec **GetStorage**,
/// pour ne pas redemander le mot de passe à chaque ouverture de l'app.
///
/// Pourquoi GetStorage et pas SharedPreferences ici ?
/// La lecture est SYNCHRONE. Au J2, le middleware GetX (`redirect`) doit
/// décider TOUT DE SUITE, sans `await`, si on ouvre l'écran de connexion
/// ou l'accueil : il ne peut pas attendre une lecture asynchrone.
///
/// 🔒 Sécurité : GetStorage n'est pas chiffré. Pour un projet d'école c'est
/// acceptable (le fichier est dans le dossier privé de l'app). En
/// production, on utiliserait `flutter_secure_storage` (Keystore Android).
class SessionService {
  SessionService({GetStorage? boite}) : _boite = boite ?? GetStorage();

  final GetStorage _boite;

  static const String _cle = 'tala.session';

  /// Session enregistrée, ou `null` si personne n'est connecté
  /// (ou si les données sont abîmées).
  Session? lireSession() {
    try {
      final json = JsonParser.lireMap(_boite.read<Object?>(_cle));
      if (json == null) return null;
      final session = Session.fromJson(json);
      return session.estValide ? session : null;
    } catch (erreur) {
      debugPrint('Session illisible : $erreur');
      return null;
    }
  }

  Future<void> enregistrerSession(Session session) async {
    try {
      await _boite.write(_cle, session.toJson());
    } catch (erreur) {
      debugPrint('Session non enregistrée : $erreur');
    }
  }

  Future<void> effacerSession() async {
    try {
      await _boite.remove(_cle);
    } catch (erreur) {
      debugPrint('Session non effacée : $erreur');
    }
  }
}

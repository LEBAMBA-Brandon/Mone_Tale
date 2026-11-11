import 'package:tala/data/models/role.dart';

/// Règles communes aux formulaires de compte (ajout et modification).
/// Ce sont les mêmes que celles de l'API (UserController::store).
abstract final class ReglesCompte {
  static const int longueurMaxNom = 100;
  static const int longueurMinMotDePasse = 6;

  static final RegExp _formatEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? verifierNom(String valeur, String libelle) {
    final texte = valeur.trim();
    if (texte.isEmpty) return '$libelle obligatoire.';
    if (texte.length > longueurMaxNom) {
      return '$libelle trop long ($longueurMaxNom caractères maximum).';
    }
    return null;
  }

  static String? verifierEmail(String valeur) {
    final texte = valeur.trim();
    if (texte.isEmpty) return 'E-mail obligatoire.';
    if (!_formatEmail.hasMatch(texte)) return 'E-mail invalide.';
    return null;
  }

  static String? verifierMotDePasse(String valeur) {
    if (valeur.isEmpty) return 'Mot de passe obligatoire.';
    if (valeur.length < longueurMinMotDePasse) {
      return 'Au moins $longueurMinMotDePasse caractères.';
    }
    return null;
  }
}

/// Le formulaire "Ajouter un collecteur" (écran admin).
///
/// Les clés des erreurs ("nom", "prenom", "email", "password") sont celles
/// de l'API : une erreur 422 du serveur (ex : "email déjà utilisé")
/// s'affiche au même endroit qu'une erreur détectée sur le téléphone.
class NouveauCollecteur {
  const NouveauCollecteur({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
  });

  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;

  /// `champ → message`. Map vide = prêt à envoyer.
  Map<String, String> valider() => {
    // `'nom': ?valeur` : l'entrée n'est ajoutée QUE si valeur n'est pas null.
    'nom': ?ReglesCompte.verifierNom(nom, 'Nom'),
    'prenom': ?ReglesCompte.verifierNom(prenom, 'Prénom'),
    'email': ?ReglesCompte.verifierEmail(email),
    'password': ?ReglesCompte.verifierMotDePasse(motDePasse),
  };

  /// Corps JSON de `POST /api/users`.
  /// Le rôle est FORCÉ à "collecteur" : cet écran ne crée pas d'admin.
  Map<String, dynamic> versJson() => {
    'nom': nom.trim(),
    'prenom': prenom.trim(),
    'email': email.trim().toLowerCase(),
    'password': motDePasse, // jamais de trim sur un mot de passe
    'role': Role.collecteur.valeurApi,
  };
}

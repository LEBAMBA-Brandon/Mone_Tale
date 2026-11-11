import 'package:tala/data/models/nouveau_collecteur.dart';

/// Les changements demandés sur un compte (écran "Mon compte" de l'admin).
///
/// Chaque champ est FACULTATIF : `null` = "ne pas changer".
/// On n'envoie à l'API que ce qui a changé (`PATCH /api/users/{id}` accepte
/// des champs partiels grâce à la règle "sometimes" côté Laravel).
class ModificationCompte {
  const ModificationCompte({
    this.nom,
    this.prenom,
    this.email,
    this.motDePasse,
  });

  final String? nom;
  final String? prenom;
  final String? email;
  final String? motDePasse;

  /// `true` si rien n'a été changé (inutile d'appeler l'API).
  bool get estVide =>
      nom == null && prenom == null && email == null && motDePasse == null;

  /// Vérifie SEULEMENT les champs modifiés. Map vide = prêt à envoyer.
  Map<String, String> valider() {
    final nom = this.nom;
    final prenom = this.prenom;
    final email = this.email;
    final motDePasse = this.motDePasse;
    return {
      if (nom != null) 'nom': ?ReglesCompte.verifierNom(nom, 'Nom'),
      if (prenom != null) 'prenom': ?ReglesCompte.verifierNom(prenom, 'Prénom'),
      if (email != null) 'email': ?ReglesCompte.verifierEmail(email),
      if (motDePasse != null)
        'password': ?ReglesCompte.verifierMotDePasse(motDePasse),
    };
  }

  /// Corps JSON : uniquement les champs renseignés.
  Map<String, dynamic> versJson() => {
    if (nom != null) 'nom': nom!.trim(),
    if (prenom != null) 'prenom': prenom!.trim(),
    if (email != null) 'email': email!.trim().toLowerCase(),
    if (motDePasse != null) 'password': motDePasse,
  };
}

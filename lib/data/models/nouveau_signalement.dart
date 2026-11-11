import 'package:tala/data/models/categorie.dart';
import 'package:tala/data/models/coordonnees.dart';
import 'package:tala/data/models/gravite.dart';
import 'package:tala/data/models/photo_signalement.dart';
import 'package:tala/data/models/quartier.dart';

/// Le signalement EN COURS DE SAISIE dans le formulaire "Ajouter un
/// signalement" (pas encore envoyé, donc pas d'id ni de statut).
///
/// Tous les champs sont facultatifs pendant la saisie : [valider] dit ce
/// qui manque encore avant l'envoi.
///
/// Les clés des erreurs ("photo", "categorie", "quartier_id"…) sont les
/// MÊMES que celles de l'API Laravel. Une erreur détectée sur le téléphone
/// et une erreur 422 renvoyée par le serveur s'affichent donc au même
/// endroit dans le formulaire.
class NouveauSignalement {
  const NouveauSignalement({
    this.position,
    this.categorie,
    this.gravite,
    this.quartier,
    this.description = '',
    this.photo,
  });

  /// Longueur max de la description (`max:200` dans StoreSignalementRequest).
  static const int longueurMaxDescription = 200;

  /// Formulaire vide (au départ).
  static const NouveauSignalement vide = NouveauSignalement();

  final Coordonnees? position;
  final Categorie? categorie;
  final Gravite? gravite;
  final Quartier? quartier;
  final String description;
  final PhotoSignalement? photo;

  /// Vérifie le formulaire AVANT l'envoi (évite un aller-retour réseau
  /// pour une erreur évidente). Renvoie `champ → message`.
  /// Map vide = tout est bon.
  Map<String, String> valider() => {
    'photo': ?_erreurPhoto(),
    'latitude': ?_erreurPosition(),
    if (categorie == null) 'categorie': 'Choisissez une catégorie.',
    if (gravite == null) 'gravite': 'Choisissez une gravité.',
    if (quartier == null) 'quartier_id': 'Choisissez un quartier.',
    'description': ?_erreurDescription(),
  };

  // `'photo': ?_erreurPhoto()` : le `?` devant la valeur veut dire
  // "ajoute cette entrée SEULEMENT si la valeur n'est pas null".
  // Pas d'erreur → pas de clé "photo" dans la Map.

  // `if (x case final erreur?)` : "s'il y a une erreur (pas null), appelle-la
  // erreur et ajoute-la". Une seule ligne par champ, une seule clé.

  String? _erreurPhoto() {
    final photo = this.photo;
    if (photo == null) return 'Prenez une photo du problème.';
    if (photo.estTropLourde) {
      return 'La photo est trop lourde (${photo.tailleLisible}, 1 Mo maximum). '
          'Reprenez-la.';
    }
    return null;
  }

  String? _erreurPosition() {
    final position = this.position;
    if (position == null || !position.estValide) {
      return 'Position introuvable : activez le GPS ou placez le point sur la carte.';
    }
    return null;
  }

  String? _erreurDescription() {
    final texte = description.trim();
    if (texte.isEmpty) return 'Décrivez le problème en quelques mots.';
    if (texte.length > longueurMaxDescription) {
      return 'Description trop longue '
          '(${texte.length}/$longueurMaxDescription caractères).';
    }
    return null;
  }

  bool get estPret => valider().isEmpty;

  /// Champs TEXTE à envoyer à `POST /api/signalements`
  /// (la photo part à part, comme fichier).
  ///
  /// ⚠️ À appeler seulement si [estPret] est vrai : sinon un `!` plantera.
  /// Le repository vérifie avant d'appeler.
  Map<String, String> versChamps() => {
    // 7 décimales ≈ 1 cm de précision : largement suffisant.
    'latitude': position!.latitude.toStringAsFixed(7),
    'longitude': position!.longitude.toStringAsFixed(7),
    'categorie': categorie!.valeurApi,
    'gravite': gravite!.valeurApi,
    'quartier_id': quartier!.id.toString(),
    'description': description.trim(),
  };

  /// Copie en changeant certains champs.
  ///
  /// Comme dans SignalementFiltre, chaque paramètre est une FONCTION,
  /// pour pouvoir aussi remettre un champ à `null` :
  /// - `brouillon.copyWith(photo: () => nouvellePhoto)` → change la photo
  /// - `brouillon.copyWith(photo: () => null)` → retire la photo
  NouveauSignalement copyWith({
    Coordonnees? Function()? position,
    Categorie? Function()? categorie,
    Gravite? Function()? gravite,
    Quartier? Function()? quartier,
    String? description,
    PhotoSignalement? Function()? photo,
  }) {
    return NouveauSignalement(
      position: position != null ? position() : this.position,
      categorie: categorie != null ? categorie() : this.categorie,
      gravite: gravite != null ? gravite() : this.gravite,
      quartier: quartier != null ? quartier() : this.quartier,
      description: description ?? this.description,
      photo: photo != null ? photo() : this.photo,
    );
  }
}

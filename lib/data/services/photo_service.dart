import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tala/data/models/photo_signalement.dart';

/// Les raisons pour lesquelles on peut ne pas obtenir de photo.
enum TypeErreurPhoto {
  permissionRefusee, // l'utilisateur a refusé l'accès à l'appareil photo
  tropLourde, // même compressée, la photo dépasse 1 Mo
  inconnue,
}

/// Erreur de photo avec un message en français prêt à afficher.
class PhotoException implements Exception {
  const PhotoException(this.type, this.message);

  final TypeErreurPhoto type;
  final String message;

  @override
  String toString() => 'PhotoException($type) : $message';
}

/// Prend la photo du signalement avec l'appareil du téléphone.
///
/// La COMPRESSION se fait ici, au moment de la prise :
/// - [_largeurMax] : une photo de 4000 px est réduite à 1600 px ;
/// - [_qualite] : JPEG à 70 % (invisible à l'œil sur un téléphone).
/// Résultat : quelques centaines de Ko au lieu de 3 à 8 Mo, donc sous la
/// limite de 1 Mo de l'API, et un envoi rapide même en 3G.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _largeurMax = 1600;
  static const int _qualite = 70;

  /// Ouvre l'appareil photo (caméra arrière).
  /// Renvoie `null` si l'utilisateur annule (ce n'est pas une erreur).
  Future<PhotoSignalement?> prendrePhoto() =>
      _choisir(ImageSource.camera);

  /// Choisit une photo dans la galerie.
  /// Pratique sur l'émulateur, qui n'a pas de vraie caméra.
  Future<PhotoSignalement?> choisirDansGalerie() =>
      _choisir(ImageSource.gallery);

  /// Android peut FERMER l'app pendant que l'appareil photo est ouvert
  /// (téléphone avec peu de mémoire). Au retour, la photo n'est pas
  /// perdue : on la récupère ici. À appeler au démarrage de l'écran
  /// "Ajouter un signalement" (dans onInit du controller, au J2).
  Future<PhotoSignalement?> recupererPhotoPerdue() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final reponse = await _picker.retrieveLostData();
      final fichier = reponse.file;
      if (reponse.isEmpty || fichier == null) return null;
      return _versPhoto(fichier);
    } catch (erreur) {
      debugPrint('Récupération de photo impossible : $erreur');
      return null;
    }
  }

  Future<PhotoSignalement?> _choisir(ImageSource source) async {
    final XFile? fichier;
    try {
      fichier = await _picker.pickImage(
        source: source,
        maxWidth: _largeurMax,
        maxHeight: _largeurMax,
        imageQuality: _qualite,
        preferredCameraDevice: CameraDevice.rear,
      );
    } on PlatformException catch (erreur) {
      debugPrint('Appareil photo : ${erreur.code} ${erreur.message}');
      throw PhotoException(
        erreur.code.contains('access_denied')
            ? TypeErreurPhoto.permissionRefusee
            : TypeErreurPhoto.inconnue,
        erreur.code.contains('access_denied')
            ? "Autorisez l'accès à l'appareil photo dans les paramètres du téléphone."
            : "Impossible d'ouvrir l'appareil photo.",
      );
    }

    if (fichier == null) return null; // l'utilisateur a annulé
    return _versPhoto(fichier);
  }

  /// Mesure le fichier et vérifie la limite de 1 Mo.
  Future<PhotoSignalement> _versPhoto(XFile fichier) async {
    final int taille;
    try {
      taille = await fichier.length();
    } catch (erreur) {
      debugPrint('Photo illisible : $erreur');
      throw const PhotoException(
        TypeErreurPhoto.inconnue,
        'La photo est illisible. Reprenez-la.',
      );
    }

    final photo = PhotoSignalement(chemin: fichier.path, tailleOctets: taille);
    if (photo.estTropLourde) {
      throw PhotoException(
        TypeErreurPhoto.tropLourde,
        'Photo trop lourde (${photo.tailleLisible}, 1 Mo maximum). '
        'Reprenez-la de plus loin ou avec moins de détails.',
      );
    }
    return photo;
  }
}

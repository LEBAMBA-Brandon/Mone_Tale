import 'package:tala/core/theme/app_infos.dart';

/// Une partie d'une page d'information : un titre + des paragraphes.
class SectionTexte {
  const SectionTexte(this.titre, this.paragraphes);

  final String titre;
  final List<String> paragraphes;
}

/// Contenu des pages Aide, Conditions d'utilisation et Politique de
/// confidentialité.
///
/// ⚠️ Les conditions et la politique de confidentialité sont des MODÈLES
/// rédigés pour le projet : à faire relire et valider par BI-TECH Services
/// avant une vraie mise en service.
abstract final class TextesInfo {
  static const String miseAJour = 'novembre 2026';

  static List<SectionTexte> pour(PageInfo page) => switch (page) {
    PageInfo.aide => aide,
    PageInfo.conditions => conditions,
    PageInfo.confidentialite => confidentialite,
  };

  // =====================================================================
  //  AIDE
  // =====================================================================

  static const List<SectionTexte> aide = [
    SectionTexte('Ajouter un signalement', [
      '1. Ouvrez l’onglet « Ajouter » et prenez une photo du problème.',
      '2. Votre position GPS est trouvée automatiquement. Vérifiez-la sur '
          'la petite carte.',
      '3. Choisissez la catégorie, la gravité et le quartier, puis décrivez '
          'le problème en quelques mots (200 caractères maximum).',
      '4. Appuyez sur « Envoyer ». Le signalement apparaît dans « Mes '
          'signalements ».',
    ]),
    SectionTexte('La position est fausse ou imprécise', [
      'Si le message « Position approximative » s’affiche, appuyez sur '
          '« Ajuster sur la carte » et faites glisser la carte pour placer la '
          'pointe de l’épingle exactement sur le problème.',
      'À l’intérieur d’un bâtiment, le GPS est moins précis : sortez à '
          'découvert puis appuyez sur « GPS » pour réessayer.',
    ]),
    SectionTexte('La photo est refusée', [
      'Une photo ne doit pas dépasser 1 Mo. L’application la réduit '
          'automatiquement ; si elle reste trop lourde, reprenez-la.',
      'Si l’appareil photo ne s’ouvre pas, autorisez l’accès à la caméra '
          'dans les paramètres du téléphone.',
    ]),
    SectionTexte('Pas de connexion internet', [
      'Si l’envoi échoue, votre signalement n’est pas perdu : il reste '
          'dans le formulaire. Appuyez sur « Réessayer » quand le réseau revient.',
    ]),
    SectionTexte('Que veulent dire les statuts ?', [
      'Signalé : le problème a été enregistré.',
      'En cours : les services s’en occupent.',
      'Résolu : le problème a été réglé.',
    ]),
    SectionTexte('Mot de passe oublié', [
      'Contactez votre administrateur : il peut vous donner un nouveau '
          'mot de passe. Vous pourrez ensuite le changer dans Profil → '
          '« Modifier mes informations ».',
    ]),
  ];

  // =====================================================================
  //  CONDITIONS D'UTILISATION (modèle)
  // =====================================================================

  static const List<SectionTexte> conditions = [
    SectionTexte('1. Objet', [
      '${AppInfos.nom} permet aux collecteurs désignés de signaler les '
          'problèmes urbains (voirie, ordures, éclairage public, caniveaux…) '
          'et aux administrateurs de suivre leur traitement.',
    ]),
    SectionTexte('2. Accès au service', [
      'Les comptes sont créés par un administrateur. Vos identifiants sont '
          'personnels : ne les communiquez à personne.',
      'Vous êtes responsable de ce qui est fait avec votre compte. En cas '
          'de perte de votre téléphone, prévenez votre administrateur.',
    ]),
    SectionTexte('3. Vos engagements', [
      'Signaler uniquement des problèmes réels, constatés sur place, avec '
          'une description exacte.',
      'Ne pas photographier de personnes reconnaissables ni de plaques '
          'd’immatriculation lisibles.',
      'Ne publier aucun contenu injurieux, discriminatoire ou sans rapport '
          'avec le service.',
    ]),
    SectionTexte('4. Publication des signalements', [
      'Les signalements (photo, position, catégorie, gravité, description, '
          'date, statut, ainsi que le nom et le prénom de leur auteur) sont '
          'visibles publiquement dans l’application de consultation destinée '
          'aux habitants.',
    ]),
    SectionTexte('5. Suspension du compte', [
      'Un administrateur peut supprimer un signalement ou désactiver un '
          'compte en cas de non-respect de ces conditions.',
    ]),
    SectionTexte('6. Modification des conditions', [
      'Ces conditions peuvent évoluer. La date de la dernière mise à jour '
          'est indiquée en bas de cette page.',
    ]),
  ];

  // =====================================================================
  //  POLITIQUE DE CONFIDENTIALITÉ (modèle)
  // =====================================================================

  static const List<SectionTexte> confidentialite = [
    SectionTexte('Données collectées', [
      'Votre compte : nom, prénom, adresse e-mail et mot de passe '
          '(enregistré chiffré, personne ne peut le lire).',
      'Vos signalements : photo, position GPS, catégorie, gravité, quartier, '
          'description et date.',
    ]),
    SectionTexte('Votre position', [
      'La position du téléphone est lue UNIQUEMENT quand vous créez un '
          'signalement ou appuyez sur « GPS ». L’application ne suit pas vos '
          'déplacements et ne lit pas votre position en arrière-plan.',
    ]),
    SectionTexte('Pourquoi ces données ?', [
      'Pour vous identifier, localiser précisément les problèmes et permettre '
          'aux services concernés de les traiter.',
    ]),
    SectionTexte('Qui peut les voir ?', [
      'Les administrateurs voient les comptes et tous les signalements.',
      'Les signalements sont publiés dans l’application de consultation '
          'pour informer les habitants, avec le nom et le prénom de leur '
          'auteur.',
      'Vos données ne sont ni vendues ni cédées à des tiers.',
    ]),
    SectionTexte('Données gardées sur le téléphone', [
      'Votre session (pour ne pas retaper votre mot de passe), votre dernier '
          'e-mail et votre dernier quartier utilisés, et vos réglages '
          '(thème, notifications). La session est effacée à la déconnexion ; '
          'le reste est effacé en désinstallant l’application.',
    ]),
    SectionTexte('Vos droits', [
      'Vous pouvez consulter et corriger vos informations dans Profil → '
          '« Modifier mes informations ».',
      'Pour supprimer votre compte, adressez-vous à votre administrateur.',
      'Ces droits s’exercent conformément à la réglementation gabonaise sur '
          'la protection des données personnelles.',
    ]),
  ];
}

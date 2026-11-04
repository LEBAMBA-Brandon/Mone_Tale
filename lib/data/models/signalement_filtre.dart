import 'package:urbasign/data/models/categorie.dart';
import 'package:urbasign/data/models/gravite.dart';
import 'package:urbasign/data/models/signalement.dart';
import 'package:urbasign/data/models/statut.dart';

/// Les filtres de `GET /api/signalements`.
///
/// Un champ à `null` = "pas de filtre sur ce champ".
/// Le filtre "Tout" de l'écran correspond à [SignalementFiltre.vide].
class SignalementFiltre {
  const SignalementFiltre({
    this.categorie,
    this.statut,
    this.gravite,
    this.quartierId,
    this.dateDebut,
    this.dateFin,
  });

  /// Aucun filtre : tous les signalements ("Tout").
  static const SignalementFiltre vide = SignalementFiltre();

  final Categorie? categorie;
  final Statut? statut;
  final Gravite? gravite;
  final int? quartierId;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  bool get estVide =>
      categorie == null &&
      statut == null &&
      gravite == null &&
      quartierId == null &&
      dateDebut == null &&
      dateFin == null;

  /// Nombre de filtres actifs (pour afficher un badge "2" sur un bouton filtre).
  int get nombreFiltresActifs => [
    categorie,
    statut,
    gravite,
    quartierId,
    dateDebut,
    dateFin,
  ].where((filtre) => filtre != null).length;

  /// Convertit le filtre en paramètres d'URL pour l'API.
  /// Ex : { "categorie": "Voirie", "date_debut": "2026-10-01" }
  /// → `/api/signalements?categorie=Voirie&date_debut=2026-10-01`
  Map<String, String> versParametresRequete() => {
    if (categorie != null) 'categorie': categorie!.valeurApi,
    if (statut != null) 'statut': statut!.valeurApi,
    if (gravite != null) 'gravite': gravite!.valeurApi,
    if (quartierId != null) 'quartier_id': quartierId.toString(),
    if (dateDebut != null) 'date_debut': _formaterDate(dateDebut!),
    if (dateFin != null) 'date_fin': _formaterDate(dateFin!),
  };

  /// Vérifie si un signalement respecte ce filtre.
  /// Sert au mode hors ligne : on filtre localement les données déjà reçues.
  bool correspond(Signalement signalement) {
    if (categorie != null && signalement.categorie != categorie) return false;
    if (statut != null && signalement.statut != statut) return false;
    if (gravite != null && signalement.gravite != gravite) return false;
    if (quartierId != null && signalement.quartierId != quartierId)
      return false;

    if (dateDebut != null || dateFin != null) {
      final date = signalement.dateCreation;
      if (date == null) return false;
      final jour = _jourSeul(date);
      if (dateDebut != null && jour.isBefore(_jourSeul(dateDebut!)))
        return false;
      if (dateFin != null && jour.isAfter(_jourSeul(dateFin!))) return false;
    }
    return true;
  }

  /// Crée une copie en changeant certains champs.
  ///
  /// Astuce : chaque paramètre est une **fonction** pour pouvoir aussi
  /// remettre un champ à `null` :
  /// - `filtre.copyWith(categorie: () => Categorie.voirie)` → filtre sur Voirie
  /// - `filtre.copyWith(categorie: () => null)` → retire le filtre catégorie
  /// - `filtre.copyWith()` → copie identique
  SignalementFiltre copyWith({
    Categorie? Function()? categorie,
    Statut? Function()? statut,
    Gravite? Function()? gravite,
    int? Function()? quartierId,
    DateTime? Function()? dateDebut,
    DateTime? Function()? dateFin,
  }) {
    return SignalementFiltre(
      categorie: categorie != null ? categorie() : this.categorie,
      statut: statut != null ? statut() : this.statut,
      gravite: gravite != null ? gravite() : this.gravite,
      quartierId: quartierId != null ? quartierId() : this.quartierId,
      dateDebut: dateDebut != null ? dateDebut() : this.dateDebut,
      dateFin: dateFin != null ? dateFin() : this.dateFin,
    );
  }

  /// Format attendu par l'API : AAAA-MM-JJ (ex : 2026-10-01).
  static String _formaterDate(DateTime date) {
    final annee = date.year.toString().padLeft(4, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');
    return '$annee-$mois-$jour';
  }

  /// Garde seulement le jour (sans l'heure) pour comparer des dates.
  static DateTime _jourSeul(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // Égalité "par valeur" : deux filtres identiques sont considérés égaux.
  // Important avec Riverpod (J2) pour éviter des rechargements inutiles.
  @override
  bool operator ==(Object other) =>
      other is SignalementFiltre &&
      other.categorie == categorie &&
      other.statut == statut &&
      other.gravite == gravite &&
      other.quartierId == quartierId &&
      other.dateDebut == dateDebut &&
      other.dateFin == dateFin;

  @override
  int get hashCode =>
      Object.hash(categorie, statut, gravite, quartierId, dateDebut, dateFin);
}

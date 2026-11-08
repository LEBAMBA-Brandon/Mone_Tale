import 'package:flutter/material.dart';

/// Palette brute de tala (la même que mono : les deux apps se ressemblent).
///
/// Règles du projet :
/// - vert  → boutons et composants
/// - jaune → AppBar, barre de navigation
/// - noir  → fond du thème sombre / blanc → fond du thème clair
/// - rouge → erreurs
/// - couleurs FONCÉES en thème clair, CLAIRES en thème sombre (lisibilité).
///
/// ⚠️ Dans les écrans et widgets, n'utilise PAS ces constantes directement :
/// passe par `context.schema` (couleurs Material) ou `context.couleurs`
/// (couleurs tala). Sinon le changement de thème ne s'appliquera pas.
abstract final class AppCouleurs {
  // ---------- Thème clair : couleurs foncées ----------
  static const Color vertFonce = Color(0xFF2E7D32);
  static const Color vertFonceConteneur = Color(0xFFC8E6C9);
  static const Color surVertFonceConteneur = Color(0xFF0B3D0E);

  static const Color jauneFonce = Color(0xFFF9A825);
  static const Color jauneFonceConteneur = Color(0xFFFFF3C4);
  static const Color surJauneFonceConteneur = Color(0xFF3D2E00);

  static const Color rougeFonce = Color(0xFFC62828);
  static const Color rougeFonceConteneur = Color(0xFFFFDAD6);
  static const Color surRougeFonceConteneur = Color(0xFF410002);

  static const Color blanc = Color(0xFFFFFFFF);

  // ---------- Thème sombre : couleurs claires ----------
  static const Color vertClair = Color(0xFF81C784);
  static const Color vertClairConteneur = Color(0xFF1E4D21);
  static const Color surVertClair = Color(0xFF0B2E0D);

  static const Color jauneClair = Color(0xFFFFF176);
  static const Color jauneClairConteneur = Color(0xFF4A3F00);

  static const Color rougeClair = Color(0xFFEF9A9A);
  static const Color rougeClairConteneur = Color(0xFF8C1D18);
  static const Color surRougeClair = Color(0xFF4A0E0E);

  static const Color noir = Color(0xFF000000);

  /// Texte et icônes posés sur du jaune : TOUJOURS sombre, dans les 2 thèmes.
  /// (du blanc sur du jaune serait illisible)
  static const Color texteSurJaune = Color(0xFF1A1A1A);

  // ---------- Catégories (marqueurs de la carte) ----------
  // Identiques dans les 2 thèmes : la carte OpenStreetMap, elle, ne change pas.
  // Aucune n'utilise le vert, le jaune ou le rouge, déjà pris par l'interface.
  static const Color voirie = Color(0xFFE65100); // orange
  static const Color ordures = Color(0xFF795548); // marron
  static const Color eclairagePublic = Color(0xFF7B1FA2); // violet
  static const Color caniveauInondation = Color(0xFF1565C0); // bleu
  static const Color autre = Color(0xFF546E7A); // gris bleuté

  // ---------- Gravité ----------
  static const Color graviteFaible = Color(0xFF2E7D32); // vert
  static const Color graviteMoyenne = Color(0xFFFFA000); // ambre
  static const Color graviteCritique = Color(0xFFC62828); // rouge

  // ---------- Statut ----------
  static const Color statutSignale = Color(0xFF1976D2); // bleu
  static const Color statutEnCours = Color(0xFFFFA000); // ambre
  static const Color statutResolu = Color(0xFF2E7D32); // vert

  /// Point bleu "Vous êtes ici".
  static const Color positionUtilisateur = Color(0xFF1E88E5);
}

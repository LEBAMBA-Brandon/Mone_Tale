/// Petites fonctions pour lire le JSON renvoyé par l'API **sans jamais planter**.
///
/// Pourquoi ? Le JSON vient du réseau : un champ peut manquer, valoir `null`,
/// ou arriver dans un type inattendu (`"12"` au lieu de `12`, `5` au lieu de `5.0`).
/// Écrire `json['id'] as int` partout ferait planter l'app au moindre écart.
/// Ces fonctions convertissent proprement et renvoient une valeur par défaut.
///
/// `abstract final class` = classe qu'on ne peut ni instancier ni hériter :
/// c'est juste une "boîte" de fonctions statiques.
abstract final class JsonParser {
  /// Lit un entier. Accepte `12`, `12.0` ou `"12"`.
  static int lireInt(Object? valeur, {int parDefaut = 0}) =>
      lireIntOuNull(valeur) ?? parDefaut;

  /// Lit un entier, ou renvoie `null` si la valeur est absente ou illisible.
  static int? lireIntOuNull(Object? valeur) {
    if (valeur is int) return valeur;
    if (valeur is num) return valeur.toInt();
    if (valeur is String) return int.tryParse(valeur.trim());
    return null;
  }

  /// Lit un nombre décimal. Accepte `0.41`, `1` ou `"0.41"`.
  static double lireDouble(Object? valeur, {double parDefaut = 0}) {
    if (valeur is num) return valeur.toDouble();
    if (valeur is String) return double.tryParse(valeur.trim()) ?? parDefaut;
    return parDefaut;
  }

  /// Lit un texte. `null` devient [parDefaut].
  static String lireString(Object? valeur, {String parDefaut = ''}) {
    if (valeur == null) return parDefaut;
    return valeur.toString();
  }

  /// Lit un texte, ou renvoie `null` s'il est absent ou vide.
  static String? lireStringOuNull(Object? valeur) {
    if (valeur == null) return null;
    final texte = valeur.toString().trim();
    return texte.isEmpty ? null : texte;
  }

  /// Lit une date ISO 8601 (ex : "2026-10-31T22:50:12.000000Z")
  /// et la convertit dans le fuseau horaire du téléphone.
  static DateTime? lireDate(Object? valeur) {
    if (valeur is! String) return null;
    return DateTime.tryParse(valeur)?.toLocal();
  }

  /// Lit un objet JSON (`{ ... }`), ou renvoie `null`.
  static Map<String, dynamic>? lireMap(Object? valeur) {
    if (valeur is Map<String, dynamic>) return valeur;
    if (valeur is Map) return Map<String, dynamic>.from(valeur);
    return null;
  }

  /// Lit une liste d'objets JSON (`[ {...}, {...} ]`).
  /// Les éléments qui ne sont pas des objets sont ignorés.
  static List<Map<String, dynamic>> lireListeDeMaps(Object? valeur) {
    if (valeur is! List) return const [];
    return valeur
        .whereType<Map>()
        .map((element) => Map<String, dynamic>.from(element))
        .toList();
  }
}

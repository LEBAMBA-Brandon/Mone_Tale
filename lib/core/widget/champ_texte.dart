import 'package:flutter/material.dart';
import 'package:tala/core/theme/app_icons.dart';

/// Champ de saisie de tala (connexion, ajout de collecteur, description…).
///
/// - [erreur] : message affiché en rouge sous le champ. Il vient directement
///   de `ApiException.erreurPourChamp('email')` : erreur locale ou erreur
///   422 du serveur, c'est le même affichage.
/// - [longueurMax] : affiche un compteur "12/200" et bloque au-delà.
/// - Le style (bordure, couleurs) vient du thème : rien à répéter ici.
class ChampTexte extends StatelessWidget {
  const ChampTexte({
    super.key,
    required this.libelle,
    this.controller,
    this.icone,
    this.indication,
    this.erreur,
    this.typeClavier,
    this.actionClavier,
    this.onSoumis,
    this.onChange,
    this.longueurMax,
    this.lignesMax = 1,
    this.lignesMin,
    this.indicesRemplissage,
    this.majuscules = TextCapitalization.none,
    this.actif = true,
    this.focus,
  });

  /// Titre du champ ("E-mail", "Nom"…), qui remonte quand on écrit.
  final String libelle;
  final TextEditingController? controller;
  final IconData? icone;

  /// Texte d'aide gris quand le champ est vide ("ex : jean@mail.com").
  final String? indication;

  /// `null` = pas d'erreur.
  final String? erreur;

  final TextInputType? typeClavier;

  /// Bouton en bas à droite du clavier : "Suivant", "Envoyer"…
  final TextInputAction? actionClavier;
  final ValueChanged<String>? onSoumis;
  final ValueChanged<String>? onChange;
  final int? longueurMax;
  final int? lignesMax;
  final int? lignesMin;

  /// Aide au remplissage automatique (gestionnaire de mots de passe…).
  final Iterable<String>? indicesRemplissage;
  final TextCapitalization majuscules;
  final bool actif;
  final FocusNode? focus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focus,
      enabled: actif,
      keyboardType: typeClavier,
      textInputAction: actionClavier,
      onSubmitted: onSoumis,
      onChanged: onChange,
      maxLength: longueurMax,
      maxLines: lignesMax,
      minLines: lignesMin,
      autofillHints: indicesRemplissage,
      textCapitalization: majuscules,
      // Ferme le clavier quand on touche ailleurs.
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: libelle,
        hintText: indication,
        errorText: erreur,
        prefixIcon: icone == null ? null : Icon(icone),
        // Pour un champ de plusieurs lignes, le titre reste en haut.
        alignLabelWithHint: (lignesMax ?? 2) > 1,
      ),
    );
  }
}

/// Champ "Mot de passe" avec le bouton 👁 pour l'afficher ou le masquer.
///
/// C'est un StatefulWidget : "visible ou pas" est un petit état d'affichage
/// qui ne concerne que ce champ. Inutile de le mettre dans un controller GetX.
class ChampMotDePasse extends StatefulWidget {
  const ChampMotDePasse({
    super.key,
    this.controller,
    this.libelle = 'Mot de passe',
    this.erreur,
    this.actionClavier = TextInputAction.done,
    this.onSoumis,
    this.onChange,
    this.nouveau = false,
    this.focus,
  });

  final TextEditingController? controller;
  final String libelle;
  final String? erreur;
  final TextInputAction actionClavier;
  final ValueChanged<String>? onSoumis;
  final ValueChanged<String>? onChange;

  /// `true` pour un NOUVEAU mot de passe (création de compte) : le
  /// téléphone peut alors proposer d'en générer un solide.
  final bool nouveau;
  final FocusNode? focus;

  @override
  State<ChampMotDePasse> createState() => _ChampMotDePasseState();
}

class _ChampMotDePasseState extends State<ChampMotDePasse> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focus,
      obscureText: !_visible,
      // Pas de correcteur ni de suggestions sur un mot de passe.
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.actionClavier,
      onSubmitted: widget.onSoumis,
      onChanged: widget.onChange,
      autofillHints: [
        widget.nouveau ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: widget.libelle,
        errorText: widget.erreur,
        prefixIcon: const Icon(AppIcons.motDePasse),
        suffixIcon: IconButton(
          tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
          icon: Icon(_visible ? AppIcons.masquer : AppIcons.afficher),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

<p align="center">
  <img src="assets/images/icone_app.png" alt="Logo Mono" width="110">
</p>

<h1 align="center">Mono</h1>

<p align="center">
  <strong>Voir sur une carte les problèmes urbains signalés dans la ville</strong><br>
  voirie abîmée, ordures, éclairage en panne, caniveaux bouchés…
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter" alt="Flutter 3.44">
  <img src="https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart" alt="Dart 3.12">
  <img src="https://img.shields.io/badge/GetX-4.7-8A2BE2" alt="GetX 4.7">
  <img src="https://img.shields.io/badge/carte-OpenStreetMap-7EBC6F?logo=openstreetmap" alt="OpenStreetMap">
</p>

---

Mono est l'application **visiteur** du projet *Signalement des problèmes urbains*.
Elle affiche sur une carte les signalements enregistrés par les collecteurs dans l'API Laravel.
**Pas de compte, pas de connexion** : on ouvre l'app et on consulte.

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Couleurs](#couleurs)
- [Prérequis](#prérequis)
- [Installation et lancement](#installation-et-lancement)
- [Architecture](#architecture)
- [GetX dans le projet](#getx-dans-le-projet)
- [Stockage dans le téléphone](#stockage-dans-le-téléphone)
- [Écrans et routes](#écrans-et-routes)
- [Routes de l'API utilisées](#routes-de-lapi-utilisées)
- [Packages](#packages)
- [Icône de l'application](#icône-de-lapplication)
- [Vérifier le code](#vérifier-le-code)
- [Auteur](#auteur)

## Fonctionnalités

**Carte**
- Carte OpenStreetMap avec un marqueur par signalement, coloré selon sa catégorie.
- Les marqueurs proches se regroupent en une bulle avec leur nombre quand on dézoome (clustering).
- Bouton **Autour de moi** : centre la carte sur la position GPS et affiche le point bleu.
  La dernière position est gardée pour centrer la carte tout de suite au lancement suivant.
- Toucher un marqueur ouvre un **aperçu** en bas de l'écran, puis la **page de détail** :
  photo, description, catégorie, gravité, quartier, auteur, date, statut et une mini-carte.

**Recherche (comme Google Maps)**
- Suggestions pendant la frappe, avec un `debounce` de 400 ms : la recherche part quand on arrête de taper, pas à chaque lettre.
- Les accents et les majuscules sont ignorés : `eclairage` trouve « Éclairage public ».
- Plusieurs mots possibles : `trou glass` trouve les signalements qui contiennent « trou » **et** sont à Glass.
- Les quartiers apparaissent d'abord, puis les signalements.
- Les **8 dernières recherches** sont gardées dans le téléphone. On peut les supprimer une par une ou toutes.

**Filtres**
- Puces défilables sous la barre de recherche : **Tout** + les 5 catégories.

**Confort**
- Thème clair ou sombre, gardé en mémoire. En thème sombre, la carte passe aussi en mode « nuit ».
- **Hors ligne** : les signalements déjà reçus restent affichés, et les filtres et la recherche marchent sur ces données.
- Écrans adaptés de la très petite fenêtre (150 px) à la tablette et au navigateur.
- Si le téléphone affiche un texte très grand, l'app le suit jusqu'à 130 % pour rester lisible.
- Interface entièrement en français (dates, boutons système).
- Un lien de détail invalide (ex. `/signalement/abc`) mène à une page « introuvable » au lieu de planter.

## Couleurs

**Interface**

| Couleur | Rôle | Thème clair | Thème sombre |
| ------- | ---- | ----------- | ------------ |
| Vert    | boutons, composants      | `#2E7D32` | `#81C784` |
| Jaune   | barre du haut, navigation | `#F9A825` | `#FFF176` |
| Rouge   | erreurs                  | `#C62828` | `#EF9A9A` |
| Fond    | arrière-plan             | blanc `#FFFFFF` | noir `#000000` |

**Catégories de signalement** (marqueurs de la carte, identiques dans les deux thèmes)

| Catégorie            | Couleur      | Code      |
| -------------------- | ------------ | --------- |
| Voirie               | orange       | `#E65100` |
| Ordures              | marron       | `#795548` |
| Éclairage public     | violet       | `#7B1FA2` |
| Caniveau/Inondation  | bleu         | `#1565C0` |
| Autre                | gris bleuté  | `#546E7A` |

Aucune catégorie n'utilise le vert, le jaune ou le rouge : ces couleurs sont déjà prises par l'interface.

**Gravité** : faible `#2E7D32` · moyenne `#FFA000` · critique `#C62828`
**Statut** : signalé `#1976D2` · en cours `#FFA000` · résolu `#2E7D32`

## Prérequis

- **Flutter 3.44** ou plus récent, avec **Dart 3.12.2** ou plus (`flutter --version` pour vérifier)
- VS Code ou Android Studio
- Un téléphone Android, un émulateur ou Chrome
- **L'API Laravel lancée** avec des données (branche `api-laravel`, voir son README)

## Installation et lancement

### 1. Récupérer le projet

```bash
git clone -b urbasign https://github.com/LEBAMBA-Brandon/UrbaSign.git urbasign
cd urbasign
flutter pub get
```

### 2. Lancer l'API

Dans le dossier de l'API :

```bash
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

> `--host=0.0.0.0` est indispensable pour un vrai téléphone : sans lui, l'API n'accepte que les requêtes venant du PC lui-même.

### 3. Lancer l'application

L'adresse de l'API dépend de l'appareil utilisé :

| Appareil          | Commande | Adresse utilisée |
| ----------------- | -------- | ---------------- |
| Émulateur Android | `flutter run` | `http://10.0.2.2:8000/api` (automatique) |
| Navigateur        | `flutter run -d chrome` | `http://localhost:8000/api` (automatique) |
| Vrai téléphone    | `flutter run --dart-define=API_URL=http://IP_DU_PC:8000/api` | celle que tu donnes |

Pour un vrai téléphone :
1. Mets le téléphone et le PC sur **le même Wi-Fi**.
2. Trouve l'IP du PC avec `ipconfig` (Windows), ligne « Adresse IPv4 », par exemple `192.168.1.71`.
3. Lance `flutter run --dart-define=API_URL=http://192.168.1.71:8000/api`.

Avec VS Code, mets l'adresse dans `.vscode/launch.json` pour ne plus la retaper :

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "mono (téléphone)",
      "cwd": "mono",
      "request": "launch",
      "type": "dart",
      "toolArgs": ["--dart-define=API_URL=http://192.168.1.71:8000/api"]
    }
  ]
}
```

L'adresse est lue dans `lib/data/services/api_config.dart`.

## Architecture

Le code est rangé en **trois couches**. Chaque couche ne parle qu'à celle du dessous :
on peut changer un écran sans toucher à l'API, ou changer l'API sans toucher aux écrans.

```
lib/
├── main.dart                 démarrage : GetStorage, thème, GetMaterialApp
├── core/                     ce qui sert partout
│   ├── theme/                couleurs, thèmes clair/sombre, tailles, icônes, formats
│   └── widget/               15 composants réutilisables (marqueurs, boutons, barre de recherche…)
├── data/                     les données, sans aucun widget
│   ├── models/               les classes : Signalement, Quartier, Categorie, Statut…
│   ├── services/             la porte vers l'extérieur : API (dio), GetStorage, SharedPreferences, GPS
│   └── repositories/         cache, mode hors ligne, recherche
└── modules/                  les écrans et leur logique
    ├── routes/               noms des routes + liste des pages
    ├── binding/              création des controllers et des dépendances
    ├── controller/           état des écrans (.obs) et actions
    ├── middleware/           contrôle avant d'ouvrir un écran
    └── screens/              carte, détail, page introuvable
```

Qui appelle qui :

```
Écran ──(Obx)──▶ Controller ──▶ Repository ──▶ Service ──▶ API Laravel / téléphone
  │                                   │
  └──▶ core (thème, widgets)          └── renvoie des Models
```

- Un **écran** ne fait qu'afficher l'état de son controller.
- Un **controller** ne parle qu'aux repositories, jamais directement à l'API.
- Un **repository** décide d'où viennent les données : cache, API ou mode hors ligne.
- Un **service** est le seul à faire une requête HTTP ou à lire la mémoire du téléphone.

## GetX dans le projet

| Notion GetX | À quoi elle sert ici | Où |
| ----------- | -------------------- | -- |
| `GetMaterialApp`, `GetPage` | navigation par routes nommées | `main.dart`, `modules/routes/` |
| `Bindings` | créer les controllers au bon moment | `modules/binding/` |
| `Get.put(..., permanent: true)` | services et repositories gardés toute la vie de l'app (le cache survit aux changements d'écran) | `initial_binding.dart` |
| `GetxController` + `.obs` / `Rxn` | l'état d'un écran | `modules/controller/` |
| `Obx` | reconstruire seulement la partie de l'écran qui change | `modules/screens/` |
| `debounce` | attendre la fin de la frappe avant de chercher | `carte_controller.dart` |
| `GetMiddleware` | refuser un lien de détail invalide | `detail_signalement_middleware.dart` |
| `Get.changeThemeMode` | changer de thème sans redémarrer | `theme_controller.dart` |

**Cycle de vie d'un controller** (exemple : `CarteController`)

| Méthode   | Quand                         | Ce qu'on y fait |
| --------- | ----------------------------- | --------------- |
| `onInit`  | à la création du controller   | crée le champ texte, la carte, le `debounce`, lance le 1er chargement |
| `onReady` | quand l'écran est affiché     | montre le point bleu si la localisation est déjà autorisée |
| `onClose` | quand on quitte l'écran       | annule les requêtes en cours et libère tout ce qui a été créé |

## Stockage dans le téléphone

| Outil | Ce qu'il garde | Pourquoi lui |
| ----- | -------------- | ------------ |
| **GetStorage** | le thème choisi, la dernière position GPS | lecture **sans `await`** : le thème est connu avant le premier écran, donc pas de clignotement |
| **SharedPreferences** | les 8 dernières recherches | stockage standard pour une petite liste de textes |

Si le stockage échoue, l'app continue avec des valeurs par défaut : elle ne plante jamais pour ça.

## Écrans et routes

| Route | Écran | Remarque |
| ----- | ----- | -------- |
| `/` | Carte | écran d'accueil, pas de barre de navigation (app visiteur) |
| `/signalement/:id` | Détail d'un signalement | protégé par `DetailSignalementMiddleware` |
| `/introuvable` | Page introuvable | aussi utilisée pour toute route inconnue |

## Routes de l'API utilisées

L'application visiteur ne fait que **lire** : aucune connexion n'est nécessaire.

| Requête | Utilisation |
| ------- | ----------- |
| `GET /api/signalements` | tous les signalements de la carte |
| `GET /api/signalements?categorie=…&statut=…&gravite=…&quartier_id=…&date_debut=…&date_fin=…` | liste filtrée |
| `GET /api/signalements/{id}` | page de détail |
| `GET /api/quartiers` | suggestions de quartiers dans la recherche |

## Packages

| Package | Rôle |
| ------- | ---- |
| `get` | état, navigation, dépendances, thème |
| `dio` | requêtes HTTP vers l'API (délais, annulation) |
| `flutter_map` + `latlong2` | carte OpenStreetMap et coordonnées |
| `flutter_map_marker_cluster` | regroupement des marqueurs |
| `geolocator` | position GPS (« Autour de moi ») |
| `get_storage` | thème et dernière position |
| `shared_preferences` | recherches récentes |
| `flutter_localizations` | interface système en français |
| `flutter_launcher_icons` *(dev)* | génération de l'icône de l'app |
| `flutter_lints` *(dev)* | règles de qualité du code |

La carte utilise les tuiles gratuites d'OpenStreetMap. Leur règle d'usage impose d'afficher « © Contributeurs OpenStreetMap », ce que fait l'app en bas de la carte.

## Icône de l'application

Les images sont dans `assets/images/`. La configuration est en bas de `pubspec.yaml` (section `flutter_launcher_icons`).
Après avoir changé une image :

```bash
dart run flutter_launcher_icons
flutter clean
flutter run
```

## Auteur

LEBAMBA BIKECK Brandon.

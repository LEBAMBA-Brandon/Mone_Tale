# UrbaSign — API REST

API de signalement des problèmes urbains (voirie, ordures, éclairage public, caniveaux…) à Libreville.
Elle centralise les signalements envoyés par l'application de collecte (position GPS, photo, catégorie, gravité)
et les renvoie, filtrés, à l'application de consultation qui les affiche sur une carte.

Projet de 2e année informatique — BI-TECH Services.

## Technologies

| Élément | Choix |
|---|---|
| Framework | Laravel 13 (PHP 8.3) |
| Base de données | PostgreSQL |
| Authentification | Laravel Sanctum (token Bearer) |
| Documentation | Swagger (généré par Scramble) + collection Postman |

## Prérequis

- PHP 8.3 ou plus
- Composer
- PostgreSQL

## Installation

1. Cloner la branche de l'API :
   ```bash
   git clone -b api-laravel https://github.com/LEBAMBA-Brandon/UrbaSign.git
   cd UrbaSign
   ```

2. Installer les dépendances :
   ```bash
   composer install
   ```

3. Créer le fichier de configuration :
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

4. Créer une base PostgreSQL vide nommée `urbasign`, puis renseigner ses accès dans `.env` :
   ```env
   DB_CONNECTION=pgsql
   DB_HOST=127.0.0.1
   DB_PORT=5432
   DB_DATABASE=urbasign
   DB_USERNAME=<usernme de votre base de donnée>
   DB_PASSWORD=<votre mot de passe>
   ```

5. Créer les tables et les données de test (communes, arrondissements, quartiers de Libreville, compte admin, 30 signalements) :
   ```bash
   php artisan migrate --seed
   ```

6. Rendre les photos accessibles publiquement :
   ```bash
   php artisan storage:link
   ```

7. Lancer le serveur :
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```

L'API est disponible sur `http://localhost:8000/api`.

> **Tester depuis un téléphone :** le téléphone et le PC doivent être sur le même Wi-Fi.
> Dans les applications, utilisez l'adresse IP du PC (ex : `http://192.168.1.10:8000/api`) au lieu de `localhost`.

## Comptes de test

| Rôle | Email | Mot de passe |
|---|---|---|
| Admin | admin@user.com | 987654 |
| Collecteur | <collecteur@user.com> | <mot_de_passe> |

## Documentation de l'API

- **Swagger** : `http://localhost:8000/docs/api` (serveur lancé, `APP_ENV=local`)
- **Postman** : importer `docs/api-laravel-urbasign.postman_collection.json`
  1. Lancer la requête `se_connecter` : le token est enregistré automatiquement.
  2. Toutes les autres requêtes l'utilisent ensuite.

## Authentification

`POST /api/auth/login` renvoie un token. Il doit être envoyé dans l'en-tête de chaque requête protégée :

```
Authorization: Bearer <token>
Accept: application/json
```

## Endpoints

| Méthode | Route | Rôle | Accès |
|---|---|---|---|
| POST | `/api/auth/login` | Connexion, renvoie un token | Public |
| GET | `/api/auth/me` | Utilisateur connecté | Connecté |
| POST | `/api/auth/logout` | Déconnexion | Connecté |
| GET | `/api/signalements` | Liste filtrable | Public |
| GET | `/api/signalements/{id}` | Détail d'un signalement | Public |
| POST | `/api/signalements` | Créer un signalement avec photo (form-data) | Connecté |
| GET | `/api/signalements/mes-signalements` | Signalements de l'utilisateur connecté | Connecté |
| PATCH | `/api/signalements/{id}/statut` | Changer le statut | Admin |
| DELETE | `/api/signalements/{id}` | Supprimer un signalement | Admin |
| GET | `/api/communes`, `/api/arrondissements`, `/api/quartiers` (+ `/{id}`) | Listes et détails | Public |
| POST / PUT / DELETE | `/api/communes`, `/api/arrondissements`, `/api/quartiers` | Gestion | Admin |
| GET / POST / PUT / DELETE | `/api/users` | Gestion des utilisateurs | Admin |

### Filtres de `GET /api/signalements`

Tous facultatifs et combinables :
`categorie`, `statut`, `gravite`, `quartier_id`, `date_debut`, `date_fin` (format `AAAA-MM-JJ`)

Exemple : `/api/signalements?categorie=Voirie&statut=Signalé&date_debut=2026-10-01`

### Valeurs autorisées

| Champ | Valeurs |
|---|---|
| categorie | Voirie, Ordures, Éclairage public, Caniveau/Inondation, Autre |
| gravite | Faible, Moyenne, Critique |
| statut | Signalé, En cours, Résolu |
| photo | JPEG ou PNG, 1 Mo maximum |

## Auteur

LEBAMBA BIKECK Brandon
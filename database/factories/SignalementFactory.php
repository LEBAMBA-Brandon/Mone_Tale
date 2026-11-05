<?php

namespace Database\Factories;

use App\Models\Quartier;
use App\Models\Signalement;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Signalement>
 */
class SignalementFactory extends Factory
{
    /**
     * Un faux signalement placé AUTOUR du centre réel de son quartier
     * (et plus au hasard dans tout Libreville, mer comprise).
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        // 1) Un quartier qui a des coordonnées (remplies par GeocodageQuartierSeeder)…
        $quartier = Quartier::whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->inRandomOrder()
            ->first();

        if ($quartier === null) {
            throw new \RuntimeException(
                "Aucun quartier n'a de coordonnées : le géocodage a échoué. "
                . 'Vérifie ta connexion internet puis relance php artisan migrate:fresh --seed.'
            );
        }

        // 2) …et un point à moins de ~300 m de son centre
        //    (0,0027 degré ≈ 300 mètres à Libreville, presque sur l'équateur).
        $ecart = 0.0027;

        // 3) Des descriptions réalistes selon la catégorie
        //    (pour tester la recherche : "trou", "lampadaire", "caniveau"…).
        $descriptions = [
            'Voirie' => ['Gros nid-de-poule au carrefour', 'Route très dégradée après la pluie', 'Trou dangereux sur la chaussée'],
            'Ordures' => ["Dépôt d'ordures sauvage", 'Bac à ordures plein depuis une semaine', 'Déchets au bord de la route'],
            'Éclairage public' => ['Lampadaire éteint depuis plusieurs jours', 'Poteau électrique penché', 'Rue entière sans éclairage'],
            'Caniveau/Inondation' => ['Caniveau bouché', 'Rue inondée après la pluie', 'Eau stagnante devant les maisons'],
            'Autre' => ['Panneau de signalisation tombé', 'Arbre tombé sur le trottoir', "Bouche d'égout ouverte"],
        ];
        $categorie = fake()->randomElement(Signalement::CATEGORIES);

        return [
            'latitude'    => $quartier->latitude + fake()->randomFloat(7, -$ecart, $ecart),
            'longitude'   => $quartier->longitude + fake()->randomFloat(7, -$ecart, $ecart),
            'description' => fake()->randomElement($descriptions[$categorie]),
            'categorie'   => $categorie,
            'gravite'     => fake()->randomElement(Signalement::GRAVITES),
            'statut'      => fake()->randomElement(Signalement::STATUTS),
            'photo'       => 'signalements/exemple.jpg',
            'auteur_id'   => User::factory()->state(['role' => 'collecteur']),
            'quartier_id' => $quartier->id,
        ];
    }
}
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Géocodage : trouve les coordonnées GPS d'un lieu à partir de son NOM,
 * grâce à Nominatim, le moteur de recherche d'OpenStreetMap (gratuit, sans clé).
 *
 * Règles d'utilisation de Nominatim (sinon blocage de l'adresse IP) :
 * - 1 requête par seconde maximum → c'est à l'appelant d'attendre entre 2 appels ;
 * - un User-Agent qui identifie l'application.
 */
class GeocodageService
{
    private const URL = 'https://nominatim.openstreetmap.org/search';

    /**
     * Rectangle autour du Grand Libreville (gauche, haut, droite, bas).
     * On ne garde QUE les résultats dedans : évite de tomber sur un "Louis"
     * ou un "Glass" à l'autre bout du monde.
     */
    private const ZONE_LIBREVILLE = '9.35,0.55,9.65,0.25';

    /**
     * @return array{latitude: float, longitude: float}|null  null si introuvable
     */
    public function trouverQuartier(string $quartier, string $commune = 'Libreville'): ?array
    {
        try {
            $reponse = Http::withHeaders(['User-Agent' => 'UrbaSign/1.0 (projet etudiant BI-TECH)'])
                ->timeout(10)
                ->get(self::URL, [
                    'q' => "{$quartier}, {$commune}, Gabon",
                    'format' => 'jsonv2',
                    'limit' => 1,
                    'countrycodes' => 'ga',
                    'viewbox' => self::ZONE_LIBREVILLE,
                    'bounded' => 1,
                ]);
        } catch (\Throwable $e) {
            // Pas d'internet, délai dépassé… : on n'empêche pas le reste de fonctionner.
            Log::warning("Géocodage impossible pour {$quartier} : {$e->getMessage()}");
            return null;
        }

        if (! $reponse->successful()) {
            return null;
        }

        $resultat = $reponse->json()[0] ?? null; // 1er (et seul) résultat
        if ($resultat === null) {
            return null;
        }

        return [
            'latitude' => (float) $resultat['lat'],
            'longitude' => (float) $resultat['lon'],
        ];
    }
}
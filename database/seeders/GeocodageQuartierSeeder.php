<?php

namespace Database\Seeders;

use App\Models\Quartier;
use App\Services\GeocodageService;
use Illuminate\Database\Seeder;

/**
 * Remplit AUTOMATIQUEMENT la latitude et la longitude de chaque quartier
 * qui n'en a pas encore, en interrogeant OpenStreetMap.
 */
class GeocodageQuartierSeeder extends Seeder
{
    public function run(GeocodageService $geocodage): void
    {
        $quartiers = Quartier::with('arrondissement.commune')
            ->whereNull('latitude') // seulement ceux qui n'en ont pas
            ->get();

        foreach ($quartiers as $quartier) {
            $commune = $quartier->arrondissement?->commune?->nom_commune ?? 'Libreville';
            $position = $geocodage->trouverQuartier($quartier->nom_quartier, $commune);

            if ($position === null) {
                $this->command?->warn("  ✗ {$quartier->nom_quartier} : introuvable sur OpenStreetMap");
            } else {
                $quartier->update($position);
                $this->command?->info(
                    "  ✓ {$quartier->nom_quartier} : {$position['latitude']}, {$position['longitude']}"
                );
            }

            usleep(1_100_000); // 1,1 seconde : règle "1 requête par seconde" de Nominatim
        }
    }
}
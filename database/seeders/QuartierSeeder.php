<?php

namespace Database\Seeders;
use App\Models\Quartier;
use App\Models\Arrondissement;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class QuartierSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $parArrondissement = [
            '1er' => ['Glass', 'Mont-Bouet', 'Charbonnages'],
            '2e' => ['Nzeng-Ayong', 'PK8'],
            '3e' => ['Louis', 'Lalala'],
            '4e' => ['Akébé', 'Abilé'],
        ];

        foreach ($parArrondissement as $nomArrondissement => $quartiers) {
            $arrondissement = Arrondissement::where('nom_arrondissement', $nomArrondissement)->firstOrFail();

            foreach ($quartiers as $nomQuartier) {
                Quartier::firstOrCreate([
                    'nom_quartier' => $nomQuartier,
                    'arrondissement_id' => $arrondissement->id,
                ]);
            }
        }
        // Les coordonnées sont ajoutées ensuite par GeocodageQuartierSeeder.
    }
}

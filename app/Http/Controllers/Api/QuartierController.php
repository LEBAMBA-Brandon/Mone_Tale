<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Quartier;
use App\Models\Arrondissement;
use App\Services\GeocodageService;

class QuartierController extends Controller
{
    /**
     * Afficher les quartiers
     * 
     * Affichage de l’ensemble des quartiers
     * @unauthenticated
    */
    public function index(Request $request)
    {
        $quartiers = Quartier::query()
            ->with('arrondissement:id,nom_arrondissement')
            ->when($request->integer('arrondissement_id'), fn ($q, $v) => $q->where('arrondissement_id', $v))
            ->orderBy('nom_quartier')
            ->get();

        return response()->json($quartiers);
    }

    /**
     * Ajouter un quartier
     *
     * Si la latitude et la longitude ne sont pas fournies, elles sont
     * trouvées automatiquement sur OpenStreetMap à partir du nom.
     */
    public function store(Request $request, GeocodageService $geocodage)
    {
        $data = $request->validate([
            'nom_quartier'      => ['required', 'string', 'max:100'],
            'arrondissement_id' => ['required', 'integer', 'exists:arrondissements,id'],
            'latitude'          => ['nullable', 'numeric', 'between:-90,90'],
            'longitude'         => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        if (! isset($data['latitude'], $data['longitude'])) {
            $commune = Arrondissement::with('commune')
                ->find($data['arrondissement_id'])
                ?->commune?->nom_commune ?? 'Libreville';

            // += : n'ajoute latitude/longitude que si le géocodage a trouvé quelque chose.
            $data += $geocodage->trouverQuartier($data['nom_quartier'], $commune) ?? [];
        }

        return response()->json(Quartier::create($data), 201);
    }

    /**
     * Afficher un quartier
     * 
     * Affichage de l’ensemble d’un quartier
     * @unauthenticated
    */
    public function show(Quartier $quartier)
    {
        return response()->json($quartier->load('arrondissement.commune'));
    }

    /**
     * Modifier un quartier
     * 
     * Modification des informations d’un quartier
    */
    public function update(Request $request, Quartier $quartier)
    {
        $data = $request->validate([
            'nom_quartier'      => ['sometimes', 'required', 'string', 'max:100'],
            'arrondissement_id' => ['sometimes', 'required', 'integer', 'exists:arrondissements,id'],
            'latitude'  => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
        ]);

        $quartier->update($data);

        return response()->json($quartier);
    }

    /**
     * Supprimer un quartier
     * 
     * Suppression d’un quartier
    */
    public function destroy(Quartier $quartier)
    {
        if ($quartier->signalements()->exists()) {
            return response()->json(['message' => 'Ce quartier a des signalements, suppression impossible.'], 409);
        }

        $quartier->delete();

        return response()->json(null, 204);
    }
}

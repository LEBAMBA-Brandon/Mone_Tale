<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['nom_quartier', 'arrondissement_id', 'latitude', 'longitude'])]

class Quartier extends Model
{
    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }
    
    public function arrondissement(): BelongsTo
    {
        return $this->belongsTo(Arrondissement::class, 'arrondissement_id');
    }

    public function signalements(): HasMany
    {
        return $this->hasMany(Signalement::class, 'quartier_id');
    }
}

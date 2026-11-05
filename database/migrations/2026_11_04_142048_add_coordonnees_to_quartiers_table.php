<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('quartiers', function (Blueprint $table) {
            // Centre du quartier. nullable : rempli ensuite par le géocodage.
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('quartiers', function (Blueprint $table) {
            $table->dropColumn(['latitude', 'longitude']);
        });
    }
};
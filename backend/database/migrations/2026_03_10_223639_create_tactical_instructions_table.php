<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function run(): void
    {
        Schema::create('tactical_instructions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tactic_id')->constrained()->cascadeOnDelete();
            $table->string('title'); // e.g., "Bloc B"
            $table->text('description')->nullable();
            $table->timestamps();
        });

        Schema::create('instruction_player', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tactical_instruction_id')->constrained()->cascadeOnDelete();
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('instruction_player');
        Schema::dropIfExists('tactical_instructions');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tactic_slot_positions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tactic_id')->constrained()->onDelete('cascade');
            $table->unsignedTinyInteger('slot_index');
            $table->float('x_position');
            $table->float('y_position');
            $table->timestamps();

            $table->unique(['tactic_id', 'slot_index']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tactic_slot_positions');
    }
};

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
        Schema::table('teams', function (Blueprint $blueprint) {
            $blueprint->foreignId('active_tactic_id')->nullable()->constrained('tactics')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('teams', function (Blueprint $blueprint) {
            $blueprint->dropForeign(['active_tactic_id']);
            $blueprint->dropColumn('active_tactic_id');
        });
    }
};

<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Tactic;

class DefaultTacticSeeder extends Seeder
{
    public function run(): void
    {
        $defaults = [
            ['name' => 'Standard 4-4-2', 'formation' => '4-4-2', 'is_default' => true],
            ['name' => 'Attacking 4-3-3', 'formation' => '4-3-3', 'is_default' => true],
            ['name' => 'Defensive 5-4-1', 'formation' => '5-4-1', 'is_default' => true],
            ['name' => 'Balanced 4-2-3-1', 'formation' => '4-2-3-1', 'is_default' => true],
        ];

        foreach ($defaults as $tactic) {
            Tactic::firstOrCreate(
                ['name' => $tactic['name']],
                ['formation' => $tactic['formation'], 'is_default' => $tactic['is_default']]
            );
        }
    }
}

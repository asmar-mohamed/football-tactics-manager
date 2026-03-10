<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Player;
use App\Models\Team;

class PlayerSeeder extends Seeder
{
    public function run(): void
    {
        $team = Team::first();
        if (!$team) return;

        $players = [
            ['name' => 'Kylian Mbappé', 'number' => 7, 'position' => 'FW'],
            ['name' => 'Luka Modric', 'number' => 10, 'position' => 'MF'],
            ['name' => 'Virgil van Dijk', 'number' => 4, 'position' => 'DF'],
            ['name' => 'Thibaut Courtois', 'number' => 1, 'position' => 'GK'],
        ];

        foreach ($players as $playerData) {
            $team->players()->create($playerData);
        }
    }
}

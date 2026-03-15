<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Team;
use App\Models\Category;

class PlayerSeeder extends Seeder
{
    public function run(): void
    {
        $team = Team::where('name', 'Real Madrid CF')->first() ?? Team::first();
        if (!$team) return;

        $categories = Category::pluck('id', 'name');

        $players = [
            // Goalkeepers
            ['name' => 'Thibaut Courtois', 'number' => 1, 'position' => 'GK', 'category' => 'Goalkeeper'],
            ['name' => 'Andriy Lunin', 'number' => 13, 'position' => 'GK', 'category' => 'Goalkeeper'],
            // Defenders
            ['name' => 'Dani Carvajal', 'number' => 2, 'position' => 'RB', 'category' => 'Defender'],
            ['name' => 'Eder Militao', 'number' => 3, 'position' => 'CB', 'category' => 'Defender'],
            ['name' => 'David Alaba', 'number' => 4, 'position' => 'CB', 'category' => 'Defender'],
            ['name' => 'Antonio Rudiger', 'number' => 22, 'position' => 'CB', 'category' => 'Defender'],
            ['name' => 'Ferland Mendy', 'number' => 23, 'position' => 'LB', 'category' => 'Defender'],
            ['name' => 'Fran Garcia', 'number' => 20, 'position' => 'LB', 'category' => 'Defender'],
            ['name' => 'Lucas Vazquez', 'number' => 17, 'position' => 'RB', 'category' => 'Defender'],
            // Midfielders
            ['name' => 'Aurelien Tchouameni', 'number' => 18, 'position' => 'DM', 'category' => 'Midfielder'],
            ['name' => 'Eduardo Camavinga', 'number' => 6, 'position' => 'CM', 'category' => 'Midfielder'],
            ['name' => 'Federico Valverde', 'number' => 15, 'position' => 'CM', 'category' => 'Midfielder'],
            ['name' => 'Jude Bellingham', 'number' => 5, 'position' => 'AM', 'category' => 'Midfielder'],
            ['name' => 'Dani Ceballos', 'number' => 19, 'position' => 'CM', 'category' => 'Midfielder'],
            ['name' => 'Arda Guler', 'number' => 24, 'position' => 'AM', 'category' => 'Midfielder'],
            ['name' => 'Luka Modric', 'number' => 10, 'position' => 'CM', 'category' => 'Midfielder'],
            // Forwards
            ['name' => 'Vinicius Junior', 'number' => 7, 'position' => 'LW', 'category' => 'Forward'],
            ['name' => 'Rodrygo Goes', 'number' => 11, 'position' => 'RW', 'category' => 'Forward'],
            ['name' => 'Endrick', 'number' => 16, 'position' => 'ST', 'category' => 'Forward'],
            ['name' => 'Joselu Mato', 'number' => 14, 'position' => 'ST', 'category' => 'Forward'],
            ['name' => 'Cristiano Ronaldo', 'number' => 9, 'position' => 'ST', 'category' => 'Forward'],
        ];

        foreach ($players as $playerData) {
            $team->players()->create([
                'name' => $playerData['name'],
                'number' => $playerData['number'],
                'position' => $playerData['position'],
                'category_id' => $categories[$playerData['category']] ?? $categories->first(),
            ]);
        }
    }
}

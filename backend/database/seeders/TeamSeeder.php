<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Team;
use App\Models\User;

class TeamSeeder extends Seeder
{
    public function run(): void
    {
        $coach = User::first() ?? User::factory()->create([
            'name' => 'Coach Tester',
            'email' => 'coach@example.com',
            'password' => bcrypt('password123'),
        ]);

        Team::factory()->for($coach, 'coach')->create([
            'name' => 'Real Madrid CF',
        ]);
    }
}

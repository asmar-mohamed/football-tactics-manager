<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Team;
use App\Models\User;

class TeamSeeder extends Seeder
{
    public function run(): void
    {
        $coach = User::first();
        if (!$coach) {
            $coach = User::create([
                'name' => 'Coach Tester',
                'email' => 'coach@example.com',
                'password' => bcrypt('password123'),
            ]);
        }

        Team::create([
            'name' => 'FC Test',
            'coach_id' => $coach->id,
        ]);
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Team;
use App\Models\User;

class TeamSeeder extends Seeder
{
    public function run(): void
    {
        $coach = User::firstOrCreate([
            'email' => 'coach@example.com',
        ], [
            'name' => 'Coach Tester',
            'password' => 'password123',
        ]);

        $team = Team::query()
            ->where('coach_id', $coach->id)
            ->orWhere('name', 'Real Madrid CF')
            ->first() ?? new Team();

        $team->name = 'Real Madrid CF';
        $team->coach()->associate($coach);
        $team->save();
    }
}

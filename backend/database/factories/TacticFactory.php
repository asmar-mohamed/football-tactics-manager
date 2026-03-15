<?php

namespace Database\Factories;

use App\Models\Team;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Tactic>
 */
class TacticFactory extends Factory
{
    public function definition(): array
    {
        $formations = ['4-4-2', '4-3-3', '3-5-2', '5-3-2', '4-2-3-1'];

        return [
            'name' => fake()->words(2, true) . ' ' . fake()->randomElement($formations),
            'formation' => fake()->randomElement($formations),
            'team_id' => Team::factory(),
            'is_default' => false,
        ];
    }
}

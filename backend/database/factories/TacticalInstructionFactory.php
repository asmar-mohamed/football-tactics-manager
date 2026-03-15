<?php

namespace Database\Factories;

use App\Models\Tactic;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\TacticalInstruction>
 */
class TacticalInstructionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'tactic_id' => Tactic::factory(),
            'title' => fake()->sentence(3),
            'description' => fake()->optional()->sentence(8),
        ];
    }
}

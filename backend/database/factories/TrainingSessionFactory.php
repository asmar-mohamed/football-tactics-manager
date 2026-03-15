<?php

namespace Database\Factories;

use App\Models\Team;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\TrainingSession>
 */
class TrainingSessionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'title' => fake()->sentence(3),
            'description' => fake()->optional()->paragraph(1),
            'team_id' => Team::factory(),
            'date' => fake()->dateTimeBetween('-1 month', '+1 month'),
        ];
    }
}

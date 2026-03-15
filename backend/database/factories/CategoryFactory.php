<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Category>
 */
class CategoryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->unique()->randomElement([
                'Goalkeeper', 'Defender', 'Midfielder', 'Forward',
                'Wing Back', 'Attacking Midfielder', 'Defensive Midfielder'
            ]),
            'description' => fake()->optional()->sentence(),
        ];
    }
}

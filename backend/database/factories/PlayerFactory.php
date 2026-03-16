<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Team;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Player>
 */
class PlayerFactory extends Factory
{
    public function definition(): array
    {
        $positions = [
            'GK' => 'Goalkeeper',
            'CB' => 'Defender',
            'LB' => 'Defender',
            'RB' => 'Defender',
            'DM' => 'Defensive Midfielder',
            'CM' => 'Midfielder',
            'AM' => 'Attacking Midfielder',
            'LW' => 'Forward',
            'RW' => 'Forward',
            'ST' => 'Forward',
        ];

        $code = fake()->randomElement(array_keys($positions));

        return [
            'name' => fake()->name(),
            'number' => fake()->unique()->numberBetween(1, 99),
            'position' => $code,
            'role' => fake()->randomElement(['starter', 'substitute']),
            'team_id' => Team::factory(),
            'category_id' => Category::factory()->state([
                'name' => $positions[$code],
            ]),
        ];
    }
}

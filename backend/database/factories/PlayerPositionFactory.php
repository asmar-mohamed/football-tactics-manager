<?php

namespace Database\Factories;

use App\Models\Player;
use App\Models\Tactic;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\PlayerPosition>
 */
class PlayerPositionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'player_id' => Player::factory(),
            'tactic_id' => Tactic::factory(),
            'x_position' => fake()->randomFloat(2, 0, 100),
            'y_position' => fake()->randomFloat(2, 0, 100),
        ];
    }
}

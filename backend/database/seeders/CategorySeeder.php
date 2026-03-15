<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Goalkeeper', 'description' => 'Last line of defense, prevents goals.'],
            ['name' => 'Defender', 'description' => 'Protects defensive third and stops attacks.'],
            ['name' => 'Midfielder', 'description' => 'Links defense and attack, controls tempo.'],
            ['name' => 'Forward', 'description' => 'Primary goal scorers and attackers.'],
        ];

        foreach ($categories as $data) {
            Category::firstOrCreate(['name' => $data['name']], $data);
        }
    }
}

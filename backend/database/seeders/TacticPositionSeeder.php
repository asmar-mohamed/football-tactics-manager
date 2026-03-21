<?php

namespace Database\Seeders;

use App\Models\Tactic;
use App\Models\TacticSlotPosition;
use App\Models\Team;
use Illuminate\Database\Seeder;

class TacticPositionSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedSlotTemplatesForAllTactics();
        $this->seedTeamTacticsWithPlayerPositions();
    }

    private function seedSlotTemplatesForAllTactics(): void
    {
        $tactics = Tactic::query()->get();

        foreach ($tactics as $tactic) {
            $slots = $this->formationSlots($tactic->formation);
            $this->upsertSlotPositions($tactic->id, $slots);
        }
    }

    private function seedTeamTacticsWithPlayerPositions(): void
    {
        $teams = Team::with('players')->get();

        foreach ($teams as $team) {
            if ($team->players->isEmpty()) {
                continue;
            }

            $lineupPlayers = $team->players
                ->sortBy([
                    fn ($player) => $player->role === 'starter' ? 0 : 1,
                    fn ($player) => $player->number,
                ])
                ->take(11)
                ->values();

            if ($lineupPlayers->isEmpty()) {
                continue;
            }

            $seedTactics = [
                ['name' => 'Main Lineup', 'formation' => '4-3-3'],
                ['name' => 'Defensive Shape', 'formation' => '4-4-2'],
            ];

            foreach ($seedTactics as $seedTactic) {
                $tactic = Tactic::updateOrCreate(
                    [
                        'team_id' => $team->id,
                        'name' => $seedTactic['name'],
                    ],
                    [
                        'formation' => $seedTactic['formation'],
                        'is_default' => false,
                    ]
                );

                $slots = $this->formationSlots($tactic->formation);
                $this->upsertSlotPositions($tactic->id, $slots);

                if ($team->active_tactic_id !== $tactic->id) {
                    $team->active_tactic_id = $tactic->id;
                }
            }

            // Mark the active tactic as is_default = true
            if ($team->active_tactic_id) {
                $team->tactics()->update(['is_default' => false]);
                Tactic::where('id', $team->active_tactic_id)->update(['is_default' => true]);
            }

            if ($team->isDirty('active_tactic_id')) {
                $team->save();
            }
        }
    }

    /**
     * Returns 11 normalized slot positions from a formation string.
     *
     * @return array<int, array{x_position: float, y_position: float}>
     */
    private function formationSlots(string $formation): array
    {
        $default = [
            ['x_position' => 0.08, 'y_position' => 0.50],
            ['x_position' => 0.25, 'y_position' => 0.15],
            ['x_position' => 0.22, 'y_position' => 0.38],
            ['x_position' => 0.22, 'y_position' => 0.62],
            ['x_position' => 0.25, 'y_position' => 0.85],
            ['x_position' => 0.45, 'y_position' => 0.25],
            ['x_position' => 0.45, 'y_position' => 0.50],
            ['x_position' => 0.45, 'y_position' => 0.75],
            ['x_position' => 0.75, 'y_position' => 0.20],
            ['x_position' => 0.80, 'y_position' => 0.50],
            ['x_position' => 0.75, 'y_position' => 0.80],
        ];

        preg_match_all('/\d+/', preg_replace('/\s+/', '', $formation), $matches);
        $lines = array_map('intval', $matches[0] ?? []);
        $sum = array_sum($lines);

        if (empty($lines) || $sum !== 10 || in_array(0, $lines, true)) {
            return $default;
        }

        $slots = [['x_position' => 0.08, 'y_position' => 0.50]];
        $lineCount = count($lines);

        if ($lineCount === 3) {
            $xBands = [0.25, 0.50, 0.75];
        } elseif ($lineCount === 4) {
            $xBands = [0.25, 0.45, 0.65, 0.80];
        } else {
            $xBands = [];
            for ($i = 0; $i < $lineCount; $i++) {
                $xBands[] = 0.25 + ($i * 0.55 / ($lineCount - 1));
            }
        }

        foreach ($lines as $lineIndex => $count) {
            $x = $xBands[$lineIndex];
            if ($count === 1) {
                $slots[] = ['x_position' => $x, 'y_position' => 0.50];
                continue;
            }

            $verticalSpan = $count <= 2 ? 0.35 : 0.70;
            $yStart = 0.50 - ($verticalSpan / 2);
            $yStep = $verticalSpan / ($count - 1);

            for ($j = 0; $j < $count; $j++) {
                $y = $yStart + ($j * $yStep);
                $dx = $x;

                if ($lineIndex === 0 && ($j === 0 || $j === $count - 1) && $count >= 4) {
                    $dx += 0.03;
                }
                if ($lineIndex === 0 && $count >= 4 && $j > 0 && $j < $count - 1) {
                    $dx -= 0.03;
                }

                $slots[] = [
                    'x_position' => round($dx, 4),
                    'y_position' => round($y, 4),
                ];
            }
        }

        while (count($slots) < 11) {
            $slots[] = ['x_position' => 0.50, 'y_position' => 0.50];
        }

        return array_slice($slots, 0, 11);
    }

    /**
     * @param array<int, array{x_position: float, y_position: float}> $slots
     */
    private function upsertSlotPositions(int $tacticId, array $slots): void
    {
        $validIndexes = [];

        foreach ($slots as $index => $slot) {
            $slotIndex = $index + 1;
            $validIndexes[] = $slotIndex;

            TacticSlotPosition::updateOrCreate(
                [
                    'tactic_id' => $tacticId,
                    'slot_index' => $slotIndex,
                ],
                [
                    'x_position' => $slot['x_position'],
                    'y_position' => $slot['y_position'],
                ]
            );
        }

        TacticSlotPosition::where('tactic_id', $tacticId)
            ->whereNotIn('slot_index', $validIndexes)
            ->delete();
    }
}


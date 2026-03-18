<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTacticSlotPositionRequest;
use App\Models\Tactic;
use App\Models\TacticSlotPosition;

class TacticSlotPositionController extends Controller
{
    public function store(StoreTacticSlotPositionRequest $request)
    {
        $tactic = Tactic::findOrFail($request->tactic_id);

        if (!$tactic->is_default) {
            $this->authorize('update', $tactic->team);
        }

        $position = TacticSlotPosition::updateOrCreate(
            [
                'tactic_id' => $request->tactic_id,
                'slot_index' => $request->slot_index,
            ],
            [
                'x_position' => $request->x_position,
                'y_position' => $request->y_position,
            ]
        );

        return response()->json([
            'message' => 'Tactic slot position saved',
            'data' => $position,
        ], 201);
    }

    public function getTacticPositions($tacticId)
    {
        $tactic = Tactic::findOrFail($tacticId);

        if (!$tactic->is_default) {
            $this->authorize('view', $tactic->team);
        }

        return response()->json([
            'message' => 'Tactic slot positions retrieved',
            'data' => $tactic->slotPositions()->orderBy('slot_index')->get(),
        ]);
    }
}

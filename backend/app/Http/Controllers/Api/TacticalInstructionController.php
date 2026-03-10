<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TacticalInstruction;
use App\Models\Tactic;
use Illuminate\Http\Request;
use App\Http\Requests\StoreTacticalInstructionRequest;
use Illuminate\Support\Facades\DB;

class TacticalInstructionController extends Controller
{
    public function store(StoreTacticalInstructionRequest $request)
    {
        $tactic = Tactic::findOrFail($request->tactic_id);
        $this->authorize('update', $tactic->team);

        $instruction = DB::transaction(function () use ($request) {
            $instruction = TacticalInstruction::create([
                'tactic_id' => $request->tactic_id,
                'title' => $request->title,
                'description' => $request->description,
            ]);

            $instruction->players()->sync($request->player_ids);

            return $instruction->load('players');
        });

        return response()->json([
            'message' => 'Tactical instruction created',
            'data' => $instruction
        ], 201);
    }

    public function destroy(TacticalInstruction $tacticalInstruction)
    {
        $this->authorize('delete', $tacticalInstruction->tactic->team);
        $tacticalInstruction->delete();

        return response()->json([
            'message' => 'Tactical instruction deleted'
        ]);
    }

    public function getByTactic($tacticId)
    {
        $tactic = Tactic::findOrFail($tacticId);
        $this->authorize('view', $tactic->team);

        return response()->json([
            'message' => 'Instructions retrieved',
            'data' => $tactic->tacticalInstructions()->with('players')->get()
        ]);
    }
}

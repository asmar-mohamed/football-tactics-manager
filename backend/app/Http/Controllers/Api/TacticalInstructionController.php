<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TacticalInstruction;
use App\Models\Tactic;
use App\Models\Player;
use Illuminate\Http\Request;
use App\Http\Requests\StoreTacticalInstructionRequest;
use Illuminate\Support\Facades\DB;

class TacticalInstructionController extends Controller
{
    public function store(StoreTacticalInstructionRequest $request)
    {
        $tactic = Tactic::findOrFail($request->tactic_id);
        $this->authorize('update', $tactic->team);

        // Ensure every player is on the same team as the tactic
        $invalidPlayer = Player::whereIn('id', $request->player_ids ?? [])
            ->where('team_id', '!=', $tactic->team_id)
            ->exists();
        if ($invalidPlayer) {
            abort(422, 'All players must belong to the same team as the tactic');
        }

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
            'data' => $instruction->load('players.category')
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
            'data' => $tactic->tacticalInstructions()->with('players.category')->get()
        ]);
    }
}

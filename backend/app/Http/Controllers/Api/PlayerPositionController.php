<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PlayerPosition;
use App\Models\Tactic;
use App\Models\Player;
use Illuminate\Http\Request;
use App\Http\Requests\StorePlayerPositionRequest;

class PlayerPositionController extends Controller
{
    public function store(StorePlayerPositionRequest $request)
    {
        $tactic = Tactic::findOrFail($request->tactic_id);
        $this->authorize('update', $tactic->team);

        // Ensure the player belongs to the same team as the tactic
        $belongsToTeam = $tactic->team_id
            ? Player::where('team_id', $tactic->team_id)->whereKey($request->player_id)->exists()
            : false;
        if (!$belongsToTeam) {
            abort(422, 'Player must belong to the same team as the tactic');
        }

        $position = PlayerPosition::updateOrCreate(
            ['tactic_id' => $request->tactic_id, 'player_id' => $request->player_id],
            ['x_position' => $request->x_position, 'y_position' => $request->y_position]
        );

        return response()->json([
            'message' => 'Player position saved',
            'data' => $position->load('player.category')
        ], 201);
    }

    public function update(StorePlayerPositionRequest $request, $id)
    {
        $position = PlayerPosition::findOrFail($id);
        $this->authorize('update', $position->tactic->team);

        $position->update($request->validated());

        return response()->json([
            'message' => 'Player position updated',
            'data' => $position->load('player.category')
        ]);
    }

    public function getTacticPositions($tacticId)
    {
        $tactic = Tactic::findOrFail($tacticId);
        $this->authorize('view', $tactic->team);

        return response()->json([
            'message' => 'Tactic positions retrieved',
            'data' => $tactic->playerPositions()->with('player.category')->get()
        ]);
    }
}

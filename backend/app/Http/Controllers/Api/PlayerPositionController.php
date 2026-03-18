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
        
        if (!$tactic->is_default) {
            $this->authorize('update', $tactic->team);
        }

        $player = Player::findOrFail($request->player_id);
        $this->authorize('update', $player->team);

        if (!$tactic->is_default && $player->team_id !== $tactic->team_id) {
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
        $this->authorize('update', $position->player->team);

        $position->update($request->validated());

        return response()->json([
            'message' => 'Player position updated',
            'data' => $position->load('player.category')
        ]);
    }

    public function getTacticPositions($tacticId)
    {
        $tactic = Tactic::findOrFail($tacticId);
        
        if (!$tactic->is_default) {
            $this->authorize('view', $tactic->team);
        }

        $userTeamIds = auth()->user()->teams->pluck('id');

        $positions = $tactic->playerPositions()
            ->whereHas('player', function ($query) use ($userTeamIds) {
                $query->whereIn('team_id', $userTeamIds);
            })
            ->with('player.category')
            ->get();

        return response()->json([
            'message' => 'Tactic positions retrieved',
            'data' => $positions
        ]);
    }
}

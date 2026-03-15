<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Player;
use App\Models\Team;
use Illuminate\Http\Request;
use App\Http\Requests\StorePlayerRequest;
use App\Http\Requests\UpdatePlayerRequest;
use Illuminate\Support\Facades\Auth;

class PlayerController extends Controller
{
    public function index(Request $request)
    {
        if ($request->has('team_id')) {
            $team = Team::findOrFail($request->team_id);
            $this->authorize('view', $team);
            $players = $team->players()->with('category')->get();
        } else {
            $players = Player::whereIn('team_id', Auth::user()->teams->pluck('id'))
                ->with('category')
                ->get();
        }

        return response()->json([
            'message' => 'Players retrieved',
            'data' => $players
        ]);
    }

    public function store(StorePlayerRequest $request)
    {
        $team = Team::findOrFail($request->team_id);
        $this->authorize('update', $team);

        $player = $team->players()->create($request->validated());

        return response()->json([
            'message' => 'Player created',
            'data' => $player->load('category')
        ], 201);
    }

    public function show(Player $player)
    {
        $this->authorize('view', $player->team);
        return response()->json([
            'message' => 'Player details',
            'data' => $player->load('category')
        ]);
    }

    public function update(UpdatePlayerRequest $request, Player $player)
    {
        $this->authorize('update', $player->team);
        $player->update($request->validated());

        return response()->json([
            'message' => 'Player updated',
            'data' => $player->load('category')
        ]);
    }

    public function destroy(Player $player)
    {
        $this->authorize('delete', $player->team);
        $player->delete();

        return response()->json([
            'message' => 'Player deleted'
        ]);
    }
}

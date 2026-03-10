<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tactic;
use App\Models\Team;
use Illuminate\Http\Request;
use App\Http\Requests\StoreTacticRequest;
use App\Http\Requests\UpdateTacticRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class TacticController extends Controller
{
    public function index(Request $request)
    {
        $query = Tactic::query();

        if ($request->has('team_id')) {
            $team = Team::findOrFail($request->team_id);
            $this->authorize('view', $team);
            $query->where('team_id', $request->team_id)
                  ->orWhere('is_default', true); // Include defaults when asking for a team's tactics
        } else {
            // General list for the user: their tactics + defaults
            $query->whereIn('team_id', Auth::user()->teams->pluck('id'))
                  ->orWhere('is_default', true);
        }

        return response()->json([
            'message' => 'Tactics retrieved',
            'data' => $query->get()
        ]);
    }

    public function defaults()
    {
        return response()->json([
            'message' => 'Default tactics retrieved',
            'data' => Tactic::where('is_default', true)->get()
        ]);
    }

    public function store(StoreTacticRequest $request)
    {
        $team = Team::findOrFail($request->team_id);
        $this->authorize('update', $team);

        $tactic = DB::transaction(function () use ($request, $team) {
            $tactic = $team->tactics()->create([
                'name' => $request->name,
                'formation' => $request->formation,
                'is_default' => false,
            ]);

            if ($request->has('positions')) {
                foreach ($request->positions as $pos) {
                    $tactic->playerPositions()->create([
                        'player_id' => $pos['player_id'],
                        'x_position' => $pos['x_position'],
                        'y_position' => $pos['y_position'],
                    ]);
                }
            }

            return $tactic->load('playerPositions');
        });

        return response()->json([
            'message' => 'Tactic created',
            'data' => $tactic
        ], 201);
    }

    public function show(Tactic $tactic)
    {
        if (!$tactic->is_default) {
            $this->authorize('view', $tactic->team);
        }
        
        return response()->json([
            'message' => 'Tactic details',
            'data' => $tactic->load(['playerPositions.player', 'tacticalInstructions.players'])
        ]);
    }

    public function update(UpdateTacticRequest $request, Tactic $tactic)
    {
        if ($tactic->is_default) {
            return response()->json(['message' => 'Cannot update default tactics'], 403);
        }

        $this->authorize('update', $tactic->team);
        
        $tactic->update($request->only(['name', 'formation']));

        return response()->json([
            'message' => 'Tactic updated',
            'data' => $tactic
        ]);
    }

    public function destroy(Tactic $tactic)
    {
        if ($tactic->is_default) {
            return response()->json(['message' => 'Cannot delete default tactics'], 403);
        }

        $this->authorize('delete', $tactic->team);
        $tactic->delete();

        return response()->json([
            'message' => 'Tactic deleted'
        ]);
    }
}

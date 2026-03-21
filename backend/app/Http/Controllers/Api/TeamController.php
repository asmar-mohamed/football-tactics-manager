<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tactic;
use App\Models\Team;
use Illuminate\Http\Request;
use App\Http\Requests\StoreTeamRequest;
use App\Http\Requests\UpdateTeamRequest;
use Illuminate\Support\Facades\Auth;

class TeamController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(Team::class, 'team');
    }

    public function index()
    {
        $team = Auth::user()->team()->with('activeTactic')->withCount('players')->first();
        $teams = $team ? [$team] : [];

        return response()->json([
            'message' => 'Teams retrieved',
            'data' => $teams
        ]);
    }

    public function store(StoreTeamRequest $request)
    {
        if (Auth::user()->team()->exists()) {
            return response()->json([
                'message' => 'You already have a team'
            ], 422);
        }

        $team = Auth::user()->team()->create($request->validated());

        return response()->json([
            'message' => 'Team created',
            'data' => $team
        ], 201);
    }

    public function show(Team $team)
    {
        return response()->json([
            'message' => 'Team details',
            'data' => $team->load('activeTactic')
        ]);
    }

    public function setActiveTactic(Request $request, Team $team)
    {
        $this->authorize('update', $team);

        $request->validate([
            'tactic_id' => 'required|integer|exists:tactics,id',
        ]);

        $tactic = Tactic::findOrFail($request->tactic_id);

        // If it's a global template tactic (no team_id), clone it for the team
        if (is_null($tactic->team_id)) {
            $tactic = $team->tactics()->create([
                'name' => $tactic->name,
                'formation' => $tactic->formation,
                'is_default' => true,
            ]);
        } elseif ($tactic->team_id !== $team->id) {
            return response()->json([
                'message' => 'This tactic does not belong to your team'
            ], 403);
        }

        // Set all team tactics to is_default = 0
        $team->tactics()->update(['is_default' => false]);
        
        // Set the chosen one to is_default = 1
        $tactic->update(['is_default' => true]);

        // Still keep active_tactic_id for backward compatibility and quick access
        $team->update(['active_tactic_id' => $tactic->id]);

        return response()->json([
            'message' => 'Active tactic updated',
            'data' => $team->load('activeTactic'),
        ]);
    }

    public function update(UpdateTeamRequest $request, Team $team)
    {
        $team->update($request->validated());

        return response()->json([
            'message' => 'Team updated',
            'data' => $team
        ]);
    }

    public function destroy(Team $team)
    {
        $team->delete();

        return response()->json([
            'message' => 'Team deleted'
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
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
        $teams = Auth::user()->teams()->withCount('players')->get();
        return response()->json([
            'message' => 'Teams retrieved',
            'data' => $teams
        ]);
    }

    public function store(StoreTeamRequest $request)
    {
        $team = Auth::user()->teams()->create($request->validated());

        return response()->json([
            'message' => 'Team created',
            'data' => $team
        ], 201);
    }

    public function show(Team $team)
    {
        return response()->json([
            'message' => 'Team details',
            'data' => $team
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

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
                  ->orWhereNull('team_id'); // Include global templates
        } else {
            // General list for the user: their team tactics + global templates
            $teamId = Auth::user()?->team?->id;
            $query->where(function ($q) use ($teamId) {
                if ($teamId) {
                    $q->where('team_id', $teamId);
                }
                $q->orWhereNull('team_id');
            });
        }

        $query->orderBy('is_default', 'desc')
              ->orderBy('id', 'asc');

        return response()->json([
            'message' => 'Tactics retrieved',
            'data' => $query->get()
        ]);
    }

    public function defaults()
    {
        return response()->json([
            'message' => 'Default tactics retrieved',
            'data' => Tactic::whereNull('team_id')->get()
        ]);
    }

    public function store(StoreTacticRequest $request)
    {
        $team = Team::findOrFail($request->team_id);
        $this->authorize('update', $team);

        $tactic = DB::transaction(function () use ($request, $team) {
            // If they are creating a new tactic, it shouldn't be the default right away unless we want it to.
            // Requirement: "when i create tactics he should be not the default"
            $tactic = $team->tactics()->create([
                'name' => $request->name,
                'formation' => $request->formation,
                'is_default' => false,
            ]);

            return $tactic;
        });

        return response()->json([
            'message' => 'Tactic created',
            'data' => $tactic
        ], 201);
    }

    public function show(Tactic $tactic)
    {
        if (!is_null($tactic->team_id)) {
            $this->authorize('view', $tactic->team);
        }
        
        return response()->json([
            'message' => 'Tactic details',
            'data' => $tactic->load('tacticalInstructions.players')
        ]);
    }

    public function update(UpdateTacticRequest $request, Tactic $tactic)
    {
        if (is_null($tactic->team_id)) {
            return response()->json(['message' => 'Cannot update global template tactics'], 403);
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
        if (is_null($tactic->team_id)) {
            return response()->json(['message' => 'Cannot delete global template tactics'], 403);
        }

        $this->authorize('delete', $tactic->team);
        $tactic->delete();

        return response()->json([
            'message' => 'Tactic deleted'
        ]);
    }
}

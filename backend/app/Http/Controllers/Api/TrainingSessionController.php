<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TrainingSession;
use App\Models\Team;
use Illuminate\Http\Request;
use App\Http\Requests\StoreTrainingSessionRequest;
use App\Http\Requests\UpdateTrainingSessionRequest;
use Illuminate\Support\Facades\Auth;

class TrainingSessionController extends Controller
{
    public function index(Request $request)
    {
        if ($request->has('team_id')) {
            $team = Team::findOrFail($request->team_id);
            $this->authorize('view', $team);
            $sessions = $team->trainingSessions;
        } else {
            $sessions = TrainingSession::whereIn('team_id', Auth::user()->teams->pluck('id'))->get();
        }

        return response()->json([
            'message' => 'Training sessions retrieved',
            'data' => $sessions
        ]);
    }

    public function store(StoreTrainingSessionRequest $request)
    {
        $team = Team::findOrFail($request->team_id);
        $this->authorize('update', $team);

        $session = $team->trainingSessions()->create($request->validated());

        return response()->json([
            'message' => 'Training session created',
            'data' => $session
        ], 201);
    }

    public function show(TrainingSession $trainingSession)
    {
        $this->authorize('view', $trainingSession->team);
        return response()->json([
            'message' => 'Training session details',
            'data' => $trainingSession
        ]);
    }

    public function update(UpdateTrainingSessionRequest $request, TrainingSession $trainingSession)
    {
        $this->authorize('update', $trainingSession->team);
        $trainingSession->update($request->validated());

        return response()->json([
            'message' => 'Training session updated',
            'data' => $trainingSession
        ]);
    }

    public function destroy(TrainingSession $trainingSession)
    {
        $this->authorize('delete', $trainingSession->team);
        $trainingSession->delete();

        return response()->json([
            'message' => 'Training session deleted'
        ]);
    }
}

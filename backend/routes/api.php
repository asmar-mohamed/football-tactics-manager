<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TeamController;
use App\Http\Controllers\Api\PlayerController;
use App\Http\Controllers\Api\TacticController;
use App\Http\Controllers\Api\PlayerPositionController;
use App\Http\Controllers\Api\TacticSlotPositionController;
use App\Http\Controllers\Api\TacticalInstructionController;
use App\Http\Controllers\Api\TrainingSessionController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);

    // 7. Gestion des équipes
    Route::apiResource('teams', TeamController::class);

    // 8. Gestion des joueurs
    Route::apiResource('players', PlayerController::class);

    // 9. Gestion des tactiques
    Route::get('tactics/defaults', [TacticController::class, 'defaults']);
    Route::apiResource('tactics', TacticController::class);

    // 10. Gestion des positions des joueurs (Drag & Drop)
    Route::post('player-positions', [PlayerPositionController::class, 'store']);
    Route::put('player-positions/{id}', [PlayerPositionController::class, 'update']);
    Route::get('tactics/{id}/positions', [PlayerPositionController::class, 'getTacticPositions']);
    Route::post('tactic-slot-positions', [TacticSlotPositionController::class, 'store']);
    Route::get('tactics/{id}/slot-positions', [TacticSlotPositionController::class, 'getTacticPositions']);

    // NOUVEAU : Instructions tactiques (Bloc B, etc.)
    Route::post('tactical-instructions', [TacticalInstructionController::class, 'store']);
    Route::delete('tactical-instructions/{tacticalInstruction}', [TacticalInstructionController::class, 'destroy']);
    Route::get('tactics/{id}/instructions', [TacticalInstructionController::class, 'getByTactic']);

    // 11. Séances d'entraînement
    Route::apiResource('training-sessions', TrainingSessionController::class);
});

Route::get('/test', function () {
    return response()->json(['message' => 'API is working']);
});


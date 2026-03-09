<?php
use App\Http\Controllers\Api\AuthController;

Route::post('/register',[AuthController::class,'register']);
Route::post('/login',[AuthController::class,'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout',[AuthController::class,'logout']);
});

Route::get('/test', function () {
    return "API working";
});

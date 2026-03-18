<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Team;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    private function profilePayload(User $user): array
    {
        $team = $user->team;

        return [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'team' => $team ? [
                'id' => $team->id,
                'name' => $team->name,
            ] : null,
            'stats' => [
                'total_players' => $team ? $team->players()->count() : 0,
                'total_tactics' => $team ? $team->tactics()->count() : 0,
                'total_training_sessions' => $team ? $team->trainingSessions()->count() : 0,
                'total_starters' => $team ? $team->players()->where('role', 'starter')->count() : 0,
                'total_substitutes' => $team ? $team->players()->where('role', 'substitute')->count() : 0,
            ],
        ];
    }


    public function register(Request $request)
    {
        $request->validate([
            'name'=>'required',
            'email'=>'required|email|unique:users',
            'password'=>'required|min:6',
            'team_name' => 'required|string|max:255',
        ]);

        $user = DB::transaction(function () use ($request) {
            $user = User::create([
                'name'=>$request->name,
                'email'=>$request->email,
                'password'=>Hash::make($request->password)
            ]);

            Team::create([
                'name' => $request->team_name,
                'coach_id' => $user->id,
            ]);

            return $user;
        });

        $token = $user->createToken("api_token")->plainTextToken;

        return response()->json([
            "user"=>$user,
            "token"=>$token
        ]);
    }

    public function login(Request $request)
    {
        if(!Auth::attempt($request->only('email','password'))){
            return response()->json([
                "message"=>"Invalid credentials"
            ],401);
        }

        $user = Auth::user();

        $token = $user->createToken("api_token")->plainTextToken;

        return response()->json([
            "user"=>$user,
            "token"=>$token
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            "message"=>"Logged out"
        ]);
    }

    public function profile(Request $request)
    {
        $user = $request->user()->load('team');

        return response()->json([
            'message' => 'Profile retrieved',
            'data' => $this->profilePayload($user),
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => [
                'sometimes',
                'required',
                'email',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'team_name' => 'sometimes|required|string|max:255',
        ]);

        DB::transaction(function () use ($user, $validated) {
            $userData = [];
            if (array_key_exists('name', $validated)) {
                $userData['name'] = $validated['name'];
            }
            if (array_key_exists('email', $validated)) {
                $userData['email'] = $validated['email'];
            }
            if (!empty($userData)) {
                $user->update($userData);
            }

            if (array_key_exists('team_name', $validated)) {
                $team = $user->team;
                if ($team) {
                    $team->update(['name' => $validated['team_name']]);
                } else {
                    Team::create([
                        'name' => $validated['team_name'],
                        'coach_id' => $user->id,
                    ]);
                }
            }
        });

        $freshUser = $user->fresh()->load('team');

        return response()->json([
            'message' => 'Profile updated',
            'data' => $this->profilePayload($freshUser),
        ]);
    }
}

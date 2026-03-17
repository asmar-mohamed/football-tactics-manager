<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Team;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{

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
}

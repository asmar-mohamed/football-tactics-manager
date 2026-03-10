<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePlayerPositionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'player_id' => 'required|exists:players,id',
            'tactic_id' => 'required|exists:tactics,id',
            'x_position' => 'required|numeric',
            'y_position' => 'required|numeric',
        ];
    }
}

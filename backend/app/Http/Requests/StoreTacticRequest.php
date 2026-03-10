<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTacticRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'formation' => 'required|string|max:50',
            'team_id' => 'required|exists:teams,id',
            'positions' => 'sometimes|array',
            'positions.*.player_id' => 'required|exists:players,id',
            'positions.*.x_position' => 'required|numeric',
            'positions.*.y_position' => 'required|numeric',
        ];
    }
}

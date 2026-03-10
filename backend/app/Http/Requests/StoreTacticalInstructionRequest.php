<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTacticalInstructionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tactic_id' => 'required|exists:tactics,id',
            'title' => 'required|string|max:255',
            'description' => 'sometimes|nullable|string',
            'player_ids' => 'required|array',
            'player_ids.*' => 'exists:players,id',
        ];
    }
}

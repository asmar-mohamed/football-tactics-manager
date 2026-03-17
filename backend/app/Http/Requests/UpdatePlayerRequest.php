<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePlayerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $player = $this->route('player');
        $playerId = is_object($player) ? $player->id : $player;
        $teamId = $this->input('team_id', is_object($player) ? $player->team_id : null);

        return [
            'name' => 'sometimes|required|string|max:255',
            'number' => [
                'sometimes',
                'required',
                'integer',
                Rule::unique('players', 'number')
                    ->where(fn ($query) => $query->where('team_id', $teamId))
                    ->ignore($playerId),
            ],
            'position' => 'sometimes|required|string|max:100',
            'role' => 'sometimes|required|in:starter,substitute',
            'team_id' => 'sometimes|required|exists:teams,id',
            'category_id' => 'sometimes|nullable|exists:categories,id',
        ];
    }
}

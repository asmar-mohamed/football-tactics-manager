<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePlayerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'number' => [
                'required',
                'integer',
                Rule::unique('players', 'number')->where(
                    fn ($query) => $query->where('team_id', $this->input('team_id'))
                ),
            ],
            'position' => 'required|string|max:100',
            'role' => 'required|in:starter,substitute',
            'team_id' => 'required|exists:teams,id',
            'category_id' => 'nullable|exists:categories,id',
        ];
    }
}

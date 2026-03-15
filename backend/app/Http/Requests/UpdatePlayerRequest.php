<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePlayerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'sometimes|required|string|max:255',
            'number' => 'sometimes|required|integer',
            'position' => 'sometimes|required|string|max:100',
            'team_id' => 'sometimes|required|exists:teams,id',
            'category_id' => 'sometimes|required|exists:categories,id',
        ];
    }
}

<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTacticSlotPositionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tactic_id' => 'required|exists:tactics,id',
            'slot_index' => 'required|integer|min:1|max:11',
            'x_position' => 'required|numeric|between:0,1',
            'y_position' => 'required|numeric|between:0,1',
        ];
    }
}

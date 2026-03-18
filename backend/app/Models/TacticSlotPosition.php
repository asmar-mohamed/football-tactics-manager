<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TacticSlotPosition extends Model
{
    use HasFactory;

    protected $fillable = ['tactic_id', 'slot_index', 'x_position', 'y_position'];

    public function tactic()
    {
        return $this->belongsTo(Tactic::class);
    }
}

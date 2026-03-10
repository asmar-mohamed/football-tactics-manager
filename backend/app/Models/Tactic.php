<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Tactic extends Model
{
    protected $fillable = ['name', 'formation', 'team_id', 'is_default'];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }

    public function playerPositions()
    {
        return $this->hasMany(PlayerPosition::class);
    }

    public function tacticalInstructions()
    {
        return $this->hasMany(TacticalInstruction::class);
    }
}

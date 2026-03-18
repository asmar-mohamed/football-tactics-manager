<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Tactic extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'formation', 'team_id', 'is_default'];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }

    public function playerPositions()
    {
        return $this->hasMany(PlayerPosition::class);
    }

    public function slotPositions()
    {
        return $this->hasMany(TacticSlotPosition::class);
    }

    public function tacticalInstructions()
    {
        return $this->hasMany(TacticalInstruction::class);
    }
}

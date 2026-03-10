<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TacticalInstruction extends Model
{
    protected $fillable = ['tactic_id', 'title', 'description'];

    public function tactic()
    {
        return $this->belongsTo(Tactic::class);
    }

    public function players()
    {
        return $this->belongsToMany(Player::class, 'instruction_player');
    }
}

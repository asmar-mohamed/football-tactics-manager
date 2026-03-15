<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class TacticalInstruction extends Model
{
    use HasFactory;

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

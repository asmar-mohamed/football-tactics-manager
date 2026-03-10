<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlayerPosition extends Model
{
    protected $fillable = ['player_id', 'tactic_id', 'x_position', 'y_position'];

    public function player()
    {
        return $this->belongsTo(Player::class);
    }

    public function tactic()
    {
        return $this->belongsTo(Tactic::class);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Player extends Model
{
    protected $fillable = ['name', 'number', 'position', 'team_id'];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }

    public function positions()
    {
        return $this->hasMany(PlayerPosition::class);
    }
}

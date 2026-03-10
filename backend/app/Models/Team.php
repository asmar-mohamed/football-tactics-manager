<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Team extends Model
{
    protected $fillable = ['name', 'coach_id'];

    public function coach()
    {
        return $this->belongsTo(User::class, 'coach_id');
    }

    public function players()
    {
        return $this->hasMany(Player::class);
    }

    public function tactics()
    {
        return $this->hasMany(Tactic::class);
    }

    public function trainingSessions()
    {
        return $this->hasMany(TrainingSession::class);
    }
}

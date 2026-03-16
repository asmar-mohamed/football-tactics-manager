<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Player extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'number', 'position', 'role', 'team_id', 'category_id'];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }

    public function positions()
    {
        return $this->hasMany(PlayerPosition::class);
    }

    public function tacticalInstructions()
    {
        return $this->belongsToMany(TacticalInstruction::class, 'instruction_player');
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}

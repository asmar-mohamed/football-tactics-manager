<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrainingSession extends Model
{
    protected $fillable = ['title', 'description', 'team_id', 'date'];

    protected $casts = [
        'date' => 'datetime',
    ];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }
}

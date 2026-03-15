<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class TrainingSession extends Model
{
    use HasFactory;

    protected $fillable = ['title', 'description', 'team_id', 'date'];

    protected $casts = [
        'date' => 'datetime',
    ];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }
}

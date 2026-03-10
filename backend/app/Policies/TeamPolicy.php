<?php

namespace App\Policies;

use App\Models\Team;
use App\Models\User;

class TeamPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // Users can only see their own via controller logic
    }

    public function view(User $user, Team $team): bool
    {
        return $user->id === $team->coach_id;
    }

    public function create(User $user): bool
    {
        return true; // Any authenticated user can create a team
    }

    public function update(User $user, Team $team): bool
    {
        return $user->id === $team->coach_id;
    }

    public function delete(User $user, Team $team): bool
    {
        return $user->id === $team->coach_id;
    }
}

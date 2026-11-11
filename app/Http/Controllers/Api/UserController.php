<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Afficher les utilisateurs
     * 
     * Affichage de l’ensemble des utilisateurs
    */
    public function index()
    {
        return response()->json(User::orderBy('nom')->get());
    }

    /**
     * Ajouter un utilisateur
     * 
     * Ajout d’un utilisateur
    */
   public function store(Request $request)
    {
        $data = $request->validate([
            'nom'      => ['required', 'string', 'max:100'],
            'prenom'   => ['required', 'string', 'max:100'],
            'email'    => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'role'     => ['required', Rule::in(User::ROLES)],
        ]);

        $user = User::create($data);

        return response()->json($user, 201);
    }

    /**
     * Afficher un utilisateur
     * 
     * Affichage en détail d’un utilisateur
    */
    public function show(User $user)
    {
        return response()->json($user);
    }

    /**
     * Modifier un utilisateur
     * 
     * Modification des informations d’un utilisateur
    */
    public function update(Request $request, User $user)
    {
        // "sometimes" = on ne valide que quand le champ est envoyé
        $data = $request->validate([
            'nom'      => ['sometimes', 'required', 'string', 'max:100'],
            'prenom'   => ['sometimes', 'required', 'string', 'max:100'],
            'email'    => ['sometimes', 'required', 'email', Rule::unique('users', 'email')->ignore($user)],
            'password' => ['sometimes', 'required', 'string', 'min:6'],
            'role'     => ['sometimes', 'required', Rule::in(User::ROLES)],
        ]);

        $user->update($data);

        // Mot de passe changé par l'admin : les anciens tokens du collecteur
        // sont supprimés → il est déconnecté de tous ses téléphones et doit
        // se reconnecter avec le nouveau mot de passe.
        if (array_key_exists('password', $data)) {
            $user->tokens()->delete();
        }

        return response()->json($user);
    }

    /**
     * Supprimer un utilisateur
     * 
     * Suppression d’un utilisateur
    */
    public function destroy(Request $request, User $user)
    {
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Tu ne peux pas supprimer ton propre compte.'], 422);
        }

        if ($user->signalements()->exists()) {
            return response()->json(['message' => 'Cet utilisateur a des signalements, suppression impossible.'], 409);
        }

        $user->delete();

        return response()->json(null, 204);
    }
}

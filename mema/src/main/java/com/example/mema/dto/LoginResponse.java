package com.example.mema.dto;

public record LoginResponse(
        String token,
        UtilisateurResponse utilisateur,
        String pharmacieNom,
        long expireDansSecondes
) {}
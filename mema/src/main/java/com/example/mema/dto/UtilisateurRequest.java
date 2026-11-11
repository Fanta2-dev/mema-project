package com.example.mema.dto;

public record UtilisateurRequest(
        Long pharmacieId,
        String nom,
        String telephone,
        String motDePasse,
        String role
) {}
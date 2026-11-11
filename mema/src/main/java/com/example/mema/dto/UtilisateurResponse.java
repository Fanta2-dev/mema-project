package com.example.mema.dto;

public record UtilisateurResponse(
        Long id,
        Long pharmacieId,
        String nom,
        String telephone,
        String role
) {}
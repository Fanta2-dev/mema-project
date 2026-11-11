package com.example.mema.dto;

public record InscriptionRequest(
        String pharmacieNom,
        String pharmacieAdresse,
        Double latitude,
        Double longitude,
        String pharmacieTelephone,
        String numeroAgrement,
        String responsableNom,
        String responsableTelephone,
        String motDePasse
) {}
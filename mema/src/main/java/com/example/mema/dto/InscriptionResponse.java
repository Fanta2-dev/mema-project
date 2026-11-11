package com.example.mema.dto;

import java.time.LocalDateTime;

public record InscriptionResponse(
        Long id,
        String pharmacieNom,
        String pharmacieAdresse,
        Double latitude,
        Double longitude,
        String pharmacieTelephone,
        String numeroAgrement,
        String responsableNom,
        String responsableTelephone,
        String statut,
        String motifRefus,
        LocalDateTime dateDemande
) {}
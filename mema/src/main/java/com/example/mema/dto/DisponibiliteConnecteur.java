package com.example.mema.dto;

import java.time.LocalDateTime;

public record DisponibiliteConnecteur(
        Long medicamentId,
        String medicament,
        String statut,
        String source,
        LocalDateTime dateMiseAJour,
        boolean aVerifier
) {}
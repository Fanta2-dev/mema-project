package com.example.mema.dto;

import java.util.List;

/** resultat : OK si toutes les lignes sont acceptées, PARTIEL si certaines sont refusées. */
public record ResultatConnecteur(
        String resultat,
        int recues,
        int misesAJour,
        List<String> erreurs
) {}
package com.example.mema.dto;

import com.example.mema.model.Medicament;
import com.example.mema.model.Pharmacie;

import java.time.LocalDateTime;

/** Ce que voit le public : jamais la quantité exacte. */
public record StockPublicResponse(
        Long id,
        Pharmacie pharmacie,
        Medicament medicament,
        boolean disponible,
        String statut,
        boolean aVerifier,
        Double prix,
        LocalDateTime dateMiseAJour
) {}
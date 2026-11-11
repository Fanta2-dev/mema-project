package com.example.mema.dto;

public record StockRequest(
        Long pharmacieId,
        Long medicamentId,
        Boolean disponible,
        Integer quantite,
        Double prix
) {}
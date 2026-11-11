package com.example.mema.dto;

/** Une ligne envoyée par le connecteur : un médicament et son statut. */
public record LigneDisponibilite(
        Long medicamentId,
        String statut
) {}
package com.example.mema.dto;

import java.util.List;

public record ResumeRecherches(
        int jours,
        int totalRecherches,
        int sansResultat,
        List<Terme> plusRecherches,
        List<Terme> plusRecherchesSansResultat
) {
    public record Terme(String terme, long nombre) {}
}
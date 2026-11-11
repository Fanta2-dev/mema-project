package com.example.mema.dto;

import java.util.List;

public record ResultatImport(
        int lignesLues,
        int stocksMisAJour,
        int stocksCrees,
        int stocksMisEnRupture,
        boolean remplacementApplique,
        List<String> medicamentsInconnus,
        int demandesEnregistrees,
        List<String> erreurs
) {}
package com.example.mema.dto;

import java.util.List;

public record ResultatCatalogue(
        int lignesLues,
        int medicamentsCrees,
        int medicamentsMisAJour,
        int doublonsIgnores,
        int demandesFermees,
        List<String> erreurs
) {}
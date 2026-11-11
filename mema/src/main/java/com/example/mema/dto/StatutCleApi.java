package com.example.mema.dto;

import java.time.LocalDateTime;

public record StatutCleApi(
        boolean existe,
        boolean active,
        String prefixe,
        LocalDateTime dateCreation,
        LocalDateTime derniereUtilisation
) {}
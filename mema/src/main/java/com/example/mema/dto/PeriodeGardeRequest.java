package com.example.mema.dto;

import java.time.LocalDateTime;

public record PeriodeGardeRequest(
        Long pharmacieId,
        String zone,
        LocalDateTime dateDebut,
        LocalDateTime dateFin,
        String source
) {}
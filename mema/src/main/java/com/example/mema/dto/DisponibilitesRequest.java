package com.example.mema.dto;

import java.util.List;

public record DisponibilitesRequest(
        List<LigneDisponibilite> disponibilites
) {}
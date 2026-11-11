package com.example.mema.dto;

public record LoginRequest(
        String telephone,
        String motDePasse
) {}
package com.example.mema.dto;

public record AlerteRequest(
        Long medicamentId,
        Long pharmacieId,
        String telephonePatient
) {}
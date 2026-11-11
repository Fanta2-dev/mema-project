package com.example.mema.util;

public class TelephoneUtils {

    private static final String INDICATIF = "+221";

    public static String normaliserEtValider(String saisi) {
        if (saisi == null || saisi.isBlank()) {
            throw new IllegalArgumentException("Le numéro de téléphone est obligatoire.");
        }

        String nettoye = saisi.replaceAll("[^0-9+]", "");

        if (nettoye.startsWith("+221")) {
            nettoye = nettoye.substring(4);
        } else if (nettoye.startsWith("00221")) {
            nettoye = nettoye.substring(5);
        } else if (nettoye.startsWith("221") && nettoye.length() > 9) {
            nettoye = nettoye.substring(3);
        } else if (nettoye.startsWith("0")) {
            nettoye = nettoye.substring(1);
        }

        if (!nettoye.matches("[37]\\d{8}")) {
            throw new IllegalArgumentException(
                    "Numéro invalide : un numéro sénégalais doit contenir 9 chiffres et commencer par 7 (mobile) ou 3 (fixe). Reçu : " + saisi
            );
        }

        return INDICATIF + nettoye;
    }
}
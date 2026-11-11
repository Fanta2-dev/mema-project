package com.example.mema.util;

import java.text.Normalizer;
import java.util.Locale;

public final class Textes {

    private Textes() {}

    /** "  Inéxium 20MG " devient "inexium 20mg" : sert à comparer des noms écrits différemment. */
    public static String normaliser(String s) {
        if (s == null) {
            return "";
        }
        String sansAccents = Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        return sansAccents.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", " ").trim();
    }

    /** Sans espaces ni ponctuation : "40 mg, comprimé" devient "40mgcomprime". */
    public static String compact(String s) {
        return normaliser(s).replace(" ", "");
    }
}
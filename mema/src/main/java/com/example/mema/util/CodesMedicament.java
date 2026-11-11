package com.example.mema.util;

import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class CodesMedicament {

    private static final Pattern NOMBRE = Pattern.compile("\\d+(?:[.,]\\d+)?");
    private static final int LONGUEUR_MAX = 70;

    private CodesMedicament() {}

    /** Code saisi à la main : majuscules, espaces remplacés par des soulignés. Null si vide. */
    public static String normaliser(String code) {
        if (code == null) {
            return null;
        }
        String propre = Textes.normaliser(code).toUpperCase(Locale.ROOT).replace(' ', '_');
        return propre.isEmpty() ? null : propre;
    }

    /**
     * Génère un code lisible : ("Paracétamol", "500 mg, comprimé") donne PARACETAMOL_500.
     * En cas de doublon, ajoute _2, _3... Le code obtenu est ajouté à "dejaUtilises".
     */
    public static String generer(String nom, String dosage, Set<String> dejaUtilises) {
        String base = normaliser(nom);
        if (base == null) {
            base = "MEDICAMENT";
        }
        Matcher m = NOMBRE.matcher(dosage == null ? "" : dosage);
        String code = m.find() ? base + "_" + m.group().replace(',', '_').replace('.', '_') : base;
        if (code.length() > LONGUEUR_MAX) {
            code = code.substring(0, LONGUEUR_MAX);
        }
        String candidat = code;
        int n = 2;
        while (dejaUtilises.contains(candidat)) {
            candidat = code + "_" + n;
            n++;
        }
        dejaUtilises.add(candidat);
        return candidat;
    }
}
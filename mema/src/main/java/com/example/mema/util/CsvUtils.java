package com.example.mema.util;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;
import org.apache.commons.csv.DuplicateHeaderMode;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.List;

public final class CsvUtils {

    private CsvUtils() {}

    /** UTF-8 si le fichier en est un, sinon Windows-1252 (Excel français). Retire le BOM éventuel. */
    public static String lireTexte(byte[] octets) {
        String texte;
        try {
            texte = StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(octets))
                    .toString();
        } catch (CharacterCodingException e) {
            texte = new String(octets, Charset.forName("windows-1252"));
        }
        return texte.startsWith("\uFEFF") ? texte.substring(1) : texte;
    }

    /** Format CSV avec séparateur détecté (point-virgule, virgule ou tabulation). */
    public static CSVFormat format(String texte) {
        return CSVFormat.DEFAULT.builder()
                .setDelimiter(detecterDelimiteur(texte))
                .setHeader()
                .setSkipHeaderRecord(true)
                .setTrim(true)
                .setAllowMissingColumnNames(true)
                .setDuplicateHeaderMode(DuplicateHeaderMode.ALLOW_ALL)
                .build();
    }

    private static char detecterDelimiteur(String texte) {
        String premiere = texte.lines().findFirst().orElse("");
        long pointsVirgules = premiere.chars().filter(c -> c == ';').count();
        long tabulations = premiere.chars().filter(c -> c == '\t').count();
        long virgules = premiere.chars().filter(c -> c == ',').count();
        if (tabulations > pointsVirgules && tabulations >= virgules) {
            return '\t';
        }
        if (virgules > pointsVirgules) {
            return ',';
        }
        return ';';
    }

    /** Retrouve, parmi les colonnes du fichier, celle dont le nom (nettoyé) fait partie des noms acceptés. */
    public static String trouverColonne(List<String> entetes, List<String> possibles) {
        for (String entete : entetes) {
            if (entete != null && possibles.contains(Textes.normaliser(entete))) {
                return entete;
            }
        }
        return null;
    }

    /** Valeur d'une cellule, ou null si la colonne n'existe pas ou si la ligne est trop courte. */
    public static String valeur(CSVRecord ligne, String colonne) {
        if (colonne == null || !ligne.isSet(colonne)) {
            return null;
        }
        return ligne.get(colonne);
    }
}
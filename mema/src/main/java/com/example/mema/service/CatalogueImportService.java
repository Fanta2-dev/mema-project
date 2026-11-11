package com.example.mema.service;

import com.example.mema.dto.ResultatCatalogue;
import com.example.mema.model.Medicament;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.util.CodesMedicament;
import com.example.mema.util.CsvUtils;
import com.example.mema.util.Textes;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Ajoute des médicaments au catalogue commun depuis un CSV.
 * Colonnes : nom (obligatoire), dci, dosage, categorie, code, top100.
 * Un médicament = un nom + un dosage. Si le code est absent, il est généré.
 */
@Service
public class CatalogueImportService {

    private static final List<String> NOMS_NOM =
            List.of("nom", "designation", "produit", "libelle", "medicament");
    private static final List<String> NOMS_DCI = List.of("dci", "principe actif", "molecule");
    private static final List<String> NOMS_DOSAGE = List.of("dosage", "forme", "conditionnement");
    private static final List<String> NOMS_CATEGORIE = List.of("categorie", "famille", "classe");
    private static final List<String> NOMS_CODE = List.of("code", "code produit", "code mema");
    private static final List<String> NOMS_TOP100 = List.of("top100", "top 100");

    @Autowired
    private MedicamentRepository medicamentRepository;

    @Autowired
    private DemandeMedicamentService demandeService;

    @Transactional
    public ResultatCatalogue importer(MultipartFile fichier) throws IOException {
        if (fichier == null || fichier.isEmpty()) {
            throw new IllegalArgumentException("Le fichier est vide.");
        }
        String texte = CsvUtils.lireTexte(fichier.getBytes());

        Map<String, Medicament> existants = new HashMap<>();
        Set<String> codes = new HashSet<>();
        for (Medicament m : medicamentRepository.findAll()) {
            existants.put(cle(m.getNom(), m.getDosage()), m);
            if (m.getCode() != null) {
                codes.add(m.getCode());
            }
        }

        int lues = 0;
        int crees = 0;
        int misAJour = 0;
        int doublons = 0;
        List<String> erreurs = new ArrayList<>();
        Set<String> nomsCrees = new HashSet<>();

        try (CSVParser parser = CsvUtils.format(texte).parse(new StringReader(texte))) {
            List<String> entetes = parser.getHeaderNames();
            String colNom = CsvUtils.trouverColonne(entetes, NOMS_NOM);
            String colDci = CsvUtils.trouverColonne(entetes, NOMS_DCI);
            String colDosage = CsvUtils.trouverColonne(entetes, NOMS_DOSAGE);
            String colCategorie = CsvUtils.trouverColonne(entetes, NOMS_CATEGORIE);
            String colCode = CsvUtils.trouverColonne(entetes, NOMS_CODE);
            String colTop100 = CsvUtils.trouverColonne(entetes, NOMS_TOP100);
            if (colNom == null) {
                throw new IllegalArgumentException(
                        "Colonne « nom » introuvable. Colonnes attendues : nom, dci, dosage, categorie, "
                                + "code (facultative), top100 (facultative).");
            }

            for (CSVRecord ligne : parser) {
                lues++;
                try {
                    String nom = CsvUtils.valeur(ligne, colNom);
                    if (nom == null || nom.isBlank()) {
                        throw new IllegalArgumentException("nom du médicament vide");
                    }
                    String dosage = vide(CsvUtils.valeur(ligne, colDosage)) ? "Non précisé"
                            : CsvUtils.valeur(ligne, colDosage);
                    String categorie = vide(CsvUtils.valeur(ligne, colCategorie)) ? "Non précisée"
                            : CsvUtils.valeur(ligne, colCategorie);
                    String dci = CsvUtils.valeur(ligne, colDci);
                    Boolean top = colTop100 == null ? null : lireOuiNon(CsvUtils.valeur(ligne, colTop100));

                    String cleLigne = cle(nom, dosage);
                    Medicament deja = existants.get(cleLigne);
                    if (deja != null) {
                        // Déjà au catalogue : on ne le recrée pas, mais on met à jour le TOP 100 si le fichier le précise.
                        if (top != null && !top.equals(deja.getTop100())) {
                            deja.setTop100(top);
                            medicamentRepository.save(deja);
                            misAJour++;
                        } else {
                            doublons++;
                        }
                        continue;
                    }

                    Medicament m = new Medicament();
                    m.setNom(nom.trim());
                    m.setDci(vide(dci) ? null : dci.trim());
                    m.setDosage(dosage.trim());
                    m.setCategorie(categorie.trim());

                    String codeFichier = CodesMedicament.normaliser(CsvUtils.valeur(ligne, colCode));
                    if (codeFichier != null) {
                        if (!codes.add(codeFichier)) {
                            throw new IllegalArgumentException("code déjà utilisé : " + codeFichier);
                        }
                        m.setCode(codeFichier);
                    } else {
                        m.setCode(CodesMedicament.generer(nom, dosage, codes));
                    }
                    m.setTop100(top != null && top);

                    medicamentRepository.save(m);
                    existants.put(cleLigne, m);
                    nomsCrees.add(Textes.normaliser(nom));
                    crees++;
                } catch (Exception e) {
                    erreurs.add("Ligne " + (lues + 1) + " : " + e.getMessage());
                }
            }
        }

        int demandesFermees = demandeService.marquerTraiteesSiConnues(nomsCrees);
        return new ResultatCatalogue(lues, crees, misAJour, doublons, demandesFermees, erreurs);
    }

    private boolean vide(String s) {
        return s == null || s.isBlank();
    }

    /** oui, o, 1, true, vrai, x, yes donnent vrai ; une cellule vide donne null (pas d'information). */
    private Boolean lireOuiNon(String brut) {
        if (brut == null || brut.isBlank()) {
            return null;
        }
        String v = Textes.normaliser(brut);
        return v.equals("oui") || v.equals("o") || v.equals("1") || v.equals("true")
                || v.equals("vrai") || v.equals("x") || v.equals("yes");
    }

    private String cle(String nom, String dosage) {
        return Textes.normaliser(nom) + "|" + Textes.compact(dosage);
    }
}
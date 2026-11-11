package com.example.mema.service;

import com.example.mema.dto.ResultatImport;
import com.example.mema.model.Medicament;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.Stock;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.repository.StockRepository;
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
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Lit un fichier CSV exporté du logiciel (ou d'Excel) d'une pharmacie et met à jour SON stock.
 * Colonnes reconnues (peu importe l'ordre) : nom / désignation / produit, quantité / qté / stock,
 * prix / prix de vente / pv, et dosage (facultatif, utile quand un nom existe en plusieurs dosages).
 * Séparateur et encodage détectés automatiquement.
 */
@Service
public class StockImportService {

    private static final List<String> NOMS_NOM =
            List.of("nom", "designation", "produit", "libelle", "medicament", "article");
    private static final List<String> NOMS_QUANTITE =
            List.of("quantite", "qte", "qt", "stock", "quantite en stock");
    private static final List<String> NOMS_PRIX =
            List.of("prix", "prix de vente", "prix vente", "pv", "tarif");
    private static final List<String> NOMS_DOSAGE = List.of("dosage");

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private PharmacieRepository pharmacieRepository;

    @Autowired
    private MedicamentRepository medicamentRepository;

    @Autowired
    private DemandeMedicamentService demandeService;

    @Autowired
    private JournalService journal;

    @Transactional
    public ResultatImport importerCsv(Long pharmacieId, MultipartFile fichier, boolean remplacer,
                                      Long utilisateurId) throws IOException {
        Pharmacie pharmacie = pharmacieRepository.findById(pharmacieId)
                .orElseThrow(() -> new IllegalArgumentException("Pharmacie introuvable : " + pharmacieId));
        if (fichier == null || fichier.isEmpty()) {
            throw new IllegalArgumentException("Le fichier est vide.");
        }

        String texte = CsvUtils.lireTexte(fichier.getBytes());

        // Catalogue indexé par nom nettoyé : une liste, car un nom peut exister en plusieurs dosages.
        Map<String, List<Medicament>> parNom = new HashMap<>();
        for (Medicament m : medicamentRepository.findAll()) {
            parNom.computeIfAbsent(Textes.normaliser(m.getNom()), cle -> new ArrayList<>()).add(m);
        }

        int lues = 0;
        int misAJour = 0;
        int crees = 0;
        List<String> erreurs = new ArrayList<>();
        Set<Long> touches = new HashSet<>();
        Map<String, String> inconnus = new LinkedHashMap<>();

        try (CSVParser parser = CsvUtils.format(texte).parse(new StringReader(texte))) {
            List<String> entetes = parser.getHeaderNames();
            String colNom = CsvUtils.trouverColonne(entetes, NOMS_NOM);
            String colQuantite = CsvUtils.trouverColonne(entetes, NOMS_QUANTITE);
            String colPrix = CsvUtils.trouverColonne(entetes, NOMS_PRIX);
            String colDosage = CsvUtils.trouverColonne(entetes, NOMS_DOSAGE);
            if (colNom == null || colQuantite == null || colPrix == null) {
                throw new IllegalArgumentException(
                        "Colonnes introuvables. La première ligne du fichier doit contenir : "
                                + "nom, quantité, prix.");
            }

            for (CSVRecord ligne : parser) {
                lues++;
                try {
                    String nom = CsvUtils.valeur(ligne, colNom);
                    if (nom == null || nom.isBlank()) {
                        throw new IllegalArgumentException("nom du médicament vide");
                    }
                    int quantite = lireQuantite(CsvUtils.valeur(ligne, colQuantite));
                    double prix = lirePrix(CsvUtils.valeur(ligne, colPrix));

                    Medicament medicament = trouverMedicament(nom, CsvUtils.valeur(ligne, colDosage), parNom);
                    if (medicament == null) {
                        inconnus.putIfAbsent(Textes.normaliser(nom), nom.trim());
                        throw new IllegalArgumentException("médicament inconnu « " + nom + " »");
                    }

                    Optional<Stock> existant = stockRepository
                            .findByPharmacieIdAndMedicamentId(pharmacieId, medicament.getId());
                    Stock stock = existant.orElseGet(Stock::new);
                    if (existant.isPresent()) {
                        misAJour++;
                    } else {
                        stock.setPharmacie(pharmacie);
                        stock.setMedicament(medicament);
                        crees++;
                    }
                    stock.setQuantite(Math.max(0, quantite));
                    stock.setPrix(prix);
                    stock.setDisponible(quantite > 0);
                    stock.setSurCommande(false);
                    stock.setSource(Stock.SOURCE_IMPORT);
                    stock.setDateMiseAJour(LocalDateTime.now());
                    Stock sauvegarde = stockRepository.save(stock);
                    touches.add(sauvegarde.getId());
                } catch (Exception e) {
                    erreurs.add("Ligne " + (lues + 1) + " : " + e.getMessage());
                }
            }
        }

        // Les noms inconnus sont signalés à l'administrateur, sans doublon.
        int demandes = inconnus.isEmpty() ? 0 : demandeService.enregistrer(pharmacie, inconnus.values());

        // Option "tout ce qui n'est pas dans le fichier passe en rupture".
        // Jamais appliquée si le fichier contient une erreur : un nom mal reconnu
        // ferait passer à tort un médicament en rupture.
        int enRupture = 0;
        boolean remplacementApplique = false;
        if (remplacer && erreurs.isEmpty() && (misAJour + crees) > 0) {
            LocalDateTime maintenant = LocalDateTime.now();
            for (Stock s : stockRepository.findByPharmacieId(pharmacieId)) {
                boolean absentDuFichier = !touches.contains(s.getId());
                boolean considereDisponible = (s.getQuantite() != null && s.getQuantite() > 0)
                        || Boolean.TRUE.equals(s.getDisponible());
                if (absentDuFichier && considereDisponible) {
                    s.setQuantite(0);
                    s.setDisponible(false);
                    s.setSurCommande(false);
                    s.setSource(Stock.SOURCE_IMPORT);
                    s.setDateMiseAJour(maintenant);
                    stockRepository.save(s);
                    enRupture++;
                }
            }
            remplacementApplique = true;
        }

        journal.enregistrer(pharmacieId, utilisateurId, "IMPORT_STOCK",
                lues + " ligne(s) lue(s), " + misAJour + " mise(s) à jour, " + crees + " ajoutée(s), "
                        + erreurs.size() + " erreur(s)"
                        + (remplacementApplique ? ", " + enRupture + " mise(s) en rupture" : ""));

        return new ResultatImport(lues, misAJour, crees, enRupture, remplacementApplique,
                new ArrayList<>(inconnus.values()), demandes, erreurs);
    }

    /**
     * Retrouve le médicament du catalogue. Renvoie null si le nom est inconnu.
     * Si le nom existe en plusieurs dosages, le dosage du fichier doit correspondre EXACTEMENT
     * à l'un d'eux : on ne devine jamais.
     */
    private Medicament trouverMedicament(String nom, String dosageFichier,
                                         Map<String, List<Medicament>> parNom) {
        List<Medicament> candidats = parNom.get(Textes.normaliser(nom));
        if (candidats == null || candidats.isEmpty()) {
            return null;
        }
        if (candidats.size() == 1) {
            return candidats.get(0);
        }
        if (dosageFichier != null && !dosageFichier.isBlank()) {
            String voulu = Textes.compact(dosageFichier);
            List<Medicament> correspondants = new ArrayList<>();
            for (Medicament m : candidats) {
                if (Textes.compact(m.getDosage()).equals(voulu)) {
                    correspondants.add(m);
                }
            }
            if (correspondants.size() == 1) {
                return correspondants.get(0);
            }
        }
        List<String> dosages = new ArrayList<>();
        for (Medicament m : candidats) {
            dosages.add(m.getDosage());
        }
        throw new IllegalArgumentException("plusieurs dosages possibles pour « " + nom + " » ("
                + String.join(" / ", dosages)
                + "). Ajoutez une colonne « dosage » avec la valeur exacte.");
    }

    private int lireQuantite(String brut) {
        if (brut == null) {
            throw new IllegalArgumentException("quantité manquante");
        }
        try {
            String propre = brut.replaceAll("[\\s\\u00A0]", "").replace(',', '.');
            return (int) Math.round(Double.parseDouble(propre));
        } catch (RuntimeException e) {
            throw new IllegalArgumentException("quantité invalide « " + brut + " »");
        }
    }

    private double lirePrix(String brut) {
        if (brut == null) {
            throw new IllegalArgumentException("prix manquant");
        }
        try {
            String propre = brut.replaceAll("[\\s\\u00A0]", "").replace(',', '.');
            double prix = Double.parseDouble(propre);
            if (prix < 0) {
                throw new IllegalArgumentException("prix négatif");
            }
            return prix;
        } catch (RuntimeException e) {
            throw new IllegalArgumentException("prix invalide « " + brut + " »");
        }
    }
}
package com.example.mema.service;

import com.example.mema.dto.DisponibiliteConnecteur;
import com.example.mema.dto.LigneDisponibilite;
import com.example.mema.dto.ResultatConnecteur;
import com.example.mema.model.Medicament;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.Stock;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.repository.StockRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/** Reçoit les statuts envoyés par le connecteur d'une pharmacie (jamais de quantité). */
@Service
public class ConnecteurService {

    private static final int MAX_LIGNES = 500;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private MedicamentRepository medicamentRepository;

    @Autowired
    private JournalService journal;

    @Transactional
    public ResultatConnecteur appliquer(Pharmacie pharmacie, List<LigneDisponibilite> lignes) {
        if (lignes == null || lignes.isEmpty()) {
            throw new IllegalArgumentException("Aucune disponibilité reçue.");
        }
        if (lignes.size() > MAX_LIGNES) {
            throw new IllegalArgumentException(
                    "Trop de lignes dans une même requête (" + MAX_LIGNES + " au maximum). Envoyez plusieurs requêtes.");
        }

        int misesAJour = 0;
        List<String> erreurs = new ArrayList<>();
        List<String> changements = new ArrayList<>();

        for (int i = 0; i < lignes.size(); i++) {
            LigneDisponibilite ligne = lignes.get(i);
            try {
                if (ligne == null || ligne.medicamentId() == null) {
                    throw new IllegalArgumentException("medicamentId manquant");
                }
                String statut = ligne.statut() == null ? "" : ligne.statut().trim().toUpperCase();
                Medicament medicament = medicamentRepository.findById(ligne.medicamentId())
                        .orElseThrow(() -> new IllegalArgumentException(
                                "médicament inconnu (id " + ligne.medicamentId() + ")"));

                Optional<Stock> existant = stockRepository
                        .findByPharmacieIdAndMedicamentId(pharmacie.getId(), medicament.getId());
                Stock stock = existant.orElseGet(() -> nouveauStock(pharmacie, medicament));
                String avant = existant.isPresent() ? stock.calculerStatut() : null;

                appliquerStatut(stock, statut);
                stockRepository.save(stock);
                misesAJour++;

                if (!statut.equals(avant)) {
                    changements.add(medicament.getNom() + " : " + (avant == null ? "nouveau" : avant) + " -> " + statut);
                }
            } catch (IllegalArgumentException e) {
                erreurs.add("Ligne " + (i + 1) + " : " + e.getMessage());
            }
        }

        if (!changements.isEmpty()) {
            journal.enregistrer(pharmacie.getId(), null, "CHANGEMENT_STATUT",
                    changements.size() + " statut(s) modifié(s) sur " + lignes.size() + " reçu(s) : "
                            + String.join(" ; ", changements));
        }
        if (!erreurs.isEmpty()) {
            journal.enregistrer(pharmacie.getId(), null, "ERREUR_CONNECTEUR",
                    erreurs.size() + " ligne(s) refusée(s) : "
                            + String.join(" ; ", erreurs.subList(0, Math.min(3, erreurs.size()))));
        }

        return new ResultatConnecteur(erreurs.isEmpty() ? "OK" : "PARTIEL", lignes.size(), misesAJour, erreurs);
    }

    /** Ce que la pharmacie a actuellement dans MEMA (jamais celles des autres). */
    public List<DisponibiliteConnecteur> lister(Pharmacie pharmacie) {
        LocalDateTime maintenant = LocalDateTime.now();
        return stockRepository.findByPharmacieId(pharmacie.getId()).stream()
                .map(s -> new DisponibiliteConnecteur(
                        s.getMedicament().getId(),
                        s.getMedicament().getNom(),
                        s.calculerStatut(),
                        s.getSource(),
                        s.getDateMiseAJour(),
                        Duration.between(s.getDateMiseAJour(), maintenant).toHours() >= 24))
                .toList();
    }

    private Stock nouveauStock(Pharmacie pharmacie, Medicament medicament) {
        Stock s = new Stock();
        s.setPharmacie(pharmacie);
        s.setMedicament(medicament);
        s.setQuantite(null);
        s.setPrix(null);
        return s;
    }

    /** Traduit le statut reçu. La quantité n'est jamais transmise : on la laisse inconnue. */
    private void appliquerStatut(Stock s, String statut) {
        switch (statut) {
            case "DISPONIBLE" -> {
                s.setDisponible(true);
                s.setSurCommande(false);
                if (s.getQuantite() != null && s.getQuantite() == 0) {
                    s.setQuantite(null);
                }
            }
            case "INDISPONIBLE" -> {
                s.setDisponible(false);
                s.setSurCommande(false);
                s.setQuantite(0);
            }
            case "SUR_COMMANDE" -> {
                s.setDisponible(false);
                s.setSurCommande(true);
                s.setQuantite(0);
            }
            default -> throw new IllegalArgumentException(
                    "statut inconnu « " + statut + " » (DISPONIBLE, INDISPONIBLE ou SUR_COMMANDE attendu)");
        }
        s.setSource(Stock.SOURCE_CONNECTEUR);
        s.setDateMiseAJour(LocalDateTime.now());
    }
}
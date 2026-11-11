package com.example.mema.service;

import com.example.mema.dto.StockPublicResponse;
import com.example.mema.dto.StockRequest;
import com.example.mema.model.Medicament;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.Stock;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.repository.StockRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class StockService {

    /** Au-delà de ce délai sans mise à jour, l'information passe en "à vérifier". */
    private static final long HEURES_AVANT_A_VERIFIER = 24;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private PharmacieRepository pharmacieRepository;

    @Autowired
    private MedicamentRepository medicamentRepository;

    /** Mettre à false pour ne pas montrer le prix aux patients. */
    @Value("${mema.public.prix-visible:true}")
    private boolean prixVisible;

    public List<Stock> listerTous() {
        return stockRepository.findAll();
    }

    public Optional<Stock> trouverParId(Long id) {
        return stockRepository.findById(id);
    }

    // ---------- Vue publique : jamais de quantité ----------

    public List<StockPublicResponse> listerPublic() {
        return stockRepository.findAll().stream().map(this::versPublic).toList();
    }

    public Optional<StockPublicResponse> trouverPublicParId(Long id) {
        return stockRepository.findById(id).map(this::versPublic);
    }

    // ---------- Vue détaillée, réservée au personnel de la pharmacie ----------

    public List<Stock> listerParPharmacie(Long pharmacieId) {
        return stockRepository.findByPharmacieId(pharmacieId);
    }

    private StockPublicResponse versPublic(Stock s) {
        boolean dispo = Boolean.TRUE.equals(s.getDisponible());
        long heures = Duration.between(s.getDateMiseAJour(), LocalDateTime.now()).toHours();
        return new StockPublicResponse(
                s.getId(),
                s.getPharmacie(),
                s.getMedicament(),
                dispo,
                s.calculerStatut(),
                heures >= HEURES_AVANT_A_VERIFIER,
                prixVisible ? s.getPrix() : null,
                s.getDateMiseAJour()
        );
    }

    // ---------- Modifications ----------

    public Stock creer(StockRequest requete) {
        verifier(requete);
        Pharmacie pharmacie = pharmacieRepository.findById(requete.pharmacieId())
                .orElseThrow(() -> new IllegalArgumentException("Pharmacie introuvable : " + requete.pharmacieId()));
        Medicament medicament = medicamentRepository.findById(requete.medicamentId())
                .orElseThrow(() -> new IllegalArgumentException("Médicament introuvable : " + requete.medicamentId()));

        Stock stock = new Stock();
        stock.setPharmacie(pharmacie);
        stock.setMedicament(medicament);
        stock.setQuantite(requete.quantite());
        stock.setDisponible(requete.quantite() > 0);
        stock.setSurCommande(false);
        stock.setSource(Stock.SOURCE_MANUEL);
        stock.setPrix(requete.prix());
        stock.setDateMiseAJour(LocalDateTime.now());
        return stockRepository.save(stock);
    }

    public Optional<Stock> modifier(Long id, StockRequest requete) {
        verifier(requete);
        return stockRepository.findById(id).map(existant -> {
            existant.setQuantite(requete.quantite());
            existant.setDisponible(requete.quantite() > 0);
            existant.setSurCommande(false);
            existant.setSource(Stock.SOURCE_MANUEL);
            existant.setPrix(requete.prix());
            existant.setDateMiseAJour(LocalDateTime.now());
            return stockRepository.save(existant);
        });
    }

    /** Enregistre une vente : la quantite baisse, et a 0 le medicament passe en rupture. */
    public Optional<Stock> enregistrerVente(Long id, int quantiteVendue) {
        if (quantiteVendue <= 0) {
            throw new IllegalArgumentException("La quantité vendue doit être supérieure à 0.");
        }
        return stockRepository.findById(id).map(stock -> {
            int actuel = stock.getQuantite() == null ? 0 : stock.getQuantite();
            int restant = Math.max(0, actuel - quantiteVendue);
            stock.setQuantite(restant);
            stock.setDisponible(restant > 0);
            stock.setSource(Stock.SOURCE_MANUEL);
            stock.setDateMiseAJour(LocalDateTime.now());
            return stockRepository.save(stock);
        });
    }

    public boolean supprimer(Long id) {
        if (stockRepository.existsById(id)) {
            stockRepository.deleteById(id);
            return true;
        }
        return false;
    }

    private void verifier(StockRequest requete) {
        if (requete.quantite() == null || requete.quantite() < 0) {
            throw new IllegalArgumentException("La quantité doit être un nombre supérieur ou égal à 0.");
        }
        if (requete.prix() == null || requete.prix() < 0) {
            throw new IllegalArgumentException("Le prix doit être un nombre supérieur ou égal à 0.");
        }
    }
}
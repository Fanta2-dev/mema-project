package com.example.mema.service;

import com.example.mema.dto.ResumeRecherches;
import com.example.mema.model.RecherchePublique;
import com.example.mema.repository.RecherchePubliqueRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class RecherchePubliqueService {

    private final RecherchePubliqueRepository repository;
    private final TransactionTemplate transactionIndependante;

    /** Mettre à false pour ne rien enregistrer des recherches du public. */
    @Value("${mema.public.enregistrer-recherches:true}")
    private boolean actif;

    public RecherchePubliqueService(RecherchePubliqueRepository repository,
                                    PlatformTransactionManager gestionnaire) {
        this.repository = repository;
        this.transactionIndependante = new TransactionTemplate(gestionnaire);
        this.transactionIndependante.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    /** Un enregistrement par médicament cherché : terme -> nombre de pharmacies où il est disponible. */
    public void enregistrer(Map<String, Integer> nbPharmaciesParTerme, Double latitude, Double longitude) {
        if (!actif || nbPharmaciesParTerme == null || nbPharmaciesParTerme.isEmpty()) {
            return;
        }
        try {
            Double zoneLatitude = arrondir(latitude);
            Double zoneLongitude = arrondir(longitude);
            List<RecherchePublique> lignes = new ArrayList<>();
            for (Map.Entry<String, Integer> e : nbPharmaciesParTerme.entrySet()) {
                RecherchePublique r = new RecherchePublique();
                r.setMedicamentRecherche(e.getKey());
                r.setNbPharmacies(e.getValue());
                r.setZoneLatitude(zoneLatitude);
                r.setZoneLongitude(zoneLongitude);
                lignes.add(r);
            }
            transactionIndependante.executeWithoutResult(statut -> repository.saveAll(lignes));
        } catch (Exception e) {
            System.err.println(">>> Recherches : enregistrement impossible : " + e.getMessage());
        }
    }

    public ResumeRecherches resume(int jours) {
        int j = Math.max(1, Math.min(jours, 365));
        List<RecherchePublique> lignes = repository.findByDateRechercheAfter(LocalDateTime.now().minusDays(j));
        List<RecherchePublique> sansResultat = lignes.stream()
                .filter(l -> l.getNbPharmacies() == 0)
                .toList();
        return new ResumeRecherches(j, lignes.size(), sansResultat.size(),
                classer(lignes), classer(sansResultat));
    }

    private List<ResumeRecherches.Terme> classer(List<RecherchePublique> lignes) {
        Map<String, Long> compte = lignes.stream().collect(
                Collectors.groupingBy(RecherchePublique::getMedicamentRecherche, Collectors.counting()));
        return compte.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(20)
                .map(e -> new ResumeRecherches.Terme(e.getKey(), e.getValue()))
                .toList();
    }

    /** 14.693712 devient 14.69 : une zone d'environ 1 km, pas un point précis. */
    private static Double arrondir(Double valeur) {
        return valeur == null ? null : Math.round(valeur * 100.0) / 100.0;
    }
}
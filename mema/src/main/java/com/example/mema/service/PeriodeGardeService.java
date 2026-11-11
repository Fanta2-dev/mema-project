package com.example.mema.service;

import com.example.mema.dto.PeriodeGardeRequest;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.PeriodeGarde;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.repository.PeriodeGardeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class PeriodeGardeService {

    @Autowired
    private PeriodeGardeRepository periodeGardeRepository;

    @Autowired
    private PharmacieRepository pharmacieRepository;

    public List<PeriodeGarde> listerToutes() {
        return periodeGardeRepository.findAll();
    }

    public PeriodeGarde creer(PeriodeGardeRequest requete) {
        if (requete.zone() == null || requete.zone().isBlank()) {
            throw new IllegalArgumentException("La zone est obligatoire (par exemple Yeumbeul).");
        }
        if (requete.dateDebut() == null || requete.dateFin() == null
                || !requete.dateFin().isAfter(requete.dateDebut())) {
            throw new IllegalArgumentException("La date de fin doit être après la date de début.");
        }
        Pharmacie pharmacie = pharmacieRepository.findById(requete.pharmacieId())
                .orElseThrow(() -> new IllegalArgumentException("Pharmacie introuvable : " + requete.pharmacieId()));

        // Une pharmacie ne peut pas être de garde à deux endroits en même temps.
        for (PeriodeGarde existante : periodeGardeRepository.findAll()) {
            boolean memePharmacie = existante.getPharmacie().getId().equals(pharmacie.getId());
            boolean seChevauchent = requete.dateDebut().isBefore(existante.getDateFin())
                    && requete.dateFin().isAfter(existante.getDateDebut());
            if (memePharmacie && seChevauchent) {
                throw new IllegalArgumentException(
                        "Cette période chevauche une garde déjà enregistrée pour cette pharmacie (zone « "
                                + existante.getZone() + " »). Supprimez-la ou modifiez les dates.");
            }
        }

        PeriodeGarde periode = new PeriodeGarde();
        periode.setPharmacie(pharmacie);
        periode.setZone(requete.zone().trim());
        periode.setDateDebut(requete.dateDebut());
        periode.setDateFin(requete.dateFin());
        periode.setSource(requete.source());
        return periodeGardeRepository.save(periode);
    }

    /** Renvoie la période de garde active pour cette pharmacie à l'instant présent, s'il y en a une. */
    public Optional<PeriodeGarde> trouverActivePour(Long pharmacieId) {
        LocalDateTime maintenant = LocalDateTime.now();
        return periodeGardeRepository.findAll().stream()
                .filter(p -> p.getPharmacie().getId().equals(pharmacieId))
                .filter(p -> !maintenant.isBefore(p.getDateDebut()) && !maintenant.isAfter(p.getDateFin()))
                .findFirst();
    }

    /** Toutes les périodes de garde en cours à cet instant (heure du serveur). */
    public List<PeriodeGarde> listerActives() {
        LocalDateTime maintenant = LocalDateTime.now();
        return periodeGardeRepository.findAll().stream()
                .filter(p -> !maintenant.isBefore(p.getDateDebut()) && !maintenant.isAfter(p.getDateFin()))
                .toList();
    }

    public boolean supprimer(Long id) {
        if (periodeGardeRepository.existsById(id)) {
            periodeGardeRepository.deleteById(id);
            return true;
        }
        return false;
    }
}
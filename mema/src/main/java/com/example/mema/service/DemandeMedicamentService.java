package com.example.mema.service;

import com.example.mema.model.DemandeMedicament;
import com.example.mema.model.Pharmacie;
import com.example.mema.repository.DemandeMedicamentRepository;
import com.example.mema.util.Textes;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Service
public class DemandeMedicamentService {

    @Autowired
    private DemandeMedicamentRepository repository;

    /** Enregistre une demande par nom, sans doublon en attente pour la même pharmacie. Renvoie le nombre de nouvelles demandes. */
    public int enregistrer(Pharmacie pharmacie, Collection<String> noms) {
        Set<String> dejaDemandes = new HashSet<>();
        for (DemandeMedicament d : repository.findByPharmacieIdAndTraiteeFalse(pharmacie.getId())) {
            dejaDemandes.add(Textes.normaliser(d.getNom()));
        }
        int nouvelles = 0;
        for (String nom : noms) {
            String cle = Textes.normaliser(nom);
            if (cle.isEmpty() || !dejaDemandes.add(cle)) {
                continue;
            }
            String propre = nom.trim();
            DemandeMedicament demande = new DemandeMedicament();
            demande.setPharmacie(pharmacie);
            demande.setNom(propre.length() > 200 ? propre.substring(0, 200) : propre);
            repository.save(demande);
            nouvelles++;
        }
        return nouvelles;
    }

    public List<DemandeMedicament> listerEnAttente() {
        return repository.findByTraiteeFalseOrderByDateDemandeDesc();
    }

    public Optional<DemandeMedicament> marquerTraitee(Long id) {
        return repository.findById(id).map(demande -> {
            demande.setTraitee(true);
            return repository.save(demande);
        });
    }

    /** Ferme les demandes dont le nom vient d'être ajouté au catalogue. Renvoie le nombre fermé. */
    public int marquerTraiteesSiConnues(Set<String> nomsNormalises) {
        int fermees = 0;
        for (DemandeMedicament d : repository.findByTraiteeFalse()) {
            if (nomsNormalises.contains(Textes.normaliser(d.getNom()))) {
                d.setTraitee(true);
                repository.save(d);
                fermees++;
            }
        }
        return fermees;
    }
}
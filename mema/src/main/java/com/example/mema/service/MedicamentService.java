package com.example.mema.service;

import com.example.mema.model.Medicament;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.util.CodesMedicament;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class MedicamentService {

    @Autowired
    private MedicamentRepository medicamentRepository;

    public List<Medicament> listerTous() {
        return medicamentRepository.findAll();
    }

    public Optional<Medicament> trouverParId(Long id) {
        return medicamentRepository.findById(id);
    }

    public Medicament ajouter(Medicament medicament) {
        verifier(medicament);
        String code = CodesMedicament.normaliser(medicament.getCode());
        if (code == null) {
            code = CodesMedicament.generer(medicament.getNom(), medicament.getDosage(), codesUtilises());
        } else if (medicamentRepository.findByCode(code).isPresent()) {
            throw new IllegalArgumentException("Ce code est déjà utilisé par un autre médicament.");
        }
        medicament.setId(null);
        medicament.setCode(code);
        return medicamentRepository.save(medicament);
    }

    public Optional<Medicament> modifier(Long id, Medicament donnees) {
        verifier(donnees);
        return medicamentRepository.findById(id).map(existant -> {
            existant.setNom(donnees.getNom());
            existant.setDci(donnees.getDci());
            existant.setDosage(donnees.getDosage());
            existant.setCategorie(donnees.getCategorie());

            String code = CodesMedicament.normaliser(donnees.getCode());
            if (code != null && !code.equals(existant.getCode())) {
                Optional<Medicament> autre = medicamentRepository.findByCode(code);
                if (autre.isPresent() && !autre.get().getId().equals(existant.getId())) {
                    throw new IllegalArgumentException("Ce code est déjà utilisé par un autre médicament.");
                }
                existant.setCode(code);
            }
            return medicamentRepository.save(existant);
        });
    }

    /** Marque ou démarque un médicament comme faisant partie du TOP 100. */
    public Optional<Medicament> definirTop100(Long id, boolean valeur) {
        return medicamentRepository.findById(id).map(medicament -> {
            medicament.setTop100(valeur);
            return medicamentRepository.save(medicament);
        });
    }

    public boolean supprimer(Long id) {
        if (medicamentRepository.existsById(id)) {
            medicamentRepository.deleteById(id);
            return true;
        }
        return false;
    }

    private void verifier(Medicament m) {
        if (m.getNom() == null || m.getNom().isBlank()) {
            throw new IllegalArgumentException("Le nom du médicament est obligatoire.");
        }
        if (m.getDosage() == null || m.getDosage().isBlank()) {
            throw new IllegalArgumentException("Le dosage est obligatoire.");
        }
        if (m.getCategorie() == null || m.getCategorie().isBlank()) {
            throw new IllegalArgumentException("La catégorie est obligatoire.");
        }
    }

    private Set<String> codesUtilises() {
        return medicamentRepository.findAll().stream()
                .map(Medicament::getCode)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(HashSet::new));
    }
}
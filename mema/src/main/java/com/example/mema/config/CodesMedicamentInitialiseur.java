package com.example.mema.config;

import com.example.mema.model.Medicament;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.util.CodesMedicament;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Component
public class CodesMedicamentInitialiseur {

    private final MedicamentRepository repository;

    public CodesMedicamentInitialiseur(MedicamentRepository repository) {
        this.repository = repository;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void attribuerLesCodesManquants() {
        List<Medicament> sansCode = repository.findByCodeIsNull();
        if (sansCode.isEmpty()) {
            return;
        }
        Set<String> utilises = new HashSet<>();
        for (Medicament m : repository.findAll()) {
            if (m.getCode() != null) {
                utilises.add(m.getCode());
            }
        }
        for (Medicament m : sansCode) {
            m.setCode(CodesMedicament.generer(m.getNom(), m.getDosage(), utilises));
        }
        repository.saveAll(sansCode);
        System.out.println(">>> " + sansCode.size() + " code(s) de médicament attribué(s)");
    }
}
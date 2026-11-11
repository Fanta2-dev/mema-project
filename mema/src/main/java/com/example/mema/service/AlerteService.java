package com.example.mema.service;

import com.example.mema.dto.AlerteRequest;
import com.example.mema.model.Alerte;
import com.example.mema.model.Medicament;
import com.example.mema.model.Pharmacie;
import com.example.mema.repository.AlerteRepository;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.util.TelephoneUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class AlerteService {

    @Autowired
    private AlerteRepository alerteRepository;

    @Autowired
    private MedicamentRepository medicamentRepository;

    @Autowired
    private PharmacieRepository pharmacieRepository;

    public List<Alerte> listerToutes() {
        return alerteRepository.findAll();
    }

    public Alerte creer(AlerteRequest requete) {
        Medicament medicament = medicamentRepository.findById(requete.medicamentId())
                .orElseThrow(() -> new IllegalArgumentException("Médicament introuvable : " + requete.medicamentId()));
        Pharmacie pharmacie = pharmacieRepository.findById(requete.pharmacieId())
                .orElseThrow(() -> new IllegalArgumentException("Pharmacie introuvable : " + requete.pharmacieId()));

        Alerte alerte = new Alerte();
        alerte.setMedicament(medicament);
        alerte.setPharmacie(pharmacie);
        alerte.setTelephonePatient(TelephoneUtils.normaliserEtValider(requete.telephonePatient()));
        alerte.setNotifie(false);
        alerte.setDateCreation(LocalDateTime.now());
        return alerteRepository.save(alerte);
    }

    public Optional<Alerte> marquerNotifiee(Long id) {
        return alerteRepository.findById(id).map(alerte -> {
            alerte.setNotifie(true);
            return alerteRepository.save(alerte);
        });
    }

    public boolean supprimer(Long id) {
        if (alerteRepository.existsById(id)) {
            alerteRepository.deleteById(id);
            return true;
        }
        return false;
    }
}
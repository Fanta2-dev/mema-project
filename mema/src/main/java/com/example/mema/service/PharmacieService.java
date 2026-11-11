package com.example.mema.service;

import com.example.mema.model.Pharmacie;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.util.TelephoneUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PharmacieService {

    @Autowired
    private PharmacieRepository pharmacieRepository;

    public List<Pharmacie> listerToutes() {
        return pharmacieRepository.findAll();
    }

    public Optional<Pharmacie> trouverParId(Long id) {
        return pharmacieRepository.findById(id);
    }

    public Pharmacie ajouter(Pharmacie pharmacie) {
        valider(pharmacie);
        pharmacie.setTelephone(TelephoneUtils.normaliserEtValider(pharmacie.getTelephone()));
        return pharmacieRepository.save(pharmacie);
    }

    public Optional<Pharmacie> modifier(Long id, Pharmacie donnees) {
        valider(donnees);
        String telephone = TelephoneUtils.normaliserEtValider(donnees.getTelephone());
        return pharmacieRepository.findById(id).map(existante -> {
            existante.setNom(donnees.getNom());
            existante.setAdresse(donnees.getAdresse());
            existante.setLatitude(donnees.getLatitude());
            existante.setLongitude(donnees.getLongitude());
            existante.setTelephone(telephone);
            existante.setAgreee(donnees.getAgreee());
            existante.setNumeroAgrement(donnees.getNumeroAgrement());
            return pharmacieRepository.save(existante);
        });
    }

    public boolean supprimer(Long id) {
        if (pharmacieRepository.existsById(id)) {
            pharmacieRepository.deleteById(id);
            return true;
        }
        return false;
    }

    /** Vérifie les champs obligatoires et que les coordonnées sont bien au Sénégal. */
    private void valider(Pharmacie p) {
        if (p.getNom() == null || p.getNom().isBlank()) {
            throw new IllegalArgumentException("Le nom de la pharmacie est obligatoire.");
        }
        if (p.getAdresse() == null || p.getAdresse().isBlank()) {
            throw new IllegalArgumentException("L'adresse de la pharmacie est obligatoire.");
        }
        if (p.getLatitude() == null || p.getLongitude() == null) {
            throw new IllegalArgumentException("Les coordonnées (latitude et longitude) sont obligatoires.");
        }
        boolean auSenegal = p.getLatitude() >= 12.0 && p.getLatitude() <= 17.0
                && p.getLongitude() >= -18.0 && p.getLongitude() <= -11.0;
        if (!auSenegal) {
            throw new IllegalArgumentException(
                    "Ces coordonnées ne sont pas au Sénégal. Vérifiez l'ordre : "
                            + "latitude (environ 14) puis longitude (environ -17).");
        }
        if (p.getAgreee() == null) {
            p.setAgreee(false);
        }
    }
}
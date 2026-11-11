package com.example.mema.service;

import com.example.mema.dto.UtilisateurRequest;
import com.example.mema.dto.UtilisateurResponse;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.Utilisateur;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.repository.UtilisateurRepository;
import com.example.mema.util.TelephoneUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UtilisateurService {

    private static final int LONGUEUR_MIN_MOT_DE_PASSE = 8;

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private PharmacieRepository pharmacieRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public List<UtilisateurResponse> listerTous() {
        return utilisateurRepository.findAll().stream()
                .map(this::versReponse)
                .collect(Collectors.toList());
    }

    public Optional<UtilisateurResponse> trouverParId(Long id) {
        return utilisateurRepository.findById(id).map(this::versReponse);
    }

    public UtilisateurResponse creer(UtilisateurRequest requete) {
        if (requete.nom() == null || requete.nom().isBlank()) {
            throw new IllegalArgumentException("Le nom est obligatoire.");
        }
        if (requete.motDePasse() == null || requete.motDePasse().length() < LONGUEUR_MIN_MOT_DE_PASSE) {
            throw new IllegalArgumentException(
                    "Le mot de passe doit contenir au moins " + LONGUEUR_MIN_MOT_DE_PASSE + " caractères.");
        }

        Utilisateur.Role role;
        try {
            role = Utilisateur.Role.valueOf(requete.role().trim().toUpperCase());
        } catch (IllegalArgumentException | NullPointerException e) {
            throw new IllegalArgumentException("Rôle invalide : PHARMACIEN, AGENT ou ADMIN attendu.");
        }

        // Un administrateur n'est rattaché à aucune pharmacie ; les autres doivent l'être.
        Pharmacie pharmacie = null;
        if (requete.pharmacieId() != null) {
            pharmacie = pharmacieRepository.findById(requete.pharmacieId())
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Pharmacie introuvable : " + requete.pharmacieId()));
        } else if (role != Utilisateur.Role.ADMIN) {
            throw new IllegalArgumentException(
                    "Une pharmacie est obligatoire pour un pharmacien ou un agent.");
        }

        String telephone = TelephoneUtils.normaliserEtValider(requete.telephone());
        if (utilisateurRepository.findByTelephone(telephone).isPresent()) {
            throw new IllegalArgumentException("Ce numéro est déjà utilisé par un autre compte.");
        }

        Utilisateur utilisateur = new Utilisateur();
        utilisateur.setPharmacie(pharmacie);
        utilisateur.setNom(requete.nom().trim());
        utilisateur.setTelephone(telephone);
        utilisateur.setMotDePasseHash(passwordEncoder.encode(requete.motDePasse()));
        utilisateur.setRole(role);

        return versReponse(utilisateurRepository.save(utilisateur));
    }

    public boolean supprimer(Long id) {
        Optional<Utilisateur> trouve = utilisateurRepository.findById(id);
        if (trouve.isEmpty()) {
            return false;
        }
        if (trouve.get().getRole() == Utilisateur.Role.ADMIN) {
            long nbAdmins = utilisateurRepository.findAll().stream()
                    .filter(u -> u.getRole() == Utilisateur.Role.ADMIN)
                    .count();
            if (nbAdmins <= 1) {
                throw new IllegalArgumentException("Impossible de supprimer le dernier administrateur.");
            }
        }
        utilisateurRepository.deleteById(id);
        return true;
    }

    private UtilisateurResponse versReponse(Utilisateur u) {
        return new UtilisateurResponse(
                u.getId(),
                u.getPharmacie() != null ? u.getPharmacie().getId() : null,
                u.getNom(),
                u.getTelephone(),
                u.getRole().name()
        );
    }
}
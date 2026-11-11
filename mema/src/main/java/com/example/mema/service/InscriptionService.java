package com.example.mema.service;

import com.example.mema.dto.InscriptionRequest;
import com.example.mema.dto.InscriptionResponse;
import com.example.mema.model.DemandeInscription;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.Utilisateur;
import com.example.mema.repository.DemandeInscriptionRepository;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.repository.UtilisateurRepository;
import com.example.mema.util.TelephoneUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class InscriptionService {

    private static final int LONGUEUR_MIN_MOT_DE_PASSE = 8;
    private static final int LONGUEUR_MAX_TEXTE = 200;

    @Autowired
    private DemandeInscriptionRepository repository;

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private PharmacieRepository pharmacieRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Transactional
    public InscriptionResponse soumettre(InscriptionRequest r) {
        exiger(r.pharmacieNom(), "Le nom de la pharmacie est obligatoire.");
        exiger(r.pharmacieAdresse(), "L'adresse de la pharmacie est obligatoire.");
        exiger(r.numeroAgrement(), "Le numéro d'agrément est obligatoire.");
        exiger(r.responsableNom(), "Votre nom est obligatoire.");

        if (r.latitude() == null || r.longitude() == null) {
            throw new IllegalArgumentException("La position de la pharmacie est obligatoire.");
        }
        boolean auSenegal = r.latitude() >= 12.0 && r.latitude() <= 17.0
                && r.longitude() >= -18.0 && r.longitude() <= -11.0;
        if (!auSenegal) {
            throw new IllegalArgumentException(
                    "Ces coordonnées ne sont pas au Sénégal. Vérifiez l'ordre : "
                            + "latitude (environ 14) puis longitude (environ -17).");
        }
        if (r.motDePasse() == null || r.motDePasse().length() < LONGUEUR_MIN_MOT_DE_PASSE) {
            throw new IllegalArgumentException(
                    "Le mot de passe doit contenir au moins " + LONGUEUR_MIN_MOT_DE_PASSE + " caractères.");
        }

        String telephonePharmacie = TelephoneUtils.normaliserEtValider(r.pharmacieTelephone());
        String telephoneResponsable = TelephoneUtils.normaliserEtValider(r.responsableTelephone());

        if (utilisateurRepository.findByTelephone(telephoneResponsable).isPresent()) {
            throw new IllegalArgumentException(
                    "Ce numéro est déjà utilisé par un compte. Connectez-vous, ou utilisez un autre numéro.");
        }
        if (repository.existsByResponsableTelephoneAndStatut(
                telephoneResponsable, DemandeInscription.Statut.EN_ATTENTE)) {
            throw new IllegalArgumentException(
                    "Une demande est déjà en cours de vérification pour ce numéro.");
        }

        DemandeInscription d = new DemandeInscription();
        d.setPharmacieNom(r.pharmacieNom().trim());
        d.setPharmacieAdresse(r.pharmacieAdresse().trim());
        d.setPharmacieLatitude(r.latitude());
        d.setPharmacieLongitude(r.longitude());
        d.setPharmacieTelephone(telephonePharmacie);
        d.setNumeroAgrement(r.numeroAgrement().trim());
        d.setResponsableNom(r.responsableNom().trim());
        d.setResponsableTelephone(telephoneResponsable);
        d.setMotDePasseHash(passwordEncoder.encode(r.motDePasse()));
        return versReponse(repository.save(d));
    }

    public List<InscriptionResponse> listerEnAttente() {
        return repository.findByStatutOrderByDateDemandeDesc(DemandeInscription.Statut.EN_ATTENTE)
                .stream()
                .map(this::versReponse)
                .collect(Collectors.toList());
    }

    /** Dernière demande faite avec ce numéro (déjà normalisé), pour expliquer l'état à la connexion. */
    public Optional<DemandeInscription> derniereDemandePour(String telephoneNormalise) {
        return repository.findFirstByResponsableTelephoneOrderByDateDemandeDesc(telephoneNormalise);
    }

    /** Valide : crée la pharmacie (agréée) et le compte du responsable. */
    @Transactional
    public Optional<InscriptionResponse> valider(Long id, Long adminId) {
        Optional<DemandeInscription> trouvee = repository.findById(id);
        if (trouvee.isEmpty()) {
            return Optional.empty();
        }
        DemandeInscription d = trouvee.get();
        verifierEnAttente(d);
        if (utilisateurRepository.findByTelephone(d.getResponsableTelephone()).isPresent()) {
            throw new IllegalArgumentException(
                    "Un compte utilise déjà le numéro de ce responsable. "
                            + "Refusez la demande ou supprimez l'ancien compte.");
        }

        Pharmacie pharmacie = new Pharmacie();
        pharmacie.setNom(d.getPharmacieNom());
        pharmacie.setAdresse(d.getPharmacieAdresse());
        pharmacie.setLatitude(d.getPharmacieLatitude());
        pharmacie.setLongitude(d.getPharmacieLongitude());
        pharmacie.setTelephone(d.getPharmacieTelephone());
        pharmacie.setAgreee(true);
        pharmacie.setNumeroAgrement(d.getNumeroAgrement());
        pharmacieRepository.save(pharmacie);

        Utilisateur compte = new Utilisateur();
        compte.setPharmacie(pharmacie);
        compte.setNom(d.getResponsableNom());
        compte.setTelephone(d.getResponsableTelephone());
        compte.setMotDePasseHash(d.getMotDePasseHash());
        compte.setRole(Utilisateur.Role.PHARMACIEN);
        utilisateurRepository.save(compte);

        d.setStatut(DemandeInscription.Statut.VALIDEE);
        d.setDateDecision(LocalDateTime.now());
        d.setDecidePar(adminId);
        return Optional.of(versReponse(repository.save(d)));
    }

    @Transactional
    public Optional<InscriptionResponse> refuser(Long id, String motif, Long adminId) {
        Optional<DemandeInscription> trouvee = repository.findById(id);
        if (trouvee.isEmpty()) {
            return Optional.empty();
        }
        DemandeInscription d = trouvee.get();
        verifierEnAttente(d);
        if (motif == null || motif.trim().length() < 3) {
            throw new IllegalArgumentException("Indiquez un motif de refus (il sera affiché au demandeur).");
        }
        d.setStatut(DemandeInscription.Statut.REFUSEE);
        d.setMotifRefus(motif.trim().length() > LONGUEUR_MAX_TEXTE
                ? motif.trim().substring(0, LONGUEUR_MAX_TEXTE)
                : motif.trim());
        d.setDateDecision(LocalDateTime.now());
        d.setDecidePar(adminId);
        return Optional.of(versReponse(repository.save(d)));
    }

    private void verifierEnAttente(DemandeInscription d) {
        if (d.getStatut() != DemandeInscription.Statut.EN_ATTENTE) {
            throw new IllegalArgumentException("Cette demande a déjà été traitée.");
        }
    }

    private static void exiger(String valeur, String message) {
        if (valeur == null || valeur.isBlank()) {
            throw new IllegalArgumentException(message);
        }
        if (valeur.trim().length() > LONGUEUR_MAX_TEXTE) {
            throw new IllegalArgumentException("Un des champs est trop long (200 caractères au maximum).");
        }
    }

    private InscriptionResponse versReponse(DemandeInscription d) {
        return new InscriptionResponse(
                d.getId(),
                d.getPharmacieNom(),
                d.getPharmacieAdresse(),
                d.getPharmacieLatitude(),
                d.getPharmacieLongitude(),
                d.getPharmacieTelephone(),
                d.getNumeroAgrement(),
                d.getResponsableNom(),
                d.getResponsableTelephone(),
                d.getStatut().name(),
                d.getMotifRefus(),
                d.getDateDemande()
        );
    }
}
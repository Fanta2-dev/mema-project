package com.example.mema.service;

import com.example.mema.model.CleApiPharmacie;
import com.example.mema.model.Pharmacie;
import com.example.mema.repository.CleApiPharmacieRepository;
import com.example.mema.repository.PharmacieRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class CleApiService {

    private static final String ALPHABET =
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    private static final SecureRandom HASARD = new SecureRandom();

    public record CleGeneree(String cle, String prefixe) {}

    @Autowired
    private CleApiPharmacieRepository repository;

    @Autowired
    private PharmacieRepository pharmacieRepository;

    @Autowired
    private JournalService journal;

    /** Génère une nouvelle clé pour cette pharmacie. L'ancienne, s'il y en avait une, cesse de fonctionner. */
    @Transactional
    public CleGeneree generer(Long pharmacieId, Long adminId) {
        Pharmacie pharmacie = pharmacieRepository.findById(pharmacieId)
                .orElseThrow(() -> new IllegalArgumentException("Pharmacie introuvable : " + pharmacieId));

        String cle = "mema_" + aleatoire(32);
        String prefixe = cle.substring(0, 9);

        CleApiPharmacie enregistrement = repository.findByPharmacieId(pharmacieId)
                .orElseGet(CleApiPharmacie::new);
        enregistrement.setPharmacie(pharmacie);
        enregistrement.setEmpreinte(empreinte(cle));
        enregistrement.setPrefixe(prefixe);
        enregistrement.setDateCreation(LocalDateTime.now());
        enregistrement.setDerniereUtilisation(null);
        enregistrement.setActive(true);
        repository.save(enregistrement);

        journal.enregistrer(pharmacieId, adminId, "CLE_API_GENEREE", "Nouvelle clé, préfixe " + prefixe);
        return new CleGeneree(cle, prefixe);
    }

    @Transactional
    public boolean revoquer(Long pharmacieId, Long adminId) {
        Optional<CleApiPharmacie> trouvee = repository.findByPharmacieId(pharmacieId);
        if (trouvee.isEmpty() || !Boolean.TRUE.equals(trouvee.get().getActive())) {
            return false;
        }
        CleApiPharmacie cle = trouvee.get();
        cle.setActive(false);
        repository.save(cle);
        journal.enregistrer(pharmacieId, adminId, "CLE_API_REVOQUEE", "Clé révoquée, préfixe " + cle.getPrefixe());
        return true;
    }

    public Optional<CleApiPharmacie> statut(Long pharmacieId) {
        return repository.findByPharmacieId(pharmacieId);
    }

    /** Retrouve la pharmacie à partir de la clé présentée. Vide si la clé est inconnue ou révoquée. */
    @Transactional
    public Optional<Pharmacie> verifier(String cle) {
        if (cle == null || cle.isBlank()) {
            return Optional.empty();
        }
        return repository.findByEmpreinteAndActiveTrue(empreinte(cle.trim())).map(enregistrement -> {
            enregistrement.setDerniereUtilisation(LocalDateTime.now());
            repository.save(enregistrement);
            return enregistrement.getPharmacie();
        });
    }

    private static String aleatoire(int longueur) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < longueur; i++) {
            sb.append(ALPHABET.charAt(HASARD.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }

    private static String empreinte(String cle) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] octets = md.digest(cle.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : octets) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponible", e);
        }
    }
}
package com.example.mema.controller;

import com.example.mema.dto.LoginRequest;
import com.example.mema.dto.LoginResponse;
import com.example.mema.dto.UtilisateurResponse;
import com.example.mema.model.DemandeInscription;
import com.example.mema.model.Utilisateur;
import com.example.mema.repository.UtilisateurRepository;
import com.example.mema.service.InscriptionService;
import com.example.mema.service.TokenService;
import com.example.mema.util.TelephoneUtils;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private static final int MAX_ECHECS = 5;
    private static final long BLOCAGE_MS = 15 * 60 * 1000L;

    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;
    private final InscriptionService inscriptionService;

    /** Sert à toujours faire le même travail de vérification, même si le numéro n'existe pas. */
    private final String hashBidon;

    /** Par numéro : [nombre d'échecs, heure de fin du blocage]. */
    private final Map<String, long[]> echecs = new ConcurrentHashMap<>();

    public AuthController(UtilisateurRepository utilisateurRepository,
                          PasswordEncoder passwordEncoder,
                          TokenService tokenService,
                          InscriptionService inscriptionService) {
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
        this.inscriptionService = inscriptionService;
        this.hashBidon = passwordEncoder.encode("mot-de-passe-bidon");
    }

    @PostMapping("/login")
    public ResponseEntity<?> connecter(@RequestBody LoginRequest requete) {
        String telephone;
        try {
            telephone = TelephoneUtils.normaliserEtValider(requete.telephone());
        } catch (IllegalArgumentException e) {
            return refus();
        }

        long maintenant = System.currentTimeMillis();
        long[] etat = echecs.get(telephone);
        if (etat != null && etat[0] >= MAX_ECHECS && maintenant < etat[1]) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("erreur", "Trop de tentatives. Réessayez dans 15 minutes."));
        }

        Optional<Utilisateur> trouve = utilisateurRepository.findByTelephone(telephone);
        String hash = trouve.map(Utilisateur::getMotDePasseHash).orElse(hashBidon);
        boolean motDePasseOk = requete.motDePasse() != null
                && passwordEncoder.matches(requete.motDePasse(), hash);

        // Pas encore de compte : la personne a peut-être une demande d'inscription en cours ou refusée.
        // On ne l'explique que si le mot de passe de la demande est le bon.
        if (trouve.isEmpty() && requete.motDePasse() != null) {
            Optional<DemandeInscription> demande = inscriptionService.derniereDemandePour(telephone);
            if (demande.isPresent()
                    && passwordEncoder.matches(requete.motDePasse(), demande.get().getMotDePasseHash())) {
                DemandeInscription d = demande.get();
                if (d.getStatut() == DemandeInscription.Statut.EN_ATTENTE) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                            "erreur", "Votre demande d'inscription est en cours de vérification. "
                                    + "Vous pourrez vous connecter dès qu'elle sera validée.",
                            "statut", "EN_ATTENTE"));
                }
                if (d.getStatut() == DemandeInscription.Statut.REFUSEE) {
                    String motif = d.getMotifRefus() != null ? " Motif : " + d.getMotifRefus() + "." : "";
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                            "erreur", "Votre demande d'inscription a été refusée." + motif
                                    + " Vous pouvez refaire une demande.",
                            "statut", "REFUSEE"));
                }
            }
        }

        if (trouve.isEmpty() || !motDePasseOk) {
            echecs.compute(telephone, (cle, ancien) -> {
                long[] nouveau = (ancien == null || (ancien[0] >= MAX_ECHECS && maintenant >= ancien[1]))
                        ? new long[]{0, 0}
                        : ancien;
                nouveau[0]++;
                nouveau[1] = maintenant + BLOCAGE_MS;
                return nouveau;
            });
            return refus();
        }

        echecs.remove(telephone);
        Utilisateur u = trouve.get();
        Long pharmacieId = u.getPharmacie() != null ? u.getPharmacie().getId() : null;
        String pharmacieNom = u.getPharmacie() != null ? u.getPharmacie().getNom() : null;
        UtilisateurResponse reponse = new UtilisateurResponse(
                u.getId(), pharmacieId, u.getNom(), u.getTelephone(), u.getRole().name());

        return ResponseEntity.ok(new LoginResponse(
                tokenService.creer(u), reponse, pharmacieNom, TokenService.DUREE_SECONDES));
    }

    /** Même message que le numéro soit inconnu ou le mot de passe faux : on ne révèle rien. */
    private ResponseEntity<Map<String, String>> refus() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("erreur", "Numéro ou mot de passe incorrect."));
    }
}
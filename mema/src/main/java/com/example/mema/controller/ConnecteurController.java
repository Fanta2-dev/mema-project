package com.example.mema.controller;

import com.example.mema.dto.DisponibiliteConnecteur;
import com.example.mema.dto.DisponibilitesRequest;
import com.example.mema.dto.ResultatConnecteur;
import com.example.mema.model.Pharmacie;
import com.example.mema.service.CleApiService;
import com.example.mema.service.ConnecteurService;
import com.example.mema.service.JournalService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * API utilisée par le connecteur installé chez la pharmacie.
 * Authentification : en-tête X-API-Key (pas de connexion par mot de passe).
 */
@RestController
@RequestMapping("/api/v1")
public class ConnecteurController {

    private static final int MAX_ECHECS = 20;
    private static final long FENETRE_MS = 15 * 60 * 1000L;

    @Autowired
    private CleApiService cleApiService;

    @Autowired
    private ConnecteurService connecteurService;

    @Autowired
    private JournalService journal;

    /** Par adresse : [nombre d'échecs, début de la fenêtre]. */
    private final Map<String, long[]> echecs = new ConcurrentHashMap<>();

    /** Envoie les statuts d'une ou plusieurs lignes (500 au maximum par requête). */
    @PostMapping("/disponibilite")
    public ResultatConnecteur envoyer(@RequestHeader(value = "X-API-Key", required = false) String cle,
                                      @RequestBody DisponibilitesRequest requete,
                                      HttpServletRequest http) {
        Pharmacie pharmacie = authentifier(cle, http);
        return connecteurService.appliquer(pharmacie, requete.disponibilites());
    }

    /** Ce que MEMA contient pour cette pharmacie. */
    @GetMapping("/mes-disponibilites")
    public List<DisponibiliteConnecteur> mesDisponibilites(
            @RequestHeader(value = "X-API-Key", required = false) String cle,
            HttpServletRequest http) {
        Pharmacie pharmacie = authentifier(cle, http);
        return connecteurService.lister(pharmacie);
    }

    /** Teste la clé : à utiliser lors de l'installation du connecteur. */
    @GetMapping("/ping")
    public Map<String, Object> ping(@RequestHeader(value = "X-API-Key", required = false) String cle,
                                    HttpServletRequest http) {
        Pharmacie pharmacie = authentifier(cle, http);
        journal.enregistrer(pharmacie.getId(), null, "CONNEXION", "Test de connexion du connecteur");
        return Map.of("resultat", "OK", "pharmacieId", pharmacie.getId(), "pharmacie", pharmacie.getNom());
    }

    private Pharmacie authentifier(String cle, HttpServletRequest http) {
        String adresse = http.getRemoteAddr();
        long maintenant = System.currentTimeMillis();

        long[] etat = echecs.get(adresse);
        if (etat != null && etat[0] >= MAX_ECHECS && maintenant - etat[1] < FENETRE_MS) {
            throw new CleInvalideException(429, "Trop de tentatives. Réessayez plus tard.");
        }

        Optional<Pharmacie> pharmacie = cleApiService.verifier(cle);
        if (pharmacie.isEmpty()) {
            echecs.compute(adresse, (a, ancien) -> {
                if (ancien == null || maintenant - ancien[1] >= FENETRE_MS) {
                    return new long[]{1, maintenant};
                }
                ancien[0]++;
                return ancien;
            });
            throw new CleInvalideException(401, "Clé API invalide ou révoquée.");
        }
        echecs.remove(adresse);
        return pharmacie.get();
    }

    static class CleInvalideException extends RuntimeException {
        final int statut;

        CleInvalideException(int statut, String message) {
            super(message);
            this.statut = statut;
        }
    }

    @ExceptionHandler(CleInvalideException.class)
    public ResponseEntity<Map<String, String>> cleInvalide(CleInvalideException e) {
        return ResponseEntity.status(e.statut)
                .body(Map.of("resultat", "ERREUR", "erreur", e.getMessage()));
    }
}
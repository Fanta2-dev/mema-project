package com.example.mema.controller;

import com.example.mema.dto.InscriptionRequest;
import com.example.mema.dto.InscriptionResponse;
import com.example.mema.dto.RefusInscriptionRequest;
import com.example.mema.service.InscriptionService;
import com.example.mema.util.Autorisation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/inscriptions")
public class InscriptionController {

    private static final int MAX_DEMANDES_PAR_HEURE = 10;
    private static final long UNE_HEURE_MS = 60 * 60 * 1000L;

    @Autowired
    private InscriptionService service;

    /** Horodatages des demandes récentes, par adresse. */
    private final Map<String, Deque<Long>> envois = new ConcurrentHashMap<>();

    /** Publique : n'importe qui peut déposer une demande (qui sera vérifiée par un administrateur). */
    @PostMapping
    public ResponseEntity<?> soumettre(@RequestBody InscriptionRequest requete, HttpServletRequest http) {
        if (!autorise(http.getRemoteAddr())) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("erreur", "Trop de demandes depuis cette connexion. Réessayez plus tard."));
        }
        return ResponseEntity.ok(service.soumettre(requete));
    }

    /** Réservé à l'administrateur. */
    @GetMapping
    public List<InscriptionResponse> enAttente() {
        return service.listerEnAttente();
    }

    /** Réservé à l'administrateur. */
    @PostMapping("/{id}/valider")
    public ResponseEntity<InscriptionResponse> valider(@PathVariable Long id, HttpServletRequest http) {
        return service.valider(id, Autorisation.utilisateurId(http))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /** Réservé à l'administrateur. */
    @PostMapping("/{id}/refuser")
    public ResponseEntity<InscriptionResponse> refuser(@PathVariable Long id,
                                                       @RequestBody RefusInscriptionRequest requete,
                                                       HttpServletRequest http) {
        return service.refuser(id, requete.motif(), Autorisation.utilisateurId(http))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    private boolean autorise(String adresse) {
        long maintenant = System.currentTimeMillis();
        Deque<Long> file = envois.computeIfAbsent(adresse, cle -> new ArrayDeque<>());
        synchronized (file) {
            while (!file.isEmpty() && maintenant - file.peekFirst() > UNE_HEURE_MS) {
                file.pollFirst();
            }
            if (file.size() >= MAX_DEMANDES_PAR_HEURE) {
                return false;
            }
            file.addLast(maintenant);
            return true;
        }
    }
}
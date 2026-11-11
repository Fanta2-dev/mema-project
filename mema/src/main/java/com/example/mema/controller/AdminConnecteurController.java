package com.example.mema.controller;

import com.example.mema.dto.CleApiResponse;
import com.example.mema.dto.StatutCleApi;
import com.example.mema.model.JournalAction;
import com.example.mema.service.CleApiService;
import com.example.mema.service.JournalService;
import com.example.mema.util.Autorisation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Réservé à l'administrateur (vérifié par AuthInterceptor). */
@RestController
@RequestMapping("/admin")
public class AdminConnecteurController {

    @Autowired
    private CleApiService cleApiService;

    @Autowired
    private JournalService journal;

    /** Génère (ou régénère) la clé API d'une pharmacie. La clé n'est affichée qu'une seule fois. */
    @PostMapping("/pharmacies/{pharmacieId}/cle-api")
    public CleApiResponse generer(@PathVariable Long pharmacieId, HttpServletRequest http) {
        CleApiService.CleGeneree generee = cleApiService.generer(pharmacieId, Autorisation.utilisateurId(http));
        return new CleApiResponse(
                generee.cle(),
                generee.prefixe(),
                "Notez cette clé maintenant : elle ne sera plus jamais affichée. "
                        + "L'ancienne clé de cette pharmacie, s'il y en avait une, ne fonctionne plus.");
    }

    @GetMapping("/pharmacies/{pharmacieId}/cle-api")
    public StatutCleApi statut(@PathVariable Long pharmacieId) {
        return cleApiService.statut(pharmacieId)
                .map(c -> new StatutCleApi(true, Boolean.TRUE.equals(c.getActive()), c.getPrefixe(),
                        c.getDateCreation(), c.getDerniereUtilisation()))
                .orElse(new StatutCleApi(false, false, null, null, null));
    }

    @DeleteMapping("/pharmacies/{pharmacieId}/cle-api")
    public ResponseEntity<Void> revoquer(@PathVariable Long pharmacieId, HttpServletRequest http) {
        if (cleApiService.revoquer(pharmacieId, Autorisation.utilisateurId(http))) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }

    /** Les 200 dernières actions (toutes les pharmacies, ou une seule avec pharmacieId). */
    @GetMapping("/journal")
    public List<JournalAction> journal(@RequestParam(required = false) Long pharmacieId) {
        return journal.recents(pharmacieId);
    }
}
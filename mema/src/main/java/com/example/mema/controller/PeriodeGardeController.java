package com.example.mema.controller;

import com.example.mema.dto.PeriodeGardeRequest;
import com.example.mema.model.PeriodeGarde;
import com.example.mema.service.PeriodeGardeService;
import com.example.mema.util.Autorisation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/periodes-garde")
public class PeriodeGardeController {

    @Autowired
    private PeriodeGardeService periodeGardeService;

    @GetMapping
    public List<PeriodeGarde> listerToutes() {
        return periodeGardeService.listerToutes();
    }

    /** Pharmacies de garde en ce moment : publique, pour l'écran d'urgence des patients. */
    @GetMapping("/actives")
    public List<PeriodeGarde> actives() {
        return periodeGardeService.listerActives();
    }

    @GetMapping("/pharmacie/{pharmacieId}/active")
    public ResponseEntity<PeriodeGarde> active(@PathVariable Long pharmacieId) {
        return periodeGardeService.trouverActivePour(pharmacieId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public PeriodeGarde creer(@RequestBody PeriodeGardeRequest requete, HttpServletRequest requeteHttp) {
        Autorisation.exigerPharmacie(requeteHttp, requete.pharmacieId());
        return periodeGardeService.creer(requete);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        if (periodeGardeService.supprimer(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
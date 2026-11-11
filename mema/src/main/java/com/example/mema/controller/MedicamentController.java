package com.example.mema.controller;

import com.example.mema.model.Medicament;
import com.example.mema.service.MedicamentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/medicaments")
public class MedicamentController {

    @Autowired
    private MedicamentService medicamentService;

    @GetMapping
    public List<Medicament> listerTous() {
        return medicamentService.listerTous();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Medicament> trouverParId(@PathVariable Long id) {
        return medicamentService.trouverParId(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Medicament ajouter(@RequestBody Medicament medicament) {
        return medicamentService.ajouter(medicament);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Medicament> modifier(@PathVariable Long id, @RequestBody Medicament donnees) {
        return medicamentService.modifier(id, donnees)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /** Réservé à l'administrateur : ajoute ou retire un médicament de la liste TOP 100. */
    @PatchMapping("/{id}/top100")
    public ResponseEntity<Medicament> definirTop100(@PathVariable Long id, @RequestParam boolean valeur) {
        return medicamentService.definirTop100(id, valeur)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        if (medicamentService.supprimer(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
package com.example.mema.controller;

import com.example.mema.model.Pharmacie;
import com.example.mema.service.PharmacieService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/pharmacies")
public class PharmacieController {

    @Autowired
    private PharmacieService pharmacieService;

    @GetMapping
    public List<Pharmacie> listerToutes() {
        return pharmacieService.listerToutes();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Pharmacie> trouverParId(@PathVariable Long id) {
        return pharmacieService.trouverParId(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Pharmacie ajouter(@RequestBody Pharmacie pharmacie) {
        return pharmacieService.ajouter(pharmacie);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Pharmacie> modifier(@PathVariable Long id, @RequestBody Pharmacie donnees) {
        return pharmacieService.modifier(id, donnees)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        if (pharmacieService.supprimer(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}

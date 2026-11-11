package com.example.mema.controller;

import com.example.mema.model.DemandeMedicament;
import com.example.mema.service.DemandeMedicamentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Réservé à l'administrateur (vérifié par AuthInterceptor). */
@RestController
@RequestMapping("/demandes-medicaments")
public class DemandeMedicamentController {

    @Autowired
    private DemandeMedicamentService service;

    @GetMapping
    public List<DemandeMedicament> listerEnAttente() {
        return service.listerEnAttente();
    }

    @PatchMapping("/{id}/traiter")
    public ResponseEntity<DemandeMedicament> traiter(@PathVariable Long id) {
        return service.marquerTraitee(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
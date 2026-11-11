package com.example.mema.controller;

import com.example.mema.dto.AlerteRequest;
import com.example.mema.model.Alerte;
import com.example.mema.service.AlerteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/alertes")
public class AlerteController {

    @Autowired
    private AlerteService alerteService;

    @GetMapping
    public List<Alerte> listerToutes() {
        return alerteService.listerToutes();
    }

    @PostMapping
    public Alerte creer(@RequestBody AlerteRequest requete) {
        return alerteService.creer(requete);
    }

    @PatchMapping("/{id}/notifier")
    public ResponseEntity<Alerte> marquerNotifiee(@PathVariable Long id) {
        return alerteService.marquerNotifiee(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        if (alerteService.supprimer(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
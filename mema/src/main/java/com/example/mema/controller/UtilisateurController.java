package com.example.mema.controller;

import com.example.mema.dto.UtilisateurRequest;
import com.example.mema.dto.UtilisateurResponse;
import com.example.mema.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/utilisateurs")
public class UtilisateurController {

    @Autowired
    private UtilisateurService utilisateurService;

    @GetMapping
    public List<UtilisateurResponse> listerTous() {
        return utilisateurService.listerTous();
    }

    @GetMapping("/{id}")
    public ResponseEntity<UtilisateurResponse> trouverParId(@PathVariable Long id) {
        return utilisateurService.trouverParId(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public UtilisateurResponse creer(@RequestBody UtilisateurRequest requete) {
        return utilisateurService.creer(requete);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        if (utilisateurService.supprimer(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
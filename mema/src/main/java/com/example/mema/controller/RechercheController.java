package com.example.mema.controller;

import com.example.mema.dto.ResultatRecherche;
import com.example.mema.service.RechercheService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class RechercheController {

    @Autowired
    private RechercheService rechercheService;

    /**
     * Où trouver ces médicaments ?
     * ids=1,2,3 (identifiants du catalogue) ou medicament=paracetamol (nom, principe actif ou code).
     * latitude et longitude sont facultatives : sans elles, pas de distance.
     */
    @GetMapping("/recherche")
    public ResultatRecherche rechercher(@RequestParam(required = false) String ids,
                                        @RequestParam(required = false) String medicament,
                                        @RequestParam(required = false) Double latitude,
                                        @RequestParam(required = false) Double longitude,
                                        @RequestParam(required = false) Integer limite) {
        return rechercheService.rechercher(lireIds(ids), medicament, latitude, longitude, limite);
    }

    private List<Long> lireIds(String ids) {
        List<Long> liste = new ArrayList<>();
        if (ids == null || ids.isBlank()) {
            return liste;
        }
        for (String morceau : ids.split(",")) {
            String propre = morceau.trim();
            if (propre.isEmpty()) {
                continue;
            }
            try {
                liste.add(Long.valueOf(propre));
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("Identifiant de médicament invalide : « " + propre + " ».");
            }
        }
        return liste;
    }
}
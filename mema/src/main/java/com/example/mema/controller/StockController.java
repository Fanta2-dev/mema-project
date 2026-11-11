package com.example.mema.controller;

import com.example.mema.dto.StockPublicResponse;
import com.example.mema.dto.StockRequest;
import com.example.mema.model.Stock;
import com.example.mema.service.StockService;
import com.example.mema.util.Autorisation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/stocks")
public class StockController {

    @Autowired
    private StockService stockService;

    /** Public : disponibilités sans quantité. */
    @GetMapping
    public List<StockPublicResponse> listerTous() {
        return stockService.listerPublic();
    }

    /** Public : une disponibilité, sans quantité. */
    @GetMapping("/{id}")
    public ResponseEntity<StockPublicResponse> trouverParId(@PathVariable Long id) {
        return stockService.trouverPublicParId(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Stock creer(@RequestBody StockRequest requete, HttpServletRequest requeteHttp) {
        Autorisation.exigerPharmacie(requeteHttp, requete.pharmacieId());
        return stockService.creer(requete);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Stock> modifier(@PathVariable Long id, @RequestBody StockRequest requete) {
        return stockService.modifier(id, requete)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> supprimer(@PathVariable Long id) {
        if (stockService.supprimer(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }

    @PatchMapping("/{id}/vente")
    public ResponseEntity<Stock> vente(@PathVariable Long id, @RequestParam int quantite) {
        return stockService.enregistrerVente(id, quantite)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
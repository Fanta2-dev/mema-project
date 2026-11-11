package com.example.mema.controller;

import com.example.mema.model.Stock;
import com.example.mema.service.StockService;
import com.example.mema.util.Autorisation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/pharmacies/{pharmacieId}/stock")
public class StockPharmacieController {

    @Autowired
    private StockService stockService;

    /** Stock complet (avec quantités) : uniquement pour le personnel de cette pharmacie ou un administrateur. */
    @GetMapping
    public List<Stock> stockDeLaPharmacie(@PathVariable Long pharmacieId, HttpServletRequest requeteHttp) {
        Autorisation.exigerPharmacie(requeteHttp, pharmacieId);
        return stockService.listerParPharmacie(pharmacieId);
    }
}
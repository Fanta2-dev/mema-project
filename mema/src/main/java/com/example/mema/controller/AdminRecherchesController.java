package com.example.mema.controller;

import com.example.mema.dto.ResumeRecherches;
import com.example.mema.service.RecherchePubliqueService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Réservé à l'administrateur (vérifié par AuthInterceptor, route /admin). */
@RestController
@RequestMapping("/admin/recherches")
public class AdminRecherchesController {

    @Autowired
    private RecherchePubliqueService service;

    @GetMapping("/resume")
    public ResumeRecherches resume(@RequestParam(defaultValue = "30") int jours) {
        return service.resume(jours);
    }
}
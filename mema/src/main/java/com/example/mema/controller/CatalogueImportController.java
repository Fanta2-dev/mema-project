package com.example.mema.controller;

import com.example.mema.dto.ResultatCatalogue;
import com.example.mema.service.CatalogueImportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

/** Réservé à l'administrateur (vérifié par AuthInterceptor). */
@RestController
@RequestMapping("/medicaments/import")
public class CatalogueImportController {

    @Autowired
    private CatalogueImportService service;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResultatCatalogue importer(@RequestParam("fichier") MultipartFile fichier) throws IOException {
        return service.importer(fichier);
    }
}
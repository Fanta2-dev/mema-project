package com.example.mema.controller;

import com.example.mema.dto.ResultatImport;
import com.example.mema.service.StockImportService;
import com.example.mema.util.Autorisation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/pharmacies/{pharmacieId}/stock")
public class StockImportController {

    @Autowired
    private StockImportService importService;

    @PostMapping(value = "/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResultatImport importer(@PathVariable Long pharmacieId,
                                   @RequestParam("fichier") MultipartFile fichier,
                                   @RequestParam(value = "remplacer", defaultValue = "false") boolean remplacer,
                                   HttpServletRequest http)
            throws IOException {
        return importService.importerCsv(pharmacieId, fichier, remplacer, Autorisation.utilisateurId(http));
    }
}
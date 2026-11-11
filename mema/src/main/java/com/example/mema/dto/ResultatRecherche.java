package com.example.mema.dto;

import java.time.LocalDateTime;
import java.util.List;

/** Réponse de la recherche : les médicaments cherchés et les pharmacies classées. Jamais de quantité. */
public record ResultatRecherche(
        List<MedicamentCherche> medicaments,
        List<PharmacieTrouvee> pharmacies
) {

    public record MedicamentCherche(
            Long id,
            String code,
            String nom,
            String dosage,
            boolean top100
    ) {}

    /** statut : DISPONIBLE, INDISPONIBLE, SUR_COMMANDE ou NON_REFERENCE (la pharmacie ne le gère pas). */
    public record LigneStatut(
            Long medicamentId,
            String statut,
            boolean aVerifier,
            Double prix,
            LocalDateTime dateMiseAJour
    ) {}

    public record PharmacieTrouvee(
            Long id,
            String nom,
            String adresse,
            Double latitude,
            Double longitude,
            String telephone,
            boolean agreee,
            boolean deGarde,
            Double distanceKm,
            int nbDisponibles,
            List<LigneStatut> medicaments
    ) {}
}
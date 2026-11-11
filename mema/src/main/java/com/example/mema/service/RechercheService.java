package com.example.mema.service;

import com.example.mema.dto.ResultatRecherche;
import com.example.mema.dto.ResultatRecherche.LigneStatut;
import com.example.mema.dto.ResultatRecherche.MedicamentCherche;
import com.example.mema.dto.ResultatRecherche.PharmacieTrouvee;
import com.example.mema.model.Medicament;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.Stock;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.repository.StockRepository;
import com.example.mema.util.Geo;
import com.example.mema.util.Textes;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/** Recherche publique : le serveur fait le tri, le téléphone reçoit seulement le résultat. */
@Service
public class RechercheService {

    private static final int LIMITE_PAR_DEFAUT = 5;
    private static final int LIMITE_MAX = 20;
    private static final int MAX_MEDICAMENTS = 15;
    private static final long HEURES_AVANT_A_VERIFIER = 24;

    @Autowired
    private MedicamentRepository medicamentRepository;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private PeriodeGardeService periodeGardeService;

    @Autowired
    private RecherchePubliqueService recherchesPubliques;

    @Value("${mema.public.prix-visible:true}")
    private boolean prixVisible;

    public ResultatRecherche rechercher(List<Long> ids, String texte, Double latitude, Double longitude,
                                        Integer limiteDemandee) {
        validerPosition(latitude, longitude);
        int limite = limiteDemandee == null
                ? LIMITE_PAR_DEFAUT
                : Math.max(1, Math.min(limiteDemandee, LIMITE_MAX));

        List<Medicament> cherches = trouverMedicaments(ids, texte);
        if (cherches.isEmpty()) {
            if (texte != null && !texte.isBlank()) {
                recherchesPubliques.enregistrer(Map.of(coupe(texte.trim()), 0), latitude, longitude);
            }
            return new ResultatRecherche(List.of(), List.of());
        }

        Set<Long> idsCherches = cherches.stream()
                .map(Medicament::getId)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        List<Stock> stocks = stockRepository.findByMedicamentIdIn(idsCherches);

        Map<Long, Pharmacie> pharmacies = new LinkedHashMap<>();
        Map<Long, Map<Long, Stock>> parPharmacie = new HashMap<>();
        Map<Long, Set<Long>> disponiblesParMedicament = new HashMap<>();
        for (Stock s : stocks) {
            Long pharmacieId = s.getPharmacie().getId();
            pharmacies.putIfAbsent(pharmacieId, s.getPharmacie());
            parPharmacie.computeIfAbsent(pharmacieId, cle -> new HashMap<>())
                    .put(s.getMedicament().getId(), s);
            if (Boolean.TRUE.equals(s.getDisponible())) {
                disponiblesParMedicament
                        .computeIfAbsent(s.getMedicament().getId(), cle -> new HashSet<>())
                        .add(pharmacieId);
            }
        }

        Set<Long> deGarde = periodeGardeService.listerActives().stream()
                .map(p -> p.getPharmacie().getId())
                .collect(Collectors.toSet());
        LocalDateTime maintenant = LocalDateTime.now();
        boolean positionConnue = latitude != null && longitude != null;

        List<PharmacieTrouvee> trouvees = new ArrayList<>();
        for (Pharmacie p : pharmacies.values()) {
            Map<Long, Stock> stocksDeLaPharmacie = parPharmacie.get(p.getId());
            List<LigneStatut> lignes = new ArrayList<>();
            int nbDisponibles = 0;
            for (Medicament m : cherches) {
                Stock s = stocksDeLaPharmacie.get(m.getId());
                if (s == null) {
                    lignes.add(new LigneStatut(m.getId(), "NON_REFERENCE", false, null, null));
                    continue;
                }
                if (Boolean.TRUE.equals(s.getDisponible())) {
                    nbDisponibles++;
                }
                boolean aVerifier = Duration.between(s.getDateMiseAJour(), maintenant).toHours()
                        >= HEURES_AVANT_A_VERIFIER;
                lignes.add(new LigneStatut(m.getId(), s.calculerStatut(), aVerifier,
                        prixVisible ? s.getPrix() : null, s.getDateMiseAJour()));
            }
            // Une pharmacie qui n'a aucun des médicaments cherchés n'est pas proposée.
            if (nbDisponibles == 0) {
                continue;
            }
            Double distance = positionConnue
                    ? arrondi(Geo.distanceKm(latitude, longitude, p.getLatitude(), p.getLongitude()))
                    : null;
            trouvees.add(new PharmacieTrouvee(
                    p.getId(), p.getNom(), p.getAdresse(), p.getLatitude(), p.getLongitude(),
                    p.getTelephone(), Boolean.TRUE.equals(p.getAgreee()), deGarde.contains(p.getId()),
                    distance, nbDisponibles, lignes));
        }

        // Le plus de médicaments disponibles d'abord, puis la plus proche, puis par nom.
        trouvees.sort(Comparator
                .comparingInt(PharmacieTrouvee::nbDisponibles).reversed()
                .thenComparing(PharmacieTrouvee::distanceKm, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(PharmacieTrouvee::nom));
        List<PharmacieTrouvee> retenues = trouvees.size() > limite
                ? new ArrayList<>(trouvees.subList(0, limite))
                : trouvees;

        // Statistiques anonymes : pour chaque médicament cherché, combien de pharmacies l'ont.
        Map<String, Integer> compteurs = new LinkedHashMap<>();
        for (Medicament m : cherches) {
            String terme = m.getCode() != null ? m.getCode() : m.getNom();
            compteurs.put(terme, disponiblesParMedicament.getOrDefault(m.getId(), Set.of()).size());
        }
        recherchesPubliques.enregistrer(compteurs, latitude, longitude);

        List<MedicamentCherche> infos = cherches.stream()
                .map(m -> new MedicamentCherche(m.getId(), m.getCode(), m.getNom(), m.getDosage(), m.getTop100()))
                .toList();
        return new ResultatRecherche(infos, retenues);
    }

    private List<Medicament> trouverMedicaments(List<Long> ids, String texte) {
        if (ids != null && !ids.isEmpty()) {
            if (ids.size() > MAX_MEDICAMENTS) {
                throw new IllegalArgumentException(
                        "Trop de médicaments dans une même recherche (" + MAX_MEDICAMENTS + " au maximum).");
            }
            return new ArrayList<>(medicamentRepository.findAllById(ids));
        }
        if (texte == null || texte.isBlank()) {
            throw new IllegalArgumentException("Indiquez un médicament : paramètre « ids » ou « medicament ».");
        }

        String cle = Textes.normaliser(texte);
        if (cle.length() < 2) {
            throw new IllegalArgumentException("Tapez au moins 2 lettres.");
        }
        String cleCompacte = cle.replace(" ", "");
        List<Medicament> resultat = new ArrayList<>();
        for (Medicament m : medicamentRepository.findAll()) {
            boolean correspond = Textes.normaliser(m.getNom()).contains(cle)
                    || (m.getDci() != null && Textes.normaliser(m.getDci()).contains(cle))
                    || (m.getCode() != null && Textes.compact(m.getCode()).contains(cleCompacte));
            if (correspond) {
                resultat.add(m);
            }
        }
        // Les médicaments de la liste TOP 100 d'abord, puis par nom.
        resultat.sort(Comparator
                .comparing((Medicament m) -> !m.getTop100())
                .thenComparing(Medicament::getNom));
        if (resultat.size() > MAX_MEDICAMENTS) {
            resultat = new ArrayList<>(resultat.subList(0, MAX_MEDICAMENTS));
        }
        return resultat;
    }

    private void validerPosition(Double latitude, Double longitude) {
        if ((latitude == null) != (longitude == null)) {
            throw new IllegalArgumentException("Indiquez la latitude et la longitude ensemble.");
        }
        if (latitude != null && (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)) {
            throw new IllegalArgumentException("Position invalide.");
        }
    }

    private static double arrondi(double valeur) {
        return Math.round(valeur * 100.0) / 100.0;
    }

    private static String coupe(String texte) {
        return texte.length() > 120 ? texte.substring(0, 120) : texte;
    }
}
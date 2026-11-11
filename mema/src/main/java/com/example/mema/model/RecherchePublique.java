package com.example.mema.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/**
 * Une recherche faite par le public, sans aucune donnée personnelle :
 * ni nom, ni téléphone, ni adresse IP, ni ordonnance. La zone est arrondie (environ 1 km).
 */
@Entity
@Table(name = "recherches_publiques")
public class RecherchePublique {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Code du médicament cherché, ou le texte tapé si rien n'a été trouvé. */
    @Column(nullable = false, length = 120)
    private String medicamentRecherche;

    /** Nombre de pharmacies où il était disponible au moment de la recherche. */
    @Column(nullable = false)
    private Integer nbPharmacies = 0;

    private Double zoneLatitude;

    private Double zoneLongitude;

    @Column(nullable = false)
    private LocalDateTime dateRecherche = LocalDateTime.now();

    public RecherchePublique() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getMedicamentRecherche() { return medicamentRecherche; }
    public void setMedicamentRecherche(String medicamentRecherche) { this.medicamentRecherche = medicamentRecherche; }

    public Integer getNbPharmacies() { return nbPharmacies; }
    public void setNbPharmacies(Integer nbPharmacies) { this.nbPharmacies = nbPharmacies; }

    public Double getZoneLatitude() { return zoneLatitude; }
    public void setZoneLatitude(Double zoneLatitude) { this.zoneLatitude = zoneLatitude; }

    public Double getZoneLongitude() { return zoneLongitude; }
    public void setZoneLongitude(Double zoneLongitude) { this.zoneLongitude = zoneLongitude; }

    public LocalDateTime getDateRecherche() { return dateRecherche; }
    public void setDateRecherche(LocalDateTime dateRecherche) { this.dateRecherche = dateRecherche; }
}
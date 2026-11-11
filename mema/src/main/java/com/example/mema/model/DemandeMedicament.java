package com.example.mema.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/** Un nom de médicament absent du catalogue, signalé par une pharmacie lors d'un import. */
@Entity
@Table(name = "demande_medicament")
public class DemandeMedicament {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "pharmacie_id")
    private Pharmacie pharmacie;

    @Column(nullable = false)
    private String nom;

    @Column(nullable = false)
    private LocalDateTime dateDemande = LocalDateTime.now();

    @Column(nullable = false)
    private Boolean traitee = false;

    public DemandeMedicament() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Pharmacie getPharmacie() { return pharmacie; }
    public void setPharmacie(Pharmacie pharmacie) { this.pharmacie = pharmacie; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public LocalDateTime getDateDemande() { return dateDemande; }
    public void setDateDemande(LocalDateTime dateDemande) { this.dateDemande = dateDemande; }

    public Boolean getTraitee() { return traitee; }
    public void setTraitee(Boolean traitee) { this.traitee = traitee; }
}
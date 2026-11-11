package com.example.mema.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

import java.time.LocalDateTime;

/** Demande d'inscription d'une pharmacie et de son responsable, en attente de vérification. */
@Entity
@Table(name = "demande_inscription")
public class DemandeInscription {

    public enum Statut { EN_ATTENTE, VALIDEE, REFUSEE }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String pharmacieNom;

    @Column(nullable = false)
    private String pharmacieAdresse;

    @Column(nullable = false)
    private Double pharmacieLatitude;

    @Column(nullable = false)
    private Double pharmacieLongitude;

    @Column(nullable = false)
    private String pharmacieTelephone;

    @Column(nullable = false)
    private String numeroAgrement;

    @Column(nullable = false)
    private String responsableNom;

    @Column(nullable = false)
    private String responsableTelephone;

    @JsonIgnore
    @Column(nullable = false)
    private String motDePasseHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Statut statut = Statut.EN_ATTENTE;

    private String motifRefus;

    @Column(nullable = false)
    private LocalDateTime dateDemande = LocalDateTime.now();

    private LocalDateTime dateDecision;

    /** Identifiant de l'administrateur qui a validé ou refusé. */
    private Long decidePar;

    public DemandeInscription() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getPharmacieNom() { return pharmacieNom; }
    public void setPharmacieNom(String pharmacieNom) { this.pharmacieNom = pharmacieNom; }

    public String getPharmacieAdresse() { return pharmacieAdresse; }
    public void setPharmacieAdresse(String pharmacieAdresse) { this.pharmacieAdresse = pharmacieAdresse; }

    public Double getPharmacieLatitude() { return pharmacieLatitude; }
    public void setPharmacieLatitude(Double pharmacieLatitude) { this.pharmacieLatitude = pharmacieLatitude; }

    public Double getPharmacieLongitude() { return pharmacieLongitude; }
    public void setPharmacieLongitude(Double pharmacieLongitude) { this.pharmacieLongitude = pharmacieLongitude; }

    public String getPharmacieTelephone() { return pharmacieTelephone; }
    public void setPharmacieTelephone(String pharmacieTelephone) { this.pharmacieTelephone = pharmacieTelephone; }

    public String getNumeroAgrement() { return numeroAgrement; }
    public void setNumeroAgrement(String numeroAgrement) { this.numeroAgrement = numeroAgrement; }

    public String getResponsableNom() { return responsableNom; }
    public void setResponsableNom(String responsableNom) { this.responsableNom = responsableNom; }

    public String getResponsableTelephone() { return responsableTelephone; }
    public void setResponsableTelephone(String responsableTelephone) { this.responsableTelephone = responsableTelephone; }

    public String getMotDePasseHash() { return motDePasseHash; }
    public void setMotDePasseHash(String motDePasseHash) { this.motDePasseHash = motDePasseHash; }

    public Statut getStatut() { return statut; }
    public void setStatut(Statut statut) { this.statut = statut; }

    public String getMotifRefus() { return motifRefus; }
    public void setMotifRefus(String motifRefus) { this.motifRefus = motifRefus; }

    public LocalDateTime getDateDemande() { return dateDemande; }
    public void setDateDemande(LocalDateTime dateDemande) { this.dateDemande = dateDemande; }

    public LocalDateTime getDateDecision() { return dateDecision; }
    public void setDateDecision(LocalDateTime dateDecision) { this.dateDecision = dateDecision; }

    public Long getDecidePar() { return decidePar; }
    public void setDecidePar(Long decidePar) { this.decidePar = decidePar; }
}
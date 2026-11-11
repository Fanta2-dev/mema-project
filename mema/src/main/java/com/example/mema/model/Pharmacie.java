package com.example.mema.model;

import jakarta.persistence.*;

@Entity
@Table(name = "pharmacie")
public class Pharmacie {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    @Column(nullable = false)
    private String adresse;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false)
    private String telephone;

    @Column(nullable = false)
    private Boolean agreee = false;
    private String numeroAgrement;

    public Pharmacie() {}

    public Long getId() {
        return id;
    } 

    public void setId(Long id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public String getTelephone() {
        return telephone;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
    }

    public Boolean getAgreee() {
        return agreee;
    }

    public void setAgreee(Boolean agreee) {
        this.agreee = agreee;
    }

    public String getNumeroAgrement() {
        return numeroAgrement;
    }

    public void setNumeroAgrement(String numeroAgrement) {
        this.numeroAgrement = numeroAgrement;
    }
}

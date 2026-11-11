package com.example.mema.model;

import jakarta.persistence.*;

@Entity
@Table(name = "medicament")
public class Medicament {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    private String dci;

    @Column(nullable = false)
    private String dosage;

    @Column(nullable = false)
    private String categorie;

    /** Code lisible et unique, par exemple PARACETAMOL_500. */
    @Column(unique = true, length = 80)
    private String code;

    /** Fait partie de la liste des 100 médicaments de référence du test. */
    private Boolean top100;

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getDci() {
        return dci;
    }

    public void setDci(String dci) {
        this.dci = dci;
    }

    public String getDosage() {
        return dosage;
    }

    public void setDosage(String dosage) {
        this.dosage = dosage;
    }

    public String getCategorie() {
        return categorie;
    }

    public void setCategorie(String categorie) {
        this.categorie = categorie;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    /** Jamais null : un médicament non marqué n'est pas dans le TOP 100. */
    public Boolean getTop100() {
        return Boolean.TRUE.equals(top100);
    }

    public void setTop100(Boolean top100) {
        this.top100 = top100;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
}
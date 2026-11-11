package com.example.mema.model;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "utilisateur")


public class Utilisateur {
    public enum Role {PHARMACIEN, AGENT, ADMIN}
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name ="pharmacie_id")
    private Pharmacie pharmacie;


    @Column(nullable = false)
    private String nom;

    @Column(nullable = false, unique = true)
    private String telephone;

    @JsonIgnore
    @Column(nullable = false)
    private String motDePasseHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;


    public Utilisateur() {}

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Pharmacie getPharmacie() {
        return pharmacie;
    }

    public void setPharmacie(Pharmacie pharmacie) {
        this.pharmacie = pharmacie;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getTelephone() {
        return telephone;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
    }

    public String getMotDePasseHash() {
        return motDePasseHash;
    }

    public void setMotDePasseHash(String motDePasseHash) {
        this.motDePasseHash = motDePasseHash;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }
}

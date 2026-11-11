package com.example.mema.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

import java.time.LocalDateTime;

/** Clé API d'une pharmacie, pour son connecteur. Seule l'empreinte de la clé est conservée. */
@Entity
@Table(name = "cle_api_pharmacie", uniqueConstraints = @UniqueConstraint(columnNames = "pharmacie_id"))
public class CleApiPharmacie {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "pharmacie_id")
    private Pharmacie pharmacie;

    @JsonIgnore
    @Column(nullable = false, unique = true, length = 64)
    private String empreinte;

    /** Début de la clé, pour la reconnaître sans la révéler. */
    @Column(nullable = false, length = 20)
    private String prefixe;

    @Column(nullable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();

    private LocalDateTime derniereUtilisation;

    @Column(nullable = false)
    private Boolean active = true;

    public CleApiPharmacie() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Pharmacie getPharmacie() { return pharmacie; }
    public void setPharmacie(Pharmacie pharmacie) { this.pharmacie = pharmacie; }

    public String getEmpreinte() { return empreinte; }
    public void setEmpreinte(String empreinte) { this.empreinte = empreinte; }

    public String getPrefixe() { return prefixe; }
    public void setPrefixe(String prefixe) { this.prefixe = prefixe; }

    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime dateCreation) { this.dateCreation = dateCreation; }

    public LocalDateTime getDerniereUtilisation() { return derniereUtilisation; }
    public void setDerniereUtilisation(LocalDateTime derniereUtilisation) { this.derniereUtilisation = derniereUtilisation; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }
}
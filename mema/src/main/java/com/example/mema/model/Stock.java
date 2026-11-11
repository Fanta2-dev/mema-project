package com.example.mema.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "stock",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"pharmacie_id", "medicament_id"})
        },
        indexes = {
                @Index(name = "idx_stock_medicament", columnList = "medicament_id")
        })
public class Stock {

    public static final String SOURCE_MANUEL = "MANUEL";
    public static final String SOURCE_IMPORT = "IMPORT_CSV";
    public static final String SOURCE_CONNECTEUR = "CONNECTEUR";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "pharmacie_id")
    private Pharmacie pharmacie;

    @ManyToOne(optional = false)
    @JoinColumn(name = "medicament_id")
    private Medicament medicament;

    @Column(nullable = false)
    private Boolean disponible = false;

    /** Commandé auprès du fournisseur, pas encore en stock. Vide = non. */
    private Boolean surCommande = false;

    /** Origine de la dernière mise à jour : MANUEL, IMPORT_CSV ou CONNECTEUR. */
    @Column(length = 30)
    private String source;

    /** Facultative : un logiciel de pharmacie peut ne transmettre que le statut. */
    private Integer quantite = 0;

    /** Facultatif, pour la même raison. */
    private Double prix;

    @ManyToOne
    @JoinColumn(name = "mise_a_jour_par_id")
    private Utilisateur miseAJourPar;

    @Column(nullable = false)
    private LocalDateTime dateMiseAJour = LocalDateTime.now();

    public Stock() {}

    /** DISPONIBLE, SUR_COMMANDE ou INDISPONIBLE. */
    public String calculerStatut() {
        if (Boolean.TRUE.equals(disponible)) {
            return "DISPONIBLE";
        }
        return Boolean.TRUE.equals(surCommande) ? "SUR_COMMANDE" : "INDISPONIBLE";
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Pharmacie getPharmacie() { return pharmacie; }
    public void setPharmacie(Pharmacie pharmacie) { this.pharmacie = pharmacie; }

    public Medicament getMedicament() { return medicament; }
    public void setMedicament(Medicament medicament) { this.medicament = medicament; }

    public Boolean getDisponible() { return disponible; }
    public void setDisponible(Boolean disponible) { this.disponible = disponible; }

    public Boolean getSurCommande() { return surCommande; }
    public void setSurCommande(Boolean surCommande) { this.surCommande = surCommande; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public Integer getQuantite() { return quantite; }
    public void setQuantite(Integer quantite) { this.quantite = quantite; }

    public Double getPrix() { return prix; }
    public void setPrix(Double prix) { this.prix = prix; }

    public Utilisateur getMiseAJourPar() { return miseAJourPar; }
    public void setMiseAJourPar(Utilisateur miseAJourPar) { this.miseAJourPar = miseAJourPar; }

    public LocalDateTime getDateMiseAJour() { return dateMiseAJour; }
    public void setDateMiseAJour(LocalDateTime dateMiseAJour) { this.dateMiseAJour = dateMiseAJour; }
}
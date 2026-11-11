package com.example.mema.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/** Journal : qui a fait quoi, et quand (preuve en cas de litige). */
@Entity
@Table(name = "journal_logs")
public class JournalAction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long pharmacieId;

    private Long utilisateurId;

    /** Par exemple CHANGEMENT_STATUT, CONNEXION, ERREUR_CONNECTEUR, IMPORT_STOCK, CLE_API_GENEREE. */
    @Column(nullable = false, length = 40)
    private String action;

    @Column(length = 500)
    private String details;

    @Column(nullable = false)
    private LocalDateTime dateAction = LocalDateTime.now();

    public JournalAction() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getPharmacieId() { return pharmacieId; }
    public void setPharmacieId(Long pharmacieId) { this.pharmacieId = pharmacieId; }

    public Long getUtilisateurId() { return utilisateurId; }
    public void setUtilisateurId(Long utilisateurId) { this.utilisateurId = utilisateurId; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public LocalDateTime getDateAction() { return dateAction; }
    public void setDateAction(LocalDateTime dateAction) { this.dateAction = dateAction; }
}
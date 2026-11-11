package com.example.mema.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "alerte")
public class Alerte {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "medicament_id")
    private Medicament medicament;

    @ManyToOne(optional = false)
    @JoinColumn(name = "pharmacie_id")
    private Pharmacie pharmacie;

    @Column(nullable = false)
    private String telephonePatient;

    @Column(nullable = false)
    private Boolean notifie = false;

    @Column(nullable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();

    public Alerte() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Medicament getMedicament() { return medicament; }
    public void setMedicament(Medicament medicament) { this.medicament = medicament; }

    public Pharmacie getPharmacie() { return pharmacie; }
    public void setPharmacie(Pharmacie pharmacie) { this.pharmacie = pharmacie; }

    public String getTelephonePatient() { return telephonePatient; }
    public void setTelephonePatient(String telephonePatient) { this.telephonePatient = telephonePatient; }

    public Boolean getNotifie() { return notifie; }
    public void setNotifie(Boolean notifie) { this.notifie = notifie; }

    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime dateCreation) { this.dateCreation = dateCreation; }
}
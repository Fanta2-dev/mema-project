package com.example.mema.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "periode_garde")
public class PeriodeGarde {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "pharmacie_id")
    private Pharmacie pharmacie;

    @Column(nullable = false)
    private String zone;

    @Column(nullable = false)
    private LocalDateTime dateDebut;

    @Column(nullable = false)
    private LocalDateTime dateFin;

    private String source;

    public PeriodeGarde() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Pharmacie getPharmacie() { return pharmacie; }
    public void setPharmacie(Pharmacie pharmacie) { this.pharmacie = pharmacie; }

    public String getZone() { return zone; }
    public void setZone(String zone) { this.zone = zone; }

    public LocalDateTime getDateDebut() { return dateDebut; }
    public void setDateDebut(LocalDateTime dateDebut) { this.dateDebut = dateDebut; }

    public LocalDateTime getDateFin() { return dateFin; }
    public void setDateFin(LocalDateTime dateFin) { this.dateFin = dateFin; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
}
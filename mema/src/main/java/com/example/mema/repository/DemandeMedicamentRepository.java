package com.example.mema.repository;

import com.example.mema.model.DemandeMedicament;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DemandeMedicamentRepository extends JpaRepository<DemandeMedicament, Long> {

    List<DemandeMedicament> findByTraiteeFalseOrderByDateDemandeDesc();

    List<DemandeMedicament> findByTraiteeFalse();

    List<DemandeMedicament> findByPharmacieIdAndTraiteeFalse(Long pharmacieId);
}
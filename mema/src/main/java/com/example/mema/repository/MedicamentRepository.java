package com.example.mema.repository;

import com.example.mema.model.Medicament;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MedicamentRepository extends JpaRepository<Medicament, Long> {

    Optional<Medicament> findFirstByNomIgnoreCase(String nom);

    Optional<Medicament> findByCode(String code);

    List<Medicament> findByCodeIsNull();
}
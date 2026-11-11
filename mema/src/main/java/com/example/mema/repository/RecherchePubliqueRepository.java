package com.example.mema.repository;

import com.example.mema.model.RecherchePublique;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface RecherchePubliqueRepository extends JpaRepository<RecherchePublique, Long> {

    List<RecherchePublique> findByDateRechercheAfter(LocalDateTime date);
}
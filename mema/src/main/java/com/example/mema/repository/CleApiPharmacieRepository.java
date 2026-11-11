package com.example.mema.repository;

import com.example.mema.model.CleApiPharmacie;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CleApiPharmacieRepository extends JpaRepository<CleApiPharmacie, Long> {

    Optional<CleApiPharmacie> findByEmpreinteAndActiveTrue(String empreinte);

    Optional<CleApiPharmacie> findByPharmacieId(Long pharmacieId);
}
package com.example.mema.repository;

import com.example.mema.model.Stock;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface StockRepository extends JpaRepository<Stock, Long> {

    Optional<Stock> findByPharmacieIdAndMedicamentId(Long pharmacieId, Long medicamentId);

    List<Stock> findByPharmacieId(Long pharmacieId);

    /** Seulement les stocks des médicaments cherchés : c'est ce qui rend la recherche rapide. */
    List<Stock> findByMedicamentIdIn(Collection<Long> medicamentIds);
}
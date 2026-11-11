package com.example.mema.repository;

import com.example.mema.model.JournalAction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JournalRepository extends JpaRepository<JournalAction, Long> {

    List<JournalAction> findTop200ByOrderByDateActionDesc();

    List<JournalAction> findTop200ByPharmacieIdOrderByDateActionDesc(Long pharmacieId);
}
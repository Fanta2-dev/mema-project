package com.example.mema.repository;

import com.example.mema.model.Alerte;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AlerteRepository extends JpaRepository<Alerte, Long> {
}
package com.example.mema.repository;

import com.example.mema.model.Utilisateur;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {

    Optional<Utilisateur> findByTelephone(String telephone);

    boolean existsByRole(Utilisateur.Role role);
}
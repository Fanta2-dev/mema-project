package com.example.mema.repository;

import com.example.mema.model.DemandeInscription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DemandeInscriptionRepository extends JpaRepository<DemandeInscription, Long> {

    List<DemandeInscription> findByStatutOrderByDateDemandeDesc(DemandeInscription.Statut statut);

    boolean existsByResponsableTelephoneAndStatut(String telephone, DemandeInscription.Statut statut);

    Optional<DemandeInscription> findFirstByResponsableTelephoneOrderByDateDemandeDesc(String telephone);
}
package com.example.mema.service;

import com.example.mema.model.JournalAction;
import com.example.mema.repository.JournalRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;

@Service
public class JournalService {

    private final JournalRepository repository;
    private final TransactionTemplate transactionIndependante;

    public JournalService(JournalRepository repository, PlatformTransactionManager gestionnaire) {
        this.repository = repository;
        this.transactionIndependante = new TransactionTemplate(gestionnaire);
        this.transactionIndependante.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    /** Enregistre une action. En cas de problème, l'opération principale n'est pas affectée. */
    public void enregistrer(Long pharmacieId, Long utilisateurId, String action, String details) {
        try {
            JournalAction a = new JournalAction();
            a.setPharmacieId(pharmacieId);
            a.setUtilisateurId(utilisateurId);
            a.setAction(action);
            a.setDetails(details != null && details.length() > 500 ? details.substring(0, 500) : details);
            transactionIndependante.executeWithoutResult(statut -> repository.save(a));
        } catch (Exception e) {
            System.err.println(">>> Journal : enregistrement impossible : " + e.getMessage());
        }
    }

    public List<JournalAction> recents(Long pharmacieId) {
        if (pharmacieId == null) {
            return repository.findTop200ByOrderByDateActionDesc();
        }
        return repository.findTop200ByPharmacieIdOrderByDateActionDesc(pharmacieId);
    }
}
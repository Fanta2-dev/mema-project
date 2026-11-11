package com.example.mema.config;

import com.example.mema.model.Medicament;
import com.example.mema.model.Pharmacie;
import com.example.mema.model.Utilisateur;
import com.example.mema.repository.MedicamentRepository;
import com.example.mema.repository.PharmacieRepository;
import com.example.mema.repository.UtilisateurRepository;
import com.example.mema.util.TelephoneUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataSeeder implements CommandLineRunner {

    private final MedicamentRepository medicamentRepository;
    private final PharmacieRepository pharmacieRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${mema.admin.telephone:}")
    private String adminTelephone;

    @Value("${mema.admin.mot-de-passe:}")
    private String adminMotDePasse;

    @Value("${mema.demo.pharmacien.telephone:}")
    private String pharmacienTelephone;

    @Value("${mema.demo.pharmacien.mot-de-passe:}")
    private String pharmacienMotDePasse;

    public DataSeeder(MedicamentRepository medicamentRepository,
                      PharmacieRepository pharmacieRepository,
                      UtilisateurRepository utilisateurRepository,
                      PasswordEncoder passwordEncoder) {
        this.medicamentRepository = medicamentRepository;
        this.pharmacieRepository = pharmacieRepository;
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        if (medicamentRepository.count() == 0) {
            medicamentRepository.save(creerMedicament("Propranolol", "Propranolol", "40 mg, comprimé", "Cardiologie"));
            medicamentRepository.save(creerMedicament("Peptex", null, "Sirop, 200 ml", "Digestif"));
            medicamentRepository.save(creerMedicament("Anna Fenugrec", null, "Gélules, boîte de 60", "Phytothérapie"));
            medicamentRepository.save(creerMedicament("Inexium", "Esoméprazole", "20 mg, comprimé", "Digestif"));
            medicamentRepository.save(creerMedicament("Diantalex", "Paracétamol", "500 mg, comprimé", "Antalgique"));
            System.out.println(">>> 5 médicaments de démonstration insérés");
        }

        if (pharmacieRepository.count() == 0) {
            Pharmacie p = new Pharmacie();
            p.setNom("Pharmacie Awa Santé");
            p.setAdresse("Avenue Cheikh Anta Diop, Dakar");
            p.setLatitude(14.6947);
            p.setLongitude(-17.4633);
            p.setTelephone(TelephoneUtils.normaliserEtValider("33 825 00 00"));
            p.setAgreee(true);
            p.setNumeroAgrement("SN-PH-2026-001");
            pharmacieRepository.save(p);
            System.out.println(">>> Pharmacie de démonstration insérée");
        }

        // Comptes de démonstration : créés seulement s'il n'existe pas déjà un compte de ce type.
        if (!utilisateurRepository.existsByRole(Utilisateur.Role.ADMIN)) {
            creerUtilisateur(adminTelephone, adminMotDePasse, "Administrateur MEMA",
                    Utilisateur.Role.ADMIN, null);
        }
        if (!utilisateurRepository.existsByRole(Utilisateur.Role.PHARMACIEN)) {
            Pharmacie demo = pharmacieRepository.findAll().stream().findFirst().orElse(null);
            if (demo != null) {
                creerUtilisateur(pharmacienTelephone, pharmacienMotDePasse, "Pharmacien de démonstration",
                        Utilisateur.Role.PHARMACIEN, demo);
            }
        }
    }

    private void creerUtilisateur(String telephone, String motDePasse, String nom,
                                  Utilisateur.Role role, Pharmacie pharmacie) {
        if (telephone == null || telephone.isBlank() || motDePasse == null || motDePasse.isBlank()) {
            return;
        }
        String tel = TelephoneUtils.normaliserEtValider(telephone);
        if (utilisateurRepository.findByTelephone(tel).isPresent()) {
            return;
        }
        Utilisateur u = new Utilisateur();
        u.setNom(nom);
        u.setTelephone(tel);
        u.setMotDePasseHash(passwordEncoder.encode(motDePasse));
        u.setRole(role);
        u.setPharmacie(pharmacie);
        utilisateurRepository.save(u);
        System.out.println(">>> Compte " + role + " de démonstration créé : " + tel);
    }

    private Medicament creerMedicament(String nom, String dci, String dosage, String categorie) {
        Medicament m = new Medicament();
        m.setNom(nom);
        m.setDci(dci);
        m.setDosage(dosage);
        m.setCategorie(categorie);
        return m;
    }
}
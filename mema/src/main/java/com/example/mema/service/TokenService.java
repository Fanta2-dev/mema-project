package com.example.mema.service;

import com.example.mema.model.Utilisateur;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;

@Service
public class TokenService {

    /** Ce que le serveur sait d'une personne connectée. */
    public record SessionInfo(Long utilisateurId, Long pharmacieId, Utilisateur.Role role) {}

    public static final long DUREE_SECONDES = 12 * 60 * 60L;

    private final byte[] secret;

    public TokenService(@Value("${mema.token.secret:}") String secretConfigure) {
        byte[] cle;
        if (secretConfigure == null || secretConfigure.isBlank()) {
            cle = new byte[32];
            new SecureRandom().nextBytes(cle);
            System.out.println(">>> mema.token.secret non défini : secret aléatoire "
                    + "(il faudra se reconnecter après chaque redémarrage du serveur)");
        } else {
            cle = secretConfigure.getBytes(StandardCharsets.UTF_8);
        }
        this.secret = cle;
    }

    public String creer(Utilisateur u) {
        long expiration = Instant.now().getEpochSecond() + DUREE_SECONDES;
        Long pharmacieId = u.getPharmacie() != null ? u.getPharmacie().getId() : null;
        String charge = u.getId() + ":" + (pharmacieId != null ? pharmacieId : 0L)
                + ":" + u.getRole().name() + ":" + expiration;
        String partie = encoder(charge.getBytes(StandardCharsets.UTF_8));
        return partie + "." + encoder(signer(partie));
    }

    public Optional<SessionInfo> verifier(String token) {
        try {
            if (token == null) {
                return Optional.empty();
            }
            String[] parties = token.split("\\.");
            if (parties.length != 2) {
                return Optional.empty();
            }
            byte[] attendue = signer(parties[0]);
            byte[] recue = Base64.getUrlDecoder().decode(parties[1]);
            if (!MessageDigest.isEqual(attendue, recue)) {
                return Optional.empty();
            }
            String charge = new String(Base64.getUrlDecoder().decode(parties[0]), StandardCharsets.UTF_8);
            String[] champs = charge.split(":");
            if (champs.length != 4) {
                return Optional.empty();
            }
            if (Instant.now().getEpochSecond() > Long.parseLong(champs[3])) {
                return Optional.empty();
            }
            Long pharmacieId = Long.valueOf(champs[1]);
            return Optional.of(new SessionInfo(
                    Long.valueOf(champs[0]),
                    pharmacieId == 0L ? null : pharmacieId,
                    Utilisateur.Role.valueOf(champs[2])
            ));
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    private byte[] signer(String donnees) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return mac.doFinal(donnees.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("Signature impossible", e);
        }
    }

    private static String encoder(byte[] octets) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(octets);
    }
}
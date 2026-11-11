package com.example.mema.util;

import com.example.mema.model.Utilisateur;
import com.example.mema.service.TokenService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

public final class Autorisation {

    public static final String ATTRIBUT_SESSION = "memaSession";

    private Autorisation() {}

    /** Refuse (403) si la personne connectée n'est pas de cette pharmacie. L'administrateur passe partout. */
    public static void exigerPharmacie(HttpServletRequest requete, Long pharmacieId) {
        Object attribut = requete.getAttribute(ATTRIBUT_SESSION);
        if (!(attribut instanceof TokenService.SessionInfo session)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Connexion requise.");
        }
        if (session.role() == Utilisateur.Role.ADMIN) {
            return;
        }
        if (session.pharmacieId() == null || !session.pharmacieId().equals(pharmacieId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cette pharmacie n'est pas la vôtre.");
        }
    }

    /** Identifiant de la personne connectée, ou null si la demande n'est pas authentifiée. */
    public static Long utilisateurId(HttpServletRequest requete) {
        Object attribut = requete.getAttribute(ATTRIBUT_SESSION);
        if (attribut instanceof TokenService.SessionInfo session) {
            return session.utilisateurId();
        }
        return null;
    }
}
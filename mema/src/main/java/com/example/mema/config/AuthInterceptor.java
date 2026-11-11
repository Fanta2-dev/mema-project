package com.example.mema.config;

import com.example.mema.model.PeriodeGarde;
import com.example.mema.model.Stock;
import com.example.mema.model.Utilisateur;
import com.example.mema.repository.PeriodeGardeRepository;
import com.example.mema.repository.StockRepository;
import com.example.mema.service.TokenService;
import com.example.mema.util.Autorisation;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class AuthInterceptor implements HandlerInterceptor {

    private static final Pattern STOCK_ID = Pattern.compile("^/stocks/(\\d+)(/.*)?$");
    private static final Pattern GARDE_ID = Pattern.compile("^/periodes-garde/(\\d+)$");
    /** Stock détaillé d'une pharmacie (lecture) et import de stock : réservés à cette pharmacie. */
    private static final Pattern STOCK_PHARMACIE = Pattern.compile("^/pharmacies/(\\d+)/stock(/import)?$");

    private final TokenService tokenService;
    private final StockRepository stockRepository;
    private final PeriodeGardeRepository periodeGardeRepository;

    public AuthInterceptor(TokenService tokenService,
                           StockRepository stockRepository,
                           PeriodeGardeRepository periodeGardeRepository) {
        this.tokenService = tokenService;
        this.stockRepository = stockRepository;
        this.periodeGardeRepository = periodeGardeRepository;
    }

    @Override
    public boolean preHandle(HttpServletRequest requete, HttpServletResponse reponse, Object handler)
            throws IOException {
        String methode = requete.getMethod();
        String chemin = requete.getRequestURI();

        // Le stock détaillé (avec les quantités) n'est jamais public, même en lecture.
        boolean stockPrive = "GET".equals(methode) && STOCK_PHARMACIE.matcher(chemin).matches();

        if ("OPTIONS".equals(methode) || (!stockPrive && estPublic(methode, chemin))) {
            return true;
        }

        Optional<TokenService.SessionInfo> trouvee = lireSession(requete);
        if (trouvee.isEmpty()) {
            return refuser(reponse, 401, "Connexion requise.");
        }
        TokenService.SessionInfo session = trouvee.get();
        requete.setAttribute(Autorisation.ATTRIBUT_SESSION, session);

        // L'administrateur a tous les droits.
        if (session.role() == Utilisateur.Role.ADMIN) {
            return true;
        }

        // --- Personnel de pharmacie (PHARMACIEN, AGENT) : uniquement SA pharmacie ---
        Matcher m = STOCK_PHARMACIE.matcher(chemin);
        if (m.matches()) {
            return exigerPharmacie(reponse, session, Long.valueOf(m.group(1)));
        }

        if (chemin.startsWith("/pharmacies") || chemin.startsWith("/medicaments")
                || chemin.startsWith("/utilisateurs") || chemin.startsWith("/alertes")
                || chemin.startsWith("/demandes-medicaments") || chemin.startsWith("/inscriptions")
                || chemin.startsWith("/admin")) {
            return refuser(reponse, 403, "Action réservée à l'administrateur.");
        }

        m = STOCK_ID.matcher(chemin);
        if (m.matches()) {
            Optional<Stock> stock = stockRepository.findById(Long.valueOf(m.group(1)));
            if (stock.isEmpty()) {
                return true; // le contrôleur répondra 404
            }
            return exigerPharmacie(reponse, session, stock.get().getPharmacie().getId());
        }

        m = GARDE_ID.matcher(chemin);
        if (m.matches()) {
            Optional<PeriodeGarde> periode = periodeGardeRepository.findById(Long.valueOf(m.group(1)));
            if (periode.isEmpty()) {
                return true;
            }
            return exigerPharmacie(reponse, session, periode.get().getPharmacie().getId());
        }

        // Création : la pharmacie est dans le corps de la demande, donc vérifiée dans le contrôleur.
        boolean creationStock = "POST".equals(methode) && chemin.equals("/stocks");
        boolean creationGarde = "POST".equals(methode) && chemin.equals("/periodes-garde");
        if (creationStock || creationGarde) {
            return true;
        }

        return refuser(reponse, 403, "Action non autorisée.");
    }

    /** Ce que tout le monde (patients compris) peut faire sans se connecter. */
    private boolean estPublic(String methode, String chemin) {
        if ("GET".equals(methode) || "HEAD".equals(methode)) {
            return chemin.startsWith("/stocks") || chemin.startsWith("/medicaments")
                    || chemin.startsWith("/pharmacies") || chemin.startsWith("/periodes-garde");
        }
        if ("POST".equals(methode)) {
            return chemin.equals("/alertes") || chemin.equals("/inscriptions");
        }
        return false;
    }

    private Optional<TokenService.SessionInfo> lireSession(HttpServletRequest requete) {
        String entete = requete.getHeader("Authorization");
        if (entete == null || !entete.startsWith("Bearer ")) {
            return Optional.empty();
        }
        return tokenService.verifier(entete.substring(7).trim());
    }

    private boolean exigerPharmacie(HttpServletResponse reponse, TokenService.SessionInfo session,
                                    Long pharmacieId) throws IOException {
        if (session.pharmacieId() != null && session.pharmacieId().equals(pharmacieId)) {
            return true;
        }
        return refuser(reponse, 403, "Cette pharmacie n'est pas la vôtre.");
    }

    private boolean refuser(HttpServletResponse reponse, int statut, String message) throws IOException {
        reponse.setStatus(statut);
        reponse.setContentType("application/json;charset=UTF-8");
        reponse.getWriter().write("{\"erreur\":\"" + message + "\"}");
        return false;
    }
}
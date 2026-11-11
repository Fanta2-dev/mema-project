import 'package:flutter/material.dart';
import '../models/medicament.dart';
import '../models/recherche.dart';
import '../services/recherche_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/geo.dart';
import '../utils/lanceurs.dart';
import '../widgets/mema_widgets.dart';

class ResultsScreen extends StatefulWidget {
  final List<Medicament> medicaments;
  final double? latitude;
  final double? longitude;

  const ResultsScreen({
    super.key,
    required this.medicaments,
    this.latitude,
    this.longitude,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final RechercheService _service = RechercheService();
  late Future<ResultatRecherche> _futur;

  bool get _avecPosition => widget.latitude != null && widget.longitude != null;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<ResultatRecherche> _charger() => _service.rechercher(
    ids: widget.medicaments.map((m) => m.id).toList(),
    latitude: widget.latitude,
    longitude: widget.longitude,
  );

  void _recharger() {
    setState(() {
      _futur = _charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MemaScaffold(
      title: 'Où le trouver',
      subtitle: 'Pharmacies qui ont vos médicaments.',
      child: FutureBuilder<ResultatRecherche>(
        future: _futur,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList(count: 3);
          }
          if (snapshot.hasError) {
            return StateView(
              icon: Icons.cloud_off_rounded,
              danger: true,
              title: 'Résultats indisponibles',
              message: messageErreur(snapshot.error!),
              actionLabel: 'Réessayer',
              onAction: _recharger,
            );
          }

          final pharmacies = snapshot.data!.pharmacies;
          if (pharmacies.isEmpty) {
            return StateView(
              icon: Icons.store_mall_directory_outlined,
              title: 'Aucune pharmacie disponible',
              message: "Aucune pharmacie n'a ces médicaments disponibles en ce moment. "
                  'Réessayez plus tard, ou consultez les pharmacies de garde.',
              actionLabel: 'Actualiser',
              onAction: _recharger,
            );
          }

          final total = widget.medicaments.length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Reveal(index: 0, child: _resume(pharmacies, total)),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  '${pharmacies.length} pharmacie${pharmacies.length > 1 ? 's' : ''}'
                      '${_avecPosition ? ' · de la plus adaptée à la moins adaptée' : ''}',
                  style: AppText.caption,
                ),
              ),
              for (var i = 0; i < pharmacies.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Reveal(
                    index: i + 1,
                    child: _PharmacieCard(
                      trouvee: pharmacies[i],
                      medicaments: widget.medicaments,
                      total: total,
                      meilleur: i == 0 && !pharmacies[i].infoAncienne,
                      depuisLat: widget.latitude,
                      depuisLng: widget.longitude,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _resume(List<PharmacieTrouvee> pharmacies, int total) {
    final complets = pharmacies.where((p) => p.nbDisponibles == total).length;
    final best = pharmacies.first;

    final titre = complets > 0
        ? '$complets pharmacie${complets > 1 ? 's ont' : ' a'} tout'
        : 'Disponibilité partielle';

    return MemaCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : best.nbDisponibles / total,
                    strokeWidth: 7,
                    backgroundColor: AppColors.primaryTint,
                    color: AppColors.primary,
                  ),
                ),
                Text('${best.nbDisponibles}/$total',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: AppText.h2),
                const SizedBox(height: 4),
                Text('Meilleure option : ${best.pharmacie.nom}', style: AppText.body),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _avecPosition
                          ? Icons.my_location_rounded
                          : Icons.location_disabled_rounded,
                      size: 14,
                      color: AppColors.textSoft,
                    ),
                    const SizedBox(width: 5),
                    Text(_avecPosition ? 'Position activée' : 'Position non partagée',
                        style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _lancer(BuildContext context, Future<bool> Function() action, String erreur) async {
  bool ok = false;
  try {
    ok = await action();
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erreur)));
  }
}

class _PharmacieCard extends StatelessWidget {
  final PharmacieTrouvee trouvee;
  final List<Medicament> medicaments;
  final int total;
  final bool meilleur;
  final double? depuisLat;
  final double? depuisLng;

  const _PharmacieCard({
    required this.trouvee,
    required this.medicaments,
    required this.total,
    required this.meilleur,
    this.depuisLat,
    this.depuisLng,
  });

  @override
  Widget build(BuildContext context) {
    final p = trouvee.pharmacie;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: meilleur ? AppColors.accent : AppColors.border,
            width: meilleur ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meilleur)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: AppColors.primaryDark),
                    SizedBox(width: 6),
                    Text('Meilleur choix',
                        style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- En-tête : nom, badges, distance ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.local_pharmacy_rounded,
                            color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nom, style: AppText.title.copyWith(fontSize: 16.5)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (p.agreee)
                                  const StatusChip(
                                    label: 'Agréée',
                                    icon: Icons.verified_rounded,
                                    color: AppColors.primary,
                                    background: AppColors.primaryTint,
                                  ),
                                if (trouvee.deGarde)
                                  const StatusChip(
                                    label: 'De garde',
                                    icon: Icons.nightlight_round,
                                    color: AppColors.primaryDark,
                                    background: AppColors.accentTint,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (trouvee.distanceKm != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatDistance(trouvee.distanceKm!),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.primary)),
                            const Text('à vol d\'oiseau', style: AppText.caption),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // --- Lieu et téléphone ---
                  _LigneInfo(icon: Icons.place_rounded, texte: p.adresse),
                  if (p.telephone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _LigneInfo(icon: Icons.phone_rounded, texte: p.telephone),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: AppColors.border),
                  ),

                  // --- Médicaments ---
                  Text('Disponibilité · ${trouvee.nbDisponibles}/$total',
                      style: AppText.caption.copyWith(
                          fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 10),
                  for (final m in medicaments)
                    _LigneMedicament(medicament: m, ligne: trouvee.ligne(m.id)),

                  // --- Avertissement : informations anciennes ---
                  if (trouvee.infoAncienne) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.update_rounded, size: 19, color: AppColors.accent),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Certaines informations datent de plus de 24 h. '
                                  'Appelez la pharmacie pour confirmer avant de vous déplacer.',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // --- Actions ---
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: MemaButton(
                          label: 'Itinéraire',
                          icon: Icons.directions_rounded,
                          onPressed: () => _lancer(
                            context,
                                () => ouvrirItineraire(p, depuisLat: depuisLat, depuisLng: depuisLng),
                            "Impossible d'ouvrir l'itinéraire.",
                          ),
                        ),
                      ),
                      if (p.telephone.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: MemaButton(
                            label: 'Appeler',
                            icon: Icons.call_rounded,
                            variant: 'outline',
                            onPressed: () => _lancer(
                              context,
                                  () => appeler(p.telephone),
                              "Impossible de lancer l'appel.",
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icon;
  final String texte;
  const _LigneInfo({required this.icon, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texte,
              style: const TextStyle(fontSize: 13.5, color: AppColors.text, height: 1.35)),
        ),
      ],
    );
  }
}

class _LigneMedicament extends StatelessWidget {
  final Medicament medicament;
  final LigneStatut? ligne;
  const _LigneMedicament({required this.medicament, required this.ligne});

  @override
  Widget build(BuildContext context) {
    final statut = ligne?.statut ?? 'NON_REFERENCE';
    final inconnu = statut == 'NON_REFERENCE';
    final dispo = statut == 'DISPONIBLE';
    final surCommande = statut == 'SUR_COMMANDE';
    final ancienne = dispo && (ligne?.aVerifier ?? false);
    final prix = ligne?.prix;
    final date = ligne?.dateMiseAJour;

    final Color couleur = inconnu
        ? AppColors.textSoft
        : (dispo ? AppColors.primary : (surCommande ? AppColors.primaryDark : AppColors.danger));
    final IconData icone = inconnu
        ? Icons.help_outline_rounded
        : (dispo
        ? Icons.check_circle_rounded
        : (surCommande ? Icons.local_shipping_outlined : Icons.cancel_rounded));

    final String droite;
    if (inconnu) {
      droite = 'Non référencé';
    } else if (dispo) {
      droite = prix != null ? formatPrix(prix) : 'Disponible';
    } else if (surCommande) {
      droite = 'Sur commande';
    } else {
      droite = 'Rupture';
    }
    final String? sous = date != null ? 'Mis à jour ${tempsEcoule(date)}' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicament.nom,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sous ?? medicament.dosage, style: AppText.caption),
                if (ancienne)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.accent),
                        SizedBox(width: 4),
                        Text('Information ancienne',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(droite,
              style: TextStyle(
                  color: couleur, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      ),
    );
  }
}
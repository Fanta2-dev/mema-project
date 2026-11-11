import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/periode_garde.dart';
import '../services/garde_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/geo.dart';
import '../utils/lanceurs.dart';
import '../widgets/mema_widgets.dart';

class PharmaciesGardeScreen extends StatefulWidget {
  const PharmaciesGardeScreen({super.key});

  @override
  State<PharmaciesGardeScreen> createState() => _PharmaciesGardeScreenState();
}

class _PharmaciesGardeScreenState extends State<PharmaciesGardeScreen> {
  final GardeService _service = GardeService();
  late Future<List<PeriodeGarde>> _futur;
  Position? _position;
  bool _localisationEnCours = false;

  @override
  void initState() {
    super.initState();
    _futur = _service.listerActives();
  }

  void _recharger() {
    setState(() {
      _futur = _service.listerActives();
    });
  }

  Future<void> _activerPosition() async {
    setState(() => _localisationEnCours = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('La localisation est désactivée sur cet appareil.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission refusée définitivement. Activez-la dans les réglages.');
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
      }
    } finally {
      if (mounted) setState(() => _localisationEnCours = false);
    }
  }

  double _distance(PeriodeGarde p) => distanceKm(
    _position!.latitude,
    _position!.longitude,
    p.pharmacie.latitude,
    p.pharmacie.longitude,
  );

  /// Une seule ligne par pharmacie, triée par distance (si la position est connue) sinon par nom.
  List<PeriodeGarde> _preparer(List<PeriodeGarde> brutes) {
    final parPharmacie = <int, PeriodeGarde>{};
    for (final p in brutes) {
      final actuelle = parPharmacie[p.pharmacie.id];
      if (actuelle == null || p.dateFin.isAfter(actuelle.dateFin)) {
        parPharmacie[p.pharmacie.id] = p;
      }
    }
    final liste = parPharmacie.values.toList();
    if (_position != null) {
      liste.sort((a, b) => _distance(a).compareTo(_distance(b)));
    } else {
      liste.sort((a, b) => a.pharmacie.nom.compareTo(b.pharmacie.nom));
    }
    return liste;
  }

  @override
  Widget build(BuildContext context) {
    return MemaScaffold(
      title: 'Pharmacies de garde',
      subtitle: 'Ouvertes en ce moment (nuit, dimanche, jours fériés).',
      child: FutureBuilder<List<PeriodeGarde>>(
        future: _futur,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList(count: 3);
          }
          if (snapshot.hasError) {
            return StateView(
              icon: Icons.cloud_off_rounded,
              danger: true,
              title: 'Chargement impossible',
              message: messageErreur(snapshot.error!),
              actionLabel: 'Réessayer',
              onAction: _recharger,
            );
          }

          final liste = _preparer(snapshot.data ?? <PeriodeGarde>[]);
          if (liste.isEmpty) {
            return StateView(
              icon: Icons.nightlight_outlined,
              title: 'Aucune garde enregistrée',
              message: "Aucune pharmacie de garde n'est enregistrée pour le moment dans MEMA. "
                  "En cas d'urgence vitale, appelez les secours.",
              actionLabel: 'Actualiser',
              onAction: _recharger,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _recharger();
              try {
                await _futur;
              } catch (_) {
                // l'erreur est affichée par l'écran lui-même
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Appelez avant de vous déplacer pour confirmer que la pharmacie est bien ouverte.',
                          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_position == null)
                  MemaButton(
                    label: 'Voir la plus proche de moi',
                    icon: Icons.my_location_rounded,
                    variant: 'outline',
                    loading: _localisationEnCours,
                    onPressed: _activerPosition,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('Triées de la plus proche à la plus éloignée.',
                        style: AppText.caption),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    '${liste.length} pharmacie${liste.length > 1 ? 's' : ''} de garde',
                    style: AppText.caption,
                  ),
                ),
                for (var i = 0; i < liste.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Reveal(
                      index: i,
                      child: _CarteGarde(
                        periode: liste[i],
                        distance: _position != null ? _distance(liste[i]) : null,
                        depuisLat: _position?.latitude,
                        depuisLng: _position?.longitude,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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

String _jusqua(DateTime fin) {
  String p(int n) => n.toString().padLeft(2, '0');
  final maintenant = DateTime.now();
  final memeJour = fin.year == maintenant.year &&
      fin.month == maintenant.month &&
      fin.day == maintenant.day;
  return "Garde jusqu'à ${p(fin.hour)}h${p(fin.minute)}${memeJour ? '' : ' le ${p(fin.day)}/${p(fin.month)}'}";
}

class _CarteGarde extends StatelessWidget {
  final PeriodeGarde periode;
  final double? distance;
  final double? depuisLat;
  final double? depuisLng;

  const _CarteGarde({
    required this.periode,
    this.distance,
    this.depuisLat,
    this.depuisLng,
  });

  @override
  Widget build(BuildContext context) {
    final p = periode.pharmacie;
    return MemaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.nightlight_round, color: AppColors.accent, size: 26),
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
                        const StatusChip(
                          label: 'De garde',
                          icon: Icons.nightlight_round,
                          color: AppColors.primaryDark,
                          background: AppColors.accentTint,
                        ),
                        if (p.agreee)
                          const StatusChip(
                            label: 'Agréée',
                            icon: Icons.verified_rounded,
                            color: AppColors.primary,
                            background: AppColors.primaryTint,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (distance != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatDistance(distance!),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.primary)),
                    const Text("à vol d'oiseau", style: AppText.caption),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          _Info(icon: Icons.schedule_rounded, texte: _jusqua(periode.dateFin)),
          const SizedBox(height: 6),
          _Info(icon: Icons.place_rounded, texte: p.adresse),
          if (periode.zone.isNotEmpty) ...[
            const SizedBox(height: 6),
            _Info(icon: Icons.map_outlined, texte: 'Zone : ${periode.zone}'),
          ],
          if (p.telephone.isNotEmpty) ...[
            const SizedBox(height: 6),
            _Info(icon: Icons.phone_rounded, texte: p.telephone),
          ],
          const SizedBox(height: 16),
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
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String texte;
  const _Info({required this.icon, required this.texte});

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
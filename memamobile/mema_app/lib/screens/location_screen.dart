import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/mema_widgets.dart';
import 'search_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> with SingleTickerProviderStateMixin {
  bool _chargement = false;
  String? _erreur;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _activerPosition() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final bool serviceActif = await Geolocator.isLocationServiceEnabled();
      if (!serviceActif) {
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

      final Position position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      Navigator.of(context).push(
        memaRoute(SearchScreen(latitude: position.latitude, longitude: position.longitude)),
      );
    } catch (e) {
      setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _continuerSansPosition() {
    Navigator.of(context).push(memaRoute(const SearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return MemaScaffold(
      title: 'Localisation',
      subtitle: "Pour trouver l'officine la plus proche de vous.",
      step: 2,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MemaButton(
            label: _chargement ? 'Recherche en cours...' : 'Activer ma position',
            icon: Icons.my_location_rounded,
            loading: _chargement,
            onPressed: _activerPosition,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _chargement ? null : _continuerSansPosition,
            child: const Text('Continuer sans position',
                style: TextStyle(
                    color: AppColors.textSoft, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        children: [
          Center(child: _radar()),
          const SizedBox(height: 30),
          const Text('Activez votre position',
              textAlign: TextAlign.center, style: AppText.h2),
          const SizedBox(height: 8),
          const Text(
            "MEMA utilise votre position pour indiquer l'officine la plus proche.",
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
          const SizedBox(height: 24),
          const _Avantage(
            icon: Icons.near_me_rounded,
            texte: 'Distance jusqu\'à la pharmacie',
          ),
          const _Avantage(
            icon: Icons.lock_outline_rounded,
            texte: 'Votre position n\'est pas enregistrée',
          ),
          const _Avantage(
            icon: Icons.tune_rounded,
            texte: 'Vous pouvez aussi continuer sans la partager',
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_erreur!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Icône de position entourée d'ondes qui pulsent.
  Widget _radar() {
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final decalage in [0.0, 0.5])
                _onde((_pulse.value + decalage) % 1.0),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.primaryDark, size: 44),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _onde(double t) {
    final taille = 92 + 98 * t;
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withOpacity((1 - t) * 0.5),
          width: 2,
        ),
      ),
    );
  }
}

class _Avantage extends StatelessWidget {
  final IconData icon;
  final String texte;
  const _Avantage({required this.icon, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texte, style: AppText.body)),
        ],
      ),
    );
  }
}
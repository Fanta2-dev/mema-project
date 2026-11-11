import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'admin_widgets.dart';
import 'mema_widgets.dart';

class SaisiePosition extends StatefulWidget {
  final TextEditingController controleur;
  const SaisiePosition({super.key, required this.controleur});

  /// Lit "14.6937, -17.4441" (copié depuis Google Maps) : exactement deux nombres.
  static ({double lat, double lng})? lire(String texte) {
    final nombres = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(texte)
        .map((m) => double.parse(m.group(0)!))
        .toList();
    if (nombres.length != 2) return null;
    return (lat: nombres[0], lng: nombres[1]);
  }

  @override
  State<SaisiePosition> createState() => _SaisiePositionState();
}

class _SaisiePositionState extends State<SaisiePosition> {
  bool _enCours = false;
  String? _erreur;

  Future<void> _utiliserMaPosition() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
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
      widget.controleur.text =
      '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controleur,
          decoration: const InputDecoration(
            hintText: 'Latitude, longitude (ex. 14.6937, -17.4441)',
            prefixIcon: Icon(Icons.my_location_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Dans Google Maps : touchez longuement l'emplacement de la pharmacie, puis copiez "
              'les deux nombres affichés. Ou, si vous êtes devant la pharmacie, utilisez votre position.',
          style: AppText.caption,
        ),
        const SizedBox(height: 10),
        MemaButton(
          label: 'Utiliser ma position actuelle',
          icon: Icons.gps_fixed_rounded,
          variant: 'outline',
          loading: _enCours,
          onPressed: _utiliserMaPosition,
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 10),
          BoiteMessage.erreur(_erreur!),
        ],
      ],
    );
  }
}
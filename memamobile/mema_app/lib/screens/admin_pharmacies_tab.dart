import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pharmacie.dart';
import '../services/admin_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/mema_widgets.dart';
import 'admin_comptes_tab.dart';

class AdminPharmaciesTab extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  const AdminPharmaciesTab({super.key, required this.onSessionExpiree});

  @override
  State<AdminPharmaciesTab> createState() => _AdminPharmaciesTabState();
}

class _AdminPharmaciesTabState extends State<AdminPharmaciesTab> {
  final AdminService _service = AdminService();
  late Future<List<Pharmacie>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<List<Pharmacie>> _charger() =>
      avecSession(_service.pharmacies, widget.onSessionExpiree);

  void _recharger() {
    setState(() {
      _futur = _charger();
    });
  }

  Future<void> _ajouter() async {
    final creee = await ouvrirFeuille<Pharmacie>(
      context,
          (_) => _FeuillePharmacie(onSessionExpiree: widget.onSessionExpiree),
    );
    if (creee == null || !mounted) return;
    _recharger();

    final creerCompte = await confirmer(
      context,
      titre: 'Pharmacie créée',
      message: 'Voulez-vous créer maintenant le compte du pharmacien de « ${creee.nom} » ?',
      action: 'Créer le compte',
    );
    if (!creerCompte || !mounted) return;
    await ouvrirFeuille<bool>(
      context,
          (_) => FeuilleCompte(
        pharmacies: [creee],
        preselection: creee,
        onSessionExpiree: widget.onSessionExpiree,
      ),
    );
  }

  Future<void> _changerAgrement(Pharmacie p, bool valeur) async {
    final ok = await confirmer(
      context,
      titre: valeur ? "Accorder l'agrément ?" : "Retirer l'agrément ?",
      message: valeur
          ? '« ${p.nom} » sera affichée avec le badge « Agréée ».'
          : "« ${p.nom} » ne sera plus affichée avec le badge « Agréée ».",
      action: valeur ? 'Accorder' : 'Retirer',
      danger: !valeur,
    );
    if (!ok || !mounted) return;
    try {
      await avecSession(() => _service.definirAgrement(p, valeur), widget.onSessionExpiree);
      if (mounted) _recharger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Pharmacie>>(
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

        final liste = [...snapshot.data!]..sort((a, b) => a.nom.compareTo(b.nom));
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              MemaButton(
                label: 'Ajouter une pharmacie',
                icon: Icons.add_business_rounded,
                variant: 'accent',
                onPressed: _ajouter,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  '${liste.length} pharmacie${liste.length > 1 ? 's' : ''}',
                  style: AppText.caption,
                ),
              ),
              if (liste.isEmpty)
                const StateView(
                  icon: Icons.local_pharmacy_outlined,
                  title: 'Aucune pharmacie',
                  message: 'Ajoutez la première pharmacie partenaire.',
                )
              else
                for (var i = 0; i < liste.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Reveal(index: i, child: _carte(liste[i])),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _carte(Pharmacie p) {
    return MemaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nom, style: AppText.title),
                    const SizedBox(height: 2),
                    Text(p.adresse, style: AppText.caption),
                    if (p.telephone.isNotEmpty) Text(p.telephone, style: AppText.caption),
                    if (p.numeroAgrement != null && p.numeroAgrement!.isNotEmpty)
                      Text('Agrément : ${p.numeroAgrement}', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: AppColors.border),
          Row(
            children: [
              Icon(
                p.agreee ? Icons.verified_rounded : Icons.remove_moderator_outlined,
                size: 18,
                color: p.agreee ? AppColors.primary : AppColors.textSoft,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.agreee ? 'Pharmacie agréée' : 'Non agréée',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: p.agreee ? AppColors.primary : AppColors.textSoft,
                  ),
                ),
              ),
              Switch(
                value: p.agreee,
                activeColor: AppColors.primary,
                onChanged: (valeur) => _changerAgrement(p, valeur),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formulaire de création d'une pharmacie.
class _FeuillePharmacie extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  const _FeuillePharmacie({required this.onSessionExpiree});

  @override
  State<_FeuillePharmacie> createState() => _FeuillePharmacieState();
}

class _FeuillePharmacieState extends State<_FeuillePharmacie> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _adresse = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _coordonnees = TextEditingController();
  final TextEditingController _agrement = TextEditingController();
  bool _agreee = true;
  bool _enCours = false;
  bool _positionEnCours = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    _adresse.dispose();
    _telephone.dispose();
    _coordonnees.dispose();
    _agrement.dispose();
    super.dispose();
  }

  /// Lit "14.6937, -17.4441" (copié depuis Google Maps) : exactement deux nombres.
  ({double lat, double lng})? _lireCoordonnees(String texte) {
    final nombres = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(texte)
        .map((m) => double.parse(m.group(0)!))
        .toList();
    if (nombres.length != 2) return null;
    return (lat: nombres[0], lng: nombres[1]);
  }

  Future<void> _utiliserMaPosition() async {
    setState(() {
      _positionEnCours = true;
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
      _coordonnees.text =
      '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _positionEnCours = false);
    }
  }

  Future<void> _enregistrer() async {
    final nom = _nom.text.trim();
    final adresse = _adresse.text.trim();
    final telephone = _telephone.text.trim();
    if (nom.isEmpty || adresse.isEmpty || telephone.isEmpty) {
      setState(() => _erreur = "Le nom, l'adresse et le téléphone sont obligatoires.");
      return;
    }
    final coord = _lireCoordonnees(_coordonnees.text);
    if (coord == null) {
      setState(() => _erreur =
      'Écrivez la latitude puis la longitude, séparées par une virgule, avec des points '
          'pour les décimales (ex. 14.6937, -17.4441).');
      return;
    }
    final agrement = _agrement.text.trim();

    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final creee = await AdminService().creerPharmacie(
        nom: nom,
        adresse: adresse,
        telephone: telephone,
        latitude: coord.lat,
        longitude: coord.lng,
        agreee: _agreee,
        numeroAgrement: agrement.isEmpty ? null : agrement,
      );
      if (!mounted) return;
      Navigator.of(context).pop(creee);
    } catch (e) {
      if (!mounted) return;
      if (e is SessionExpireeException) {
        Navigator.of(context).pop();
        widget.onSessionExpiree();
        return;
      }
      setState(() {
        _erreur = messageErreur(e);
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CorpsFeuille(
      children: [
        const Text('Nouvelle pharmacie', style: AppText.h2),
        const SizedBox(height: 18),
        TextField(
          controller: _nom,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nom (ex. Pharmacie Awa Santé)',
            prefixIcon: Icon(Icons.local_pharmacy_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adresse,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Adresse',
            prefixIcon: Icon(Icons.place_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _telephone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Téléphone (ex. 33 825 00 00)',
            prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        const EtiquetteChamp('Position de la pharmacie'),
        TextField(
          controller: _coordonnees,
          decoration: const InputDecoration(
            hintText: 'Latitude, longitude (ex. 14.6937, -17.4441)',
            prefixIcon: Icon(Icons.my_location_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Dans Google Maps : touchez longuement l'emplacement, puis copiez les deux nombres "
              'affichés. Ou, si vous êtes devant la pharmacie, utilisez votre position.',
          style: AppText.caption,
        ),
        const SizedBox(height: 10),
        MemaButton(
          label: 'Utiliser ma position actuelle',
          icon: Icons.gps_fixed_rounded,
          variant: 'outline',
          loading: _positionEnCours,
          onPressed: _utiliserMaPosition,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _agrement,
          decoration: const InputDecoration(
            hintText: "Numéro d'agrément (facultatif)",
            prefixIcon: Icon(Icons.badge_rounded, color: AppColors.primary),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          value: _agreee,
          onChanged: (v) => setState(() => _agreee = v),
          title: const Text('Pharmacie agréée',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 6),
          BoiteMessage.erreur(_erreur!),
        ],
        const SizedBox(height: 18),
        MemaButton(
          label: 'Créer la pharmacie',
          icon: Icons.check_rounded,
          loading: _enCours,
          onPressed: _enregistrer,
        ),
      ],
    );
  }
}
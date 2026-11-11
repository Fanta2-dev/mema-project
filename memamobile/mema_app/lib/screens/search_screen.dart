import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medicament.dart';
import '../services/medicament_service.dart';
import '../services/ordonnance_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/mema_widgets.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;

  const SearchScreen({super.key, this.latitude, this.longitude});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MedicamentService _service = MedicamentService();
  final OrdonnanceService _ordonnance = OrdonnanceService();
  final ImagePicker _picker = ImagePicker();

  late Future<List<Medicament>> _futureMedicaments;
  final Set<int> _selection = {};
  String _recherche = '';

  // Scan d'ordonnance
  bool _scanEnCours = false;
  List<Medicament>? _detectes;
  String? _scanMessage;

  @override
  void initState() {
    super.initState();
    _futureMedicaments = _service.listerTous();
  }

  void _recharger() {
    setState(() {
      _futureMedicaments = _service.listerTous();
    });
  }

  void _basculer(int id) {
    setState(() {
      if (!_selection.remove(id)) _selection.add(id);
    });
  }

  // ---------- Scan de l'ordonnance ----------

  Future<void> _choisirSource(List<Medicament> catalogue) async {
    if (!OrdonnanceService.disponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le scan fonctionne sur téléphone (Android ou iOS), pas dans Chrome.'),
        ),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _scanner(source, catalogue);
  }

  Future<void> _scanner(ImageSource source, List<Medicament> catalogue) async {
    setState(() {
      _scanEnCours = true;
      _scanMessage = null;
      _detectes = null;
    });
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 90, maxWidth: 2200);
      if (photo == null) return;
      final res = await _ordonnance.analyser(photo.path, catalogue);
      if (!mounted) return;
      setState(() {
        _detectes = res.detectes;
        _selection.addAll(res.detectes.map((m) => m.id));
        if (res.detectes.isEmpty) {
          _scanMessage = "Aucun médicament reconnu sur la photo. Essayez avec plus de lumière, "
              "ou choisissez-les dans la liste.";
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _scanMessage = 'Lecture impossible. Réessayez avec une photo plus nette.');
      }
    } finally {
      if (mounted) setState(() => _scanEnCours = false);
    }
  }

  // ---------- Affichage ----------

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medicament>>(
      future: _futureMedicaments,
      builder: (context, snapshot) {
        final tous = snapshot.data ?? <Medicament>[];
        final pret = snapshot.connectionState == ConnectionState.done && !snapshot.hasError;

        return MemaScaffold(
          title: 'Votre ordonnance',
          subtitle: 'Scannez-la en photo ou choisissez vos médicaments.',
          step: 3,
          bottom: pret ? _barreAction(tous) : null,
          child: _contenu(snapshot, tous),
        );
      },
    );
  }

  Widget _contenu(AsyncSnapshot<List<Medicament>> snapshot, List<Medicament> tous) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingList();
    }
    if (snapshot.hasError) {
      return StateView(
        icon: Icons.cloud_off_rounded,
        danger: true,
        title: 'Impossible de joindre le serveur',
        message: '${snapshot.error}'.replaceFirst('Exception: ', ''),
        actionLabel: 'Réessayer',
        onAction: _recharger,
      );
    }

    final affiches = tous
        .where((m) => m.nom.toLowerCase().contains(_recherche.toLowerCase().trim()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _recherche = v),
            decoration: const InputDecoration(
              hintText: 'Nom du médicament (ex. Inexium)',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _carteScan(tous),
              if (_detectes != null && _detectes!.isNotEmpty) _bandeauDetectes(),
              if (_scanMessage != null) _bandeauMessage(_scanMessage!),
              const SizedBox(height: 14),
              if (affiches.isEmpty)
                StateView(
                  icon: Icons.search_off_rounded,
                  title: 'Aucun résultat',
                  message: tous.isEmpty
                      ? "Aucun médicament n'est encore référencé."
                      : 'Aucun médicament ne correspond à « $_recherche ».',
                )
              else
                for (var i = 0; i < affiches.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Reveal(
                      index: i,
                      child: _CarteMedicament(
                        medicament: affiches[i],
                        coche: _selection.contains(affiches[i].id),
                        onTap: () => _basculer(affiches[i].id),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _carteScan(List<Medicament> catalogue) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _scanEnCours ? null : () => _choisirSource(catalogue),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _scanEnCours
                      ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: AppColors.primaryDark),
                  )
                      : const Icon(Icons.document_scanner_rounded,
                      color: AppColors.primaryDark, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scanEnCours ? 'Lecture en cours...' : 'Scanner mon ordonnance',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Une photo suffit : MEMA repère les médicaments.',
                        style: TextStyle(
                            color: AppColors.primaryTint, fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primaryTint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bandeauDetectes() {
    final noms = _detectes!.map((m) => m.nom).join(', ');
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_detectes!.length} médicament${_detectes!.length > 1 ? 's' : ''} reconnu${_detectes!.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(noms, style: AppText.body.copyWith(color: AppColors.text)),
                const SizedBox(height: 6),
                const Text(
                  'Vérifiez la sélection ci-dessous avant de continuer : la lecture '
                      "d'une ordonnance peut contenir des erreurs.",
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bandeauMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.danger, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _barreAction(List<Medicament> tous) {
    final n = _selection.length;
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(n),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$n', style: AppText.h1.copyWith(color: AppColors.primary, fontSize: 26)),
              Text(n > 1 ? 'choisis' : 'choisi', style: AppText.caption),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: MemaButton(
            label: 'Trouver les pharmacies',
            icon: Icons.near_me_rounded,
            variant: 'accent',
            onPressed: n == 0
                ? null
                : () {
              final choisis = tous.where((m) => _selection.contains(m.id)).toList();
              Navigator.of(context).push(
                memaRoute(ResultsScreen(
                  medicaments: choisis,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                )),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CarteMedicament extends StatelessWidget {
  final Medicament medicament;
  final bool coche;
  final VoidCallback onTap;

  const _CarteMedicament({
    required this.medicament,
    required this.coche,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: coche ? [] : AppColors.softShadow,
      ),
      child: Material(
        color: coche ? AppColors.primaryTint : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: coche ? AppColors.primary : AppColors.border,
                width: coche ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: coche ? Colors.white : AppColors.background,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.medication_liquid_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medicament.nom, style: AppText.title),
                      const SizedBox(height: 3),
                      Text(medicament.dosage, style: AppText.caption),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: coche ? Colors.white : AppColors.accentTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          medicament.categorie,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: coche ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: coche ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: coche
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
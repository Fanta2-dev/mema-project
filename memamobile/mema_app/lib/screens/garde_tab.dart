import 'package:flutter/material.dart';
import '../models/periode_garde.dart';
import '../services/garde_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/mema_widgets.dart';

String formatDateHeure(DateTime d) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year} à ${p(d.hour)}h${p(d.minute)}';
}

class GardeTab extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  const GardeTab({super.key, required this.onSessionExpiree});

  @override
  State<GardeTab> createState() => _GardeTabState();
}

class _GardeTabState extends State<GardeTab> {
  final GardeService _service = GardeService();
  late Future<List<PeriodeGarde>> _futur;

  int get _pharmacieId => SessionService.utilisateur?.pharmacieId ?? 0;

  @override
  void initState() {
    super.initState();
    _futur = _service.listerPourPharmacie(_pharmacieId);
  }

  void _recharger() {
    setState(() {
      _futur = _service.listerPourPharmacie(_pharmacieId);
    });
  }

  Future<void> _ouvrirAjout() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FeuilleGarde(
        onSessionExpiree: widget.onSessionExpiree,
        onEnregistrer: (zone, debut, fin, source) => _service.creer(
          pharmacieId: _pharmacieId,
          zone: zone,
          debut: debut,
          fin: fin,
          source: source,
        ),
      ),
    );
    if (ok == true && mounted) {
      _recharger();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Période de garde enregistrée.')),
      );
    }
  }

  Future<void> _supprimer(PeriodeGarde p) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette période ?'),
        content: Text(
            '${p.zone}\nDu ${formatDateHeure(p.dateDebut)}\nau ${formatDateHeure(p.dateFin)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    try {
      await _service.supprimer(p.id);
      if (!mounted) return;
      _recharger();
    } catch (e) {
      if (!mounted) return;
      if (e is SessionExpireeException) {
        widget.onSessionExpiree();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PeriodeGarde>>(
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

        int rang(PeriodeGarde p) => p.enCours ? 0 : (p.terminee ? 2 : 1);
        final periodes = [...snapshot.data!]..sort((a, b) {
          final r = rang(a).compareTo(rang(b));
          if (r != 0) return r;
          return rang(a) == 2
              ? b.dateDebut.compareTo(a.dateDebut)
              : a.dateDebut.compareTo(b.dateDebut);
        });

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
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'Indiquez les périodes où votre pharmacie assure la garde. '
                      'Les patients verront le badge « De garde » pendant ces périodes.',
                  style: AppText.caption,
                ),
              ),
              MemaButton(
                label: 'Ajouter une période de garde',
                icon: Icons.add_rounded,
                variant: 'accent',
                onPressed: _ouvrirAjout,
              ),
              const SizedBox(height: 16),
              if (periodes.isEmpty)
                const StateView(
                  icon: Icons.nightlight_outlined,
                  title: 'Aucune période de garde',
                  message: "Vous n'avez pas encore enregistré de garde.",
                )
              else
                for (var i = 0; i < periodes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Reveal(index: i, child: _carte(periodes[i])),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _carte(PeriodeGarde p) {
    final String etat = p.enCours ? 'En cours' : (p.terminee ? 'Terminée' : 'À venir');
    final Color couleur = p.enCours
        ? AppColors.primary
        : (p.terminee ? AppColors.textSoft : AppColors.primaryDark);
    final Color fond = p.enCours
        ? AppColors.primaryTint
        : (p.terminee ? AppColors.border : AppColors.accentTint);
    final IconData icone = p.enCours
        ? Icons.nightlight_round
        : (p.terminee ? Icons.history_rounded : Icons.event_rounded);

    return Opacity(
      opacity: p.terminee ? 0.65 : 1,
      child: MemaCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentTint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.nightlight_round, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.zone, style: AppText.title),
                  const SizedBox(height: 6),
                  StatusChip(label: etat, icon: icone, color: couleur, background: fond),
                  const SizedBox(height: 8),
                  Text('Du ${formatDateHeure(p.dateDebut)}', style: AppText.caption),
                  Text('au ${formatDateHeure(p.dateFin)}', style: AppText.caption),
                  if (p.source != null && p.source!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Source : ${p.source}', style: AppText.caption),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _supprimer(p),
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeuilleGarde extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  final Future<void> Function(String zone, DateTime debut, DateTime fin, String? source)
  onEnregistrer;

  const _FeuilleGarde({required this.onSessionExpiree, required this.onEnregistrer});

  @override
  State<_FeuilleGarde> createState() => _FeuilleGardeState();
}

class _FeuilleGardeState extends State<_FeuilleGarde> {
  final TextEditingController _zone = TextEditingController();
  final TextEditingController _source = TextEditingController();
  late DateTime _debut;
  late DateTime _fin;
  bool _enCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final maintenant = DateTime.now();
    _debut = DateTime(maintenant.year, maintenant.month, maintenant.day, 20, 0);
    _fin = _debut.add(const Duration(hours: 12));
  }

  @override
  void dispose() {
    _zone.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<DateTime?> _choisir(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (heure == null) return null;
    return DateTime(date.year, date.month, date.day, heure.hour, heure.minute);
  }

  Future<void> _enregistrer() async {
    final zone = _zone.text.trim();
    if (zone.isEmpty) {
      setState(() => _erreur = 'Indiquez la zone (ex. Yeumbeul).');
      return;
    }
    if (!_fin.isAfter(_debut)) {
      setState(() => _erreur = 'La fin doit être après le début.');
      return;
    }
    final source = _source.text.trim();

    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await widget.onEnregistrer(zone, _debut, _fin, source.isEmpty ? null : source);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (e is SessionExpireeException) {
        Navigator.of(context).pop(false);
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nouvelle période de garde', style: AppText.h2),
            const SizedBox(height: 18),
            TextField(
              controller: _zone,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Zone (ex. Yeumbeul)',
                prefixIcon: Icon(Icons.place_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            _ChampDate(
              label: 'Début de la garde',
              valeur: formatDateHeure(_debut),
              onTap: () async {
                final choix = await _choisir(_debut);
                if (choix != null) setState(() => _debut = choix);
              },
            ),
            const SizedBox(height: 12),
            _ChampDate(
              label: 'Fin de la garde',
              valeur: formatDateHeure(_fin),
              onTap: () async {
                final choix = await _choisir(_fin);
                if (choix != null) setState(() => _fin = choix);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _source,
              decoration: const InputDecoration(
                hintText: 'Source (facultatif, ex. Ordre des Pharmaciens)',
                prefixIcon: Icon(Icons.fact_check_rounded, color: AppColors.primary),
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_erreur!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            MemaButton(
              label: 'Enregistrer',
              icon: Icons.check_rounded,
              loading: _enCours,
              onPressed: _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampDate extends StatelessWidget {
  final String label;
  final String valeur;
  final VoidCallback onTap;

  const _ChampDate({required this.label, required this.valeur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(valeur,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, color: AppColors.textSoft, size: 20),
          ],
        ),
      ),
    );
  }
}
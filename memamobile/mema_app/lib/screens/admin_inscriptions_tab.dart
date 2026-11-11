import 'package:flutter/material.dart';
import '../models/inscription.dart';
import '../services/admin_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/lanceurs.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/mema_widgets.dart';

class AdminInscriptionsTab extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  const AdminInscriptionsTab({super.key, required this.onSessionExpiree});

  @override
  State<AdminInscriptionsTab> createState() => _AdminInscriptionsTabState();
}

class _AdminInscriptionsTabState extends State<AdminInscriptionsTab> {
  final AdminService _service = AdminService();
  late Future<List<Inscription>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<List<Inscription>> _charger() =>
      avecSession(_service.inscriptions, widget.onSessionExpiree);

  void _recharger() {
    setState(() {
      _futur = _charger();
    });
  }

  Future<void> _lancer(Future<bool> Function() action, String erreur) async {
    bool ok = false;
    try {
      ok = await action();
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erreur)));
    }
  }

  Future<void> _valider(Inscription i) async {
    final ok = await confirmer(
      context,
      titre: 'Valider cette inscription ?',
      message: 'La pharmacie « ${i.pharmacieNom} » sera créée avec le badge « Agréée », '
          'et le compte de ${i.responsableNom} sera activé immédiatement.',
      action: 'Valider',
    );
    if (!ok || !mounted) return;
    try {
      await avecSession(() => _service.validerInscription(i.id), widget.onSessionExpiree);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Inscription validée. ${i.responsableNom} peut se connecter '
                'avec le numéro ${i.responsableTelephone}.')),
      );
      _recharger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  Future<void> _refuser(Inscription i) async {
    final motif = await ouvrirFeuille<String>(context, (_) => _FeuilleRefus(inscription: i));
    if (motif == null || !mounted) return;
    try {
      await avecSession(() => _service.refuserInscription(i.id, motif), widget.onSessionExpiree);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription refusée. Le motif sera affiché au demandeur.')),
      );
      _recharger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Inscription>>(
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

        final liste = snapshot.data!;
        if (liste.isEmpty) {
          return StateView(
            icon: Icons.how_to_reg_outlined,
            title: 'Aucune inscription en attente',
            message: "Les pharmacies qui s'inscrivent depuis l'écran de connexion apparaîtront ici.",
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const BoiteMessage.info(
                "Avant de valider : appelez la pharmacie, vérifiez le numéro d'agrément "
                    "auprès de l'Ordre des Pharmaciens, et contrôlez l'emplacement sur la carte.",
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  '${liste.length} inscription${liste.length > 1 ? 's' : ''} en attente',
                  style: AppText.caption,
                ),
              ),
              for (var k = 0; k < liste.length; k++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Reveal(index: k, child: _carte(liste[k])),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _carte(Inscription i) {
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
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.how_to_reg_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.pharmacieNom, style: AppText.title),
                    const SizedBox(height: 2),
                    Text('Demandé ${tempsEcoule(i.dateDemande)}', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Ligne(icon: Icons.place_rounded, texte: i.pharmacieAdresse),
          const SizedBox(height: 6),
          _Ligne(icon: Icons.phone_rounded, texte: 'Pharmacie : ${i.pharmacieTelephone}'),
          const SizedBox(height: 6),
          _Ligne(icon: Icons.badge_rounded, texte: "Agrément : ${i.numeroAgrement}"),
          const SizedBox(height: 6),
          _Ligne(
              icon: Icons.person_rounded,
              texte: 'Responsable : ${i.responsableNom} (${i.responsableTelephone})'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MemaButton(
                  label: 'Emplacement',
                  icon: Icons.map_rounded,
                  variant: 'outline',
                  onPressed: () => _lancer(
                        () => ouvrirCarte(i.latitude, i.longitude),
                    "Impossible d'ouvrir la carte.",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MemaButton(
                  label: 'Appeler',
                  icon: Icons.call_rounded,
                  variant: 'outline',
                  onPressed: () => _lancer(
                        () => appeler(i.pharmacieTelephone),
                    "Impossible de lancer l'appel.",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MemaButton(
                  label: 'Refuser',
                  icon: Icons.close_rounded,
                  variant: 'outline',
                  onPressed: () => _refuser(i),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MemaButton(
                  label: 'Valider',
                  icon: Icons.check_rounded,
                  onPressed: () => _valider(i),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final IconData icon;
  final String texte;
  const _Ligne({required this.icon, required this.texte});

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

/// Saisie du motif de refus (affiché ensuite au demandeur).
class _FeuilleRefus extends StatefulWidget {
  final Inscription inscription;
  const _FeuilleRefus({required this.inscription});

  @override
  State<_FeuilleRefus> createState() => _FeuilleRefusState();
}

class _FeuilleRefusState extends State<_FeuilleRefus> {
  final TextEditingController _motif = TextEditingController();
  String? _erreur;

  static const List<String> _modeles = [
    "Numéro d'agrément introuvable",
    'Pharmacie injoignable par téléphone',
    'Informations incomplètes ou incorrectes',
  ];

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _envoyer() {
    final motif = _motif.text.trim();
    if (motif.length < 3) {
      setState(() => _erreur = 'Indiquez un motif (au moins 3 caractères).');
      return;
    }
    Navigator.of(context).pop(motif);
  }

  @override
  Widget build(BuildContext context) {
    return CorpsFeuille(
      children: [
        const Text('Refuser cette inscription', style: AppText.h2),
        const SizedBox(height: 4),
        Text(widget.inscription.pharmacieNom, style: AppText.body),
        const SizedBox(height: 16),
        const EtiquetteChamp('Motif (affiché au demandeur)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in _modeles)
              ActionChip(
                label: Text(m, style: const TextStyle(fontSize: 12)),
                onPressed: () => setState(() => _motif.text = m),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _motif,
          maxLines: 2,
          maxLength: 200,
          decoration: const InputDecoration(hintText: 'Expliquez brièvement la raison'),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 8),
          BoiteMessage.erreur(_erreur!),
        ],
        const SizedBox(height: 14),
        MemaButton(
          label: 'Confirmer le refus',
          icon: Icons.close_rounded,
          onPressed: _envoyer,
        ),
      ],
    );
  }
}
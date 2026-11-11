import 'package:flutter/material.dart';
import '../models/demande_medicament.dart';
import '../services/admin_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/mema_widgets.dart';

class AdminDemandesTab extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  final VoidCallback onAllerCatalogue;

  const AdminDemandesTab({
    super.key,
    required this.onSessionExpiree,
    required this.onAllerCatalogue,
  });

  @override
  State<AdminDemandesTab> createState() => _AdminDemandesTabState();
}

class _AdminDemandesTabState extends State<AdminDemandesTab> {
  final AdminService _service = AdminService();
  late Future<List<DemandeMedicament>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<List<DemandeMedicament>> _charger() =>
      avecSession(_service.demandes, widget.onSessionExpiree);

  void _recharger() {
    setState(() {
      _futur = _charger();
    });
  }

  Future<void> _ecarter(DemandeMedicament d) async {
    final ok = await confirmer(
      context,
      titre: 'Écarter cette demande ?',
      message: "« ${d.nom} » ne sera pas ajouté au catalogue et disparaîtra de cette liste.",
      action: 'Écarter',
    );
    if (!ok || !mounted) return;
    try {
      await avecSession(() => _service.traiterDemande(d.id), widget.onSessionExpiree);
      if (mounted) _recharger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DemandeMedicament>>(
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
            icon: Icons.inbox_outlined,
            title: 'Aucune demande en attente',
            message:
            "Quand une pharmacie importe un médicament absent du catalogue, il apparaît ici.",
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
                "Ajoutez ces médicaments dans l'onglet Catalogue : les demandes se ferment "
                    "toutes seules à l'import. « Écarter » sert à retirer une demande sans "
                    "ajouter le médicament.",
              ),
              const SizedBox(height: 12),
              MemaButton(
                label: 'Importer le catalogue',
                icon: Icons.upload_file_rounded,
                variant: 'outline',
                onPressed: widget.onAllerCatalogue,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  '${liste.length} demande${liste.length > 1 ? 's' : ''} en attente',
                  style: AppText.caption,
                ),
              ),
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

  Widget _carte(DemandeMedicament d) {
    return MemaCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.nom, style: AppText.title),
                const SizedBox(height: 3),
                Text('Demandé par ${d.pharmacieNom}', style: AppText.caption),
                Text(tempsEcoule(d.dateDemande), style: AppText.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _ecarter(d),
            tooltip: 'Écarter',
            icon: const Icon(Icons.close_rounded, color: AppColors.textSoft),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/mema_widgets.dart';

class AdminCatalogueTab extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  const AdminCatalogueTab({super.key, required this.onSessionExpiree});

  @override
  State<AdminCatalogueTab> createState() => _AdminCatalogueTabState();
}

class _AdminCatalogueTabState extends State<AdminCatalogueTab> {
  final AdminService _service = AdminService();
  bool _enCours = false;
  String? _erreur;
  ResultatCatalogue? _resultat;

  Future<void> _importer() async {
    setState(() => _erreur = null);

    FichierCsv? choisi;
    try {
      choisi = await choisirFichierCsv();
    } catch (e) {
      setState(() => _erreur = messageErreur(e));
      return;
    }
    if (choisi == null) return;
    final fichier = choisi;

    setState(() {
      _enCours = true;
      _resultat = null;
    });
    try {
      final resultat = await avecSession(
            () => _service.importerCatalogue(fichier.octets, fichier.nom),
        widget.onSessionExpiree,
      );
      if (!mounted) return;
      setState(() {
        _resultat = resultat;
        _enCours = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e is SessionExpireeException ? null : messageErreur(e);
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultat;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text('Importer des médicaments', style: AppText.h2),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comment préparer le fichier',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              SizedBox(height: 6),
              Text(
                '• Un fichier CSV avec, en première ligne, les colonnes : nom (obligatoire), '
                    'dci, dosage, categorie.\n'
                    '• Un même nom en plusieurs dosages : une ligne par dosage.\n'
                    '• Les doublons (même nom et même dosage) sont ignorés.\n'
                    '• Depuis Excel : Fichier > Enregistrer sous > « CSV UTF-8 (délimité par des '
                    'points-virgules) ».',
                style: AppText.caption,
              ),
              SizedBox(height: 8),
              Text('Exemple :', style: AppText.caption),
              Text(
                'nom;dci;dosage;categorie\n'
                    'Doliprane;Paracétamol;500 mg, comprimé;Antalgique\n'
                    'Doliprane;Paracétamol;1000 mg, comprimé;Antalgique',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_erreur != null) ...[
          BoiteMessage.erreur(_erreur!),
          const SizedBox(height: 12),
        ],
        MemaButton(
          label: _enCours ? 'Import en cours...' : 'Choisir un fichier CSV',
          icon: Icons.upload_file_rounded,
          variant: 'accent',
          loading: _enCours,
          onPressed: _importer,
        ),
        if (r != null) ..._vueResultat(r),
      ],
    );
  }

  List<Widget> _vueResultat(ResultatCatalogue r) {
    final affichees = r.erreurs.take(30).toList();
    return [
      const SizedBox(height: 20),
      Row(
        children: [
          Icon(
            r.erreurs.isEmpty ? Icons.check_circle_rounded : Icons.info_rounded,
            color: r.erreurs.isEmpty ? AppColors.primary : AppColors.accent,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              r.erreurs.isEmpty ? 'Import terminé' : 'Import terminé avec des erreurs',
              style: AppText.h2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Compteur(valeur: '${r.lignesLues}', label: 'lignes lues', couleur: AppColors.text),
          _Compteur(
              valeur: '${r.medicamentsCrees}', label: 'ajoutés', couleur: AppColors.primary),
          _Compteur(
              valeur: '${r.doublonsIgnores}', label: 'déjà connus', couleur: AppColors.textSoft),
          _Compteur(
              valeur: '${r.demandesFermees}',
              label: 'demandes fermées',
              couleur: AppColors.primary),
        ],
      ),
      if (r.erreurs.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          '${r.erreurs.length} ligne${r.erreurs.length > 1 ? 's' : ''} non importée${r.erreurs.length > 1 ? 's' : ''} :',
          style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.dangerTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in affichees)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(e,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12.5, height: 1.35)),
                ),
              if (r.erreurs.length > affichees.length)
                Text('... et ${r.erreurs.length - affichees.length} autres',
                    style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ];
  }
}

class _Compteur extends StatelessWidget {
  final String valeur;
  final String label;
  final Color couleur;

  const _Compteur({required this.valeur, required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(valeur,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: couleur)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/import_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/mema_widgets.dart';

/// Fenêtre du bas : choix du fichier, envoi, puis compte rendu.
class FeuilleImport extends StatefulWidget {
  final int pharmacieId;
  final VoidCallback onSessionExpiree;

  const FeuilleImport({
    super.key,
    required this.pharmacieId,
    required this.onSessionExpiree,
  });

  @override
  State<FeuilleImport> createState() => _FeuilleImportState();
}

class _FeuilleImportState extends State<FeuilleImport> {
  bool _remplacer = false;
  bool _remplacementDemande = false;
  bool _enCours = false;
  String? _erreur;
  ResultatImport? _resultat;

  Future<void> _choisirEtImporter() async {
    setState(() => _erreur = null);

    FilePickerResult? choix;
    try {
      choix = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    } catch (_) {
      setState(() => _erreur = "Impossible d'ouvrir le sélecteur de fichiers.");
      return;
    }
    if (choix == null || choix.files.isEmpty) return;

    final fichier = choix.files.single;
    final nom = fichier.name.toLowerCase();
    if (nom.endsWith('.xlsx') || nom.endsWith('.xls')) {
      setState(() => _erreur =
      'Les fichiers Excel (.xlsx) ne sont pas encore pris en charge. Dans Excel : '
          'Fichier > Enregistrer sous > « CSV UTF-8 (délimité par des points-virgules) », '
          'puis choisissez ce nouveau fichier.');
      return;
    }
    if (!nom.endsWith('.csv') && !nom.endsWith('.txt')) {
      setState(() => _erreur = 'Choisissez un fichier au format .csv.');
      return;
    }
    final octets = fichier.bytes;
    if (octets == null) {
      setState(() => _erreur = 'Impossible de lire ce fichier.');
      return;
    }

    setState(() => _enCours = true);
    try {
      final resultat = await ImportService().importer(
        pharmacieId: widget.pharmacieId,
        octets: octets,
        nomFichier: fichier.name,
        remplacer: _remplacer,
      );
      if (!mounted) return;
      setState(() {
        _resultat = resultat;
        _remplacementDemande = _remplacer;
        _enCours = false;
      });
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
            if (_resultat == null) ..._vueChoix() else ..._vueResultat(_resultat!),
          ],
        ),
      ),
    );
  }

  List<Widget> _vueChoix() {
    return [
      const Text('Importer un fichier de stock', style: AppText.h2),
      const SizedBox(height: 10),
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
              '• Un fichier CSV, avec une première ligne contenant les colonnes : '
                  'nom, quantité, prix.\n'
                  '• Si un médicament existe en plusieurs dosages, ajoutez une colonne « dosage ».\n'
                  '• Depuis Excel : Fichier > Enregistrer sous > « CSV UTF-8 (délimité par des '
                  'points-virgules) ».\n'
                  '• Les médicaments absents du catalogue MEMA sont signalés à l\'administrateur '
                  'automatiquement.',
              style: AppText.caption,
            ),
            SizedBox(height: 8),
            Text('Exemple :', style: AppText.caption),
            Text('nom;quantite;prix\nPeptex;12;1800\nInexium;0;4500',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12.5)),
          ],
        ),
      ),
      const SizedBox(height: 14),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primary,
        value: _remplacer,
        onChanged: _enCours ? null : (v) => setState(() => _remplacer = v),
        title: const Text('Les médicaments absents du fichier passent en rupture',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: const Text(
          "À activer seulement si votre fichier contient TOUT votre stock.",
          style: AppText.caption,
        ),
      ),
      if (_erreur != null) ...[
        const SizedBox(height: 10),
        _boite(_erreur!, AppColors.dangerTint, AppColors.danger, Icons.error_outline_rounded),
      ],
      const SizedBox(height: 18),
      MemaButton(
        label: _enCours ? 'Import en cours...' : 'Choisir un fichier',
        icon: Icons.upload_file_rounded,
        loading: _enCours,
        onPressed: _choisirEtImporter,
      ),
    ];
  }

  List<Widget> _vueResultat(ResultatImport r) {
    final importees = r.stocksMisAJour + r.stocksCrees;
    final erreurs = r.erreurs;
    final affichees = erreurs.take(30).toList();
    final nbInconnus = r.medicamentsInconnus.length;

    return [
      Row(
        children: [
          Icon(
            erreurs.isEmpty ? Icons.check_circle_rounded : Icons.info_rounded,
            color: erreurs.isEmpty ? AppColors.primary : AppColors.accent,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              erreurs.isEmpty ? 'Import terminé' : 'Import terminé avec des erreurs',
              style: AppText.h2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Compteur(valeur: '${r.lignesLues}', label: 'lignes lues', couleur: AppColors.text),
          _Compteur(
              valeur: '${r.stocksMisAJour}', label: 'mis à jour', couleur: AppColors.primary),
          _Compteur(valeur: '${r.stocksCrees}', label: 'ajoutés', couleur: AppColors.primary),
          if (r.remplacementApplique)
            _Compteur(
                valeur: '${r.stocksMisEnRupture}',
                label: 'mis en rupture',
                couleur: AppColors.danger),
        ],
      ),
      if (_remplacementDemande && !r.remplacementApplique) ...[
        const SizedBox(height: 14),
        _boite(
          "Le passage en rupture des médicaments absents n'a PAS été appliqué, car le fichier "
              'contient des erreurs. Corrigez-les puis réimportez.',
          AppColors.accentTint,
          AppColors.primaryDark,
          Icons.warning_amber_rounded,
        ),
      ],
      if (nbInconnus > 0) ...[
        const SizedBox(height: 14),
        _boite(
          '$nbInconnus médicament${nbInconnus > 1 ? 's' : ''} absent${nbInconnus > 1 ? 's' : ''} '
              'du catalogue MEMA : ${r.medicamentsInconnus.take(10).join(', ')}'
              '${nbInconnus > 10 ? '...' : ''}.\n'
              "${r.demandesEnregistrees > 0 ? "Ces noms ont été signalés à l'administrateur." : "Ces noms avaient déjà été signalés à l'administrateur."} "
              'Une fois ajoutés au catalogue, réimportez votre fichier.',
          AppColors.accentTint,
          AppColors.primaryDark,
          Icons.mark_email_read_rounded,
        ),
      ],
      if (erreurs.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          '${erreurs.length} ligne${erreurs.length > 1 ? 's' : ''} non importée${erreurs.length > 1 ? 's' : ''}'
              '${importees > 0 ? " (les autres ont bien été importées)" : ""} :',
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
              if (erreurs.length > affichees.length)
                Text('... et ${erreurs.length - affichees.length} autres',
                    style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      MemaButton(
        label: 'Terminer',
        icon: Icons.check_rounded,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ];
  }

  Widget _boite(String texte, Color fond, Color couleur, IconData icone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texte, style: TextStyle(color: couleur, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
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
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
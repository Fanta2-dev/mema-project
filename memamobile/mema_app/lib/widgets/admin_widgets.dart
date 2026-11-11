import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Ouvre une fenêtre du bas arrondie. Renvoie ce que la fenêtre passe à Navigator.pop.
Future<T?> ouvrirFeuille<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}

/// Contenu standard d'une fenêtre du bas : poignée, défilement, adaptation au clavier.
class CorpsFeuille extends StatelessWidget {
  final List<Widget> children;
  const CorpsFeuille({super.key, required this.children});

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
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Encadré coloré : erreur, information ou succès.
class BoiteMessage extends StatelessWidget {
  final String texte;
  final Color fond;
  final Color couleur;
  final IconData icone;

  const BoiteMessage.erreur(this.texte, {super.key})
      : fond = AppColors.dangerTint,
        couleur = AppColors.danger,
        icone = Icons.error_outline_rounded;

  const BoiteMessage.info(this.texte, {super.key})
      : fond = AppColors.accentTint,
        couleur = AppColors.primaryDark,
        icone = Icons.info_outline_rounded;

  const BoiteMessage.succes(this.texte, {super.key})
      : fond = AppColors.primaryTint,
        couleur = AppColors.primary,
        icone = Icons.check_circle_outline_rounded;

  @override
  Widget build(BuildContext context) {
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

/// Exécute une action ; si la session a expiré, prévient l'écran pour qu'il renvoie vers la connexion.
Future<T> avecSession<T>(Future<T> Function() action, VoidCallback onExpiree) async {
  try {
    return await action();
  } on SessionExpireeException {
    WidgetsBinding.instance.addPostFrameCallback((_) => onExpiree());
    rethrow;
  }
}

/// Affiche une erreur dans une bulle (sauf expiration de session, déjà gérée).
void afficherErreur(BuildContext context, Object e) {
  if (e is SessionExpireeException || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
}

/// Demande une confirmation. Renvoie vrai si la personne confirme.
Future<bool> confirmer(
    BuildContext context, {
      required String titre,
      required String message,
      String action = 'Confirmer',
      bool danger = false,
    }) async {
  final reponse = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action,
              style: TextStyle(color: danger ? AppColors.danger : AppColors.primary)),
        ),
      ],
    ),
  );
  return reponse == true;
}

class FichierCsv {
  final String nom;
  final List<int> octets;
  FichierCsv(this.nom, this.octets);
}

/// Fait choisir un fichier CSV. Renvoie null si la personne annule, ou lève une erreur lisible.
Future<FichierCsv?> choisirFichierCsv() async {
  FilePickerResult? choix;
  try {
    choix = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
  } catch (_) {
    throw Exception("Impossible d'ouvrir le sélecteur de fichiers.");
  }
  if (choix == null || choix.files.isEmpty) return null;

  final fichier = choix.files.single;
  final nom = fichier.name.toLowerCase();
  if (nom.endsWith('.xlsx') || nom.endsWith('.xls')) {
    throw Exception(
        'Les fichiers Excel (.xlsx) ne sont pas encore pris en charge. Dans Excel : '
            'Fichier > Enregistrer sous > « CSV UTF-8 (délimité par des points-virgules) », '
            'puis choisissez ce nouveau fichier.');
  }
  if (!nom.endsWith('.csv') && !nom.endsWith('.txt')) {
    throw Exception('Choisissez un fichier au format .csv.');
  }
  final octets = fichier.bytes;
  if (octets == null) {
    throw Exception('Impossible de lire ce fichier.');
  }
  return FichierCsv(fichier.name, octets);
}

/// Étiquette de champ au-dessus d'une zone de saisie.
class EtiquetteChamp extends StatelessWidget {
  final String texte;
  const EtiquetteChamp(this.texte, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texte,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
    );
  }
}
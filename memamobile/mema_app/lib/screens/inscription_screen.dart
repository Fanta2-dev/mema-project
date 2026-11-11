import 'package:flutter/material.dart';
import '../services/inscription_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/mema_widgets.dart';
import '../widgets/saisie_position.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final TextEditingController _pharmacieNom = TextEditingController();
  final TextEditingController _adresse = TextEditingController();
  final TextEditingController _pharmacieTel = TextEditingController();
  final TextEditingController _position = TextEditingController();
  final TextEditingController _agrement = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();

  bool _cacher = true;
  bool _enCours = false;
  bool _envoyee = false;
  String? _erreur;
  String _telephoneEnvoye = '';

  @override
  void dispose() {
    for (final c in [
      _pharmacieNom,
      _adresse,
      _pharmacieTel,
      _position,
      _agrement,
      _nom,
      _telephone,
      _motDePasse,
      _confirmation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_pharmacieNom.text.trim().isEmpty ||
        _adresse.text.trim().isEmpty ||
        _pharmacieTel.text.trim().isEmpty ||
        _agrement.text.trim().isEmpty ||
        _nom.text.trim().isEmpty ||
        _telephone.text.trim().isEmpty) {
      setState(() => _erreur = 'Tous les champs sont obligatoires.');
      return;
    }
    final coord = SaisiePosition.lire(_position.text);
    if (coord == null) {
      setState(() => _erreur =
      'Écrivez la latitude puis la longitude, séparées par une virgule, avec des points '
          'pour les décimales (ex. 14.6937, -17.4441).');
      return;
    }
    if (_motDePasse.text.length < 8) {
      setState(() => _erreur = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (_motDePasse.text != _confirmation.text) {
      setState(() => _erreur = 'Les deux mots de passe ne sont pas identiques.');
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await InscriptionService().envoyer(
        pharmacieNom: _pharmacieNom.text.trim(),
        pharmacieAdresse: _adresse.text.trim(),
        latitude: coord.lat,
        longitude: coord.lng,
        pharmacieTelephone: _pharmacieTel.text.trim(),
        numeroAgrement: _agrement.text.trim(),
        responsableNom: _nom.text.trim(),
        responsableTelephone: _telephone.text.trim(),
        motDePasse: _motDePasse.text,
      );
      if (!mounted) return;
      setState(() {
        _envoyee = true;
        _telephoneEnvoye = _telephone.text.trim();
        _enCours = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreur(e);
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemaScaffold(
      title: 'Inscrire ma pharmacie',
      subtitle: 'Votre demande sera vérifiée avant activation.',
      bottom: _envoyee
          ? MemaButton(
        label: 'Retour à la connexion',
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.of(context).pop(),
      )
          : MemaButton(
        label: 'Envoyer ma demande',
        icon: Icons.send_rounded,
        loading: _enCours,
        onPressed: _envoyer,
      ),
      child: _envoyee ? _vueConfirmation() : _vueFormulaire(),
    );
  }

  Widget _titre(String texte) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 12),
    child: Text(texte, style: AppText.h2),
  );

  Widget _vueFormulaire() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        const BoiteMessage.info(
          "Pour protéger les patients, seules les pharmacies agréées peuvent gérer leur stock. "
              "Nous vérifions votre numéro d'agrément et pouvons appeler la pharmacie.",
        ),
        const SizedBox(height: 16),
        _titre('Votre pharmacie'),
        TextField(
          controller: _pharmacieNom,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nom de la pharmacie',
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
          controller: _pharmacieTel,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Téléphone de la pharmacie',
            prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _agrement,
          decoration: const InputDecoration(
            hintText: "Numéro d'agrément",
            prefixIcon: Icon(Icons.badge_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        const EtiquetteChamp('Position de la pharmacie'),
        SaisiePosition(controleur: _position),
        const SizedBox(height: 22),
        _titre('Votre compte'),
        TextField(
          controller: _nom,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Votre nom complet',
            prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _telephone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Votre téléphone (sert d\'identifiant)',
            prefixIcon: Icon(Icons.smartphone_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _motDePasse,
          obscureText: _cacher,
          decoration: InputDecoration(
            hintText: 'Mot de passe (8 caractères minimum)',
            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _cacher ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: AppColors.textSoft,
              ),
              onPressed: () => setState(() => _cacher = !_cacher),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmation,
          obscureText: _cacher,
          decoration: const InputDecoration(
            hintText: 'Confirmez le mot de passe',
            prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 16),
          BoiteMessage.erreur(_erreur!),
        ],
      ],
    );
  }

  Widget _vueConfirmation() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 40, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Demande envoyée',
            textAlign: TextAlign.center, style: AppText.h2),
        const SizedBox(height: 8),
        const Text(
          'Merci. Votre demande va être vérifiée par notre équipe.',
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
        const SizedBox(height: 22),
        _etape('1', "Nous vérifions votre numéro d'agrément, et nous pouvons appeler la pharmacie."),
        _etape('2',
            'Dès que votre demande est validée, connectez-vous avec le numéro $_telephoneEnvoye '
                'et le mot de passe que vous avez choisi.'),
        _etape('3',
            "Si la demande est refusée, le motif s'affichera quand vous essaierez de vous connecter."),
      ],
    );
  }

  Widget _etape(String numero, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.accentTint, shape: BoxShape.circle),
            child: Text(numero,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.primaryDark, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texte, style: AppText.body.copyWith(color: AppColors.text))),
        ],
      ),
    );
  }
}
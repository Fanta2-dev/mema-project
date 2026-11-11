import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/mema_widgets.dart';
import 'admin_screen.dart';
import 'inscription_screen.dart';
import 'pharmacien_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  bool _cacher = true;
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _telephone.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (_telephone.text.trim().isEmpty || _motDePasse.text.isEmpty) {
      setState(() => _erreur = 'Entrez votre numéro et votre mot de passe.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await AuthService().connecter(_telephone.text.trim(), _motDePasse.text);
      if (!mounted) return;
      final admin = SessionService.utilisateur?.estAdmin == true;
      Navigator.of(context).pushReplacement(
        memaRoute(admin ? const AdminScreen() : const PharmacienScreen()),
      );
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enAttente = _erreur != null && _erreur!.contains('en cours de vérification');
    return MemaScaffold(
      title: 'Espace professionnel',
      subtitle: 'Connectez-vous pour gérer votre stock.',
      bottom: MemaButton(
        label: 'Se connecter',
        icon: Icons.login_rounded,
        loading: _chargement,
        onPressed: _connecter,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_pharmacy_rounded,
                  size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Bienvenue',
              textAlign: TextAlign.center, style: AppText.h2),
          const SizedBox(height: 6),
          const Text(
            'Réservé au personnel des pharmacies partenaires et aux administrateurs.',
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _telephone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Numéro de téléphone (ex. 77 000 00 02)',
              prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _motDePasse,
            obscureText: _cacher,
            onSubmitted: (_) => _connecter(),
            decoration: InputDecoration(
              hintText: 'Mot de passe',
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
          if (_erreur != null) ...[
            const SizedBox(height: 16),
            enAttente ? BoiteMessage.info(_erreur!) : BoiteMessage.erreur(_erreur!),
          ],
          const SizedBox(height: 22),
          const Divider(color: AppColors.border),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(memaRoute(const InscriptionScreen())),
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: const Text(
                'Pas encore de compte ? Inscrire ma pharmacie',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mema_widgets.dart';
import 'garde_tab.dart';
import 'login_screen.dart';
import 'stock_tab.dart';

class PharmacienScreen extends StatefulWidget {
  const PharmacienScreen({super.key});

  @override
  State<PharmacienScreen> createState() => _PharmacienScreenState();
}

class _PharmacienScreenState extends State<PharmacienScreen> {
  int _onglet = 0;

  void _deconnecter() {
    SessionService.fermer();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _sessionExpiree() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Votre session a expiré. Reconnectez-vous.')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      memaRoute(const LoginScreen()),
          (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = SessionService.utilisateur;
    return MemaScaffold(
      title: SessionService.pharmacieNom ?? 'Ma pharmacie',
      subtitle: utilisateur != null ? 'Connecté : ${utilisateur.nom}' : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _Onglet(
                    label: 'Stock',
                    icon: Icons.inventory_2_rounded,
                    actif: _onglet == 0,
                    onTap: () => setState(() => _onglet = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Onglet(
                    label: 'Gardes',
                    icon: Icons.nightlight_round,
                    actif: _onglet == 1,
                    onTap: () => setState(() => _onglet = 1),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _deconnecter,
                  tooltip: 'Se déconnecter',
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _onglet,
              children: [
                StockTab(onSessionExpiree: _sessionExpiree),
                GardeTab(onSessionExpiree: _sessionExpiree),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool actif;
  final VoidCallback onTap;

  const _Onglet({
    required this.label,
    required this.icon,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: actif ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: actif ? AppColors.primary : AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: actif ? Colors.white : AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: actif ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
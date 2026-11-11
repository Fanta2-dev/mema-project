import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mema_widgets.dart';
import 'admin_catalogue_tab.dart';
import 'admin_comptes_tab.dart';
import 'admin_demandes_tab.dart';
import 'admin_inscriptions_tab.dart';
import 'admin_pharmacies_tab.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _onglet = 0;

  static const List<String> _libelles = [
    'Inscriptions',
    'Demandes',
    'Pharmacies',
    'Comptes',
    'Catalogue',
  ];
  static const List<IconData> _icones = [
    Icons.how_to_reg_rounded,
    Icons.mark_email_unread_rounded,
    Icons.local_pharmacy_rounded,
    Icons.manage_accounts_rounded,
    Icons.menu_book_rounded,
  ];

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

  /// Chaque changement d'onglet recharge les données : elles sont toujours à jour.
  Widget _corps() {
    switch (_onglet) {
      case 0:
        return AdminInscriptionsTab(
          key: const ValueKey('inscriptions'),
          onSessionExpiree: _sessionExpiree,
        );
      case 1:
        return AdminDemandesTab(
          key: const ValueKey('demandes'),
          onSessionExpiree: _sessionExpiree,
          onAllerCatalogue: () => setState(() => _onglet = 4),
        );
      case 2:
        return AdminPharmaciesTab(
          key: const ValueKey('pharmacies'),
          onSessionExpiree: _sessionExpiree,
        );
      case 3:
        return AdminComptesTab(
          key: const ValueKey('comptes'),
          onSessionExpiree: _sessionExpiree,
        );
      default:
        return AdminCatalogueTab(
          key: const ValueKey('catalogue'),
          onSessionExpiree: _sessionExpiree,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = SessionService.utilisateur;
    return MemaScaffold(
      title: 'Administration',
      subtitle: utilisateur != null ? 'Connecté : ${utilisateur.nom}' : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _libelles.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Onglet(
                              label: _libelles[i],
                              icon: _icones[i],
                              actif: _onglet == i,
                              onTap: () => setState(() => _onglet = i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _deconnecter,
                  tooltip: 'Se déconnecter',
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                ),
              ],
            ),
          ),
          Expanded(child: _corps()),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 17, color: actif ? Colors.white : AppColors.primary),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: actif ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
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
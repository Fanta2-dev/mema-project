import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/mema_widgets.dart';
import 'admin_screen.dart';
import 'location_screen.dart';
import 'login_screen.dart';
import 'pharmacien_screen.dart';
import 'pharmacies_garde_screen.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  Widget _ecranProfessionnel() {
    if (!SessionService.connecte) return const LoginScreen();
    return SessionService.utilisateur?.estAdmin == true
        ? const AdminScreen()
        : const PharmacienScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MemaScaffold(
      title: 'Qui êtes-vous ?',
      subtitle: 'Choisissez votre profil pour une expérience adaptée.',
      step: 1,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Reveal(
            index: 0,
            child: _CarteUrgence(
              onTap: () => Navigator.of(context)
                  .push(memaRoute(const PharmaciesGardeScreen())),
            ),
          ),
          const SizedBox(height: 18),
          Reveal(
            index: 1,
            child: _RoleCard(
              icon: Icons.people_alt_rounded,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryTint,
              title: 'Patient ou assistant',
              subtitle: 'Trouver un médicament disponible près de moi',
              badge: 'Gratuit, sans compte',
              onTap: () => Navigator.of(context).push(memaRoute(const LocationScreen())),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 2,
            child: _RoleCard(
              icon: Icons.local_pharmacy_rounded,
              iconColor: AppColors.accent,
              iconBg: AppColors.accentTint,
              title: 'Agent de santé / pharmacien',
              subtitle: 'Stock, gardes et administration',
              badge: 'Connexion requise',
              onTap: () => Navigator.of(context).push(memaRoute(_ecranProfessionnel())),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accès direct, sans rien choisir : les pharmacies de garde en ce moment.
class _CarteUrgence extends StatelessWidget {
  final VoidCallback onTap;
  const _CarteUrgence({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.nightlight_round,
                      color: AppColors.primaryDark, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Besoin d'une pharmacie de garde ?",
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Voir celles qui sont ouvertes en ce moment',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MemaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.caption),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSoft),
        ],
      ),
    );
  }
}
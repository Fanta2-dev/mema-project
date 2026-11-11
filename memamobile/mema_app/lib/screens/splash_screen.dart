import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/mema_widgets.dart';
import 'role_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final Animation<double> _logo = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
  );
  late final Animation<double> _texte = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
  );
  late final Animation<double> _bouton = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            // Cercles décoratifs
            Positioned(
              top: -90,
              right: -70,
              child: _cercle(260, AppColors.accent.withOpacity(0.10)),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: _cercle(300, Colors.white.withOpacity(0.05)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    ScaleTransition(scale: _logo, child: const MemaLogo(size: 96)),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _texte,
                      child: Column(
                        children: [
                          const Text(
                            'MEMA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'MÉDICAMENT + MALADE',
                            style: TextStyle(
                              color: AppColors.accentLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Savoir tout de suite où trouver\nvotre médicament.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryTint,
                              fontSize: 16,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: _bouton,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(_bouton),
                        child: Column(
                          children: [
                            MemaButton(
                              label: 'Commencer',
                              icon: Icons.arrow_forward_rounded,
                              variant: 'accent',
                              onPressed: () {
                                Navigator.of(context)
                                    .pushReplacement(memaRoute(const RoleScreen()));
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.verified_rounded,
                                    size: 16, color: AppColors.accentLight),
                                SizedBox(width: 6),
                                Text(
                                  'Pharmacies agréées uniquement',
                                  style: TextStyle(
                                      color: AppColors.primaryTint, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cercle(double taille, Color couleur) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
  );
}
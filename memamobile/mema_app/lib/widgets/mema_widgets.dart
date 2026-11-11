import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Transition de page commune : fondu + léger glissement.
Route<T> memaRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Logo MEMA (pastille or + icône médicament).
class MemaLogo extends StatelessWidget {
  final double size;
  const MemaLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.medication_rounded, color: AppColors.primaryDark, size: size * 0.52),
    );
  }
}

/// Bouton principal. variant : 'primary' (vert), 'accent' (or), 'outline'.
class MemaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String variant;

  const MemaButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.variant = 'primary',
  });

  @override
  Widget build(BuildContext context) {
    final outline = variant == 'outline';
    final bg = variant == 'accent' ? AppColors.accent : AppColors.primary;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: outline ? AppColors.primary : Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
        ),
      ],
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));
    const size = Size.fromHeight(54);
    final action = loading ? null : onPressed;

    if (outline) {
      return OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: size,
          shape: shape,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        child: content,
      );
    }
    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSoft,
        elevation: 0,
        minimumSize: size,
        shape: shape,
      ),
      child: content,
    );
  }
}

/// Carte blanche arrondie avec ombre douce.
class MemaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  const MemaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
    this.borderColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pastille d'état (Disponible, Rupture...).
class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Structure commune des écrans : en-tête dégradé arrondi, contenu, barre du bas.
class MemaScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? step; // 1..totalSteps
  final int totalSteps;
  final Widget child;
  final Widget? bottom;

  const MemaScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.step,
    this.totalSteps = 3,
    required this.child,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 26),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (canPop)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    const Spacer(),
                    if (step != null) _StepDots(step: step!, total: totalSteps),
                  ],
                ),
                const SizedBox(height: 18),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppColors.primaryTint, fontSize: 14, height: 1.45)),
                ],
              ],
            ),
          ),
          Expanded(child: child),
          if (bottom != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(top: false, child: bottom!),
            ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;
  final int total;
  const _StepDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(left: 6),
            width: i == step ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= step ? AppColors.accent : Colors.white.withOpacity(0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// Bloc rectangulaire qui « respire » pendant le chargement.
class SkeletonBox extends StatefulWidget {
  final double height;
  const SkeletonBox({super.key, this.height = 76});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.border, Colors.white, _c.value * 0.7),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// Liste de squelettes affichée pendant un chargement.
class LoadingList extends StatelessWidget {
  final int count;
  const LoadingList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [for (var i = 0; i < count; i++) const SkeletonBox()],
    );
  }
}

/// État vide / erreur : icône, message, action.
class StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger;

  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: danger ? AppColors.dangerTint : AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 38, color: danger ? AppColors.danger : AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: AppText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppText.body, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                child: MemaButton(
                    label: actionLabel!, icon: Icons.refresh_rounded, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Apparition progressive d'un élément de liste (décalée par index).
class Reveal extends StatelessWidget {
  final int index;
  final Widget child;
  const Reveal({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index.clamp(0, 8) * 70)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: c),
      ),
      child: child,
    );
  }
}
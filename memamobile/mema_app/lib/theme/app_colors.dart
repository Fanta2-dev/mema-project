import 'package:flutter/material.dart';

/// Palette MEMA : vert profond (confiance, santé) + or (action, chaleur).
/// Les couleurs d'origine sont conservées ; seules des nuances dérivées sont ajoutées.
class AppColors {
  // --- Couleurs d'origine ---
  static const primary = Color(0xFF134A43);
  static const primaryDark = Color(0xFF0C332E);
  static const primaryTint = Color(0xFFDCEBE6);
  static const accent = Color(0xFFCE9A3D);
  static const accentTint = Color(0xFFF6ECD6);
  static const danger = Color(0xFFAE4230);
  static const dangerTint = Color(0xFFF4E0DB);
  static const text = Color(0xFF22271F);
  static const textSoft = Color(0xFF5C6459);
  static const background = Color(0xFFEEF3EA);
  static const border = Color(0xFFDCE2D5);

  // --- Nuances dérivées (dégradés, relief) ---
  static const primaryLight = Color(0xFF1F6B60);
  static const accentLight = Color(0xFFE3B866);
  static const surface = Colors.white;

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryDark.withOpacity(0.07),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}
import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Le logo, cadré exactement comme sur la bannière du profil GitHub.
///
/// Le fichier porte son propre cadre néon, mais réduit à la taille d'un
/// écran, son trait ne pèse plus que deux pixels et sort crénelé. Le logo
/// est donc agrandi au-delà de ce cadre, 182 pour une plaque de 142, et le
/// contour est redessiné : un trait de 1,5 à 75 %, un halo faible de 7, et
/// une ombre portée sombre. Les mêmes valeurs que `smartbudget.sh`, à
/// l'échelle de [taille].
class LogoNeon extends StatelessWidget {
  const LogoNeon({super.key, this.taille = 142});

  final double taille;

  @override
  Widget build(BuildContext context) {
    final echelle = taille / 142;
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30 * echelle),
        border: Border.all(color: const Color(0xC050F48D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neon.withValues(alpha: 0x30 / 255),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: Offset(0, 12 * echelle),
            blurRadius: 34 * echelle,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30 * echelle - 1.5),
        child: OverflowBox(
          maxWidth: 182 * echelle,
          maxHeight: 182 * echelle,
          child: Image.asset(
            'assets/logo.png',
            width: 182 * echelle,
            height: 182 * echelle,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

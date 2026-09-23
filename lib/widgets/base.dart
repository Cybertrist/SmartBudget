import 'package:flutter/material.dart';

import '../config/icones_symbols.dart';
import '../config/theme.dart';
import '../config/format.dart';

/// Une icône Material Symbols par son nom.
IconData icone(String? nom) => iconesSymbols[nom] ?? iconesSymbols['category']!;

/// La tuile d'une catégorie : verre teinté de sa couleur, un reflet en
/// haut, et un halo de la même couleur. C'est la seule lueur de
/// l'application.
class Tuile extends StatelessWidget {
  const Tuile({super.key, required this.icone, required this.couleur, this.taille = 42, this.eteinte = false});

  final String? icone;
  final Color couleur;
  final double taille;

  /// Grise et sans halo, pour une catégorie vide ce mois-ci.
  final bool eteinte;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(taille * 0.34);
    if (eteinte) {
      return Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Icon(iconeDe(icone), size: taille * 0.48, color: AppColors.texteDiscret),
      );
    }
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [couleur.withValues(alpha: 0.2), couleur.withValues(alpha: 0.063)],
        ),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: couleur.withValues(alpha: 0.56), blurRadius: 18, spreadRadius: -8, offset: const Offset(0, 6)),
        ],
      ),
      child: Icon(iconeDe(icone), size: taille * 0.5, color: couleur, fill: 1),
    );
  }
}

IconData iconeDe(String? nom) => icone(nom);

/// Une carte plate.
class Carte extends StatelessWidget {
  const Carte({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.couleur = AppColors.surface, this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final Color couleur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: couleur,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Le titre discret d'une carte, et ce qui s'aligne à sa droite.
class Surtitre extends StatelessWidget {
  const Surtitre(this.texte, {super.key, this.droite});

  final String texte;
  final Widget? droite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            texte.toUpperCase(),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: AppColors.texteSecondaire),
          ),
        ),
        ?droite,
      ],
    );
  }
}

/// Un montant, toujours écrit pareil.
class Montant extends StatelessWidget {
  const Montant(this.centimes, {super.key, this.taille = 16, this.couleur, this.signe = false, this.poids = FontWeight.w700});

  final int centimes;
  final double taille;
  final Color? couleur;
  final bool signe;
  final FontWeight poids;

  @override
  Widget build(BuildContext context) {
    return Text(
      euros(centimes, signe: signe),
      maxLines: 1,
      style: TextStyle(
        fontSize: taille,
        fontWeight: poids,
        color: couleur ?? AppColors.texte,
        fontFeatures: chiffres,
        letterSpacing: taille > 30 ? -0.8 : -0.1,
      ),
    );
  }
}

/// Une barre de progression plate.
class Jauge extends StatelessWidget {
  const Jauge({super.key, required this.part, this.couleur = AppColors.vert, this.hauteur = 8});

  final double part;
  final Color couleur;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: hauteur,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0x0DFFFFFF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: part.clamp(0, 1),
              child: ColoredBox(color: couleur),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une barre coupée en segments, un par catégorie.
class BarreSegmentee extends StatelessWidget {
  const BarreSegmentee({super.key, required this.parts, this.hauteur = 9});

  final List<(int, Color)> parts;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    final utiles = parts.where((p) => p.$1 > 0).toList();
    if (utiles.isEmpty) return Jauge(part: 0, hauteur: hauteur);
    // Un segment ne descend pas sous 2,5 % de la barre : une petite
    // dépense doit rester visible.
    final total = utiles.fold<int>(0, (s, p) => s + p.$1);
    int largeur(int v) => (1000 * (v / total < 0.025 ? 0.025 : v / total)).round();
    return SizedBox(
      height: hauteur,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < utiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: largeur(utiles[i].$1),
              child: DecoratedBox(decoration: BoxDecoration(color: utiles[i].$2, borderRadius: BorderRadius.circular(99))),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un bouton rond d'en-tête : retour, recherche.
class BoutonRond extends StatelessWidget {
  const BoutonRond({super.key, required this.icone, required this.onTap, required this.label});

  final String icone;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: const Color(0x0AFFFFFF),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(iconeDe(icone), size: 22)),
        ),
      ),
    );
  }
}

/// Le motif hachuré des virements internes : « ceci ne compte pas ».
class Hachures extends CustomPainter {
  const Hachures();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.interne.withValues(alpha: 0.07)
      ..strokeWidth = 2;
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Les couleurs et icônes de la répartition des dépenses.
Color couleurNature(Object n) => switch (n.toString().split('.').last) {
      'essentiel' => const Color(0xFF5AB2FF),
      'plaisir' => const Color(0xFFFF8FD1),
      'imprevu' => const Color(0xFFFF9F5A),
      _ => AppColors.epargne,
    };

String iconeNature(Object n) => switch (n.toString().split('.').last) {
      'essentiel' => 'favorite',
      'plaisir' => 'thumb_up',
      'imprevu' => 'bolt',
      _ => 'savings',
    };

/// Pose une pastille verte cochée au coin bas droit de [child] quand
/// l'opération est pointée.
class AvecCoche extends StatelessWidget {
  const AvecCoche({super.key, required this.pointee, required this.child, this.taille = 18});

  final bool pointee;
  final Widget child;
  final double taille;

  @override
  Widget build(BuildContext context) {
    if (!pointee) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -taille * 0.3,
          bottom: -taille * 0.3,
          child: Container(
            width: taille,
            height: taille,
            decoration: BoxDecoration(
              color: AppColors.vert,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
            child: Icon(iconeDe('check'), size: taille * 0.62, color: Colors.black, weight: 700),
          ),
        ),
      ],
    );
  }
}

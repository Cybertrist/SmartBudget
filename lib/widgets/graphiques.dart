import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/mois.dart';
import '../providers/donnees.dart';
import 'base.dart';

/// Le mois affiché, et les flèches pour en changer. Partagé : changer de
/// mois ici le change partout.
class SelecteurMois extends ConsumerWidget {
  const SelecteurMois({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mois = ref.watch(moisProvider);
    final courant = Mois.de(DateTime.now());
    void aller(Mois m) => ref.read(moisProvider.notifier).state = m;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mois précédent',
            onPressed: () => aller(mois.precedent),
            icon: Icon(iconeDe('chevron_left'), color: AppColors.texteSecondaire),
          ),
          Expanded(
            child: Text(nomMois(mois), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: 'Mois suivant',
            onPressed: mois.compareTo(courant) >= 0 ? null : () => aller(mois.suivant),
            icon: Icon(iconeDe('chevron_right'), color: AppColors.texteSecondaire),
          ),
        ],
      ),
    );
  }
}

/// Une part de l'anneau.
class PartAnneau {
  const PartAnneau(this.valeur, this.couleur, this.icone);

  final int valeur;
  final Color couleur;
  final String? icone;
}

/// L'anneau des dépenses : fin, des segments nets séparés d'un filet, et
/// l'icône de chaque catégorie posée à l'extérieur, au milieu de son arc.
class Anneau extends StatelessWidget {
  const Anneau({super.key, required this.parts, required this.centre, this.taille = 300});

  final List<PartAnneau> parts;
  final Widget centre;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final total = parts.fold<int>(0, (s, p) => s + max(p.valeur, 0));
    final rayon = taille * 0.32;
    final badges = <Widget>[];
    var debut = -pi / 2;
    if (total > 0) {
      for (final p in parts) {
        if (p.valeur <= 0) continue;
        final angle = p.valeur / total * 2 * pi;
        if (p.valeur / total >= 0.05) {
          final milieu = debut + angle / 2;
          final r = rayon + 30;
          badges.add(Positioned(
            left: taille / 2 + cos(milieu) * r - 15,
            top: taille / 2 + sin(milieu) * r - 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.couleur.withValues(alpha: 0.4)),
              ),
              child: Icon(iconeDe(p.icone), size: 16, color: p.couleur, fill: 1),
            ),
          ));
        }
        debut += angle;
      }
    }
    return SizedBox(
      width: taille,
      height: taille,
      child: Stack(
        children: [
          CustomPaint(size: Size.square(taille), painter: _Anneau(parts, total, rayon)),
          ...badges,
          Positioned.fill(child: Center(child: centre)),
        ],
      ),
    );
  }
}

class _Anneau extends CustomPainter {
  _Anneau(this.parts, this.total, this.rayon);

  final List<PartAnneau> parts;
  final int total;
  final double rayon;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const epaisseur = 16.0;
    final filet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0DFFFFFF);
    canvas.drawCircle(c, rayon + epaisseur / 2 + 5, filet);
    canvas.drawCircle(c, rayon - epaisseur / 2 - 5, filet);
    final rect = Rect.fromCircle(center: c, radius: rayon);
    if (total == 0) {
      canvas.drawCircle(c, rayon, Paint()..style = PaintingStyle.stroke..strokeWidth = epaisseur..color = AppColors.surfaceHaute);
      return;
    }
    const jeu = 3 / 96;
    var debut = -pi / 2;
    for (final p in parts) {
      if (p.valeur <= 0) continue;
      final angle = p.valeur / total * 2 * pi;
      canvas.drawArc(
        rect,
        debut,
        max(angle - jeu, 0.01),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = epaisseur
          ..color = p.couleur,
      );
      debut += angle;
    }
  }

  @override
  bool shouldRepaint(covariant _Anneau o) => o.parts != parts || o.total != total;
}

/// La courbe du solde sur le mois, jusqu'à aujourd'hui.
class CourbeSolde extends StatelessWidget {
  const CourbeSolde({super.key, required this.points, required this.jours});

  /// Le solde, en centimes, à la fin de chaque jour écoulé.
  final List<int> points;

  /// Le nombre de jours du mois.
  final int jours;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 96, child: CustomPaint(size: Size.infinite, painter: _Courbe(points, jours)));
  }
}

class _Courbe extends CustomPainter {
  _Courbe(this.points, this.jours);

  final List<int> points;
  final int jours;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final mn = points.reduce(min).toDouble();
    final mx = points.reduce(max).toDouble();
    final plage = max(mx - mn, 1);
    final h = size.height - 12;
    Offset p(int i) => Offset(i / max(jours - 1, 1) * size.width, 6 + h - (points[i] - mn) / plage * h);

    final ligne = Path()..moveTo(p(0).dx, p(0).dy);
    for (var i = 1; i < points.length; i++) {
      ligne.lineTo(p(i).dx, p(i).dy);
    }
    final aire = Path.from(ligne)
      ..lineTo(p(points.length - 1).dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      aire,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.vert.withValues(alpha: 0.22), AppColors.vert.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      ligne,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.vert,
    );
    final fin = p(points.length - 1);
    final pointille = Paint()
      ..color = AppColors.vert.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    for (var x = fin.dx + 4; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, fin.dy), Offset(min(x + 2, size.width), fin.dy), pointille);
    }
    canvas.drawCircle(fin, 4.5, Paint()..color = AppColors.vert);
  }

  @override
  bool shouldRepaint(covariant _Courbe o) => o.points != points;
}

/// Le cadran de l'épargne : des graduations allumées jusqu'à l'objectif
/// atteint.
class Cadran extends StatelessWidget {
  const Cadran({super.key, required this.part, this.couleur = AppColors.epargne});

  final double part;
  final Color couleur;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 126, height: 68, child: CustomPaint(painter: _Cadran(part.clamp(0, 1), couleur)));
}

class _Cadran extends CustomPainter {
  _Cadran(this.part, this.couleur);

  final double part;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final c = Offset(size.width / 2, size.height - 6);
    for (var i = 0; i < n; i++) {
      final a = pi + i / (n - 1) * pi;
      final on = i / (n - 1) <= part && part > 0;
      canvas.drawLine(
        c + Offset(cos(a), sin(a)) * 42,
        c + Offset(cos(a), sin(a)) * 54,
        Paint()
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..color = on ? couleur : const Color(0x17FFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Cadran o) => o.part != part;
}

/// Les dépenses semaine par semaine.
class BarresSemaines extends StatelessWidget {
  const BarresSemaines({super.key, required this.semaines});

  /// Libellé et montant de chaque semaine ; la dernière est la courante.
  final List<(String, int)> semaines;

  @override
  Widget build(BuildContext context) {
    final mx = semaines.fold<int>(1, (m, s) => max(m, s.$2));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < semaines.length; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 108,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 34,
                      height: 8 + semaines[i].$2 / mx * 96,
                      decoration: BoxDecoration(
                        color: i == semaines.length - 1 ? AppColors.vert : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(semaines[i].$1,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: chiffres,
                        color: i == semaines.length - 1 ? AppColors.texte : AppColors.texteDiscret)),
                const SizedBox(height: 2),
                Montant(semaines[i].$2, taille: 12, couleur: i == semaines.length - 1 ? AppColors.vert : AppColors.texteDiscret),
              ],
            ),
          ),
      ],
    );
  }
}

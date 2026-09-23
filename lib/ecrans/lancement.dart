import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Le lancement : ce qui se voit entre l'icône touchée et l'écran
/// d'ouverture.
///
/// Android pose d'abord son propre écran, le logo au centre. Celui-ci
/// prend le relais au même endroit et l'anime : les trois barres montent
/// l'une après l'autre, puis le nom apparaît dessous. L'écran d'ouverture
/// attend la fin pour demander l'empreinte : la fenêtre du système par
/// dessus l'animation la couperait en plein milieu.
class Lancement {
  Lancement._();

  static final _fini = Completer<void>();

  static Future<void> get termine => _fini.future;
  static bool get estTermine => _fini.isCompleted;

  static void _terminer() {
    if (!_fini.isCompleted) _fini.complete();
  }
}

class AnimationLancement extends StatefulWidget {
  const AnimationLancement({super.key});

  @override
  State<AnimationLancement> createState() => _EtatLancement();
}

class _EtatLancement extends State<AnimationLancement> with TickerProviderStateMixin {
  late final _entree = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final _sortie = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  /// Déjà joué dans ce processus : l'activité a été recréée, pas
  /// l'application relancée.
  bool _parti = Lancement.estTermine;

  @override
  void initState() {
    super.initState();
    if (!_parti) _derouler();
  }

  Future<void> _derouler() async {
    await Future<void>.delayed(const Duration(milliseconds: 1750));
    if (!mounted) return;
    await _sortie.forward();
    if (!mounted) return;
    setState(() => _parti = true);
    Lancement._terminer();
  }

  @override
  void dispose() {
    _entree.dispose();
    _sortie.dispose();
    Lancement._terminer();
    super.dispose();
  }

  double _phase(double debut, double fin, [Curve courbe = Curves.easeOutCubic]) =>
      courbe.transform(((_entree.value - debut) / (fin - debut)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    if (_parti) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: Listenable.merge([_entree, _sortie]),
      builder: (context, _) {
        final sortie = Curves.easeInCubic.transform(_sortie.value);
        return IgnorePointer(
          ignoring: _sortie.value > 0.5,
          child: Opacity(
            opacity: 1 - sortie,
            child: ColoredBox(
              color: AppColors.fond,
              child: Center(
                child: Transform.scale(
                  scale: 1 + sortie * 0.06,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LogoAnime(
                        taille: 144,
                        barres: [
                          _phase(0.10, 0.55, Curves.easeOutBack),
                          _phase(0.22, 0.67, Curves.easeOutBack),
                          _phase(0.34, 0.79, Curves.easeOutBack),
                        ],
                        cadre: _phase(0.0, 0.35),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: _phase(0.62, 0.95),
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - _phase(0.62, 0.95))),
                          child: const NomApp(taille: 34),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// « Smart Budget », comme sur la bannière du dépôt : le second mot en
/// vert.
class NomApp extends StatelessWidget {
  const NomApp({super.key, this.taille = 24});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        const TextSpan(text: 'Smart '),
        TextSpan(text: 'Budget', style: TextStyle(color: AppColors.neon)),
      ]),
      style: TextStyle(fontSize: taille, fontWeight: FontWeight.w800, letterSpacing: -taille * 0.03, color: AppColors.texte),
    );
  }
}

/// Le logo redessiné, pour pouvoir animer ses barres : une plaque sombre,
/// un cadre néon, trois barres qui montent.
class LogoAnime extends StatelessWidget {
  const LogoAnime({super.key, required this.taille, required this.barres, this.cadre = 1});

  final double taille;

  /// La hauteur de chaque barre, de 0 à 1 (un peu plus pendant le rebond).
  final List<double> barres;
  final double cadre;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: taille,
      child: CustomPaint(painter: _Logo(barres, cadre)),
    );
  }
}

class _Logo extends CustomPainter {
  _Logo(this.barres, this.cadre);

  final List<double> barres;
  final double cadre;

  static const _couleurs = [
    [Color(0xFFD2FFE2), Color(0xFF8DF3B2)],
    [Color(0xFF8BFFB5), Color(0xFF3FE08A)],
    [Color(0xFF4FF596), Color(0xFF10C265)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = size.width;
    final plaque = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(t * 0.21));
    canvas.drawRRect(plaque, Paint()..color = const Color(0xFF02110A).withValues(alpha: cadre));
    canvas.drawRRect(
      plaque.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.neon.withValues(alpha: 0.75 * cadre),
    );
    canvas.drawRRect(
      plaque,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..color = AppColors.neon.withValues(alpha: 0.18 * cadre),
    );

    final largeur = t * 0.16;
    final bas = t * 0.76;
    const hauteurs = [0.27, 0.40, 0.54];
    const centres = [0.32, 0.5, 0.68];
    for (var i = 0; i < 3; i++) {
      final h = t * hauteurs[i] * math.max(barres[i], 0);
      if (h <= 0) continue;
      final r = Rect.fromLTWH(t * centres[i] - largeur / 2, bas - h, largeur, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(largeur / 2)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _couleurs[i],
          ).createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Logo o) => o.barres != barres || o.cadre != cadre;
}

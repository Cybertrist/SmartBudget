import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/logo_neon.dart';

/// Le lancement : ce qui se voit entre l'icône touchée et l'écran
/// d'ouverture.
///
/// Android pose d'abord son propre écran, le logo au centre. Celui-ci
/// prend le relais au même endroit : le vrai logo grandit, un reflet le
/// traverse, puis le nom apparaît dessous. L'écran d'ouverture
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
            child: Material(
              color: AppColors.fond,
              child: Center(
                child: Transform.scale(
                  scale: 1 + sortie * 0.06,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Le vrai logo, pas une copie redessinée : il grandit, puis un
                      // reflet le traverse.
                      Opacity(
                        opacity: _phase(0.0, 0.3),
                        child: Transform.scale(
                          scale: 0.82 + 0.18 * _phase(0.0, 0.55, Curves.easeOutBack),
                          child: Stack(
                            children: [
                              const LogoNeon(taille: 144),
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: FractionalTranslation(
                                    translation: Offset(-1.2 + 2.4 * _phase(0.45, 0.95, Curves.easeInOut), 0),
                                    child: const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment(-1, -0.4),
                                          end: Alignment(1, 0.4),
                                          colors: [Color(0x00FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
                                          stops: [0.3, 0.5, 0.7],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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


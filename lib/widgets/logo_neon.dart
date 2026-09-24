import 'dart:math';

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Le logo, tel que l'icône de l'application : le liseré vert à la forme
/// des icônes de Samsung, la plaque sombre, les barres. L'image vient de
/// `tool/icone.mjs`, comme l'icône, pour que les deux ne divergent jamais.
///
/// Dessous, un halo vert faible et une ombre portée sombre, qui suivent la
/// même forme.
class LogoNeon extends StatelessWidget {
  const LogoNeon({super.key, this.taille = 142});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: taille,
      height: taille,
      child: CustomPaint(
        painter: _Ombre(),
        child: Image.asset('assets/logo_icone.png', width: taille, height: taille, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

/// La forme des icônes de Samsung, une superellipse, sur [taille].
Path formeLogo(Size taille) {
  final r = taille.shortestSide / 2;
  final c = taille.center(Offset.zero);
  const n = 4.2;
  final chemin = Path();
  for (var i = 0; i <= 360; i++) {
    final a = i / 360 * 2 * pi;
    final x = c.dx + r * cos(a).sign * pow(cos(a).abs(), 2 / n);
    final y = c.dy + r * sin(a).sign * pow(sin(a).abs(), 2 / n);
    i == 0 ? chemin.moveTo(x, y) : chemin.lineTo(x, y);
  }
  return chemin..close();
}

class _Ombre extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final forme = formeLogo(size);
    final e = size.shortestSide / 142;
    canvas.drawPath(
      forme.shift(Offset(0, 12 * e)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 17 * e),
    );
    canvas.drawPath(
      forme,
      Paint()
        ..color = AppColors.neon.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * e),
    );
  }

  @override
  bool shouldRepaint(_Ombre old) => false;
}

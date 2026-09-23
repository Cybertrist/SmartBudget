import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/layout.dart';
import '../config/theme.dart';
import 'base.dart';
import 'volets.dart';

/// Les quatre onglets.
const onglets = [
  ('home', 'Mois', '/mois'),
  ('pie_chart', 'Analyse', '/analyse'),
  ('savings', 'Épargne', '/epargne'),
  ('settings', 'Réglages', '/reglages'),
];

/// La coque : la capsule flottante en bas sur téléphone et sur l'écran de
/// couverture, le rail à gauche sur l'écran déplié.
class Coque extends ConsumerWidget {
  const Coque({super.key, required this.child, required this.chemin});

  final Widget child;
  final String chemin;

  int get _index {
    final i = onglets.indexWhere((o) => chemin.startsWith(o.$3));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppLayout.usesRail(context)) {
      return Scaffold(
        body: Row(
          children: [
            _Rail(index: _index),
            const VerticalDivider(width: 1, color: AppColors.trait),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: retourVolet,
                // Le geste retour referme d'abord le dernier volet.
                builder: (_, retour, enfant) => PopScope(
                  canPop: retour == null,
                  onPopInvokedWithResult: (fait, _) {
                    if (!fait) retour?.call();
                  },
                  child: enfant!,
                ),
                child: MediaQuery.removePadding(context: context, removeLeft: true, child: child),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _Capsule(index: _index),
    );
  }
}

/// Place à laisser sous le contenu pour que la capsule ne le cache pas.
double margeCapsule(BuildContext context) =>
    AppLayout.usesRail(context) ? 24 : 110 + MediaQuery.paddingOf(context).bottom;

class _Capsule extends StatelessWidget {
  const _Capsule({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final bas = MediaQuery.paddingOf(context).bottom;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Le bas de page s'assombrit derrière la capsule.
        IgnorePointer(
          child: Container(
            height: 120 + bas,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00121212), Color(0xE6121212)],
                stops: [0, 0.6],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bas),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 68,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xB8282828),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < onglets.length; i++)
                      Expanded(child: _Onglet(onglet: onglets[i], actif: i == index)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({required this.onglet, required this.actif});

  final (String, String, String) onglet;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.texte : const Color(0xFF9A9A9A);
    return Semantics(
      selected: actif,
      button: true,
      label: onglet.$2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: actif ? const Color(0x24FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.go(onglet.$3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconeDe(onglet.$1), size: 22, color: couleur, fill: actif ? 1 : 0, weight: actif ? 600 : 400),
              const SizedBox(height: 3),
              Text(
                onglet.$2,
                maxLines: 1,
                style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w800 : FontWeight.w600, color: couleur),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le rail de l'écran déplié : de la couleur de la page, sans logo, les
/// quatre onglets au milieu de la hauteur, là où tombe le pouce.
class _Rail extends StatelessWidget {
  const _Rail({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final gauche = MediaQuery.paddingOf(context).left;
    return Container(
      width: 92 + gauche,
      padding: EdgeInsets.only(left: gauche),
      color: AppColors.fond,
      child: SafeArea(
        left: false,
        right: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < onglets.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _OngletRail(onglet: onglets[i], actif: i == index),
              ),
          ],
        ),
      ),
    );
  }
}

/// Un onglet du rail : l'icône dans une pastille quand il est actif, le
/// nom dessous.
class _OngletRail extends StatelessWidget {
  const _OngletRail({required this.onglet, required this.actif});

  final (String, String, String) onglet;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.texte : const Color(0xFF9A9A9A);
    return Semantics(
      selected: actif,
      button: true,
      label: onglet.$2,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go(onglet.$3),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 60,
                height: 34,
                decoration: BoxDecoration(
                  color: actif ? const Color(0x24FFFFFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(iconeDe(onglet.$1), size: 23, color: couleur, fill: actif ? 1 : 0, weight: actif ? 600 : 400),
              ),
              const SizedBox(height: 6),
              Text(onglet.$2, maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: actif ? FontWeight.w800 : FontWeight.w600, color: couleur)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une page d'onglet : sur téléphone, une liste qui défile sous son titre ;
/// sur l'écran déplié, deux colonnes qui tiennent sans défiler, avec les
/// mêmes titres que les volets.
class DeuxColonnes extends StatelessWidget {
  const DeuxColonnes({
    super.key,
    required this.titre,
    required this.gauche,
    required this.droite,
    this.surtitre,
    this.titreDroite = '',
    this.surtitreDroite,
  });

  final String titre;
  final String? surtitre;
  final String titreDroite;
  final String? surtitreDroite;
  final List<Widget> gauche;
  final List<Widget> droite;

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.usesRail(context)) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, margeCapsule(context)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 14),
            child: Text(titre, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          ),
          ...gauche,
          const SizedBox(height: 14),
          ...droite,
        ],
      );
    }
    const marges = EdgeInsets.fromLTRB(16, 0, 16, 20);
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Contenu(ajuster: true, padding: marges, tete: TitreVolet(surtitre: surtitre, titre: titre), children: gauche)),
          const VerticalDivider(width: 1, color: AppColors.trait),
          Expanded(child: Contenu(ajuster: true, padding: marges, tete: TitreVolet(surtitre: surtitreDroite, titre: titreDroite), children: droite)),
        ],
      ),
    );
  }
}

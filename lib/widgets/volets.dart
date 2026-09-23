import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// La navigation en volets de l'écran déplié.
///
/// Sur téléphone, toucher une catégorie ouvre une nouvelle page. Sur
/// l'écran déplié, les pages forment une pile dont on montre les deux
/// dernières, côte à côte, couché ou non : toucher Shopping pousse tout
/// vers la gauche, la liste prend la place de l'anneau et Shopping s'ouvre
/// à droite, et ainsi de suite jusqu'à une opération.
class VoletScope extends InheritedWidget {
  const VoletScope({super.key, required this.index, required this.pousser, required this.retirer, required super.child});

  /// La place de ce volet dans la pile.
  final int index;

  /// Ouvre [chemin] juste après ce volet, en fermant ce qui suivait.
  final void Function(int depuis, String chemin) pousser;

  /// Referme le dernier volet.
  final VoidCallback retirer;

  static VoletScope? de(BuildContext context) => context.dependOnInheritedWidgetOfExactType<VoletScope>();

  @override
  bool updateShouldNotify(VoletScope old) => old.index != index;
}

/// Ouvre une page : dans le volet voisin sur l'écran déplié, sinon en
/// plein écran.
void ouvrirPage(BuildContext context, String chemin) {
  final volet = VoletScope.de(context);
  if (volet != null) {
    volet.pousser(volet.index, chemin);
  } else {
    context.push(chemin);
  }
}

/// Revient en arrière : ferme le dernier volet, ou la page.
void revenir(BuildContext context) {
  final volet = VoletScope.de(context);
  if (volet != null) {
    volet.retirer();
  } else if (context.canPop()) {
    context.pop();
  } else {
    context.go('/analyse');
  }
}

/// Montre les [nombre] derniers volets d'une pile de chemins, et fait
/// glisser le tout vers la gauche quand un volet s'ajoute.
class PileVolets extends StatefulWidget {
  const PileVolets({super.key, required this.racine, required this.construire, required this.nombre});

  /// Les premiers volets, toujours là au fond de la pile.
  final List<String> racine;

  /// Le widget d'un chemin.
  final Widget Function(String chemin) construire;
  final int nombre;

  @override
  State<PileVolets> createState() => _EtatPile();
}

class _EtatPile extends State<PileVolets> {
  late List<String> _pile = [...widget.racine];
  bool _enAvant = true;

  void _pousser(int depuis, String chemin) {
    setState(() {
      _enAvant = true;
      _pile = [..._pile.take(depuis + 1), chemin];
    });
  }

  void _retirer() {
    if (_pile.length <= widget.racine.length) return;
    setState(() {
      _enAvant = false;
      _pile = _pile.sublist(0, _pile.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final debut = (_pile.length - widget.nombre).clamp(0, _pile.length);
    final visibles = _pile.sublist(debut);
    return PopScope(
      canPop: _pile.length <= widget.racine.length,
      onPopInvokedWithResult: (fait, _) {
        if (!fait) _retirer();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (enfant, animation) {
          final entrant = enfant.key == ValueKey(_pile.join('|'));
          final sens = (_enAvant == entrant) ? 1.0 : -1.0;
          return SlideTransition(
            position: Tween(begin: Offset(sens / widget.nombre, 0), end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: enfant),
          );
        },
        layoutBuilder: (actuel, anciens) => Stack(children: [...anciens, ?actuel]),
        child: Row(
          key: ValueKey(_pile.join('|')),
          children: [
            for (var i = 0; i < visibles.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1, color: Color(0x12FFFFFF)),
              Expanded(
                child: VoletScope(
                  index: debut + i,
                  pousser: _pousser,
                  retirer: _retirer,
                  child: KeyedSubtree(key: ValueKey(visibles[i]), child: widget.construire(visibles[i])),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

/// La navigation en volets de l'écran déplié.
///
/// Sur téléphone, toucher une catégorie ouvre une nouvelle page. Sur
/// l'écran déplié, les pages forment une seule grande page dont on montre
/// les deux derniers volets, côte à côte : toucher Shopping pousse tout
/// vers la gauche, la liste prend la place de l'anneau et Shopping s'ouvre
/// à droite, et ainsi de suite jusqu'à une opération. On revient en
/// arrière par le geste retour, sans bouton.
class VoletScope extends InheritedWidget {
  const VoletScope({
    super.key,
    required this.index,
    required this.suivant,
    required this.pousser,
    required this.fermer,
    required super.child,
  });

  /// La place de ce volet dans la pile.
  final int index;

  /// Le chemin ouvert juste à droite de ce volet, s'il y en a un : la
  /// ligne correspondante reste surlignée, pour qu'on voie d'où il vient.
  final String? suivant;

  /// Ouvre [chemin] juste après ce volet, en fermant ce qui suivait.
  final void Function(int depuis, String chemin) pousser;

  /// Referme le volet [index] et ceux qui le suivent.
  final void Function(int index) fermer;

  static VoletScope? de(BuildContext context) => context.dependOnInheritedWidgetOfExactType<VoletScope>();

  @override
  bool updateShouldNotify(VoletScope old) => old.index != index || old.suivant != suivant;
}

/// Vrai si l'on est dans un volet de l'écran déplié.
bool dansUnVolet(BuildContext context) => VoletScope.de(context) != null;

/// Vrai si [chemin] est ouvert dans le volet voisin.
bool estOuvert(BuildContext context, String chemin) => VoletScope.de(context)?.suivant == chemin;

/// De quoi refermer le dernier volet ouvert, ou rien.
///
/// Le geste retour d'Android arrive au navigateur du haut : go_router ne
/// le confie à l'onglet que si celui-ci a une page à dépiler, ce qui
/// n'est jamais le cas des volets. Sans relais, le geste fermait
/// l'application au lieu du volet. La coque écoute cette valeur.
final retourVolet = ValueNotifier<VoidCallback?>(null);

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

/// Revient en arrière : ferme ce volet, ou la page.
void revenir(BuildContext context) {
  final volet = VoletScope.de(context);
  if (volet != null) {
    volet.fermer(volet.index);
  } else if (context.canPop()) {
    context.pop();
  } else {
    context.go('/analyse');
  }
}

/// Montre les [nombre] derniers volets d'une pile de chemins, et fait
/// glisser le tout vers la gauche quand un volet s'ajoute.
class PileVolets extends StatefulWidget {
  const PileVolets({super.key, required this.racine, required this.construire, required this.nombre, this.ouverts = const []});

  /// Les premiers volets, toujours là au fond de la pile.
  final List<String> racine;

  /// Des volets déjà ouverts à l'arrivée : une catégorie touchée sur
  /// l'accueil s'ouvre ici, à côté de la liste.
  final List<String> ouverts;

  /// Le widget d'un chemin.
  final Widget Function(String chemin) construire;
  final int nombre;

  @override
  State<PileVolets> createState() => _EtatPile();
}

class _EtatPile extends State<PileVolets> {
  late List<String> _pile = [...widget.racine, ...widget.ouverts];
  bool _enAvant = true;

  @override
  void initState() {
    super.initState();
    if (widget.ouverts.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _publier());
  }

  void _pousser(int depuis, String chemin) {
    // Toucher la ligne déjà ouverte ne rouvre rien.
    if (depuis + 1 < _pile.length && _pile[depuis + 1] == chemin) return;
    setState(() {
      _enAvant = true;
      _pile = [..._pile.take(depuis + 1), chemin];
    });
    _publier();
  }

  void _retirer() => _fermer(_pile.length - 1);

  void _fermer(int index) {
    if (index < widget.racine.length || index >= _pile.length) return;
    setState(() {
      _enAvant = false;
      _pile = _pile.sublist(0, index);
    });
    _publier();
  }

  void _publier() {
    retourVolet.value = _pile.length > widget.racine.length ? _retirer : null;
  }

  @override
  void dispose() {
    // Après l'image : la coque se reconstruit en écoutant la valeur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (retourVolet.value == _retirer) retourVolet.value = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debut = (_pile.length - widget.nombre).clamp(0, _pile.length);
    final visibles = _pile.sublist(debut);
    return AnimatedSwitcher(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visibles.length; i++) ...[
            if (i > 0) const VerticalDivider(width: 1, color: AppColors.trait),
            Expanded(
              child: VoletScope(
                index: debut + i,
                suivant: debut + i + 1 < _pile.length ? _pile[debut + i + 1] : null,
                pousser: _pousser,
                fermer: _fermer,
                child: KeyedSubtree(key: ValueKey(visibles[i]), child: widget.construire(visibles[i])),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le titre d'un volet : un surtitre discret, toujours présent pour que
/// les titres des volets voisins tombent à la même hauteur, puis le titre.
class TitreVolet extends StatelessWidget {
  const TitreVolet({super.key, required this.titre, this.surtitre, this.droite});

  final String titre;
  final String? surtitre;

  /// Un montant, à droite du titre.
  final Widget? droite;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (surtitre ?? '').toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: AppColors.texteDiscret),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                  ),
                ),
                if (droite != null) ...[const SizedBox(width: 12), droite!],
              ],
            ),
          ],
        ),
      );
}

/// Surligne une ligne dont le détail est ouvert dans le volet voisin.
class Surligne extends StatelessWidget {
  const Surligne({super.key, required this.actif, required this.couleur, required this.child});

  final bool actif;
  final Color couleur;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -10,
            right: -10,
            top: 3,
            bottom: 3,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: actif ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: couleur.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      );
}

/// Le contenu d'une page. Sur téléphone, une liste qui défile. Dans un
/// volet de l'écran déplié, tout doit se voir d'un coup : si la hauteur
/// manque, le contenu se resserre un peu ; s'il faudrait trop le réduire
/// pour rester lisible, il défile.
class Contenu extends StatelessWidget {
  const Contenu({super.key, required this.children, this.tete, this.padding = EdgeInsets.zero, this.ajuster});

  /// L'en-tête, qui ne se resserre jamais : les titres des volets voisins
  /// gardent la même taille et la même hauteur.
  final Widget? tete;

  final List<Widget> children;
  final EdgeInsets padding;

  /// Par défaut, dans un volet seulement.
  final bool? ajuster;

  @override
  Widget build(BuildContext context) {
    if (!(ajuster ?? dansUnVolet(context))) return ListView(padding: padding, children: [?tete, ...children]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?tete,
        Expanded(
          child: LayoutBuilder(
            builder: (context, contraintes) => SingleChildScrollView(
              child: _Ajuste(
                hauteur: contraintes.maxHeight,
                child: Padding(
                  padding: padding,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Ajuste extends SingleChildRenderObjectWidget {
  const _Ajuste({required this.hauteur, required super.child});

  final double hauteur;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenduAjuste(hauteur);

  @override
  void updateRenderObject(BuildContext context, _RenduAjuste renderObject) => renderObject.hauteur = hauteur;
}

/// Pose l'enfant plus large puis le réduit d'autant : il garde toute la
/// largeur et tient dans la hauteur, sans descendre sous [_minimum].
class _RenduAjuste extends RenderProxyBox {
  _RenduAjuste(this._hauteur);

  static const _minimum = 0.8;

  double _hauteur;
  set hauteur(double v) {
    if (v == _hauteur) return;
    _hauteur = v;
    markNeedsLayout();
  }

  double _echelle = 1;

  Matrix4 get _matrice => Matrix4.diagonal3Values(_echelle, _echelle, 1);

  @override
  void performLayout() {
    final enfant = child!;
    final largeur = constraints.maxWidth;
    enfant.layout(BoxConstraints.tightFor(width: largeur), parentUsesSize: true);
    var echelle = 1.0;
    if (_hauteur.isFinite && enfant.size.height > _hauteur) {
      echelle = (_hauteur / enfant.size.height).clamp(_minimum, 1.0);
      // Plus large, le contenu se replie moins et raccourcit encore.
      enfant.layout(BoxConstraints.tightFor(width: largeur / echelle), parentUsesSize: true);
    }
    _echelle = echelle;
    size = constraints.constrain(Size(largeur, enfant.size.height * echelle));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_echelle == 1) {
      layer = null;
      context.paintChild(child!, offset);
      return;
    }
    layer = context.pushTransform(needsCompositing, offset, _matrice, (c, o) => c.paintChild(child!, o), oldLayer: layer as TransformLayer?);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(transform: _matrice, position: position, hitTest: (r, p) => child!.hitTest(r, position: p));

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_matrice);
}

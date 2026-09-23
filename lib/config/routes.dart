import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ecrans/analyse.dart';
import '../ecrans/categorie.dart';
import '../ecrans/epargne.dart';
import '../ecrans/livret.dart';
import '../ecrans/mois.dart';
import '../ecrans/operation.dart';
import '../ecrans/operations.dart';
import '../ecrans/reglages.dart';
import '../ecrans/verifier.dart';
import '../ecrans/verrouillage.dart';
import '../security/lock_state.dart';
import '../widgets/coque.dart';
import '../widgets/volets.dart';
import 'layout.dart';
import 'theme.dart';

/// Le routeur écoute le verrou : dès qu'il se ferme, toute page renvoie à
/// l'écran d'ouverture, et rien d'autre n'est accessible tant qu'il l'est.
final router = GoRouter(
  initialLocation: '/verrou',
  refreshListenable: EtatVerrou.instance,
  redirect: (context, etat) {
    final ouvert = EtatVerrou.instance.isUnlocked;
    final surVerrou = etat.matchedLocation == '/verrou';
    if (!ouvert) return surVerrou ? null : '/verrou';
    if (surVerrou) return '/mois';
    return null;
  },
  routes: [
    GoRoute(path: '/verrou', builder: (_, _) => const EcranVerrouillage()),
    ShellRoute(
      builder: (context, etat, enfant) =>
          Coque(chemin: etat.matchedLocation, child: enfant),
      routes: [
        GoRoute(
          path: '/mois',
          pageBuilder: (_, _) => const NoTransitionPage(child: _VoletsMois()),
        ),
        GoRoute(
          path: '/analyse',
          pageBuilder: (_, etat) =>
              NoTransitionPage(child: _VoletsAnalyse(ouvrir: etat.uri.queryParameters['ouvrir'])),
        ),
        GoRoute(
          path: '/epargne',
          pageBuilder: (_, _) => const NoTransitionPage(child: EcranEpargne()),
        ),
        GoRoute(
          path: '/reglages',
          pageBuilder: (_, _) => const NoTransitionPage(child: EcranReglages()),
        ),
      ],
    ),
    GoRoute(path: '/categories', builder: (_, _) => const _Pleine(EcranCategories())),
    GoRoute(
      path: '/categorie/:id',
      builder: (_, e) => _Pleine(EcranCategorie(id: int.parse(e.pathParameters['id']!))),
    ),
    GoRoute(
      path: '/categorie/:id/nouvelle',
      builder: (_, e) => EcranNouvelleSousCategorie(
        parentId: int.parse(e.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/sous/:id',
      builder: (_, e) =>
          _Pleine(EcranSousCategorie(id: int.parse(e.pathParameters['id']!))),
    ),
    GoRoute(
      path: '/operation/:id',
      builder: (_, e) => _Pleine(EcranOperation(id: int.parse(e.pathParameters['id']!))),
    ),
    GoRoute(
      path: '/operation/:id/lier',
      builder: (_, e) => _Pleine(EcranLier(id: int.parse(e.pathParameters['id']!))),
    ),
    GoRoute(
      path: '/operation/:id/rembourse',
      builder: (_, e) => _Pleine(EcranChoisirRemboursement(id: int.parse(e.pathParameters['id']!))),
    ),
    GoRoute(path: '/operations', builder: (_, _) => const _Pleine(EcranOperations())),
    GoRoute(path: '/verifier', builder: (_, _) => const _Pleine(EcranAVerifier())),
    GoRoute(path: '/livret/nouveau', builder: (_, _) => const EcranNouveauLivret()),
    GoRoute(path: '/internes', builder: (_, _) => const _Pleine(EcranInternes())),
  ],
);

/// Le mois : seul sur téléphone. Sur l'écran déplié, en deux colonnes qui
/// tiennent sans défiler : les comptes à gauche, les dépenses à droite.
class _VoletsMois extends StatelessWidget {
  const _VoletsMois();

  @override
  Widget build(BuildContext context) {
    if (Volets.nombre(context) == 1) return const EcranMois();
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: EcranMois(partie: PartieMois.comptes)),
        VerticalDivider(width: 1, color: AppColors.trait),
        Expanded(child: EcranMois(partie: PartieMois.depenses)),
      ],
    );
  }
}

/// L'analyse : seule sur téléphone. Sur l'écran déplié, l'anneau à gauche
/// et les dépenses à droite ; toucher une catégorie fait glisser le tout
/// vers la gauche et l'ouvre à droite, jusqu'à l'opération.
class _VoletsAnalyse extends StatelessWidget {
  const _VoletsAnalyse({this.ouvrir});

  /// Un volet à ouvrir d'emblée à côté de la liste.
  final String? ouvrir;

  @override
  Widget build(BuildContext context) {
    final n = Volets.nombre(context);
    if (n == 1) return const EcranAnalyse();
    return PileVolets(
      key: ValueKey(ouvrir),
      racine: const ['resume', 'liste'],
      ouverts: [?ouvrir],
      nombre: 2,
      construire: (chemin) {
        final id = int.tryParse(chemin.split('/').last) ?? 0;
        if (chemin == 'resume') {
          return const EcranAnalyse(mode: ModeAnalyse.resume);
        }
        if (chemin == 'liste') {
          return const EcranAnalyse(mode: ModeAnalyse.liste);
        }
        if (chemin.startsWith('/categorie/')) {
          return EcranCategorie(id: id, dansVolet: true);
        }
        if (chemin.startsWith('/sous/')) return EcranSousCategorie(id: id);
        if (chemin.startsWith('/operation/')) return EcranOperation(id: id);
        if (chemin == '/internes') return const EcranInternes();
        if (chemin == '/operations') return const EcranOperations();
        return const SizedBox.shrink();
      },
    );
  }
}

/// Une page ouverte par-dessus les onglets. Sur l'écran déplié, elle garde
/// la largeur d'une colonne, centrée, au lieu de s'étirer d'un bord à
/// l'autre.
class _Pleine extends StatelessWidget {
  const _Pleine(this.page);

  final Widget page;

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isExpanded(context)) return page;
    return ColoredBox(
      color: AppColors.fond,
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: page)),
    );
  }
}

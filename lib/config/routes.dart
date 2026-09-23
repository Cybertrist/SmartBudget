import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ecrans/analyse.dart';
import '../ecrans/categorie.dart';
import '../ecrans/epargne.dart';
import '../ecrans/mois.dart';
import '../ecrans/operation.dart';
import '../ecrans/reglages.dart';
import '../ecrans/verrouillage.dart';
import '../security/lock_state.dart';
import '../widgets/coque.dart';
import 'layout.dart';
import 'theme.dart';

/// La catégorie ouverte dans le volet de droite, sur l'écran déplié.
final categorieVoletProvider = StateProvider<int?>((ref) => null);

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
      builder: (context, etat, enfant) => Coque(chemin: etat.matchedLocation, child: enfant),
      routes: [
        GoRoute(path: '/mois', pageBuilder: (_, _) => const NoTransitionPage(child: _VoletsMois())),
        GoRoute(path: '/analyse', pageBuilder: (_, _) => const NoTransitionPage(child: _VoletsAnalyse())),
        GoRoute(path: '/epargne', pageBuilder: (_, _) => const NoTransitionPage(child: EcranEpargne())),
        GoRoute(path: '/reglages', pageBuilder: (_, _) => const NoTransitionPage(child: EcranReglages())),
      ],
    ),
    GoRoute(path: '/categories', builder: (_, _) => const EcranCategories()),
    GoRoute(path: '/categorie/:id', builder: (_, e) => EcranCategorie(id: int.parse(e.pathParameters['id']!))),
    GoRoute(path: '/categorie/:id/nouvelle', builder: (_, e) => EcranNouvelleSousCategorie(parentId: int.parse(e.pathParameters['id']!))),
    GoRoute(path: '/sous/:id', builder: (_, e) => EcranSousCategorie(id: int.parse(e.pathParameters['id']!))),
    GoRoute(path: '/operation/:id', builder: (_, e) => EcranOperation(id: int.parse(e.pathParameters['id']!))),
    GoRoute(path: '/operation/:id/lier', builder: (_, e) => EcranLier(id: int.parse(e.pathParameters['id']!))),
    GoRoute(path: '/internes', builder: (_, _) => const EcranInternes()),
  ],
);

/// Le mois : seul sur téléphone, à côté de l'analyse sur l'écran déplié.
class _VoletsMois extends StatelessWidget {
  const _VoletsMois();

  @override
  Widget build(BuildContext context) {
    if (Volets.nombre(context) == 1) return const EcranMois();
    return const Row(
      children: [
        Expanded(child: EcranMois(avecSelecteur: false)),
        VerticalDivider(width: 1, color: AppColors.trait),
        Expanded(child: EcranAnalyse()),
      ],
    );
  }
}

/// L'analyse : seule sur téléphone ; sur l'écran déplié, la catégorie
/// touchée s'ouvre à côté.
class _VoletsAnalyse extends ConsumerWidget {
  const _VoletsAnalyse();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Volets.nombre(context) == 1) return const EcranAnalyse();
    final choisie = ref.watch(categorieVoletProvider);
    return Row(
      children: [
        Expanded(child: EcranAnalyse(onCategorie: (id) => ref.read(categorieVoletProvider.notifier).state = id)),
        const VerticalDivider(width: 1, color: AppColors.trait),
        Expanded(
          child: choisie == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Touche une catégorie pour la voir ici.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.texteSecondaire)),
                  ),
                )
              : EcranCategorie(key: ValueKey(choisie), id: choisie, dansVolet: true),
        ),
      ],
    );
  }
}

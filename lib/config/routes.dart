import 'package:go_router/go_router.dart';

import '../ecrans/mois.dart';
import '../ecrans/verrouillage.dart';
import '../security/lock_state.dart';

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
    GoRoute(path: '/mois', builder: (_, _) => const EcranMois()),
  ],
);

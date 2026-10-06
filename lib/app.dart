import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'ecran_accueil/atelier.dart';
import 'ecrans/lancement.dart';
import 'providers/auth_provider.dart';
import 'providers/donnees.dart';
import 'providers/securite.dart';
import 'security/lock_state.dart';

class SmartBudgetApp extends ConsumerStatefulWidget {
  const SmartBudgetApp({super.key});

  @override
  ConsumerState<SmartBudgetApp> createState() => _SmartBudgetAppState();
}

class _SmartBudgetAppState extends ConsumerState<SmartBudgetApp>
    with WidgetsBindingObserver {
  /// Délai avant le reverrouillage, sans geste à l'écran ou en arrière
  /// plan, réglable. Rien ne se referme quand le verrou est coupé.
  Duration get _delai => ref.read(securiteProvider).delai;
  bool get _actif => ref.read(securiteProvider).verrou;

  Timer? _inactivite;

  /// L'état du verrou vu la dernière fois, pour repérer l'ouverture.
  bool _etaitOuvert = EtatVerrou.instance.isUnlocked;

  /// La page demandée par un appui sur un widget de l'écran d'accueil, en
  /// attendant que le verrou s'ouvre.
  String? _pageDemandee;
  StreamSubscription<Uri?>? _liens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EtatVerrou.instance.addListener(_surVerrou);
    _orienter();
    if (Platform.isAndroid && !Platform.environment.containsKey('FLUTTER_TEST')) {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_surWidget).catchError((_) {});
      _liens = HomeWidget.widgetClicked.listen(_surWidget, onError: (_) {});
    }
  }

  void _surWidget(Uri? lien) {
    final chemin = cheminDuLien(lien);
    if (chemin == null) return;
    _pageDemandee = chemin;
    if (EtatVerrou.instance.isUnlocked) _ouvrirPageDemandee();
  }

  /// Un onglet s'ouvre à sa place ; une autre page se pose sur l'accueil,
  /// pour que le geste retour y ramène.
  void _ouvrirPageDemandee() {
    final chemin = _pageDemandee;
    if (chemin == null) return;
    _pageDemandee = null;
    const onglets = ['/mois', '/analyse', '/epargne', '/reglages'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!EtatVerrou.instance.isUnlocked) return;
      if (onglets.contains(chemin)) return router.go(chemin);
      router.go('/mois');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (EtatVerrou.instance.isUnlocked) router.push(chemin);
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Vrai quand l'appli est bloquée en portrait.
  bool? _portrait;

  /// L'écran extérieur du Fold, comme un téléphone, reste en portrait :
  /// couché, il n'a plus la place de rien. L'écran intérieur tourne
  /// librement. On regarde l'écran lui-même, pas la fenêtre, et on
  /// recommence à chaque pliage ou dépliage.
  void _orienter() {
    final ecran = WidgetsBinding.instance.platformDispatcher.views.first.display;
    final etroit = ecran.size.shortestSide / ecran.devicePixelRatio < 600;
    if (etroit == _portrait) return;
    _portrait = etroit;
    SystemChrome.setPreferredOrientations(etroit ? const [DeviceOrientation.portraitUp] : const []);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _orienter();
  }

  @override
  void dispose() {
    EtatVerrou.instance.removeListener(_surVerrou);
    _liens?.cancel();
    _inactivite?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// À chaque ouverture, tous les écrans relisent la base. Une lecture
  /// tentée pendant le verrou, ou au milieu d'un effacement, échoue ; sans
  /// cette relecture, l'erreur restait en mémoire et les pages grises.
  void _surVerrou() {
    final ouvert = EtatVerrou.instance.isUnlocked;
    if (ouvert && !_etaitOuvert) ref.read(versionProvider.notifier).state++;
    _etaitOuvert = ouvert;
    if (ouvert) _ouvrirPageDemandee();
    _relancer();
  }

  /// Repart de zéro à chaque contact avec l'écran.
  void _relancer() {
    _inactivite?.cancel();
    if (!EtatVerrou.instance.isUnlocked || !_actif) return;
    _inactivite = Timer(_delai, () {
      // Une synchronisation en cours repousse le verrou : il se réarme
      // quand la retenue se relâche.
      if (EtatVerrou.instance.retenu) return;
      if (EtatVerrou.instance.isUnlocked) ref.read(authServiceProvider).lock();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final verrou = EtatVerrou.instance;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Le premier départ seulement : en revenant, Android repasse par
        // « hidden » juste avant « resumed », et réécrire l'heure ici
        // remettait le chrono à zéro. L'appli ne se reverrouillait jamais.
        if (verrou.isUnlocked) verrou.pausedAt ??= DateTime.now();
        _inactivite?.cancel();
      case AppLifecycleState.resumed:
        final parti = verrou.pausedAt;
        verrou.pausedAt = null;
        if (!verrou.isUnlocked || parti == null) return;
        if (_actif && !verrou.retenu && DateTime.now().difference(parti) >= _delai) {
          ref.read(authServiceProvider).lock();
        } else {
          _relancer();
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(securiteProvider, (_, _) => _relancer());
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _relancer(),
      child: MaterialApp.router(
        title: 'SmartBudget',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.sombre,
        routerConfig: router,
        // L'animation de lancement se pose par dessus le routeur, le temps
        // qu'elle dure : l'écran d'ouverture est déjà dessous, prêt.
        builder: (context, enfant) => AtelierWidgets(child: _SansClavierFantome(child: Stack(children: [?enfant, const AnimationLancement()]))),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR')],
        locale: const Locale('fr', 'FR'),
      ),
    );
  }
}

/// Le clavier Samsung laisse parfois sa hauteur en mémoire après un verrou
/// ou un passage en arrière-plan, alors qu'il n'est plus à l'écran : la
/// moitié basse de l'accueil restait vide. Sans champ en cours de saisie,
/// il n'y a pas de clavier, quoi qu'en dise Android.
class _SansClavierFantome extends StatefulWidget {
  const _SansClavierFantome({required this.child});

  final Widget child;

  @override
  State<_SansClavierFantome> createState() => _EtatSansClavierFantome();
}

class _EtatSansClavierFantome extends State<_SansClavierFantome> {
  bool _saisie = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_suivre);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_suivre);
    super.dispose();
  }

  /// Le focus change parfois en pleine construction : on attend la fin
  /// de l'image pour redessiner.
  void _suivre() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final saisie = FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<EditableTextState>() != null;
      if (mounted && saisie != _saisie) setState(() => _saisie = saisie);
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (_saisie || mq.viewInsets.bottom == 0) return widget.child;
    return MediaQuery(data: mq.copyWith(viewInsets: mq.viewInsets.copyWith(bottom: 0)), child: widget.child);
  }
}

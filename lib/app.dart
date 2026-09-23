import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'ecrans/lancement.dart';
import 'providers/auth_provider.dart';
import 'security/lock_state.dart';

class SmartBudgetApp extends ConsumerStatefulWidget {
  const SmartBudgetApp({super.key});

  @override
  ConsumerState<SmartBudgetApp> createState() => _SmartBudgetAppState();
}

class _SmartBudgetAppState extends ConsumerState<SmartBudgetApp>
    with WidgetsBindingObserver {
  /// Délai avant le reverrouillage, sans geste à l'écran ou en arrière
  /// plan. Deux minutes : assez pour répondre à un message et revenir,
  /// trop peu pour laisser ses comptes ouverts dans la poche.
  static const _delai = Duration(minutes: 2);

  Timer? _inactivite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EtatVerrou.instance.addListener(_relancer);
  }

  @override
  void dispose() {
    EtatVerrou.instance.removeListener(_relancer);
    _inactivite?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Repart de zéro à chaque contact avec l'écran.
  void _relancer() {
    _inactivite?.cancel();
    if (!EtatVerrou.instance.isUnlocked) return;
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
        if (verrou.isUnlocked) verrou.pausedAt = DateTime.now();
        _inactivite?.cancel();
      case AppLifecycleState.resumed:
        final parti = verrou.pausedAt;
        verrou.pausedAt = null;
        if (!verrou.isUnlocked || parti == null) return;
        if (!verrou.retenu && DateTime.now().difference(parti) >= _delai) {
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
        builder: (context, enfant) => Stack(children: [?enfant, const AnimationLancement()]),
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

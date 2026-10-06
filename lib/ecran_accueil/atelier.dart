import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../config/theme.dart';
import '../providers/donnees.dart';
import '../security/lock_state.dart';
import 'vues.dart';

/// Nom complet d'une classe Android de widget. L'identifiant de la démo
/// change, pas celui des classes.
String classeAndroid(WidgetEcran w) => 'com.cybertrist.smartbudget.${w.classe}';

/// L'atelier des widgets de l'écran d'accueil du téléphone.
///
/// Il dessine chaque widget hors de l'écran avec les composants de
/// l'application, le photographie, et confie la photo à Android. Les photos
/// sont refaites quand l'application s'ouvre, revient au premier plan, ou
/// que ses données changent.
///
/// Une photo est une image en clair, hors de la base chiffrée, que l'écran
/// d'accueil montre sans empreinte : c'est le prix d'un widget. Seuls les
/// widgets réellement posés sont donc photographiés, et la photo d'un
/// widget retiré est effacée. Sans widget, rien ne sort de la base.
class AtelierWidgets extends ConsumerStatefulWidget {
  const AtelierWidgets({super.key, required this.child});

  final Widget child;

  /// Efface toutes les photos : « Tout effacer », dans les réglages.
  static Future<void> toutOublier() async {
    if (!_actif) return;
    for (final w in WidgetEcran.values) {
      await _oublier(w);
    }
  }

  /// Sans effet hors d'Android et pendant les tests automatiques.
  static bool get _actif => Platform.isAndroid && !Platform.environment.containsKey('FLUTTER_TEST');

  static Future<void> _oublier(WidgetEcran w) async {
    try {
      final chemin = await HomeWidget.getWidgetData<String>(w.cle);
      if (chemin == null) return;
      final fichier = File(chemin);
      if (await fichier.exists()) await fichier.delete();
      await HomeWidget.saveWidgetData<String>(w.cle, null);
      await HomeWidget.updateWidget(qualifiedAndroidName: classeAndroid(w));
    } catch (_) {
      // Un widget qui ne se met pas à jour ne doit jamais gêner l'appli.
    }
  }

  @override
  ConsumerState<AtelierWidgets> createState() => _EtatAtelierWidgets();
}

class _EtatAtelierWidgets extends ConsumerState<AtelierWidgets> with WidgetsBindingObserver {
  final _cles = {for (final w in WidgetEcran.values) w: GlobalKey()};
  Timer? _attente;
  String? _empreinte;
  bool _enCours = false;
  bool _aRefaire = false;

  /// Ce qui est en train d'être dessiné (null : rien hors écran).
  Instantane? _donnees;
  Set<WidgetEcran> _poses = const {};

  @override
  void initState() {
    super.initState();
    if (!AtelierWidgets._actif) return;
    WidgetsBinding.instance.addObserver(this);
    EtatVerrou.instance.addListener(_prevoir);
    _prevoir();
  }

  @override
  void dispose() {
    _attente?.cancel();
    if (AtelierWidgets._actif) {
      WidgetsBinding.instance.removeObserver(this);
      EtatVerrou.instance.removeListener(_prevoir);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _prevoir();
  }

  /// Regroupe les changements : on redessine trois secondes après le
  /// dernier.
  void _prevoir() {
    if (!AtelierWidgets._actif) return;
    _attente?.cancel();
    _attente = Timer(const Duration(seconds: 3), _refaire);
  }

  /// Les widgets posés sur l'écran d'accueil. En débogage, tous : c'est de
  /// là que viennent les aperçus du sélecteur de widgets.
  Future<Set<WidgetEcran>> _lirePoses() async {
    if (kDebugMode) return WidgetEcran.values.toSet();
    // Android donne le nom court, « .WidgetBudget », quand la classe est
    // dans le paquet de l'application, et le nom complet pour la démo, dont
    // l'identifiant diffère : on ne compare que la fin.
    final classes = [for (final i in await HomeWidget.getInstalledWidgets()) i.androidClassName ?? ''];
    return {
      for (final w in WidgetEcran.values)
        if (!w.fixe && classes.any((c) => c.endsWith('.${w.classe}'))) w,
    };
  }

  Future<Instantane> _lire() async {
    final mois = ref.read(moisCourantProvider);
    final maintenant = DateTime.now();
    return Instantane(
      mois: mois,
      bilan: await ref.read(bilanProvider(mois).future),
      categories: await ref.read(categoriesProvider.future),
      comptes: await ref.read(comptesProvider.future),
      budget: await ref.read(budgetProvider.future),
      objectif: await ref.read(objectifEpargneProvider.future),
      attendues: passagesAttendus(await ref.read(recurrencesProvider.future), maintenant),
      jour: maintenant,
    );
  }

  Future<void> _refaire() async {
    // Verrouillée, la base est fermée : les photos restent celles de la
    // dernière ouverture.
    if (!mounted || !EtatVerrou.instance.isUnlocked) return;
    if (_enCours) {
      _aRefaire = true;
      return;
    }
    _enCours = true;
    try {
      final poses = await _lirePoses();
      for (final w in WidgetEcran.values.where((w) => !w.fixe && !poses.contains(w))) {
        await AtelierWidgets._oublier(w);
      }
      if (poses.isEmpty || !mounted) return;
      // Le mois en cours dépend du calendrier des salaires.
      await ref.read(calendrierProvider.future);
      final donnees = await _lire();
      final empreinte = '${donnees.empreinte}|${poses.map((w) => w.cle).join(',')}';
      if (empreinte == _empreinte || !mounted) return;
      setState(() {
        _donnees = donnees;
        _poses = poses;
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !EtatVerrou.instance.isUnlocked) return;
      for (final w in poses) {
        final rendu = _cles[w]!.currentContext?.findRenderObject();
        if (rendu is! RenderRepaintBoundary) continue;
        final image = await rendu.toImage(pixelRatio: 3);
        final octets = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (octets == null) continue;
        await HomeWidget.saveFile(w.cle, octets.buffer.asUint8List(), extension: 'png');
        await HomeWidget.updateWidget(qualifiedAndroidName: classeAndroid(w));
      }
      _empreinte = empreinte;
    } catch (_) {
      // Un widget qui ne se met pas à jour ne doit jamais gêner l'appli.
    } finally {
      _enCours = false;
      if (mounted && _donnees != null) setState(() => _donnees = null);
      if (_aRefaire) {
        _aRefaire = false;
        _prevoir();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(versionProvider, (_, _) => _prevoir());
    final donnees = _donnees;
    if (donnees == null) return widget.child;
    return Stack(
      children: [
        widget.child,
        // Hors de l'écran, à gauche : dessiné, jamais vu ni touché.
        Positioned(
          left: -5000,
          top: 0,
          child: ExcludeSemantics(
            child: Material(
              type: MaterialType.transparency,
              textStyle: const TextStyle(fontFamily: AppTheme.police, color: AppColors.texte),
              // À la taille du dessin, quel que soit le réglage de texte du
              // téléphone.
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final w in _poses) RepaintBoundary(key: _cles[w], child: vueEcran(w, donnees)),
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

/// La page de l'application que demande un appui sur un widget
/// (`sbwidget://ouvrir?chemin=/epargne`), ou null.
String? cheminDuLien(Uri? lien) {
  if (lien == null || lien.scheme != 'sbwidget') return null;
  final chemin = lien.queryParameters['chemin'];
  return chemin == null || !chemin.startsWith('/') ? null : chemin;
}

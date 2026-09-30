import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/bilan.dart';
import '../domaine/modeles.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import 'categorie.dart';
import 'epargne.dart';

/// Toutes les opérations, de tous les temps, jour par jour. Ouvertes
/// depuis l'anneau de l'analyse, seulement les entrées ou les sorties de
/// sa période. Sur l'écran déplié, elles occupent le volet à côté du mois.
class EcranOperations extends ConsumerStatefulWidget {
  const EcranOperations({super.key, this.dansVolet = false, this.genre});

  final bool dansVolet;

  /// Seulement les entrées, ou seulement les sorties, telles que l'analyse
  /// les compte : ouvertes depuis le centre de son anneau.
  final Genre? genre;

  @override
  ConsumerState<EcranOperations> createState() => _EtatOperations();
}

class _EtatOperations extends ConsumerState<EcranOperations> {
  final _cherche = TextEditingController();
  String _texte = '';

  /// Les derniers résultats affichés : ils restent pendant qu'une nouvelle
  /// recherche se charge. Remplacer la page par une roue de chargement
  /// retirait le champ de l'écran, et le clavier se fermait en pleine
  /// frappe.
  List<Operation> _derniers = const [];

  @override
  void dispose() {
    _cherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dansVolet = widget.dansVolet;
    // Sans filtre, tout, depuis la première opération. Les entrées ou les
    // sorties de l'anneau suivent la période de l'analyse. Une recherche
    // fouille tout.
    final recherche = _texte.trim().length >= 2;
    final ops = recherche
        ? ref.watch(rechercheProvider(_texte))
        : widget.genre == null
            ? ref.watch(toutesOperationsProvider)
            : ref.watch(operationsPeriodeProvider);
    final periode = ref.watch(libellePeriodeProvider);
    final categories = ref.watch(categoriesProvider);
    if (!categories.hasValue) return const Center(child: CircularProgressIndicator());
    final cats = categories.value!;
    final genre = widget.genre;
    final poids = genre == null ? const <int, int>{} : (ref.watch(poidsPeriodeProvider).value ?? const <int, int>{});
    int net(Operation o) => poids[o.id] ?? o.montantCentimes;
    if (ops.hasValue) {
      _derniers = genre == null ? ops.value! : ops.value!.where((o) => compteDans(genre, o, cats) && net(o) != 0).toList();
    }

    final jours = <DateTime, List<Operation>>{};
    for (final o in _derniers) {
      jours.putIfAbsent(DateTime(o.le.year, o.le.month, o.le.day), () => []).add(o);
    }

    final entetes = <Widget>[
        EnTetePage(surtitre: genre == null ? 'Toutes les opérations' : (recherche ? 'Recherche dans toutes les opérations' : periode), titre: switch (genre) {
          Genre.revenu => 'Entrées',
          Genre.depense => 'Sorties',
          _ => 'Opérations',
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cherche,
                  onChanged: (t) => setState(() => _texte = t),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Chercher un nom, une note, un montant',
                    prefixIcon: Icon(iconeDe('search'), color: AppColors.texteSecondaire),
                    suffixIcon: _texte.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(iconeDe('close'), color: AppColors.texteSecondaire),
                            onPressed: () => setState(() {
                              _cherche.clear();
                              _texte = '';
                            }),
                          ),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28)), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Une dépense payée en espèces, que la banque ne voit pas.
              Material(
                color: AppColors.vert.withValues(alpha: 0.1),
                shape: StadiumBorder(side: BorderSide(color: AppColors.vert.withValues(alpha: 0.35))),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => context.push('/especes/nouvelle'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconeDe('add'), size: 18, color: AppColors.vert),
                        const SizedBox(width: 6),
                        const Text('Espèces', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.vert)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Les résultats d'avant restent affichés pendant que la recherche se
        // charge : une barre le dit, et une erreur ne passe pas en silence.
        if (ops.isLoading)
          const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 14), child: LinearProgressIndicator(minHeight: 2)),
        if (ops.hasError && !ops.isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Text('Recherche impossible : ${ops.error}', style: const TextStyle(color: AppColors.alerte)),
          ),
        if (jours.isEmpty && ops.hasValue && !ops.isLoading)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(recherche ? 'Rien ne correspond à « ${_texte.trim()} ».' : genre == null ? 'Aucune opération.' : 'Aucune opération sur la période.',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.texteSecondaire)),
          ),
    ];
    // Des centaines de jours sur des années : chacun ne se construit
    // qu'au moment d'apparaître.
    final parJour = jours.entries.toList();
    Widget unJour(MapEntry<DateTime, List<Operation>> e) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(jour(e.key), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire))),
                      Montant(e.value.where((o) => o.interne == null).fold(0, (s, o) => s + net(o)), taille: 13, couleur: AppColors.texteDiscret, signe: true),
                    ],
                  ),
                ),
                Carte(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < e.value.length; i++)
                        if (e.value[i].interne != null)
                          LigneVirement(operation: e.value[i], separateur: i > 0)
                        else
                          Builder(builder: (_) {
                            final o = e.value[i];
                            final c = cats[o.categorieId]!;
                            final p = c.parentId == null ? c : cats[c.parentId]!;
                            return LigneOperation(operation: o, icone: c.icone ?? p.icone, couleur: Color(p.couleur), separateur: i > 0, net: genre == null ? null : net(o));
                          }),
                    ],
                  ),
                ),
              ],
            ),
          );
    final liste = ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: entetes.length + parJour.length,
      itemBuilder: (_, i) => i < entetes.length ? entetes[i] : unJour(parJour[i - entetes.length]),
    );
    return dansVolet ? SafeArea(child: liste) : Scaffold(body: SafeArea(child: liste));
  }
}

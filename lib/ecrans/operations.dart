import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/modeles.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import 'categorie.dart';
import 'epargne.dart';

/// Toutes les opérations du mois, jour par jour. Sur l'écran déplié, elles
/// occupent le volet à côté du mois : ce que l'accueil ne montre pas déjà.
class EcranOperations extends ConsumerStatefulWidget {
  const EcranOperations({super.key, this.dansVolet = false});

  final bool dansVolet;

  @override
  ConsumerState<EcranOperations> createState() => _EtatOperations();
}

class _EtatOperations extends ConsumerState<EcranOperations> {
  final _cherche = TextEditingController();
  String _texte = '';

  @override
  void dispose() {
    _cherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dansVolet = widget.dansVolet;
    // Toute la période choisie dans l'analyse : sur un an, la liste
    // remonte les douze mois. Une recherche, elle, fouille tout.
    final recherche = _texte.trim().length >= 2;
    final ops = recherche ? ref.watch(rechercheProvider(_texte)) : ref.watch(operationsPeriodeProvider);
    final periode = ref.watch(libellePeriodeProvider);
    final categories = ref.watch(categoriesProvider);
    if (!ops.hasValue || !categories.hasValue) return const Center(child: CircularProgressIndicator());
    final cats = categories.value!;

    final jours = <DateTime, List<Operation>>{};
    for (final o in ops.value!) {
      jours.putIfAbsent(DateTime(o.le.year, o.le.month, o.le.day), () => []).add(o);
    }

    final liste = ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        EnTetePage(surtitre: recherche ? 'Toutes les opérations' : periode, titre: 'Opérations'),
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
        if (jours.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(recherche ? 'Rien ne correspond à « ${_texte.trim()} ».' : 'Aucune opération sur la période.',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.texteSecondaire)),
          ),
        for (final e in jours.entries)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(jour(e.key), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire))),
                      Montant(e.value.where((o) => o.interne == null).fold(0, (s, o) => s + o.montantCentimes), taille: 13, couleur: AppColors.texteDiscret, signe: true),
                    ],
                  ),
                ),
                Carte(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < e.value.length; i++)
                        if (e.value[i].interne != null)
                          LigneVirement(operation: e.value[i])
                        else
                          Builder(builder: (_) {
                            final o = e.value[i];
                            final c = cats[o.categorieId]!;
                            final p = c.parentId == null ? c : cats[c.parentId]!;
                            return LigneOperation(operation: o, icone: c.icone ?? p.icone, couleur: Color(p.couleur), separateur: i > 0);
                          }),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return dansVolet ? SafeArea(child: liste) : Scaffold(body: SafeArea(child: liste));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/modeles.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import 'categorie.dart';
import 'epargne.dart';

/// Toutes les opérations du mois, jour par jour. Sur l'écran déplié, elles
/// occupent le volet à côté du mois : ce que l'accueil ne montre pas déjà.
class EcranOperations extends ConsumerWidget {
  const EcranOperations({super.key, this.dansVolet = false});

  final bool dansVolet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Toute la période choisie dans l'analyse : sur un an, la liste
    // remonte les douze mois.
    final ops = ref.watch(operationsPeriodeProvider);
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
        EnTetePage(surtitre: periode, titre: 'Opérations'),
        if (jours.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Text('Aucune opération sur la période.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.texteSecondaire))),
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

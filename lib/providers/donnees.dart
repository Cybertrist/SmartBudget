import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domaine/bilan.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../domaine/recurrences.dart';
import '../donnees/depots.dart';

/// Monte à chaque écriture : tout ce qui lit la base se relit.
final versionProvider = StateProvider<int>((ref) => 0);

/// Après une modification : les écrans relisent la base.
void rafraichir(WidgetRef ref) => ref.read(versionProvider.notifier).state++;

/// Le mois affiché, partagé par tous les écrans.
final moisProvider = StateProvider<Mois>((ref) => Mois.de(DateTime.now()));

/// Un mois, trois mois ou un an, pour l'analyse.
enum Periode { mois, trimestre, annee }

final periodeProvider = StateProvider<Periode>((ref) => Periode.mois);

final categoriesProvider = FutureProvider<Map<int, Categorie>>((ref) async {
  ref.watch(versionProvider);
  return const DepotCategories().parId();
});

final bilanProvider = FutureProvider.family<Bilan, Mois>((ref, mois) async {
  ref.watch(versionProvider);
  return const DepotBilan().du(mois);
});

/// Le bilan de la période choisie, qui se termine au mois affiché.
final bilanPeriodeProvider = FutureProvider<Bilan>((ref) async {
  final mois = ref.watch(moisProvider);
  final periode = ref.watch(periodeProvider);
  final n = switch (periode) {
    Periode.mois => 1,
    Periode.trimestre => 3,
    Periode.annee => 12,
  };
  var m = mois;
  final bilans = <Bilan>[];
  for (var i = 0; i < n; i++) {
    bilans.add(await ref.watch(bilanProvider(m).future));
    m = m.precedent;
  }
  return fusionner(mois, bilans);
});

final operationsMoisProvider = FutureProvider.family<List<Operation>, Mois>((ref, mois) async {
  ref.watch(versionProvider);
  final debut = await const DepotReglages().debutMois();
  return const DepotOperations().duMois(mois, debut: debut);
});

final operationProvider = FutureProvider.family<Operation?, int>((ref, id) async {
  ref.watch(versionProvider);
  return const DepotOperations().une(id);
});

final comptesProvider = FutureProvider<List<Compte>>((ref) async {
  ref.watch(versionProvider);
  await const DepotComptes().courant();
  return const DepotComptes().tous();
});

final recurrencesProvider = FutureProvider<List<Recurrence>>((ref) async {
  ref.watch(versionProvider);
  return const DepotOperations().recurrences();
});

final liensProvider = FutureProvider.family<List<Lien>, int>((ref, id) async {
  ref.watch(versionProvider);
  return const DepotLiens().concernant([id]);
});

/// Le budget mensuel, en centimes, 0 s'il n'est pas fixé.
final budgetProvider = FutureProvider<int>((ref) async {
  ref.watch(versionProvider);
  return int.tryParse(await const DepotReglages().lire('budget') ?? '') ?? 0;
});

final objectifEpargneProvider = FutureProvider<int>((ref) async {
  ref.watch(versionProvider);
  return int.tryParse(await const DepotReglages().lire('objectif_epargne') ?? '') ?? 0;
});

/// Additionne plusieurs bilans mensuels en un seul.
Bilan fusionner(Mois mois, List<Bilan> bilans) {
  final b = Bilan(mois);
  for (final x in bilans) {
    b.sorties += x.sorties;
    b.entrees += x.entrees;
    b.essentiel += x.essentiel;
    b.plaisir += x.plaisir;
    b.imprevu += x.imprevu;
    b.misDeCote += x.misDeCote;
    b.pioche += x.pioche;
    b.virementsInternes += x.virementsInternes;
    void somme(Map<int, int> a, Map<int, int> de) => de.forEach((k, v) => a.update(k, (w) => w + v, ifAbsent: () => v));
    somme(b.parCategorie, x.parCategorie);
    somme(b.operationsParCategorie, x.operationsParCategorie);
    somme(b.parSous, x.parSous);
    somme(b.operationsParSous, x.operationsParSous);
  }
  return b;
}

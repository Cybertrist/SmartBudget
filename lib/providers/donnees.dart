import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/format.dart';
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
  final liste = ref.watch(moisPeriodeProvider);
  final bilans = <Bilan>[];
  for (final m in liste) {
    bilans.add(await ref.watch(bilanProvider(m).future));
  }
  return fusionner(liste.first, bilans);
});

final operationsMoisProvider = FutureProvider.family<List<Operation>, Mois>((ref, mois) async {
  ref.watch(versionProvider);
  final debut = await const DepotReglages().debutMois();
  return const DepotOperations().duMois(mois, debut: debut);
});

/// Les mois de la période choisie, du plus récent au plus ancien.
final moisPeriodeProvider = Provider<List<Mois>>((ref) {
  final n = switch (ref.watch(periodeProvider)) {
    Periode.mois => 1,
    Periode.trimestre => 3,
    Periode.annee => 12,
  };
  var m = ref.watch(moisProvider);
  final liste = <Mois>[];
  for (var i = 0; i < n; i++) {
    liste.add(m);
    m = m.precedent;
  }
  return liste;
});

/// Toutes les opérations de la période choisie, les plus récentes d'abord :
/// sur un an, la liste remonte les douze mois.
final operationsPeriodeProvider = FutureProvider<List<Operation>>((ref) async {
  final tous = <Operation>[];
  for (final m in ref.watch(moisPeriodeProvider)) {
    tous.addAll(await ref.watch(operationsMoisProvider(m).future));
  }
  return tous;
});

/// La période en toutes lettres : « septembre 2026 », « 3 mois jusqu'à
/// septembre », « 12 mois jusqu'à septembre ».
final libellePeriodeProvider = Provider<String>((ref) {
  final mois = ref.watch(moisProvider);
  return switch (ref.watch(periodeProvider)) {
    Periode.mois => nomMois(mois),
    Periode.trimestre => "3 mois jusqu'à ${nomMoisSeul(mois).toLowerCase()}",
    Periode.annee => "12 mois jusqu'à ${nomMoisSeul(mois).toLowerCase()}",
  };
});

final operationProvider = FutureProvider.family<Operation?, int>((ref, id) async {
  ref.watch(versionProvider);
  return const DepotOperations().une(id);
});

final comptesProvider = FutureProvider<List<Compte>>((ref) async {
  ref.watch(versionProvider);
  const depot = DepotComptes();
  await depot.courant();
  return [
    for (final c in await depot.tous())
      if (c.nature == NatureCompte.portefeuille)
        Compte(id: c.id, nature: c.nature, nom: c.nom, soldeCentimes: await depot.soldePortefeuille(c), soldeLe: c.soldeLe)
      else
        c,
  ];
});

final recurrencesProvider = FutureProvider<List<Recurrence>>((ref) async {
  ref.watch(versionProvider);
  return const DepotOperations().recurrences();
});

/// Le résultat d'une recherche dans toutes les opérations.
final rechercheProvider = FutureProvider.family<List<Operation>, String>((ref, texte) async {
  ref.watch(versionProvider);
  final t = texte.trim();
  final v = double.tryParse(t.replaceAll(RegExp(r'[\s €]'), '').replaceAll(',', '.'));
  return const DepotOperations().chercher(t, centimes: v == null ? null : (v * 100).round());
});

/// Les opérations non reconnues, à vérifier.
final aVerifierProvider = FutureProvider<List<Operation>>((ref) async {
  ref.watch(versionProvider);
  return const DepotOperations().aVerifier();
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

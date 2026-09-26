import 'classement.dart';
import 'modeles.dart';
import 'mois.dart';
import 'virements.dart';

/// Ce qu'un mois a coûté et rapporté, catégorie par catégorie.
///
/// Trois règles le distinguent d'une simple somme :
/// - un virement interne ne compte ni en dépense ni en revenu, il alimente
///   seulement le suivi de l'épargne ;
/// - une entrée qui rembourse des dépenses ne compte pas comme un revenu
///   pour la part liée : cette part vient en déduction des dépenses
///   qu'elle rembourse, qui ne comptent plus que pour leur reste à charge ;
/// - une entrée rangée dans « Remboursements » (la mutuelle, un ami qui
///   rend sa part) n'est pas un revenu non plus, même sans lien : elle
///   est comptée à part ;
/// - une opération masquée ne compte nulle part.
class Bilan {
  Bilan(this.mois);

  final Mois mois;

  /// Total des sorties, positif.
  int sorties = 0;

  /// Total des entrées, hors remboursements liés.
  int entrees = 0;

  /// Les remboursements reçus, laissés hors des entrées.
  int rembourses = 0;

  /// Par catégorie de premier niveau : le montant (positif pour une
  /// dépense nette) et le nombre d'opérations.
  final Map<int, int> parCategorie = {};
  final Map<int, int> operationsParCategorie = {};

  /// Même chose par sous-catégorie.
  final Map<int, int> parSous = {};
  final Map<int, int> operationsParSous = {};

  int essentiel = 0;
  int plaisir = 0;
  int imprevu = 0;

  /// Virements internes du mois.
  int misDeCote = 0;
  int pioche = 0;
  int virementsInternes = 0;

  int get epargneNette => misDeCote - pioche;
  int get solde => entrees - sorties;
}

/// Calcule le bilan de [mois].
///
/// [operations] contient celles du mois, et aussi toute dépense d'un autre
/// mois qu'une entrée de celui-ci rembourse, et inversement : [liens] les
/// relie. [categories] donne pour chaque identifiant sa catégorie.
Bilan calculerBilan({
  required Mois mois,
  required List<Operation> operations,
  required List<Lien> liens,
  required Map<int, Categorie> categories,
  int debut = 1,
  Map<int, int>? retraitsDepenses,
}) {
  final bilan = Bilan(mois);
  final parId = {for (final o in operations) o.id: o};

  Mois moisDe(Operation o) =>
      o.moisCompte != null ? Mois.lire(o.moisCompte!) : Mois.de(o.le, debut: debut);

  Categorie? racine(int id) {
    final c = categories[id];
    if (c == null) return null;
    return c.parentId == null ? c : categories[c.parentId];
  }

  // Un virement entre ses comptes ne rembourse rien et n'est pas remboursé.
  bool interne(Operation? o) => o != null && (o.interne != null || racine(o.categorieId)?.genre == Genre.interne);

  // Ce que chaque opération pèse une fois les remboursements répartis.
  // Une dépense ne reçoit jamais plus que son montant, même si d'anciens
  // liens le dépassaient : elle deviendrait un gain.
  final poids = <int, int>{for (final o in operations) o.id: o.montantCentimes};
  final recu = <int, int>{};
  for (final l in liens) {
    final entree = parId[l.entreeId];
    final depense = parId[l.depenseId];
    // Une entrée masquée ne compte nulle part : elle ne rembourse rien.
    if (interne(entree) || interne(depense) || (entree?.masquee ?? false)) continue;
    var m = l.montantCentimes;
    if (depense != null) {
      final libre = -depense.montantCentimes - (recu[depense.id] ?? 0);
      m = m.clamp(0, libre < 0 ? 0 : libre);
      recu[depense.id] = (recu[depense.id] ?? 0) + m;
    }
    if (entree != null) poids[entree.id] = poids[entree.id]! - m;
    if (depense != null) poids[depense.id] = poids[depense.id]! + m;
  }

  // Les retraits au distributeur, et ce qui a été dépensé en espèces.
  var especes = 0;
  final retraits = <(Categorie top, Categorie cat, Nature nature), int>{};

  for (final o in operations) {
    if (o.masquee || moisDe(o) != mois) continue;
    final cat = categories[o.categorieId];
    final top = racine(o.categorieId);
    if (cat == null || top == null) continue;

    if (top.genre == Genre.interne) {
      final m = o.montantCentimes.abs();
      bilan.virementsInternes += m;
      // Le sens, ou à défaut celui de sa sous-catégorie, s'il a été rangé
      // là à la main.
      final sens = o.interne ?? SensInterne.values.where((s) => sousCategorieInterne(s) == cat.nom).firstOrNull;
      if (sens == SensInterne.versEpargne) bilan.misDeCote += m;
      if (sens == SensInterne.depuisEpargne) bilan.pioche += m;
      continue;
    }

    final p = poids[o.id]!;
    if (p == 0) continue;

    if (top.genre == Genre.revenu) {
      if (estRemboursement(cat, top)) {
        bilan.rembourses += p;
        bilan.parSous.update(cat.id, (v) => v + p, ifAbsent: () => p);
        bilan.operationsParSous.update(cat.id, (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      bilan.entrees += p;
      _ajouter(bilan, top, cat, p, o);
      continue;
    }

    if (top.genre == Genre.epargne) {
      bilan.misDeCote += -p;
      continue;
    }

    // Une dépense : positive quand l'argent sort. Un remboursement
    // marchand, positif, vient en déduction de sa catégorie.
    final d = -p;
    bilan.sorties += d;
    _ajouter(bilan, top, cat, d, o);
    final nature = o.nature ?? cat.nature;
    if (o.especes) especes += d;
    if (cat.nom == "Retraits d'espèces" && d > 0) {
      // Avec [retraitsDepenses], chaque retrait sait ce qui en a été
      // dépensé en espèces, ce mois-ci ou un autre ; sinon, on compense
      // dans le mois seulement.
      final x = retraitsDepenses == null ? d : (retraitsDepenses[o.id] ?? 0).clamp(0, d);
      if (x > 0) retraits.update((top, cat, nature), (v) => v + x, ifAbsent: () => x);
    }
    switch (nature) {
      case Nature.essentiel:
        bilan.essentiel += d;
      case Nature.plaisir:
        bilan.plaisir += d;
      case Nature.imprevu:
        bilan.imprevu += d;
    }
  }

  // L'argent retiré puis dépensé en espèces : la dépense compte, le retrait
  // n'est plus qu'un passage du compte au porte-monnaie.
  var aDeduire = retraitsDepenses == null ? especes : retraits.values.fold<int>(0, (s, v) => s + v);
  for (final e in retraits.entries) {
    if (aDeduire <= 0) break;
    final x = e.value < aDeduire ? e.value : aDeduire;
    aDeduire -= x;
    final (top, cat, nature) = e.key;
    bilan.sorties -= x;
    bilan.parCategorie[top.id] = (bilan.parCategorie[top.id] ?? 0) - x;
    if (cat.id != top.id) bilan.parSous[cat.id] = (bilan.parSous[cat.id] ?? 0) - x;
    switch (nature) {
      case Nature.essentiel:
        bilan.essentiel -= x;
      case Nature.plaisir:
        bilan.plaisir -= x;
      case Nature.imprevu:
        bilan.imprevu -= x;
    }
  }
  return bilan;
}

void _ajouter(Bilan b, Categorie top, Categorie cat, int montant, Operation o) {
  b.parCategorie.update(top.id, (v) => v + montant, ifAbsent: () => montant);
  b.operationsParCategorie.update(top.id, (v) => v + 1, ifAbsent: () => 1);
  if (cat.parentId != null) {
    b.parSous.update(cat.id, (v) => v + montant, ifAbsent: () => montant);
    b.operationsParSous.update(cat.id, (v) => v + 1, ifAbsent: () => 1);
  }
}

/// Le poids net de chaque opération de [operations], remboursements
/// répartis, avec les mêmes règles que le bilan.
Map<int, int> poidsNets(List<Operation> operations, List<Lien> liens) {
  final parId = {for (final o in operations) o.id: o};
  final poids = <int, int>{for (final o in operations) o.id: o.montantCentimes};
  final recu = <int, int>{};
  bool interne(Operation? o) => o != null && o.interne != null;
  for (final l in liens) {
    final entree = parId[l.entreeId];
    final depense = parId[l.depenseId];
    if (interne(entree) || interne(depense) || (entree?.masquee ?? false)) continue;
    var m = l.montantCentimes;
    if (depense != null) {
      final libre = -depense.montantCentimes - (recu[depense.id] ?? 0);
      m = m.clamp(0, libre < 0 ? 0 : libre);
      recu[depense.id] = (recu[depense.id] ?? 0) + m;
    }
    if (entree != null) poids[entree.id] = poids[entree.id]! - m;
    if (depense != null) poids[depense.id] = poids[depense.id]! + m;
  }
  return poids;
}

/// Ce que chaque retrait au distributeur a financé en espèces : chaque
/// dépense en espèces puise dans le plus ancien retrait qui la précède, de
/// deux mois au plus. Retirer 50 € en septembre puis payer 20 € au marché
/// en octobre : le retrait ne compte plus que 30 €, les courses 20 €, et
/// les 50 € ne sont comptés qu'une fois.
Map<int, int> financementEspeces(List<Operation> retraits, List<Operation> especes) {
  final file = [...retraits]..sort((a, b) => a.le.compareTo(b.le));
  final reste = {for (final r in file) r.id: -r.montantCentimes};
  final pris = <int, int>{};
  for (final e in [...especes]..sort((a, b) => a.le.compareTo(b.le))) {
    var besoin = -e.montantCentimes;
    for (final r in file) {
      if (besoin <= 0) break;
      if (r.le.isAfter(e.le) || e.le.difference(r.le).inDays > 62) continue;
      final x = reste[r.id]! < besoin ? reste[r.id]! : besoin;
      if (x <= 0) continue;
      reste[r.id] = reste[r.id]! - x;
      pris[r.id] = (pris[r.id] ?? 0) + x;
      besoin -= x;
    }
  }
  return pris;
}

/// La sous-catégorie des remboursements : de l'argent qui revient, pas un
/// revenu.
bool estRemboursement(Categorie cat, Categorie top) => top.genre == Genre.revenu && cat.nom == 'Remboursements';

/// Ce que l'analyse compte parmi les entrées ([Genre.revenu]) ou les
/// sorties ([Genre.depense]) : la liste des opérations suit le même tri
/// que l'anneau.
bool compteDans(Genre genre, Operation o, Map<int, Categorie> categories) {
  if (o.masquee || o.interne != null) return false;
  final cat = categories[o.categorieId];
  if (cat == null) return false;
  final top = cat.parentId == null ? cat : categories[cat.parentId];
  if (top == null || top.genre != genre) return false;
  return !estRemboursement(cat, top);
}

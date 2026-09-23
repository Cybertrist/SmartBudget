import 'libelle.dart';

/// Ce qui revient tout seul : loyer, abonnements, forfait, salle de sport.
///
/// Rien n'est saisi : les récurrences se déduisent des opérations. Un même
/// marchand, un montant qui ne bouge presque pas, et un écart régulier
/// entre deux passages, d'une semaine, d'un mois ou d'un an.
enum Frequence {
  hebdomadaire('Chaque semaine'),
  mensuelle('Chaque mois'),
  trimestrielle('Chaque trimestre'),
  annuelle('Chaque année');

  const Frequence(this.libelle);

  final String libelle;
}

/// Le passage suivant, une fréquence après [d].
DateTime suivante(DateTime d, Frequence f) => switch (f) {
      Frequence.hebdomadaire => d.add(const Duration(days: 7)),
      Frequence.mensuelle => DateTime(d.year, d.month + 1, d.day),
      Frequence.trimestrielle => DateTime(d.year, d.month + 3, d.day),
      Frequence.annuelle => DateTime(d.year + 1, d.month, d.day),
    };

class Recurrence {
  const Recurrence({
    required this.cle,
    required this.libelle,
    required this.montantCentimes,
    required this.frequence,
    required this.derniere,
    required this.prochaine,
    required this.nombre,
    this.derniereId,
  });

  final String cle;
  final String libelle;

  /// Le montant habituel, la médiane des passages.
  final int montantCentimes;
  final Frequence frequence;
  final DateTime derniere;
  final DateTime prochaine;

  /// Combien de passages l'ont fait reconnaître.
  final int nombre;

  /// La dernière opération passée, qu'on ouvre en touchant la récurrence.
  final int? derniereId;

  /// Attendue depuis plus de [grace] jours sans être passée.
  bool enRetard(DateTime maintenant, {int grace = 4}) =>
      maintenant.isAfter(prochaine.add(Duration(days: grace)));

  /// Nombre de jours avant le prochain passage, négatif s'il est dépassé.
  int dansJours(DateTime maintenant) =>
      DateTime(prochaine.year, prochaine.month, prochaine.day)
          .difference(DateTime(maintenant.year, maintenant.month, maintenant.day))
          .inDays;
}

/// Une opération vue par la détection : juste ce qu'il lui faut.
class Passage {
  const Passage(this.libelle, this.le, this.montantCentimes, [this.id]);

  final String libelle;
  final DateTime le;
  final int montantCentimes;

  /// L'opération d'où vient le passage, pour l'ouvrir.
  final int? id;
}

/// Les récurrences de sorties trouvées dans une liste d'opérations.
///
/// Il faut au moins deux passages, et que chaque écart tombe dans la
/// fenêtre de sa fréquence : de 25 à 35 jours pour un mois. Le montant
/// peut varier de 15 % autour de sa médiane, pour un forfait qui change
/// d'un euro ou une facture d'électricité lissée.
List<Recurrence> detecterRecurrences(List<Passage> passages) {
  final groupes = <String, List<Passage>>{};
  for (final p in passages) {
    if (p.montantCentimes >= 0) continue;
    groupes.putIfAbsent(cleMarchand(p.libelle), () => []).add(p);
  }

  final trouvees = <Recurrence>[];
  groupes.forEach((cle, liste) {
    if (liste.length < 2) return;
    liste.sort((a, b) => a.le.compareTo(b.le));

    final montants = liste.map((p) => p.montantCentimes).toList()..sort();
    final mediane = montants[montants.length ~/ 2];
    final stables = liste
        .where((p) => (p.montantCentimes - mediane).abs() <= (mediane.abs() * 0.15).round())
        .toList();
    if (stables.length < 2) return;

    final ecarts = <int>[];
    for (var i = 1; i < stables.length; i++) {
      ecarts.add(stables[i].le.difference(stables[i - 1].le).inDays);
    }
    final freq = _frequence(ecarts);
    if (freq == null) return;

    final derniere = stables.last.le;
    final prochaine = suivante(derniere, freq);
    trouvees.add(Recurrence(
      cle: cle,
      libelle: joli(stables.last.libelle),
      montantCentimes: mediane,
      frequence: freq,
      derniere: derniere,
      prochaine: prochaine,
      nombre: stables.length,
      derniereId: stables.last.id,
    ));
  });
  trouvees.sort((a, b) => a.prochaine.compareTo(b.prochaine));
  return trouvees;
}

Frequence? _frequence(List<int> ecarts) {
  bool tous(int min, int max) => ecarts.every((e) => e >= min && e <= max);
  if (tous(6, 8)) return Frequence.hebdomadaire;
  if (tous(25, 35)) return Frequence.mensuelle;
  if (tous(85, 95)) return Frequence.trimestrielle;
  if (tous(350, 380)) return Frequence.annuelle;
  return null;
}

/// Applique les choix faits à la main, marchand par marchand : une
/// fréquence imposée, même si la détection n'a rien vu, ou aucune
/// (`null`), même si elle a cru voir quelque chose.
List<Recurrence> appliquerChoix(List<Recurrence> trouvees, List<Passage> passages, Map<String, Frequence?> choix) {
  final resultat = [for (final r in trouvees) if (!choix.containsKey(r.cle)) r];
  choix.forEach((cle, freq) {
    if (freq == null) return;
    final liste = passages.where((p) => p.montantCentimes < 0 && cleMarchand(p.libelle) == cle).toList()
      ..sort((a, b) => a.le.compareTo(b.le));
    if (liste.isEmpty) return;
    final montants = liste.map((p) => p.montantCentimes).toList()..sort();
    final derniere = liste.last.le;
    resultat.add(Recurrence(
      cle: cle,
      libelle: joli(liste.last.libelle),
      montantCentimes: montants[montants.length ~/ 2],
      frequence: freq,
      derniere: derniere,
      prochaine: suivante(derniere, freq),
      nombre: liste.length,
      derniereId: liste.last.id,
    ));
  });
  resultat.sort((a, b) => a.prochaine.compareTo(b.prochaine));
  return resultat;
}

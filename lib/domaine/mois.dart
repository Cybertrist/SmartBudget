/// Un mois budgétaire.
///
/// Le mois ne commence pas forcément le 1er : quand le salaire tombe le 28,
/// c'est de là que part le budget. Avec un début au 28, une dépense du
/// 29 septembre compte dans octobre. Un mois qui commence dans la première
/// quinzaine porte au contraire le nom du mois où il commence : avec un
/// début au 3, le 3 octobre ouvre octobre. [debut] vaut 1 pour un mois
/// civil.
class Mois implements Comparable<Mois> {
  const Mois(this.annee, this.mois);

  final int annee;
  final int mois;

  /// Le mois auquel une date appartient.
  factory Mois.de(DateTime date, {int debut = 1}) {
    if (debut <= 1) return Mois(date.year, date.month);
    // Le mois civil où la période a commencé, puis son nom.
    final depart = DateTime(date.year, date.month - (date.day >= debut ? 0 : 1));
    final nom = debut <= 15 ? depart : DateTime(depart.year, depart.month + 1);
    return Mois(nom.year, nom.month);
  }

  /// Lu depuis « 2026-09 ».
  factory Mois.lire(String texte) {
    final p = texte.split('-');
    return Mois(int.parse(p[0]), int.parse(p[1]));
  }

  Mois get suivant => mois == 12 ? Mois(annee + 1, 1) : Mois(annee, mois + 1);
  Mois get precedent => mois == 1 ? Mois(annee - 1, 12) : Mois(annee, mois - 1);

  /// Le premier jour, inclus, et le lendemain du dernier, exclu.
  (DateTime, DateTime) bornes({int debut = 1}) {
    if (debut <= 1) {
      return (DateTime(annee, mois), DateTime(annee, mois + 1));
    }
    if (debut <= 15) return (DateTime(annee, mois, debut), DateTime(annee, mois + 1, debut));
    return (DateTime(annee, mois - 1, debut), DateTime(annee, mois, debut));
  }

  String get cle => '$annee-${mois.toString().padLeft(2, '0')}';

  @override
  int compareTo(Mois autre) => cle.compareTo(autre.cle);

  @override
  bool operator ==(Object other) => other is Mois && other.cle == cle;

  @override
  int get hashCode => cle.hashCode;

  @override
  String toString() => cle;
}

/// Le jour habituel du salaire, d'après les dates où il est arrivé : celui
/// du milieu, une fois rangées. Il ne sert qu'aux mois dont le salaire
/// n'est pas encore là, ou pas connu ; les autres commencent le jour même
/// où leur salaire est arrivé (voir [Calendrier]). Un salaire du 29, 30 ou
/// 31 donne le 28 ; un salaire versé en tout début de mois, le 1er ou le
/// 2, compte comme la fin du précédent quand les autres tombent en fin de
/// mois. Rien sans au moins deux salaires.
int? jourDuSalaire(List<DateTime> dates) {
  if (dates.length < 2) return null;
  final jours = [for (final d in dates) d.day];
  final finDeMois = jours.any((j) => j >= 20);
  // En fin de mois, un salaire du 1er au 10 est un salaire en retard :
  // il se range après le 31.
  final ranges = [for (final j in jours) finDeMois && j <= 10 ? j + 31 : j]..sort();
  final milieu = ranges[(ranges.length - 1) ~/ 2];
  if (milieu > 31) return 1;
  return milieu > 28 ? 28 : milieu;
}

/// Le mois que chaque salaire ouvre, et le jour où il l'ouvre. Un salaire
/// finance le mois qui suit son arrivée : versé le 19 décembre pour Noël
/// au lieu du 25, il ouvre quand même janvier, le 19. On le range donc
/// comme s'il était arrivé dix jours plus tard, ce qui absorbe l'avance
/// d'un jour férié comme le retard d'un week-end.
///
/// [salaires] : la date et le montant de chacun. N'ouvre un mois qu'un vrai
/// salaire : au moins la moitié du salaire habituel (une prime, un rappel,
/// un remboursement rangé là n'ouvrent rien), et arrivé à dix jours au plus
/// du jour habituel [debut], qui n'est qu'un repère. Deux salaires pour le
/// même mois n'en ouvrent qu'un, le premier.
Map<Mois, DateTime> ouverturesDuSalaire(List<(DateTime, int)> salaires, {required int debut}) {
  if (salaires.length < 2) return const {};
  final montants = [for (final s in salaires) s.$2]..sort();
  final habituel = montants[montants.length ~/ 2];
  // L'écart au jour habituel, en tournant d'un mois sur l'autre : le 28
  // est à trois jours du 1er.
  bool autour(DateTime d) {
    final ecart = (d.day - debut) % 30;
    return ecart <= 10 || ecart >= 20;
  }

  final dates = [
    for (final (d, montant) in salaires)
      if (montant * 2 >= habituel && autour(d)) DateTime(d.year, d.month, d.day),
  ]..sort();
  final ouvertures = <Mois, DateTime>{};
  for (final d in dates) {
    ouvertures.putIfAbsent(Mois.de(DateTime(d.year, d.month, d.day + 10), debut: debut), () => d);
  }
  return ouvertures;
}

/// Les mois du budget : chacun commence le jour où arrive le salaire qui
/// le finance, et se termine la veille du suivant. Un mois dont le salaire
/// n'est pas connu (pas encore arrivé, ou d'avant l'historique de la
/// banque) commence au jour habituel [debut].
class Calendrier {
  Calendrier({this.debut = 1, Map<Mois, DateTime> ouvertures = const {}}) : ouvertures = _coherentes(debut, ouvertures);

  final int debut;
  final Map<Mois, DateTime> ouvertures;

  /// Un salaire qui tomberait avant l'ouverture du mois précédent, ou
  /// après celle du suivant, casserait l'ordre des mois : il est ignoré.
  static Map<Mois, DateTime> _coherentes(int debut, Map<Mois, DateTime> ouvertures) {
    DateTime fixe(Mois m) => m.bornes(debut: debut).$1;
    final retenues = <Mois, DateTime>{};
    for (final m in ouvertures.keys.toList()..sort()) {
      final d = ouvertures[m]!;
      final avant = retenues[m.precedent] ?? fixe(m.precedent);
      final apres = ouvertures[m.suivant] ?? fixe(m.suivant);
      if (d.isAfter(avant) && d.isBefore(apres)) retenues[m] = d;
    }
    return retenues;
  }

  /// Le premier jour de [mois].
  DateTime debutDe(Mois mois) => ouvertures[mois] ?? mois.bornes(debut: debut).$1;

  /// Le premier jour de [mois], inclus, et celui du suivant, exclu.
  (DateTime, DateTime) bornes(Mois mois) => (debutDe(mois), debutDe(mois.suivant));

  /// Le mois auquel une date appartient.
  Mois de(DateTime date) {
    final jour = DateTime(date.year, date.month, date.day);
    var m = Mois.de(jour, debut: debut);
    for (var i = 0; i < 3 && jour.isBefore(debutDe(m)); i++) {
      m = m.precedent;
    }
    for (var i = 0; i < 3 && !jour.isBefore(debutDe(m.suivant)); i++) {
      m = m.suivant;
    }
    return m;
  }
}

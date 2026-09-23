/// Un mois budgétaire.
///
/// Le mois ne commence pas forcément le 1er : quand le salaire tombe le 28,
/// c'est de là que part le budget. Avec un début au 28, une dépense du
/// 29 septembre compte dans octobre. [debut] vaut 1 pour un mois civil.
class Mois implements Comparable<Mois> {
  const Mois(this.annee, this.mois);

  final int annee;
  final int mois;

  /// Le mois auquel une date appartient.
  factory Mois.de(DateTime date, {int debut = 1}) {
    var a = date.year, m = date.month;
    if (debut > 1 && date.day >= debut) {
      m++;
      if (m > 12) {
        m = 1;
        a++;
      }
    }
    return Mois(a, m);
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

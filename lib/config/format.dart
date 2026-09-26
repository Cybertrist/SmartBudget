import 'package:intl/intl.dart';

import '../domaine/mois.dart';

/// « 1 284,52 € », « -46,23 € », « +500,00 € » : un seul bloc, les
/// centimes à la même taille que les euros, une espace fine entre les
/// milliers, comme sur un relevé.
String euros(int centimes, {bool signe = false, bool centimesSiRond = true}) {
  final abs = centimes.abs();
  final ent = (abs ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  final cts = (abs % 100).toString().padLeft(2, '0');
  final s = centimes < 0 ? '-' : (signe && centimes > 0 ? '+' : '');
  final corps = !centimesSiRond && abs % 100 == 0 ? ent : '$ent,$cts';
  return '$s$corps €';
}

final _mois = DateFormat('MMMM yyyy', 'fr_FR');
final _jour = DateFormat('EEEE d MMMM', 'fr_FR');
final _jourCourt = DateFormat('d MMM', 'fr_FR');

String _majuscule(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String nomMois(Mois m) => _majuscule(_mois.format(DateTime(m.annee, m.mois)));
String nomMoisSeul(Mois m) => _majuscule(DateFormat('MMMM', 'fr_FR').format(DateTime(m.annee, m.mois)));
String jour(DateTime d) => _majuscule(_jour.format(d));
String jourCourt(DateTime d) => _jourCourt.format(d);

String pluriel(int n, String un, [String? plusieurs]) => '$n ${n > 1 ? (plusieurs ?? '${un}s') : un}';

/// Lit un montant en euros tapé à la française : « 1 500 », « 12,5 »,
/// « 1.500,00 ». Rien pour ce qui n'est pas un nombre fini.
int? lireEuros(String texte) {
  var t = texte.replaceAll(RegExp(r'[\s  €]'), '');
  // Avec une virgule pour les centimes, les points séparent les milliers.
  if (t.contains(',')) t = t.replaceAll('.', '');
  t = t.replaceAll(',', '.');
  if (!RegExp(r'^[+-]?(\d+(\.\d{0,2})?|\.\d{1,2})$').hasMatch(t)) return null;
  final v = double.tryParse(t);
  if (v == null || !v.isFinite || v.abs() > 10000000) return null;
  return (v * 100).round();
}

/// Des pourcentages arrondis qui font 100 : le reste va aux plus grosses
/// décimales, pas 61 + 27 + 13.
List<int> pourcentages(List<int> valeurs) {
  final total = valeurs.fold<int>(0, (s, v) => s + (v > 0 ? v : 0));
  if (total == 0) return [for (final _ in valeurs) 0];
  final exactes = [for (final v in valeurs) (v > 0 ? v : 0) * 100 / total];
  final parts = [for (final e in exactes) e.floor()];
  var reste = 100 - parts.fold<int>(0, (s, p) => s + p);
  final ordre = [for (var i = 0; i < valeurs.length; i++) i]
    ..sort((a, b) => (exactes[b] - parts[b]).compareTo(exactes[a] - parts[a]));
  for (final i in ordre) {
    if (reste <= 0) break;
    parts[i]++;
    reste--;
  }
  return parts;
}

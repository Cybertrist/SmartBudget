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

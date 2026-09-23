/// Lecture des libellés bancaires.
///
/// Un libellé de banque est écrit pour la banque : « PAIEMENT PAR CARTE
/// X4057 CARREFOUR MARKET VANNES 12/09 ». Pour classer et regrouper, il
/// faut en tirer le marchand, « CARREFOUR MARKET VANNES », puis une clé
/// stable, sans ville ni date, qui reste la même d'un mois à l'autre.
library;

/// Majuscules, sans accents, espaces simples.
String normaliser(String texte) {
  const accents = {
    'À': 'A', 'Â': 'A', 'Ä': 'A', 'Á': 'A', 'Ã': 'A',
    'Ç': 'C', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'Î': 'I', 'Ï': 'I', 'Í': 'I', 'Ô': 'O', 'Ö': 'O', 'Ó': 'O',
    'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ú': 'U', 'Ÿ': 'Y', 'Ñ': 'N',
    'Œ': 'OE', 'Æ': 'AE',
  };
  final haut = texte.toUpperCase();
  final sortie = StringBuffer();
  for (final r in haut.runes) {
    final c = String.fromCharCode(r);
    sortie.write(accents[c] ?? c);
  }
  return sortie.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Les préfixes que la banque ajoute devant le nom du marchand.
final _prefixes = RegExp(
  r'^(PAIEMENT PAR CARTE|PAIEMENT CB|PAIEMENT CARTE|FACTURE CARTE|CARTE|CB|'
  r'PRLV SEPA|PRELEVEMENT SEPA|PRELEVEMENT|PRLV|'
  r'VIR SEPA RECU|VIR SEPA EMIS|VIR SEPA|VIR INST RECU|VIR INST|VIREMENT SEPA|VIREMENT|VIR|'
  r'RETRAIT DAB|RETRAIT|REMISE CHEQUE|REMISE CHQ)\b[ :]*',
);

/// Ce qui ne dit rien du marchand : numéros de carte masqués, dates,
/// références, montants recopiés.
final _bruit = [
  RegExp(r'\bX\d{3,4}\b'),
  RegExp(r'\b\d{2}/\d{2}(/\d{2,4})?\b'),
  RegExp(r'\b\d{6,}\b'),
  RegExp(r'\bDU \d{6}\b'),
  RegExp(r'\b(N°|NO|REF|REFERENCE|ECH|MDT|RUM|ID)[ :]*\S+'),
  RegExp(r'\b\d+[,.]\d{2}\s?(EUR|€)?'),
  RegExp(r'[*#]'),
];

/// Le libellé débarrassé des préfixes et du bruit.
String marchand(String libelle) {
  var s = normaliser(libelle);
  // Plusieurs préfixes peuvent se suivre : « PRLV SEPA » puis « CB ».
  for (var i = 0; i < 3; i++) {
    final avant = s;
    s = s.replaceFirst(_prefixes, '');
    if (s == avant) break;
  }
  for (final motif in _bruit) {
    s = s.replaceAll(motif, ' ');
  }
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s.isEmpty ? normaliser(libelle) : s;
}

/// Une clé qui reste la même d'une opération à l'autre chez le même
/// marchand : ses trois premiers mots, sans les suffixes de société.
String cleMarchand(String libelle) {
  final mots = marchand(libelle)
      .split(' ')
      .where((m) => m.length > 1 && !const {'SA', 'SAS', 'SARL', 'EUROPE', 'FRANCE', 'FR', 'ET', 'CIE', 'SCA', 'DE', 'LA', 'LE'}.contains(m))
      .take(3);
  final cle = mots.join(' ');
  return cle.isEmpty ? marchand(libelle) : cle;
}

/// Le nom à afficher : « Carrefour Market Vannes ».
String joli(String libelle) {
  final n = normaliser(libelle);
  // Un chèque ou un retrait n'a pas de marchand : son libellé ne garde
  // qu'un numéro, et il n'en restait qu'un « N ».
  if (RegExp(r'^REMISE (CHEQUE|CHQ)').hasMatch(n)) return 'Remise de chèque';
  if (RegExp(r'^(CHEQUE|CHQ)\b').hasMatch(n)) return 'Chèque';
  if (RegExp(r'^RETRAIT').hasMatch(n)) return 'Retrait d\'espèces';
  final m = marchand(libelle).toLowerCase();
  return m
      .split(' ')
      .map((mot) => mot.isEmpty ? mot : mot[0].toUpperCase() + mot.substring(1))
      .join(' ');
}

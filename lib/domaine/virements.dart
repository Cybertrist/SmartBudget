import 'libelle.dart';

/// Le sens d'un virement entre ses propres comptes.
enum SensInterne {
  /// Du compte courant vers un livret : mis de côté.
  versEpargne,

  /// D'un livret vers le compte courant : pioché dans l'épargne.
  depuisEpargne,

  /// Entre deux comptes courants.
  entreComptes,
}

/// Un virement reconnu entre deux comptes à soi.
class VirementInterne {
  const VirementInterne({
    required this.source,
    required this.destination,
    required this.sens,
  });

  final String source;
  final String destination;
  final SensInterne sens;
}

/// Le Crédit Mutuel de Bretagne écrit ses virements internes ainsi :
/// « VIR VERS LIVRET CMB DE CARTE BANCAIRE ». La destination vient après
/// VERS, la source après DE, et « CARTE BANCAIRE » désigne le compte
/// courant.
final _forme = RegExp(r'^VIR(?:EMENT)?(?: INTERNE)? VERS (.+?) DE (.+)$');

/// Ce qui désigne un compte d'épargne dans un nom de compte.
final _epargne = RegExp(r'\b(LIVRET|LDD|LDDS|LEP|PEL|CEL|EPARGNE|ASSURANCE VIE|COMPTE SUR LIVRET|CSL)\b');

bool _estEpargne(String compte, Iterable<String> livretsConnus) {
  if (_epargne.hasMatch(compte)) return true;
  return livretsConnus.any((l) => l.isNotEmpty && compte.contains(l));
}

/// Reconnaît un virement interne, ou rend null.
///
/// [livretsConnus] : les motifs des livrets saisis à la main, en
/// majuscules, pour les noms de compte que la règle générale ne devine
/// pas.
VirementInterne? reconnaitreInterne(
  String libelle, {
  Iterable<String> livretsConnus = const [],
}) {
  final m = _forme.firstMatch(normaliser(libelle));
  if (m == null) return null;
  final destination = m.group(1)!.trim();
  final source = m.group(2)!.trim();
  final versLivret = _estEpargne(destination, livretsConnus);
  final depuisLivret = _estEpargne(source, livretsConnus);
  final sens = versLivret && !depuisLivret
      ? SensInterne.versEpargne
      : depuisLivret && !versLivret
          ? SensInterne.depuisEpargne
          : SensInterne.entreComptes;
  return VirementInterne(source: source, destination: destination, sens: sens);
}

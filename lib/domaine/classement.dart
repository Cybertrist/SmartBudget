import 'dictionnaire.dart';
import 'libelle.dart';
import 'virements.dart';

/// D'où vient le classement d'une opération.
enum Origine {
  /// Reclassée à la main : rien ne la touche plus.
  main,

  /// Une règle apprise d'une correction précédente.
  regle,

  /// Le dictionnaire intégré.
  dictionnaire,

  /// Un virement entre ses propres comptes.
  interne,

  /// Rien n'a reconnu le libellé.
  defaut,
}

class Classement {
  const Classement(this.categorieId, this.origine, {this.interne});

  final int categorieId;
  final Origine origine;
  final SensInterne? interne;
}

/// Une règle apprise : un motif de libellé et sa catégorie.
class Regle {
  const Regle(this.motif, this.categorieId);

  final String motif;
  final int categorieId;
}

/// Trouve la catégorie d'une opération, dans cet ordre :
///
/// 1. un virement interne, reconnu à la forme de son libellé ;
/// 2. une règle apprise, la plus longue d'abord, parce qu'elle est la plus
///    précise ;
/// 3. le dictionnaire intégré ;
/// 4. par défaut, « À classer » pour une sortie, « Autres revenus » pour
///    une entrée.
class Classeur {
  Classeur({
    required this.idDe,
    required this.regles,
    this.livretsConnus = const [],
  }) : _regles = [...regles]..sort((a, b) => b.motif.length.compareTo(a.motif.length));

  /// L'identifiant d'une sous-catégorie à partir de ses deux noms, ou
  /// null si l'utilisateur l'a supprimée.
  final int? Function(String categorie, String sous) idDe;
  final List<Regle> regles;
  final Iterable<String> livretsConnus;
  final List<Regle> _regles;

  Classement classer(String libelle, int montantCentimes) {
    final texte = normaliser(libelle);

    final interne = reconnaitreInterne(texte, livretsConnus: livretsConnus);
    if (interne != null) {
      final sous = switch (interne.sens) {
        SensInterne.versEpargne => "Vers l'épargne",
        SensInterne.depuisEpargne => "Depuis l'épargne",
        SensInterne.entreComptes => 'Entre mes comptes courants',
      };
      final id = idDe('Virements internes', sous);
      if (id != null) return Classement(id, Origine.interne, interne: interne.sens);
    }

    for (final r in _regles) {
      if (contient(texte, r.motif)) return Classement(r.categorieId, Origine.regle);
    }

    final entree = montantCentimes > 0;
    for (final m in dictionnaire) {
      if (m.seulementEntree && !entree) continue;
      if (!contient(texte, m.texte, motEntier: m.mot || m.texte.length <= 3)) continue;
      final id = idDe(m.categorie, m.sous);
      if (id != null) return Classement(id, Origine.dictionnaire);
    }

    final defaut = entree
        ? idDe('Autres revenus', 'Virements reçus')
        : idDe('À classer', 'À classer');
    return Classement(defaut ?? 0, Origine.defaut);
  }
}

/// Le motif figure-t-il dans le texte, au début d'un mot ?
bool contient(String texte, String motif, {bool motEntier = false}) {
  final m = normaliser(motif);
  var depuis = 0;
  while (true) {
    final i = texte.indexOf(m, depuis);
    if (i < 0) return false;
    final avantOk = i == 0 || !_alnum(texte.codeUnitAt(i - 1));
    final fin = i + m.length;
    final apresOk = !motEntier || fin == texte.length || !_alnum(texte.codeUnitAt(fin));
    if (avantOk && apresOk) return true;
    depuis = i + 1;
  }
}

bool _alnum(int c) =>
    (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122);

/// Le motif à retenir quand l'utilisateur reclasse une opération : la clé
/// du marchand, qui vaudra pour toutes ses opérations suivantes.
String motifAApprendre(String libelle) => cleMarchand(libelle);

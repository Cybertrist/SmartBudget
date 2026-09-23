import 'classement.dart';
import 'libelle.dart';
import 'virements.dart';

/// Ce que compte une catégorie dans le budget.
enum Genre {
  depense,
  revenu,

  /// Mis de côté hors livrets suivis : assurance vie, investissements.
  epargne,

  /// Virement entre ses propres comptes : ni dépense ni revenu.
  interne;

  static Genre lire(String s) => Genre.values.firstWhere((g) => g.name == s);
}

/// Ce que pose chaque dépense : essentielle, un plaisir, ou un imprévu
/// qui n'avait pas sa place dans le mois.
enum Nature {
  essentiel,
  plaisir,
  imprevu;

  String get libelle => switch (this) {
        Nature.essentiel => 'Essentiel',
        Nature.plaisir => 'Plaisir',
        Nature.imprevu => 'Imprévu',
      };
}

class Categorie {
  const Categorie({
    required this.id,
    required this.parentId,
    required this.nom,
    required this.genre,
    required this.icone,
    required this.couleur,
    required this.budgetCentimes,
    required this.ordre,
    required this.nature,
  });

  final int id;

  /// Null pour une catégorie, l'identifiant du parent pour une
  /// sous-catégorie.
  final int? parentId;
  final String nom;
  final Genre genre;

  /// Le nom de l'icône Material, null pour reprendre celle du parent.
  final String? icone;
  final int couleur;
  final int? budgetCentimes;
  final int ordre;

  /// La nature par défaut des dépenses rangées ici.
  final Nature nature;

  bool get estSous => parentId != null;

  factory Categorie.lire(Map<String, Object?> l) => Categorie(
        id: l['id']! as int,
        parentId: l['parent_id'] as int?,
        nom: l['nom']! as String,
        genre: Genre.lire(l['genre']! as String),
        icone: l['icone'] as String?,
        couleur: l['couleur']! as int,
        budgetCentimes: l['budget_centimes'] as int?,
        ordre: l['ordre']! as int,
        nature: Nature.values.byName(l['nature']! as String),
      );
}

enum NatureCompte { courant, livret }

class Compte {
  const Compte({
    required this.id,
    required this.nature,
    required this.nom,
    this.uidBanque,
    this.ibanFin,
    required this.soldeCentimes,
    this.soldeLe,
    this.motif,
  });

  final int id;
  final NatureCompte nature;
  final String nom;
  final String? uidBanque;
  final String? ibanFin;
  final int soldeCentimes;
  final DateTime? soldeLe;

  /// Comment la banque nomme ce livret dans ses virements, « LIVRET CMB ».
  final String? motif;

  factory Compte.lire(Map<String, Object?> l) => Compte(
        id: l['id']! as int,
        nature: NatureCompte.values.byName(l['nature']! as String),
        nom: l['nom']! as String,
        uidBanque: l['uid_banque'] as String?,
        ibanFin: l['iban_fin'] as String?,
        soldeCentimes: l['solde_centimes']! as int,
        soldeLe: l['solde_le'] == null ? null : DateTime.parse(l['solde_le']! as String),
        motif: l['motif'] as String?,
      );
}

/// Une opération telle que la banque la donne, avant classement.
class OperationBrute {
  const OperationBrute({
    required this.uidBanque,
    required this.le,
    required this.libelle,
    required this.montantCentimes,
  });

  final String uidBanque;
  final DateTime le;
  final String libelle;
  final int montantCentimes;
}

class Operation {
  const Operation({
    required this.id,
    required this.compteId,
    required this.uidBanque,
    required this.le,
    required this.libelle,
    required this.montantCentimes,
    required this.categorieId,
    required this.origine,
    this.nature,
    this.moisCompte,
    this.note,
    this.masquee = false,
    this.recurrente,
    this.interne,
    this.pointee = false,
    this.nom,
  });

  final int id;
  final int compteId;
  final String? uidBanque;
  final DateTime le;
  final String libelle;
  final int montantCentimes;
  final int categorieId;
  final Origine origine;

  /// Null : la nature par défaut de la catégorie.
  final Nature? nature;

  /// « 2026-09 » quand l'opération est rattachée à un autre mois que le
  /// sien, un loyer payé le 30 pour le mois suivant.
  final String? moisCompte;
  final String? note;
  final bool masquee;

  /// Null : décidé par la détection. Sinon forcé à la main.
  final bool? recurrente;
  final SensInterne? interne;

  /// Vérifiée à la main : sa catégorie est la bonne.
  final bool pointee;

  /// Le nom choisi à la main, « Spotify » plutôt que « Spotify P2f9
  /// Stockholm ».
  final String? nom;

  /// Ce qu'on affiche : le nom choisi, sinon celui tiré du libellé.
  String get titre => (nom == null || nom!.isEmpty) ? joli(libelle) : nom!;

  bool get entree => montantCentimes > 0;

  factory Operation.lire(Map<String, Object?> l) => Operation(
        id: l['id']! as int,
        compteId: l['compte_id']! as int,
        uidBanque: l['uid_banque'] as String?,
        le: DateTime.parse(l['le']! as String),
        libelle: l['libelle']! as String,
        montantCentimes: l['montant_centimes']! as int,
        categorieId: l['categorie_id']! as int,
        origine: Origine.values.byName(l['origine']! as String),
        nature: l['nature'] == null ? null : Nature.values.byName(l['nature']! as String),
        moisCompte: l['mois_compte'] as String?,
        note: l['note'] as String?,
        masquee: (l['masquee'] as int? ?? 0) == 1,
        recurrente: l['recurrente'] == null ? null : (l['recurrente']! as int) == 1,
        interne: l['interne'] == null ? null : SensInterne.values.byName(l['interne']! as String),
        pointee: (l['pointee'] as int? ?? 0) == 1,
        nom: l['nom'] as String?,
      );
}

/// La part d'une entrée d'argent qui rembourse une dépense.
class Lien {
  const Lien(this.entreeId, this.depenseId, this.montantCentimes);

  final int entreeId;
  final int depenseId;
  final int montantCentimes;
}

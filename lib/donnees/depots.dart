import 'package:sqflite_sqlcipher/sqflite.dart';

import '../domaine/bilan.dart';
import '../domaine/classement.dart';
import '../domaine/libelle.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../domaine/recurrences.dart';
import '../domaine/virements.dart';
import 'base.dart';

Future<Database> get _db => Base.instance.db;

String _date(DateTime d) => d.toIso8601String().substring(0, 10);

// ------------------------------------------------------------ catégories

class DepotCategories {
  const DepotCategories();

  Future<List<Categorie>> toutes() async {
    final lignes = await (await _db).query('categories', orderBy: 'ordre, id');
    return lignes.map(Categorie.lire).toList();
  }

  Future<Map<int, Categorie>> parId() async =>
      {for (final c in await toutes()) c.id: c};

  /// Trouve une sous-catégorie par ses deux noms, ou à défaut la catégorie.
  Future<int? Function(String, String)> resolveur() async {
    final liste = await toutes();
    final racines = {for (final c in liste.where((c) => c.parentId == null)) c.nom: c.id};
    final sous = {
      for (final c in liste.where((c) => c.parentId != null)) '${c.parentId}/${c.nom}': c.id,
    };
    return (String categorie, String nom) {
      final r = racines[categorie];
      if (r == null) return null;
      return sous['$r/$nom'] ?? r;
    };
  }

  Future<int> creer({
    required String nom,
    int? parentId,
    required Genre genre,
    String? icone,
    required int couleur,
    Nature nature = Nature.plaisir,
  }) async {
    final db = await _db;
    final ordre = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COALESCE(MAX(ordre), -1) + 1 FROM categories WHERE parent_id IS ?',
          [parentId],
        )) ??
        0;
    return db.insert('categories', {
      'parent_id': parentId,
      'nom': nom,
      'genre': genre.name,
      'icone': icone,
      'couleur': couleur,
      'ordre': ordre,
      'nature': nature.name,
    });
  }

  Future<void> definirBudget(int id, int? centimes) async {
    await (await _db).update('categories', {'budget_centimes': centimes}, where: 'id = ?', whereArgs: [id]);
  }
}

// --------------------------------------------------------------- comptes

class DepotComptes {
  const DepotComptes();

  Future<List<Compte>> tous() async =>
      (await (await _db).query('comptes', orderBy: 'id')).map(Compte.lire).toList();

  /// Le compte courant, créé à la première demande.
  Future<Compte> courant() async {
    final db = await _db;
    final l = await db.query('comptes', where: "nature = 'courant'", limit: 1);
    if (l.isNotEmpty) return Compte.lire(l.first);
    await db.insert('comptes', {
      'nature': NatureCompte.courant.name,
      'nom': 'Compte courant',
      'solde_centimes': 0,
      'cree_le': DateTime.now().toIso8601String(),
    });
    return courant();
  }

  Future<int> ajouterLivret({required String nom, required int soldeCentimes, String? motif}) async {
    return (await _db).insert('comptes', {
      'nature': NatureCompte.livret.name,
      'nom': nom,
      'solde_centimes': soldeCentimes,
      'solde_le': DateTime.now().toIso8601String(),
      'motif': motif == null ? null : normaliser(motif),
      'cree_le': DateTime.now().toIso8601String(),
    });
  }

  Future<void> definirSolde(int id, int centimes, {DateTime? le}) async {
    await (await _db).update(
      'comptes',
      {'solde_centimes': centimes, 'solde_le': (le ?? DateTime.now()).toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> motifsLivrets() async {
    final l = await (await _db).query('comptes', columns: ['motif', 'nom'], where: "nature = 'livret'");
    return [for (final r in l) normaliser((r['motif'] ?? r['nom'])! as String)];
  }
}

// ------------------------------------------------------------ opérations

class DepotOperations {
  const DepotOperations();

  static const _categories = DepotCategories();
  static const _comptes = DepotComptes();

  Future<Classeur> _classeur() async {
    final db = await _db;
    final regles = (await db.query('regles'))
        .map((l) => Regle(l['motif']! as String, l['categorie_id']! as int))
        .toList();
    return Classeur(
      idDe: await _categories.resolveur(),
      regles: regles,
      livretsConnus: await _comptes.motifsLivrets(),
    );
  }

  /// Range les opérations venues de la banque. Celles déjà connues, à leur
  /// identifiant bancaire, sont ignorées : une synchronisation peut se
  /// relancer sans rien doubler. Rend le nombre d'opérations nouvelles.
  Future<int> importer(int compteId, List<OperationBrute> brutes) async {
    final db = await _db;
    final classeur = await _classeur();
    final livrets = (await db.query('comptes', where: "nature = 'livret'")).map(Compte.lire).toList();
    var nouvelles = 0;
    await db.transaction((t) async {
      for (final b in brutes) {
        final existe = await t.query('operations', columns: ['id'], where: 'uid_banque = ?', whereArgs: [b.uidBanque], limit: 1);
        if (existe.isNotEmpty) continue;
        final c = classeur.classer(b.libelle, b.montantCentimes);
        await t.insert('operations', {
          'compte_id': compteId,
          'uid_banque': b.uidBanque,
          'le': _date(b.le),
          'libelle': b.libelle,
          'montant_centimes': b.montantCentimes,
          'categorie_id': c.categorieId,
          'origine': c.origine.name,
          'interne': c.interne?.name,
        });
        nouvelles++;
        // Un virement vers ou depuis un livret suivi fait vivre son solde,
        // s'il est postérieur au solde saisi.
        final v = c.interne == null ? null : reconnaitreInterne(b.libelle);
        if (v == null) continue;
        for (final l in livrets) {
          final motif = normaliser(l.motif ?? l.nom);
          if (l.soldeLe != null && !b.le.isAfter(l.soldeLe!)) continue;
          if (v.destination.contains(motif)) {
            await t.rawUpdate('UPDATE comptes SET solde_centimes = solde_centimes + ? WHERE id = ?', [b.montantCentimes.abs(), l.id]);
          } else if (v.source.contains(motif)) {
            await t.rawUpdate('UPDATE comptes SET solde_centimes = solde_centimes - ? WHERE id = ?', [b.montantCentimes.abs(), l.id]);
          }
        }
      }
    });
    return nouvelles;
  }

  Future<Operation?> une(int id) async {
    final l = await (await _db).query('operations', where: 'id = ?', whereArgs: [id]);
    return l.isEmpty ? null : Operation.lire(l.first);
  }

  /// Les opérations comptées dans [mois] : celles de ses dates, et celles
  /// rattachées à lui à la main.
  Future<List<Operation>> duMois(Mois mois, {int debut = 1}) async {
    final (de, a) = mois.bornes(debut: debut);
    final l = await (await _db).query(
      'operations',
      where: '(le >= ? AND le < ? AND mois_compte IS NULL) OR mois_compte = ?',
      whereArgs: [_date(de), _date(a), mois.cle],
      orderBy: 'le DESC, id DESC',
    );
    return l.map(Operation.lire).toList();
  }

  Future<List<Operation>> entre(DateTime de, DateTime a) async {
    final l = await (await _db).query('operations',
        where: 'le >= ? AND le < ?', whereArgs: [_date(de), _date(a)], orderBy: 'le DESC, id DESC');
    return l.map(Operation.lire).toList();
  }

  /// Reclasse une opération à la main. Avec [apprendre], la correction
  /// devient une règle : les opérations du même marchand qui n'ont pas été
  /// classées à la main suivent, et les prochaines aussi.
  Future<int> reclasser(int id, int categorieId, {bool apprendre = true}) async {
    final db = await _db;
    final op = await une(id);
    if (op == null) return 0;
    var suivies = 0;
    await db.transaction((t) async {
      await t.update('operations', {'categorie_id': categorieId, 'origine': Origine.main.name, 'interne': null},
          where: 'id = ?', whereArgs: [id]);
      if (!apprendre || op.interne != null) return;
      final motif = motifAApprendre(op.libelle);
      await t.insert('regles', {'motif': motif, 'categorie_id': categorieId},
          conflictAlgorithm: ConflictAlgorithm.replace);
      final autres = await t.query('operations',
          columns: ['id', 'libelle'], where: "origine != 'main' AND interne IS NULL AND id != ?", whereArgs: [id]);
      for (final a in autres) {
        if (contient(normaliser(a['libelle']! as String), motif)) {
          await t.update('operations', {'categorie_id': categorieId, 'origine': Origine.regle.name},
              where: 'id = ?', whereArgs: [a['id']]);
          suivies++;
        }
      }
    });
    return suivies;
  }

  Future<void> modifier(
    int id, {
    Object? note = _rien,
    Object? nature = _rien,
    Object? moisCompte = _rien,
    bool? masquee,
    Object? recurrente = _rien,
  }) async {
    final champs = <String, Object?>{
      if (!identical(note, _rien)) 'note': note,
      if (!identical(nature, _rien)) 'nature': (nature as Nature?)?.name,
      if (!identical(moisCompte, _rien)) 'mois_compte': (moisCompte as Mois?)?.cle,
      if (masquee != null) 'masquee': masquee ? 1 : 0,
      if (!identical(recurrente, _rien)) 'recurrente': recurrente == null ? null : ((recurrente as bool) ? 1 : 0),
    };
    if (champs.isEmpty) return;
    await (await _db).update('operations', champs, where: 'id = ?', whereArgs: [id]);
  }

  /// Les récurrences, déduites d'un an d'opérations.
  Future<List<Recurrence>> recurrences({DateTime? maintenant}) async {
    final fin = maintenant ?? DateTime.now();
    final ops = await entre(fin.subtract(const Duration(days: 400)), fin.add(const Duration(days: 1)));
    final forcees = ops.where((o) => o.recurrente == false).map((o) => cleMarchand(o.libelle)).toSet();
    final passages = [
      for (final o in ops)
        if (o.interne == null && !o.masquee) Passage(o.libelle, o.le, o.montantCentimes),
    ];
    final choix = <String, Frequence?>{
      for (final e in (await const DepotReglages().commencantPar(_repetition)).entries)
        e.key.substring(_repetition.length): Frequence.values.where((f) => f.name == e.value).firstOrNull,
    };
    return appliquerChoix(
      detecterRecurrences(passages).where((r) => !forcees.contains(r.cle)).toList(),
      passages,
      choix,
    );
  }

  static const _repetition = 'repetition:';

  /// Fixe la répétition d'un marchand : toutes ses opérations suivent.
  /// [frequence] à null : ce marchand ne revient pas, quoi qu'en dise la
  /// détection.
  Future<void> choisirRepetition(String cleMarchand, Frequence? frequence) =>
      const DepotReglages().ecrire('$_repetition$cleMarchand', frequence?.name ?? 'aucune');
}

const _rien = Object();

// ---------------------------------------------------------------- liens

class DepotLiens {
  const DepotLiens();

  /// Répartit une entrée sur des dépenses : chèque de 500 € pour 300 € de
  /// train et 200 € de restaurant. Remplace la répartition précédente.
  /// Refuse une répartition qui dépasse l'entrée ou l'une des dépenses.
  Future<void> repartir(int entreeId, Map<int, int> parDepense) async {
    final db = await _db;
    const ops = DepotOperations();
    final entree = await ops.une(entreeId);
    if (entree == null || !entree.entree) throw ArgumentError('Pas une entrée d\'argent.');
    final total = parDepense.values.fold(0, (a, b) => a + b);
    if (total > entree.montantCentimes) {
      throw ArgumentError('La répartition dépasse le montant reçu.');
    }
    for (final e in parDepense.entries) {
      final d = await ops.une(e.key);
      if (d == null || d.entree) throw ArgumentError('Pas une dépense.');
      if (e.value <= 0 || e.value > -d.montantCentimes) {
        throw ArgumentError('Part hors de la dépense.');
      }
    }
    await db.transaction((t) async {
      await t.delete('liens', where: 'entree_id = ?', whereArgs: [entreeId]);
      for (final e in parDepense.entries) {
        await t.insert('liens', {'entree_id': entreeId, 'depense_id': e.key, 'montant_centimes': e.value});
      }
    });
  }

  Future<List<Lien>> concernant(Iterable<int> ids) async {
    if (ids.isEmpty) return [];
    final marques = List.filled(ids.length, '?').join(',');
    final l = await (await _db).rawQuery(
      'SELECT * FROM liens WHERE entree_id IN ($marques) OR depense_id IN ($marques)',
      [...ids, ...ids],
    );
    return l
        .map((r) => Lien(r['entree_id']! as int, r['depense_id']! as int, r['montant_centimes']! as int))
        .toList();
  }
}

// -------------------------------------------------------------- réglages

class DepotReglages {
  const DepotReglages();

  Future<String?> lire(String cle) async {
    final l = await (await _db).query('reglages', where: 'cle = ?', whereArgs: [cle]);
    return l.isEmpty ? null : l.first['valeur'] as String?;
  }

  Future<void> ecrire(String cle, String? valeur) async {
    await (await _db).insert('reglages', {'cle': cle, 'valeur': valeur},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Les réglages dont la clé commence par [prefixe].
  Future<Map<String, String>> commencantPar(String prefixe) async {
    final l = await (await _db).query('reglages', where: 'cle LIKE ?', whereArgs: ['$prefixe%']);
    return {for (final r in l) if (r['valeur'] != null) r['cle']! as String: r['valeur']! as String};
  }

  /// Le jour où commence le mois budgétaire, 1 par défaut.
  Future<int> debutMois() async => int.tryParse(await lire('debut_mois') ?? '') ?? 1;
}

// ------------------------------------------------------------------ bilan

class DepotBilan {
  const DepotBilan();

  Future<Bilan> du(Mois mois) async {
    const ops = DepotOperations();
    const liens = DepotLiens();
    final debut = await const DepotReglages().debutMois();
    final duMois = await ops.duMois(mois, debut: debut);
    final lies = await liens.concernant(duMois.map((o) => o.id));

    // Les dépenses d'un autre mois qu'une entrée de celui-ci rembourse, et
    // les entrées d'un autre mois qui remboursent les siennes : elles
    // entrent dans le calcul pour que les parts tombent au bon endroit.
    final connues = {for (final o in duMois) o.id};
    final manquantes = {for (final l in lies) ...[l.entreeId, l.depenseId]}.difference(connues);
    final autres = <Operation>[];
    for (final id in manquantes) {
      final o = await ops.une(id);
      if (o != null) autres.add(o);
    }

    return calculerBilan(
      mois: mois,
      operations: [...duMois, ...autres],
      liens: lies,
      categories: await const DepotCategories().parId(),
      debut: debut,
    );
  }
}

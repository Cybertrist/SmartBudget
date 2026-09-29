import 'package:sqflite_sqlcipher/sqflite.dart';

import '../config/format.dart';
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

  static const _repere = 'portefeuille_repere';

  /// Ouvre le portefeuille avec ce qu'il contient, ou en corrige le
  /// contenu. Les retraits et les dépenses en espèces arrivés ensuite le
  /// font vivre.
  Future<void> fixerPortefeuille(int centimes) async {
    final db = await _db;
    final existant = await db.query('comptes', where: "nature = 'portefeuille'", limit: 1);
    if (existant.isEmpty) {
      await db.insert('comptes', {
        'nature': NatureCompte.portefeuille.name,
        'nom': 'Portefeuille',
        'solde_centimes': centimes,
        'solde_le': DateTime.now().toIso8601String(),
        'cree_le': DateTime.now().toIso8601String(),
      });
    } else {
      await definirSolde(existant.first['id']! as int, centimes);
    }
    // Le repère : la dernière opération connue. Celles d'après bougent le
    // portefeuille, celles d'avant sont déjà dans le montant saisi.
    final dernier = (await db.rawQuery('SELECT MAX(id) AS m FROM operations')).first['m'] as int? ?? 0;
    await const DepotReglages().ecrire(_repere, '$dernier');
  }

  /// Le contenu du portefeuille aujourd'hui : le montant saisi, plus les
  /// retraits au distributeur arrivés depuis, moins les dépenses en espèces.
  Future<int> soldePortefeuille(Compte portefeuille) async {
    final repere = int.tryParse(await const DepotReglages().lire(_repere) ?? '') ?? 0;
    final db = await _db;
    final retraits = await db.rawQuery(
      "SELECT COALESCE(SUM(-o.montant_centimes), 0) AS s FROM operations o JOIN categories c ON c.id = o.categorie_id "
      "WHERE o.id > ? AND c.nom = 'Retraits d''espèces' AND o.montant_centimes < 0",
      [repere],
    );
    final especes = await db.rawQuery(
      'SELECT COALESCE(SUM(-montant_centimes), 0) AS s FROM operations WHERE id > ? AND especes = 1',
      [repere],
    );
    return portefeuille.soldeCentimes + (retraits.first['s'] as int) - (especes.first['s'] as int);
  }

  /// Supprime un livret ou le portefeuille. Le compte courant, lui, ne se
  /// supprime pas.
  Future<void> supprimerLivret(int id) async {
    await (await _db).delete('comptes', where: "id = ? AND nature != 'courant'", whereArgs: [id]);
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

  /// Retire les règles apprises trop vagues (celles d'avant la version
  /// 1.2.1 sur un chèque ou un retrait : « N », une ville), puis reclasse
  /// les opérations qu'elles avaient rangées. Rend leur nombre.
  Future<int> reparerRegles() async {
    final db = await _db;
    // Les clés tirées d'un chèque ou d'un retrait (« N », « VANNES ») : une
    // règle sur elles n'a jamais désigné un marchand.
    final sansMarchandCles = {
      for (final r in await db.query('operations', columns: ['libelle']))
        if (sansMarchand(r['libelle']! as String)) cleMarchand(r['libelle']! as String),
    };
    final mauvaises = [
      for (final r in await db.query('regles'))
        if (!motifValable(r['motif']! as String) || sansMarchandCles.contains(r['motif'])) r['motif']! as String,
    ];
    if (mauvaises.isEmpty) return 0;
    for (final m in mauvaises) {
      await db.delete('regles', where: 'motif = ?', whereArgs: [m]);
    }
    final classeur = await _classeur();
    final touchees = await db.query('operations',
        columns: ['id', 'libelle', 'montant_centimes', 'categorie_id'], where: "origine = 'regle'");
    var n = 0;
    await db.transaction((t) async {
      for (final o in touchees) {
        final c = classeur.classer(o['libelle']! as String, o['montant_centimes']! as int);
        if (c.categorieId == o['categorie_id'] && c.origine == Origine.regle) continue;
        await t.update('operations', {'categorie_id': c.categorieId, 'origine': c.origine.name, 'interne': c.interne?.name},
            where: 'id = ?', whereArgs: [o['id']]);
        n++;
      }
    });
    return n;
  }

  /// La catégorie que le classement automatique donnerait à [o].
  Future<int?> categorieProposee(Operation o) async {
    final id = (await _classeur()).classer(o.libelle, o.montantCentimes).categorieId;
    return id == 0 ? null : id;
  }

  /// Le classeur, ses règles lues par [t] quand on en donne un : dans une
  /// transaction, une règle apprise juste avant compte déjà.
  Future<Classeur> _classeur({DatabaseExecutor? t, int? Function(String, String)? idDe, Iterable<String>? livretsConnus}) async {
    final regles = (await (t ?? await _db).query('regles'))
        .map((l) => Regle(l['motif']! as String, l['categorie_id']! as int))
        .toList();
    return Classeur(
      idDe: idDe ?? await _categories.resolveur(),
      regles: regles,
      livretsConnus: livretsConnus ?? await _comptes.motifsLivrets(),
    );
  }

  /// Range les opérations venues de la banque. Celles déjà connues, à leur
  /// identifiant bancaire, sont ignorées : une synchronisation peut se
  /// relancer sans rien doubler. Rend le nombre d'opérations nouvelles.
  ///
  /// Une opération en attente est mise à jour sur place par celle qui lui
  /// correspond : la même encore en attente, ou la même une fois
  /// comptabilisée, du même marchand, au même montant à une semaine près,
  /// ou à un montant voisin (un pourboire) à un mois près. Elle garde son
  /// identifiant, donc ses liens de remboursement, les pages ouvertes sur
  /// elle, et ce qui a été fait à la main (catégorie, nom, note, mois).
  ///
  /// Celles que la banque ne donne plus s'effacent, seulement si elle a
  /// bien donné toute la liste de celles en attente ([attenteLue]), lue
  /// depuis [depuis] : une liste partielle ne doit rien effacer.
  Future<int> importer(int compteId, List<OperationBrute> brutes, {bool attenteLue = true, DateTime? depuis}) async {
    final db = await _db;
    // Ce qui ne peut pas se lire dans la transaction : les catégories et
    // les livrets, qui ne bougent pas pendant un import.
    final idDe = await _categories.resolveur();
    final motifsLivrets = await _comptes.motifsLivrets();
    final livrets = (await db.query('comptes', where: "nature = 'livret'")).map(Compte.lire).toList();
    var nouvelles = 0;
    await db.transaction((t) async {
      final classeur = await _classeur(t: t, idDe: idDe, livretsConnus: motifsLivrets);
      // Les noms choisis pour des marchands, que les nouvelles reprennent.
      final noms = {
        for (final r in await t.query('reglages', where: 'cle LIKE ?', whereArgs: ['$_nomMarchand%']))
          if (r['valeur'] != null) (r['cle']! as String).substring(_nomMarchand.length): r['valeur']! as String,
      };
      // Toutes les opérations déjà comptabilisées, d'une seule lecture :
      // une requête par opération rendait le premier import très lent.
      final connues = {
        for (final r in await t.query('operations', columns: ['uid_banque'], where: 'uid_banque IS NOT NULL AND en_attente = 0'))
          r['uid_banque']! as String,
      };
      final enAttente = [
        ...await t.query('operations', where: 'compte_id = ? AND en_attente = 1', whereArgs: [compteId]),
      ];
      // Celles que la banque donne encore en attente : une comptabilisée ne
      // doit pas leur prendre la place.
      final encoreEnAttente = {for (final b in brutes) if (b.enAttente) b.uidBanque};
      int jours(Map<String, Object?> a, OperationBrute b) => DateTime.parse(a['le']! as String).difference(b.le).inDays.abs();
      bool memeMarchand(Map<String, Object?> a, OperationBrute b) {
        final x = cleMarchand(a['libelle']! as String), y = cleMarchand(b.libelle);
        if (x == y) return true;
        final mots = {for (final m in x.split(' ')) if (m.length >= 4) m};
        return y.split(' ').any(mots.contains);
      }

      // L'ancienne en attente qui correspond à [b], retirée de la liste.
      // Sans la liste complète de la banque, seul l'identifiant fait foi.
      Map<String, Object?>? reprise(OperationBrute b) {
        var i = enAttente.indexWhere((a) => a['uid_banque'] == b.uidBanque);
        if (i < 0 && !b.enAttente && attenteLue) {
          bool libre(Map<String, Object?> a) => !encoreEnAttente.contains(a['uid_banque']) && memeMarchand(a, b);
          i = enAttente.indexWhere((a) => libre(a) && a['montant_centimes'] == b.montantCentimes && jours(a, b) <= 7);
          if (i < 0) {
            // Un pourboire ajouté, une caution levée plus tard : même
            // marchand, montant à 20 % près, dans le mois.
            i = enAttente.indexWhere((a) {
              final m = a['montant_centimes']! as int;
              return libre(a) && m.sign == b.montantCentimes.sign && (m - b.montantCentimes).abs() * 5 <= m.abs() && jours(a, b) <= 30;
            });
          }
        }
        return i < 0 ? null : enAttente.removeAt(i);
      }

      final lot = t.batch();
      for (final b in brutes) {
        if (connues.contains(b.uidBanque)) continue;
        final c = classeur.classer(b.libelle, b.montantCentimes);
        final a = reprise(b);
        final aLaMain = a != null && a['origine'] == Origine.main.name;
        final champs = {
          'uid_banque': b.uidBanque,
          'le': _date(b.le),
          'libelle': b.libelle,
          'montant_centimes': b.montantCentimes,
          if (!aLaMain) ...{
            'categorie_id': c.categorieId,
            'origine': c.origine.name,
            'interne': c.interne?.name,
          },
          'nom': a?['nom'] ?? noms[cleMarchand(b.libelle)],
          'en_attente': b.enAttente ? 1 : 0,
        };
        if (a == null) {
          lot.insert('operations', {...champs, 'compte_id': compteId});
          nouvelles++;
        } else {
          // Déjà vue en attente la fois d'avant : rien de neuf à annoncer.
          lot.update('operations', champs, where: 'id = ?', whereArgs: [a['id']]);
        }
        if (!b.enAttente) connues.add(b.uidBanque);
        // Un virement vers ou depuis un livret suivi fait vivre son solde,
        // s'il est postérieur au solde saisi. Pas tant qu'il est en attente :
        // il compterait deux fois.
        final v = c.interne == null || b.enAttente ? null : reconnaitreInterne(b.libelle);
        if (v == null) continue;
        for (final l in livrets) {
          final motif = normaliser(l.motif ?? l.nom);
          if (l.soldeLe != null && !b.le.isAfter(l.soldeLe!)) continue;
          // Au mot entier : un virement vers le LDDS ne crédite pas le LDD.
          if (contient(v.destination, motif, motEntier: true)) {
            lot.rawUpdate('UPDATE comptes SET solde_centimes = solde_centimes + ? WHERE id = ?', [b.montantCentimes.abs(), l.id]);
          } else if (contient(v.source, motif, motEntier: true)) {
            lot.rawUpdate('UPDATE comptes SET solde_centimes = solde_centimes - ? WHERE id = ?', [b.montantCentimes.abs(), l.id]);
          }
        }
      }
      // Celles que la banque ne donne plus : annulées, ou déjà prises.
      for (final a in attenteLue ? enAttente : const <Map<String, Object?>>[]) {
        if (depuis != null && DateTime.parse(a['le']! as String).isBefore(depuis)) continue;
        lot.delete('operations', where: 'id = ?', whereArgs: [a['id']]);
      }
      await lot.commit(noResult: true);
    });
    return nouvelles;
  }

  /// Les salaires reçus depuis [depuis] : leur date et leur montant.
  Future<List<(DateTime, int)>> _salaires(DateTime depuis) async {
    final cats = await _categories.parId();
    bool salaire(Operation o) {
      final c = cats[o.categorieId];
      final racine = c?.parentId == null ? c : cats[c!.parentId];
      return racine?.nom == 'Salaire';
    }

    return [
      for (final o in await entre(depuis, DateTime.now().add(const Duration(days: 1))))
        if (o.montantCentimes > 0 && !o.masquee && o.interne == null && !o.enAttente && salaire(o)) (o.le, o.montantCentimes),
    ];
  }

  /// Règle le jour habituel du salaire, d'après les six derniers mois, tant
  /// que le début n'a pas été choisi à la main. Rend vrai s'il a changé.
  Future<bool> ajusterDebutMois() async {
    const reglages = DepotReglages();
    if (!await reglages.debutMoisAuto()) return false;
    final salaires = await _salaires(DateTime.now().subtract(const Duration(days: 190)));
    final jour = jourDuSalaire([for (final s in salaires) s.$1]);
    if (jour == null || jour == await reglages.debutMois()) return false;
    await reglages.ecrire('debut_mois', '$jour');
    return true;
  }

  /// Les mois du budget : chaque salaire ouvre le sien le jour où il
  /// arrive, même en avance pour Noël. Le jour réglé, trouvé tout seul ou
  /// choisi à la main, n'est qu'un repère autour duquel il tombe.
  Future<Calendrier> calendrier() async {
    final debut = await const DepotReglages().debutMois();
    return Calendrier(debut: debut, ouvertures: ouverturesDuSalaire(await _salaires(DateTime(2000)), debut: debut));
  }

  /// La plus ancienne opération encore en attente : la banque doit donner
  /// les attentes au moins depuis elle, sinon elle ne s'effacerait jamais.
  Future<DateTime?> plusAncienneEnAttente() async {
    final r = await (await _db).rawQuery('SELECT MIN(le) AS le FROM operations WHERE en_attente = 1');
    final le = r.first['le'] as String?;
    return le == null ? null : DateTime.parse(le);
  }

  Future<Operation?> une(int id) async {
    final l = await (await _db).query('operations', where: 'id = ?', whereArgs: [id]);
    return l.isEmpty ? null : Operation.lire(l.first);
  }

  /// Les opérations comptées dans [mois] : celles de ses dates, et celles
  /// rattachées à lui à la main.
  Future<List<Operation>> duMois(Mois mois, Calendrier calendrier) async {
    final (de, a) = calendrier.bornes(mois);
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
    // Rangée à la main dans « Virements internes » : le sens suit la
    // sous-catégorie, sinon l'épargne ne la compterait pas.
    final cats = await _categories.parId();
    final cat = cats[categorieId];
    final racine = cat?.parentId == null ? cat : cats[cat!.parentId];
    final sens = racine?.genre != Genre.interne
        ? null
        : SensInterne.values.where((s) => sousCategorieInterne(s) == cat!.nom).firstOrNull;
    var suivies = 0;
    await db.transaction((t) async {
      await t.update('operations', {'categorie_id': categorieId, 'origine': Origine.main.name, 'interne': sens?.name, 'pointee': 1},
          where: 'id = ?', whereArgs: [id]);
      if (sens != null) await t.delete('liens', where: 'entree_id = ? OR depense_id = ?', whereArgs: [id, id]);
      if (!apprendre || op.interne != null) return;
      final motif = motifAApprendre(op.libelle);
      if (motif == null) return;
      await t.insert('regles', {'motif': motif, 'categorie_id': categorieId},
          conflictAlgorithm: ConflictAlgorithm.replace);
      final autres = await t.query('operations',
          columns: ['id', 'libelle'], where: "origine != 'main' AND interne IS NULL AND id != ?", whereArgs: [id]);
      for (final a in autres) {
        if (contient(normaliser(a['libelle']! as String), motif, motEntier: true)) {
          await t.update('operations', {'categorie_id': categorieId, 'origine': Origine.regle.name},
              where: 'id = ?', whereArgs: [a['id']]);
          suivies++;
        }
      }
    });
    return suivies;
  }

  /// Marque une opération comme virement entre ses comptes, dans ce sens :
  /// elle sort du budget. Pour l'inverse, la reclasser dans une catégorie.
  Future<void> marquerInterne(int id, SensInterne sens) async {
    final idDe = await _categories.resolveur();
    final categorie = idDe('Virements internes', sousCategorieInterne(sens));
    if (categorie == null) return;
    await (await _db).transaction((t) async {
      await t.update(
        'operations',
        {'categorie_id': categorie, 'origine': Origine.main.name, 'interne': sens.name, 'pointee': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      // Un virement entre ses comptes ne rembourse rien et n'est pas
      // remboursé : ses liens n'ont plus de sens.
      await t.delete('liens', where: 'entree_id = ? OR depense_id = ?', whereArgs: [id, id]);
    });
  }

  /// Les opérations que rien n'a su reconnaître : à toi de dire ce
  /// qu'elles sont. Celles déjà liées à un remboursement n'y sont plus :
  /// en les liant, tu as déjà dit ce qu'elles étaient.
  Future<List<Operation>> aVerifier() async {
    final l = await (await _db).query(
      'operations',
      where: "origine = ? AND interne IS NULL AND masquee = 0 "
          'AND id NOT IN (SELECT entree_id FROM liens) AND id NOT IN (SELECT depense_id FROM liens)',
      whereArgs: [Origine.defaut.name],
      orderBy: 'le DESC, id DESC',
    );
    return l.map(Operation.lire).toList();
  }

  /// Garde la catégorie proposée : l'opération quitte la liste à vérifier.
  Future<void> valider(int id) async {
    await (await _db).update('operations', {'origine': Origine.main.name, 'pointee': 1}, where: 'id = ?', whereArgs: [id]);
  }

  static const _nomMarchand = 'nom:';

  /// Donne un nom à une opération, et à toutes celles du même marchand,
  /// passées et à venir. Un nom vide rend celui tiré du libellé.
  Future<void> renommer(int id, String nom) async {
    final op = await une(id);
    if (op == null) return;
    final cle = cleMarchand(op.libelle);
    final valeur = nom.trim().isEmpty ? null : nom.trim();
    final db = await _db;
    // Un chèque ou un retrait n'a pas de marchand : renommer l'un ne
    // renomme pas tous les autres.
    if (sansMarchand(op.libelle)) {
      await db.update('operations', {'nom': valeur}, where: 'id = ?', whereArgs: [id]);
      return;
    }
    await db.transaction((t) async {
      final toutes = await t.query('operations', columns: ['id', 'libelle']);
      for (final r in toutes) {
        if (cleMarchand(r['libelle']! as String) == cle) {
          await t.update('operations', {'nom': valeur}, where: 'id = ?', whereArgs: [r['id']]);
        }
      }
      await t.insert('reglages', {'cle': '$_nomMarchand$cle', 'valeur': valeur}, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Ajoute une dépense payée en espèces : sur le compte courant, sans
  /// identifiant bancaire, déjà vérifiée puisque tu l'as saisie.
  Future<int> ajouterEspeces({required DateTime le, required String nom, required int centimes, required int categorieId, String? note}) async {
    final courant = await const DepotComptes().courant();
    return (await _db).insert('operations', {
      'compte_id': courant.id,
      'le': _date(le),
      'libelle': 'ESPECES ${normaliser(nom)}',
      'nom': nom,
      'montant_centimes': -centimes.abs(),
      'categorie_id': categorieId,
      'origine': Origine.main.name,
      'note': note,
      'pointee': 1,
      'especes': 1,
    });
  }

  /// Supprime une opération saisie à la main. Celles de la banque restent.
  Future<void> supprimerManuelle(int id) async {
    await (await _db).delete('operations', where: 'id = ? AND uid_banque IS NULL', whereArgs: [id]);
  }

  /// Cherche dans toutes les opérations, depuis la première : le nom, le
  /// libellé, la note, ou le montant s'il s'agit d'un nombre.
  Future<List<Operation>> chercher(String texte, {int? centimes}) async {
    // Un « % » ou un « _ » tapé se cherche tel quel.
    String echappe(String s) => s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
    final t = '%${echappe(texte.trim())}%';
    final n = '%${echappe(normaliser(texte))}%';
    final l = await (await _db).query(
      'operations',
      where: r"nom LIKE ? ESCAPE '\' OR libelle LIKE ? ESCAPE '\' OR note LIKE ? ESCAPE '\'"
          '${centimes != null ? ' OR ABS(montant_centimes) = ?' : ''}',
      whereArgs: [t, n, t, if (centimes != null) centimes.abs()],
      orderBy: 'le DESC, id DESC',
      limit: 300,
    );
    return l.map(Operation.lire).toList();
  }

  /// Pointe une opération : tu as vérifié qu'elle est bien classée.
  Future<void> pointer(int id, bool pointee) async {
    await (await _db).update('operations', {'pointee': pointee ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  /// Les entrées d'argent qui peuvent rembourser une dépense, avec ce qui
  /// reste de chacune une fois ôtées ses parts sur d'autres dépenses :
  /// reçues de deux mois avant à deux mois après elle, hors virements
  /// internes. Celles déjà entièrement réparties ailleurs y sont aussi,
  /// avec un reste à zéro : l'écran les grise plutôt que de les cacher.
  /// Celles déjà liées à la dépense y sont toujours, même loin d'elle.
  Future<List<(Operation, int)>> remboursementsPossibles(Operation depense) async {
    final db = await _db;
    final l = await db.query(
      'operations',
      where: '(montant_centimes > 0 AND interne IS NULL AND le >= ? AND le < ?) '
          'OR id IN (SELECT entree_id FROM liens WHERE depense_id = ?)',
      whereArgs: [
        _date(depense.le.subtract(const Duration(days: 62))),
        _date(depense.le.add(const Duration(days: 63))),
        depense.id,
      ],
      orderBy: 'le DESC, id DESC',
    );
    final ailleurs = {
      for (final r in await db.rawQuery(
          'SELECT entree_id, SUM(montant_centimes) AS s FROM liens WHERE depense_id != ? GROUP BY entree_id', [depense.id]))
        r['entree_id']! as int: (r['s']! as num).toInt(),
    };
    return [
      for (final o in l.map(Operation.lire))
        (o, (o.montantCentimes - (ailleurs[o.id] ?? 0)).clamp(0, o.montantCentimes)),
    ];
  }

  /// Les dépenses qu'une entrée peut rembourser, de deux mois avant à un
  /// mois après elle : l'achat peut précéder le remboursement ou le suivre.
  /// Celles déjà liées à l'entrée y sont toujours. Avec, pour chacune, ce
  /// que d'autres entrées en remboursent déjà.
  Future<List<(Operation, int)>> depensesRemboursables(Operation entree) async {
    final db = await _db;
    final l = await db.query(
      'operations',
      where: '(montant_centimes < 0 AND interne IS NULL AND le >= ? AND le < ?) '
          'OR id IN (SELECT depense_id FROM liens WHERE entree_id = ?)',
      whereArgs: [
        _date(entree.le.subtract(const Duration(days: 62))),
        _date(entree.le.add(const Duration(days: 32))),
        entree.id,
      ],
      orderBy: 'le DESC, id DESC',
    );
    final ailleurs = {
      for (final r in await db.rawQuery(
          'SELECT depense_id, SUM(montant_centimes) AS s FROM liens WHERE entree_id != ? GROUP BY depense_id', [entree.id]))
        r['depense_id']! as int: (r['s']! as num).toInt(),
    };
    return [for (final o in l.map(Operation.lire)) (o, ailleurs[o.id] ?? 0)];
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
        if (o.interne == null && !o.masquee) Passage(o.libelle, o.le, o.montantCentimes, o.id),
    ];
    final choix = <String, Frequence?>{
      for (final e in (await const DepotReglages().commencantPar(_repetition)).entries)
        e.key.substring(_repetition.length): Frequence.values.where((f) => f.name == e.value).firstOrNull,
    };
    // Une récurrence porte le nom choisi pour son marchand, s'il y en a un.
    final titres = {for (final o in ops) o.id: o.titre};
    return [
      for (final r in appliquerChoix(
        detecterRecurrences(passages).where((r) => !forcees.contains(r.cle)).toList(),
        passages,
        choix,
      ))
        Recurrence(
          cle: r.cle,
          libelle: titres[r.derniereId] ?? r.libelle,
          montantCentimes: r.montantCentimes,
          frequence: r.frequence,
          derniere: r.derniere,
          prochaine: r.prochaine,
          nombre: r.nombre,
          derniereId: r.derniereId,
        ),
    ];
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
    // Tout se lit et se vérifie dans la transaction, par [t] : un lien
    // posé au même moment ailleurs ne peut plus faire dépasser la dépense.
    await db.transaction((t) async {
      Future<Operation?> une(int id) async {
        final l = await t.query('operations', where: 'id = ?', whereArgs: [id]);
        return l.isEmpty ? null : Operation.lire(l.first);
      }

      final entree = await une(entreeId);
      if (entree == null || !entree.entree) throw ArgumentError('Pas une entrée d\'argent.');
      final total = parDepense.values.fold(0, (a, b) => a + b);
      if (total > entree.montantCentimes) {
        throw ArgumentError('La répartition dépasse le montant reçu.');
      }
      for (final e in parDepense.entries) {
        final d = await une(e.key);
        if (d == null || d.entree) throw ArgumentError('Pas une dépense.');
        final ailleurs = await _ailleurs(t, depense: e.key, sauf: entreeId);
        if (e.value <= 0 || e.value + ailleurs > -d.montantCentimes) {
          throw ArgumentError(ailleurs > 0
              ? '« ${d.titre} » est déjà remboursée ailleurs : il n\'en reste que ${euros(-d.montantCentimes - ailleurs)}.'
              : 'La part de « ${d.titre} » dépasse la dépense.');
        }
      }
      await t.delete('liens', where: 'entree_id = ?', whereArgs: [entreeId]);
      for (final e in parDepense.entries) {
        await t.insert('liens', {'entree_id': entreeId, 'depense_id': e.key, 'montant_centimes': e.value});
      }
    });
  }

  /// Fixe toutes les entrées qui remboursent une dépense : six amis qui
  /// rendent chacun 23 € d'une sortie à 192 €. Remplace les liens de la
  /// dépense ; ceux de ces entrées vers d'autres dépenses ne bougent pas.
  /// Refuse ce qui dépasse la dépense, ou ce qui reste d'une entrée. Une
  /// table vide délie la dépense de tout.
  Future<void> rembourserPar(int depenseId, Map<int, int> parEntree) async {
    final db = await _db;
    // Tout se lit et se vérifie dans la transaction, par [t], comme dans
    // [repartir] : passer par la base attendrait la fin de celle-ci.
    await db.transaction((t) async {
      Future<Operation?> une(int id) async {
        final l = await t.query('operations', where: 'id = ?', whereArgs: [id]);
        return l.isEmpty ? null : Operation.lire(l.first);
      }

      final depense = await une(depenseId);
      if (depense == null || depense.entree) throw ArgumentError('Pas une dépense.');
      final total = parEntree.values.fold(0, (a, b) => a + b);
      if (total > -depense.montantCentimes) {
        throw ArgumentError('Les remboursements dépassent la dépense de ${euros(total + depense.montantCentimes)}.');
      }
      for (final e in parEntree.entries) {
        final entree = await une(e.key);
        if (entree == null || !entree.entree) throw ArgumentError('Pas une entrée d\'argent.');
        final ailleurs = await _ailleurs(t, entree: e.key, sauf: depenseId);
        if (e.value <= 0 || e.value + ailleurs > entree.montantCentimes) {
          throw ArgumentError(ailleurs > 0
              ? '« ${entree.titre} » rembourse déjà d\'autres dépenses : il n\'en reste que ${euros(entree.montantCentimes - ailleurs)}.'
              : 'La part de « ${entree.titre} » dépasse le montant reçu.');
        }
      }
      await t.delete('liens', where: 'depense_id = ?', whereArgs: [depenseId]);
      for (final e in parEntree.entries) {
        await t.insert('liens', {'entree_id': e.key, 'depense_id': depenseId, 'montant_centimes': e.value});
      }
    });
  }

  /// Lie une dépense à l'entrée qui la rembourse, pour ce qui reste de
  /// l'une et de l'autre, à la place de [ancienne] s'il y en avait une.
  /// Les autres entrées qui remboursent la même dépense restent liées.
  /// Sans [nouvelle], délie seulement [ancienne].
  Future<void> rembourser(int depenseId, {int? ancienne, int? nouvelle}) async {
    final db = await _db;
    const ops = DepotOperations();
    final d = await ops.une(depenseId);
    if (d == null || d.entree) throw ArgumentError('Pas une dépense.');
    // Lue avant la transaction : passer par la base pendant qu'elle est
    // ouverte attendrait sa fin, qui attendrait cette lecture, et plus
    // rien ne répondrait jusqu'au redémarrage.
    final e = nouvelle == null ? null : await ops.une(nouvelle);
    if (nouvelle != null && (e == null || !e.entree)) throw ArgumentError('Pas une entrée d\'argent.');
    await db.transaction((t) async {
      if (ancienne != null) {
        await t.delete('liens', where: 'depense_id = ? AND entree_id = ?', whereArgs: [depenseId, ancienne]);
      }
      if (e == null) return;
      final deja = await _ailleurs(t, entree: e.id, sauf: depenseId);
      final dejaDepense = await _ailleurs(t, depense: depenseId, sauf: e.id);
      final part = [-d.montantCentimes - dejaDepense, e.montantCentimes - deja].reduce((a, b) => a < b ? a : b);
      if (part <= 0) {
        throw ArgumentError(dejaDepense >= -d.montantCentimes
            ? 'Cette dépense est déjà entièrement remboursée.'
            : 'Ce remboursement est déjà entièrement réparti.');
      }
      await t.insert('liens', {'entree_id': e.id, 'depense_id': depenseId, 'montant_centimes': part},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Ce que d'autres entrées que [sauf] remboursent déjà de [depense], ou
  /// ce que [entree] rembourse déjà à d'autres dépenses que [sauf].
  static Future<int> _ailleurs(DatabaseExecutor db, {int? depense, int? entree, required int sauf}) async {
    final r = depense != null
        ? await db.rawQuery('SELECT COALESCE(SUM(montant_centimes), 0) AS s FROM liens WHERE depense_id = ? AND entree_id != ?', [depense, sauf])
        : await db.rawQuery('SELECT COALESCE(SUM(montant_centimes), 0) AS s FROM liens WHERE entree_id = ? AND depense_id != ?', [entree, sauf]);
    return (r.first['s'] as num).toInt();
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

  /// Le début du mois suit-il le salaire tout seul ? Oui, tant qu'on n'a
  /// pas choisi un jour à la main.
  Future<bool> debutMoisAuto() async => await lire('debut_mois_auto') != '0';

  /// Le jour où commence le mois budgétaire, 1 par défaut.
  Future<int> debutMois() async => int.tryParse(await lire('debut_mois') ?? '') ?? 1;
}

// ------------------------------------------------------------------ bilan

class DepotBilan {
  const DepotBilan();

  Future<Bilan> du(Mois mois, {Calendrier? calendrier}) async {
    const ops = DepotOperations();
    const liens = DepotLiens();
    final cal = calendrier ?? await ops.calendrier();
    final duMois = await ops.duMois(mois, cal);
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

    // Les retraits et les dépenses en espèces de quatre mois avant à deux
    // mois après : un retrait de ce mois-ci peut être dépensé le suivant,
    // et une dépense de ce mois-ci puiser dans un retrait d'avant.
    final categories = await const DepotCategories().parId();
    final (de, a) = cal.bornes(mois);
    final autour = (await ops.entre(de.subtract(const Duration(days: 124)), a.add(const Duration(days: 63))))
        .where((o) => !o.masquee && o.montantCentimes < 0)
        .toList();
    final financement = financementEspeces(
      [for (final o in autour) if (categories[o.categorieId]?.nom == "Retraits d'espèces") o],
      [for (final o in autour) if (o.especes) o],
    );

    return calculerBilan(
      mois: mois,
      operations: [...duMois, ...autres],
      liens: lies,
      categories: categories,
      debut: cal.debut,
      calendrier: cal,
      retraitsDepenses: financement,
    );
  }
}

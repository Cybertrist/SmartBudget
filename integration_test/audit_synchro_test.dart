// Audit de la couche données : synchronisations successives, liens,
// livrets, règles, bilan, sauvegarde et écritures concurrentes.
//
//   flutter test integration_test/audit_synchro_test.dart -d <émulateur>
//
// Comme donnees_test.dart, ces tests effacent la base de l'application :
// à lancer sur un émulateur, jamais sur le téléphone qui porte les vrais
// comptes. Chaque test décrit le comportement attendu : un test rouge est
// un défaut de l'application, pas du test.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartbudget/domaine/classement.dart';
import 'package:smartbudget/domaine/modeles.dart';
import 'package:smartbudget/domaine/mois.dart';
import 'package:smartbudget/donnees/base.dart';
import 'package:smartbudget/donnees/depots.dart';
import 'package:smartbudget/donnees/sauvegarde.dart';
import 'package:smartbudget/security/key_vault.dart';

const _categories = DepotCategories();
const _comptes = DepotComptes();
const _ops = DepotOperations();
const _liens = DepotLiens();
const _bilan = DepotBilan();

/// Rien ne doit geler : toute attente sur la base a une limite.
const _limite = Duration(seconds: 30);
Future<T> _w<T>(Future<T> f) => f.timeout(_limite);

/// Un an d'opérations à importer : lent, mais doit finir.
Future<T> _long<T>(Future<T> f) => f.timeout(const Duration(minutes: 2));

const _lent = Timeout(Duration(minutes: 3));

/// Une opération comptabilisée, avec la référence de la banque.
OperationBrute _b(String uid, String date, String libelle, double euros) => OperationBrute(
      uidBanque: uid,
      le: DateTime.parse(date),
      libelle: libelle,
      montantCentimes: (euros * 100).round(),
    );

/// Une opération en attente, avec l'empreinte que lui donne
/// EnableBanking._operation : « attente-date-centimes-libellé ».
OperationBrute _att(String date, String libelle, double euros, {int n = 1}) {
  final c = (euros * 100).round();
  final base = 'attente-$date-$c-$libelle';
  return OperationBrute(
    uidBanque: n == 1 ? base : '$base-$n',
    le: DateTime.parse(date),
    libelle: libelle,
    montantCentimes: c,
    enAttente: true,
  );
}

Future<int> _idDe(String categorie, String sous) async => (await _categories.resolveur())(categorie, sous)!;

Future<List<Operation>> _toutes() => _w(_ops.entre(DateTime(2000), DateTime(2100)));

Future<List<Operation>> _dont(String texte) async =>
    (await _toutes()).where((o) => o.libelle.contains(texte)).toList();

Future<Operation> _une(String texte) async => (await _dont(texte)).single;

Future<int> _compte() async => (await _w(_comptes.courant())).id;

Future<void> _neuf() async {
  await Base.instance.effacer();
  await KeyVault.instance.unlock();
}

/// Toutes les tables, pour comparer avant et après une restauration.
Future<String> _vidage() async {
  final db = await Base.instance.db;
  return jsonEncode({
    for (final t in ['categories', 'comptes', 'operations', 'regles', 'liens', 'reglages'])
      t: await db.rawQuery('SELECT * FROM $t ORDER BY 1, 2'),
  });
}

/// Un an d'opérations réalistes, du 1er octobre 2025 au 25 septembre 2026 :
/// salaire, loyer, abonnements, virements au livret, retraits, et une
/// quarantaine de paiements par carte chaque mois, dont deux cafés
/// identiques le même jour.
List<OperationBrute> _uneAnnee(Random r, {String prefixe = 'ref'}) {
  const marchands = [
    ('PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES', 15, 120),
    ('PAIEMENT PAR CARTE X4057 LIDL VANNES', 10, 80),
    ('PAIEMENT PAR CARTE X4057 BOULANGERIE DU PORT', 1, 8),
    ('PAIEMENT PAR CARTE X4057 UBER EATS', 12, 35),
    ('PAIEMENT PAR CARTE X4057 SNCF VOYAGEURS', 20, 90),
    ('PRLV SEPA AMAZON PAYMENTS EUROPE', 8, 60),
    ('PAIEMENT PAR CARTE X4057 TOTAL ACCESS VANNES', 30, 70),
    ('PAIEMENT PAR CARTE X4057 BOUTIQUE INCONNUE', 5, 50),
  ];
  String j(int v) => v.toString().padLeft(2, '0');
  final sortie = <OperationBrute>[];
  var i = 0;
  for (var m = 0; m < 12; m++) {
    final an = m < 3 ? 2025 : 2026;
    final mo = m < 3 ? 10 + m : m - 2;
    String d(int jour) => '$an-${j(mo)}-${j(jour)}';
    sortie
      ..add(_b('$prefixe-${i++}', d(5), 'VIR SEPA SALAIRE ALTERNANCE ${j(mo)}', 1500))
      ..add(_b('$prefixe-${i++}', d(3), 'PRLV SEPA LOYER FONCIA ${j(mo)}', -550))
      ..add(_b('$prefixe-${i++}', d(10), 'PRLV SEPA FREE MOBILE', -17.99))
      ..add(_b('$prefixe-${i++}', d(6), 'VIR VERS LIVRET CMB DE CARTE BANCAIRE', -100))
      ..add(_b('$prefixe-${i++}', d(15), 'RETRAIT DAB VANNES ${j(15)}/${j(mo)}', -40));
    // Deux cafés au même prix le même jour, sans référence : la seconde
    // empreinte prend un numéro, comme dans EnableBanking.operations.
    final cafe = 'eb-${d(12)}-250-cafe';
    sortie
      ..add(_b(cafe, d(12), 'PAIEMENT PAR CARTE X4057 CAFE DU COIN 11/${j(mo)}', -2.5))
      ..add(_b('$cafe-2', d(12), 'PAIEMENT PAR CARTE X4057 CAFE DU COIN 11/${j(mo)}', -2.5));
    for (var k = 0; k < 43; k++) {
      final (lib, min, max) = marchands[r.nextInt(marchands.length)];
      final jour = 1 + r.nextInt(m == 11 ? 25 : 28);
      final euros = -(min + r.nextInt((max - min) * 100) / 100);
      sortie.add(_b('$prefixe-${i++}', d(jour), '$lib ${j(jour)}/${j(mo)}', euros));
    }
  }
  return sortie;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await KeyVault.instance.destroy();
    await _neuf();
  });

  setUp(_neuf);

  // ------------------------------------------------------------------ A
  group('synchronisations successives', () {
    test('A1 une attente dont le montant change en passant (pourboire) garde note, catégorie, mois et lien', () async {
      final compte = await _compte();
      final ami = _b('ref-ami', '2026-09-13', 'VIR SEPA RECU DE M DUPONT', 15);
      await _w(_ops.importer(compte, [ami, _att('2026-09-12', 'RESTAURANT LE PORT', -30)], depuis: DateTime(2026, 9, 1)));
      final resto = await _une('RESTAURANT LE PORT');
      final virement = await _une('M DUPONT');
      final categorie = await _idDe('Restaurants et sorties', 'Restaurant');
      await _w(_ops.reclasser(resto.id, categorie, apprendre: false));
      await _w(_ops.modifier(resto.id, note: 'anniversaire de Léa', moisCompte: const Mois(2026, 10)));
      await _w(_liens.rembourser(resto.id, nouvelle: virement.id));

      // Comptabilisée deux jours plus tard, avec le pourboire.
      await _w(_ops.importer(
          compte,
          [ami, _b('ref-resto', '2026-09-14', 'PAIEMENT PAR CARTE X4057 RESTAURANT LE PORT 12/09', -34.5)],
          depuis: DateTime(2026, 9, 7)));

      final restes = await _dont('RESTAURANT LE PORT');
      expect(restes, hasLength(1), reason: 'Une seule opération pour ce repas.');
      final apres = restes.single;
      expect(apres.enAttente, isFalse);
      expect(apres.note, 'anniversaire de Léa', reason: 'La note écrite sur l\'attente ne doit pas se perdre.');
      expect(apres.moisCompte, '2026-10');
      expect(apres.categorieId, categorie);
      expect(await _w(_liens.concernant([apres.id])), hasLength(1), reason: 'Le remboursement de M. Dupont reste lié.');
    });

    test('A2 une attente dont le libellé change garde son identifiant, sa note, son nom et son lien', () async {
      final compte = await _compte();
      final ami = _b('ref-ami', '2026-09-13', 'VIR SEPA RECU DE M DUPONT', 20);
      expect(await _w(_ops.importer(compte, [ami, _att('2026-09-12', 'CARREFOUR', -42.1)])), 2);
      final avant = await _une('CARREFOUR');
      await _w(_ops.modifier(avant.id, note: 'pour la fête'));
      await _w(_ops.renommer(avant.id, 'Carrefour du port'));
      await _w(_liens.rembourser(avant.id, nouvelle: (await _une('DUPONT')).id));

      final n = await _w(_ops.importer(
          compte,
          [ami, _b('ref-carrefour', '2026-09-13', 'PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09', -42.1)],
          depuis: DateTime(2026, 9, 6)));
      expect(n, 0, reason: 'Rien de neuf à annoncer : elle était déjà là, en attente.');
      final apres = await _une('CARREFOUR');
      expect(apres.id, avant.id);
      expect(apres.enAttente, isFalse);
      expect(apres.libelle, 'PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09');
      expect(apres.uidBanque, 'ref-carrefour');
      expect(apres.note, 'pour la fête');
      expect(apres.nom, 'Carrefour du port');
      expect(apres.categorieId, await _idDe('Courses', 'Supermarché'));
      expect(await _w(_liens.concernant([apres.id])), hasLength(1));
    });

    test('A3 deux attentes identiques : l\'une passe, puis l\'autre, sans doublon ni note perdue', () async {
      final compte = await _compte();
      final c1 = _att('2026-09-20', 'CAFE DU PORT', -2.5);
      final c2 = _att('2026-09-20', 'CAFE DU PORT', -2.5, n: 2);
      expect(await _w(_ops.importer(compte, [c1, c2])), 2);
      final deux = await _dont('CAFE DU PORT');
      final ids = deux.map((o) => o.id).toSet();
      await _w(_ops.modifier(deux[0].id, note: 'mon café'));
      await _w(_ops.modifier(deux[1].id, note: 'café de Paul'));

      // La première passe ; la banque ne donne plus qu'une attente.
      await _w(_ops.importer(
          compte,
          [_b('ref-cafe-1', '2026-09-21', 'PAIEMENT PAR CARTE X4057 CAFE DU PORT 20/09', -2.5), c1],
          depuis: DateTime(2026, 9, 14)));
      var l = await _dont('CAFE DU PORT');
      expect(l, hasLength(2));
      expect(l.where((o) => o.enAttente), hasLength(1));
      expect(l.map((o) => o.id).toSet(), ids);
      expect(l.map((o) => o.note).toSet(), {'mon café', 'café de Paul'});

      // La seconde passe à son tour.
      await _w(_ops.importer(
          compte,
          [
            _b('ref-cafe-1', '2026-09-21', 'PAIEMENT PAR CARTE X4057 CAFE DU PORT 20/09', -2.5),
            _b('ref-cafe-2', '2026-09-22', 'PAIEMENT PAR CARTE X4057 CAFE DU PORT 20/09', -2.5),
          ],
          depuis: DateTime(2026, 9, 15)));
      l = await _dont('CAFE DU PORT');
      expect(l, hasLength(2));
      expect(l.where((o) => o.enAttente), isEmpty);
      expect(l.map((o) => o.id).toSet(), ids);
      expect(l.map((o) => o.note).toSet(), {'mon café', 'café de Paul'});
    });

    test('A4 une attente annulée s\'efface avec ses liens, sauf si la banque n\'a pas donné la liste', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('ref-sal', '2026-09-05', 'VIR SEPA SALAIRE SEPTEMBRE', 1200),
        _b('ref-ami', '2026-09-19', 'VIR SEPA RECU DE M DUPONT', 60),
        _att('2026-09-18', 'ZALANDO', -60),
      ]));
      final zalando = await _une('ZALANDO');
      await _w(_liens.rembourser(zalando.id, nouvelle: (await _une('DUPONT')).id));

      // La banque n'a pas pu donner les attentes : rien ne s'efface.
      await _w(_ops.importer(compte, [], attenteLue: false, depuis: DateTime(2026, 9, 12)));
      expect(await _dont('ZALANDO'), hasLength(1));

      // Elle les a données, et ZALANDO n'y est plus : annulée.
      await _w(_ops.importer(compte, [], depuis: DateTime(2026, 9, 12)));
      expect(await _dont('ZALANDO'), isEmpty);
      expect(await _w(_liens.concernant([(await _une('DUPONT')).id])), isEmpty);
      expect(await _dont('SALAIRE'), hasLength(1));
      expect(await _dont('DUPONT'), hasLength(1));
    });

    test('A5 une attente de plus de 7 jours (caution d\'hôtel) comptabilisée hors fenêtre ne compte pas deux fois', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_att('2026-09-01', 'HOTEL IBIS NANTES', -200)], depuis: DateTime(2026, 8, 25)));
      // Synchros suivantes : la fenêtre part d'une semaine avant la
      // précédente ; l'hôtel est débité au départ, onze jours après.
      await _w(_ops.importer(
          compte,
          [_b('ref-hotel', '2026-09-12', 'PAIEMENT PAR CARTE X4057 HOTEL IBIS NANTES 01/09', -200)],
          depuis: DateTime(2026, 9, 5)));
      expect(await _dont('HOTEL IBIS'), hasLength(1), reason: 'Un seul séjour payé.');
      expect((await _w(_bilan.du(const Mois(2026, 9)))).sorties, 20000);
    });

    test('A6 une attente annulée plus vieille que la fenêtre ne reste pas pour toujours', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_att('2026-09-01', 'LOCATION VOITURE HERTZ', -300)], depuis: DateTime(2026, 8, 25)));
      // La caution est levée ; les synchros suivantes ne la donnent plus.
      // La synchro redemande les attentes depuis la plus ancienne connue
      // (ConnexionBanque.synchroniser) : c'est cette date qui arrive ici.
      final depuis = (await _ops.plusAncienneEnAttente())!.subtract(const Duration(days: 1));
      await _w(_ops.importer(compte, [], depuis: depuis));
      expect(await _dont('HERTZ'), isEmpty, reason: 'Une caution levée ne doit pas peser sur le budget pour toujours.');
    });

    test('A7 synchro relancée trois fois : rien ne double, rien ne bouge', () async {
      final compte = await _compte();
      final lot = [
        _b('ref-1', '2026-09-02', 'PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 01/09', -64.12),
        _b('ref-2', '2026-09-05', 'VIR SEPA SALAIRE SEPTEMBRE', 1250),
        _b('ref-3', '2026-09-07', 'VIR VERS LIVRET CMB DE CARTE BANCAIRE', -200),
        _att('2026-09-24', 'UBER EATS', -18.4),
        _att('2026-09-24', 'UBER EATS', -18.4, n: 2),
        _att('2026-09-25', 'SNCF', -45),
      ];
      expect(await _w(_ops.importer(compte, lot, depuis: DateTime(2026, 9, 1))), 6);
      final avant = {for (final o in await _toutes()) o.id: o.uidBanque};
      await _w(_ops.modifier(avant.keys.first, note: 'n'));
      expect(await _w(_ops.importer(compte, lot, depuis: DateTime(2026, 9, 1))), 0);
      expect(await _w(_ops.importer(compte, lot, depuis: DateTime(2026, 9, 1))), 0);
      final apres = {for (final o in await _toutes()) o.id: o.uidBanque};
      expect(apres, avant);
      expect((await _w(_ops.une(avant.keys.first)))!.note, 'n');
    });

    test('A8 une comptabilisée d\'un autre marchand ne prend pas la ligne d\'une attente annulée du même montant', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_att('2026-09-20', 'CARREFOUR VANNES', -10)]));
      final carrefour = await _une('CARREFOUR');
      await _w(_ops.modifier(carrefour.id, note: 'courses du week-end'));
      await _w(_ops.renommer(carrefour.id, 'Carrefour'));
      // Carrefour annulé ; un prélèvement PayPal de 10 € arrive, jamais vu en attente.
      await _w(_ops.importer(compte, [_b('ref-paypal', '2026-09-22', 'PRLV SEPA PAYPAL EUROPE', -10)], depuis: DateTime(2026, 9, 15)));
      final paypal = await _une('PAYPAL');
      expect(paypal.note, isNull, reason: 'La note de Carrefour ne passe pas sur PayPal.');
      expect(paypal.nom, isNull, reason: 'PayPal ne s\'affiche pas « Carrefour ».');
    });

    test('A9 sans la liste des attentes, une comptabilisée ne vole pas une attente toujours en cours', () async {
      final compte = await _compte();
      final boulangerie = _att('2026-09-20', 'BOULANGERIE DU PORT', -3);
      await _w(_ops.importer(compte, [boulangerie]));
      final b = await _une('BOULANGERIE');
      await _w(_ops.modifier(b.id, note: 'croissants'));
      // Synchro sans les attentes (attenteLue faux) : un café comptabilisé
      // du même prix, qui n'a jamais été en attente.
      await _w(_ops.importer(compte, [_b('ref-cafe', '2026-09-21', 'PAIEMENT PAR CARTE X4057 CAFE DU COIN 21/09', -3)],
          attenteLue: false, depuis: DateTime(2026, 9, 14)));
      // Puis une synchro normale : la boulangerie est toujours en attente.
      await _w(_ops.importer(compte, [_b('ref-cafe', '2026-09-21', 'PAIEMENT PAR CARTE X4057 CAFE DU COIN 21/09', -3), boulangerie],
          depuis: DateTime(2026, 9, 14)));
      final l = await _dont('BOULANGERIE');
      expect(l, hasLength(1));
      expect(l.single.note, 'croissants', reason: 'La note reste sur la boulangerie.');
      expect((await _une('CAFE DU COIN')).note, isNull);
    });

    test('A10 un an d\'historique (600 opérations), puis une synchro qui chevauche', () async {
      final compte = await _compte();
      final annee = _uneAnnee(Random(42));
      final attentes = [
        _att('2026-09-22', 'CARREFOUR MARKET VANNES', -23.17),
        _att('2026-09-23', 'UBER EATS', -8.4),
        _att('2026-09-24', 'TOTAL ACCESS VANNES', -61.05),
        _att('2026-09-25', 'BOULANGERIE DU PORT', -4.99),
        _att('2026-09-25', 'SNCF VOYAGEURS', -12.3),
      ];
      final chrono = Stopwatch()..start();
      final n1 = await _long(_ops.importer(compte, [...annee, ...attentes], depuis: DateTime(2025, 9, 26)));
      final duree1 = chrono.elapsedMilliseconds;
      expect(n1, annee.length + attentes.length);
      final total1 = (await _toutes()).length;
      expect(total1, n1);

      // Une semaine plus tard : les comptabilisées d'après le 19 reviennent,
      // trois attentes passent, deux restent, quatre nouvelles.
      final depuis = DateTime(2026, 9, 19);
      final lot = [
        ...annee.where((o) => !o.le.isBefore(depuis)),
        _b('ref-p0', '2026-09-23', 'PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 22/09', -23.17),
        _b('ref-p1', '2026-09-24', 'PAIEMENT PAR CARTE X4057 UBER EATS 23/09', -8.4),
        _b('ref-p2', '2026-09-25', 'PAIEMENT PAR CARTE X4057 TOTAL ACCESS VANNES 24/09', -61.05),
        attentes[3],
        attentes[4],
        for (var k = 0; k < 4; k++) _b('ref-n$k', '2026-09-26', 'PAIEMENT PAR CARTE X4057 LIDL VANNES 26/09', -(10 + k).toDouble()),
      ];
      chrono.reset();
      final n2 = await _long(_ops.importer(compte, lot, depuis: depuis));
      final duree2 = chrono.elapsedMilliseconds;
      expect(n2, 4);
      final toutes = await _toutes();
      expect(toutes, hasLength(total1 + 4));
      expect(toutes.where((o) => o.enAttente), hasLength(2));
      expect(toutes.map((o) => o.uidBanque).toSet(), hasLength(toutes.length));
      // ignore: avoid_print
      print('A10 : import de $n1 opérations en $duree1 ms, puis synchro en $duree2 ms');

      // Chaque mois, le bilan retrouve ce que disent les opérations.
      final cats = await _categories.parId();
      var attendu = 0;
      for (final o in toutes) {
        final c = cats[o.categorieId]!;
        final top = c.parentId == null ? c : cats[c.parentId]!;
        if (top.genre == Genre.revenu || top.genre == Genre.depense) attendu += o.montantCentimes;
      }
      var obtenu = 0;
      for (var m = 0; m < 12; m++) {
        final b = await _w(_bilan.du(Mois(m < 3 ? 2025 : 2026, m < 3 ? 10 + m : m - 2)));
        obtenu += b.solde + b.rembourses;
        expect(b.misDeCote, 10000, reason: 'Le virement mensuel au livret.');
      }
      expect(obtenu, attendu);
    }, timeout: _lent);
  });

  // ------------------------------------------------------------------ B
  group('livrets', () {
    test('B1 un virement au livret, en attente puis comptabilisé puis relu, compte une fois', () async {
      final compte = await _compte();
      final livret = await _w(_comptes.ajouterLivret(nom: 'Livret CMB', soldeCentimes: 100000, motif: 'LIVRET CMB'));
      await _w(_comptes.definirSolde(livret, 100000, le: DateTime(2026, 9, 1)));
      Future<int> solde() async => (await _comptes.tous()).singleWhere((c) => c.id == livret).soldeCentimes;

      await _w(_ops.importer(compte, [_att('2026-09-10', 'VIR VERS LIVRET CMB DE CARTE BANCAIRE', -200)]));
      expect(await solde(), 100000, reason: 'Pas tant qu\'il est en attente.');
      final lot = [
        _b('ref-v1', '2026-09-11', 'VIR VERS LIVRET CMB DE CARTE BANCAIRE', -200),
        _b('ref-v2', '2026-09-15', 'VIR VERS CARTE BANCAIRE DE LIVRET CMB', 50),
      ];
      await _w(_ops.importer(compte, lot, depuis: DateTime(2026, 9, 4)));
      expect(await solde(), 100000 + 20000 - 5000);
      await _w(_ops.importer(compte, lot, depuis: DateTime(2026, 9, 4)));
      await _w(_ops.importer(compte, lot, depuis: DateTime(2026, 9, 4)));
      expect(await solde(), 100000 + 20000 - 5000, reason: 'Une synchro relancée ne recompte pas.');
      expect(await _dont('LIVRET CMB'), hasLength(2));
    });

    test('B2 un virement antérieur au solde saisi ne le change pas', () async {
      final compte = await _compte();
      final livret = await _w(_comptes.ajouterLivret(nom: 'Livret CMB', soldeCentimes: 100000, motif: 'LIVRET CMB'));
      await _w(_comptes.definirSolde(livret, 100000, le: DateTime(2026, 9, 10)));
      await _w(_ops.importer(compte, [_b('ref-v1', '2026-09-05', 'VIR VERS LIVRET CMB DE CARTE BANCAIRE', -200)]));
      expect((await _comptes.tous()).singleWhere((c) => c.id == livret).soldeCentimes, 100000);
    });

    test('B3 deux livrets aux noms voisins (LDD et LDDS) : seul le bon bouge', () async {
      final compte = await _compte();
      final ldd = await _w(_comptes.ajouterLivret(nom: 'LDD', soldeCentimes: 50000));
      final ldds = await _w(_comptes.ajouterLivret(nom: 'LDDS', soldeCentimes: 70000));
      for (final l in [ldd, ldds]) {
        await _w(_comptes.definirSolde(l, l == ldd ? 50000 : 70000, le: DateTime(2026, 9, 1)));
      }
      await _w(_ops.importer(compte, [_b('ref-v', '2026-09-12', 'VIR VERS LDDS DE CARTE BANCAIRE', -100)]));
      final soldes = {for (final c in await _comptes.tous()) c.id: c.soldeCentimes};
      expect(soldes[ldds], 80000);
      expect(soldes[ldd], 50000, reason: 'Un virement vers le LDDS ne crédite pas le LDD.');
    });
  });

  // ------------------------------------------------------------------ C
  group('règles', () {
    test('C1 une règle apprise suit le mot entier : FREE ne range pas FREENOW', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('r1', '2026-09-02', 'PRLV SEPA FREE', -29.99),
        _b('r2', '2026-09-03', 'PAIEMENT CB FREENOW PARIS 02/09', -14),
      ]));
      final free = await _une('SEPA FREE');
      final avant = (await _une('FREENOW')).categorieId;
      final internet = await _idDe('Abonnements', 'Internet');
      await _w(_ops.reclasser(free.id, internet));
      expect((await _une('FREENOW')).categorieId, avant, reason: 'Une course FreeNow n\'est pas un abonnement Free.');
      // Et la même chose à l'import suivant, pour que les deux chemins s'accordent.
      await _w(_ops.importer(compte, [_b('r3', '2026-09-20', 'PAIEMENT CB FREENOW PARIS 19/09', -9)]));
      expect((await _une('19/09')).categorieId, isNot(internet));
    });

    test('C2 reparerRegles retire « N » et la ville apprise sur un retrait', () async {
      final compte = await _compte();
      final db = await Base.instance.db;
      final retraits = await _idDe('Retraits et virements', "Retraits d'espèces");
      final bars = await _idDe('Restaurants et sorties', 'Bars et clubs');
      // Ce qu'apprenait la version 1.2.0 en reclassant « REMISE CHEQUE N 8841207 »
      // et « RETRAIT DAB VANNES 12/09 ».
      await db.insert('regles', {'motif': 'N', 'categorie_id': bars});
      await db.insert('regles', {'motif': 'VANNES', 'categorie_id': retraits});
      await _w(_ops.importer(compte, [
        _b('r1', '2026-09-21', 'REMISE CHEQUE N 8841207', 500),
        _b('r2', '2026-09-02', 'PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 01/09', -64.12),
        _b('r3', '2026-09-12', 'RETRAIT DAB VANNES 12/09', -40),
      ]));
      expect((await _une('CARREFOUR')).categorieId, retraits, reason: 'Le défaut à réparer est bien là.');
      expect(await _w(_ops.reparerRegles()), greaterThan(0));
      final restantes = (await db.query('regles')).map((r) => r['motif']).toList();
      expect(restantes, isNot(contains('N')));
      expect(restantes, isNot(contains('VANNES')), reason: 'Une ville apprise sur un retrait est trop vague.');
      expect((await _une('CARREFOUR')).categorieId, await _idDe('Courses', 'Supermarché'));
      expect((await _une('RETRAIT DAB')).categorieId, retraits);
    });

    test('C3 reparerRegles garde les bonnes règles et ce qui est classé à la main', () async {
      final compte = await _compte();
      final db = await Base.instance.db;
      final bars = await _idDe('Restaurants et sorties', 'Bars et clubs');
      await _w(_ops.importer(compte, [
        _b('r1', '2026-08-10', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/08', -22),
        _b('r2', '2026-09-10', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/09', -31),
        _b('r3', '2026-09-21', 'REMISE CHEQUE N 8841207', 500),
      ]));
      await _w(_ops.reclasser((await _une('09/08')).id, bars));
      final cheque = await _une('REMISE CHEQUE');
      final cadeau = await _idDe('Autres revenus', 'Cadeaux reçus');
      await _w(_ops.reclasser(cheque.id, cadeau, apprendre: false));
      await db.insert('regles', {'motif': 'N', 'categorie_id': bars});
      final n = await _w(_ops.reparerRegles());
      expect(n, 0, reason: 'Aucune opération n\'avait été rangée par la règle « N ».');
      expect((await db.query('regles')).map((r) => r['motif']), ['CABANE VANNES']);
      expect((await _une('09/09')).categorieId, bars);
      expect((await _une('REMISE CHEQUE')).categorieId, cadeau);
    });

    test('C4 une correction faite sur une attente est suivie par la comptabilisée', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_att('2026-09-20', 'LA CABANE VANNES', -12)]));
      final bars = await _idDe('Restaurants et sorties', 'Bars et clubs');
      await _w(_ops.reclasser((await _une('CABANE')).id, bars));
      await _w(_ops.importer(compte, [_b('r1', '2026-09-21', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 20/09', -12)],
          depuis: DateTime(2026, 9, 14)));
      final o = await _une('CABANE');
      expect(o.enAttente, isFalse);
      expect(o.categorieId, bars);
      expect(o.origine, Origine.main);
    });
  });

  // ------------------------------------------------------------------ D
  group('bilan, cas tordus', () {
    test('D1 un remboursement d\'octobre pour une dépense de septembre', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('r1', '2026-09-20', 'PAIEMENT PAR CARTE X4057 SNCF VOYAGEURS 19/09', -100),
        _b('r2', '2026-10-03', 'VIR SEPA RECU DE M DUPONT', 100),
        _b('r3', '2026-10-05', 'VIR SEPA SALAIRE OCTOBRE', 1000),
      ]));
      await _w(_liens.rembourser((await _une('SNCF')).id, nouvelle: (await _une('DUPONT')).id));
      final sept = await _w(_bilan.du(const Mois(2026, 9)));
      final oct = await _w(_bilan.du(const Mois(2026, 10)));
      expect(sept.sorties, 0);
      expect(oct.entrees, 100000);
      expect(oct.sorties, 0);
    });

    test('D2 une dépense masquée liée : son remboursement ne devient pas un revenu', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('r1', '2026-09-10', 'PAIEMENT PAR CARTE X4057 RESTAURANT LE PORT 09/09', -120),
        _b('r2', '2026-09-12', 'VIR SEPA RECU DE M DUPONT', 80),
      ]));
      final resto = await _une('RESTAURANT');
      await _w(_liens.rembourser(resto.id, nouvelle: (await _une('DUPONT')).id));
      await _w(_ops.modifier(resto.id, masquee: true));
      final b = await _w(_bilan.du(const Mois(2026, 9)));
      expect(b.sorties, 0);
      expect(b.entrees, 0);
      expect(b.rembourses, 0);
    });

    test('D3 une entrée masquée ne rembourse plus rien', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('r1', '2026-09-10', 'PAIEMENT PAR CARTE X4057 RESTAURANT LE PORT 09/09', -120),
        _b('r2', '2026-09-12', 'VIR SEPA RECU DE M DUPONT', 80),
      ]));
      final ami = await _une('DUPONT');
      await _w(_liens.rembourser((await _une('RESTAURANT')).id, nouvelle: ami.id));
      await _w(_ops.modifier(ami.id, masquee: true));
      final b = await _w(_bilan.du(const Mois(2026, 9)));
      expect(b.sorties, 12000, reason: 'Une opération masquée ne compte nulle part, pas même en déduction.');
    });

    test('D4 un remboursement plus grand que la dépense : le surplus est un revenu', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('r1', '2026-09-10', 'PAIEMENT PAR CARTE X4057 SNCF VOYAGEURS 09/09', -100),
        _b('r2', '2026-09-12', 'VIR SEPA RECU DE M DUPONT', 150),
      ]));
      final train = await _une('SNCF');
      final ami = await _une('DUPONT');
      expect(() => _liens.repartir(ami.id, {train.id: 15000}), throwsArgumentError);
      await _w(_liens.rembourser(train.id, nouvelle: ami.id));
      expect((await _w(_liens.concernant([train.id]))).single.montantCentimes, 10000);
      final b = await _w(_bilan.du(const Mois(2026, 9)));
      expect(b.sorties, 0);
      expect(b.entrees, 5000);
    });

    test('D5 espèces dépensées le mois suivant le retrait : pas comptées deux fois', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_b('r1', '2026-09-25', 'RETRAIT DAB VANNES 25/09', -50)]));
      await _w(_ops.ajouterEspeces(le: DateTime(2026, 10, 2), nom: 'Marché', centimes: 2000, categorieId: await _idDe('Courses', 'Marché et primeur')));
      final sept = await _w(_bilan.du(const Mois(2026, 9)));
      final oct = await _w(_bilan.du(const Mois(2026, 10)));
      expect(sept.sorties + oct.sorties, 5000, reason: '50 € sont sortis du compte, pas 70.');
    });

    test('D6 plus d\'espèces dépensées que retirées dans le mois', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_b('r1', '2026-09-05', 'RETRAIT DAB VANNES 05/09', -20)]));
      await _w(_ops.ajouterEspeces(le: DateTime(2026, 9, 6), nom: 'Marché', centimes: 5000, categorieId: await _idDe('Courses', 'Marché et primeur')));
      final b = await _w(_bilan.du(const Mois(2026, 9)));
      expect(b.sorties, 5000);
      expect(b.parCategorie[await _idDe('Retraits et virements', '')], 0);
    });

    test('D7 un mois rattaché à la main et un lien vers l\'autre mois', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('r1', '2026-09-30', 'PRLV SEPA LOYER FONCIA', -600),
        _b('r2', '2026-10-04', 'VIR SEPA RECU DE M DUPONT', 300),
      ]));
      final loyer = await _une('LOYER');
      await _w(_ops.modifier(loyer.id, moisCompte: const Mois(2026, 10)));
      await _w(_liens.rembourser(loyer.id, nouvelle: (await _une('DUPONT')).id));
      expect((await _w(_bilan.du(const Mois(2026, 9)))).sorties, 0);
      final oct = await _w(_bilan.du(const Mois(2026, 10)));
      expect(oct.sorties, 30000);
      expect(oct.entrees, 0);
    });
  });

  // ------------------------------------------------------------------ E
  group('sauvegarde', () {
    test('E1 un an de données, liens, notes, règles et livrets : la restauration rend tout à l\'identique', () async {
      final compte = await _compte();
      await _long(_ops.importer(compte, [..._uneAnnee(Random(7)), _att('2026-09-25', 'UBER EATS', -8.4)]));
      await _w(_ops.importer(compte, [_b('rx', '2026-09-20', 'VIR SEPA RECU DE M DUPONT', 30)], attenteLue: false));
      final livret = await _w(_comptes.ajouterLivret(nom: 'Livret CMB', soldeCentimes: 123456, motif: 'LIVRET CMB'));
      await _w(_comptes.fixerPortefeuille(4000));
      final uber = (await _dont('UBER EATS')).firstWhere((o) => o.enAttente);
      await _w(_ops.modifier(uber.id, note: 'Déjà réglé', moisCompte: const Mois(2026, 10)));
      await _w(_ops.renommer((await _dont('BOUTIQUE INCONNUE')).first.id, 'La boutique'));
      await _w(_ops.reclasser((await _dont('BOUTIQUE INCONNUE')).first.id, await _idDe('Loisirs', '')));
      await _w(_liens.rembourser((await _dont('SNCF')).first.id, nouvelle: (await _une('DUPONT')).id));
      final avant = await _vidage();

      final chrono = Stopwatch()..start();
      final chemin = await Sauvegarde.exporter('phrase de test').timeout(const Duration(minutes: 1));
      await _w(_ops.importer(compte, [_b('ry', '2026-09-26', 'PAIEMENT PAR CARTE X4057 LIDL VANNES 26/09', -3)], attenteLue: false));
      await _w(_comptes.definirSolde(livret, 1));
      await Sauvegarde.restaurer(chemin, 'phrase de test').timeout(const Duration(minutes: 1));
      // ignore: avoid_print
      print("E1 : export puis restauration en ${chrono.elapsedMilliseconds} ms");
      expect(await _vidage(), avant);
      // Et la synchro suivante ne double rien.
      expect(await _long(_ops.importer(compte, _uneAnnee(Random(7)), attenteLue: false)), 0);
    }, timeout: _lent);

    test('E2 après une restauration, un retrait arrivé ensuite fait encore vivre le portefeuille', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_b('r1', '2026-09-01', 'RETRAIT DAB VANNES 01/09', -30)]));
      final faute = await _w(_ops.ajouterEspeces(le: DateTime(2026, 9, 2), nom: 'Erreur', centimes: 100, categorieId: await _idDe('Courses', 'Marché et primeur')));
      await _w(_comptes.fixerPortefeuille(5000));
      // La dépense saisie par erreur est supprimée : c'était la dernière
      // opération, celle que retient le repère du portefeuille.
      await _w(_ops.supprimerManuelle(faute));
      final chemin = await Sauvegarde.exporter('phrase de test').timeout(const Duration(minutes: 1));
      // Restaurée sur un téléphone neuf : une base vide, puis la sauvegarde.
      await _neuf();
      await Sauvegarde.restaurer(chemin, 'phrase de test').timeout(const Duration(minutes: 1));

      await _w(_ops.importer(compte, [_b('r2', '2026-09-10', 'RETRAIT DAB VANNES 10/09', -20)]));
      final p = (await _comptes.tous()).singleWhere((c) => c.nature == NatureCompte.portefeuille);
      expect(await _w(_comptes.soldePortefeuille(p)), 5000 + 2000);
    }, timeout: _lent);
  });

  // ------------------------------------------------------------------ F
  group('écritures concurrentes', () {
    /// Lance tout en même temps et rend les erreurs, sans jamais geler.
    Future<List<Object?>> ensemble(List<Future<Object?>> fs) => Future.wait([
          for (final f in fs) f.then<Object?>((_) => null, onError: (Object e) => e),
        ]).timeout(const Duration(seconds: 60));

    test('F1 un gros import pendant rembourser, repartir, deux reclasser et un renommer', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('x1', '2026-09-04', 'PAIEMENT PAR CARTE X4057 SNCF 03/09', -300),
        _b('x2', '2026-09-12', 'PAIEMENT PAR CARTE X4057 RESTAURANT LE PORT 11/09', -200),
        _b('x3', '2026-09-21', 'REMISE CHEQUE N 8841207', 500),
        _b('x4', '2026-09-20', 'VIR SEPA RECU DE M DUPONT', 50),
        _b('x5', '2026-09-20', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 19/09', -20),
        _b('x6', '2026-09-22', 'PAIEMENT PAR CARTE X4057 BOUTIQUE INCONNUE 21/09', -20),
      ]));
      final train = await _une('SNCF');
      final resto = await _une('RESTAURANT');
      final cheque = await _une('REMISE CHEQUE');
      final ami = await _une('DUPONT');
      final bars = await _idDe('Restaurants et sorties', 'Bars et clubs');
      final loisirs = await _idDe('Loisirs', '');
      final erreurs = await ensemble([
        _ops.importer(compte, _uneAnnee(Random(3))),
        _liens.repartir(cheque.id, {train.id: 30000, resto.id: 20000}),
        _liens.rembourser(train.id, nouvelle: ami.id),
        _ops.reclasser((await _une('CABANE')).id, bars),
        _ops.reclasser((await _une('BOUTIQUE')).id, loisirs),
        _ops.renommer((await _une('RESTAURANT')).id, 'Le Port'),
        _bilan.du(const Mois(2026, 9)),
      ]);
      // Le chèque couvre déjà tout le train : l'un des deux liens est refusé.
      expect(erreurs.whereType<Error>().where((e) => e is! ArgumentError), isEmpty, reason: '$erreurs');
      expect(erreurs.where((e) => e != null && e is! ArgumentError), isEmpty, reason: '$erreurs');
      final l = await _w(_liens.concernant([train.id]));
      expect(l.fold(0, (a, x) => a + x.montantCentimes), lessThanOrEqualTo(30000));
      expect((await _dont('BOUTIQUE INCONNUE')).where((o) => o.categorieId != loisirs), isEmpty,
          reason: 'La règle apprise pendant l\'import vaut aussi pour ce qu\'il a apporté.');
      expect(await _w(_ops.chercher('SNCF')), isNotEmpty, reason: 'La base répond encore.');
    }, timeout: _lent);

    test('F2 repartir et rembourser sur la même dépense en même temps : pas plus que la dépense', () async {
      final compte = await _compte();
      var trop = 0;
      for (var k = 0; k < 5; k++) {
        await _w(_ops.importer(compte, [
          _b('d$k', '2026-09-04', 'PAIEMENT PAR CARTE X4057 SNCF $k', -100),
          _b('e$k', '2026-09-10', 'VIR SEPA RECU DE M DUPONT $k', 100),
          _b('f$k', '2026-09-11', 'VIR SEPA RECU DE M MARTIN $k', 100),
        ]));
        final d = await _une('SNCF $k');
        final e1 = await _une('DUPONT $k');
        final e2 = await _une('MARTIN $k');
        await ensemble([
          _liens.repartir(e1.id, {d.id: 10000}),
          _liens.rembourser(d.id, nouvelle: e2.id),
        ]);
        final somme = (await _w(_liens.concernant([d.id]))).fold(0, (a, x) => a + x.montantCentimes);
        if (somme > 10000) trop++;
      }
      expect(trop, 0, reason: 'Sur 5 essais, $trop dépenses de 100 € remboursées au-delà de 100 €.');
    }, timeout: _lent);

    test('F3 une règle apprise pendant un import s\'applique à ce qu\'il apporte', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [_b('m0', '2026-08-02', 'PAIEMENT PAR CARTE X4057 CHEZ MARCEL 01/08', -9)]));
      final bars = await _idDe('Restaurants et sorties', 'Bars et clubs');
      final marcel = await _une('CHEZ MARCEL');
      await ensemble([
        _ops.reclasser(marcel.id, bars),
        _ops.importer(compte, [
          for (var k = 1; k <= 20; k++) _b('m$k', '2026-09-${(k + 1).toString().padLeft(2, '0')}', 'PAIEMENT PAR CARTE X4057 CHEZ MARCEL $k', -9),
        ]),
      ]);
      final mal = (await _dont('CHEZ MARCEL')).where((o) => o.categorieId != bars).length;
      expect(mal, 0, reason: '$mal passages chez Marcel ne suivent pas la règle apprise.');
    });

    test('F4 un lien vers une attente que la synchro efface : rien ne gèle, pas de lien orphelin', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        _b('d', '2026-09-04', 'PAIEMENT PAR CARTE X4057 SNCF 03/09', -100),
        _att('2026-09-20', 'VIR INST RECU DE PAUL', 40),
      ]));
      final d = await _une('SNCF');
      final paul = await _une('PAUL');
      final erreurs = await ensemble([
        _liens.rembourser(d.id, nouvelle: paul.id),
        _ops.importer(compte, [], depuis: DateTime(2026, 9, 1)),
      ]);
      final db = await Base.instance.db;
      final orphelins = await db.rawQuery(
          'SELECT COUNT(*) AS n FROM liens WHERE entree_id NOT IN (SELECT id FROM operations) OR depense_id NOT IN (SELECT id FROM operations)');
      expect(orphelins.first['n'], 0);
      expect(await _dont('PAUL'), isEmpty);
      // ignore: avoid_print
      print('F4 : erreurs rendues : $erreurs');
    });

    test('F5 deux synchros lancées en même temps ne doublent rien', () async {
      final compte = await _compte();
      final lot = [..._uneAnnee(Random(9)).take(200), _att('2026-09-24', 'UBER EATS', -18.4), _att('2026-09-24', 'UBER EATS', -18.4, n: 2)];
      final erreurs = await ensemble([
        _ops.importer(compte, lot),
        _ops.importer(compte, lot),
      ]);
      expect(erreurs.whereType<Object>(), isEmpty);
      expect(await _toutes(), hasLength(lot.length));
    }, timeout: _lent);

    test('F6 deux reclasser du même marchand en même temps : les autres suivent la règle retenue', () async {
      final compte = await _compte();
      await _w(_ops.importer(compte, [
        for (var k = 1; k <= 6; k++) _b('c$k', '2026-09-0$k', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 0$k/09', -10.0 - k),
      ]));
      final l = await _dont('CABANE');
      final bars = await _idDe('Restaurants et sorties', 'Bars et clubs');
      final resto = await _idDe('Restaurants et sorties', 'Restaurant');
      final erreurs = await ensemble([_ops.reclasser(l[0].id, bars), _ops.reclasser(l[1].id, resto)]);
      expect(erreurs.whereType<Object>(), isEmpty);
      final db = await Base.instance.db;
      final regle = (await db.query('regles', where: 'motif = ?', whereArgs: ['CABANE VANNES'])).single['categorie_id'];
      final apres = await _dont('CABANE');
      for (final o in apres.where((o) => o.origine != Origine.main)) {
        expect(o.categorieId, regle);
      }
      expect(apres.firstWhere((o) => o.id == l[0].id).categorieId, bars);
      expect(apres.firstWhere((o) => o.id == l[1].id).categorieId, resto);
    });
  });
}

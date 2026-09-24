// Tests sur appareil : SQLCipher et le Keystore n'existent que sur Android.
//
//   flutter test integration_test -d <émulateur>
//
// Ils effacent la base de l'application : à lancer sur un émulateur, jamais
// sur le téléphone qui porte les vrais comptes.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartbudget/domaine/bilan.dart';
import 'package:smartbudget/domaine/classement.dart';
import 'package:smartbudget/domaine/libelle.dart';
import 'package:smartbudget/domaine/modeles.dart';
import 'package:smartbudget/domaine/mois.dart';
import 'package:smartbudget/domaine/recurrences.dart';
import 'package:smartbudget/domaine/virements.dart';
import 'package:smartbudget/donnees/base.dart';
import 'package:smartbudget/donnees/depots.dart';
import 'package:smartbudget/donnees/sauvegarde.dart';
import 'package:smartbudget/security/key_vault.dart';

const _categories = DepotCategories();
const _comptes = DepotComptes();
const _ops = DepotOperations();
const _liens = DepotLiens();
const _bilan = DepotBilan();
const _reglages = DepotReglages();

var _uid = 0;
OperationBrute _op(String date, String libelle, double euros) => OperationBrute(
      uidBanque: 'test-${_uid++}',
      le: DateTime.parse(date),
      libelle: libelle,
      montantCentimes: (euros * 100).round(),
    );

Future<int> _idDe(String categorie, String sous) async =>
    (await _categories.resolveur())(categorie, sous)!;

Future<Operation> _cherche(String libelle) async {
  final toutes = await _ops.entre(DateTime(2000), DateTime(2100));
  return toutes.firstWhere((o) => o.libelle == libelle);
}

Future<void> _neuf() async {
  await Base.instance.effacer();
  await KeyVault.instance.unlock();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await KeyVault.instance.destroy();
    await _neuf();
  });

  group('libellés', () {
    test('le marchand sort du bruit de la banque', () {
      expect(marchand('PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09'), 'CARREFOUR MARKET VANNES');
      expect(marchand('PRLV SEPA AMAZON PAYMENTS EUROPE S AMZN MKTP FR'), 'AMAZON PAYMENTS EUROPE S AMZN MKTP FR');
      expect(cleMarchand('PRLV SEPA Paypal Europe S.a.r.l. Et Cie S.c.a'), 'PAYPAL S.A.R.L. S.C.A');
      expect(joli('PAIEMENT CB SPOTIFY P2F9 STOCKHOLM'), 'Spotify P2f9 Stockholm');
    });

    test('la clé ne change pas d\'un mois à l\'autre', () {
      expect(
        cleMarchand('PAIEMENT PAR CARTE X4057 NETFLIX.COM 03/08'),
        cleMarchand('PAIEMENT PAR CARTE X4057 NETFLIX.COM 03/09'),
      );
    });
  });

  group('virements internes', () {
    test('vers le livret : mis de côté', () {
      final v = reconnaitreInterne('Vir Vers Livret Cmb De Carte Bancaire')!;
      expect(v.sens, SensInterne.versEpargne);
      expect(v.destination, 'LIVRET CMB');
      expect(v.source, 'CARTE BANCAIRE');
    });

    test('depuis le livret : pioché', () {
      expect(reconnaitreInterne('VIR VERS CARTE BANCAIRE DE LIVRET CMB')!.sens, SensInterne.depuisEpargne);
    });

    test('un livret au nom inhabituel, appris des livrets saisis', () {
      expect(reconnaitreInterne('VIR VERS PROJET VOITURE DE CARTE BANCAIRE')!.sens, SensInterne.entreComptes);
      expect(
        reconnaitreInterne('VIR VERS PROJET VOITURE DE CARTE BANCAIRE', livretsConnus: ['PROJET VOITURE'])!.sens,
        SensInterne.versEpargne,
      );
    });

    test('un virement à quelqu\'un n\'est pas interne', () {
      expect(reconnaitreInterne('VIR SEPA MARTIN LUCAS REMBOURSEMENT RESTO'), isNull);
    });
  });

  group('mois budgétaire', () {
    test('un mois civil', () {
      expect(Mois.de(DateTime(2026, 9, 30)), const Mois(2026, 9));
    });

    test('un mois qui commence le jour de paie', () {
      expect(Mois.de(DateTime(2026, 9, 27), debut: 28), const Mois(2026, 9));
      expect(Mois.de(DateTime(2026, 9, 28), debut: 28), const Mois(2026, 10));
      expect(Mois.de(DateTime(2026, 12, 29), debut: 28), const Mois(2027, 1));
      final (de, a) = const Mois(2026, 10).bornes(debut: 28);
      expect(de, DateTime(2026, 9, 28));
      expect(a, DateTime(2026, 10, 28));
    });
  });

  group('récurrences', () {
    test('un abonnement mensuel est reconnu, et sa prochaine date', () {
      final r = detecterRecurrences([
        Passage('PAIEMENT CB SPOTIFY STOCKHOLM 14/07', DateTime(2026, 7, 14), -1112),
        Passage('PAIEMENT CB SPOTIFY STOCKHOLM 14/08', DateTime(2026, 8, 14), -1112),
        Passage('PAIEMENT CB SPOTIFY STOCKHOLM 14/09', DateTime(2026, 9, 14), -1112),
        Passage('PAIEMENT CB CARREFOUR VANNES', DateTime(2026, 9, 2), -4210),
        Passage('PAIEMENT CB CARREFOUR VANNES', DateTime(2026, 9, 9), -8812),
      ]);
      expect(r, hasLength(1));
      expect(r.single.frequence, Frequence.mensuelle);
      expect(r.single.prochaine, DateTime(2026, 10, 14));
      expect(r.single.enRetard(DateTime(2026, 10, 20)), isTrue);
      expect(r.single.dansJours(DateTime(2026, 10, 12)), 2);
    });

    test('des courses irrégulières ne sont pas une récurrence', () {
      final r = detecterRecurrences([
        Passage('CARREFOUR', DateTime(2026, 9, 1), -4000),
        Passage('CARREFOUR', DateTime(2026, 9, 12), -9000),
        Passage('CARREFOUR', DateTime(2026, 9, 14), -2000),
      ]);
      expect(r, isEmpty);
    });
  });

  group('base', () {
    setUp(_neuf);

    test('les catégories de départ sont semées', () async {
      final toutes = await _categories.toutes();
      expect(toutes.where((c) => c.parentId == null), hasLength(23));
      expect(toutes.where((c) => c.parentId != null), hasLength(180));
      expect(await _idDe('Permis', 'Permis bateau'), isPositive);
    });

    test('le classement automatique, et le dédoublonnage', () async {
      final compte = await _comptes.courant();
      final lot = [
        _op('2026-09-02', 'PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 01/09', -64.12),
        _op('2026-09-03', 'PAIEMENT PAR CARTE X4057 UBER EATS 02/09', -18.40),
        _op('2026-09-04', 'PAIEMENT PAR CARTE X4057 UBER TRIP 03/09', -12.00),
        _op('2026-09-05', 'VIR SEPA SALAIRE ALTERNANCE SEPTEMBRE', 1250),
        _op('2026-09-06', 'PRLV SEPA BASIC FIT FRANCE', -29.99),
        _op('2026-09-07', 'Vir Vers Livret Cmb De Carte Bancaire', -200),
        _op('2026-09-08', 'PAIEMENT PAR CARTE X4057 BOUTIQUE INCONNUE 07/09', -15),
      ];
      expect(await _ops.importer(compte.id, lot), 7);
      expect(await _ops.importer(compte.id, lot), 0, reason: 'Une synchro relancée ne double rien.');

      expect((await _cherche(lot[0].libelle)).categorieId, await _idDe('Courses', 'Supermarché'));
      expect((await _cherche(lot[1].libelle)).categorieId, await _idDe('Restaurants et sorties', 'Livraison de repas'));
      expect((await _cherche(lot[2].libelle)).categorieId, await _idDe('Transports', 'Taxi et VTC'));
      expect((await _cherche(lot[3].libelle)).categorieId, await _idDe('Salaire', 'Salaire'));
      expect((await _cherche(lot[4].libelle)).categorieId, await _idDe('Abonnements', 'Salle de sport'));
      final interne = await _cherche(lot[5].libelle);
      expect(interne.interne, SensInterne.versEpargne);
      expect(interne.origine, Origine.interne);
      expect((await _cherche(lot[6].libelle)).categorieId, await _idDe('À classer', ''));
    });

    test('une correction est apprise, et suivie', () async {
      final compte = await _comptes.courant();
      await _ops.importer(compte.id, [
        _op('2026-08-10', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/08', -22),
        _op('2026-09-10', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/09', -31),
      ]);
      final premiere = await _cherche('PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/08');
      final bar = await _idDe('Restaurants et sorties', 'Bars et clubs');
      expect(await _ops.reclasser(premiere.id, bar), 1);
      expect((await _cherche('PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/09')).categorieId, bar);

      await _ops.importer(compte.id, [_op('2026-10-10', 'PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/10', -27)]);
      final troisieme = await _cherche('PAIEMENT PAR CARTE X4057 LA CABANE VANNES 09/10');
      expect(troisieme.categorieId, bar);
      expect(troisieme.origine, Origine.regle);
    });

    test('le bilan : remboursement lié, virements internes, masquées', () async {
      final compte = await _comptes.courant();
      await _ops.importer(compte.id, [
        _op('2026-09-04', 'PAIEMENT PAR CARTE X4057 SNCF VOYAGEURS 03/09', -300),
        _op('2026-09-12', 'PAIEMENT PAR CARTE X4057 RESTAURANT LE PORT 11/09', -200),
        _op('2026-09-15', 'PAIEMENT PAR CARTE X4057 CARREFOUR VANNES 14/09', -50),
        _op('2026-09-21', 'REMISE CHEQUE N 8841207', 500),
        _op('2026-09-05', 'VIR SEPA SALAIRE SEPTEMBRE', 1200),
        _op('2026-09-07', 'VIR VERS LIVRET CMB DE CARTE BANCAIRE', -200),
        _op('2026-09-18', 'VIR VERS CARTE BANCAIRE DE LIVRET CMB', 150),
        _op('2026-09-20', 'PAIEMENT PAR CARTE X4057 FNAC VANNES 19/09', -80),
      ]);
      final cheque = await _cherche('REMISE CHEQUE N 8841207');
      final train = await _cherche('PAIEMENT PAR CARTE X4057 SNCF VOYAGEURS 03/09');
      final resto = await _cherche('PAIEMENT PAR CARTE X4057 RESTAURANT LE PORT 11/09');
      await _liens.repartir(cheque.id, {train.id: 30000, resto.id: 20000});
      await _ops.modifier((await _cherche('PAIEMENT PAR CARTE X4057 FNAC VANNES 19/09')).id, masquee: true);

      final b = await _bilan.du(const Mois(2026, 9));
      expect(b.sorties, 5000, reason: 'Seules les courses restent à charge.');
      expect(b.entrees, 120000, reason: 'Le chèque ne compte pas comme revenu.');
      expect(b.misDeCote, 20000);
      expect(b.pioche, 15000);
      expect(b.epargneNette, 5000);
      expect(b.parCategorie[await _idDe('Transports', '')], isNull);
      expect(b.parCategorie[await _idDe('Courses', '')], 5000);
    });

    test('une répartition qui dépasse est refusée', () async {
      final compte = await _comptes.courant();
      await _ops.importer(compte.id, [
        _op('2026-09-04', 'PAIEMENT PAR CARTE X4057 SNCF 03/09', -100),
        _op('2026-09-21', 'REMISE CHEQUE N 1', 50),
      ]);
      final cheque = await _cherche('REMISE CHEQUE N 1');
      final train = await _cherche('PAIEMENT PAR CARTE X4057 SNCF 03/09');
      expect(() => _liens.repartir(cheque.id, {train.id: 6000}), throwsArgumentError);
    });

    test('le mois qui commence le jour de paie', () async {
      await _reglages.ecrire('debut_mois', '28');
      final compte = await _comptes.courant();
      await _ops.importer(compte.id, [
        _op('2026-09-27', 'PAIEMENT PAR CARTE X4057 CARREFOUR 26/09', -10),
        _op('2026-09-28', 'PAIEMENT PAR CARTE X4057 CARREFOUR 27/09', -20),
      ]);
      expect((await _bilan.du(const Mois(2026, 9))).sorties, 1000);
      expect((await _bilan.du(const Mois(2026, 10))).sorties, 2000);
    });

    test('les récurrences sortent de la base', () async {
      final compte = await _comptes.courant();
      await _ops.importer(compte.id, [
        for (final m in [6, 7, 8, 9])
          _op('2026-0$m-05', 'PRLV SEPA FREE MOBILE $m', -17.99),
      ]);
      final r = await _ops.recurrences(maintenant: DateTime(2026, 9, 20));
      expect(r.map((x) => x.libelle), contains(startsWith('Free Mobile')));
    });

    test('le portefeuille vit des retraits et des dépenses en espèces', () async {
      final compte = await _comptes.courant();
      await _ops.importer(compte.id, [_op('2026-09-01', 'RETRAIT DAB VANNES', -30)]);
      await _comptes.fixerPortefeuille(5000);
      // Le retrait d'avant est déjà dans les 50 € comptés ; ceux d'après
      // s'ajoutent, les dépenses en espèces se retirent.
      await _ops.importer(compte.id, [_op('2026-09-10', 'RETRAIT DAB VANNES', -20)]);
      await _ops.ajouterEspeces(le: DateTime(2026, 9, 11), nom: 'Marché', centimes: 1200, categorieId: await _idDe('Courses', 'Marché et primeur'));
      final p = (await _comptes.tous()).singleWhere((c) => c.nature == NatureCompte.portefeuille);
      expect(await _comptes.soldePortefeuille(p), 5000 + 2000 - 1200);
    });

    test('une sauvegarde chiffrée se relit, avec la bonne phrase seulement', () async {
      final compte = await _comptes.courant();
      await _ops.importer(compte.id, [_op('2026-09-02', 'PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 01/09', -64.12)]);
      await _comptes.ajouterLivret(nom: 'Livret A', soldeCentimes: 150000);
      await _reglages.ecrire('budget', '150000');
      final chemin = await Sauvegarde.exporter('phrase de test');

      // On change tout, puis on restaure.
      await _ops.importer(compte.id, [_op('2026-09-03', 'PAIEMENT PAR CARTE X4057 UBER EATS 02/09', -18.40)]);
      await _reglages.ecrire('budget', '1');
      await expectLater(Sauvegarde.restaurer(chemin, 'mauvaise phrase'), throwsFormatException);
      expect(await _reglages.lire('budget'), '1', reason: 'Une phrase fausse ne touche à rien.');

      await Sauvegarde.restaurer(chemin, 'phrase de test');
      final ops = await _ops.entre(DateTime(2000), DateTime(2100));
      expect(ops.map((o) => o.libelle), ['PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 01/09']);
      expect((await _comptes.tous()).where((c) => c.nature == NatureCompte.livret).single.soldeCentimes, 150000);
      expect(await _reglages.lire('budget'), '150000');
    });
  });

  test('calculerBilan sans base : un remboursement marchand réduit sa catégorie', () {
    const courses = Categorie(id: 1, parentId: null, nom: 'Courses', genre: Genre.depense, icone: null, couleur: 0, budgetCentimes: null, ordre: 0, nature: Nature.essentiel);
    final b = calculerBilan(
      mois: const Mois(2026, 9),
      operations: [
        Operation(id: 1, compteId: 1, uidBanque: 'a', le: DateTime(2026, 9, 1), libelle: 'A', montantCentimes: -5000, categorieId: 1, origine: Origine.dictionnaire),
        Operation(id: 2, compteId: 1, uidBanque: 'b', le: DateTime(2026, 9, 2), libelle: 'B', montantCentimes: 1000, categorieId: 1, origine: Origine.dictionnaire),
      ],
      liens: const [],
      categories: {1: courses},
    );
    expect(b.sorties, 4000);
    expect(b.essentiel, 4000);
  });

  test('calculerBilan sans base : une dépense en espèces sort des retraits', () {
    const retraits = Categorie(id: 1, parentId: null, nom: 'Retraits et virements', genre: Genre.depense, icone: null, couleur: 0, budgetCentimes: null, ordre: 0, nature: Nature.essentiel);
    const dab = Categorie(id: 2, parentId: 1, nom: "Retraits d'espèces", genre: Genre.depense, icone: null, couleur: 0, budgetCentimes: null, ordre: 0, nature: Nature.essentiel);
    const marche = Categorie(id: 3, parentId: null, nom: 'Courses', genre: Genre.depense, icone: null, couleur: 0, budgetCentimes: null, ordre: 1, nature: Nature.essentiel);
    final b = calculerBilan(
      mois: const Mois(2026, 9),
      operations: [
        Operation(id: 1, compteId: 1, uidBanque: 'a', le: DateTime(2026, 9, 1), libelle: 'RETRAIT DAB', montantCentimes: -5000, categorieId: 2, origine: Origine.dictionnaire),
        Operation(id: 2, compteId: 1, uidBanque: null, le: DateTime(2026, 9, 2), libelle: 'ESPECES MARCHE', montantCentimes: -2000, categorieId: 3, origine: Origine.main, especes: true),
      ],
      liens: const [],
      categories: {1: retraits, 2: dab, 3: marche},
    );
    // 50 € retirés dont 20 € dépensés au marché : 50 € sortis en tout, pas 70.
    expect(b.sorties, 5000);
    expect(b.parCategorie[3], 2000);
    expect(b.parCategorie[1], 3000);
    expect(b.parSous[2], 3000);
  });
}

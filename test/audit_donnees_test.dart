// Audit de la couche données et du domaine.
//
// Chaque test décrit le comportement attendu : ceux du groupe « bugs »
// échouent tant que le bug n'est pas corrigé, puis servent de garde-fous.
// Les tests du groupe « garde-fous » passent déjà.
//
// Tout est de la logique pure : pas de base, pas d'appareil.
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/domaine/bilan.dart';
import 'package:smartbudget/domaine/classement.dart';
import 'package:smartbudget/domaine/modeles.dart';
import 'package:smartbudget/domaine/mois.dart';
import 'package:smartbudget/domaine/recurrences.dart';
import 'package:smartbudget/domaine/virements.dart';
// FLUTTER-DEBUT
import 'package:smartbudget/ecrans/dialogues.dart' show lireEuros;
import 'package:smartbudget/providers/donnees.dart' show fusionner;
// FLUTTER-FIN

// ------------------------------------------------------------ catégories

Categorie _cat(int id, String nom, Genre genre, {int? parent, Nature nature = Nature.plaisir}) => Categorie(
      id: id,
      parentId: parent,
      nom: nom,
      genre: genre,
      icone: null,
      couleur: 0,
      budgetCentimes: null,
      ordre: 0,
      nature: nature,
    );

final _categories = <int, Categorie>{
  1: _cat(1, 'Transports', Genre.depense),
  2: _cat(2, 'Train', Genre.depense, parent: 1),
  10: _cat(10, 'Autres revenus', Genre.revenu),
  11: _cat(11, 'Remboursements', Genre.revenu, parent: 10),
  12: _cat(12, 'Virements reçus', Genre.revenu, parent: 10),
  20: _cat(20, 'Virements internes', Genre.interne),
  21: _cat(21, "Vers l'épargne", Genre.interne, parent: 20),
};

Operation _op(int id, String le, int centimes, int categorie,
        {SensInterne? interne, bool masquee = false, String libelle = 'OPERATION'}) =>
    Operation(
      id: id,
      compteId: 1,
      uidBanque: 'u$id',
      le: DateTime.parse(le),
      libelle: libelle,
      montantCentimes: centimes,
      categorieId: categorie,
      origine: Origine.main,
      interne: interne,
      masquee: masquee,
    );

const _septembre = Mois(2026, 9);

void main() {
  group('bugs', () {
    test('une dépense remboursée par deux entrées ne devient pas un gain', () {
      // repartir() ne regarde que l'entrée en cours : deux entrées peuvent
      // chacune rembourser les 100 € du même billet de train.
      final b = calculerBilan(
        mois: _septembre,
        operations: [
          _op(1, '2026-09-05', -10000, 2),
          _op(2, '2026-09-10', 10000, 12),
          _op(3, '2026-09-12', 10000, 12),
        ],
        liens: const [Lien(2, 1, 10000), Lien(3, 1, 10000)],
        categories: _categories,
      );
      expect(b.sorties, greaterThanOrEqualTo(0), reason: 'sorties = ${b.sorties}');
      expect(b.parCategorie[1] ?? 0, greaterThanOrEqualTo(0), reason: 'Transports = ${b.parCategorie[1]}');
    });

    test("un chèque reclassé n'apprend pas la règle « N »", () {
      // « REMISE CHEQUE N 8841207 » : il ne reste que « N » une fois le
      // préfixe et le numéro retirés, et reclasser() l'apprend.
      expect(motifAApprendre('REMISE CHEQUE N 8841207'), isNull);
      expect(motifAApprendre('REM 2 CHQ BORNE PONT L ABB'), isNull);
      // Et une vieille règle « N » ne prend plus Netflix : un mot entier.
      final classeur = Classeur(idDe: (c, s) => c == 'À classer' ? 99 : null, regles: [const Regle('N', 12)]);
      expect(classeur.classer('PRLV SEPA NETFLIX INTERNATIONAL', -1349).origine, isNot(Origine.regle));
      expect(motifValable('N'), isFalse);
    });

    test("un retrait reclassé n'apprend pas le nom de la ville", () {
      expect(motifAApprendre('RETRAIT DAB 12/09 VANNES'), isNull);
    });

    test("le mois de l'accueil contient aujourd'hui quand le mois commence le 25", () {
      // lib/ecrans/mois.dart:44 et providers/donnees.dart:17 prennent
      // Mois.de(DateTime.now()) sans le début, puis DepotBilan.du() lit
      // les bornes avec le début réglé.
      final aujourdhui = DateTime(2026, 9, 26);
      final (de, a) = Mois.de(aujourdhui, debut: 25).bornes(debut: 25);
      expect(!aujourdhui.isBefore(de) && aujourdhui.isBefore(a), isTrue, reason: 'accueil : $de à $a');
    });

    test('un abonnement du 31 janvier revient fin février, pas le 3 mars', () {
      final p = suivante(DateTime(2026, 1, 31), Frequence.mensuelle);
      expect(p.month, 2, reason: 'prochaine = $p');
    });

    test("dansJours compte les jours même quand l'heure d'été passe", () {
      // Paris passe à l'heure d'été le 29 mars 2026 : 14 jours séparent le
      // 20 mars du 3 avril, mais la différence ne fait que 13 j 23 h.
      final r = Recurrence(
        cle: 'X',
        libelle: 'X',
        montantCentimes: -1000,
        frequence: Frequence.mensuelle,
        derniere: DateTime(2026, 3, 3),
        prochaine: DateTime(2026, 4, 3),
        nombre: 2,
      );
      expect(r.dansJours(DateTime(2026, 3, 20, 9)), 14);
    });

    test("un virement rangé à la main dans « Vers l'épargne » compte dans l'épargne", () {
      // reclasser() vers une sous-catégorie de « Virements internes » met
      // interne à null : le bilan le voit interne, mais ne sait plus le sens.
      final b = calculerBilan(
        mois: _septembre,
        operations: [_op(1, '2026-09-05', -20000, 21)],
        liens: const [],
        categories: _categories,
      );
      expect(b.misDeCote, 20000);
    });

    test("une entrée liée puis marquée virement interne ne rembourse plus", () {
      // Le lien survit à marquerInterne() : la dépense reste allégée alors
      // que l'entrée compte déjà comme un virement entre comptes.
      final b = calculerBilan(
        mois: _septembre,
        operations: [
          _op(1, '2026-09-05', -10000, 2),
          _op(2, '2026-09-10', 10000, 21, interne: SensInterne.depuisEpargne),
        ],
        liens: const [Lien(2, 1, 10000)],
        categories: _categories,
      );
      expect(b.sorties, 10000);
    });

    // FLUTTER-DEBUT
    test('fusionner garde les remboursements', () {
      final b = calculerBilan(
        mois: _septembre,
        operations: [_op(1, '2026-09-05', 3000, 11)],
        liens: const [],
        categories: _categories,
      );
      expect(b.rembourses, 3000);
      // L'analyse passe toujours par fusionner(), même pour un seul mois.
      expect(fusionner(_septembre, [b]).rembourses, 3000);
    });

    test('lireEuros ne plante pas sur NaN ou Infinity', () {
      expect(() => lireEuros('NaN'), returnsNormally);
      expect(() => lireEuros('Infinity'), returnsNormally);
      expect(() => lireEuros('1e400'), returnsNormally);
    });

    test('lireEuros lit « 1.500,00 »', () {
      expect(lireEuros('1.500,00'), 150000);
    });
    // FLUTTER-FIN
  });

  group('garde-fous', () {
    test('une entrée liée à une dépense du mois précédent ne compte pas en revenu', () {
      final ops = [
        _op(1, '2026-08-20', -10000, 2),
        _op(2, '2026-09-03', 10000, 12),
      ];
      const liens = [Lien(2, 1, 10000)];
      final sept = calculerBilan(mois: _septembre, operations: ops, liens: liens, categories: _categories);
      final aout = calculerBilan(mois: const Mois(2026, 8), operations: ops, liens: liens, categories: _categories);
      expect(sept.entrees, 0);
      expect(aout.sorties, 0);
    });

    test('une opération masquée ne compte nulle part', () {
      final b = calculerBilan(
        mois: _septembre,
        operations: [_op(1, '2026-09-05', -10000, 2, masquee: true)],
        liens: const [],
        categories: _categories,
      );
      expect(b.sorties, 0);
    });

    test('Mois.de et bornes sont cohérents pour tout début de 1 à 28', () {
      for (var debut = 1; debut <= 28; debut++) {
        for (var d = DateTime(2026, 1, 1); d.isBefore(DateTime(2028, 1, 1)); d = DateTime(d.year, d.month, d.day + 1)) {
          final m = Mois.de(d, debut: debut);
          final (de, a) = m.bornes(debut: debut);
          expect(!d.isBefore(de) && d.isBefore(a), isTrue, reason: '$d, début $debut, mois $m');
        }
      }
    });
  });

  group('jour du salaire', () {
    DateTime d(int m, int j) => DateTime(2026, m, j);
    test('un salaire du 28 ouvre le mois le 28', () => expect(jourDuSalaire([d(6, 28), d(7, 28), d(8, 28)]), 28));
    test('un salaire en avance ne déplace pas le jour habituel', () => expect(jourDuSalaire([d(6, 28), d(7, 26), d(8, 28)]), 28));
    test('le 30 ou le 31 ouvre le mois le 28', () => expect(jourDuSalaire([d(6, 30), d(7, 31)]), 28));
    test('un salaire en retard, le 2, reste la fin du mois précédent', () => expect(jourDuSalaire([d(6, 28), d(8, 2), d(8, 28)]), 28));
    test('un salaire en début de mois', () => expect(jourDuSalaire([d(6, 3), d(7, 2), d(8, 3)]), 3));
    test('un seul salaire ne suffit pas', () => expect(jourDuSalaire([d(8, 28)]), isNull));
  });

  group('chaque salaire ouvre son mois', () {
    // Le cas vu sur le Fold : le salaire tombe vers le 25, mais celui de
    // décembre est arrivé le 19, avant Noël.
    final salaires = [
      (DateTime(2025, 10, 24), 162913),
      (DateTime(2025, 11, 25), 162913),
      (DateTime(2025, 12, 19), 299075),
      (DateTime(2026, 1, 23), 162913),
      (DateTime(2026, 2, 25), 162913),
    ];
    final cal = Calendrier(debut: 25, ouvertures: ouverturesDuSalaire(salaires, debut: 25));

    test('le salaire du 19 décembre ouvre janvier', () {
      expect(cal.de(DateTime(2025, 12, 19)), const Mois(2026, 1));
      expect(cal.de(DateTime(2025, 12, 18)), const Mois(2025, 12));
    });

    test('décembre ne compte qu’un salaire', () {
      expect(cal.bornes(const Mois(2025, 12)), (DateTime(2025, 11, 25), DateTime(2025, 12, 19)));
      expect(cal.bornes(const Mois(2026, 1)), (DateTime(2025, 12, 19), DateTime(2026, 1, 23)));
    });

    test('sans salaire encore arrivé, le mois suit le jour habituel', () {
      expect(cal.debutDe(const Mois(2026, 4)), DateTime(2026, 3, 25));
    });

    test('une prime ou un remboursement rangé en salaire n’ouvre rien', () {
      final avecPrime = [...salaires, (DateTime(2026, 1, 8), 15000)];
      expect(ouverturesDuSalaire(avecPrime, debut: 25), ouverturesDuSalaire(salaires, debut: 25));
    });

    test('un gros versement loin du jour habituel n’ouvre rien', () {
      final loin = [...salaires, (DateTime(2026, 1, 10), 162913)];
      expect(ouverturesDuSalaire(loin, debut: 25), ouverturesDuSalaire(salaires, debut: 25));
    });

    test('deux salaires pour le même mois : le premier l’ouvre', () {
      final double = [...salaires, (DateTime(2025, 11, 27), 162913)];
      expect(ouverturesDuSalaire(double, debut: 25)[const Mois(2025, 12)], DateTime(2025, 11, 25));
    });

    test('un salaire du 28 ouvre le mois suivant, même réglé au 1er', () {
      final o = ouverturesDuSalaire([(DateTime(2026, 5, 28), 100000), (DateTime(2026, 6, 29), 100000)], debut: 1);
      expect(o, {const Mois(2026, 6): DateTime(2026, 5, 28), const Mois(2026, 7): DateTime(2026, 6, 29)});
    });

    test('un salaire de début de mois ouvre le mois du même nom', () {
      expect(Mois.de(DateTime(2026, 10, 5), debut: 3), const Mois(2026, 10));
      expect(Mois.de(DateTime(2026, 10, 2), debut: 3), const Mois(2026, 9));
      final debutDeMois = Calendrier(
        debut: 3,
        ouvertures: ouverturesDuSalaire(
            [(DateTime(2026, 9, 3), 100000), (DateTime(2026, 10, 2), 100000), (DateTime(2026, 11, 3), 100000)],
            debut: 3),
      );
      // Arrivé un jour plus tôt, le 2 octobre, il ouvre quand même octobre.
      expect(debutDeMois.de(DateTime(2026, 10, 2)), const Mois(2026, 10));
      expect(debutDeMois.de(DateTime(2026, 10, 1)), const Mois(2026, 9));
      expect(debutDeMois.bornes(const Mois(2026, 10)), (DateTime(2026, 10, 2), DateTime(2026, 11, 3)));
    });

    test('chaque jour tombe dans un mois, et un seul', () {
      for (var d = DateTime(2025, 6, 1); d.isBefore(DateTime(2026, 8, 1)); d = DateTime(d.year, d.month, d.day + 1)) {
        final m = cal.de(d);
        final (de, a) = cal.bornes(m);
        expect(!d.isBefore(de) && d.isBefore(a), isTrue, reason: '$d, mois $m, de $de à $a');
      }
    });
  });

  group("espèces d'un mois sur l'autre", () {
    Operation op(int id, String le, int c, {bool especes = false}) => Operation(
          id: id, compteId: 1, uidBanque: 'u$id', le: DateTime.parse(le), libelle: 'X',
          montantCentimes: c, categorieId: 1, origine: Origine.main, especes: especes);
    test("un retrait de septembre finance le marché d'octobre", () {
      final f = financementEspeces([op(1, '2026-09-25', -5000)], [op(2, '2026-10-02', -2000, especes: true)]);
      expect(f, {1: 2000});
    });
    test("le plus ancien retrait d'abord, jamais au-delà de son montant", () {
      final f = financementEspeces(
        [op(1, '2026-09-01', -2000), op(2, '2026-09-10', -5000)],
        [op(3, '2026-09-12', -3000, especes: true)],
      );
      expect(f, {1: 2000, 2: 1000});
    });
    test('un retrait postérieur ou de plus de deux mois ne finance rien', () {
      final f = financementEspeces(
        [op(1, '2026-06-01', -5000), op(2, '2026-09-20', -5000)],
        [op(3, '2026-09-10', -1000, especes: true)],
      );
      expect(f, isEmpty);
    });
  });
}

import 'dart:math';

import '../domaine/modeles.dart';
import 'depots.dart';

/// Un jeu d'essai : quatre mois d'opérations inventées, écrites comme le
/// Crédit Mutuel de Bretagne les écrit, pour juger les écrans avant que
/// la banque ne soit branchée. Les montants et les marchands sont faux.
///
/// Il n'existe que dans une version de travail, compilée avec
/// `--dart-define=ESSAIS=true`.
class Demonstration {
  const Demonstration();

  Future<void> remplir() async {
    final hasard = Random(20260923);
    const comptes = DepotComptes();
    final courant = await comptes.courant();
    final aujourdhui = DateTime.now();
    final ops = <OperationBrute>[];
    var n = 0;

    void op(DateTime d, String libelle, double euros) {
      if (d.isAfter(aujourdhui)) return;
      ops.add(OperationBrute(uidBanque: 'demo-${n++}', le: d, libelle: libelle, montantCentimes: (euros * 100).round()));
    }

    String jj(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    String cb(DateTime d, String marchand) => 'PAIEMENT PAR CARTE X0000 $marchand ${jj(d)}';
    double v(double base, double ecart) => double.parse((base + (hasard.nextDouble() * 2 - 1) * ecart).toStringAsFixed(2));

    for (var m = 3; m >= 0; m--) {
      final debut = DateTime(aujourdhui.year, aujourdhui.month - m, 1);
      DateTime j(int jour) => DateTime(debut.year, debut.month, jour);
      final fin = DateTime(debut.year, debut.month + 1, 0).day;

      op(j(1), 'VIR SEPA RECU SALAIRE ALTERNANCE', 1285.40);
      op(j(5), 'PRLV SEPA FONCIA LOYER', -520);
      op(j(6), 'PRLV SEPA FREE MOBILE', -17.99);
      op(j(8), 'PRLV SEPA EDF CLIENTS PARTICULIERS', -v(38, 3));
      op(j(10), 'PRLV SEPA BASIC FIT FRANCE', -29.99);
      op(j(14), cb(j(13), 'SPOTIFY P2F9 STOCKHOLM'), -11.12);
      op(j(17), cb(j(16), 'NETFLIX.COM'), -14.99);
      op(j(3), 'VIR VERS LIVRET CMB DE CARTE BANCAIRE', -200);

      for (final jour in [2, 7, 12, 16, 21, 26]) {
        if (jour > fin) continue;
        final enseigne = ['CARREFOUR MARKET VANNES', 'LECLERC VANNES', 'LIDL VANNES', 'BIOCOOP VANNES'][hasard.nextInt(4)];
        op(j(jour), cb(j(jour - 1), enseigne), -v(48, 22));
      }
      for (final jour in [4, 9, 11, 18, 23, 27]) {
        if (jour > fin) continue;
        final r = hasard.nextInt(5);
        final (nom, montant) = [
          ('BOULANGERIE DU PORT', v(6, 3)),
          ('MCDONALDS VANNES', v(12, 4)),
          ('UBER EATS', v(21, 6)),
          ('LE CAFE DU PORT', v(9, 4)),
          ('CREPERIE SAINT PATERN', v(24, 8)),
        ][r];
        op(j(jour), cb(j(jour - 1), nom), -montant);
      }
      op(j(13), cb(j(12), 'TOTALENERGIES VANNES'), -v(58, 10));
      op(j(24), cb(j(23), 'ESSO KERLANN'), -v(46, 10));
      op(j(19), cb(j(18), 'PARKING REPUBLIQUE'), -v(4, 1.5));
      if (hasard.nextBool()) op(j(15), 'PRLV SEPA AMAZON PAYMENTS EUROPE S AMZN MKTP FR', -v(38, 15));
      if (hasard.nextBool()) op(j(20), cb(j(19), 'DECATHLON VANNES'), -v(35, 20));
      op(j(22), cb(j(21), 'PHARMACIE DU PORT'), -v(12, 6));
      op(j(28), 'FRAIS COTISATION CARTE', -2.30);
    }

    // Ce mois-ci, de quoi essayer la vérification : un achat Amazon sous un
    // libellé qu'il ne dit pas, un commerçant inconnu, un prélèvement
    // opaque, un remboursement entre amis, et un virement vers un livret
    // d'une autre banque, que rien ne signale comme interne.
    final ici = DateTime(aujourdhui.year, aujourdhui.month, 1);
    DateTime k(int jour) => DateTime(ici.year, ici.month, jour);
    op(k(4), cb(k(3), 'MKTP FR*2K4L9 LUXEMBOURG'), -34.99);
    op(k(9), cb(k(8), 'SUMUP *ATELIER KERNEVEL'), -18.50);
    op(k(11), 'PRLV SEPA GOCARDLESS LTD', -9.99);
    op(k(12), 'VIR SEPA RECU REMBOURSEMENT M LE GALL', 25);
    op(k(15), 'VIR SEPA EMIS REF 88213 BOURSOBANK', -100);

    // Le mois en cours : un retrait sur l'épargne, un chèque qui rembourse
    // deux dépenses, et quelques achats à reclasser.
    final ce = DateTime(aujourdhui.year, aujourdhui.month, 1);
    DateTime c(int jour) => DateTime(ce.year, ce.month, min(jour, aujourdhui.day));
    op(c(4), cb(c(3), 'SNCF VOYAGEURS'), -98);
    op(c(9), cb(c(8), 'RESTAURANT LA TABLE DU PORT'), -64);
    op(c(12), 'REMISE CHEQUE N 8841207', 162);
    op(c(14), 'VIR VERS CARTE BANCAIRE DE LIVRET CMB', 150);
    op(c(16), cb(c(15), 'GYMSHARK'), -64.80);
    op(c(18), cb(c(17), 'VINTED'), -18.50);
    op(c(19), 'VIR SEPA RECU VINTED', 24);

    await const DepotOperations().importer(courant.id, ops);

    // Le chèque rembourse le train et le restaurant.
    const depot = DepotOperations();
    final duMois = await depot.entre(ce, aujourdhui.add(const Duration(days: 1)));
    Operation? trouve(String debut) => duMois.where((o) => o.libelle.startsWith(debut)).firstOrNull;
    final cheque = trouve('REMISE CHEQUE');
    final train = trouve('PAIEMENT PAR CARTE X0000 SNCF');
    final resto = trouve('PAIEMENT PAR CARTE X0000 RESTAURANT');
    if (cheque != null && train != null && resto != null) {
      await const DepotLiens().repartir(cheque.id, {train.id: 9800, resto.id: 6400});
    }

    await comptes.definirSolde(courant.id, 128452);
    await comptes.ajouterLivret(nom: 'Livret CMB', soldeCentimes: 296000, motif: 'LIVRET CMB');
    await comptes.ajouterLivret(nom: 'Livret jeune', soldeCentimes: 160000, motif: 'LIVRET JEUNE');
    const reglages = DepotReglages();
    await reglages.ecrire('budget', '150000');
    await reglages.ecrire('objectif_epargne', '600000');
  }
}

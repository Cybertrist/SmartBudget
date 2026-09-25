import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';

import '../donnees/depots.dart';
import '../security/key_vault.dart';
import '../utils/fichiers.dart';
import 'enable_banking.dart';
import 'veille.dart';

/// Ce que l'application sait de sa connexion à la banque.
class EtatBanque {
  const EtatBanque({this.cle = false, this.banque, this.compte, this.jusquau, this.derniere});

  /// La clé privée d'Enable Banking a été importée.
  final bool cle;

  /// Le nom de la banque choisie.
  final String? banque;

  /// Le compte courant relié chez Enable Banking.
  final String? compte;

  /// La fin du consentement, 180 jours après l'autorisation.
  final DateTime? jusquau;

  /// La dernière synchronisation réussie.
  final DateTime? derniere;

  bool get relie => compte != null && jusquau != null && jusquau!.isAfter(DateTime.now());

  /// Jours avant de devoir renouveler l'accès.
  int? get joursRestants => jusquau?.difference(DateTime.now()).inDays;
}

/// La connexion au compte : la clé, l'autorisation, la synchronisation.
///
/// La clé privée est la donnée la plus sensible de l'application : elle
/// ouvre la lecture du compte. Elle est chiffrée en AES-GCM par sa propre
/// clé, dérivée de la clé maîtresse, et rangée dans la base elle-même
/// chiffrée. Elle n'est déchiffrée que le temps d'une requête.
class ConnexionBanque {
  const ConnexionBanque();

  static const _reglages = DepotReglages();
  static const _cleChiffree = 'banque_cle';
  static const _appId = 'banque_app_id';
  static const _banque = 'banque_nom';
  static const _pays = 'banque_pays';
  static const _dureeMax = 'banque_duree_max';
  static const _liste = 'banques_liste';
  static const _listeLe = 'banques_liste_le';
  static const _compte = 'banque_compte';
  static const _jusquau = 'banque_jusquau';
  static const _derniere = 'banque_derniere';
  static const _etat = 'banque_etat';
  static const _soldeLe = 'banque_solde_le';
  static const _canal = MethodChannel('smartbudget/banque');
  static const _historique = 'Crédit Mutuel de Bretagne';

  Future<EtatBanque> etat() async {
    final jusquau = await _reglages.lire(_jusquau);
    final derniere = await _reglages.lire(_derniere);
    final compte = await _reglages.lire(_compte);
    return EtatBanque(
      cle: await _reglages.lire(_cleChiffree) != null,
      // Avant le choix de la banque, seul le Crédit Mutuel de Bretagne
      // pouvait être relié.
      banque: await _reglages.lire(_banque) ?? (compte != null ? _historique : null),
      compte: compte,
      jusquau: jusquau == null ? null : DateTime.tryParse(jusquau),
      derniere: derniere == null ? null : DateTime.tryParse(derniere),
    );
  }

  // ------------------------------------------------------------------ clé

  /// Fait choisir le fichier .pem téléchargé du portail d'Enable Banking.
  /// Son nom est l'identifiant de l'application ; il est recopié chiffré,
  /// et la copie du cache est effacée aussitôt.
  Future<void> importerCle() async {
    final chemin = await Fichiers.choisir();
    if (chemin == null) return;
    final fichier = File(chemin);
    try {
      final pem = await fichier.readAsString();
      if (!pem.contains('PRIVATE KEY')) {
        throw const ErreurBanque('Ce fichier n\'est pas une clé privée : choisis le .pem téléchargé du portail d\'Enable Banking.');
      }
      if (pem.contains('RSA PRIVATE KEY')) {
        throw const ErreurBanque('Clé au format PKCS#1 : télécharge-la de nouveau depuis le portail, au format PKCS#8.');
      }
      final nom = await _canal.invokeMethod<String>('nomChoisi') ?? '';
      final id = RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').firstMatch(nom)?.group(0);
      if (id == null) {
        throw const ErreurBanque('Le nom du fichier ne contient pas l\'identifiant de l\'application : garde le nom donné par Enable Banking.');
      }
      await _reglages.ecrire(_cleChiffree, await _chiffrer(pem));
      await _reglages.ecrire(_appId, id);
    } finally {
      if (await fichier.exists()) await fichier.delete();
    }
  }

  Future<EnableBanking> _client() async {
    final chiffree = await _reglages.lire(_cleChiffree);
    final id = await _reglages.lire(_appId);
    if (chiffree == null || id == null) throw const ErreurBanque('Importe d\'abord la clé d\'Enable Banking.');
    return EnableBanking(appId: id, pem: await _dechiffrer(chiffree));
  }

  /// Une clé, chiffrée en AES-GCM par sa propre clé, dérivée de la clé
  /// maîtresse.
  Future<String> _chiffrer(String pem) async {
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final boite = await AesGcm.with256bits().encrypt(utf8.encode(pem), secretKey: await KeyVault.instance.banqueKey(), nonce: nonce);
    return base64Encode([...nonce, ...boite.cipherText, ...boite.mac.bytes]);
  }

  Future<String> _dechiffrer(String chiffree) async {
    final o = base64Decode(chiffree);
    final boite = SecretBox(o.sublist(12, o.length - 16), nonce: o.sublist(0, 12), mac: Mac(o.sublist(o.length - 16)));
    return utf8.decode(await AesGcm.with256bits().decrypt(boite, secretKey: await KeyVault.instance.banqueKey()));
  }

  // ---------------------------------------------------------------- banque

  /// Toutes les banques, pour la liste du choix. Enable Banking met
  /// plusieurs secondes à la donner : elle est gardée ici, rendue tout de
  /// suite, et remise à jour en silence une fois par semaine.
  Future<List<Banque>> banques() async {
    final gardee = await _reglages.lire(_liste);
    if (gardee == null) return _telechargerBanques();
    final le = DateTime.tryParse(await _reglages.lire(_listeLe) ?? '');
    if (le == null || DateTime.now().difference(le) > const Duration(days: 7)) {
      unawaited(_telechargerBanques().then((_) {}, onError: (_) {}));
    }
    return [
      for (final ligne in gardee.split('\n'))
        if (ligne.split('\t') case [final nom, final pays, final duree])
          Banque(nom: nom, pays: pays, dureeMax: switch (int.tryParse(duree)) {
            final int s => Duration(seconds: s),
            null => null,
          }),
    ];
  }

  Future<List<Banque>> _telechargerBanques() async {
    final liste = await EnableBanking.banques();
    await _reglages.ecrire(_liste, [for (final b in liste) '${b.nom}\t${b.pays}\t${b.dureeMax?.inSeconds ?? ''}'].join('\n'));
    await _reglages.ecrire(_listeLe, DateTime.now().toIso8601String());
    return liste;
  }

  /// Retient la banque choisie. Changer de banque oublie le compte relié.
  Future<void> choisirBanque(Banque b) async {
    final avant = (await etat()).banque;
    if (avant != null && avant != b.nom) await deconnecter();
    await _retenir(b);
  }

  Future<void> _retenir(Banque b) async {
    await _reglages.ecrire(_banque, b.nom);
    await _reglages.ecrire(_pays, b.pays);
    await _reglages.ecrire(_dureeMax, b.dureeMax?.inSeconds.toString());
  }

  /// Le pays de la banque choisie, la France sinon.
  Future<String> pays() async => await _reglages.lire(_pays) ?? 'FR';

  // ---------------------------------------------------------- autorisation

  /// Ouvre la page de la banque. Au retour, [terminer] reçoit le lien.
  Future<void> autoriser() async {
    final client = await _client();
    var banque = await _reglages.lire(_banque);
    if (banque == null && await _reglages.lire(_compte) != null) {
      // Un compte relié avant le choix de la banque : le Crédit Mutuel de
      // Bretagne, dont le nom exact se cherche dans la liste.
      final b = (await banques()).where((b) => b.pays == 'FR').where((b) => b.nom.toLowerCase().contains('bretagne') && b.nom.toLowerCase().contains('mutuel'));
      if (b.isNotEmpty) {
        await _retenir(b.first);
        banque = b.first.nom;
      }
    }
    if (banque == null) throw const ErreurBanque('Choisis d\'abord ta banque.');
    final duree = int.tryParse(await _reglages.lire(_dureeMax) ?? '');
    final etat = base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    await _reglages.ecrire(_etat, etat);
    final url = await client.autoriser(
      banque: banque,
      pays: await pays(),
      dureeMax: duree == null ? null : Duration(seconds: duree),
      etat: etat,
    );
    await EnableBanking.ouvrirLien(url);
  }

  /// Le lien de retour de la banque, s'il en attend un.
  Future<String?> lienEnAttente() => _canal.invokeMethod<String>('lienEnAttente');

  /// Termine l'autorisation avec le lien smartbudget://banque?code=…&state=…
  Future<void> terminer(String lien) async {
    final uri = Uri.parse(lien);
    final erreur = uri.queryParameters['error'];
    if (erreur != null) throw ErreurBanque('La banque a refusé l\'accès : ${uri.queryParameters['error_description'] ?? erreur}.');
    final code = uri.queryParameters['code'];
    if (code == null) throw const ErreurBanque('Le retour de la banque ne contient pas de code.');
    // Le jeton d'état empêche un lien fabriqué ailleurs de relier un autre compte.
    if (uri.queryParameters['state'] != await _reglages.lire(_etat)) {
      throw const ErreurBanque('Retour de la banque inattendu : relance la connexion.');
    }
    final session = await (await _client()).ouvrirSession(code);
    if (session.comptes.isEmpty) throw const ErreurBanque('La banque n\'a partagé aucun compte.');
    await _reglages.ecrire(_compte, session.comptes.first.uid);
    await _reglages.ecrire(_jusquau, session.jusquau.toIso8601String());
    await _reglages.ecrire(_etat, null);
  }

  /// Oublie l'accès au compte. La clé reste, pour se reconnecter.
  Future<void> deconnecter() async {
    for (final c in [_compte, _jusquau, _derniere, _soldeLe]) {
      await _reglages.ecrire(c, null);
    }
    await Veille.arreter();
  }

  // -------------------------------------------------------- synchronisation

  /// Importe les opérations et met à jour le solde. La première fois, les
  /// douze derniers mois ; ensuite, depuis une semaine avant la dernière
  /// fois, pour rattraper les opérations comptabilisées en retard. Rend le
  /// nombre d'opérations nouvelles.
  Future<int> synchroniser() async {
    final e = await etat();
    if (!e.relie) throw const ErreurBanque('Le compte n\'est pas relié, ou l\'accès a expiré : reconnecte-le.');
    final client = await _client();
    final depuis = e.derniere?.subtract(const Duration(days: 7)) ?? DateTime.now().subtract(const Duration(days: 365));
    final operations = await client.operations(e.compte!, depuis);
    final courant = await const DepotComptes().courant();
    final nouvelles = await const DepotOperations().importer(courant.id, operations);
    final solde = await client.solde(e.compte!);
    if (solde != null) await _retenirSolde(courant.id, solde);
    await _reglages.ecrire(_derniere, DateTime.now().toIso8601String());
    return nouvelles;
  }

  /// Le solde seul, sans les opérations : ce que lit la veille en
  /// arrière-plan. Rien si une lecture a eu lieu il y a moins de
  /// [depuisAuMoins] : la banque limite les accès faits sans l'utilisateur.
  Future<void> lireSolde({Duration depuisAuMoins = Duration.zero}) async {
    final e = await etat();
    if (!e.relie) return;
    final le = DateTime.tryParse(await _reglages.lire(_soldeLe) ?? '');
    if (le != null && DateTime.now().difference(le) < depuisAuMoins) return;
    final solde = await (await _client()).solde(e.compte!);
    if (solde != null) await _retenirSolde((await const DepotComptes().courant()).id, solde);
  }

  Future<void> _retenirSolde(int compte, int solde) async {
    await const DepotComptes().definirSolde(compte, solde);
    await _reglages.ecrire(_soldeLe, DateTime.now().toIso8601String());
    await Veille.verifier(solde);
  }
}

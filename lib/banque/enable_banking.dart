import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../domaine/modeles.dart';
import 'rs256.dart';

/// Le client d'Enable Banking, l'agrégateur qui lit le compte courant par
/// la DSP2, dans la banque choisie.
///
/// Chaque requête porte un JWT signé en RS256 avec la clé privée de
/// l'application, par pointycastle : en Dart, pour que la vérification du
/// solde en arrière-plan puisse signer elle aussi.
///
/// Le mode restreint d'Enable Banking ne donne accès qu'aux comptes reliés
/// sur son portail : ceux de Tristan, et personne d'autre.
class EnableBanking {
  EnableBanking({required this.appId, required this.pem});

  /// L'identifiant de l'application, le nom du fichier de clé.
  final String appId;

  /// La clé privée, en clair le temps d'une synchronisation seulement.
  final String pem;

  static const _hote = 'api.enablebanking.com';
  static const _canal = MethodChannel('smartbudget/banque');

  /// La page qui renvoie le code d'autorisation à l'application.
  static const redirection = 'https://cybertrist.github.io/SmartBudget/';

  static String _b64(List<int> octets) => base64Url.encode(octets).replaceAll('=', '');

  String _jwt() {
    final maintenant = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final entete = _b64(utf8.encode(jsonEncode({'typ': 'JWT', 'alg': 'RS256', 'kid': appId})));
    final charge = _b64(utf8.encode(jsonEncode({
      'iss': 'enablebanking.com',
      'aud': 'api.enablebanking.com',
      'iat': maintenant,
      'exp': maintenant + 3600,
    })));
    return '$entete.$charge.${_b64(signerRs256(pem, '$entete.$charge'))}';
  }

  Future<dynamic> _requete(String methode, String chemin, {Map<String, String>? parametres, Object? corps}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final requete = await client.openUrl(methode, Uri.https(_hote, chemin, parametres));
      requete.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${_jwt()}');
      requete.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (corps != null) {
        requete.headers.contentType = ContentType.json;
        requete.add(utf8.encode(jsonEncode(corps)));
      }
      final reponse = await requete.close().timeout(const Duration(seconds: 40));
      final texte = await reponse.transform(utf8.decoder).join();
      if (reponse.statusCode >= 400) throw ErreurBanque.depuis(reponse.statusCode, texte);
      return texte.isEmpty ? null : jsonDecode(texte);
    } on SocketException {
      throw const ErreurBanque('Pas de connexion à Internet.');
    } finally {
      client.close();
    }
  }

  /// Les banques qu'Enable Banking sait lire pour un particulier, tous
  /// pays confondus, par ordre alphabétique. La liste publique du portail :
  /// elle ne demande pas de clé, on choisit donc sa banque avant d'en avoir
  /// une.
  static Future<List<Banque>> banques() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final reponse = await (await client.getUrl(Uri.https('enablebanking.com', '/api/aspsps'))).close().timeout(const Duration(seconds: 40));
      final texte = await reponse.transform(utf8.decoder).join();
      if (reponse.statusCode >= 400) throw ErreurBanque.depuis(reponse.statusCode, texte);
      // Trois mégaoctets de JSON : lus à côté, pour que l'écran reste fluide.
      return await Isolate.run(() => lireBanques(texte));
    } on SocketException {
      throw const ErreurBanque('Pas de connexion à Internet.');
    } finally {
      client.close();
    }
  }

  /// La liste des banques, tirée de la réponse d'Enable Banking.
  static List<Banque> lireBanques(String texte) {
    final r = jsonDecode(texte) as Map<String, dynamic>;
    final liste = [
      for (final a in (r['aspsps'] as List? ?? const []).cast<Map>())
        if ((a['psu_types'] as List?)?.contains('personal') ?? true)
          Banque(
            nom: a['name'] as String,
            pays: a['country'] as String? ?? '',
            logo: a['logo'] as String?,
            dureeMax: switch (a['maximum_consent_validity']) {
              final int s when s > 0 => Duration(seconds: s),
              _ => null,
            },
          ),
    ];
    return liste..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
  }

  /// Ouvre une demande d'autorisation : rend l'adresse où l'utilisateur
  /// se connecte à sa banque. Le consentement dure 180 jours, ou moins si
  /// la banque n'en accorde pas autant.
  Future<String> autoriser({required String banque, required String pays, Duration? dureeMax, required String etat}) async {
    var duree = const Duration(days: 180);
    if (dureeMax != null && dureeMax < duree) duree = dureeMax;
    final r = await _requete('POST', '/auth', corps: {
      'access': {'valid_until': DateTime.now().toUtc().add(duree).toIso8601String()},
      'aspsp': {'name': banque, 'country': pays},
      'state': etat,
      'redirect_url': redirection,
      'psu_type': 'personal',
    }) as Map<String, dynamic>;
    return r['url'] as String;
  }

  /// Échange le code reçu contre une session et ses comptes.
  Future<Session> ouvrirSession(String code) async {
    final r = await _requete('POST', '/sessions', corps: {'code': code}) as Map<String, dynamic>;
    return Session(
      id: r['session_id'] as String,
      jusquau: DateTime.parse((r['access'] as Map)['valid_until'] as String),
      comptes: [
        for (final c in r['accounts'] as List)
          CompteBanque(
            uid: (c as Map)['uid'] as String,
            nom: c['name'] as String?,
            iban: ((c['account_id'] as Map?)?['iban']) as String?,
          ),
      ],
    );
  }

  /// Le solde du compte, en centimes. La banque en donne plusieurs : le
  /// solde comptable de clôture d'abord, sinon le premier venu.
  Future<int?> solde(String compte) async {
    final r = await _requete('GET', '/accounts/$compte/balances') as Map<String, dynamic>;
    final soldes = [for (final b in r['balances'] as List) b as Map];
    if (soldes.isEmpty) return null;
    Map pris = soldes.first;
    for (final type in const ['CLBD', 'ITBD', 'XPCD', 'CLAV', 'ITAV']) {
      final t = soldes.where((b) => b['balance_type'] == type);
      if (t.isNotEmpty) {
        pris = t.first;
        break;
      }
    }
    return _centimes((pris['balance_amount'] as Map)['amount']);
  }

  /// Les opérations depuis [depuis], page après page : les comptabilisées,
  /// puis celles en attente, un paiement par carte du jour que le solde
  /// compte déjà. Une banque qui ne donne pas les secondes rend les
  /// premières seules.
  Future<List<OperationBrute>> operations(String compte, DateTime depuis) async {
    final sortie = await _page(compte, depuis, 'BOOK');
    try {
      // Deux cafés au même prix le même jour ont la même empreinte : la
      // seconde prend un numéro.
      final vues = <String, int>{};
      for (final o in await _page(compte, depuis, 'PDNG')) {
        final n = vues[o.uidBanque] = (vues[o.uidBanque] ?? 0) + 1;
        sortie.add(n == 1
            ? o
            : OperationBrute(uidBanque: '${o.uidBanque}-$n', le: o.le, libelle: o.libelle, montantCentimes: o.montantCentimes, enAttente: true));
      }
    } on ErreurBanque {
      // Pas d'opérations en attente chez cette banque.
    }
    return sortie;
  }

  Future<List<OperationBrute>> _page(String compte, DateTime depuis, String statut) async {
    final sortie = <OperationBrute>[];
    String? suite;
    do {
      final r = await _requete('GET', '/accounts/$compte/transactions', parametres: {
        'date_from': depuis.toIso8601String().substring(0, 10),
        'transaction_status': statut,
        'continuation_key': ?suite,
      }) as Map<String, dynamic>;
      for (final t in (r['transactions'] as List? ?? const [])) {
        final o = _operation(t as Map, enAttente: statut == 'PDNG');
        if (o != null) sortie.add(o);
      }
      suite = r['continuation_key'] as String?;
    } while (suite != null && suite.isNotEmpty);
    return sortie;
  }

  static OperationBrute? _operation(Map t, {bool enAttente = false}) {
    final montant = _centimes((t['transaction_amount'] as Map?)?['amount']);
    final date = (t['booking_date'] ?? t['value_date'] ?? t['transaction_date']) as String?;
    if (montant == null || date == null) return null;
    final signe = t['credit_debit_indicator'] == 'CRDT' ? 1 : -1;
    final libelle = [
      ...((t['remittance_information'] as List?) ?? const []).cast<String>(),
    ].join(' ').trim();
    final tiers = (signe > 0 ? t['debtor'] : t['creditor']) as Map?;
    final nom = libelle.isNotEmpty ? libelle : (tiers?['name'] as String? ?? 'Opération');
    // La référence de la banque, sinon une empreinte stable de l'opération :
    // une synchronisation relancée ne doit rien doubler.
    // En attente, la référence change au passage : l'empreinte suffit,
    // l'opération est de toute façon remplacée à chaque synchronisation.
    final uid = enAttente
        ? 'attente-$date-${signe * montant.abs()}-$nom'
        : (t['entry_reference'] ?? t['transaction_id']) as String? ?? 'eb-$date-$montant-${nom.hashCode}';
    return OperationBrute(uidBanque: uid, le: DateTime.parse(date), libelle: nom, montantCentimes: signe * montant.abs(), enAttente: enAttente);
  }

  static int? _centimes(Object? montant) {
    final v = double.tryParse('${montant ?? ''}');
    return v == null ? null : (v * 100).round();
  }

  /// Ouvre une adresse dans le navigateur.
  static Future<void> ouvrirLien(String url) => _canal.invokeMethod('ouvrirLien', {'url': url});
}

class Session {
  const Session({required this.id, required this.jusquau, required this.comptes});

  final String id;
  final DateTime jusquau;
  final List<CompteBanque> comptes;
}

/// Une banque de la liste d'Enable Banking.
class Banque {
  const Banque({required this.nom, required this.pays, this.logo, this.dureeMax});

  /// Le nom exact attendu par Enable Banking.
  final String nom;

  /// Le code du pays, sur deux lettres.
  final String pays;

  /// L'adresse du logo, chez Enable Banking.
  final String? logo;

  /// La durée d'accès la plus longue que la banque accorde.
  final Duration? dureeMax;
}

class CompteBanque {
  const CompteBanque({required this.uid, this.nom, this.iban});

  final String uid;
  final String? nom;
  final String? iban;
}

/// Une erreur de la banque, dite en français.
class ErreurBanque implements Exception {
  const ErreurBanque(this.message);

  factory ErreurBanque.depuis(int statut, String texte) {
    String detail = texte;
    try {
      final j = jsonDecode(texte) as Map;
      detail = (j['message'] ?? j['detail'] ?? j['error'] ?? texte).toString();
    } catch (_) {}
    return switch (statut) {
      401 => ErreurBanque('Enable Banking refuse la clé : vérifie la clé importée et l\'identifiant d\'application. ($detail)'),
      403 => ErreurBanque('Accès refusé par la banque : le consentement a peut-être expiré. ($detail)'),
      429 => const ErreurBanque('Trop de synchronisations aujourd\'hui : la banque en limite le nombre. Réessaie demain.'),
      _ => ErreurBanque('Erreur de la banque ($statut) : $detail'),
    };
  }

  final String message;

  @override
  String toString() => message;
}

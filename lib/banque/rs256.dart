import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Signe en RS256 avec la clé privée d'Enable Banking, au format PKCS#8
/// que donne son portail.
///
/// En Dart, et non plus en natif : la vérification du solde tourne dans un
/// moteur Flutter lancé en arrière-plan par WorkManager, où les canaux de
/// l'activité n'existent pas. RSASSA-PKCS1-v1_5 est déterministe : la
/// signature est, octet pour octet, celle d'OpenSSL, ce que vérifie un
/// test.
Uint8List signerRs256(String pem, String donnees) {
  final cle = _clePrivee(pem);
  final signataire = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(cle));
  return signataire.generateSignature(Uint8List.fromList(utf8.encode(donnees))).bytes;
}

/// Lit une clé PKCS#8 : une séquence dont le troisième élément enveloppe,
/// dans une chaîne d'octets, la clé RSA elle-même (PKCS#1).
RSAPrivateKey _clePrivee(String pem) {
  final corps = pem
      .replaceAll('-----BEGIN PRIVATE KEY-----', '')
      .replaceAll('-----END PRIVATE KEY-----', '')
      .replaceAll(RegExp(r'\s'), '');
  final pkcs8 = ASN1Parser(Uint8List.fromList(base64Decode(corps))).nextObject() as ASN1Sequence;
  final enveloppe = pkcs8.elements![2] as ASN1OctetString;
  final rsa = ASN1Parser(enveloppe.valueBytes!).nextObject() as ASN1Sequence;
  BigInt n(int i) => (rsa.elements![i] as ASN1Integer).integer!;
  // version, n, e, d, p, q, puis les valeurs des restes chinois.
  return RSAPrivateKey(n(1), n(3), n(4), n(5));
}

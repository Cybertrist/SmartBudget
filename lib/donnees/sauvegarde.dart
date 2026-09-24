import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'base.dart';

/// Sauvegarde et restauration.
///
/// Une sauvegarde sort toutes les données de l'application, et un fichier
/// voyage : il atterrit dans Téléchargements, part sur un ordinateur, dans
/// un nuage. Il est donc chiffré avec une phrase choisie au moment de
/// l'export, et non avec la clé de l'appareil : autrement, il serait
/// illisible sur un nouveau téléphone. Sans la phrase, rien ne se relit.
///
/// Format :
///
///     "SBEX1" (5 octets) | sel (16) | nonce (12) | chiffré | MAC (16)
///
/// Le clair est un JSON compressé : la version de la base, et les lignes
/// de chaque table.
class Sauvegarde {
  const Sauvegarde._();

  static const _magie = [0x53, 0x42, 0x45, 0x58, 0x31]; // SBEX1
  static const _sel = 16;
  static const _nonce = 12;
  static const _mac = 16;

  /// Coût de dérivation, comme BodyCount : environ une seconde sur un
  /// téléphone, assez pour qu'une phrase moyenne résiste hors ligne.
  static const _iterations = 210000;

  /// Les tables, dans l'ordre où elles se remplissent : une ligne ne
  /// pointe que vers des tables déjà remplies.
  static const _tables = ['categories', 'comptes', 'operations', 'regles', 'liens', 'reglages'];

  /// Écrit une sauvegarde chiffrée dans un fichier temporaire et rend son
  /// chemin. [phrase] fait au moins 8 caractères.
  static Future<String> exporter(String phrase) async {
    if (phrase.length < 8) throw ArgumentError('La phrase doit faire au moins 8 caractères.');
    final db = await Base.instance.db;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final t in _tables) {
      tables[t] = await db.query(t);
    }
    final clair = utf8.encode(jsonEncode({
      'format': 'smartbudget',
      'version': await _version(db),
      'cree_le': DateTime.now().toIso8601String(),
      'tables': tables,
    }));

    final octets = await Isolate.run(() => _chiffrer(phrase, clair));
    final dossier = await getTemporaryDirectory();
    final chemin = p.join(dossier.path, 'smartbudget.sbx');
    await File(chemin).writeAsBytes(octets, flush: true);
    return chemin;
  }

  /// Le nom proposé pour le fichier : la date du jour.
  static String nomFichier() {
    final d = DateTime.now();
    String n(int v) => v.toString().padLeft(2, '0');
    return 'smartbudget-${d.year}-${n(d.month)}-${n(d.day)}.sbx';
  }

  /// Relit une sauvegarde et remplace toutes les données par les siennes.
  /// Une phrase fausse, ou un fichier qui n'en est pas un, lève une
  /// [FormatException] sans rien toucher.
  static Future<void> restaurer(String chemin, String phrase) async {
    final octets = await File(chemin).readAsBytes();
    final clair = await Isolate.run(() => _dechiffrer(phrase, octets));
    final Map<String, dynamic> contenu;
    try {
      contenu = jsonDecode(utf8.decode(clair)) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Ce fichier n\'est pas une sauvegarde de Smart Budget.');
    }
    if (contenu['format'] != 'smartbudget') {
      throw const FormatException('Ce fichier n\'est pas une sauvegarde de Smart Budget.');
    }
    final db = await Base.instance.db;
    if ((contenu['version'] as int? ?? 0) > await _version(db)) {
      throw const FormatException('Cette sauvegarde vient d\'une version plus récente de l\'application : mets-la à jour d\'abord.');
    }
    final tables = (contenu['tables'] as Map<String, dynamic>);

    await db.transaction((t) async {
      for (final nom in _tables.reversed) {
        await t.delete(nom);
      }
      for (final nom in _tables) {
        // Seules les colonnes que la base connaît : une sauvegarde plus
        // ancienne n'a pas les dernières, qui prennent leur valeur par
        // défaut.
        final colonnes = {for (final c in await t.rawQuery('PRAGMA table_info($nom)')) c['name']! as String};
        var lignes = [for (final l in (tables[nom] as List? ?? const [])) Map<String, Object?>.from(l as Map)];
        // Les catégories racines avant leurs sous-catégories.
        if (nom == 'categories') {
          lignes.sort((a, b) => (a['parent_id'] == null ? 0 : 1).compareTo(b['parent_id'] == null ? 0 : 1));
        }
        for (final l in lignes) {
          l.removeWhere((cle, _) => !colonnes.contains(cle));
          await t.insert(nom, l);
        }
      }
    });
  }

  /// La version du schéma, celle que SQLite garde dans user_version.
  static Future<int> _version(Database db) async =>
      (await db.rawQuery('PRAGMA user_version')).first.values.first as int? ?? 0;

  // ------------------------------------------------------------- chiffrement

  static Future<SecretKey> _cle(String phrase, List<int> sel) => Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: _iterations,
        bits: 256,
      ).deriveKeyFromPassword(password: phrase, nonce: sel);

  static Future<Uint8List> _chiffrer(String phrase, List<int> clair) async {
    final hasard = Random.secure();
    final sel = List<int>.generate(_sel, (_) => hasard.nextInt(256));
    final nonce = List<int>.generate(_nonce, (_) => hasard.nextInt(256));
    final boite = await AesGcm.with256bits().encrypt(
      GZipCodec().encode(clair),
      secretKey: await _cle(phrase, sel),
      nonce: nonce,
    );
    return Uint8List.fromList([..._magie, ...sel, ...nonce, ...boite.cipherText, ...boite.mac.bytes]);
  }

  static Future<List<int>> _dechiffrer(String phrase, Uint8List octets) async {
    const entete = 5 + _sel + _nonce;
    if (octets.length < entete + _mac) {
      throw const FormatException('Ce fichier n\'est pas une sauvegarde de Smart Budget.');
    }
    for (var i = 0; i < _magie.length; i++) {
      if (octets[i] != _magie[i]) throw const FormatException('Ce fichier n\'est pas une sauvegarde de Smart Budget.');
    }
    final sel = octets.sublist(5, 5 + _sel);
    final nonce = octets.sublist(5 + _sel, entete);
    final boite = SecretBox(
      octets.sublist(entete, octets.length - _mac),
      nonce: nonce,
      mac: Mac(octets.sublist(octets.length - _mac)),
    );
    try {
      final clair = await AesGcm.with256bits().decrypt(boite, secretKey: await _cle(phrase, sel));
      return GZipCodec().decode(clair);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Phrase incorrecte, ou fichier abîmé.');
    }
  }
}

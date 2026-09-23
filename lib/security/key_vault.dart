import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Trousseau de l'application, repris de BodyCount.
///
/// Une clé maîtresse de 32 octets est tirée au hasard au premier lancement
/// et rangée dans le Keystore Android. Elle ne quitte jamais l'appareil et
/// n'entre en mémoire qu'après l'empreinte.
///
/// Tout le reste en dérive par HKDF, une étiquette par usage : la base, et
/// la clé privée d'Enable Banking, qui ouvre l'accès en lecture au compte.
/// Cette dernière est la donnée la plus sensible de l'application : elle
/// vit chiffrée par sa propre clé dérivée, jamais en clair sur le disque.
class KeyVault {
  KeyVault._();

  static final KeyVault instance = KeyVault._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _masterKeyName = 'smartbudget_master_key_v1';

  /// Étiquettes HKDF. Ce sont des constantes de format : en changer une
  /// rend illisible ce qu'elle protège.
  static const _dbLabel = 'smartbudget/db/v1';
  static const _banqueLabel = 'smartbudget/banque/v1';

  Uint8List? _master;
  String? _dbPassword;
  SecretKey? _banqueKey;

  bool get isUnlocked => _master != null;

  /// Charge la clé maîtresse, ou la crée au premier lancement.
  Future<void> unlock() async {
    if (_master != null) return;

    final stored = await _storage.read(key: _masterKeyName);
    if (stored != null) {
      _master = Uint8List.fromList(base64Decode(stored));
      return;
    }

    final fresh = _randomBytes(32);
    await _storage.write(key: _masterKeyName, value: base64Encode(fresh));
    _master = fresh;
  }

  /// Oublie les clés, en écrasant les octets de la maîtresse avant de la
  /// lâcher plutôt que de les laisser au ramasse-miettes.
  void lock() {
    final master = _master;
    if (master != null) {
      for (var i = 0; i < master.length; i++) {
        master[i] = 0;
      }
    }
    _master = null;
    _dbPassword = null;
    _banqueKey = null;
  }

  /// Mot de passe SQLCipher, en hexadécimal.
  Future<String> databasePassword() async {
    final cached = _dbPassword;
    if (cached != null) return cached;

    final bytes = await _derive(_dbLabel, 32);
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _dbPassword = hex;
    return hex;
  }

  /// Clé AES-GCM qui chiffre la clé privée d'Enable Banking.
  Future<SecretKey> banqueKey() async {
    final cached = _banqueKey;
    if (cached != null) return cached;

    final key = SecretKey(await _derive(_banqueLabel, 32));
    _banqueKey = key;
    return key;
  }

  /// Efface la clé maîtresse : la base et la clé bancaire restées sur le
  /// disque deviennent illisibles pour tout le monde, application comprise.
  Future<void> destroy() async {
    await _storage.delete(key: _masterKeyName);
    lock();
  }

  Future<List<int>> _derive(String label, int length) async {
    final master = _master;
    if (master == null) {
      throw StateError(
        'Le trousseau est verrouillé : appeler unlock() après authentification.',
      );
    }

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: length);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(master),
      info: utf8.encode(label),
      nonce: const <int>[],
    );
    return derived.extractBytes();
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}

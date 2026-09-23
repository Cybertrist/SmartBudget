import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../security/screen_guard.dart';

/// Les réglages de sécurité, comme sur BodyCount.
///
/// Ils vivent dans le stockage sécurisé et non dans la base : il faut les
/// lire avant l'empreinte, pour savoir s'il faut la demander.
class Securite {
  const Securite({this.verrou = true, this.delai = const Duration(minutes: 2), this.masquer = true});

  /// L'empreinte à l'ouverture.
  final bool verrou;

  /// Le délai avant de reverrouiller, sans geste ou en arrière plan.
  final Duration delai;

  /// Captures bloquées et aperçu du multitâche masqué.
  final bool masquer;

  Securite copie({bool? verrou, Duration? delai, bool? masquer}) =>
      Securite(verrou: verrou ?? this.verrou, delai: delai ?? this.delai, masquer: masquer ?? this.masquer);
}

class SecuriteNotifier extends StateNotifier<Securite> {
  SecuriteNotifier() : super(const Securite()) {
    _charger();
  }

  static const _stock = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  /// Lu une fois au démarrage : l'écran d'ouverture l'attend.
  static Future<Securite> lire() async {
    final v = await _stock.read(key: 'securite_verrou');
    final d = int.tryParse(await _stock.read(key: 'securite_delai') ?? '');
    final m = await _stock.read(key: 'securite_masquer');
    return Securite(
      verrou: v != 'non',
      delai: Duration(seconds: d ?? 120),
      masquer: m != 'non',
    );
  }

  Future<void> _charger() async {
    state = await lire();
    await ScreenGuard.setProtected(state.masquer);
  }

  Future<void> verrou(bool actif) async {
    await _stock.write(key: 'securite_verrou', value: actif ? 'oui' : 'non');
    state = state.copie(verrou: actif);
  }

  Future<void> delai(Duration d) async {
    await _stock.write(key: 'securite_delai', value: '${d.inSeconds}');
    state = state.copie(delai: d);
  }

  Future<void> masquer(bool actif) async {
    await _stock.write(key: 'securite_masquer', value: actif ? 'oui' : 'non');
    await ScreenGuard.setProtected(actif);
    state = state.copie(masquer: actif);
  }
}

final securiteProvider = StateNotifierProvider<SecuriteNotifier, Securite>((ref) => SecuriteNotifier());

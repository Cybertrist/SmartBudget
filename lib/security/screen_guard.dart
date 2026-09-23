import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Protection de l'écran contre les captures et l'aperçu du multitâche.
///
/// Le drapeau est posé côté Android dès le démarrage de l'activité ; ce
/// canal ne sert qu'à le retirer, si l'utilisateur le décide dans les
/// réglages, puis à le remettre.
class ScreenGuard {
  ScreenGuard._();

  static const _channel = MethodChannel('smartbudget/ecran');

  /// Actif par défaut : on le remet à chaque démarrage tant que le réglage
  /// n'a pas dit le contraire.
  static Future<void> setProtected(bool value) async {
    if (!defaultTargetPlatform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('protegerEcran', {'actif': value});
    } on MissingPluginException {
      // Rien à faire : sur une plateforme sans canal, la protection est
      // simplement absente, ce n'est pas une raison de planter.
    }
  }
}

extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}

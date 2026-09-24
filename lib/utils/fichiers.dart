import 'package:flutter/services.dart';

import '../security/lock_state.dart';

/// Le sélecteur de fichiers du système, pour lire et écrire les
/// sauvegardes. Repris de BodyCount.
///
/// Il passe par le code natif de l'activité plutôt que par un paquet : deux
/// appels suffisent, et le sélecteur du système donne accès à tous les
/// emplacements sans que l'application demande le droit de lire le
/// stockage entier.
///
/// Le sélecteur met l'application en arrière-plan. Le verrou est retenu le
/// temps de l'aller-retour, sinon un délai court verrouillerait au retour,
/// au milieu de l'opération.
class Fichiers {
  static const _canal = MethodChannel('smartbudget/fichiers');

  /// Laisse choisir un fichier et rend le chemin d'une copie privée, ou
  /// null si rien n'a été choisi.
  static Future<String?> choisir() {
    return EtatVerrou.instance.retenir(() => _canal.invokeMethod<String>('ouvrir'));
  }

  /// Laisse choisir où enregistrer [chemin], sous le nom proposé [nom].
  /// Vrai si le fichier a été écrit.
  static Future<bool> enregistrer(String chemin, String nom) async {
    final ok = await EtatVerrou.instance.retenir(
      () => _canal.invokeMethod<bool>('enregistrer', {'chemin': chemin, 'nom': nom}),
    );
    return ok ?? false;
  }
}

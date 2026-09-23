import 'package:flutter/foundation.dart';

/// État du verrou, partagé entre le routeur et le reste de l'application.
///
/// GoRouter a besoin d'un [Listenable] pour réévaluer ses redirections ;
/// cette classe reste la seule source de vérité sur « l'application est-elle
/// ouverte ».
class EtatVerrou extends ChangeNotifier {
  EtatVerrou._();

  static final EtatVerrou instance = EtatVerrou._();

  bool _unlocked = false;
  bool get isUnlocked => _unlocked;

  /// Instant du passage en arrière plan, pour le reverrouillage automatique.
  DateTime? pausedAt;

  int _retenues = 0;

  /// Vrai pendant un travail qui ne doit pas être coupé : une
  /// synchronisation avec la banque, ou le passage par le navigateur pour
  /// valider l'accès au compte. Ce passage met l'application en arrière
  /// plan le temps de la validation Safetrans : verrouiller à ce moment-là
  /// ferait perdre le retour de la banque.
  bool get retenu => _retenues > 0;

  /// Retient le verrou le temps de [travail], puis le relâche. Relâcher
  /// prévient les écouteurs, qui relancent alors le compte à rebours.
  Future<T> retenir<T>(Future<T> Function() travail) async {
    _retenues++;
    try {
      return await travail();
    } finally {
      _retenues--;
      if (_retenues == 0) notifyListeners();
    }
  }

  void setUnlocked(bool value) {
    if (_unlocked == value) return;
    _unlocked = value;
    notifyListeners();
  }
}

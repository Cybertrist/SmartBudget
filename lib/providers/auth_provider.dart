import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../donnees/base.dart';
import '../security/key_vault.dart';
import '../security/lock_state.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Déverrouillage de l'application, repris de BodyCount.
///
/// L'empreinte ne masque pas un écran : tant qu'elle n'a pas été présentée,
/// la clé du trousseau n'est pas chargée, donc la base et la clé bancaire
/// restent illisibles. Contourner l'écran de garde ne donnerait accès à
/// rien.
class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Demande l'empreinte, et rend la raison d'un échec plutôt qu'un simple
  /// faux : un « refusé » muet ne dit pas si le doigt était mal posé ou si
  /// le téléphone n'a aucun verrou.
  Future<ResultatOuverture> authenticate() async {
    bool authentifie;
    try {
      authentifie = await _auth.authenticate(
        localizedReason: 'Déverrouille SmartBudget',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      return ResultatOuverture.echec(_expliquer(e));
    } catch (e) {
      return ResultatOuverture.echec('Erreur inattendue : $e');
    }

    // Fermer la demande n'est pas une erreur, c'est un choix.
    if (!authentifie) return const ResultatOuverture.annule();

    // La clé n'entre en mémoire qu'ici, une fois l'identité prouvée.
    await KeyVault.instance.unlock();
    EtatVerrou.instance.setUnlocked(true);
    return const ResultatOuverture.succes();
  }

  String _expliquer(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'Le capteur ne répond pas. Réessaie dans un instant.';
      case 'NotEnrolled':
        return 'Aucune empreinte ni code enregistré sur ce téléphone.\n'
            'Ajoute un verrou dans les réglages Android, puis reviens.';
      case 'LockedOut':
        return 'Trop d\'essais. Attends trente secondes.';
      case 'PermanentlyLockedOut':
        return 'Capteur bloqué. Déverrouille le téléphone avec ton code, '
            'puis rouvre SmartBudget.';
      default:
        return '${e.code} · ${e.message ?? "sans détail"}';
    }
  }

  /// Referme tout : la connexion à la base, puis les clés.
  Future<void> lock() async {
    EtatVerrou.instance.setUnlocked(false);
    await Base.instance.fermer();
    KeyVault.instance.lock();
  }
}

/// Le résultat d'une tentative d'ouverture.
class ResultatOuverture {
  const ResultatOuverture.succes()
      : raison = null,
        annule = false;
  const ResultatOuverture.echec(this.raison) : annule = false;
  const ResultatOuverture.annule()
      : raison = null,
        annule = true;

  final bool annule;
  final String? raison;

  bool get ouvert => raison == null && !annule;
}

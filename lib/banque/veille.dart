import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../config/format.dart';
import '../donnees/base.dart';
import '../donnees/depots.dart';
import '../security/key_vault.dart';
import 'connexion.dart';

/// La veille du compte courant : la seule notification de l'application,
/// quand le compte passe en négatif.
///
/// Toutes les six heures, même application fermée, Android réveille un
/// moteur Flutter qui lit le solde, et seulement lui. Quatre lectures par
/// jour au plus : c'est ce que la DSP2 accorde aux accès faits sans
/// l'utilisateur. Pour lire, il faut la clé bancaire, donc la clé
/// maîtresse : elle est chargée sans empreinte le temps de cette lecture,
/// puis oubliée. C'est le prix de l'alerte, et le README le dit.
///
/// Une seule notification par passage en négatif : la suivante attend que
/// le compte soit remonté au-dessus de zéro, puis redescendu.
class Veille {
  const Veille._();

  static const _tache = 'smartbudget.solde';
  static const _dejaPrevenu = 'alerte_negatif';
  static const _canal = 'compte_negatif';
  static final _notifications = FlutterLocalNotificationsPlugin();

  /// À appeler au démarrage : prépare le moteur d'arrière-plan.
  static Future<void> preparer() => Workmanager().initialize(rappelVeille);

  /// Lance la veille, ou la laisse telle quelle si elle tourne déjà.
  static Future<void> planifier() => Workmanager().registerPeriodicTask(
        _tache,
        _tache,
        frequency: const Duration(hours: 6),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

  /// Arrête la veille : compte délié, ou tout effacé.
  static Future<void> arreter() => Workmanager().cancelByUniqueName(_tache);

  /// Demande le droit de notifier, qu'Android 13 veut explicite.
  static Future<void> demanderPermission() async {
    await _initialiser();
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Compare le solde du compte courant à zéro, après chaque lecture de la
  /// banque, au premier plan comme en arrière-plan.
  static Future<void> verifier(int solde) async {
    const reglages = DepotReglages();
    final prevenu = await reglages.lire(_dejaPrevenu) != null;
    if (solde < 0 && !prevenu) {
      await _prevenir(solde);
      await reglages.ecrire(_dejaPrevenu, DateTime.now().toIso8601String());
    } else if (solde >= 0 && prevenu) {
      await reglages.ecrire(_dejaPrevenu, null);
    }
  }

  static Future<void> _initialiser() => _notifications.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
      );

  static Future<void> _prevenir(int solde) async {
    await _initialiser();
    await _notifications.show(
      id: 1,
      title: 'Compte courant en négatif',
      body: 'Ton compte courant est à ${euros(solde)}.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _canal,
          'Compte en négatif',
          channelDescription: 'Prévient quand le compte courant passe sous zéro.',
          importance: Importance.high,
          priority: Priority.high,
          // Le montant se lit aussi sur l'écran verrouillé : c'est voulu.
          visibility: NotificationVisibility.public,
          color: Color(0xFFFF6B7A),
        ),
      ),
    );
  }

  /// Le travail d'arrière-plan : ouvrir la base sans rien créer, lire le
  /// solde si la dernière lecture date de plus d'une heure, comparer,
  /// refermer.
  static Future<bool> _lireSolde() async {
    try {
      if (!await KeyVault.instance.unlockExisting()) return true;
      Base.instance.partagee = false;
      await const ConnexionBanque().lireSolde(depuisAuMoins: const Duration(hours: 1));
      return true;
    } catch (_) {
      // Pas de réseau, accès expiré, banque indisponible : Android
      // retentera au prochain passage. Rien à montrer à personne.
      return true;
    } finally {
      await Base.instance.fermer();
      KeyVault.instance.lock();
    }
  }
}

/// Le point d'entrée du moteur d'arrière-plan.
@pragma('vm:entry-point')
void rappelVeille() {
  Workmanager().executeTask((tache, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return Veille._lireSolde();
  });
}

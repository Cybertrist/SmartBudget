import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../providers/donnees.dart';
import '../security/lock_state.dart';
import '../widgets/base.dart';
import 'choix_banque.dart';
import 'connexion.dart';
import 'guide_cle.dart';
import 'enable_banking.dart';

/// L'état de la connexion, relu à chaque écriture.
final etatBanqueProvider = FutureProvider<EtatBanque>((ref) async {
  ref.watch(versionProvider);
  return const ConnexionBanque().etat();
});

/// Vrai pendant un échange avec la banque : l'accueil l'affiche, et une
/// seconde demande ne relance pas un échange déjà parti.
final synchroEnCours = ValueNotifier<bool>(false);

/// Synchronise, en retenant le verrou le temps de l'échange, et le dit.
/// Ce qui sert après l'échange (les données, le messager) est pris avant :
/// l'écran qui l'a lancée peut avoir été quitté entre-temps.
Future<void> synchroniser(BuildContext context, WidgetRef ref, {bool silencieux = false}) async {
  final messager = ScaffoldMessenger.of(context);
  final donnees = ProviderScope.containerOf(context, listen: false);
  if (synchroEnCours.value) {
    if (!silencieux) messager.showSnackBar(const SnackBar(content: Text('Synchronisation déjà en cours…')));
    return;
  }
  synchroEnCours.value = true;
  if (!silencieux) messager.showSnackBar(const SnackBar(content: Text('Synchronisation avec la banque…')));
  try {
    final n = await EtatVerrou.instance.retenir(() => const ConnexionBanque().synchroniser());
    donnees.read(versionProvider.notifier).state++;
    messager.hideCurrentSnackBar();
    if (!silencieux || n > 0) {
      messager.showSnackBar(SnackBar(content: Text(n == 0 ? 'Tout est à jour.' : '${pluriel(n, 'nouvelle opération', 'nouvelles opérations')}.')));
    }
  } on ErreurBanque catch (e) {
    messager.hideCurrentSnackBar();
    // Même lancée seule, une synchronisation qui échoue le dit : sinon
    // rien ne distingue « rien de neuf » de « rien n'est arrivé ».
    messager.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messager.hideCurrentSnackBar();
    messager.showSnackBar(SnackBar(content: Text('Échec de la synchronisation : $e')));
  } finally {
    synchroEnCours.value = false;
  }
}

/// Termine une autorisation dont le retour attend, puis synchronise.
Future<void> terminerSiRetour(BuildContext context, WidgetRef ref) async {
  const connexion = ConnexionBanque();
  final lien = await connexion.lienEnAttente();
  if (lien == null || !context.mounted) return;
  final messager = ScaffoldMessenger.of(context);
  final donnees = ProviderScope.containerOf(context, listen: false);
  try {
    await connexion.terminer(lien);
    donnees.read(versionProvider.notifier).state++;
    if (context.mounted) await synchroniser(context, ref);
  } on ErreurBanque catch (e) {
    messager.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// La carte de la banque dans les réglages : la clé, la connexion, la
/// synchronisation.
class CarteBanque extends ConsumerWidget {
  const CarteBanque({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(etatBanqueProvider).value ?? const EtatBanque();
    final (texte, couleur) = switch (e) {
      EtatBanque(cle: false, banque: null) => ('Choisis ta banque, puis SmartBudget te guide pour la relier.', AppColors.texteSecondaire),
      EtatBanque(cle: false) => ('Il reste à obtenir ta clé d\'Enable Banking : touche Connecter.', AppColors.texteSecondaire),
      EtatBanque(relie: false, jusquau: != null) => ('L\'accès a expiré : reconnecte le compte.', AppColors.attention),
      EtatBanque(banque: null) => ('Clé importée. Choisis ta banque, puis relie le compte.', AppColors.texteSecondaire),
      EtatBanque(relie: false) => ('Clé importée. Il reste à relier le compte.', AppColors.texteSecondaire),
      _ => (
          '${e.derniere == null ? 'Relié' : 'Synchronisé le ${jourCourt(e.derniere!)}'} · accès encore ${pluriel(e.joursRestants ?? 0, 'jour')}',
          (e.joursRestants ?? 99) < 15 ? AppColors.attention : AppColors.vert,
        ),
    };

    Future<void> agir(Future<void> Function() f) async {
      try {
        await EtatVerrou.instance.retenir(f);
        rafraichir(ref);
      } on ErreurBanque catch (x) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x.message)));
      }
    }

    // La clé s'obtient sur le portail d'Enable Banking ; une fois
    // importée, la liaison du compte s'enchaîne.
    Future<void> connecter(Banque b) async {
      if (await obtenirCle(context, b)) await agir(const ConnexionBanque().autoriser);
    }

    Future<void> connecterChoisie() async {
      final pays = await const ConnexionBanque().pays();
      if (context.mounted && e.banque != null) await connecter(Banque(nom: e.banque!, pays: pays));
    }

    Future<void> changerBanque() async {
      final b = await choisirBanque(context, actuelle: e.banque);
      if (b == null) return;
      await agir(() => const ConnexionBanque().choisirBanque(b));
      // Sans clé encore, la connexion commence aussitôt.
      if (!e.cle && context.mounted) await connecter(b);
    }

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Tuile(icone: 'account_balance', couleur: AppColors.vert, taille: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.banque ?? 'Ta banque', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(texte, style: TextStyle(fontSize: 12.5, color: couleur)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (e.banque == null)
                _Bouton(texte: 'Choisir la banque', icone: 'account_balance', onTap: changerBanque)
              else if (!e.cle) ...[
                _Bouton(texte: 'Connecter', icone: 'link', onTap: connecterChoisie),
                _Bouton(texte: 'Changer', icone: 'swap_horiz', discret: true, onTap: changerBanque),
              ] else if (!e.relie) ...[
                _Bouton(texte: 'Relier le compte', icone: 'link', onTap: () => agir(const ConnexionBanque().autoriser)),
                _Bouton(texte: 'Changer', icone: 'swap_horiz', discret: true, onTap: changerBanque),
                _Bouton(texte: 'Nouvelle clé', icone: 'key', discret: true, onTap: connecterChoisie),
              ] else ...[
                _Bouton(texte: 'Synchroniser', icone: 'sync', onTap: () => synchroniser(context, ref)),
                _Bouton(
                  texte: 'Délier',
                  icone: 'close',
                  discret: true,
                  onTap: () => agir(const ConnexionBanque().deconnecter),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Bouton extends StatelessWidget {
  const _Bouton({required this.texte, required this.icone, required this.onTap, this.discret = false});

  final String texte;
  final String icone;
  final VoidCallback onTap;
  final bool discret;

  @override
  Widget build(BuildContext context) {
    final couleur = discret ? AppColors.texteSecondaire : AppColors.vert;
    return Material(
      color: couleur.withValues(alpha: 0.08),
      shape: StadiumBorder(side: BorderSide(color: couleur.withValues(alpha: 0.3))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconeDe(icone), size: 17, color: couleur),
              const SizedBox(width: 7),
              Text(texte, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: couleur)),
            ],
          ),
        ),
      ),
    );
  }
}

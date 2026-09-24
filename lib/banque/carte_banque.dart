import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../providers/donnees.dart';
import '../security/lock_state.dart';
import '../widgets/base.dart';
import 'connexion.dart';
import 'enable_banking.dart';

/// L'état de la connexion, relu à chaque écriture.
final etatBanqueProvider = FutureProvider<EtatBanque>((ref) async {
  ref.watch(versionProvider);
  return const ConnexionBanque().etat();
});

/// Synchronise, en retenant le verrou le temps de l'échange, et le dit.
Future<void> synchroniser(BuildContext context, WidgetRef ref, {bool silencieux = false}) async {
  final messager = ScaffoldMessenger.of(context);
  if (!silencieux) messager.showSnackBar(const SnackBar(content: Text('Synchronisation avec la banque…')));
  try {
    final n = await EtatVerrou.instance.retenir(() => const ConnexionBanque().synchroniser());
    rafraichir(ref);
    messager.hideCurrentSnackBar();
    if (!silencieux || n > 0) {
      messager.showSnackBar(SnackBar(content: Text(n == 0 ? 'Tout est à jour.' : '${pluriel(n, 'nouvelle opération', 'nouvelles opérations')}.')));
    }
  } on ErreurBanque catch (e) {
    messager.hideCurrentSnackBar();
    if (!silencieux) messager.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messager.hideCurrentSnackBar();
    if (!silencieux) messager.showSnackBar(SnackBar(content: Text('Échec de la synchronisation : $e')));
  }
}

/// Termine une autorisation dont le retour attend, puis synchronise.
Future<void> terminerSiRetour(BuildContext context, WidgetRef ref) async {
  const connexion = ConnexionBanque();
  final lien = await connexion.lienEnAttente();
  if (lien == null || !context.mounted) return;
  final messager = ScaffoldMessenger.of(context);
  try {
    await connexion.terminer(lien);
    rafraichir(ref);
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
      EtatBanque(cle: false) => ('Importe la clé d\'Enable Banking pour relier ton compte.', AppColors.texteSecondaire),
      EtatBanque(relie: false, jusquau: != null) => ('L\'accès a expiré : reconnecte le compte.', AppColors.attention),
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
                    const Text('Crédit Mutuel de Bretagne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
              if (!e.cle)
                _Bouton(texte: 'Importer la clé', icone: 'key', onTap: () => agir(const ConnexionBanque().importerCle))
              else if (!e.relie)
                _Bouton(texte: 'Relier le compte', icone: 'link', onTap: () => agir(const ConnexionBanque().autoriser))
              else ...[
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

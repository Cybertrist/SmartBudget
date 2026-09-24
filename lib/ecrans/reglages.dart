import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/essais.dart';
import '../config/format.dart';
import '../config/theme.dart';
import '../banque/carte_banque.dart';
import '../donnees/base.dart';
import '../donnees/demonstration.dart';
import '../donnees/depots.dart';
import '../donnees/sauvegarde.dart';
import '../providers/auth_provider.dart';
import '../providers/donnees.dart';
import '../providers/securite.dart';
import '../main.dart' show generation;
import '../security/key_vault.dart';
import '../utils/fichiers.dart';
import '../widgets/base.dart';
import '../widgets/coque.dart';
import 'dialogues.dart';

final _debutProvider = FutureProvider<int>((ref) async {
  ref.watch(versionProvider);
  return const DepotReglages().debutMois();
});

class EcranReglages extends ConsumerWidget {
  const EcranReglages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider).value ?? 0;
    final objectif = ref.watch(objectifEpargneProvider).value ?? 0;
    final debut = ref.watch(_debutProvider).value ?? 1;
    final securite = ref.watch(securiteProvider);

    Widget ligne(String icone, String libelle, String valeur, VoidCallback onTap, {Color? couleur}) => InkWell(
          onTap: onTap,
          child: Container(
            height: 58,
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12)),
                  child: Icon(iconeDe(icone), size: 18, color: AppColors.texteSecondaire),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(libelle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                Text(valeur, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: couleur ?? AppColors.texteSecondaire, fontFeatures: chiffres)),
                Icon(iconeDe('chevron_right'), size: 18, color: AppColors.texteDiscret),
              ],
            ),
          ),
        );

    Widget bascule(String icone, String libelle, bool valeur, ValueChanged<bool> onChanged) => Container(
          height: 58,
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12)),
                child: Icon(iconeDe(icone), size: 18, color: AppColors.texteSecondaire),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(libelle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Switch(value: valeur, onChanged: onChanged),
            ],
          ),
        );

    Widget bloc(String titre, List<Widget> lignes) => Carte(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Surtitre(titre), const SizedBox(height: 8), ...lignes]),
        );

    return SafeArea(
      bottom: false,
      child: DeuxColonnes(
        titre: 'Réglages',
        surtitre: 'Banque et budget',
        titreDroite: 'Sécurité',
        surtitreDroite: 'Tes données',
        gauche: [
          const CarteBanque(),
          const SizedBox(height: 14),
          bloc('Budget', [
            ligne('target', 'Budget mensuel', budget == 0 ? 'Non fixé' : euros(budget, centimesSiRond: false),
                () => fixerMontant(context, ref, cle: 'budget', titre: 'Budget du mois')),
            ligne('savings', 'Objectif d\'épargne', objectif == 0 ? 'Non fixé' : euros(objectif, centimesSiRond: false),
                () => fixerMontant(context, ref, cle: 'objectif_epargne', titre: 'Objectif d\'épargne')),
            ligne('calendar_month', 'Le mois commence le', debut == 1 ? '1er' : '$debut', () => _choisirDebut(context, ref, debut)),
          ]),
          const SizedBox(height: 14),
          Carte(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tuile(icone: 'verified_user', couleur: AppColors.vert, taille: 40),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tes données restent ici', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text(
                        'Aucun serveur, aucun compte, aucune publicité. Tout est chiffré sur ce téléphone, et seule la banque est interrogée, en lecture.',
                        style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.texteSecondaire),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        droite: [
          bloc('Sécurité', [
            bascule('fingerprint', 'Empreinte à l\'ouverture', securite.verrou, (v) async {
              if (!v) {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Couper l\'empreinte ?'),
                    content: const Text('Les données restent chiffrées, mais l\'application s\'ouvrira sans preuve d\'identité : quiconque tient le téléphone déverrouillé verra tes comptes.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Couper', style: TextStyle(color: AppColors.alerte))),
                    ],
                  ),
                );
                if (ok != true) return;
              }
              await ref.read(securiteProvider.notifier).verrou(v);
            }),
            if (securite.verrou)
              ligne('timer', 'Verrouiller après', _duree(securite.delai), () => _choisirDelai(context, ref, securite.delai)),
            bascule('visibility_off', 'Masquer dans le multitâche', securite.masquer, (v) => ref.read(securiteProvider.notifier).masquer(v)),
          ]),
          const SizedBox(height: 14),
          bloc('Sauvegarde', [
            ligne('upload', 'Exporter, chiffré', '', () => _exporter(context)),
            ligne('download', 'Restaurer une sauvegarde', '', () => _restaurer(context, ref)),
          ]),
          if (avecEssais) ...[
            const SizedBox(height: 14),
            bloc('Essais', [
              ligne('auto_awesome', 'Remplir avec un jeu d\'essai', '4 mois', () async {
                await const Demonstration().remplir();
                rafraichir(ref);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jeu d\'essai ajouté.')));
              }),
            ]),
          ],
          const SizedBox(height: 14),
          Carte(
            child: OutlinedButton.icon(
              onPressed: () => _toutEffacer(context, ref),
              icon: Icon(iconeDe('delete'), color: AppColors.alerte),
              label: const Text('Tout effacer', style: TextStyle(color: AppColors.alerte, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: const StadiumBorder(),
                side: BorderSide(color: AppColors.alerte.withValues(alpha: 0.4)),
                backgroundColor: AppColors.alerte.withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Smart Budget $_version', style: TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
          ),
        ],
      ),
    );
  }

  /// La version affichée, celle du pubspec.
  static const _version = '1.0.2';

  static String _duree(Duration d) => d.inSeconds < 60 ? '${d.inSeconds} secondes' : (d.inMinutes == 1 ? '1 minute' : '${d.inMinutes} minutes');

  Future<void> _choisirDelai(BuildContext context, WidgetRef ref, Duration actuel) async {
    const choix = [Duration(seconds: 30), Duration(minutes: 1), Duration(minutes: 2), Duration(minutes: 5), Duration(minutes: 15)];
    final d = await carteChoix<Duration>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in choix)
              ListTile(
                title: Text(_duree(c)),
                trailing: c == actuel ? Icon(iconeDe('check'), color: AppColors.vert) : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (d != null) await ref.read(securiteProvider.notifier).delai(d);
  }

  Future<void> _choisirDebut(BuildContext context, WidgetRef ref, int actuel) async {
    final choix = await carteChoix<int>(
      context,
      builder: (ctx) => SafeArea(
        child: GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            for (var j = 1; j <= 28; j++)
              InkWell(
                onTap: () => Navigator.pop(ctx, j),
                customBorder: const CircleBorder(),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: j == actuel ? AppColors.vert : null),
                    child: Text('$j', style: TextStyle(fontWeight: FontWeight.w700, color: j == actuel ? Colors.black : AppColors.texte)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (choix == null) return;
    await const DepotReglages().ecrire('debut_mois', '$choix');
    rafraichir(ref);
  }

  /// Demande la phrase d'une sauvegarde : deux fois à l'export, pour ne
  /// pas chiffrer avec une faute de frappe qu'on ne retrouverait jamais.
  static Future<String?> _phrase(BuildContext context, {required bool nouvelle}) {
    final a = TextEditingController();
    final b = TextEditingController();
    String? erreur;
    return carteSaisie<String>(
      context,
      titre: 'Phrase de la sauvegarde',
      aide: nouvelle
          ? 'Elle chiffre le fichier. Sans elle, personne ne peut le relire, toi non plus : note-la bien.'
          : 'Celle choisie au moment de l\'export.',
      resultat: () {
        if (a.text.length < 8) return null;
        if (nouvelle && a.text != b.text) return null;
        return a.text;
      },
      champ: (ctx, valider) => StatefulBuilder(
        builder: (ctx, maj) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: a,
              autofocus: true,
              obscureText: true,
              onChanged: (_) => maj(() => erreur = null),
              decoration: const InputDecoration(hintText: 'Au moins 8 caractères'),
            ),
            if (nouvelle) ...[
              const SizedBox(height: 10),
              TextField(
                controller: b,
                obscureText: true,
                onChanged: (_) => maj(() => erreur = a.text == b.text ? null : 'Les deux phrases diffèrent.'),
                onSubmitted: (_) => valider(),
                decoration: const InputDecoration(hintText: 'La même, une seconde fois'),
              ),
            ],
            if (erreur != null) ...[
              const SizedBox(height: 8),
              Text(erreur!, style: const TextStyle(fontSize: 13, color: AppColors.alerte)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exporter(BuildContext context) async {
    final phrase = await _phrase(context, nouvelle: true);
    if (phrase == null || !context.mounted) return;
    final messager = ScaffoldMessenger.of(context);
    messager.showSnackBar(const SnackBar(content: Text('Chiffrement de la sauvegarde…')));
    try {
      final chemin = await Sauvegarde.exporter(phrase);
      final ok = await Fichiers.enregistrer(chemin, Sauvegarde.nomFichier());
      // La copie temporaire n'a plus de raison de rester.
      await File(chemin).delete().catchError((_) => File(chemin));
      messager.hideCurrentSnackBar();
      messager.showSnackBar(SnackBar(content: Text(ok ? 'Sauvegarde enregistrée.' : 'Sauvegarde annulée.')));
    } catch (e) {
      messager.hideCurrentSnackBar();
      messager.showSnackBar(SnackBar(content: Text('Échec de la sauvegarde : $e')));
    }
  }

  Future<void> _restaurer(BuildContext context, WidgetRef ref) async {
    final chemin = await Fichiers.choisir();
    if (chemin == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer cette sauvegarde ?'),
        content: const Text('Tout ce qui est dans l\'application sera remplacé par le contenu de la sauvegarde.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remplacer', style: TextStyle(color: AppColors.alerte))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final phrase = await _phrase(context, nouvelle: false);
    if (phrase == null || !context.mounted) return;
    final messager = ScaffoldMessenger.of(context);
    messager.showSnackBar(const SnackBar(content: Text('Déchiffrement…')));
    try {
      await Sauvegarde.restaurer(chemin, phrase);
      rafraichir(ref);
      messager.hideCurrentSnackBar();
      messager.showSnackBar(const SnackBar(content: Text('Sauvegarde restaurée.')));
    } on FormatException catch (e) {
      messager.hideCurrentSnackBar();
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toutEffacer(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: const Text('Les opérations, les catégories, les livrets et la clé de chiffrement disparaissent. Rien ne pourra être récupéré.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Effacer', style: TextStyle(color: AppColors.alerte))),
        ],
      ),
    );
    if (ok != true) return;
    // La clé d'abord : sans elle, plus rien ne peut rouvrir la base. Verrouiller
    // d'abord ne suffisait pas quand l'empreinte est coupée : l'écran
    // d'ouverture rouvrait aussitôt l'application avec l'ancienne clé encore
    // en mémoire, au milieu de l'effacement, et les pages restaient grises.
    // Puis la base, le verrou, et enfin l'état en mémoire : repartir de zéro
    // avant le verrou laissait les nouveaux écrans lire sans clé, et garder
    // l'erreur.
    final auth = ref.read(authServiceProvider);
    await KeyVault.instance.destroy();
    await Base.instance.toutDetruire();
    await auth.lock();
    generation.value++;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/essais.dart';
import '../config/format.dart';
import '../config/theme.dart';
import '../donnees/base.dart';
import '../donnees/demonstration.dart';
import '../donnees/depots.dart';
import '../providers/auth_provider.dart';
import '../providers/donnees.dart';
import '../providers/securite.dart';
import '../security/key_vault.dart';
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
          Carte(
            child: Row(
              children: [
                const Tuile(icone: 'account_balance', couleur: AppColors.vert, taille: 48),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crédit Mutuel de Bretagne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('Pas encore relié : c\'est l\'étape suivante.', style: TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          bloc('Budget', [
            ligne('target', 'Budget mensuel', budget == 0 ? 'Non fixé' : euros(budget, centimesSiRond: false),
                () => fixerMontant(context, ref, cle: 'budget', titre: 'Budget du mois')),
            ligne('savings', 'Objectif d\'épargne', objectif == 0 ? 'Non fixé' : euros(objectif, centimesSiRond: false),
                () => fixerMontant(context, ref, cle: 'objectif_epargne', titre: 'Objectif d\'épargne')),
            ligne('calendar_month', 'Le mois commence le', debut == 1 ? '1er' : '$debut', () => _choisirDebut(context, ref, debut)),
          ]),
          const SizedBox(height: 14),
          bloc('À propos', [
            ligne('code', 'Code source', 'GitHub', () => _ouvrirLien('https://github.com/Cybertrist/SmartBudget')),
            ligne('gavel', 'Licence', 'MIT', () => _ouvrirLien('https://github.com/Cybertrist/SmartBudget/blob/main/LICENSE')),
            ligne('description', 'Bibliothèques utilisées', '', () => showLicensePage(
                  context: context,
                  applicationName: 'Smart Budget',
                  applicationVersion: 'Version $_version',
                  applicationLegalese: '© 2026 Tristan Joncour · licence MIT',
                )),
            ligne('person', 'Auteur', 'Tristan Joncour', () => _ouvrirLien('https://github.com/Cybertrist')),
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
  static const _version = '0.1.0';

  /// Ouvre un lien dans le navigateur.
  static Future<void> _ouvrirLien(String adresse) =>
      launchUrl(Uri.parse(adresse), mode: LaunchMode.externalApplication);

  static String _duree(Duration d) => d.inSeconds < 60 ? '${d.inSeconds} secondes' : (d.inMinutes == 1 ? '1 minute' : '${d.inMinutes} minutes');

  Future<void> _choisirDelai(BuildContext context, WidgetRef ref, Duration actuel) async {
    const choix = [Duration(seconds: 30), Duration(minutes: 1), Duration(minutes: 2), Duration(minutes: 5), Duration(minutes: 15)];
    final d = await showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
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
    final choix = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
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
    await Base.instance.effacer();
    await KeyVault.instance.destroy();
    await ref.read(authServiceProvider).lock();
  }
}

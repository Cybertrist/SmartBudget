import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/modeles.dart';
import '../domaine/virements.dart';
import '../donnees/depots.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import 'categorie.dart';
import 'dialogues.dart';

/// Les opérations que rien n'a su reconnaître. Pour chacune, on dit ce
/// qu'elle est : une catégorie, un virement entre ses comptes, ou, pour
/// une entrée, on garde ce qui est proposé.
class EcranAVerifier extends ConsumerWidget {
  const EcranAVerifier({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(aVerifierProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const BarreRetour(titre: 'À vérifier'),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                'Ces opérations n\'ont pas été reconnues. Donne-leur une catégorie : les prochaines du même marchand suivront.',
                style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
              ),
            ),
            if (!liste.hasValue)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (liste.value!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Tuile(icone: 'task_alt', couleur: AppColors.vert, taille: 56),
                    const SizedBox(height: 14),
                    const Text('Tout est vérifié.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => context.pop(), child: const Text('Revenir')),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Carte(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < liste.value!.length; i++) _LigneAVerifier(operation: liste.value![i], separateur: i > 0),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LigneAVerifier extends ConsumerWidget {
  const _LigneAVerifier({required this.operation, required this.separateur});

  final Operation operation;
  final bool separateur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = operation;

    Future<void> classer() async {
      final id = await choisirCategorie(context, ref);
      if (id == null) return;
      await const DepotOperations().reclasser(o.id, id);
      rafraichir(ref);
    }

    Future<void> interne() async {
      final sens = await carteChoix<SensInterne>(
        context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (s, texte) in [
                (SensInterne.versEpargne, "Vers l'épargne"),
                (SensInterne.depuisEpargne, "Depuis l'épargne"),
                (SensInterne.entreComptes, 'Entre mes comptes'),
              ])
                ListTile(
                  leading: Icon(iconeDe(s == SensInterne.entreComptes ? 'sync_alt' : 'savings'), color: AppColors.interne),
                  title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(ctx, s),
                ),
            ],
          ),
        ),
      );
      if (sens == null) return;
      await const DepotOperations().marquerInterne(o.id, sens);
      rafraichir(ref);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: separateur ? const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push('/operation/${o.id}'),
            child: Row(
              children: [
                const Tuile(icone: 'help', couleur: AppColors.attention, taille: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${jour(o.le)}${o.enAttente ? ' · en attente' : ''} · ${o.libelle.toUpperCase()}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Montant(o.montantCentimes, taille: 15.5, signe: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 52),
              Expanded(child: _Action(texte: 'Classer', icone: 'label', couleur: AppColors.vert, onTap: classer)),
              const SizedBox(width: 8),
              Expanded(child: _Action(texte: 'Virement interne', icone: 'sync_alt', couleur: AppColors.interne, onTap: interne)),
              // Une entrée reçue peut garder ce qui est proposé.
              if (o.entree) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _Action(
                    texte: 'Garder',
                    icone: 'check',
                    couleur: AppColors.texteSecondaire,
                    onTap: () async {
                      await const DepotOperations().valider(o.id);
                      rafraichir(ref);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.texte, required this.icone, required this.couleur, required this.onTap});

  final String texte;
  final String icone;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: couleur.withValues(alpha: 0.08),
        shape: StadiumBorder(side: BorderSide(color: couleur.withValues(alpha: 0.3))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconeDe(icone), size: 16, color: couleur),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(texte,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: couleur)),
                ),
              ],
            ),
          ),
        ),
      );
}

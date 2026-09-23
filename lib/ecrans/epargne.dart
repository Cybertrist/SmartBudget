import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/layout.dart';
import '../config/theme.dart';
import '../domaine/libelle.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../domaine/virements.dart';
import '../donnees/depots.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import '../widgets/coque.dart';
import '../widgets/graphiques.dart';
import '../widgets/volets.dart';
import 'categorie.dart';
import 'dialogues.dart';

/// L'épargne : les livrets saisis à la main, et ce que les virements
/// internes disent de ce mois-ci.
class EcranEpargne extends ConsumerWidget {
  const EcranEpargne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // L'épargne, c'est maintenant : ce qu'il y a sur les livrets à cet
    // instant, et les mouvements du mois en cours.
    final mois = Mois.de(DateTime.now());
    final comptes = ref.watch(comptesProvider);
    final bilan = ref.watch(bilanProvider(mois));
    final ops = ref.watch(operationsMoisProvider(mois));
    if (!comptes.hasValue || !bilan.hasValue || !ops.hasValue) return const Center(child: CircularProgressIndicator());
    final livrets = comptes.value!.where((c) => c.nature == NatureCompte.livret).toList();
    final total = livrets.fold<int>(0, (s, c) => s + c.soldeCentimes);
    final b = bilan.value!;
    final mouvements = ops.value!.where((o) => o.interne != null && o.interne != SensInterne.entreComptes).toList();

    return Stack(
      children: [
        if (!AppLayout.usesRail(context))
        IgnorePointer(
          child: Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x8C123038), Color(0x00121212)]),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: DeuxColonnes(
            titre: 'Épargne',
            surtitre: 'Sur tes livrets',
            titreDroite: 'Mouvements',
            surtitreDroite: 'Ce mois-ci',
            gauche: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mis de côté au total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.texteSecondaire)),
                    const SizedBox(height: 6),
                    Montant(total, taille: 46),
                    const SizedBox(height: 10),
                    Text(
                      b.epargneNette == 0 ? 'Rien de déplacé ce mois-ci' : '${euros(b.epargneNette, signe: true)} ce mois-ci',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: b.epargneNette < 0 ? AppColors.alerte : (b.epargneNette > 0 ? AppColors.vert : AppColors.texteSecondaire),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(child: _Chiffre(titre: 'Mis de côté', montant: b.misDeCote, couleur: AppColors.vert)),
                  const SizedBox(width: 14),
                  Expanded(child: _Chiffre(titre: 'Pioché', montant: -b.pioche, couleur: AppColors.alerte, fond: b.pioche > 0 ? const Color(0xFF2B1519) : null)),
                ],
              ),
              const SizedBox(height: 14),
              Carte(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Surtitre('Mes livrets', droite: TextButton.icon(onPressed: () => context.push('/livret/nouveau'), icon: Icon(iconeDe('add'), size: 16), label: const Text('Ajouter'))),
                    if (livrets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'La banque ne partage que le compte courant. Ajoute tes livrets avec leur solde : l\'application le fera vivre au fil des virements.',
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
                        ),
                      ),
                    for (final l in livrets)
                      InkWell(
                        onTap: () => modifierSolde(context, ref, l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Tuile(icone: 'savings', couleur: AppColors.epargne),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                        Text(total == 0 ? '' : '${(l.soldeCentimes * 100 / total).round()} % de l\'épargne',
                                            style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                                      ],
                                    ),
                                  ),
                                  Montant(l.soldeCentimes),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Jauge(part: total == 0 ? 0 : l.soldeCentimes / total, couleur: AppColors.epargne, hauteur: 5),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            droite: [
              Carte(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Surtitre('Mouvements repérés', droite: TextButton(onPressed: () => context.push('/internes'), child: const Text('Tous'))),
                    if (mouvements.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Aucun virement vers ou depuis un livret ce mois-ci.', style: TextStyle(color: AppColors.texteSecondaire)),
                      ),
                    for (final o in mouvements) LigneVirement(operation: o),
                    const SizedBox(height: 6),
                    const Text(
                      'Les livrets sont suivis par les virements qui y entrent et en sortent, repérés sur le compte courant.',
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.texteDiscret),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chiffre extends StatelessWidget {
  const _Chiffre({required this.titre, required this.montant, required this.couleur, this.fond});

  final String titre;
  final int montant;
  final Color couleur;
  final Color? fond;

  @override
  Widget build(BuildContext context) => Carte(
        couleur: fond ?? AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Surtitre(titre),
            const SizedBox(height: 8),
            FittedBox(child: Montant(montant, taille: 24, couleur: couleur, signe: true)),
          ],
        ),
      );
}

/// Un virement interne dans une liste : d'où, vers où, le libellé brut.
class LigneVirement extends StatelessWidget {
  const LigneVirement({super.key, required this.operation});

  final Operation operation;

  @override
  Widget build(BuildContext context) {
    final o = operation;
    final v = reconnaitreInterne(o.libelle);
    final pioche = o.interne == SensInterne.depuisEpargne;
    final couleur = pioche ? AppColors.alerte : (o.interne == SensInterne.versEpargne ? AppColors.vert : AppColors.interne);
    String nom(String compte) => compte == 'CARTE BANCAIRE' ? 'Compte courant' : joli(compte);
    return InkWell(
      onTap: () => ouvrirPage(context, '/operation/${o.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
        child: Row(
          children: [
            AvecCoche(
              pointee: o.pointee,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.interne.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.interne.withValues(alpha: 0.3)),
                ),
                child: Icon(iconeDe('sync_alt'), size: 19, color: AppColors.interne),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v == null || o.nom != null ? o.titre : '${nom(v.source)} → ${nom(v.destination)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${jourCourt(o.le)} · ${pioche ? 'pioché' : (o.interne == SensInterne.versEpargne ? 'mis de côté' : 'entre comptes')}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: couleur)),
                  if (o.note != null && o.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(o.note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
                    ),
                ],
              ),
            ),
            Montant(o.montantCentimes.abs(), taille: 15, couleur: couleur, signe: true),
          ],
        ),
      ),
    );
  }
}

/// Tous les virements internes du mois.
class EcranInternes extends ConsumerWidget {
  const EcranInternes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(operationsPeriodeProvider);
    final bilan = ref.watch(bilanPeriodeProvider);
    final periode = ref.watch(libellePeriodeProvider);
    if (!ops.hasValue || !bilan.hasValue) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final liste = ops.value!.where((o) => o.interne != null).toList();
    final b = bilan.value!;
    return Scaffold(
      body: SafeArea(
        child: Contenu(
          padding: const EdgeInsets.only(bottom: 24),
          tete: const EnTetePage(surtitre: 'Dépenses', titre: 'Virements internes'),
          children: [
            if (!dansUnVolet(context)) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SelecteurMois()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  Montant(b.virementsInternes, taille: 38),
                  const SizedBox(height: 6),
                  Text('déplacés entre tes comptes, ${periode.toLowerCase()}',
                      style: const TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      painter: const Hachures(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.interne.withValues(alpha: 0.22)),
                        ),
                        child: const Text(
                          'Ni dépense ni revenu : l\'argent change seulement de compte. Ces virements sont exclus du budget et de l\'analyse, et ne servent qu\'à suivre l\'épargne.',
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _Chiffre(titre: 'Mis de côté', montant: b.misDeCote, couleur: AppColors.vert)),
                      const SizedBox(width: 10),
                      Expanded(child: _Chiffre(titre: 'Pioché', montant: -b.pioche, couleur: AppColors.alerte)),
                      const SizedBox(width: 10),
                      Expanded(child: _Chiffre(titre: 'Net', montant: b.epargneNette, couleur: b.epargneNette < 0 ? AppColors.alerte : AppColors.vert)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Carte(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: Column(
                      children: [
                        if (liste.isEmpty)
                          const Padding(padding: EdgeInsets.all(16), child: Text('Aucun virement interne ce mois-ci.', style: TextStyle(color: AppColors.texteSecondaire))),
                        for (final o in liste) LigneVirement(operation: o),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ajouter un livret : son nom, son solde, et comment la banque l'appelle.
Future<void> modifierSolde(BuildContext context, WidgetRef ref, Compte livret) async {
  var supprimer = false;
  final v = await demanderMontant(
    context,
    titre: livret.nom,
    aide: 'Le solde actuel, tel que ta banque l\'affiche.',
    initial: livret.soldeCentimes,
    gauche: Builder(
      builder: (ctx) => TextButton(
        onPressed: () {
          supprimer = true;
          Navigator.pop(ctx);
        },
        child: const Text('Supprimer', style: TextStyle(color: AppColors.alerte)),
      ),
    ),
  );
  if (supprimer) {
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${livret.nom} » ?'),
        content: const Text('Le livret et son solde disparaissent de l\'épargne. Les virements passés restent dans tes opérations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: AppColors.alerte))),
        ],
      ),
    );
    if (ok != true) return;
    await const DepotComptes().supprimerLivret(livret.id);
    rafraichir(ref);
    return;
  }
  if (v == null) return;
  await const DepotComptes().definirSolde(livret.id, v);
  rafraichir(ref);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/bilan.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import '../widgets/coque.dart';
import '../widgets/graphiques.dart';
import '../widgets/volets.dart';
import '../config/layout.dart';
import 'lancement.dart';
import 'dialogues.dart';
import 'epargne.dart';

/// Ce que montre une colonne de l'accueil.
enum PartieMois {
  /// Tout, sur une page qui défile : le téléphone.
  tout,

  /// Le solde, les comptes, le budget et l'épargne.
  comptes,

  /// Les dépenses du mois et leur répartition.
  depenses,
}

/// L'accueil : le mois en un coup d'œil.
class EcranMois extends ConsumerWidget {
  const EcranMois({super.key, this.partie = PartieMois.tout});

  final PartieMois partie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // L'accueil, c'est maintenant : toujours le mois en cours. On remonte
    // le temps dans l'analyse.
    final mois = Mois.de(DateTime.now());
    final bilan = ref.watch(bilanProvider(mois));
    final ops = ref.watch(operationsMoisProvider(mois));
    final comptes = ref.watch(comptesProvider);
    final categories = ref.watch(categoriesProvider);

    final pret = bilan.hasValue && ops.hasValue && comptes.hasValue && categories.hasValue;
    return Stack(
      children: [
        if (partie == PartieMois.tout) const _Lueur(couleur: Color(0xFF1E3A2A)),
        SafeArea(
          bottom: partie != PartieMois.tout,
          child: !pret
              ? const Center(child: CircularProgressIndicator())
              : _Contenu(
                  mois: mois,
                  bilan: bilan.value!,
                  ops: ops.value!,
                  comptes: comptes.value!,
                  categories: categories.value!,
                  partie: partie,
                ),
        ),
      ],
    );
  }
}

/// Le dégradé de couleur en haut de page, qui s'éteint vite.
class _Lueur extends StatelessWidget {
  const _Lueur({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [couleur.withValues(alpha: 0.55), couleur.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.mois,
    required this.bilan,
    required this.ops,
    required this.comptes,
    required this.categories,
    required this.partie,
  });

  final Mois mois;
  final Bilan bilan;
  final List<Operation> ops;
  final List<Compte> comptes;
  final Map<int, Categorie> categories;
  final PartieMois partie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courant = comptes.firstWhere((c) => c.nature == NatureCompte.courant);
    final livrets = comptes.where((c) => c.nature == NatureCompte.livret).toList();
    final portefeuille = comptes.where((c) => c.nature == NatureCompte.portefeuille).firstOrNull;
    final budget = ref.watch(budgetProvider).value ?? 0;
    final objectif = ref.watch(objectifEpargneProvider).value ?? 0;
    final epargne = livrets.fold<int>(0, (s, c) => s + c.soldeCentimes);
    final aVerifier = ref.watch(aVerifierProvider).value?.length ?? 0;


    final top = bilan.parCategorie.entries
        .where((e) => categories[e.key]?.genre == Genre.depense && e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final entete = Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              // Le nom de l'application, comme sur la bannière du dépôt. Sur
              // l'écran déplié, le rail porte déjà le logo et l'en-tête
              // donne le mois.
              if (partie == PartieMois.depenses)
                const Expanded(child: Text('Dépenses du mois', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))
              else if (AppLayout.usesRail(context))
                Expanded(child: Text(nomMois(mois), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))
              else ...[
                const Expanded(child: NomApp(taille: 26)),
                Text(nomMois(mois), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire)),
              ],
            ],
          ),
        );
    final solde = Padding(
          padding: EdgeInsets.fromLTRB(24, partie == PartieMois.tout ? 22 : 0, 24, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sur tes comptes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.texteSecondaire)),
              const SizedBox(height: 6),
              Montant(courant.soldeCentimes + epargne + (portefeuille?.soldeCentimes ?? 0), taille: 46),
              // La date de mise à jour et, à côté, ce qui reste à vérifier :
              // une seule ligne, pour que l'accueil déplié tienne.
              if (courant.soldeLe != null || aVerifier > 0) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (courant.soldeLe != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconeDe('sync'), size: 14, color: AppColors.texteDiscret),
                          const SizedBox(width: 5),
                          Text('Mis à jour le ${jourCourt(courant.soldeLe!)}', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                        ],
                      ),
                    if (aVerifier > 0)
                    Material(
                      color: AppColors.attention.withValues(alpha: 0.1),
                      shape: StadiumBorder(side: BorderSide(color: AppColors.attention.withValues(alpha: 0.35))),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => context.push('/verifier'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(iconeDe('fact_check'), size: 16, color: AppColors.attention),
                              const SizedBox(width: 7),
                              Text('${pluriel(aVerifier, 'opération')} à vérifier',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.attention)),
                              const SizedBox(width: 2),
                              Icon(iconeDe('chevron_right'), size: 16, color: AppColors.attention),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
    final mesComptes = Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Carte(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Surtitre('Mes comptes', droite: Text(pluriel(comptes.length, 'compte'), style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret))),
                const SizedBox(height: 6),
                for (final c in comptes)
                  _LigneCompte(
                    icone: switch (c.nature) {
                      NatureCompte.courant => 'credit_card',
                      NatureCompte.livret => 'savings',
                      NatureCompte.portefeuille => 'account_balance_wallet',
                    },
                    nom: c.nom,
                    detail: switch (c.nature) {
                      NatureCompte.courant => 'Crédit Mutuel de Bretagne',
                      NatureCompte.livret => 'Livret d\'épargne',
                      NatureCompte.portefeuille => 'Espèces',
                    },
                    solde: c.soldeCentimes,
                    couleur: switch (c.nature) {
                      NatureCompte.courant => AppColors.vert,
                      NatureCompte.livret => AppColors.epargne,
                      NatureCompte.portefeuille => AppColors.attention,
                    },
                    onTap: () => switch (c.nature) {
                      NatureCompte.courant => context.go('/analyse'),
                      NatureCompte.livret => context.go('/epargne'),
                      NatureCompte.portefeuille => modifierPortefeuille(context, ref, c),
                    },
                  ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.push('/livret/nouveau'),
                      icon: Icon(iconeDe('add'), size: 18),
                      label: const Text('Ajouter un livret'),
                    ),
                    if (portefeuille == null)
                      TextButton.icon(
                        onPressed: () => modifierPortefeuille(context, ref, null),
                        icon: Icon(iconeDe('add'), size: 18),
                        label: const Text('Portefeuille'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
    final cartes = IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _CarteBudget(depense: bilan.sorties, budget: budget)),
                    const SizedBox(width: 14),
                    Expanded(child: _CarteEpargne(epargne: epargne, objectif: objectif, aDesLivrets: livrets.isNotEmpty)),
                  ],
                ),
              );
    final depenses = Carte(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Surtitre('Dépenses par catégorie', droite: Montant(bilan.sorties)),
                    const SizedBox(height: 16),
                    BarreSegmentee(parts: [for (final e in top) (e.value, Color(categories[e.key]!.couleur))]),
                    const SizedBox(height: 10),
                    if (top.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Aucune dépense ce mois-ci.', style: TextStyle(color: AppColors.texteSecondaire)),
                      ),
                    for (final e in top.take(5))
                      _LigneCategorie(categorie: categories[e.key]!, montant: e.value),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _BoutonTexte(texte: 'Analyser', onTap: () => context.go('/analyse'))),
                        const SizedBox(width: 10),
                        Expanded(child: _BoutonTexte(texte: 'Opérations', onTap: () => context.push('/operations'))),
                      ],
                    ),
                  ],
                ),
              );
    final repartition = _CarteRepartition(bilan: bilan, serre: partie != PartieMois.tout);

    const bord = EdgeInsets.symmetric(horizontal: 16);
    switch (partie) {
      case PartieMois.tout:
        return ListView(
          padding: EdgeInsets.only(bottom: margeCapsule(context)),
          children: [
            entete,
            solde,
            mesComptes,
            const SizedBox(height: 12),
            Padding(padding: bord, child: cartes),
            const SizedBox(height: 14),
            Padding(padding: bord, child: depenses),
            const SizedBox(height: 14),
            Padding(padding: bord, child: repartition),
          ],
        );
      case PartieMois.comptes:
        return Contenu(ajuster: true, padding: const EdgeInsets.only(bottom: 16), tete: TitreVolet(surtitre: 'Ce mois-ci', titre: nomMois(mois)), children: [
          solde,
          mesComptes,
          const SizedBox(height: 12),
          Padding(padding: bord, child: cartes),
        ]);
      case PartieMois.depenses:
        return Contenu(ajuster: true, padding: const EdgeInsets.only(bottom: 16), tete: const TitreVolet(surtitre: "Où part l'argent", titre: 'Dépenses'), children: [
          Padding(padding: bord, child: depenses),
          const SizedBox(height: 14),
          Padding(padding: bord, child: repartition),
        ]);
    }
  }
}

class _CarteBudget extends ConsumerWidget {
  const _CarteBudget({required this.depense, required this.budget});

  final int depense;
  final int budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (budget <= 0) {
      return Carte(
        onTap: () => fixerMontant(context, ref, cle: 'budget', titre: 'Budget du mois'),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Surtitre('Budget'),
            SizedBox(height: 12),
            Text('Fixer un budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.vert)),
            SizedBox(height: 4),
            Text('pour voir ce qu\'il reste', style: TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
          ],
        ),
      );
    }
    final reste = budget - depense;
    final part = depense / budget;
    final couleur = part >= 1 ? AppColors.alerte : (part >= 0.9 ? AppColors.attention : AppColors.vert);
    return Carte(
      onTap: () => fixerMontant(context, ref, cle: 'budget', titre: 'Budget du mois'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Surtitre('Budget'),
          const SizedBox(height: 12),
          FittedBox(child: Montant(reste.abs(), taille: 26, couleur: couleur)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(reste >= 0 ? 'restants sur ${euros(budget, centimesSiRond: false)}' : 'de dépassement',
                maxLines: 1, style: const TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Jauge(part: part, couleur: couleur),
        ],
      ),
    );
  }
}

class _CarteEpargne extends ConsumerWidget {
  const _CarteEpargne({required this.epargne, required this.objectif, required this.aDesLivrets});

  final int epargne;
  final int objectif;
  final bool aDesLivrets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!aDesLivrets) {
      return Carte(
        onTap: () => context.push('/livret/nouveau'),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Surtitre('Épargne'),
            SizedBox(height: 12),
            Text('Ajouter un livret', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.epargne)),
            SizedBox(height: 4),
            Text('la banque ne les partage pas', style: TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
          ],
        ),
      );
    }
    return Carte(
      onTap: () => context.go('/epargne'),
      child: Column(
        children: [
          const Surtitre('Épargne'),
          const SizedBox(height: 10),
          Cadran(part: objectif > 0 ? epargne / objectif : 0),
          FittedBox(child: Montant(epargne, taille: 20)),
          const SizedBox(height: 2),
          Text(
            objectif > 0 ? '${(epargne * 100 / objectif).round()} % de ${euros(objectif, centimesSiRond: false)}' : 'sur tes livrets',
            style: const TextStyle(fontSize: 12, color: AppColors.texteSecondaire),
          ),
        ],
      ),
    );
  }
}

class _CarteRepartition extends StatelessWidget {
  const _CarteRepartition({required this.bilan, this.serre = false});

  final Bilan bilan;

  /// Des lignes plus basses, pour tenir dans une colonne de l'écran déplié.
  final bool serre;

  @override
  Widget build(BuildContext context) {
    final lignes = [
      ('Essentiel', 'essentiel', bilan.essentiel),
      ('Plaisir', 'plaisir', bilan.plaisir),
      ('Épargne', 'epargne', bilan.misDeCote),
      ('Imprévu', 'imprevu', bilan.imprevu),
    ];
    final total = lignes.fold<int>(0, (s, l) => s + (l.$3 > 0 ? l.$3 : 0));
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Surtitre('Répartition des dépenses'),
          const SizedBox(height: 16),
          BarreSegmentee(parts: [for (final l in lignes) (l.$3, couleurNature(l.$2))]),
          const SizedBox(height: 8),
          for (final l in lignes)
            Padding(
              padding: EdgeInsets.symmetric(vertical: serre ? 3 : 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: couleurNature(l.$2).withValues(alpha: l.$3 > 0 ? 1 : 0.18),
                    ),
                    child: Icon(iconeDe(iconeNature(l.$2)), size: 19, color: l.$3 > 0 ? Colors.black : couleurNature(l.$2), fill: 1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.$1, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                        if (total > 0)
                          Text('${(l.$3.clamp(0, total) * 100 / total).round()} %', style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                      ],
                    ),
                  ),
                  Montant(l.$3, couleur: l.$3 > 0 ? AppColors.texte : AppColors.texteDiscret),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LigneCompte extends StatelessWidget {
  const _LigneCompte({required this.icone, required this.nom, required this.detail, required this.solde, required this.couleur, required this.onTap});

  final String icone;
  final String nom;
  final String detail;
  final int solde;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.trait))),
          child: Row(
            children: [
              Tuile(icone: icone, couleur: couleur, taille: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                  ],
                ),
              ),
              Montant(solde, couleur: solde < 0 ? AppColors.alerte : null),
            ],
          ),
        ),
      );
}

class _LigneCategorie extends StatelessWidget {
  const _LigneCategorie({required this.categorie, required this.montant});

  final Categorie categorie;
  final int montant;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Sur l'écran déplié, la catégorie s'ouvre dans l'analyse, en volet.
      onTap: () => AppLayout.usesRail(context)
          ? context.go('/analyse?ouvrir=${Uri.encodeQueryComponent('/categorie/${categorie.id}')}')
          : context.push('/categorie/${categorie.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Tuile(icone: categorie.icone, couleur: Color(categorie.couleur), taille: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categorie.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Montant(montant),
          ],
        ),
      ),
    );
  }
}

class _BoutonTexte extends StatelessWidget {
  const _BoutonTexte({required this.texte, required this.onTap});

  final String texte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.vert.withValues(alpha: 0.06),
        shape: StadiumBorder(side: BorderSide(color: AppColors.vert.withValues(alpha: 0.18))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(texte, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.vert)),
                const SizedBox(width: 4),
                Icon(iconeDe('chevron_right'), size: 18, color: AppColors.vert),
              ],
            ),
          ),
        ),
      );
}

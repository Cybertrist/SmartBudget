import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/bilan.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../domaine/virements.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import '../widgets/coque.dart';
import '../widgets/graphiques.dart';
import '../config/layout.dart';
import '../widgets/logo_neon.dart';
import 'dialogues.dart';

/// L'accueil : le mois en un coup d'œil.
class EcranMois extends ConsumerWidget {
  const EcranMois({super.key, this.avecSelecteur = true});

  /// Sur l'écran déplié, le sélecteur de mois de l'analyse voisine suffit.
  final bool avecSelecteur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mois = ref.watch(moisProvider);
    final bilan = ref.watch(bilanProvider(mois));
    final ops = ref.watch(operationsMoisProvider(mois));
    final comptes = ref.watch(comptesProvider);
    final categories = ref.watch(categoriesProvider);

    final pret = bilan.hasValue && ops.hasValue && comptes.hasValue && categories.hasValue;
    return Stack(
      children: [
        const _Lueur(couleur: Color(0xFF1E3A2A)),
        SafeArea(
          bottom: false,
          child: !pret
              ? const Center(child: CircularProgressIndicator())
              : _Contenu(
                  mois: mois,
                  bilan: bilan.value!,
                  ops: ops.value!,
                  comptes: comptes.value!,
                  categories: categories.value!,
                  avecSelecteur: avecSelecteur,
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
    required this.avecSelecteur,
  });

  final Mois mois;
  final Bilan bilan;
  final List<Operation> ops;
  final List<Compte> comptes;
  final Map<int, Categorie> categories;
  final bool avecSelecteur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courant = comptes.firstWhere((c) => c.nature == NatureCompte.courant);
    final livrets = comptes.where((c) => c.nature == NatureCompte.livret).toList();
    final estCourant = mois == Mois.de(DateTime.now());
    final budget = ref.watch(budgetProvider).value ?? 0;
    final objectif = ref.watch(objectifEpargneProvider).value ?? 0;
    final epargne = livrets.fold<int>(0, (s, c) => s + c.soldeCentimes);

    final pioches = ops.where((o) => o.interne == SensInterne.depuisEpargne && !o.masquee).toList();

    final top = bilan.parCategorie.entries
        .where((e) => categories[e.key]?.genre == Genre.depense && e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: EdgeInsets.only(bottom: margeCapsule(context)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              // Sur l'écran déplié, le rail porte déjà le logo.
              if (!AppLayout.usesRail(context)) ...[
                const LogoNeon(taille: 44),
                const SizedBox(width: 12),
              ],
              if (avecSelecteur) const Expanded(child: SelecteurMois()) else Expanded(child: Text(nomMois(mois), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(estCourant ? 'Compte courant' : 'Solde du mois',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.texteSecondaire)),
              const SizedBox(height: 6),
              Montant(estCourant ? courant.soldeCentimes : bilan.solde, taille: 46),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Pastille(
                    icone: 'call_made',
                    texte: '${euros(bilan.sorties)} ${estCourant ? 'depuis le 1er' : 'dépensés'}',
                    couleur: AppColors.alerte,
                  ),
                  if (courant.soldeLe != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconeDe('sync'), size: 14, color: AppColors.texteDiscret),
                        const SizedBox(width: 5),
                        Text('Mis à jour le ${jourCourt(courant.soldeLe!)}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
          child: _Courbe(mois: mois, ops: ops, soldeFinal: estCourant ? courant.soldeCentimes : null),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pioches.isNotEmpty) ...[
                _AlertePioche(total: bilan.pioche, nombre: pioches.length, derniere: pioches.first.le),
                const SizedBox(height: 14),
              ],
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _CarteBudget(depense: bilan.sorties, budget: budget)),
                    const SizedBox(width: 14),
                    Expanded(child: _CarteEpargne(epargne: epargne, objectif: objectif, aDesLivrets: livrets.isNotEmpty)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Carte(
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
                      _LigneCategorie(categorie: categories[e.key]!, montant: e.value, part: bilan.sorties == 0 ? 0 : e.value / bilan.sorties),
                    const SizedBox(height: 8),
                    _BoutonTexte(texte: 'Analyser le mois', onTap: () => context.go('/analyse')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _CarteNature(bilan: bilan),
              const SizedBox(height: 14),
              Carte(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Surtitre('Par semaine'),
                    const SizedBox(height: 16),
                    BarresSemaines(semaines: _semaines(mois, ops, categories)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Les dépenses par tranche de sept jours, jusqu'à aujourd'hui pour le
  /// mois en cours.
  static List<(String, int)> _semaines(Mois mois, List<Operation> ops, Map<int, Categorie> categories) {
    final fin = DateTime(mois.annee, mois.mois + 1, 0).day;
    final aujourdhui = DateTime.now();
    final estCourant = mois == Mois.de(aujourdhui);
    final tranches = <(int, int)>[(1, 7), (8, 14), (15, 21), (22, fin)];
    final sortie = <(String, int)>[];
    for (final (a, b) in tranches) {
      if (estCourant && a > aujourdhui.day) break;
      var somme = 0;
      for (final o in ops) {
        final top = _racine(categories, o.categorieId);
        if (o.masquee || top == null || top.genre != Genre.depense) continue;
        if (o.le.month == mois.mois && o.le.day >= a && o.le.day <= b) somme -= o.montantCentimes;
      }
      sortie.add(('$a-$b', max(somme, 0)));
    }
    return sortie;
  }
}

Categorie? _racine(Map<int, Categorie> c, int id) {
  final x = c[id];
  if (x == null) return null;
  return x.parentId == null ? x : c[x.parentId];
}

class _Courbe extends StatelessWidget {
  const _Courbe({required this.mois, required this.ops, this.soldeFinal});

  final Mois mois;
  final List<Operation> ops;
  final int? soldeFinal;

  @override
  Widget build(BuildContext context) {
    final jours = DateTime(mois.annee, mois.mois + 1, 0).day;
    final aujourdhui = DateTime.now();
    final dernier = mois == Mois.de(aujourdhui) ? aujourdhui.day : jours;
    final parJour = List<int>.filled(jours + 1, 0);
    for (final o in ops) {
      if (o.le.month == mois.mois && o.le.year == mois.annee) parJour[o.le.day] += o.montantCentimes;
    }
    final points = <int>[];
    var cumul = 0;
    for (var j = 1; j <= dernier; j++) {
      cumul += parJour[j];
      points.add(cumul);
    }
    if (soldeFinal != null && points.isNotEmpty) {
      final decalage = soldeFinal! - points.last;
      for (var i = 0; i < points.length; i++) {
        points[i] += decalage;
      }
    }
    return Column(
      children: [
        CourbeSolde(points: points, jours: jours),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 ${nomMoisSeul(mois).toLowerCase().substring(0, 4)}.', style: _petit),
            if (dernier < jours) const Text("aujourd'hui", style: _petit),
            Text('$jours ${nomMoisSeul(mois).toLowerCase().substring(0, 4)}.', style: _petit),
          ],
        ),
      ],
    );
  }
}

const _petit = TextStyle(fontSize: 11.5, color: AppColors.texteDiscret, fontFeatures: chiffres);

class _Pastille extends StatelessWidget {
  const _Pastille({required this.icone, required this.texte, required this.couleur});

  final String icone;
  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: couleur.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconeDe(icone), size: 13, color: couleur),
            const SizedBox(width: 6),
            Text(texte, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: couleur, fontFeatures: chiffres)),
          ],
        ),
      );
}

class _AlertePioche extends StatelessWidget {
  const _AlertePioche({required this.total, required this.nombre, required this.derniere});

  final int total;
  final int nombre;
  final DateTime derniere;

  @override
  Widget build(BuildContext context) {
    return Carte(
      couleur: const Color(0xFF2B1519),
      onTap: () => context.go('/epargne'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const Tuile(icone: 'warning', couleur: AppColors.alerte),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${euros(total)} piochés dans l\'épargne',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFeatures: chiffres)),
                const SizedBox(height: 3),
                Text(
                  nombre > 1 ? '$nombre retraits ce mois-ci, le dernier le ${jourCourt(derniere)}' : 'Le ${jourCourt(derniere)}',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFE9AEB6)),
                ),
              ],
            ),
          ),
          Icon(iconeDe('chevron_right'), color: const Color(0xFFE9AEB6)),
        ],
      ),
    );
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
          Text(reste >= 0 ? 'restants sur ${euros(budget, centimesSiRond: false)}' : 'de dépassement',
              style: const TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
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
        onTap: () => context.go('/epargne'),
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

class _CarteNature extends StatelessWidget {
  const _CarteNature({required this.bilan});

  final Bilan bilan;

  @override
  Widget build(BuildContext context) {
    final total = bilan.essentiel + bilan.plaisir;
    int pc(int v) => total == 0 ? 0 : (v * 100 / total).round();
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Surtitre('Essentiel et plaisir'),
          const SizedBox(height: 16),
          BarreSegmentee(parts: [(bilan.essentiel, const Color(0xFF5AB2FF)), (bilan.plaisir, const Color(0xFFFF8FD1))]),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Legende(couleur: const Color(0xFF5AB2FF), texte: 'Essentiel · ${pc(bilan.essentiel)} %', montant: bilan.essentiel)),
              Expanded(child: _Legende(couleur: const Color(0xFFFF8FD1), texte: 'Plaisir · ${pc(bilan.plaisir)} %', montant: bilan.plaisir)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legende extends StatelessWidget {
  const _Legende({required this.couleur, required this.texte, required this.montant});

  final Color couleur;
  final String texte;
  final int montant;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text(texte, style: const TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
            ],
          ),
          const SizedBox(height: 4),
          Montant(montant, taille: 20),
        ],
      );
}

class _LigneCategorie extends StatelessWidget {
  const _LigneCategorie({required this.categorie, required this.montant, required this.part});

  final Categorie categorie;
  final int montant;
  final double part;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/categorie/${categorie.id}'),
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
                  Text('${(part * 100).round()} %', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
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

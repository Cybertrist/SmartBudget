import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/bilan.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../domaine/recurrences.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import '../widgets/coque.dart';
import '../widgets/graphiques.dart';
import '../widgets/volets.dart';

enum Vue { sorties, entrees, recurrences }

final vueProvider = StateProvider<Vue>((ref) => Vue.sorties);

/// L'analyse : où part l'argent, d'où il vient, et ce qui revient.
enum ModeAnalyse {
  /// Tout sur un seul écran, sur téléphone.
  complet,

  /// L'en-tête, l'anneau et le budget : le volet de gauche du déplié.
  resume,

  /// La liste des catégories seule : le volet de droite du déplié.
  liste,
}

class EcranAnalyse extends ConsumerWidget {
  const EcranAnalyse({super.key, this.mode = ModeAnalyse.complet});

  final ModeAnalyse mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vue = ref.watch(vueProvider);
    final periode = ref.watch(periodeProvider);
    final bilan = ref.watch(bilanPeriodeProvider);
    final categories = ref.watch(categoriesProvider);
    final mois = ref.watch(moisProvider);
    final enVolets = mode != ModeAnalyse.complet;
    final laPeriode = switch (periode) {
      Periode.mois => nomMois(mois),
      Periode.trimestre => "3 mois jusqu'à ${nomMoisSeul(mois).toLowerCase()}",
      Periode.annee => "12 mois jusqu'à ${nomMoisSeul(mois).toLowerCase()}",
    };

    return SafeArea(
      bottom: enVolets,
      child: Contenu(
        ajuster: enVolets,
        padding: EdgeInsets.only(bottom: enVolets ? 16 : margeCapsule(context)),
        tete: switch (mode) {
          ModeAnalyse.complet => null,
          ModeAnalyse.resume => const TitreVolet(surtitre: "Vue d'ensemble", titre: 'Analyse'),
          ModeAnalyse.liste => TitreVolet(
              surtitre: laPeriode,
              titre: switch (vue) {
                Vue.sorties => 'Dépenses',
                Vue.entrees => 'Entrées',
                Vue.recurrences => 'Récurrences',
              },
            ),
        },
        children: [
          if (mode != ModeAnalyse.liste)
          Padding(
            padding: EdgeInsets.fromLTRB(16, enVolets ? 0 : 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!enVolets)
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text('Analyse', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                  ),
                const SelecteurMois(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (p, t) in [(Periode.mois, '1 mois'), (Periode.trimestre, '3 mois'), (Periode.annee, '1 an')]) ...[
                      Expanded(child: _Puce(texte: t, actif: p == periode, onTap: () => ref.read(periodeProvider.notifier).state = p)),
                      if (p != Periode.annee) const SizedBox(width: 6),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _Onglets(vue: vue, onVue: (v) => ref.read(vueProvider.notifier).state = v),
              ],
            ),
          ),
          if (!bilan.hasValue || !categories.hasValue)
            const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
          else if (vue == Vue.recurrences)
            _Recurrences(resume: mode != ModeAnalyse.liste, blocs: mode != ModeAnalyse.resume)
          else ...[
            _Repartition(
              bilan: bilan.value!,
              categories: categories.value!,
              entrees: vue == Vue.entrees,
              anneau: mode != ModeAnalyse.liste,
              liste: mode != ModeAnalyse.resume,
            ),
          ],
        ],
      ),
    );
  }
}

class _Puce extends StatelessWidget {
  const _Puce({required this.texte, required this.actif, required this.onTap});

  final String texte;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: actif ? AppColors.vert.withValues(alpha: 0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: actif ? AppColors.vert.withValues(alpha: 0.33) : const Color(0x12FFFFFF)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Center(
              child: Text(texte,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: actif ? AppColors.vert : AppColors.texteSecondaire)),
            ),
          ),
        ),
      );
}

class _Onglets extends StatelessWidget {
  const _Onglets({required this.vue, required this.onVue});

  final Vue vue;
  final ValueChanged<Vue> onVue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: Row(
        children: [
          for (final (v, t) in [(Vue.sorties, 'Sorties'), (Vue.entrees, 'Entrées'), (Vue.recurrences, 'Récurrences')])
            Expanded(
              child: GestureDetector(
                onTap: () => onVue(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 42,
                  decoration: BoxDecoration(
                    color: v == vue ? AppColors.vert : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(t,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: v == vue ? Colors.black : AppColors.texteSecondaire)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Repartition extends ConsumerWidget {
  const _Repartition({required this.bilan, required this.categories, required this.entrees, this.anneau = true, this.liste = true});

  final Bilan bilan;
  final Map<int, Categorie> categories;
  final bool entrees;
  final bool anneau;
  final bool liste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genre = entrees ? Genre.revenu : Genre.depense;
    final total = entrees ? bilan.entrees : bilan.sorties;
    final lignes = bilan.parCategorie.entries
        .where((e) => categories[e.key]?.genre == genre && e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final budget = ref.watch(budgetProvider).value ?? 0;
    final periode = ref.watch(periodeProvider);
    final plusGrand = lignes.isEmpty ? 1 : lignes.first.value;
    final nbOps = lignes.fold<int>(0, (s, e) => s + (bilan.operationsParCategorie[e.key] ?? 0));

    void ouvrir(int id) => ouvrirPage(context, '/categorie/$id');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (anneau) ...[
        const SizedBox(height: 10),
        Center(
          child: Anneau(
            parts: [for (final e in lignes) PartAnneau(e.value, Color(categories[e.key]!.couleur), categories[e.key]!.icone)],
            centre: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entrees ? 'ENTRÉES' : 'SORTIES',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: AppColors.texteSecondaire)),
                const SizedBox(height: 6),
                Montant(total, taille: 30),
                const SizedBox(height: 4),
                Text(pluriel(nbOps, 'opération'), style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
              ],
            ),
          ),
        ),
        // Dans les volets, la liste voisine a déjà sa ligne de virements.
        if (liste && bilan.virementsInternes > 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: _PiluleInterne(montant: bilan.virementsInternes),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (anneau && !entrees && budget > 0 && periode == Periode.mois) ...[
                Carte(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Budget du mois', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                          Text('${(bilan.sorties * 100 / budget).round()} %',
                              style: const TextStyle(fontSize: 13, color: AppColors.texteSecondaire, fontFeatures: chiffres)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Jauge(part: bilan.sorties / budget, couleur: bilan.sorties > budget ? AppColors.alerte : AppColors.attention),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: Text('${euros(bilan.sorties)} dépensés', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret))),
                          Text(euros(budget, centimesSiRond: false), style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (liste) Carte(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Surtitre('Catégories', droite: TextButton(onPressed: () => context.push('/categories'), child: const Text('Toutes'))),
                    if (lignes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(entrees ? 'Aucune entrée sur la période.' : 'Aucune dépense sur la période.',
                            style: const TextStyle(color: AppColors.texteSecondaire)),
                      ),
                    for (var i = 0; i < lignes.length; i++)
                      _LigneAnalyse(
                        categorie: categories[lignes[i].key]!,
                        montant: lignes[i].value,
                        relatif: lignes[i].value / plusGrand,
                        separateur: i > 0,
                        onTap: () => ouvrir(lignes[i].key),
                      ),
                    if (!entrees && bilan.virementsInternes > 0)
                      _LigneInterne(montant: bilan.virementsInternes, onTap: () => ouvrirPage(context, '/internes')),
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

class _LigneAnalyse extends StatelessWidget {
  const _LigneAnalyse({
    required this.categorie,
    required this.montant,
    required this.relatif,
    required this.separateur,
    required this.onTap,
  });

  final Categorie categorie;
  final int montant;
  final double relatif;
  final bool separateur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleur = Color(categorie.couleur);
    return Surligne(
      actif: estOuvert(context, '/categorie/${categorie.id}'),
      couleur: couleur,
      child: InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: dansUnVolet(context) ? 9 : 12),
        decoration: separateur ? const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))) : null,
        child: Row(
          children: [
            Tuile(icone: categorie.icone, couleur: couleur, taille: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(categorie.nom, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
                      Montant(montant),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Jauge(part: relatif, couleur: couleur, hauteur: 4),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PiluleInterne extends StatelessWidget {
  const _PiluleInterne({required this.montant});

  final int montant;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF1A1A1A),
        shape: StadiumBorder(side: BorderSide(color: AppColors.interne.withValues(alpha: 0.25))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/internes'),
          child: CustomPaint(
            painter: const Hachures(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconeDe('sync_alt'), size: 14, color: AppColors.interne),
                  const SizedBox(width: 7),
                  Text('Hors virements internes · ${euros(montant)} déplacés',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire, fontFeatures: chiffres)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _LigneInterne extends StatelessWidget {
  const _LigneInterne({required this.montant, required this.onTap});

  final int montant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Surligne(
          actif: estOuvert(context, '/internes'),
          couleur: AppColors.interne,
          child: Material(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: CustomPaint(
              painter: const Hachures(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.interne.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.interne.withValues(alpha: 0.3)),
                      ),
                      child: Icon(iconeDe('sync_alt'), size: 21, color: AppColors.interne),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Virements internes', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                          SizedBox(height: 3),
                          Text('exclus du budget', style: TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                        ],
                      ),
                    ),
                    Montant(montant, taille: 15, couleur: AppColors.texteSecondaire),
                    Icon(iconeDe('chevron_right'), color: AppColors.texteDiscret),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      );
}

class _Recurrences extends ConsumerWidget {
  const _Recurrences({this.resume = true, this.blocs = true});

  /// La carte « payés sur … attendus ».
  final bool resume;

  /// Les listes en retard, à venir, payées.
  final bool blocs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(recurrencesProvider);
    final mois = ref.watch(moisProvider);
    if (!r.hasValue) return const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()));
    final maintenant = DateTime.now();
    final liste = r.value!;
    bool dansMois(DateTime d) => Mois.de(d) == mois;
    final payees = liste.where((x) => dansMois(x.derniere)).toList();
    final retard = liste.where((x) => x.enRetard(maintenant) && !dansMois(x.derniere)).toList();
    final aVenir = liste.where((x) => !x.enRetard(maintenant) && !dansMois(x.derniere) && dansMois(x.prochaine)).toList();
    final paye = payees.fold<int>(0, (s, x) => s - x.montantCentimes);
    final attendu = paye - [...retard, ...aVenir].fold<int>(0, (s, x) => s + x.montantCentimes);

    Widget bloc(String titre, List<Recurrence> l, Color couleur, String Function(Recurrence) etat, String icone) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Carte(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Surtitre(titre),
                for (var i = 0; i < l.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: i > 0 ? const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))) : null,
                    child: Row(
                      children: [
                        const Tuile(icone: 'autorenew', couleur: Color(0xFFFF8FD1)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l[i].libelle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(switch (l[i].frequence) {
                                Frequence.hebdomadaire => 'Toutes les semaines',
                                Frequence.mensuelle => 'Tous les mois',
                                Frequence.annuelle => 'Tous les ans',
                              }, style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Montant(l[i].montantCentimes, taille: 15),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(iconeDe(icone), size: 13, color: couleur),
                                const SizedBox(width: 4),
                                Text(etat(l[i]), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: couleur)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (resume)
          Carte(
            child: Column(
              children: [
                Montant(-paye, taille: 38),
                const SizedBox(height: 6),
                Text('payés sur ${euros(attendu)} attendus ce mois-ci',
                    style: const TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
                const SizedBox(height: 14),
                Jauge(part: attendu == 0 ? 0 : paye / attendu),
              ],
            ),
          ),
          if (blocs && liste.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune récurrence repérée pour l\'instant : il faut au moins deux passages.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.texteSecondaire, height: 1.5)),
            ),
          if (blocs && retard.isNotEmpty)
            bloc('En retard', retard, AppColors.alerte, (x) => 'attendu il y a ${-x.dansJours(DateTime.now())} j', 'schedule'),
          if (blocs && aVenir.isNotEmpty)
            bloc('À venir', aVenir, AppColors.attention, (x) => 'dans ${x.dansJours(DateTime.now())} j', 'calendar_month'),
          if (blocs && payees.isNotEmpty)
            bloc('Payées', payees, AppColors.vert, (x) => 'le ${x.derniere.day}', 'check'),
        ],
      ),
    );
  }
}

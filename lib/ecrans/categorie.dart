import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/icones_symbols.dart';
import '../config/theme.dart';
import '../domaine/modeles.dart';
import '../donnees/depots.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import '../widgets/graphiques.dart';
import '../widgets/volets.dart';

/// Une barre de titre avec son bouton retour.
class BarreRetour extends StatelessWidget {
  const BarreRetour({super.key, required this.titre, this.droite, this.surRetour});

  final String titre;
  final Widget? droite;
  final VoidCallback? surRetour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          BoutonRond(
            icone: 'arrow_back',
            label: 'Retour',
            onTap: surRetour ?? () => revenir(context),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ?droite,
        ],
      ),
    );
  }
}

/// L'en-tête d'une page : sur téléphone, le bouton retour et le titre ;
/// dans un volet de l'écran déplié, le même titre que les volets voisins,
/// sans bouton : on revient par le geste retour.
class EnTetePage extends StatelessWidget {
  const EnTetePage({super.key, required this.titre, this.surtitre, this.montant});

  final String titre;
  final String? surtitre;

  /// Dans un volet, le montant à droite du titre ; sur téléphone, il est
  /// en grand sous l'en-tête.
  final Widget? montant;

  @override
  Widget build(BuildContext context) =>
      dansUnVolet(context) ? TitreVolet(titre: titre, surtitre: surtitre, droite: montant) : BarreRetour(titre: titre);
}

/// Le haut d'une page de détail : grand et centré sur téléphone, sur une
/// ligne dans un volet, pour laisser la place à la liste.
class TeteDetail extends StatelessWidget {
  const TeteDetail({super.key, required this.icone, required this.couleur, required this.montant, required this.texte, this.signe = false, this.tuile});

  final String? icone;
  final Color couleur;
  final int montant;
  final String texte;
  final bool signe;

  /// Une tuile à la place de celle de la catégorie.
  final Widget? tuile;

  @override
  Widget build(BuildContext context) {
    if (dansUnVolet(context)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
        child: Row(
          children: [
            tuile ?? Tuile(icone: icone, couleur: couleur, taille: 36),
            const SizedBox(width: 12),
            Expanded(child: Text(texte, maxLines: 2, style: const TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          tuile ?? Tuile(icone: icone, couleur: couleur, taille: 64),
          const SizedBox(height: 12),
          Montant(montant, taille: 40, signe: signe),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
          ),
        ],
      ),
    );
  }
}

/// Une catégorie : son total, et toutes ses sous-catégories, même vides.
class EcranCategorie extends ConsumerWidget {
  const EcranCategorie({super.key, required this.id, this.dansVolet = false});

  final int id;

  /// Affichée à côté de l'analyse sur l'écran déplié : pas de retour.
  final bool dansVolet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La même période que la liste de l'analyse d'où l'on vient.
    final bilan = ref.watch(bilanPeriodeProvider);
    final periode = ref.watch(periodeProvider);
    final categories = ref.watch(categoriesProvider);
    if (!bilan.hasValue || !categories.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cat = categories.value![id];
    if (cat == null) return const Scaffold(body: Center(child: Text('Catégorie supprimée.')));
    final b = bilan.value!;
    final couleur = Color(cat.couleur);
    final sous = categories.value!.values.where((c) => c.parentId == id).toList()
      ..sort((a, c) {
        final d = (b.parSous[c.id] ?? 0).compareTo(b.parSous[a.id] ?? 0);
        return d != 0 ? d : a.ordre.compareTo(c.ordre);
      });
    final total = b.parCategorie[id] ?? 0;
    final pleines = sous.where((s) => (b.parSous[s.id] ?? 0) > 0).toList();
    final vides = sous.where((s) => (b.parSous[s.id] ?? 0) == 0).toList()..sort((a, c) => a.ordre.compareTo(c.ordre));
    final direct = total - pleines.fold<int>(0, (s, x) => s + (b.parSous[x.id] ?? 0));
    final revenu = cat.genre == Genre.revenu;
    final part = revenu ? (b.entrees == 0 ? 0 : total * 100 ~/ b.entrees) : (b.sorties == 0 ? 0 : total * 100 ~/ b.sorties);
    final volet = dansUnVolet(context);

    return Scaffold(
      body: Stack(
        children: [
          if (!volet) _Lueur(couleur: couleur),
          SafeArea(
            child: Contenu(
              padding: const EdgeInsets.only(bottom: 24),
              tete: EnTetePage(
                surtitre: revenu ? 'Entrées' : 'Dépenses',
                titre: cat.nom,
                montant: Montant(revenu ? total : -total, taille: 24),
              ),
              children: [
                if (!volet) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SelecteurMois()),
                TeteDetail(
                  icone: cat.icone,
                  couleur: couleur,
                  montant: revenu ? total : -total,
                  texte: '$part % de tes ${revenu ? 'entrées' : 'dépenses'} ${periode == Periode.mois ? 'du mois' : 'de la période'}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Carte(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Surtitre('Sous-catégories', droite: Text('${sous.length}', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret))),
                        const SizedBox(height: 14),
                        BarreSegmentee(
                          hauteur: 8,
                          parts: [
                            for (var i = 0; i < pleines.length; i++)
                              (b.parSous[pleines[i].id]!, Color.lerp(couleur, Colors.white, (i % 4) * 0.18)!),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (direct > 0)
                          _LigneSous(nom: cat.nom, icone: cat.icone, couleur: couleur, montant: direct, chemin: '/sous/$id', detail: 'sans sous-catégorie'),
                        for (final s in pleines)
                          _LigneSous(nom: s.nom, icone: s.icone ?? cat.icone, couleur: couleur, montant: b.parSous[s.id]!, chemin: '/sous/${s.id}'),
                        if (vides.isNotEmpty || volet) ...[
                          const SizedBox(height: 14),
                          if (vides.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text('Rien ce mois-ci', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.texteDiscret)),
                            ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in vides)
                                _PuceSous(nom: s.nom, icone: s.icone ?? cat.icone, couleur: couleur, chemin: '/sous/${s.id}'),
                              if (volet)
                                Material(
                                  color: couleur.withValues(alpha: 0.06),
                                  shape: StadiumBorder(side: BorderSide(color: couleur.withValues(alpha: 0.33))),
                                  child: InkWell(
                                    customBorder: const StadiumBorder(),
                                    onTap: () => context.push('/categorie/$id/nouvelle'),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(iconeDe('add'), size: 16, color: couleur),
                                          const SizedBox(width: 6),
                                          Text('Ajouter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: couleur)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (!volet) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/categorie/$id/nouvelle'),
                          icon: Icon(iconeDe('add'), color: couleur),
                          label: Text('Ajouter une sous-catégorie', style: TextStyle(color: couleur, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: const StadiumBorder(),
                            side: BorderSide(color: couleur.withValues(alpha: 0.33)),
                            backgroundColor: couleur.withValues(alpha: 0.06),
                          ),
                        ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              colors: [Color.lerp(couleur, Colors.black, 0.75)!.withValues(alpha: 0.9), Colors.transparent],
            ),
          ),
        ),
      );
}

class _LigneSous extends StatelessWidget {
  const _LigneSous({required this.nom, required this.icone, required this.couleur, required this.montant, required this.chemin, this.detail});

  final String nom;
  final String? icone;
  final Color couleur;
  final int montant;
  final String chemin;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Surligne(
      actif: estOuvert(context, chemin),
      couleur: couleur,
      child: InkWell(
        onTap: () => ouvrirPage(context, chemin),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
          child: Row(
            children: [
              Tuile(icone: icone, couleur: couleur, taille: 38),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    if (detail != null) Text(detail!, style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                  ],
                ),
              ),
              Montant(montant, taille: 15.5),
              Icon(iconeDe('chevron_right'), size: 18, color: AppColors.texteDiscret),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une sous-catégorie sans opération ce mois-ci : une simple pastille.
class _PuceSous extends StatelessWidget {
  const _PuceSous({required this.nom, required this.icone, required this.couleur, required this.chemin});

  final String nom;
  final String? icone;
  final Color couleur;
  final String chemin;

  @override
  Widget build(BuildContext context) {
    final actif = estOuvert(context, chemin);
    return Material(
      color: actif ? couleur.withValues(alpha: 0.14) : AppColors.surfaceBasse,
      shape: StadiumBorder(side: BorderSide(color: actif ? couleur.withValues(alpha: 0.4) : AppColors.trait)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => ouvrirPage(context, chemin),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconeDe(icone), size: 16, color: actif ? couleur : AppColors.texteDiscret),
              const SizedBox(width: 6),
              Text(nom, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: actif ? AppColors.texte : AppColors.texteSecondaire)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les opérations d'une (sous-)catégorie ce mois-ci, jour par jour.
class EcranSousCategorie extends ConsumerWidget {
  const EcranSousCategorie({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(operationsPeriodeProvider);
    final periode = ref.watch(libellePeriodeProvider);
    final categories = ref.watch(categoriesProvider);
    if (!ops.hasValue || !categories.hasValue) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cat = categories.value![id];
    if (cat == null) return const Scaffold(body: Center(child: Text('Catégorie supprimée.')));
    final parent = cat.parentId == null ? cat : categories.value![cat.parentId]!;
    final couleur = Color(parent.couleur);
    final liste = ops.value!.where((o) => o.categorieId == id).toList();
    final total = liste.where((o) => !o.masquee).fold<int>(0, (s, o) => s + o.montantCentimes);

    final jours = <DateTime, List<Operation>>{};
    for (final o in liste) {
      jours.putIfAbsent(DateTime(o.le.year, o.le.month, o.le.day), () => []).add(o);
    }

    final volet = dansUnVolet(context);
    return Scaffold(
      body: Stack(
        children: [
          if (!volet) _Lueur(couleur: couleur),
          SafeArea(
            child: Contenu(
              padding: const EdgeInsets.only(bottom: 24),
              tete: EnTetePage(
                surtitre: cat.parentId != null ? parent.nom : 'Dépenses',
                titre: cat.nom,
                montant: Montant(total, taille: 24),
              ),
              children: [
                if (!volet && cat.parentId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('${parent.nom}  ›  ${cat.nom}', style: const TextStyle(fontSize: 13, color: AppColors.texteDiscret)),
                  ),
                TeteDetail(icone: cat.icone ?? parent.icone, couleur: couleur, montant: total, texte: periode.startsWith(RegExp(r'[0-9]')) ? 'sur $periode' : 'en ${periode.toLowerCase()}'),
                if (liste.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Rien ce mois-ci.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.texteSecondaire)),
                  ),
                for (final e in jours.entries)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(jour(e.key), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire))),
                              Montant(e.value.fold(0, (s, o) => s + o.montantCentimes), taille: 13, couleur: AppColors.texteDiscret),
                            ],
                          ),
                        ),
                        Carte(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Column(
                            children: [
                              for (var i = 0; i < e.value.length; i++)
                                LigneOperation(operation: e.value[i], icone: cat.icone ?? parent.icone, couleur: couleur, separateur: i > 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une opération dans une liste.
class LigneOperation extends StatelessWidget {
  const LigneOperation({super.key, required this.operation, required this.icone, required this.couleur, this.separateur = false});

  final Operation operation;
  final String? icone;
  final Color couleur;
  final bool separateur;

  @override
  Widget build(BuildContext context) {
    final o = operation;
    return Surligne(
      actif: estOuvert(context, '/operation/${o.id}'),
      couleur: couleur,
      child: InkWell(
      onTap: () => ouvrirPage(context, '/operation/${o.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: separateur ? const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))) : null,
        child: Row(
          children: [
            AvecCoche(pointee: o.pointee, child: Tuile(icone: icone, couleur: couleur, taille: 40)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  if (o.note != null && o.note!.isNotEmpty)
                    Row(
                      children: [
                        Icon(iconeDe('sticky_note_2'), size: 12, color: AppColors.texteSecondaire),
                        const SizedBox(width: 5),
                        Expanded(child: Text(o.note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire))),
                      ],
                    )
                  else
                    Text(o.masquee ? 'Masquée de l\'analyse' : 'Compte courant', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                ],
              ),
            ),
            Montant(o.montantCentimes, taille: 15.5, signe: true, couleur: o.masquee ? AppColors.texteDiscret : null),
          ],
        ),
      ),
      ),
    );
  }
}

/// Toutes les catégories et leurs sous-catégories.
class EcranCategories extends ConsumerWidget {
  const EcranCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    if (!categories.hasValue) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final toutes = categories.value!.values.toList()..sort((a, b) => a.ordre.compareTo(b.ordre));
    final racines = toutes.where((c) => c.parentId == null).toList();
    final nbSous = toutes.length - racines.length;

    Widget bloc(String titre, List<Categorie> liste) => Carte(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Surtitre(titre),
              for (final c in liste)
                InkWell(
                  onTap: () => context.push('/categorie/${c.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Tuile(icone: c.icone, couleur: Color(c.couleur), taille: 38),
                            const SizedBox(width: 12),
                            Expanded(child: Text(c.nom, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
                            Text('${toutes.where((s) => s.parentId == c.id).length}', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 50),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final s in toutes.where((s) => s.parentId == c.id))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color(c.couleur).withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Color(c.couleur).withValues(alpha: 0.18)),
                                  ),
                                  child: Text(s.nom, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.texteSecondaire)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const BarreRetour(titre: 'Catégories'),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
              child: Text('${racines.length} catégories, $nbSous sous-catégories.',
                  style: const TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  bloc('Dépenses', racines.where((c) => c.genre == Genre.depense).toList()),
                  const SizedBox(height: 14),
                  bloc('Revenus, épargne et virements', racines.where((c) => c.genre != Genre.depense).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Créer une sous-catégorie : son nom, sa couleur, son icône.
class EcranNouvelleSousCategorie extends ConsumerStatefulWidget {
  const EcranNouvelleSousCategorie({super.key, required this.parentId});

  final int parentId;

  @override
  ConsumerState<EcranNouvelleSousCategorie> createState() => _EtatNouvelle();
}

const couleursChoix = [
  0xFF1ED760, 0xFF2EE6A0, 0xFF4DE2D0, 0xFF3CE0FF, 0xFF5AB2FF, 0xFF7C8CFF, 0xFF9B8CFF, 0xFFC77DFF, 0xFFFF8FD1,
  0xFFFF6B9A, 0xFFFF6B7A, 0xFFFF9F5A, 0xFFFFC857, 0xFFC6F45A, 0xFFE8B98A, 0xFFB0B8FF, 0xFFA3B8AB, 0xFF8A8A8A,
];

class _EtatNouvelle extends ConsumerState<EcranNouvelleSousCategorie> {
  final _nom = TextEditingController();
  int? _couleur;
  String _icone = 'category';
  String? _groupe;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _creer(Categorie parent) async {
    final nom = _nom.text.trim();
    if (nom.isEmpty) return;
    await const DepotCategories().creer(
      nom: nom,
      parentId: parent.id,
      genre: parent.genre,
      icone: _icone,
      couleur: _couleur ?? parent.couleur,
      nature: parent.nature,
    );
    rafraichir(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(categoriesProvider).value?[widget.parentId];
    if (parent == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final couleur = Color(_couleur ?? parent.couleur);
    final groupes = _groupe == null ? groupesIcones : groupesIcones.where((g) => g.$1 == _groupe).toList();
    final large = MediaQuery.sizeOf(context).width >= 720;

    const etiquette = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire);

    // L'aperçu, le nom et la couleur.
    final reglages = <Widget>[
      Center(child: Tuile(icone: _icone, couleur: couleur, taille: large ? 96 : 88)),
      const SizedBox(height: 12),
      ValueListenableBuilder(
        valueListenable: _nom,
        builder: (_, v, _) => Text(v.text.isEmpty ? 'Sans nom' : v.text,
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Dans ', style: TextStyle(fontSize: 13, color: AppColors.texteSecondaire)),
          Icon(iconeDe(parent.icone), size: 16, color: Color(parent.couleur), fill: 1),
          const SizedBox(width: 4),
          Text(parent.nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
      const SizedBox(height: 22),
      const Text('Nom', style: etiquette),
      const SizedBox(height: 8),
      TextField(controller: _nom, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Nom de la sous-catégorie')),
      const SizedBox(height: 22),
      const Text('Couleur', style: etiquette),
      const SizedBox(height: 12),
      Wrap(
        spacing: large ? 8 : 10,
        runSpacing: large ? 10 : 10,
        children: [
          for (final c in couleursChoix)
            GestureDetector(
              onTap: () => setState(() => _couleur = c),
              child: Container(
                // Neuf par ligne dans la colonne de l'écran déplié.
                width: large ? 30 : 36,
                height: large ? 30 : 36,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: c == (_couleur ?? parent.couleur) ? Border.all(color: Colors.white, width: 2.5, strokeAlign: BorderSide.strokeAlignOutside) : null,
                ),
              ),
            ),
        ],
      ),
    ];

    // Le choix de l'icône.
    final filtres = SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final g in [null, ...groupesIcones.map((g) => g.$1)])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(g ?? 'Tout'),
                selected: g == _groupe,
                onSelected: (_) => setState(() => _groupe = g),
                showCheckmark: false,
                selectedColor: AppColors.vert,
                backgroundColor: AppColors.surfaceHaute,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, color: g == _groupe ? Colors.black : AppColors.texte),
                side: BorderSide.none,
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
    final grilles = <Widget>[
      for (final g in groupes) ...[
        Text(g.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GridView.extent(
          maxCrossAxisExtent: 56,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final n in g.$2)
              GestureDetector(
                onTap: () => setState(() => _icone = n),
                child: n == _icone
                    ? Tuile(icone: n, couleur: couleur)
                    : Container(
                        decoration: BoxDecoration(color: AppColors.surfaceBasse, borderRadius: BorderRadius.circular(14)),
                        child: Icon(iconeDe(n), size: 24, color: AppColors.texteSecondaire),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 22),
      ],
    ];
    final titreIcones = Text('Icône · ${groupesIcones.fold<int>(0, (s, g) => s + g.$2.length)} au choix', style: etiquette);

    final bouton = ValueListenableBuilder(
      valueListenable: _nom,
      builder: (_, v, _) => FilledButton(
        onPressed: v.text.trim().isEmpty ? null : () => _creer(parent),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          disabledBackgroundColor: AppColors.surfaceHaute,
          disabledForegroundColor: AppColors.texteDiscret,
        ),
        child: const Text('Créer la sous-catégorie'),
      ),
    );

    // Sur l'écran déplié, deux colonnes : à gauche l'aperçu, le nom, la
    // couleur et le bouton ; à droite les icônes, qui défilent seules.
    if (large) {
      return Scaffold(
        body: Stack(
          children: [
            _Lueur(couleur: couleur),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BarreRetour(titre: 'Nouvelle sous-catégorie'),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 380,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: reglages))),
                                const SizedBox(height: 16),
                                bouton,
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, color: AppColors.trait),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 12), child: titreIcones),
                              Padding(padding: const EdgeInsets.only(left: 24), child: filtres),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                                  children: grilles,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _Lueur(couleur: couleur),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BarreRetour(titre: 'Nouvelle sous-catégorie'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      ...reglages,
                      const SizedBox(height: 26),
                      titreIcones,
                      const SizedBox(height: 12),
                      filtres,
                      const SizedBox(height: 18),
                      ...grilles,
                    ],
                  ),
                ),
                // Le bouton sous la liste, jamais par-dessus.
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: bouton),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Choisir une catégorie ou une sous-catégorie, dans une feuille.
Future<int?> choisirCategorie(BuildContext context, WidgetRef ref, {Genre? genre}) async {
  final toutes = (await ref.read(categoriesProvider.future)).values.toList()..sort((a, b) => a.ordre.compareTo(b.ordre));
  if (!context.mounted) return null;
  final racines = toutes.where((c) => c.parentId == null && (genre == null || c.genre == genre || c.genre == Genre.interne)).toList();
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (_, controle) => ListView(
        controller: controle,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        children: [
          for (final r in racines)
            ExpansionTile(
              leading: Tuile(icone: r.icone, couleur: Color(r.couleur), taille: 36),
              title: Text(r.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
              shape: const Border(),
              children: [
                for (final s in toutes.where((s) => s.parentId == r.id))
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 64, right: 8),
                    leading: Icon(iconeDe(s.icone ?? r.icone), color: Color(r.couleur), size: 20),
                    title: Text(s.nom),
                    onTap: () => Navigator.pop(ctx, s.id),
                  ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 64, right: 8),
                  title: Text('${r.nom}, sans sous-catégorie', style: const TextStyle(color: AppColors.texteSecondaire)),
                  onTap: () => Navigator.pop(ctx, r.id),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

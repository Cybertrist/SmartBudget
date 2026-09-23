import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/classement.dart';
import '../domaine/libelle.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../domaine/recurrences.dart';
import '../domaine/virements.dart';
import '../donnees/depots.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import '../widgets/volets.dart';
import 'categorie.dart';
import 'dialogues.dart';

/// Une opération, en page pleine : sa note, son classement, son suivi.
class EcranOperation extends ConsumerStatefulWidget {
  const EcranOperation({super.key, required this.id});

  final int id;

  @override
  ConsumerState<EcranOperation> createState() => _EtatOperation();
}

class _EtatOperation extends ConsumerState<EcranOperation> {
  @override
  Widget build(BuildContext context) {
    final op = ref.watch(operationProvider(widget.id));
    final categories = ref.watch(categoriesProvider);
    final liens = ref.watch(liensProvider(widget.id));
    if (!op.hasValue || !categories.hasValue) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final o = op.value;
    if (o == null) return const Scaffold(body: Center(child: Text('Opération supprimée.')));
    final cats = categories.value!;
    final cat = cats[o.categorieId]!;
    final parent = cat.parentId == null ? cat : cats[cat.parentId]!;
    final couleur = Color(parent.couleur);
    final nature = o.nature ?? cat.nature;
    final moisOp = Mois.de(o.le);
    final moisCompte = o.moisCompte == null ? moisOp : Mois.lire(o.moisCompte!);
    final lies = liens.value ?? const <Lien>[];
    final cle = cleMarchand(o.libelle);
    final repetition = ref.watch(recurrencesProvider).value?.where((r) => r.cle == cle).firstOrNull;

    Future<void> modifier(Future<void> Function() f) async {
      await f();
      rafraichir(ref);
    }

    // Dépense, revenu, ou virement entre tes comptes : la détection peut
    // se tromper dans les deux sens, alors cela se corrige ici.
    Future<void> choisirMouvement() async {
      final choix = await showModalBottomSheet<(SensInterne?,)>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: 560),
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Text(
                    'Un virement entre tes comptes n\'est ni une dépense ni un revenu : il sort du budget.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire),
                  ),
                ),
                for (final (sens, texte, icone) in [
                  (null, o.entree ? 'Revenu' : 'Dépense', 'label'),
                  (SensInterne.versEpargne, "Virement vers l'épargne", 'savings'),
                  (SensInterne.depuisEpargne, "Virement depuis l'épargne", 'savings'),
                  (SensInterne.entreComptes, 'Virement entre mes comptes', 'sync_alt'),
                ])
                  ListTile(
                    leading: Icon(iconeDe(icone), color: sens == null ? AppColors.texteSecondaire : AppColors.interne),
                    title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: sens == o.interne ? Icon(iconeDe('check'), color: AppColors.vert) : null,
                    onTap: () => Navigator.pop(ctx, (sens,)),
                  ),
              ],
            ),
          ),
        ),
      );
      if (choix == null || choix.$1 == o.interne) return;
      final sens = choix.$1;
      if (sens != null) {
        await modifier(() => const DepotOperations().marquerInterne(o.id, sens));
        return;
      }
      // Ce n'était pas un virement interne : il lui faut une vraie catégorie.
      if (!context.mounted) return;
      final id = await choisirCategorie(context, ref);
      if (id == null) return;
      await modifier(() async {
        await const DepotOperations().reclasser(o.id, id);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Contenu(
          padding: const EdgeInsets.only(bottom: 24),
          // Dans un volet, le montant monte à côté du titre et l'en-tête
          // tient sur une ligne : la page n'est plus qu'un bloc serré.
          tete: EnTetePage(surtitre: cat.nom, titre: o.titre, montant: Montant(o.montantCentimes, taille: 24, signe: true)),
          children: [
            if (dansUnVolet(context))
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    AvecCoche(
                      pointee: o.pointee,
                      child: o.interne != null ? const _TuileInterne(taille: 40) : Tuile(icone: cat.icone ?? parent.icone, couleur: couleur, taille: 40),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${jour(o.le)} ${o.le.year} · Compte courant\n${o.libelle.toUpperCase()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.texteDiscret, fontFeatures: chiffres)),
                    ),
                  ],
                ),
              )
            else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                children: [
                  AvecCoche(
                    pointee: o.pointee,
                    taille: 26,
                    child: o.interne != null ? const _TuileInterne(taille: 72) : Tuile(icone: cat.icone ?? parent.icone, couleur: couleur, taille: 72),
                  ),
                  const SizedBox(height: 14),
                  Montant(o.montantCentimes, taille: 44, signe: true),
                  const SizedBox(height: 10),
                  Text(o.titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('${o.libelle.toUpperCase()}\n${jour(o.le)} ${o.le.year} · Compte courant',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.texteDiscret, fontFeatures: chiffres)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // La note s'écrit dans une carte qui s'agrandit au centre :
                  // le clavier ne pousse plus la page hors de l'écran.
                  _CarteNote(
                    note: o.note,
                    onTap: () async {
                      final texte = await ecrireNote(context, titre: o.titre, initial: o.note ?? '');
                      if (texte == null) return;
                      await modifier(() => const DepotOperations().modifier(o.id, note: texte.trim().isEmpty ? null : texte.trim()));
                    },
                  ),
                  const SizedBox(height: 14),
                  Carte(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Surtitre('Classement'),
                          _Ligne(
                            icone: 'edit',
                            libelle: 'Nom',
                            valeur: o.titre,
                            onTap: () async {
                              final nom = await demanderTexte(
                                context,
                                titre: 'Renommer',
                                aide: 'Toutes les opérations « ${joli(o.libelle)} » prendront ce nom, les prochaines aussi.',
                                initial: o.titre,
                                indice: joli(o.libelle),
                              );
                              if (nom != null) await modifier(() => const DepotOperations().renommer(o.id, nom));
                            },
                          ),
                          _Ligne(
                            icone: 'sync_alt',
                            libelle: 'Mouvement',
                            valeur: switch (o.interne) {
                              null => o.entree ? 'Revenu' : 'Dépense',
                              SensInterne.versEpargne => "Vers l'épargne",
                              SensInterne.depuisEpargne => "Depuis l'épargne",
                              SensInterne.entreComptes => 'Entre mes comptes',
                            },
                            couleur: o.interne == null ? null : AppColors.interne,
                            onTap: choisirMouvement,
                          ),
                          if (o.interne == null) ...[
                          _Ligne(
                            icone: 'label',
                            libelle: 'Catégorie',
                            valeur: cat.parentId == null ? cat.nom : '${parent.nom} › ${cat.nom}',
                            couleur: couleur,
                            onTap: () async {
                              final id = await choisirCategorie(context, ref);
                              if (id == null) return;
                              final suivies = await const DepotOperations().reclasser(o.id, id);
                              rafraichir(ref);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(suivies > 0
                                      ? 'Reclassée, et ${pluriel(suivies, 'autre opération')} du même marchand avec elle.'
                                      : 'Reclassée. Les prochaines de ce marchand suivront.'),
                                ));
                              }
                            },
                          ),
                          if (!o.entree)
                            _Ligne(
                              icone: 'favorite',
                              libelle: 'Type',
                              valeur: nature.libelle,
                              couleur: couleurNature(nature),
                              onTap: () async {
                                final choix = await showModalBottomSheet<Nature>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (ctx) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (final n in Nature.values)
                                          ListTile(
                                            leading: Icon(iconeDe(iconeNature(n)), color: couleurNature(n), fill: 1),
                                            title: Text(n.libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            trailing: n == nature ? Icon(iconeDe('check'), color: AppColors.vert) : null,
                                            onTap: () => Navigator.pop(ctx, n),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                                if (choix != null) await modifier(() => const DepotOperations().modifier(o.id, nature: choix));
                              },
                            ),
                          _Ligne(
                            icone: 'calendar_month',
                            libelle: 'Compte en',
                            valeur: nomMoisSeul(moisCompte),
                            onTap: () async {
                              final choix = await showModalBottomSheet<Mois>(
                                context: context,
                                showDragHandle: true,
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final m in [moisOp.precedent, moisOp, moisOp.suivant])
                                        ListTile(
                                          title: Text(nomMois(m)),
                                          trailing: m == moisCompte ? Icon(iconeDe('check'), color: AppColors.vert) : null,
                                          onTap: () => Navigator.pop(ctx, m),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                              if (choix != null) {
                                await modifier(() => const DepotOperations().modifier(o.id, moisCompte: choix == moisOp ? null : choix));
                              }
                            },
                          ),
                          ],
                        ],
                      ),
                    ),
                  if (o.interne != null) ...[
                    const SizedBox(height: 14),
                    _BlocInterne(sens: o.interne!),
                  ],
                  const SizedBox(height: 14),
                  Carte(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Surtitre('Suivi'),
                        if (!o.entree && o.interne == null)
                          _Ligne(
                            icone: 'autorenew',
                            libelle: 'Répétition',
                            valeur: repetition?.frequence.libelle ?? 'Aucune',
                            couleur: repetition == null ? null : AppColors.vert,
                            onTap: () async {
                              // Un enregistrement, pour distinguer « aucune » d'une feuille refermée.
                              final choix = await showModalBottomSheet<(Frequence?,)>(
                                context: context,
                                showDragHandle: true,
                                isScrollControlled: true,
                                constraints: const BoxConstraints(maxWidth: 560),
                                builder: (ctx) => SafeArea(
                                  child: SingleChildScrollView(
                                    child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                                        child: Text('Toutes les opérations « ${joli(cle)} » suivent ce choix.',
                                            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
                                      ),
                                      for (final (f, texte) in [(null, 'Aucune'), for (final f in Frequence.values) (f, f.libelle)])
                                        ListTile(
                                          title: Text(texte, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          trailing: f == repetition?.frequence ? Icon(iconeDe('check'), color: AppColors.vert) : null,
                                          onTap: () => Navigator.pop(ctx, (f,)),
                                        ),
                                    ],
                                  ),
                                  ),
                                ),
                              );
                              if (choix != null) await modifier(() => const DepotOperations().choisirRepetition(cle, choix.$1));
                            },
                          ),
                        _Bascule(
                          icone: 'visibility_off',
                          libelle: 'Masquer de l\'analyse',
                          valeur: o.masquee,
                          onChanged: (v) => modifier(() => const DepotOperations().modifier(o.id, masquee: v)),
                        ),
                      ],
                    ),
                  ),
                  if (o.origine == Origine.main || o.origine == Origine.regle) ...[
                    const SizedBox(height: 14),
                    _Info(
                      texte: o.origine == Origine.main
                          ? 'Reclassée à la main. Les prochaines opérations « ${joli(cleMarchand(o.libelle))} » iront d\'elles-mêmes dans ${cat.nom}.'
                          : 'Classée d\'après une de tes corrections précédentes.',
                    ),
                  ],
                  if (o.entree && o.interne == null) ...[
                    const SizedBox(height: 14),
                    _BlocRembourse(operation: o, liens: lies.where((l) => l.entreeId == o.id).toList()),
                  ],
                  if (!o.entree && o.interne == null) ...[
                    const SizedBox(height: 14),
                    Builder(builder: (context) {
                      final rembourse = lies.where((l) => l.depenseId == o.id).fold(0, (s, l) => s + l.montantCentimes);
                      return Carte(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Ligne(
                              icone: 'link',
                              libelle: 'Remboursement',
                              valeur: rembourse == 0 ? 'Aucun' : '${euros(rembourse)} reçus',
                              couleur: rembourse == 0 ? null : AppColors.vert,
                              onTap: () => context.push('/operation/${o.id}/rembourse'),
                            ),
                            if (rembourse > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text('Elle ne compte plus que pour ${euros(-o.montantCentimes - rembourse)}.',
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 18),
                  // Pointer : tu confirmes que la catégorie est la bonne.
                  o.pointee
                      ? OutlinedButton.icon(
                          onPressed: () => modifier(() => const DepotOperations().pointer(o.id, false)),
                          icon: Icon(iconeDe('task_alt'), color: AppColors.vert),
                          label: const Text('Pointée', style: TextStyle(color: AppColors.vert, fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: const StadiumBorder(),
                            side: BorderSide(color: AppColors.vert.withValues(alpha: 0.4)),
                            backgroundColor: AppColors.vert.withValues(alpha: 0.08),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () => modifier(() => const DepotOperations().pointer(o.id, true)),
                          icon: Icon(iconeDe('task_alt'), color: Colors.black),
                          label: const Text('Pointer', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: const StadiumBorder(),
                            backgroundColor: AppColors.vert,
                            foregroundColor: Colors.black,
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

class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.libelle, required this.valeur, required this.onTap, this.couleur});

  final String icone;
  final String libelle;
  final String valeur;
  final VoidCallback onTap;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _PetiteIcone(icone),
              const SizedBox(width: 14),
              Text(libelle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(valeur,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: couleur ?? AppColors.texteSecondaire)),
              ),
              Icon(iconeDe('chevron_right'), size: 18, color: AppColors.texteDiscret),
            ],
          ),
        ),
      );
}

class _PetiteIcone extends StatelessWidget {
  const _PetiteIcone(this.icone);

  final String icone;

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(11)),
        child: Icon(iconeDe(icone), size: 18, color: AppColors.texteSecondaire),
      );
}

class _Bascule extends StatelessWidget {
  const _Bascule({required this.icone, required this.libelle, required this.valeur, required this.onChanged});

  final String icone;
  final String libelle;
  final bool valeur;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: Row(
          children: [
            _PetiteIcone(icone),
            const SizedBox(width: 14),
            Expanded(child: Text(libelle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
            Switch(value: valeur, onChanged: onChanged),
          ],
        ),
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.vert.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.vert.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconeDe('check'), size: 18, color: AppColors.vert),
            const SizedBox(width: 12),
            Expanded(child: Text(texte, style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire))),
          ],
        ),
      );
}

class _TuileInterne extends StatelessWidget {
  const _TuileInterne({this.taille = 42});

  final double taille;

  @override
  Widget build(BuildContext context) => Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          color: AppColors.interne.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(taille * 0.34),
          border: Border.all(color: AppColors.interne.withValues(alpha: 0.3)),
        ),
        child: Icon(iconeDe('sync_alt'), size: taille * 0.48, color: AppColors.interne),
      );
}

class _BlocInterne extends StatelessWidget {
  const _BlocInterne({required this.sens});

  final SensInterne sens;

  @override
  Widget build(BuildContext context) {
    final (texte, couleur) = switch (sens) {
      SensInterne.versEpargne => ('Mis de côté', AppColors.vert),
      SensInterne.depuisEpargne => ('Pioché dans l\'épargne', AppColors.alerte),
      SensInterne.entreComptes => ('Entre tes comptes', AppColors.interne),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: const Hachures(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.interne.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(texte, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: couleur)),
              const SizedBox(height: 6),
              const Text(
                'Virement interne : ni dépense ni revenu, l\'argent change seulement de compte. Il est exclu du budget et de l\'analyse.',
                style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlocRembourse extends ConsumerWidget {
  const _BlocRembourse({required this.operation, required this.liens});

  final Operation operation;
  final List<Lien> liens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reparti = liens.fold<int>(0, (s, l) => s + l.montantCentimes);
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Surtitre('Rembourse', droite: Text(pluriel(liens.length, 'dépense'), style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret))),
          const SizedBox(height: 10),
          Text(
            liens.isEmpty
                ? 'Si cette entrée rembourse des dépenses, lie-les : elles ne compteront plus que pour leur reste à charge, et elle ne comptera pas comme un revenu.'
                : '${euros(reparti)} répartis sur ${euros(operation.montantCentimes)}. Reste ${euros(operation.montantCentimes - reparti)}.',
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.push('/operation/${operation.id}/lier'),
            icon: Icon(iconeDe('link'), color: const Color(0xFF7FE0A8)),
            label: Text(liens.isEmpty ? 'Lier des dépenses' : 'Modifier les dépenses liées',
                style: const TextStyle(color: Color(0xFF7FE0A8), fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              side: const BorderSide(color: Color(0x557FE0A8)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Répartir une entrée sur les dépenses qu'elle rembourse.
class EcranLier extends ConsumerStatefulWidget {
  const EcranLier({super.key, required this.id});

  final int id;

  @override
  ConsumerState<EcranLier> createState() => _EtatLier();
}

class _EtatLier extends ConsumerState<EcranLier> {
  final _parts = <int, TextEditingController>{};
  List<Operation>? _depenses;
  bool _lu = false;

  @override
  void dispose() {
    for (final c in _parts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _charger(Operation entree) async {
    final fin = entree.le.add(const Duration(days: 1));
    final ops = await const DepotOperations().entre(entree.le.subtract(const Duration(days: 60)), fin);
    final liens = await const DepotLiens().concernant([entree.id]);
    setState(() {
      _depenses = ops.where((o) => !o.entree && o.interne == null).toList();
      for (final l in liens.where((l) => l.entreeId == entree.id)) {
        _parts[l.depenseId] = TextEditingController(text: euros(l.montantCentimes).replaceAll(' €', ''));
      }
    });
  }

  int get _reparti => _parts.values.fold(0, (s, c) => s + (lireEuros(c.text) ?? 0));

  @override
  Widget build(BuildContext context) {
    final entree = ref.watch(operationProvider(widget.id)).value;
    if (entree == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_lu) {
      _lu = true;
      _charger(entree);
    }
    final depenses = _depenses;
    final reparti = _reparti;
    final trop = reparti > entree.montantCentimes;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BarreRetour(titre: 'Lier des dépenses'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                children: [
                  Carte(
                    couleur: const Color(0xFF16231C),
                    child: Row(
                      children: [
                        const Tuile(icone: 'payments', couleur: Color(0xFF7FE0A8), taille: 40),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entree.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                        Montant(entree.montantCentimes, signe: true, couleur: const Color(0xFF7FE0A8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Text('Réparti', style: TextStyle(color: AppColors.texteSecondaire))),
                      Text('${euros(reparti)} / ${euros(entree.montantCentimes)}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontFeatures: chiffres, color: trop ? AppColors.alerte : AppColors.texte)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Jauge(part: reparti / entree.montantCentimes, couleur: trop ? AppColors.alerte : AppColors.vert),
                  const SizedBox(height: 18),
                  const Surtitre('Dépenses des 60 jours précédents'),
                  const SizedBox(height: 8),
                  if (depenses == null) const Center(child: CircularProgressIndicator()),
                  for (final d in depenses ?? const <Operation>[])
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _parts.containsKey(d.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                final reste = entree.montantCentimes - _reparti;
                                final part = reste.clamp(0, -d.montantCentimes);
                                _parts[d.id] = TextEditingController(text: euros(part).replaceAll(' €', ''));
                              } else {
                                _parts.remove(d.id)?.dispose();
                              }
                            }),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${jourCourt(d.le)} · ${euros(d.montantCentimes)}', style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                              ],
                            ),
                          ),
                          if (_parts.containsKey(d.id))
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _parts[d.id],
                                onChanged: (_) => setState(() {}),
                                textAlign: TextAlign.right,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(suffixText: '€', isDense: true),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: FilledButton(
                onPressed: trop
                    ? null
                    : () async {
                        final parts = {for (final e in _parts.entries) e.key: lireEuros(e.value.text) ?? 0}..removeWhere((_, v) => v <= 0);
                        try {
                          await const DepotLiens().repartir(entree.id, parts);
                          rafraichir(ref);
                          if (context.mounted) context.pop();
                        } on ArgumentError catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
                        }
                      },
                child: Text(_parts.isEmpty ? 'Enregistrer' : 'Lier ${pluriel(_parts.length, 'dépense')}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Depuis une dépense : choisir l'entrée d'argent qui la rembourse.
class EcranChoisirRemboursement extends ConsumerStatefulWidget {
  const EcranChoisirRemboursement({super.key, required this.id});

  final int id;

  @override
  ConsumerState<EcranChoisirRemboursement> createState() => _EtatChoisirRemboursement();
}

class _EtatChoisirRemboursement extends ConsumerState<EcranChoisirRemboursement> {
  Operation? _depense;
  List<Operation> _entrees = const [];
  int? _choix;
  bool _pret = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final d = await const DepotOperations().une(widget.id);
    if (d == null) return;
    final entrees = await const DepotOperations().remboursementsPossibles(d);
    final liens = await const DepotLiens().concernant([d.id]);
    if (!mounted) return;
    setState(() {
      _depense = d;
      _entrees = entrees;
      _choix = liens.where((l) => l.depenseId == d.id).firstOrNull?.entreeId;
      _pret = true;
    });
  }

  Future<void> _valider() async {
    try {
      await const DepotLiens().rembourser(widget.id, _choix);
      rafraichir(ref);
      if (mounted) context.pop();
    } on ArgumentError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <int, Categorie>{};
    final jours = <DateTime, List<Operation>>{};
    for (final o in _entrees) {
      jours.putIfAbsent(DateTime(o.le.year, o.le.month, o.le.day), () => []).add(o);
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarreRetour(titre: 'Associer à un remboursement'),
            if (_depense != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: Text(
                  'Pour « ${_depense!.titre} », ${euros(-_depense!.montantCentimes)}. Choisis l\'argent reçu qui la rembourse.',
                  style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
                ),
              ),
            Expanded(
              child: !_pret
                  ? const Center(child: CircularProgressIndicator())
                  : _entrees.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Aucune entrée d\'argent autour de cette date.',
                              textAlign: TextAlign.center, style: TextStyle(color: AppColors.texteSecondaire)),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            for (final e in jours.entries) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                                child: Text(jour(e.key),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire)),
                              ),
                              Carte(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < e.value.length; i++)
                                      _LigneChoix(
                                        operation: e.value[i],
                                        categorie: categories[e.value[i].categorieId]?.nom ?? '',
                                        choisie: _choix == e.value[i].id,
                                        separateur: i > 0,
                                        onTap: () => setState(() => _choix = _choix == e.value[i].id ? null : e.value[i].id),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: FilledButton(
                onPressed: _pret ? _valider : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                  backgroundColor: AppColors.vert,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                child: Text(_choix == null ? 'Aucun remboursement' : 'Valider'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneChoix extends StatelessWidget {
  const _LigneChoix({required this.operation, required this.categorie, required this.choisie, required this.separateur, required this.onTap});

  final Operation operation;
  final String categorie;
  final bool choisie;
  final bool separateur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: separateur ? const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))) : null,
          child: Row(
            children: [
              Icon(iconeDe(choisie ? 'task_alt' : 'radio_button_unchecked'), color: choisie ? AppColors.vert : AppColors.texteDiscret),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(operation.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$categorie · Compte courant', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                  ],
                ),
              ),
              Montant(operation.montantCentimes, taille: 15.5, signe: true, couleur: AppColors.vert),
            ],
          ),
        ),
      );
}

/// La note d'une opération, telle qu'elle s'affiche sur sa page.
class _CarteNote extends StatelessWidget {
  const _CarteNote({required this.note, required this.onTap});

  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vide = note == null || note!.isEmpty;
    return Material(
        color: AppColors.surfaceHaute,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(iconeDe('sticky_note_2'), color: AppColors.vert),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    vide ? 'Ajouter une note' : note!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.5, color: vide ? AppColors.texteDiscret : AppColors.texte),
                  ),
                ),
                if (!vide) Icon(iconeDe('edit'), size: 18, color: AppColors.texteDiscret),
              ],
            ),
          ),
        ),
    );
  }
}

/// Écrire une note, dans la carte de saisie. Rend le texte, vide pour
/// effacer, ou rien si l'on ferme sans valider.
Future<String?> ecrireNote(BuildContext context, {required String titre, required String initial}) {
  final champ = TextEditingController(text: initial);
  return carteSaisie<String>(
    context,
    titre: 'Note · $titre',
    resultat: () => champ.text,
    gauche: initial.isEmpty
        ? null
        : Builder(
            builder: (ctx) => TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Effacer', style: TextStyle(color: AppColors.alerte)),
            ),
          ),
    champ: (_, valider) => TextField(
      controller: champ,
      autofocus: true,
      maxLength: 140,
      minLines: 2,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => valider(),
      style: const TextStyle(fontSize: 17),
      decoration: const InputDecoration(hintText: 'Colis Amazon, cadeau pour…'),
    ),
  );
}

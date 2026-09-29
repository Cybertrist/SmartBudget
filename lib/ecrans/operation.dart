import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/layout.dart';
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
    Widget page(Widget corps) => Scaffold(
          body: SafeArea(child: Column(children: [const BarreRetour(titre: 'Opération'), Expanded(child: corps)])),
        );
    final erreur = op.hasError ? op.error : categories.hasError ? categories.error : null;
    if (erreur != null && (!op.hasValue || !categories.hasValue)) {
      return page(_Echec(message: 'Lecture impossible. ${_messageErreur(erreur)}', reessayer: () => rafraichir(ref)));
    }
    if (!op.hasValue || !categories.hasValue) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final o = op.value;
    if (o == null) return page(const _Echec(message: 'Cette opération n\'existe plus.'));
    final cats = categories.value!;
    final cat = cats[o.categorieId]!;
    final parent = cat.parentId == null ? cat : cats[cat.parentId]!;
    final couleur = Color(parent.couleur);
    final nature = o.nature ?? cat.nature;
    final moisOp = (ref.watch(calendrierProvider).value ?? Calendrier(debut: ref.watch(debutMoisProvider).value ?? 1)).de(o.le);
    final moisCompte = o.moisCompte == null ? moisOp : Mois.lire(o.moisCompte!);
    final lies = liens.value ?? const <Lien>[];
    final cle = cleMarchand(o.libelle);
    final repetition = ref.watch(recurrencesProvider).value?.where((r) => r.cle == cle).firstOrNull;
    final remboursements = cats.values.where((c) => c.nom == 'Remboursements' && c.parentId != null && cats[c.parentId]?.genre == Genre.revenu).firstOrNull;

    Future<void> modifier(Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageErreur(e))));
      }
      rafraichir(ref);
    }

    // Dépense, revenu, ou virement entre tes comptes : la détection peut
    // se tromper dans les deux sens, alors cela se corrige ici.
    Future<void> choisirMouvement() async {
      final choix = await carteChoix<(SensInterne?,)>(
        context,
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

    final gauche = <Widget>[
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
                                ? 'Reclassée, et ${pluriel(suivies, 'autre opération', 'autres opérations')} du même marchand avec elle.'
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
                          final choix = await carteChoix<Nature>(
                            context,
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
                        final choix = await carteChoix<Mois>(
                          context,
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
    ];
    final droite = <Widget>[
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
                        final choix = await carteChoix<(Frequence?,)>(
                          context,
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
                  // Une entrée qui rembourse une dépense n'est pas un revenu :
                  // rangée dans « Remboursements », elle sort des entrées.
                  if (o.entree && o.interne == null && remboursements != null)
                    _Bascule(
                      icone: 'currency_exchange',
                      libelle: 'C\'est un remboursement',
                      valeur: o.categorieId == remboursements.id,
                      onChanged: (v) => modifier(() async {
                        final proposee = v ? null : await const DepotOperations().categorieProposee(o);
                        await const DepotOperations().reclasser(
                          o.id,
                          v ? remboursements.id : (proposee == null || proposee == remboursements.id ? remboursements.parentId! : proposee),
                          apprendre: false,
                        );
                      }),
                    ),
                  // Un virement interne est déjà hors de l'analyse : la
                  // bascule le montre, et ne change qu'avec le mouvement.
                  _Bascule(
                    icone: 'visibility_off',
                    libelle: 'Masquer de l\'analyse',
                    valeur: o.masquee || o.interne != null,
                    onChanged: o.interne != null ? null : (v) => modifier(() => const DepotOperations().modifier(o.id, masquee: v)),
                  ),
                ],
              ),
            ),
            if (o.origine == Origine.main || o.origine == Origine.regle) ...[
              const SizedBox(height: 14),
              _Info(
                texte: o.especes
                    ? 'Payée en espèces, saisie à la main.'
                    : o.origine == Origine.main && motifAApprendre(o.libelle) == null
                    ? 'Reclassée à la main. Un chèque ou un retrait n\'a pas de marchand : les suivants ne la suivront pas.'
                    : o.origine == Origine.main
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
              _BlocRemboursements(depense: o, liens: lies.where((l) => l.depenseId == o.id).toList()),
            ],
            if (o.uidBanque == null) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer cette dépense ?'),
                      content: const Text('Elle a été saisie à la main : la banque ne la connaît pas.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: AppColors.alerte))),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await const DepotOperations().supprimerManuelle(o.id);
                  rafraichir(ref);
                  if (context.mounted) revenir(context);
                },
                icon: Icon(iconeDe('delete'), color: AppColors.alerte),
                label: const Text('Supprimer la dépense', style: TextStyle(color: AppColors.alerte, fontWeight: FontWeight.w700)),
              ),
            ],
    ];
    final pointer = <Widget>[
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
    ];
    final deuxColonnes = AppLayout.usesRail(context) && !dansUnVolet(context);

    // Dans un volet, ou en pleine page sur l'écran déplié : l'en-tête
    // serré, pour que tout tienne sans défiler.
    final serre = dansUnVolet(context) || AppLayout.usesRail(context);
    return Scaffold(
      body: SafeArea(
        child: Contenu(
          padding: const EdgeInsets.only(bottom: 24),
          // Ouverte en pleine page sur l'écran déplié, elle se resserre aussi :
          // tout tient sans défiler.
          ajuster: serre,
          // Dans un volet, le montant monte à côté du titre et l'en-tête
          // tient sur une ligne : la page n'est plus qu'un bloc serré.
          tete: EnTetePage(surtitre: cat.nom, titre: o.titre, montant: Montant(o.montantCentimes, taille: 24, signe: true)),
          children: [
            if (serre)
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
                      child: Text(o.especes ? '${jour(o.le)} ${o.le.year} · Espèces' : '${jour(o.le)} ${o.le.year} · Compte courant\n${o.libelle.toUpperCase()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.texteDiscret, fontFeatures: chiffres)),
                    ),
                    if (!dansUnVolet(context)) ...[
                      const SizedBox(width: 12),
                      Montant(o.montantCentimes, taille: 28, signe: true),
                    ],
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
                  Text(o.especes ? '${jour(o.le)} ${o.le.year} · Espèces' : '${o.libelle.toUpperCase()}\n${jour(o.le)} ${o.le.year} · Compte courant',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.texteDiscret, fontFeatures: chiffres)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // En pleine page sur l'écran déplié, deux colonnes : le
              // classement et le bouton Pointer à gauche, le suivi à droite,
              // qui garde sa hauteur pour les remboursements dépliés, et
              // rien ne défile.
              child: deuxColonnes
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...gauche, ...pointer])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: droite)),
                      ],
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...gauche, const SizedBox(height: 14), ...droite, ...pointer]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.libelle, required this.valeur, required this.onTap, this.couleur, this.deplie});

  final String icone;
  final String libelle;
  final String valeur;
  final VoidCallback onTap;
  final Color? couleur;

  /// Rien : la ligne mène ailleurs. Sinon, elle déplie un détail sous elle.
  final bool? deplie;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: dansUnVolet(context) ? 44 : 56,
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
              deplie == null
                  ? Icon(iconeDe('chevron_right'), size: 18, color: AppColors.texteDiscret)
                  : AnimatedRotation(
                      turns: deplie! ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(iconeDe('expand_more'), size: 20, color: AppColors.texteDiscret),
                    ),
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
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        // Plus basse dans un volet : la fiche tient d'un coup sur le Fold.
        height: dansUnVolet(context) ? 44 : 56,
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

/// Sur la fiche d'une dépense : l'argent reçu qui la rembourse. Un toucher
/// déplie le détail, une ligne par entrée liée ; sans lien, il mène droit
/// à l'écran d'association.
class _BlocRemboursements extends StatefulWidget {
  const _BlocRemboursements({required this.depense, required this.liens});

  final Operation depense;
  final List<Lien> liens;

  @override
  State<_BlocRemboursements> createState() => _EtatBlocRemboursements();
}

class _EtatBlocRemboursements extends State<_BlocRemboursements> {
  bool _deplie = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.depense;
    final liens = widget.liens;
    final recu = liens.fold(0, (s, l) => s + l.montantCentimes);
    final net = -o.montantCentimes - recu;
    void associer() => context.push('/operation/${o.id}/rembourse');
    return Carte(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Ligne(
            icone: 'link',
            libelle: 'Remboursement',
            valeur: recu == 0 ? 'Aucun' : '${euros(recu)} reçus (${liens.length})',
            couleur: recu == 0 ? null : AppColors.vert,
            deplie: recu == 0 ? null : _deplie,
            onTap: recu == 0 ? associer : () => setState(() => _deplie = !_deplie),
          ),
          if (recu > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(net > 0 ? 'Elle ne compte plus que pour ${euros(net)}.' : 'Elle est entièrement remboursée.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
            ),
          if (recu > 0 && _deplie) ...[
            for (final l in liens) _LigneRemboursement(lien: l),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: OutlinedButton.icon(
                onPressed: associer,
                icon: Icon(iconeDe('link'), color: const Color(0xFF7FE0A8)),
                label: const Text('Modifier les remboursements', style: TextStyle(color: Color(0xFF7FE0A8), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: Color(0x557FE0A8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une entrée qui rembourse la dépense : qui, quand, et la part qui lui
/// revient. Un toucher ouvre l'entrée.
class _LigneRemboursement extends ConsumerWidget {
  const _LigneRemboursement({required this.lien});

  final Lien lien;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(operationProvider(lien.entreeId)).value;
    return InkWell(
      onTap: () => context.push('/operation/${lien.entreeId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e?.titre ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  if (e != null)
                    Text(
                      '${jourCourt(e.le)}${lien.montantCentimes < e.montantCentimes ? ' · ${euros(lien.montantCentimes)} sur ${euros(e.montantCentimes)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Montant(lien.montantCentimes, taille: 14.5, signe: true, couleur: AppColors.vert),
            const SizedBox(width: 4),
            Icon(iconeDe('chevron_right'), size: 18, color: AppColors.texteDiscret),
          ],
        ),
      ),
    );
  }
}

/// Un message à la place d'une page qui n'a pas pu se charger, avec de
/// quoi réessayer : jamais un chargement qui tourne sans fin.
class _Echec extends StatelessWidget {
  const _Echec({required this.message, this.reessayer});

  final String message;
  final VoidCallback? reessayer;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.texteSecondaire, height: 1.5)),
              if (reessayer != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: reessayer, child: const Text('Réessayer')),
              ],
            ],
          ),
        ),
      );
}

String _messageErreur(Object e) => e is ArgumentError ? '${e.message}' : 'Échec : $e';

/// Répartir une entrée sur les dépenses qu'elle rembourse : l'achat peut
/// précéder le remboursement ou le suivre.
class EcranLier extends ConsumerStatefulWidget {
  const EcranLier({super.key, required this.id});

  final int id;

  @override
  ConsumerState<EcranLier> createState() => _EtatLier();
}

class _EtatLier extends ConsumerState<EcranLier> {
  final _parts = <int, TextEditingController>{};
  Operation? _entree;
  List<(Operation, int)>? _depenses;
  String? _erreur;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    for (final c in _parts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _charger() async {
    if (_erreur != null) setState(() => _erreur = null);
    try {
      final entree = await const DepotOperations().une(widget.id);
      if (entree == null || !entree.entree) {
        if (mounted) setState(() => _erreur = 'Cette entrée d\'argent n\'existe plus.');
        return;
      }
      final depenses = await const DepotOperations().depensesRemboursables(entree);
      final liens = await const DepotLiens().concernant([entree.id]);
      if (!mounted) return;
      setState(() {
        _entree = entree;
        _depenses = depenses;
        for (final c in _parts.values) {
          c.dispose();
        }
        _parts.clear();
        for (final l in liens.where((l) => l.entreeId == entree.id)) {
          _parts[l.depenseId] = TextEditingController(text: euros(l.montantCentimes).replaceAll(RegExp(r'\s*€'), ''));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = 'Lecture impossible. ${_messageErreur(e)}');
    }
  }

  int get _reparti => _parts.values.fold(0, (s, c) => s + (lireEuros(c.text) ?? 0));

  /// Ce qu'une dépense peut encore recevoir de cette entrée.
  int _libre(Operation d, int ailleurs) => -d.montantCentimes - ailleurs;

  /// Une part cochée qui ne peut pas s'enregistrer : illisible, nulle, ou
  /// plus grande que ce qui reste de la dépense. Enregistrer l'aurait
  /// retirée sans rien dire.
  bool _partFausse(Operation d, int ailleurs) {
    final c = _parts[d.id];
    if (c == null) return false;
    final v = lireEuros(c.text);
    return v == null || v <= 0 || v > _libre(d, ailleurs);
  }

  Future<void> _enregistrer(Operation entree) async {
    if (_enCours) return;
    setState(() => _enCours = true);
    final parts = {for (final e in _parts.entries) e.key: lireEuros(e.value.text) ?? 0}..removeWhere((_, v) => v <= 0);
    try {
      await const DepotLiens().repartir(entree.id, parts);
      rafraichir(ref);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageErreur(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entree = _entree;
    final depenses = _depenses;
    final reparti = _reparti;
    final trop = entree != null && reparti > entree.montantCentimes;
    final faussess = depenses == null ? 0 : depenses.where((e) => _partFausse(e.$1, e.$2)).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BarreRetour(titre: 'Lier des dépenses'),
            Expanded(
              child: _erreur != null
                  ? _Echec(message: _erreur!, reessayer: _charger)
                  : entree == null || depenses == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          children: [
                            Carte(
                              couleur: const Color(0xFF16231C),
                              child: Row(
                                children: [
                                  const Tuile(icone: 'payments', couleur: Color(0xFF7FE0A8), taille: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entree.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text(jourCourt(entree.le), style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                                      ],
                                    ),
                                  ),
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
                            Jauge(
                              part: entree.montantCentimes == 0 ? 0 : reparti / entree.montantCentimes,
                              couleur: trop ? AppColors.alerte : AppColors.vert,
                            ),
                            const SizedBox(height: 18),
                            const Surtitre('Dépenses, deux mois avant à un mois après'),
                            const SizedBox(height: 8),
                            if (depenses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Aucune dépense autour de cette date.',
                                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.texteSecondaire)),
                              ),
                            for (final (d, ailleurs) in depenses)
                              Builder(builder: (context) {
                                final coche = _parts.containsKey(d.id);
                                // Déjà entièrement remboursée par d'autres entrées : rien à lier.
                                final pleine = !coche && _libre(d, ailleurs) <= 0;
                                void basculer(bool? v) => setState(() {
                                      if (v == true) {
                                        final reste = entree.montantCentimes - _reparti;
                                        final libre = _libre(d, ailleurs);
                                        final part = reste.clamp(0, libre < 0 ? 0 : libre);
                                        _parts[d.id] = TextEditingController(text: euros(part).replaceAll(RegExp(r'\s*€'), ''));
                                      } else {
                                        _parts.remove(d.id)?.dispose();
                                      }
                                    });
                                return InkWell(
                                onTap: pleine ? null : () => basculer(!coche),
                                child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: coche,
                                      onChanged: pleine ? null : basculer,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(d.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          Text(
                                            '${jourCourt(d.le)} · ${euros(d.montantCentimes)}'
                                            '${pleine ? ' · déjà entièrement remboursée' : ailleurs > 0 ? ' · ${euros(ailleurs)} déjà remboursés' : ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret),
                                          ),
                                          if (_partFausse(d, ailleurs))
                                            Text('Part à corriger : au plus ${euros(_libre(d, ailleurs))}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.alerte)),
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
                                          decoration: InputDecoration(
                                            suffixText: '€',
                                            isDense: true,
                                            errorText: _partFausse(d, ailleurs) ? '' : null,
                                            errorStyle: const TextStyle(height: 0, fontSize: 0),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                                );
                              }),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: FilledButton(
                onPressed: entree == null || trop || faussess > 0 || _enCours ? null : () => _enregistrer(entree),
                child: Text(trop
                    ? 'Plus que le montant reçu'
                    : faussess > 0
                        ? 'Une part à corriger'
                        : _parts.isEmpty
                            ? 'Enregistrer'
                            : 'Lier ${pluriel(_parts.length, 'dépense')}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Depuis une dépense : cocher les entrées d'argent qui la remboursent,
/// autant qu'il en faut. Six amis qui rendent chacun 23 € d'une sortie à
/// 192 € : six cases, et la dépense ne compte plus que pour 54 €.
class EcranChoisirRemboursement extends ConsumerStatefulWidget {
  const EcranChoisirRemboursement({super.key, required this.id});

  final int id;

  @override
  ConsumerState<EcranChoisirRemboursement> createState() => _EtatChoisirRemboursement();
}

class _EtatChoisirRemboursement extends ConsumerState<EcranChoisirRemboursement> {
  Operation? _depense;

  /// Chaque entrée possible, avec ce qu'il en reste une fois ôtées ses
  /// parts sur d'autres dépenses.
  List<(Operation, int)> _entrees = const [];

  /// La part de chaque entrée cochée, telle que tapée.
  final _parts = <int, TextEditingController>{};

  /// Les liens lus en ouvrant l'écran : sans changement, rien ne s'écrit.
  Map<int, int> _initial = const {};
  bool _pret = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    for (final c in _parts.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _texte(int centimes) => euros(centimes).replaceAll(RegExp(r'\s*€'), '');

  Future<void> _charger() async {
    if (_erreur != null) setState(() => _erreur = null);
    try {
      final d = await const DepotOperations().une(widget.id);
      if (d == null || d.entree) {
        if (mounted) setState(() => _erreur = 'Cette dépense n\'existe plus.');
        return;
      }
      final entrees = await const DepotOperations().remboursementsPossibles(d);
      final liens = (await const DepotLiens().concernant([d.id])).where((l) => l.depenseId == d.id);
      if (!mounted) return;
      setState(() {
        _depense = d;
        _entrees = entrees;
        for (final c in _parts.values) {
          c.dispose();
        }
        _parts.clear();
        _initial = {for (final l in liens) l.entreeId: l.montantCentimes};
        for (final e in _initial.entries) {
          _parts[e.key] = TextEditingController(text: _texte(e.value));
        }
        _pret = true;
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = 'Lecture impossible. ${_messageErreur(e)}');
    }
  }

  int get _total => _parts.values.fold(0, (s, c) => s + (lireEuros(c.text) ?? 0));

  /// Une part cochée qui ne peut pas s'enregistrer : illisible, nulle, ou
  /// plus grande que ce qui reste de l'entrée.
  bool _partFausse(int entreeId, int reste) {
    final c = _parts[entreeId];
    if (c == null) return false;
    final v = lireEuros(c.text);
    return v == null || v <= 0 || v > reste;
  }

  /// Cocher prend de l'entrée ce qui manque encore à la dépense, sans
  /// dépasser ce qui reste de l'entrée. Déjà couverte : l'entrée entière,
  /// et l'écran prévient du dépassement plutôt que de cocher à zéro.
  void _basculer(Operation e, int reste) => setState(() {
        final c = _parts.remove(e.id);
        if (c != null) {
          c.dispose();
          return;
        }
        final manque = -_depense!.montantCentimes - _total;
        _parts[e.id] = TextEditingController(text: _texte(manque > 0 ? (reste < manque ? reste : manque) : reste));
      });

  Future<void> _valider() async {
    if (_enCours) return;
    final parts = {for (final e in _parts.entries) e.key: lireEuros(e.value.text) ?? 0};
    if (parts.length == _initial.length && parts.entries.every((e) => _initial[e.key] == e.value)) {
      context.pop();
      return;
    }
    setState(() => _enCours = true);
    try {
      await const DepotLiens().rembourserPar(widget.id, parts);
      rafraichir(ref);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageErreur(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <int, Categorie>{};
    final depense = _depense;
    final montant = depense == null ? 0 : -depense.montantCentimes;
    final total = _total;
    final trop = total > montant;
    final fausses = _entrees.where((e) => _partFausse(e.$1.id, e.$2)).length;
    final jours = <DateTime, List<(Operation, int)>>{};
    for (final e in _entrees) {
      jours.putIfAbsent(DateTime(e.$1.le.year, e.$1.le.month, e.$1.le.day), () => []).add(e);
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarreRetour(titre: 'Associer à un remboursement'),
            if (depense != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: Text(
                  'Pour « ${depense.titre} », ${euros(montant)}. Coche tout l\'argent reçu qui la rembourse, avant ou après l\'achat.',
                  style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
                ),
              ),
            Expanded(
              child: _erreur != null
                  ? _Echec(message: _erreur!, reessayer: _charger)
                  : !_pret
                      ? const Center(child: CircularProgressIndicator())
                      : _entrees.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('Aucune entrée d\'argent dans les deux mois autour de cette date.',
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
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < e.value.length; i++)
                                          _LigneChoix(
                                            operation: e.value[i].$1,
                                            reste: e.value[i].$2,
                                            categorie: categories[e.value[i].$1.categorieId]?.nom ?? '',
                                            part: _parts[e.value[i].$1.id],
                                            fausse: _partFausse(e.value[i].$1.id, e.value[i].$2),
                                            separateur: i > 0,
                                            onTap: () => _basculer(e.value[i].$1, e.value[i].$2),
                                            onPart: () => setState(() {}),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            ),
            ),
            if (depense != null && _pret)
              _Recapitulatif(nombre: _parts.length, total: total, montant: montant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: FilledButton(
                onPressed: _pret && !_enCours && !trop && fausses == 0 ? _valider : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                  backgroundColor: AppColors.vert,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                child: Text(trop
                    ? 'Plus que la dépense'
                    : fausses > 0
                        ? fausses > 1 ? '$fausses parts à corriger' : 'Une part à corriger'
                        : _parts.isEmpty && _initial.isNotEmpty
                            ? 'Tout délier'
                            : _parts.isEmpty
                                ? 'Aucun remboursement'
                                : 'Valider ${pluriel(_parts.length, 'remboursement')}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En bas de l'écran d'association : combien de cases, pour combien, et
/// ce que la dépense coûte encore.
class _Recapitulatif extends StatelessWidget {
  const _Recapitulatif({required this.nombre, required this.total, required this.montant});

  final int nombre;
  final int total;
  final int montant;

  @override
  Widget build(BuildContext context) {
    final reste = montant - total;
    final trop = reste < 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: trop ? AppColors.alerte.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: trop ? AppColors.alerte.withValues(alpha: 0.4) : AppColors.trait),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre == 0 ? 'Aucun sélectionné' : '${pluriel(nombre, 'sélectionné')} · ${euros(total)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFeatures: chiffres),
                ),
              ),
              Text(
                trop ? '${euros(-reste)} de trop' : reste == 0 ? 'Couverte' : 'Reste ${euros(reste)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFeatures: chiffres,
                  color: trop ? AppColors.alerte : reste == 0 ? AppColors.vert : AppColors.texte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Jauge(part: montant == 0 ? 0 : (total / montant).clamp(0, 1), couleur: trop ? AppColors.alerte : AppColors.vert, hauteur: 6),
          if (trop) ...[
            const SizedBox(height: 8),
            Text('Le total dépasse la dépense de ${euros(montant)} : baisse une part ou décoche un remboursement.',
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.alerte)),
          ],
        ],
      ),
    );
  }
}

class _LigneChoix extends StatelessWidget {
  const _LigneChoix({
    required this.operation,
    required this.reste,
    required this.categorie,
    required this.part,
    required this.fausse,
    required this.separateur,
    required this.onTap,
    required this.onPart,
  });

  final Operation operation;
  final int reste;
  final String categorie;

  /// La part tapée, si la case est cochée.
  final TextEditingController? part;
  final bool fausse;
  final bool separateur;
  final VoidCallback onTap;
  final VoidCallback onPart;

  @override
  Widget build(BuildContext context) {
    final cochee = part != null;
    // Déjà entièrement répartie sur d'autres dépenses : rien à prendre.
    final prise = !cochee && reste <= 0;
    final details = [
      if (prise) 'déjà entièrement affecté ailleurs' else ...[
        // Cochée, le montant laisse sa place à la part : il passe ici.
        if (cochee) euros(operation.montantCentimes, signe: true),
        if (categorie.isNotEmpty) categorie,
        if (operation.enAttente) 'En attente',
        if (reste < operation.montantCentimes) 'reste ${euros(reste)}',
      ],
    ].join(' · ');
    return Opacity(
      opacity: prise ? 0.4 : 1,
      child: InkWell(
        onTap: prise ? null : onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
          constraints: const BoxConstraints(minHeight: 60),
          decoration: separateur ? const BoxDecoration(border: Border(top: BorderSide(color: AppColors.trait))) : null,
          child: Row(
            children: [
              Checkbox(value: cochee, onChanged: prise ? null : (_) => onTap()),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(operation.titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                    ],
                    if (fausse)
                      Text('Au plus ${euros(reste)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.alerte)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (cochee)
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: part,
                    // Toucher la part la sélectionne : on tape la nouvelle
                    // au lieu d'écrire à la suite de l'ancienne.
                    onTap: () => part!.selection = TextSelection(baseOffset: 0, extentOffset: part!.text.length),
                    onChanged: (_) => onPart(),
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: chiffres, color: AppColors.vert),
                    decoration: InputDecoration(
                      suffixText: '€',
                      isDense: true,
                      errorText: fausse ? '' : null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                )
              else
                Montant(operation.montantCentimes, taille: 15.5, signe: true, couleur: prise ? AppColors.texteDiscret : AppColors.vert),
            ],
          ),
        ),
      ),
    );
  }
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

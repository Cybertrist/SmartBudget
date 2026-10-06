import 'package:flutter/material.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/bilan.dart';
import '../domaine/modeles.dart';
import '../domaine/mois.dart';
import '../domaine/recurrences.dart';
import '../widgets/base.dart';
import '../widgets/graphiques.dart';

/// Les widgets de l'écran d'accueil du téléphone. L'application les dessine
/// avec ses propres composants (mêmes tuiles, mêmes couleurs, même police),
/// l'atelier les photographie, et Android affiche la photo.
enum WidgetEcran {
  budget('budget', 'WidgetBudget', Size(170, 170)),
  epargne('epargne', 'WidgetEpargne', Size(170, 170)),
  comptes('comptes', 'WidgetComptes', Size(360, 170)),
  analyse('analyse', 'WidgetAnalyse', Size(254, 254)),
  depenses('depenses', 'WidgetDepenses', Size(360, 0)),
  aVenir('avenir', 'WidgetAVenir', Size(360, 0)),
  especes('especes', 'WidgetEspeces', Size(360, 80));

  const WidgetEcran(this.cle, this.classe, this.taille);

  /// La clé partagée avec le code Android : le chemin de l'image.
  final String cle;

  /// Le nom de la classe Android du widget.
  final String classe;

  /// La taille du dessin ; une hauteur de 0 laisse le contenu décider.
  final Size taille;

  /// Sans aucun chiffre : Android montre toujours la même image, rangée
  /// dans ses ressources. L'atelier ne le photographie pas.
  bool get fixe => this == especes;
}

/// Ce que les widgets montrent, lu une fois dans la base.
class Instantane {
  const Instantane({
    required this.mois,
    required this.bilan,
    required this.categories,
    required this.comptes,
    required this.budget,
    required this.objectif,
    required this.attendues,
    required this.jour,
  });

  final Mois mois;
  final Bilan bilan;
  final Map<int, Categorie> categories;
  final List<Compte> comptes;
  final int budget;
  final int objectif;

  /// Les récurrences en retard puis à venir, chacune avec le jour où elle
  /// est attendue.
  final List<(Recurrence, DateTime)> attendues;

  /// Le jour de la photo.
  final DateTime jour;

  Compte? get courant => comptes.where((c) => c.nature == NatureCompte.courant).firstOrNull;
  List<Compte> get livrets => comptes.where((c) => c.nature == NatureCompte.livret).toList();
  Compte? get portefeuille => comptes.where((c) => c.nature == NatureCompte.portefeuille).firstOrNull;
  int get epargne => livrets.fold<int>(0, (s, c) => s + c.soldeCentimes);

  /// Les catégories de dépenses du mois, de la plus lourde à la plus légère.
  List<MapEntry<int, int>> get top => bilan.parCategorie.entries
      .where((e) => categories[e.key]?.genre == Genre.depense && e.value > 0)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  /// Ce dont dépendent les images : inutile de les refaire si rien n'a
  /// bougé.
  String get empreinte => [
        '${jour.year}-${jour.month}-${jour.day}',
        mois.cle,
        bilan.sorties,
        for (final e in top) '${e.key}:${e.value}:${categories[e.key]!.nom}:${categories[e.key]!.icone}:${categories[e.key]!.couleur}',
        for (final c in comptes) '${c.id}:${c.nom}:${c.soldeCentimes}:${c.soldeLe}',
        budget,
        objectif,
        for (final (r, d) in attendues.take(3)) '${r.libelle}:${r.montantCentimes}:$d',
      ].join('|');
}

/// Les passages attendus d'ici un mois, les retards d'abord. Les mêmes
/// règles que l'onglet Récurrences : en retard une fois quatre jours passés,
/// et plus rien après l'arrêt d'une récurrence.
List<(Recurrence, DateTime)> passagesAttendus(List<Recurrence> recurrences, DateTime maintenant) {
  final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
  final horizon = DateTime(aujourdhui.year, aujourdhui.month + 1, aujourdhui.day);
  // Un passage manqué depuis plus d'un mois n'est plus attendu : la
  // récurrence s'est arrêtée toute seule.
  final depuis = DateTime(aujourdhui.year, aujourdhui.month - 1, aujourdhui.day);
  final liste = <(Recurrence, DateTime)>[];
  for (final r in recurrences) {
    var n = 0;
    for (var d = r.prochaine; d.isBefore(horizon) && n < 6; d = suivante(d, r.frequence)) {
      if (d.isBefore(depuis) || !r.attendueLe(d)) continue;
      liste.add((r, d));
      n++;
    }
  }
  return liste..sort((a, b) => a.$2.compareTo(b.$2));
}

const _rayon = 28.0;

/// Le cadre commun : le noir de l'application, de grands coins.
class _Cadre extends StatelessWidget {
  const _Cadre({required this.taille, required this.child});

  final Size taille;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: taille.width,
        height: taille.height == 0 ? null : taille.height,
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(_rayon),
          border: Border.all(color: AppColors.trait),
        ),
        child: child,
      );
}

const _petit = TextStyle(fontSize: 12, color: AppColors.texteSecondaire);

/// Le dessin d'un widget.
Widget vueEcran(WidgetEcran w, Instantane d) => switch (w) {
      WidgetEcran.budget => _Budget(d, w.taille),
      WidgetEcran.epargne => _Epargne(d, w.taille),
      WidgetEcran.comptes => _Comptes(d, w.taille),
      WidgetEcran.analyse => _Analyse(d, w.taille),
      WidgetEcran.depenses => _Depenses(d, w.taille),
      WidgetEcran.aVenir => _AVenir(d, w.taille),
      WidgetEcran.especes => _Especes(w.taille),
    };

/// Ce qu'il reste du budget du mois ; sans budget, ce qui a été dépensé.
class _Budget extends StatelessWidget {
  const _Budget(this.d, this.taille);

  final Instantane d;
  final Size taille;

  @override
  Widget build(BuildContext context) {
    final depense = d.bilan.sorties;
    if (d.budget <= 0) {
      return _Cadre(
        taille: taille,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Surtitre('Dépensé'),
            const SizedBox(height: 14),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Montant(depense, taille: 28)),
            const SizedBox(height: 4),
            Text('en ${nomMoisSeul(d.mois).toLowerCase()}', style: _petit),
            const Spacer(),
            BarreSegmentee(parts: [for (final e in d.top) (e.value, Color(d.categories[e.key]!.couleur))]),
          ],
        ),
      );
    }
    final reste = d.budget - depense;
    final part = depense / d.budget;
    final couleur = part >= 1 ? AppColors.alerte : (part >= 0.9 ? AppColors.attention : AppColors.vert);
    return _Cadre(
      taille: taille,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Surtitre('Budget'),
          const SizedBox(height: 14),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Montant(reste.abs(), taille: 28, couleur: couleur)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(reste >= 0 ? 'restants sur ${euros(d.budget, centimesSiRond: false)}' : 'de dépassement', maxLines: 1, style: _petit),
          ),
          const Spacer(),
          Text(nomMoisSeul(d.mois), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.texteDiscret)),
          const SizedBox(height: 8),
          Jauge(part: part, couleur: couleur),
        ],
      ),
    );
  }
}

/// Le cadran de l'épargne, comme sur l'accueil de l'application.
class _Epargne extends StatelessWidget {
  const _Epargne(this.d, this.taille);

  final Instantane d;
  final Size taille;

  @override
  Widget build(BuildContext context) {
    final epargne = d.epargne;
    final net = d.bilan.epargneNette;
    return _Cadre(
      taille: taille,
      child: Column(
        children: [
          const Surtitre('Épargne'),
          const Spacer(),
          Cadran(part: d.objectif > 0 ? epargne / d.objectif : 0),
          FittedBox(fit: BoxFit.scaleDown, child: Montant(epargne, taille: 21)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              d.objectif > 0
                  ? '${(epargne * 100 / d.objectif).round()} % de ${euros(d.objectif, centimesSiRond: false)}'
                  : net == 0
                      ? 'sur tes livrets'
                      : '${euros(net, signe: true, centimesSiRond: false)} ce mois-ci',
              maxLines: 1,
              // Le rouge dit « attention » : un mois où l'épargne a baissé.
              style: _petit.copyWith(color: d.objectif <= 0 && net < 0 ? AppColors.alerte : null),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le total des comptes, puis chacun : le courant, l'épargne, les espèces.
class _Comptes extends StatelessWidget {
  const _Comptes(this.d, this.taille);

  final Instantane d;
  final Size taille;

  @override
  Widget build(BuildContext context) {
    final courant = d.courant;
    final portefeuille = d.portefeuille;
    final total = (courant?.soldeCentimes ?? 0) + d.epargne + (portefeuille?.soldeCentimes ?? 0);
    final parts = [
      if (courant != null) ('Compte courant', courant.soldeCentimes, AppColors.vert),
      if (d.livrets.isNotEmpty) ('Épargne', d.epargne, AppColors.epargne),
      if (portefeuille != null) ('Espèces', portefeuille.soldeCentimes, AppColors.attention),
    ];
    return _Cadre(
      taille: taille,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Surtitre(
            'Sur tes comptes',
            droite: courant?.soldeLe == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconeDe('sync'), size: 13, color: AppColors.texteDiscret),
                      const SizedBox(width: 4),
                      Text(jourCourt(courant!.soldeLe!), style: const TextStyle(fontSize: 12, color: AppColors.texteDiscret)),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Montant(total, taille: 38)),
          const Spacer(),
          Row(
            children: [
              for (final (nom, solde, couleur) in parts)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Flexible(child: Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: _petit)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Montant(solde, taille: 15, couleur: solde < 0 ? AppColors.alerte : null),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une ligne à tuile : une catégorie, une récurrence.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.couleur, required this.nom, required this.montant, this.detail, this.couleurDetail});

  final String? icone;
  final Color couleur;
  final String nom;
  final int montant;
  final String? detail;
  final Color? couleurDetail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Tuile(icone: icone, couleur: couleur, taille: 30),
            const SizedBox(width: 12),
            Expanded(child: Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
            if (detail != null) ...[
              const SizedBox(width: 8),
              Text(detail!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: couleurDetail ?? AppColors.texteDiscret)),
            ],
            const SizedBox(width: 12),
            Montant(montant, taille: 14.5),
          ],
        ),
      );
}

/// L'anneau de l'analyse : les sorties du mois, une part et une icône par
/// catégorie.
class _Analyse extends StatelessWidget {
  const _Analyse(this.d, this.taille);

  final Instantane d;
  final Size taille;

  @override
  Widget build(BuildContext context) => Container(
        width: taille.width,
        height: taille.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(_rayon),
          border: Border.all(color: AppColors.trait),
        ),
        child: Anneau(
          // Juste la place des icônes autour de l'anneau : le widget tient
          // dans un carré de deux cases, où tout est rétréci.
          taille: taille.width - 14,
          parts: [for (final e in d.top) PartAnneau(e.value, Color(d.categories[e.key]!.couleur), d.categories[e.key]!.icone)],
          centre: SizedBox(
            width: 106,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Montant(d.bilan.sorties, taille: 25)),
                const SizedBox(height: 3),
                Text(nomMoisSeul(d.mois), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.vert)),
              ],
            ),
          ),
        ),
      );
}

/// Les dépenses du mois : la barre des catégories et les trois premières.
class _Depenses extends StatelessWidget {
  const _Depenses(this.d, this.taille);

  final Instantane d;
  final Size taille;

  @override
  Widget build(BuildContext context) {
    final top = d.top;
    return _Cadre(
      taille: taille,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Surtitre('Dépenses · ${nomMoisSeul(d.mois)}', droite: Montant(d.bilan.sorties)),
          const SizedBox(height: 12),
          BarreSegmentee(parts: [for (final e in top) (e.value, Color(d.categories[e.key]!.couleur))]),
          const SizedBox(height: 4),
          if (top.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 12, bottom: 4), child: Text('Aucune dépense ce mois-ci.', style: TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire))),
          for (final e in top.take(3))
            _Ligne(icone: d.categories[e.key]!.icone, couleur: Color(d.categories[e.key]!.couleur), nom: d.categories[e.key]!.nom, montant: e.value),
        ],
      ),
    );
  }
}

/// Ce qui va sortir tout seul : les trois prochaines récurrences.
class _AVenir extends StatelessWidget {
  const _AVenir(this.d, this.taille);

  final Instantane d;
  final Size taille;

  @override
  Widget build(BuildContext context) {
    final aujourdhui = DateTime(d.jour.year, d.jour.month, d.jour.day);
    final total = d.attendues.fold<int>(0, (s, e) => s + e.$1.montantCentimes);
    return _Cadre(
      taille: taille,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Surtitre('À venir', droite: d.attendues.isEmpty ? null : Montant(total)),
          const SizedBox(height: 4),
          if (d.attendues.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 12, bottom: 4), child: Text("Rien d'attendu d'ici un mois.", style: TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire))),
          for (final (r, le) in d.attendues.take(3))
            _Ligne(
              icone: 'autorenew',
              couleur: const Color(0xFFFF8FD1),
              nom: r.libelle,
              montant: r.montantCentimes,
              // Une date, pas « dans 3 j » : l'image peut rester quelques
              // jours sans être refaite.
              detail: le.add(const Duration(days: 4)).isBefore(aujourdhui) ? 'en retard' : jourCourt(le),
              couleurDetail: le.add(const Duration(days: 4)).isBefore(aujourdhui) ? AppColors.alerte : null,
            ),
        ],
      ),
    );
  }
}

/// Noter une dépense en espèces, d'un appui.
class _Especes extends StatelessWidget {
  const _Especes(this.taille);

  final Size taille;

  @override
  Widget build(BuildContext context) => _Cadre(
        taille: taille,
        child: Row(
          children: [
            const Tuile(icone: 'account_balance_wallet', couleur: AppColors.attention, taille: 46),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dépense en espèces', maxLines: 1, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('À noter tout de suite', maxLines: 1, style: TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.vert, shape: BoxShape.circle),
              child: Icon(iconeDe('add'), size: 24, color: Colors.black, weight: 700),
            ),
          ],
        ),
      );
}

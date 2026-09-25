import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../ecrans/categorie.dart';
import '../widgets/base.dart';
import 'connexion.dart';
import 'enable_banking.dart';
import 'logos_banques.dart';

/// Le nom des pays d'Enable Banking, pour les lire et les chercher.
const _pays = <String, String>{
  'AT': 'Autriche',
  'BE': 'Belgique',
  'BG': 'Bulgarie',
  'CY': 'Chypre',
  'CZ': 'Tchéquie',
  'DE': 'Allemagne',
  'DK': 'Danemark',
  'EE': 'Estonie',
  'ES': 'Espagne',
  'FI': 'Finlande',
  'FR': 'France',
  'GB': 'Royaume-Uni',
  'GR': 'Grèce',
  'HR': 'Croatie',
  'HU': 'Hongrie',
  'IE': 'Irlande',
  'IS': 'Islande',
  'IT': 'Italie',
  'LI': 'Liechtenstein',
  'LT': 'Lituanie',
  'LU': 'Luxembourg',
  'LV': 'Lettonie',
  'MT': 'Malte',
  'NL': 'Pays-Bas',
  'NO': 'Norvège',
  'PL': 'Pologne',
  'PT': 'Portugal',
  'RO': 'Roumanie',
  'SE': 'Suède',
  'SI': 'Slovénie',
  'SK': 'Slovaquie',
};

String _nomPays(String code) => _pays[code] ?? code;

/// Le drapeau d'un pays, tiré de ses deux lettres.
String _drapeau(String code) =>
    code.length == 2 ? String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65)) : '🏳️';

/// Sans accents ni majuscules : « societe » trouve « Société Générale ».
/// Les mêmes lettres que retire tool/logos_banques.mjs, pour que les noms
/// exacts de logos_banques.dart se retrouvent.
String _simple(String s) {
  const avec = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿāăąćĉċčďēĕėęěĝğġģĥĩīĭįĵķĺļľńņňōŏőŕŗřśŝşšţťũūŭůűųŵŷźżž’';
  const sans = "aaaaaaceeeeiiiinooooouuuuyyaaaccccdeeeeegggghiiiijklllnnnooorrrssssttuuuuuuwyzzz'";
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = avec.indexOf(c);
    b.write(i < 0 ? c : sans[i]);
  }
  return b.toString();
}

/// Les motifs des grandes banques, compilés une fois.
final _motifs = [for (final (motif, fichier) in logosBanques) (RegExp(motif), fichier)];

/// La grande banque que ce nom désigne, par son rang dans les motifs.
int? _marque(String nom) {
  final n = _simple(nom);
  for (final (i, (motif, _)) in _motifs.indexed) {
    if (motif.hasMatch(n)) return i;
  }
  return null;
}

/// L'icône rangée dans l'application pour ce nom, s'il y en a une.
String? _icone(String nom) => logosExacts[_simple(nom)] ?? switch (_marque(nom)) {
      final int i => _motifs[i].$2,
      null => null,
    };

/// Une ligne par banque et par pays, de A à Z ; et, à part, celles du
/// pays du téléphone qui ont une icône, pour les mettre en tête.
(List<_Groupe>, List<_Groupe>) _grouper(List<Banque> banques, String pays) {
  final toutes = [for (final b in banques) _Groupe(b)]
    ..sort((a, b) {
      final n = _simple(a.nom).compareTo(_simple(b.nom));
      return n != 0 ? n : _nomPays(a.banque.pays).compareTo(_nomPays(b.banque.pays));
    });
  final grandes = [for (final g in toutes) if (g.banque.pays == pays && g.icone != null) g];
  return (toutes, grandes);
}

/// La liste déjà rangée : rouvrir la page ne la redemande pas.
(List<_Groupe>, List<_Groupe>)? _memoire;

/// Une ligne de la liste : une banque, dans un pays.
class _Groupe {
  _Groupe(this.banque)
      : nom = banque.nom,
        cle = _simple('${banque.nom} ${_nomPays(banque.pays)}'),
        icone = _icone(banque.nom),
        sousTitre = '${_drapeau(banque.pays)}  ${_nomPays(banque.pays)}';

  final Banque banque;
  final String nom;

  /// Ce que la recherche lit : le nom et le pays.
  final String cle;

  /// L'icône de la banque, si elle a une application.
  final String? icone;

  /// Sous le nom : le pays.
  final String sousTitre;

  String get lettre {
    final s = _simple(nom);
    final c = s.isEmpty ? '' : s[0].toUpperCase();
    return RegExp('[A-Z]').hasMatch(c) ? c : '#';
  }
}

/// Ouvre la page du choix et rend la banque choisie.
Future<Banque?> choisirBanque(BuildContext context, {String? actuelle}) =>
    context.push<Banque>('/banques', extra: actuelle);

/// Choisir sa banque parmi toutes celles d'Enable Banking. Les grandes
/// d'abord, avec leur icône, puis toutes, de A à Z, et une recherche par
/// nom ou par pays.
class EcranBanques extends StatefulWidget {
  const EcranBanques({super.key, this.actuelle});

  final String? actuelle;

  @override
  State<EcranBanques> createState() => _EcranBanquesState();
}

class _EcranBanquesState extends State<EcranBanques> {
  final _recherche = TextEditingController();
  final _defilement = ScrollController();
  late Future<(List<_Groupe>, List<_Groupe>)> _groupes = _charger();

  /// Le pays du téléphone : ses grandes banques passent en tête. La
  /// France, s'il n'est pas de ceux d'Enable Banking.
  final String _monPays = switch (WidgetsBinding.instance.platformDispatcher.locale.countryCode) {
    final String p when _pays.containsKey(p) => p,
    _ => 'FR',
  };

  Future<(List<_Groupe>, List<_Groupe>)> _charger() async {
    if (_memoire case final m?) return m;
    final banques = await const ConnexionBanque().banques();
    final pays = _monPays;
    final rangees = await Isolate.run(() => _grouper(banques, pays));
    return _memoire = rangees;
  }

  @override
  void dispose() {
    _recherche.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _chercher(String _) {
    setState(() {});
    if (_defilement.hasClients) _defilement.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<(List<_Groupe>, List<_Groupe>)>(
          future: _groupes,
          builder: (context, s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BarreRetour(titre: 'Ta banque'),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    key: ValueKey(s.data?.$1.length),
                    s.data == null
                        ? 'Celle que tu as reliée sur le portail d\'Enable Banking.'
                        : '${s.data!.$1.length} banques dans toute l\'Europe. Choisis celle reliée sur le portail d\'Enable Banking.',
                    style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.texteSecondaire),
                  ),
                ),
              ),
              _Recherche(controleur: _recherche, onChanged: _chercher),
              Expanded(child: _corps(s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corps(AsyncSnapshot<(List<_Groupe>, List<_Groupe>)> s) {
    if (s.hasError) {
      final e = s.error;
      return _Vide(
        icone: 'cloud_off',
        texte: e is ErreurBanque ? e.message : 'Impossible de charger la liste des banques.',
        action: ('Réessayer', () => setState(() => _groupes = _charger())),
      );
    }
    if (!s.hasData) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: AppColors.vert, strokeWidth: 3)),
          SizedBox(height: 16),
          Text('Chargement des banques…', style: TextStyle(color: AppColors.texteSecondaire)),
          SizedBox(height: 60),
        ],
      );
    }
    final q = _simple(_recherche.text.trim());
    final (tous, grandes) = s.data!;
    final groupes = [for (final g in tous) if (q.isEmpty || g.cle.contains(q)) g];
    if (groupes.isEmpty) {
      return _Vide(icone: 'search_off', texte: 'Aucune banque ne répond à « ${_recherche.text.trim()} ».');
    }

    // Chaque ligne porte sa partie : une banque peut paraître deux fois,
    // en haut et à sa place de A à Z.
    final lignes = <Object>[];
    // Sans recherche, les banques du pays qui ont une icône d'abord :
    // celles qu'on a le plus de chances de chercher.
    if (q.isEmpty && grandes.isNotEmpty) {
      lignes.add(_Section('Les grandes banques · ${_nomPays(_monPays)}', grandes.length));
      lignes.addAll([for (final g in grandes) ('g', g)]);
      lignes.add(_Section('Toutes les banques, de A à Z', groupes.length));
    }
    String? lettre;
    for (final g in groupes) {
      if (g.lettre != lettre) lignes.add(lettre = g.lettre);
      lignes.add(('t', g));
    }

    return ListView.builder(
      controller: _defilement,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: lignes.length,
      itemBuilder: (context, i) => switch (lignes[i]) {
        final _Section x => _TitreSection(x),
        final String l => _Lettre(l),
        (final String partie, final _Groupe g) => _Ligne(
            key: ValueKey('$partie${g.nom}${g.banque.pays}'),
            groupe: g,
            choisie: g.nom == widget.actuelle,
            onTap: () => context.pop(g.banque),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Section {
  const _Section(this.titre, this.nombre);

  final String titre;
  final int nombre;
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.section);

  final _Section section;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
        child: Surtitre(
          section.titre,
          droite: Text('${section.nombre}', style: const TextStyle(fontSize: 12.5, color: AppColors.texteDiscret)),
        ),
      );
}

class _Recherche extends StatelessWidget {
  const _Recherche({required this.controleur, required this.onChanged});

  final TextEditingController controleur;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const bord = OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30)), borderSide: BorderSide.none);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: ValueListenableBuilder(
        valueListenable: controleur,
        builder: (context, valeur, _) => TextField(
          controller: controleur,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Nom de la banque, ou pays',
            filled: true,
            fillColor: AppColors.surfaceHaute,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 10),
              child: Icon(iconeDe('search'), color: AppColors.vert),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: valeur.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controleur.clear();
                      onChanged('');
                    },
                    icon: Icon(iconeDe('cancel'), color: AppColors.texteSecondaire, size: 20, fill: 1),
                  ),
            border: bord,
            enabledBorder: bord,
            focusedBorder: bord.copyWith(borderSide: BorderSide(color: AppColors.vert.withValues(alpha: 0.6), width: 1.5)),
          ),
        ),
      ),
    );
  }
}

class _Lettre extends StatelessWidget {
  const _Lettre(this.lettre);

  final String lettre;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
        child: Text(lettre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.vert)),
      );
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    super.key,
    required this.groupe,
    required this.choisie,
    required this.onTap,
  });

  final _Groupe groupe;
  final bool choisie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: choisie ? AppColors.vert.withValues(alpha: 0.07) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: choisie ? AppColors.vert.withValues(alpha: 0.5) : Colors.transparent),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              children: [
                _IconeBanque(nom: groupe.nom, icone: groupe.icone),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(groupe.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(groupe.sousTitre, style: const TextStyle(fontSize: 12.5, color: AppColors.texteSecondaire)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (choisie)
                  Icon(iconeDe('check_circle'), color: AppColors.vert, fill: 1)
                else
                  Icon(iconeDe('chevron_right'), color: AppColors.texteDiscret),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L'icône d'une grande banque, ou ses initiales dans une tuile de verre
/// teintée, comme les catégories.
class _IconeBanque extends StatelessWidget {
  const _IconeBanque({required this.nom, this.icone});

  final String nom;
  final String? icone;

  static const _taille = 46.0;

  /// Des teintes vives, tirées du nom : la même banque garde toujours la
  /// même couleur.
  static const _teintes = [
    Color(0xFF1ED760),
    Color(0xFF3CE0FF),
    Color(0xFFFFC857),
    Color(0xFFFF6B7A),
    Color(0xFFB18CFF),
    Color(0xFFFF9F5A),
    Color(0xFF5AA9FF),
    Color(0xFFFF7AD9),
  ];

  String get _initiales {
    final mots = nom.replaceAll(RegExp(r"[^A-Za-zÀ-ÿ0-9 ]"), ' ').split(' ').where((m) => m.isNotEmpty && m.length > 2 || RegExp(r'^[A-Z0-9]+$').hasMatch(m)).toList();
    if (mots.isEmpty) return nom.isEmpty ? '?' : nom[0].toUpperCase();
    if (mots.length == 1) return mots.first.substring(0, mots.first.length.clamp(1, 2)).toUpperCase();
    return (mots[0][0] + mots[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(_taille * 0.3);
    if (icone != null) {
      return Container(
        width: _taille,
        height: _taille,
        // Blanc dessous, comme le lanceur d'Android pour une icône
        // transparente.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: r,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(borderRadius: r, child: Image.asset(icone!, fit: BoxFit.cover, filterQuality: FilterQuality.medium)),
      );
    }
    final couleur = _teintes[nom.codeUnits.fold(0, (a, c) => (a * 31 + c) & 0x7fffffff) % _teintes.length];
    return Container(
      width: _taille,
      height: _taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [couleur.withValues(alpha: 0.2), couleur.withValues(alpha: 0.063)],
        ),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: couleur.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: -8, offset: const Offset(0, 6))],
      ),
      child: Text(_initiales, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: couleur, letterSpacing: 0.3)),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide({required this.icone, required this.texte, this.action});

  final String icone;
  final String texte;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Tuile(icone: icone, couleur: AppColors.texteSecondaire, taille: 56),
          const SizedBox(height: 16),
          Text(texte, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.texteSecondaire, height: 1.45)),
          if (action case (final libelle, final f)) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: f, child: Text(libelle, style: const TextStyle(color: AppColors.vert, fontWeight: FontWeight.w800))),
          ],
        ],
      ),
    );
  }
}

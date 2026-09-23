import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../donnees/depots.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import 'categorie.dart';
import 'dialogues.dart';

/// Les livrets les plus courants, pour ne rien avoir à taper.
const _types = [
  ('Livret A', 'savings'),
  ('LDDS', 'eco'),
  ('LEP', 'volunteer_activism'),
  ('Livret jeune', 'school'),
  ('PEL', 'home'),
  ('CEL', 'cottage'),
  ('Assurance vie', 'shield'),
  ('Autre', 'account_balance'),
];

/// Ajouter un livret : la banque ne partage que le compte courant, alors
/// on donne le solde une fois, et l'application le fait vivre au fil des
/// virements repérés.
class EcranNouveauLivret extends ConsumerStatefulWidget {
  const EcranNouveauLivret({super.key});

  @override
  ConsumerState<EcranNouveauLivret> createState() => _EtatNouveauLivret();
}

class _EtatNouveauLivret extends ConsumerState<EcranNouveauLivret> {
  final _solde = TextEditingController();
  final _nom = TextEditingController(text: _types.first.$1);
  final _motif = TextEditingController();
  int _type = 0;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _nom.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _solde.dispose();
    _nom.dispose();
    _motif.dispose();
    super.dispose();
  }

  void _choisir(int i) {
    setState(() {
      // Le nom suit le type tant qu'on ne l'a pas changé à la main.
      final nomParDefaut = _nom.text.trim().isEmpty || _types.any((t) => t.$1 == _nom.text.trim() && t.$1 != 'Autre');
      _type = i;
      if (nomParDefaut) _nom.text = _types[i].$1 == 'Autre' ? '' : _types[i].$1;
    });
  }

  Future<void> _ajouter() async {
    final nom = _nom.text.trim();
    if (nom.isEmpty || _enCours) return;
    setState(() => _enCours = true);
    await const DepotComptes().ajouterLivret(
      nom: nom,
      soldeCentimes: lireEuros(_solde.text) ?? 0,
      motif: _motif.text.trim().isEmpty ? null : _motif.text.trim(),
    );
    rafraichir(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final icone = _types[_type].$2;
    // Sur l'écran déplié, le clavier ne s'ouvre pas tout seul : il
    // mangerait la moitié de la page.
    final large = MediaQuery.sizeOf(context).width >= 720;

    // Le solde, en grand : c'est ce qui compte.
    final solde = Carte(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tuile(icone: icone, couleur: AppColors.epargne, taille: 64),
          const SizedBox(height: 14),
          // Le champ épouse la largeur du montant, et le symbole euro le
          // suit, même tant que rien n'est tapé.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntrinsicWidth(
                stepWidth: 24,
                child: TextField(
                  controller: _solde,
                  autofocus: !large,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ,.]'))],
                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1),
                  decoration: const InputDecoration(hintText: '0', filled: false, border: InputBorder.none),
                ),
              ),
              const SizedBox(width: 6),
              const Text('€', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire)),
            ],
          ),
          const Text('Solde actuel du livret', style: TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
        ],
      ),
    );

    final type = Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Surtitre('Type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _types.length; i++)
                _Choix(texte: _types[i].$1, icone: _types[i].$2, actif: i == _type, onTap: () => _choisir(i)),
            ],
          ),
        ],
      ),
    );

    final nom = Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Surtitre('Nom'),
          const SizedBox(height: 10),
          TextField(
            controller: _nom,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Livret A, Livret vacances…'),
          ),
          const SizedBox(height: 18),
          const Surtitre('Sur ton relevé'),
          // Sur l'écran déplié, l'indice du champ suffit : tout tient.
          if (!large) ...[
            const SizedBox(height: 6),
            const Text(
              'Le mot du libellé quand tu verses sur ce livret. Laisse vide si c\'est le nom.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.texteDiscret),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _motif,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: _nom.text.trim().isEmpty ? 'LIVRET A' : _nom.text.trim().toUpperCase()),
          ),
        ],
      ),
    );

    final bouton = FilledButton(
      onPressed: _nom.text.trim().isEmpty || _enCours ? null : _ajouter,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.vert,
        foregroundColor: Colors.black,
        disabledBackgroundColor: AppColors.surfaceHaute,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: const Text('Ajouter le livret'),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, contraintes) {
            // Sur l'écran déplié, deux colonnes : le solde à gauche, le
            // reste à droite, et le bouton sous la colonne de droite.
            if (large) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BarreRetour(titre: 'Nouveau livret'),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: solde),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [type, const SizedBox(height: 14), nom],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    bouton,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BarreRetour(titre: 'Nouveau livret'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [solde, const SizedBox(height: 14), type, const SizedBox(height: 14), nom],
                  ),
                ),
                // Le bouton reste au-dessus du clavier.
                Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: bouton),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Choix extends StatelessWidget {
  const _Choix({required this.texte, required this.icone, required this.actif, required this.onTap});

  final String texte;
  final String icone;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: actif ? AppColors.epargne.withValues(alpha: 0.12) : AppColors.surfaceBasse,
        shape: StadiumBorder(side: BorderSide(color: actif ? AppColors.epargne.withValues(alpha: 0.45) : AppColors.trait)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconeDe(icone), size: 17, color: actif ? AppColors.epargne : AppColors.texteDiscret),
                const SizedBox(width: 7),
                Text(texte,
                    style: TextStyle(fontSize: 14, fontWeight: actif ? FontWeight.w800 : FontWeight.w600, color: actif ? AppColors.texte : AppColors.texteSecondaire)),
              ],
            ),
          ),
        ),
      );
}

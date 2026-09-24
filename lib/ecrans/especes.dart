import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/format.dart';
import '../config/theme.dart';
import '../domaine/modeles.dart';
import '../donnees/depots.dart';
import '../providers/donnees.dart';
import '../widgets/base.dart';
import 'categorie.dart';
import 'dialogues.dart';

/// Une dépense payée en espèces : la banque ne la voit pas, on la saisit.
/// Elle se retranche des retraits au distributeur du mois, pour que le même
/// argent ne compte pas deux fois.
class EcranNouvelleDepense extends ConsumerStatefulWidget {
  const EcranNouvelleDepense({super.key});

  @override
  ConsumerState<EcranNouvelleDepense> createState() => _EtatNouvelleDepense();
}

class _EtatNouvelleDepense extends ConsumerState<EcranNouvelleDepense> {
  final _montant = TextEditingController();
  final _nom = TextEditingController();
  final _note = TextEditingController();
  DateTime _le = DateTime.now();
  int? _categorie;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _montant.addListener(() => setState(() {}));
    _nom.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montant.dispose();
    _nom.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _complet => (lireEuros(_montant.text) ?? 0) > 0 && _nom.text.trim().isNotEmpty && _categorie != null;

  Future<void> _ajouter() async {
    if (!_complet || _enCours) return;
    setState(() => _enCours = true);
    await const DepotOperations().ajouterEspeces(
      le: _le,
      nom: _nom.text.trim(),
      centimes: lireEuros(_montant.text)!,
      categorieId: _categorie!,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    rafraichir(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).value ?? const <int, Categorie>{};
    final cat = _categorie == null ? null : cats[_categorie];
    final parent = cat == null ? null : (cat.parentId == null ? cat : cats[cat.parentId]);
    final large = MediaQuery.sizeOf(context).width >= 720;

    final montant = Carte(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tuile(icone: cat?.icone ?? parent?.icone ?? 'payments', couleur: parent == null ? AppColors.vert : Color(parent.couleur), taille: 64),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntrinsicWidth(
                stepWidth: 24,
                child: TextField(
                  controller: _montant,
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
          const Text('Payé en espèces', style: TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
        ],
      ),
    );

    Widget ligne(String icone, String libelle, String valeur, VoidCallback onTap, {Color? couleur}) => InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Icon(iconeDe(icone), size: 20, color: AppColors.texteSecondaire),
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

    final details = Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Surtitre('Quoi'),
          const SizedBox(height: 10),
          TextField(
            controller: _nom,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Boulangerie, marché, coiffeur…'),
          ),
          const SizedBox(height: 8),
          ligne(
            'label',
            'Catégorie',
            cat == null ? 'Choisir' : (cat.parentId == null ? cat.nom : '${parent!.nom} › ${cat.nom}'),
            () async {
              final id = await choisirCategorie(context, ref, genre: Genre.depense);
              if (id != null) setState(() => _categorie = id);
            },
            couleur: parent == null ? AppColors.vert : Color(parent.couleur),
          ),
          ligne('calendar_month', 'Le', jour(_le), () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _le,
              firstDate: DateTime.now().subtract(const Duration(days: 400)),
              lastDate: DateTime.now(),
            );
            if (d != null) setState(() => _le = d);
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLength: 140,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ajouter une note',
              counterText: '',
              prefixIcon: Icon(iconeDe('sticky_note_2'), color: AppColors.vert),
            ),
          ),
        ],
      ),
    );

    final bouton = FilledButton(
      onPressed: _complet && !_enCours ? _ajouter : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.vert,
        foregroundColor: Colors.black,
        disabledBackgroundColor: AppColors.surfaceHaute,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: const Text('Ajouter la dépense'),
    );

    return Scaffold(
      body: SafeArea(
        child: large
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BarreRetour(titre: 'Dépense en espèces'),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: montant),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: SingleChildScrollView(child: details)),
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
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BarreRetour(titre: 'Dépense en espèces'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [montant, const SizedBox(height: 14), details],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: bouton),
                ],
              ),
      ),
    );
  }
}

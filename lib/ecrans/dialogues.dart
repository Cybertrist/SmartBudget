import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../donnees/depots.dart';
import '../providers/donnees.dart';

/// Lit un montant en euros tapé à la française : « 1 500 », « 12,5 ».
int? lireEuros(String texte) {
  final t = texte.replaceAll(RegExp(r'[\s  €]'), '').replaceAll(',', '.');
  final v = double.tryParse(t);
  return v == null ? null : (v * 100).round();
}

/// Demande un montant et l'enregistre dans les réglages.
Future<void> fixerMontant(BuildContext context, WidgetRef ref, {required String cle, required String titre}) async {
  final actuel = await const DepotReglages().lire(cle);
  if (!context.mounted) return;
  final v = await demanderMontant(context, titre: titre, initial: actuel == null ? null : int.tryParse(actuel), vide: true);
  if (v == null) return;
  await const DepotReglages().ecrire(cle, v == 0 ? null : v.toString());
  rafraichir(ref);
}

/// Un montant tapé dans le champ, prêt à être relu.
String saisieEuros(int centimes) =>
    centimes % 100 == 0 ? '${centimes ~/ 100}' : (centimes / 100).toStringAsFixed(2).replaceAll('.', ',');

/// Demande un montant dans une feuille qui monte du bas : le montant en
/// grand au milieu, un seul bouton, et tout reste au-dessus du clavier.
/// Rend le montant en centimes, ou rien si l'on referme la feuille.
/// Avec [vide], un champ vide vaut zéro.
Future<int?> demanderMontant(BuildContext context, {required String titre, String? aide, int? initial, bool vide = false}) {
  final champ = TextEditingController(text: initial == null || initial == 0 ? '' : saisieEuros(initial));
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      void valider() {
        final v = lireEuros(champ.text);
        if (v == null && !(vide && champ.text.trim().isEmpty)) return;
        Navigator.pop(ctx, v ?? 0);
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (aide != null) ...[
              const SizedBox(height: 6),
              Text(aide, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.texteSecondaire)),
            ],
            const SizedBox(height: 18),
            // Le champ épouse la largeur du montant : le symbole euro le suit.
            Center(
              child: IntrinsicWidth(
                stepWidth: 24,
                child: TextField(
                  controller: champ,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ,.]'))],
                  onSubmitted: (_) => valider(),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '€',
                    suffixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire),
                    filled: false,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: valider,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: const StadiumBorder(),
                backgroundColor: AppColors.vert,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
    },
  );
}

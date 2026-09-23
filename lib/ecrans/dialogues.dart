import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final champ = TextEditingController();
  final actuel = await const DepotReglages().lire(cle);
  if (actuel != null) champ.text = ((int.tryParse(actuel) ?? 0) ~/ 100).toString();
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titre),
      content: TextField(
        controller: champ,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ,.]'))],
        decoration: const InputDecoration(suffixText: '€', hintText: '0'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
      ],
    ),
  );
  if (ok != true) return;
  final v = lireEuros(champ.text);
  await const DepotReglages().ecrire(cle, v?.toString());
  rafraichir(ref);
}

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

/// Une carte de saisie : elle s'agrandit depuis le centre et se tient en
/// haut de l'écran, au-dessus du clavier. Une feuille montant du bas ne
/// tenait pas sur l'écran déplié couché, où le clavier en prend la moitié.
Future<T?> carteSaisie<T>(
  BuildContext context, {
  required String titre,
  String? aide,
  String? icone,
  required Widget Function(BuildContext ctx, void Function() valider) champ,
  required T? Function() resultat,
  Widget? gauche,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, animation, _, enfant) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic)),
        child: enfant,
      ),
    ),
    pageBuilder: (ctx, _, _) {
      void valider() {
        final r = resultat();
        if (r != null) Navigator.pop(ctx, r);
      }

      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(titre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      if (aide != null) ...[
                        const SizedBox(height: 4),
                        Text(aide, style: const TextStyle(fontSize: 13, color: AppColors.texteSecondaire)),
                      ],
                      const SizedBox(height: 12),
                      champ(ctx, valider),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ?gauche,
                          const Spacer(),
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: valider,
                            style: FilledButton.styleFrom(
                              // Le thème étire les boutons : dans une rangée,
                              // il faut une largeur finie.
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                              shape: const StadiumBorder(),
                              backgroundColor: AppColors.vert,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            child: const Text('Enregistrer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Demande un montant. Rend le montant en centimes, ou rien si l'on
/// referme. Avec [vide], un champ vide vaut zéro.
Future<int?> demanderMontant(BuildContext context, {required String titre, String? aide, int? initial, bool vide = false, Widget? gauche}) {
  final champ = TextEditingController(text: initial == null || initial == 0 ? '' : saisieEuros(initial));
  return carteSaisie<int>(
    context,
    titre: titre,
    aide: aide,
    gauche: gauche,
    resultat: () {
      final v = lireEuros(champ.text);
      if (v == null && !(vide && champ.text.trim().isEmpty)) return null;
      return v ?? 0;
    },
    champ: (_, valider) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IntrinsicWidth(
          stepWidth: 24,
          child: TextField(
            controller: champ,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ,.]'))],
            onSubmitted: (_) => valider(),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
            decoration: const InputDecoration(hintText: '0', filled: false, border: InputBorder.none, isDense: true),
          ),
        ),
        const SizedBox(width: 6),
        const Text('€', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.texteSecondaire)),
      ],
    ),
  );
}

/// Demande un texte court. Rend le texte, vide compris, ou rien si l'on
/// referme.
Future<String?> demanderTexte(BuildContext context, {required String titre, String? aide, String initial = '', String? indice}) {
  final champ = TextEditingController(text: initial);
  return carteSaisie<String>(
    context,
    titre: titre,
    aide: aide,
    resultat: () => champ.text,
    champ: (_, valider) => TextField(
      controller: champ,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: (_) => valider(),
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(hintText: indice),
    ),
  );
}

/// Une liste de choix dans une carte au centre de l'écran, qui s'agrandit
/// comme la carte de saisie. Elle remplace les feuilles qui montaient du
/// bas. Toucher à côté la referme sans rien choisir.
Future<T?> carteChoix<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, animation, _, enfant) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic)),
        child: enfant,
      ),
    ),
    pageBuilder: (ctx, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

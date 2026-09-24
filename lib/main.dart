import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'banque/veille.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Les noms des mois et des jours en français, pour les en-têtes.
  await initializeDateFormatting('fr_FR');
  // Le moteur qui lit le solde en arrière-plan, pour l'alerte de compte en
  // négatif.
  await Veille.preparer();
  runApp(
    ValueListenableBuilder(
      valueListenable: generation,
      builder: (_, n, _) => ProviderScope(key: ValueKey(n), child: const SmartBudgetApp()),
    ),
  );
}

/// Monte après un effacement total : l'état en mémoire (les chiffres déjà
/// chargés, le mois choisi, les volets ouverts) repart de zéro. Sans cela,
/// les écrans réaffichaient l'ancien historique après l'effacement.
final generation = ValueNotifier(0);

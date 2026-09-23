import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Les noms des mois et des jours en français, pour les en-têtes.
  await initializeDateFormatting('fr_FR');
  runApp(const ProviderScope(child: SmartBudgetApp()));
}

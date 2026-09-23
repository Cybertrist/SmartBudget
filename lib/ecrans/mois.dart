import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../donnees/base.dart';
import '../providers/auth_provider.dart';

/// Les catégories de la base, lues à l'ouverture.
///
/// Provisoire : l'écran du mois viendra les remplacer. Il prouve déjà que
/// la base chiffrée s'ouvre derrière l'empreinte et qu'elle est semée.
final _categoriesProvider = FutureProvider.autoDispose<List<Map<String, Object?>>>(
  (ref) async {
    final base = await Base.instance.db;
    return base.query('categories', orderBy: 'ordre');
  },
);

class EcranMois extends ConsumerWidget {
  const EcranMois({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(_categoriesProvider);
    final mois = DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          mois[0].toUpperCase() + mois.substring(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Verrouiller',
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () => ref.read(authServiceProvider).lock(),
          ),
        ],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Base illisible : $e')),
        data: (liste) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.bord),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucun compte relié',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'La base chiffrée est prête. Le compte Crédit Mutuel de '
                    'Bretagne s\'y branchera à l\'étape suivante.',
                    style: TextStyle(height: 1.45, color: AppColors.texteSecondaire),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${liste.length} CATÉGORIES DE DÉPART',
              style: const TextStyle(
                fontSize: 11.5,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: AppColors.texteDiscret,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in liste)
                  Chip(
                    label: Text(c['nom']! as String),
                    side: BorderSide(color: Color(c['couleur']! as int).withValues(alpha: 0.5)),
                    backgroundColor: Color(c['couleur']! as int).withValues(alpha: 0.10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

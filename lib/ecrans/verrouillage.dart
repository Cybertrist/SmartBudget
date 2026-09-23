import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/logo_neon.dart';

/// L'écran d'ouverture : le logo, et l'empreinte.
///
/// La première demande part toute seule, dès que l'écran est posé : ouvrir
/// l'application et poser le doigt doit suffire. Si elle est fermée ou
/// ratée, un bouton la relance, et l'écran dit pourquoi.
class EcranVerrouillage extends ConsumerStatefulWidget {
  const EcranVerrouillage({super.key});

  @override
  ConsumerState<EcranVerrouillage> createState() => _EcranVerrouillageState();
}

class _EcranVerrouillageState extends ConsumerState<EcranVerrouillage> {
  bool _enCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrir());
  }

  Future<void> _ouvrir() async {
    if (_enCours) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final resultat = await ref.read(authServiceProvider).authenticate();
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _erreur = resultat.raison;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 0.9,
            colors: [Color(0xFF0B2A19), AppColors.fond],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const LogoNeon(taille: 128),
                const SizedBox(height: 28),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Smart '),
                    TextSpan(
                      text: 'Budget',
                      style: TextStyle(color: AppColors.neon),
                    ),
                  ]),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ton argent, sur ton téléphone seulement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.texteSecondaire),
                ),
                const Spacer(flex: 2),
                if (_erreur != null) ...[
                  Text(
                    _erreur!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.alerte,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                FilledButton.icon(
                  onPressed: _enCours ? null : _ouvrir,
                  icon: const Icon(Icons.fingerprint_rounded, size: 24),
                  label: Text(_enCours ? 'En attente du capteur…' : 'Ouvrir'),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../ecrans/categorie.dart';
import '../security/lock_state.dart';
import '../widgets/base.dart';
import 'connexion.dart';
import 'enable_banking.dart';

/// Ouvre la procédure pour obtenir la clé d'Enable Banking. Rend vrai quand
/// la clé est importée.
Future<bool> obtenirCle(BuildContext context, Banque banque) async =>
    await context.push<bool>('/banque/cle', extra: banque) ?? false;

const _portail = 'https://enablebanking.com/sign-in/?next=/cp/applications';
const _description = 'Application personnelle de suivi de budget, en lecture seule, pour mes propres comptes.';
const _lien = 'https://github.com/Cybertrist/SmartBudget';

/// La procédure sur le portail d'Enable Banking, pas à pas : tout se passe
/// sur leur site, SmartBudget donne quoi faire et quoi coller, puis importe
/// la clé que le site a téléchargée.
class EcranGuideCle extends StatelessWidget {
  const EcranGuideCle({super.key, required this.banque});

  final Banque banque;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const BarreRetour(titre: 'Obtenir ta clé'),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Enable Banking relie SmartBudget à ta banque, gratuitement, pour tes propres comptes. '
                'Ça se passe une fois, sur leur site, en quelques minutes.',
                style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.texteSecondaire),
              ),
            ),
            _Etape(
              numero: 1,
              titre: 'Se connecter au portail',
              texte: 'Tape ton adresse e-mail, puis ouvre le lien reçu. Le compte se crée tout seul la première fois.',
              actions: [_Action.ouvrir('Ouvrir le portail', _portail)],
            ),
            const _Etape(
              numero: 2,
              titre: 'Créer l\'application',
              texte: 'Dans « API applications », remplis « Add a new application » :',
              details: [
                'Environnement : Production',
                'Clé : laisse « Generate in the browser »',
                'Nom : SmartBudget',
              ],
            ),
            _Etape(
              numero: null,
              titre: 'À coller dans le formulaire',
              texte: 'Touche « Copier », puis colle dans le champ du même nom.',
              valeurs: [
                ('Allowed redirect URLs', EnableBanking.redirection),
                ('Application description', _description),
                ('Privacy URL', _lien),
                ('Terms URL', _lien),
              ],
              pied: 'Email for data protection : ton adresse e-mail. Puis « Register » : le site télécharge un fichier .pem, c\'est ta clé.',
            ),
            _Etape(
              numero: 3,
              titre: 'Relier ton compte sur le portail',
              texte: 'Sur la fiche de l\'application, touche « Activate by linking accounts », choisis ${banque.nom} '
                  'et « personal », puis « Link ». Valide sur ta banque, comme d\'habitude.',
            ),
            _Etape(
              numero: 4,
              titre: 'Importer la clé ici',
              texte: 'Choisis le fichier .pem téléchargé, sans le renommer : son nom est l\'identifiant de ton application. '
                  'SmartBudget le chiffre aussitôt et efface la copie.',
              principal: _Importer(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  const _Action.ouvrir(this.texte, this.adresse);

  final String texte;
  final String adresse;
}

/// Une étape de la procédure, dans une carte numérotée.
class _Etape extends StatelessWidget {
  const _Etape({
    required this.numero,
    required this.titre,
    required this.texte,
    this.details = const [],
    this.valeurs = const [],
    this.actions = const [],
    this.pied,
    this.principal,
  });

  final int? numero;
  final String titre;
  final String texte;
  final List<String> details;
  final List<(String, String)> valeurs;
  final List<_Action> actions;
  final String? pied;
  final Widget? principal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Carte(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (numero != null)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.vert.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.vert.withValues(alpha: 0.4)),
                ),
                child: Text('$numero', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.vert)),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(texte, style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.texteSecondaire)),
                  for (final d in details) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7, right: 8),
                          child: CircleAvatar(radius: 2.5, backgroundColor: AppColors.vert),
                        ),
                        Expanded(child: Text(d, style: const TextStyle(fontSize: 14, height: 1.4))),
                      ],
                    ),
                  ],
                  for (final (champ, valeur) in valeurs) _Valeur(champ: champ, valeur: valeur),
                  if (pied != null) ...[
                    const SizedBox(height: 10),
                    Text(pied!, style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.texteSecondaire)),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final a in actions)
                      _Pilule(texte: a.texte, icone: 'open_in_new', onTap: () => EnableBanking.ouvrirLien(a.adresse)),
                  ],
                  if (principal != null) ...[const SizedBox(height: 14), principal!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une valeur à coller dans le formulaire du portail, et son bouton pour la
/// copier.
class _Valeur extends StatelessWidget {
  const _Valeur({required this.champ, required this.valeur});

  final String champ;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(color: AppColors.surfaceHaute, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(champ, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.texteDiscret)),
                const SizedBox(height: 2),
                Text(valeur, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: valeur));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$champ copié.')));
            },
            child: const Text('Copier', style: TextStyle(color: AppColors.vert, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Pilule extends StatelessWidget {
  const _Pilule({required this.texte, required this.icone, required this.onTap});

  final String texte;
  final String icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.vert.withValues(alpha: 0.08),
      shape: StadiumBorder(side: BorderSide(color: AppColors.vert.withValues(alpha: 0.3))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconeDe(icone), size: 17, color: AppColors.vert),
              const SizedBox(width: 7),
              Text(texte, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.vert)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le bouton final : importer le .pem, puis revenir aux réglages, où la
/// liaison du compte s'enchaîne.
class _Importer extends StatelessWidget {
  const _Importer();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        final messager = ScaffoldMessenger.of(context);
        try {
          await EtatVerrou.instance.retenir(const ConnexionBanque().importerCle);
          if (!context.mounted) return;
          if ((await const ConnexionBanque().etat()).cle && context.mounted) context.pop(true);
        } on ErreurBanque catch (e) {
          messager.showSnackBar(SnackBar(content: Text(e.message)));
        }
      },
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.vert,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      icon: Icon(iconeDe('key'), size: 20),
      label: const Text('Importer la clé'),
    );
  }
}

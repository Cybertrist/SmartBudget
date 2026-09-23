import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../security/key_vault.dart';

/// La base, chiffrée par SQLCipher.
///
/// Elle garde une copie des opérations du compte : l'application s'ouvre
/// et se consulte sans réseau, et la banque n'est interrogée qu'au moment
/// d'une synchronisation. Sans la clé du trousseau, le fichier n'est
/// qu'un bloc d'octets.
///
/// Cinq tables :
/// - `comptes` : le compte courant venu de la banque, et les livrets saisis
///   à la main, que la DSP2 ne partage pas.
/// - `operations` : une ligne par mouvement. Les montants sont en centimes,
///   négatifs pour une sortie : un double ne sait pas écrire 0,10 €.
/// - `categories` : le classement des dépenses et des revenus.
/// - `regles` : ce que l'application a appris de tes corrections. Un
///   libellé reclassé à la main l'est ensuite tout seul.
/// - `reglages` : quelques valeurs, dont l'état de l'accès bancaire.
class Base {
  Base._();

  static final Base instance = Base._();

  static const _fichier = 'smartbudget.db';
  static const _version = 1;

  /// L'ouverture en cours ou faite. On garde le futur, pas la base : au
  /// déverrouillage, plusieurs écrans la demandent au même instant, et
  /// chacun lançait sinon sa propre ouverture. BodyCount a appris à ses
  /// dépens ce que deux connexions sur deux fichiers peuvent donner.
  Future<Database>? _ouverture;

  Future<Database> get db {
    final enCours = _ouverture;
    if (enCours != null) return enCours;
    final ouverture = _ouvrir();
    _ouverture = ouverture;
    ouverture.then(
      (_) {},
      onError: (Object _) {
        if (identical(_ouverture, ouverture)) _ouverture = null;
      },
    );
    return ouverture;
  }

  Future<Database> _ouvrir() async {
    if (!KeyVault.instance.isUnlocked) {
      throw StateError(
        'Base demandée avant déverrouillage : authentifier d\'abord.',
      );
    }

    final chemin = join(await getDatabasesPath(), _fichier);
    final motDePasse = await KeyVault.instance.databasePassword();

    return openDatabase(
      chemin,
      password: motDePasse,
      version: _version,
      onConfigure: (base) async {
        // Sans cette ligne, les ON DELETE CASCADE ne s'appliquent pas.
        await base.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (base, version) async {
        await _creerSchema(base);
        await _semerCategories(base);
      },
    );
  }

  Future<void> fermer() async {
    final ouverture = _ouverture;
    _ouverture = null;
    if (ouverture == null) return;
    try {
      await (await ouverture).close();
    } catch (_) {
      // Jamais ouverte : rien à fermer.
    }
  }

  /// Supprime le fichier. Avec [KeyVault.destroy], c'est l'effacement total.
  Future<void> effacer() async {
    await fermer();
    final chemin = join(await getDatabasesPath(), _fichier);
    final fichier = File(chemin);
    if (await fichier.exists()) await fichier.delete();
  }

  // ---------------------------------------------------------------- schéma

  Future<void> _creerSchema(Database base) async {
    await base.execute('''
      CREATE TABLE comptes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nature TEXT NOT NULL,
        nom TEXT NOT NULL,
        uid_banque TEXT UNIQUE,
        iban_fin TEXT,
        solde_centimes INTEGER NOT NULL DEFAULT 0,
        solde_le TEXT,
        motif_virement TEXT,
        cree_le TEXT NOT NULL
      )
    ''');

    await base.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE,
        genre TEXT NOT NULL,
        icone TEXT NOT NULL,
        couleur INTEGER NOT NULL,
        budget_centimes INTEGER,
        ordre INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await base.execute('''
      CREATE TABLE operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compte_id INTEGER NOT NULL REFERENCES comptes(id) ON DELETE CASCADE,
        uid_banque TEXT UNIQUE,
        le TEXT NOT NULL,
        libelle TEXT NOT NULL,
        montant_centimes INTEGER NOT NULL,
        categorie_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        classee_a_la_main INTEGER NOT NULL DEFAULT 0,
        livret_id INTEGER REFERENCES comptes(id) ON DELETE SET NULL,
        note TEXT
      )
    ''');
    await base.execute('CREATE INDEX operations_le ON operations(le)');
    await base.execute(
        'CREATE INDEX operations_categorie ON operations(categorie_id)');

    await base.execute('''
      CREATE TABLE regles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motif TEXT NOT NULL UNIQUE,
        categorie_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await base.execute('''
      CREATE TABLE reglages (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      )
    ''');
  }

  /// Les catégories de départ. Chacune se renomme, se recolore ou se
  /// supprime ensuite : ce n'est qu'un point de départ, pas un plan
  /// comptable.
  Future<void> _semerCategories(Database base) async {
    // L'icône est un nom, traduit en icône Material par le code : un
    // numéro de glyphe rangé en base empêcherait la version de publication
    // d'élaguer la police d'icônes.
    const categories = <(String, String, String, int)>[
      // nom, genre, icône, couleur
      ('Courses', 'depense', 'courses', 0xFF50F48D),
      ('Restaurants et sorties', 'depense', 'sorties', 0xFFFFC857),
      ('Logement', 'depense', 'logement', 0xFF5AB2FF),
      ('Transports', 'depense', 'transports', 0xFF9B8CFF),
      ('Abonnements', 'depense', 'abonnements', 0xFFFF8FD1),
      ('Shopping', 'depense', 'shopping', 0xFFFF9F5A),
      ('Santé', 'depense', 'sante', 0xFF4DE2D0),
      ('Loisirs', 'depense', 'loisirs', 0xFFC6F45A),
      ('Banque et frais', 'depense', 'banque', 0xFF8FA89A),
      ('Impôts', 'depense', 'impots', 0xFFB0B8FF),
      ('À classer', 'depense', 'aclasser', 0xFF5B7266),
      ('Salaire', 'revenu', 'salaire', 0xFF1BCC6D),
      ('Autres revenus', 'revenu', 'revenus', 0xFF7FE0A8),
      ('Épargne', 'epargne', 'epargne', 0xFF3CE0FF),
    ];
    final lot = base.batch();
    for (var i = 0; i < categories.length; i++) {
      final (nom, genre, icone, couleur) = categories[i];
      lot.insert('categories', {
        'nom': nom,
        'genre': genre,
        'icone': icone,
        'couleur': couleur,
        'ordre': i,
      });
    }
    await lot.commit(noResult: true);
  }
}

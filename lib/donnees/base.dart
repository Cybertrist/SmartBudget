import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../security/key_vault.dart';
import 'icones.dart';

/// La base, chiffrée par SQLCipher.
///
/// Elle garde une copie des opérations du compte : l'application s'ouvre
/// et se consulte sans réseau, et la banque n'est interrogée qu'au moment
/// d'une synchronisation. Sans la clé du trousseau, le fichier n'est
/// qu'un bloc d'octets.
///
/// Six tables :
/// - `comptes` : le compte courant venu de la banque, et les livrets saisis
///   à la main, que la DSP2 ne partage pas ;
/// - `categories` : catégories et sous-catégories, les secondes pointant
///   sur les premières par `parent_id` ;
/// - `operations` : une ligne par mouvement, en centimes, négatif pour une
///   sortie : un double ne sait pas écrire 0,10 € ;
/// - `regles` : ce que l'application a appris de tes corrections ;
/// - `liens` : la part d'une entrée qui rembourse une dépense ;
/// - `reglages` : quelques valeurs, dont le jour où commence le mois.
class Base {
  Base._();

  static final Base instance = Base._();

  static const _fichier = 'smartbudget.db';

  /// 2 : sous-catégories, liens de remboursement, virements internes. La
  /// version 1 n'a jamais porté de vraie donnée : elle est refaite à neuf.
  static const _version = 5;

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
      onUpgrade: (base, ancienne, nouvelle) async {
        if (ancienne < 2) {
          for (final t in ['liens', 'regles', 'operations', 'categories', 'comptes', 'reglages']) {
            await base.execute('DROP TABLE IF EXISTS $t');
          }
          await _creerSchema(base);
          await _semerCategories(base);
          return;
        }
        // Version 3 : une opération se pointe, une fois vérifiée à la main.
        if (ancienne < 3) {
          await base.execute('ALTER TABLE operations ADD COLUMN pointee INTEGER NOT NULL DEFAULT 0');
        }
        // Version 4 : une opération peut porter un nom choisi.
        if (ancienne < 4) {
          await base.execute('ALTER TABLE operations ADD COLUMN nom TEXT');
        }
        // Version 5 : une dépense payée en espèces, saisie à la main.
        if (ancienne < 5) {
          await base.execute('ALTER TABLE operations ADD COLUMN especes INTEGER NOT NULL DEFAULT 0');
        }
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
    final fichier = File(join(await getDatabasesPath(), _fichier));
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
        motif TEXT,
        cree_le TEXT NOT NULL
      )
    ''');

    await base.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
        nom TEXT NOT NULL,
        genre TEXT NOT NULL,
        icone TEXT,
        couleur INTEGER NOT NULL,
        budget_centimes INTEGER,
        ordre INTEGER NOT NULL DEFAULT 0,
        nature TEXT NOT NULL DEFAULT 'plaisir',
        UNIQUE (parent_id, nom)
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
        categorie_id INTEGER NOT NULL REFERENCES categories(id),
        origine TEXT NOT NULL,
        nature TEXT,
        mois_compte TEXT,
        note TEXT,
        masquee INTEGER NOT NULL DEFAULT 0,
        recurrente INTEGER,
        interne TEXT,
        pointee INTEGER NOT NULL DEFAULT 0,
        nom TEXT,
        especes INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await base.execute('CREATE INDEX operations_le ON operations(le)');
    await base.execute('CREATE INDEX operations_categorie ON operations(categorie_id)');

    await base.execute('''
      CREATE TABLE regles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motif TEXT NOT NULL UNIQUE,
        categorie_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await base.execute('''
      CREATE TABLE liens (
        entree_id INTEGER NOT NULL REFERENCES operations(id) ON DELETE CASCADE,
        depense_id INTEGER NOT NULL REFERENCES operations(id) ON DELETE CASCADE,
        montant_centimes INTEGER NOT NULL,
        PRIMARY KEY (entree_id, depense_id)
      )
    ''');

    await base.execute('''
      CREATE TABLE reglages (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      )
    ''');
  }

  /// Les catégories de départ, lues dans `assets/categories.json`. Chacune
  /// se renomme, se recolore ou se supprime ensuite.
  Future<void> _semerCategories(Database base) async {
    final json = jsonDecode(await rootBundle.loadString('assets/categories.json'))
        as Map<String, Object?>;
    final liste = (json['categories']! as List).cast<Map<String, Object?>>();

    await base.transaction((t) async {
      for (var i = 0; i < liste.length; i++) {
        final c = liste[i];
        final nom = c['nom']! as String;
        final couleur = int.parse('FF${(c['couleur']! as String).substring(1)}', radix: 16);
        final nature = naturesEssentielles.contains(nom) ? 'essentiel' : 'plaisir';
        final id = await t.insert('categories', {
          'nom': nom,
          'genre': c['genre'],
          'icone': iconeDeCategorie[c['icone']] ?? 'category',
          'couleur': couleur,
          'ordre': i,
          'nature': nature,
        });
        final sous = (c['sous']! as List).cast<String>();
        for (var j = 0; j < sous.length; j++) {
          final s = sous[j];
          await t.insert('categories', {
            'parent_id': id,
            'nom': s,
            'genre': c['genre'],
            'icone': iconeDeSous[s],
            'couleur': couleur,
            'ordre': j,
            'nature': sousEssentielles.contains(s) ? 'essentiel' : nature,
          });
        }
      }
    });
  }
}

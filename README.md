<div align="center">

<img src="docs/banniere.png" alt="Smart Budget : votre argent, vos projets, votre avenir. Gardez le contrôle, profitez de l'essentiel. Flutter, Enable Banking, SQLCipher, AES-GCM, Fold." width="100%">

</div>

<br>

Une application Android de budget, faite pour une seule personne et un seul compte : le sien. Elle lit le compte courant au Crédit Mutuel de Bretagne par la DSP2, range chaque opération dans sa catégorie, met de côté ce qui n'est ni une dépense ni un revenu, et montre où part l'argent, mois après mois. Tout reste sur le téléphone, chiffré.

Elle est née d'une envie simple : arrêter de dépenser sans regarder, et de piocher dans l'épargne. Le modèle, c'est Bankin ; le style, celui de Spotify, sobre et sombre, avec un seul vert.

<img src="docs/sections/s01.png" alt="01 Fonctionnalités" width="100%">

<img src="docs/schemas/fonctionnalites.png" alt="Douze fonctionnalités. Le compte, tout seul : le compte courant lu par la DSP2 via Enable Banking, douze mois d'historique puis une synchronisation à chaque ouverture. Classé sans rien faire : 23 catégories, 180 sous-catégories, 250 marchands reconnus, et une correction apprise. L'anneau des dépenses, sur un mois, trois mois ou un an. Les virements internes à part, hors budget. Les remboursements liés à leurs dépenses. Les récurrences repérées seules. À vérifier et pointer. Espèces et portefeuille. Livrets et épargne tenus par les virements. La recherche dans toutes les opérations. Chiffré sur le téléphone. La sauvegarde chiffrée." width="100%">

<img src="docs/sections/s02.png" alt="02 Les écrans" width="100%">

Sur le téléphone, une capsule flottante en bas pour naviguer.

<img src="docs/schemas/captures-telephone.png" alt="Onze écrans sur téléphone. L'ouverture : le logo, l'accroche et l'empreinte. Le mois : le solde de tous les comptes, les opérations à vérifier, les comptes. Où part l'argent : budget, épargne, les cinq premières catégories, la répartition essentiel, plaisir, épargne, imprévu. L'anneau des sorties, dont le centre ouvre les opérations. Une catégorie et ses sous-catégories. Les récurrences payées, à venir et en retard. L'épargne, mis de côté et pioché, les livrets. À vérifier. Les opérations jour par jour, avec la recherche et le bouton espèces. Une opération, avec son nom, son mouvement, sa catégorie, son type et sa répétition. Les réglages, avec la banque, le budget, la sécurité et la sauvegarde. Toutes viennent du jeu d'essai." width="100%">

Sur l'écran déplié du Fold, un rail à gauche, et les pages deviennent des volets côte à côte.

<img src="docs/schemas/captures-deplie.png" alt="Six écrans sur l'écran déplié du Fold. Le mois en deux colonnes, sans défiler. L'analyse, l'anneau à gauche et les catégories à droite. Toucher Logement pousse tout vers la gauche, la ligne ouverte reste surlignée. Puis Loyer, un volet de plus. Jusqu'à l'opération Foncia Loyer, dont le titre porte le montant. L'épargne, les livrets à gauche et les mouvements du mois à droite." width="100%">

<img src="docs/schemas/palette.png" alt="Palette : vert #1ED760, néon du logo #50F48D, fond #121212, cartes #181818, épargne #3CE0FF, virements internes #8FA3B8, attention #FFC857, alerte #FF6B7A." width="100%">

<img src="docs/sections/s03.png" alt="03 Installer" width="100%">

<p align="center">
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget.apk"><img src="docs/telecharger.png" alt="Télécharger Smart Budget, version 1.0.0, Android 8 ou plus, arm64" width="480"></a>
</p>

L'APK n'est pas sur le Play Store : Android demande d'autoriser l'installation depuis le navigateur, une fois. Chaque version est signée par la même clé, ce qui permet de l'installer par-dessus la précédente sans rien perdre. Pour vérifier le fichier téléchargé :

```
# SHA-256 de SmartBudget.apk, version 1.0.0
d73996a9305b03bb00a4ee9235b5087cc661a458f51f4d7c411464b9c5fedfea

# SHA-256 du certificat de signature, CN=SmartBudget, O=Cybertrist
55572db26550312a39ee80315ad81ce6c31e492f0e3aebfc8e5e0f2cffabcbef
```

Pour la construire soi-même :

```
flutter build apk --release --split-per-abi
# avec le jeu d'essai de quatre mois, pour essayer sans banque :
flutter build apk --release --split-per-abi --dart-define=ESSAIS=true
```

<img src="docs/sections/s04.png" alt="04 Relier la banque" width="100%">

<img src="docs/schemas/banque.svg" alt="Relier la banque, un échange entre quatre acteurs : Smart Budget, Enable Banking, ta banque et GitHub Pages. Smart Budget envoie un JWT signé en RS256 et un état tiré au hasard ; Enable Banking ouvre la page de la banque ; tu valides par Safetrans ; la banque revient sur GitHub Pages avec un code et l'état ; la page rend la main par smartbudget://banque ; l'application vérifie l'état, échange le code contre une session de 180 jours et les comptes, importe douze mois, puis se synchronise à chaque ouverture." width="100%">

La banque ne parle pas aux particuliers : il faut un agrégateur agréé DSP2. [Enable Banking](https://enablebanking.com) en propose un, gratuit en mode restreint, c'est-à-dire limité aux comptes qu'on a soi-même reliés sur son portail. Bridge, l'API de Bankin, est réservé aux entreprises, et GoCardless a fermé ses inscriptions.

1. Sur le portail d’Enable Banking, créer une application en production, mode restreint, avec pour adresse de retour `https://cybertrist.github.io/SmartBudget/`, puis y relier son compte au Crédit Mutuel de Bretagne.
2. Télécharger la clé privée : un fichier `.pem` dont le nom est l'identifiant de l'application. Ne jamais le renommer.
3. Dans l'application, Réglages, **Importer la clé**, choisir le fichier. Il est aussitôt chiffré et sa copie effacée.
4. **Relier le compte** : la page de la banque s'ouvre, on valide par Safetrans, et l'application reprend la main.

L'accès expire au bout de 180 jours, par la loi : la carte de la banque prévient quinze jours avant, et un toucher le renouvelle. La DSP2 ne partage que le compte courant, que la banque appelle « CARTE BANCAIRE » : les livrets se saisissent à la main, puis vivent au fil des virements repérés.

<img src="docs/sections/s05.png" alt="05 Comment une opération est lue" width="100%">

<img src="docs/schemas/classement.svg" alt="Comment une opération est lue. Le libellé PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09 perd son bruit, il reste la clé du marchand. Quatre questions s'enchaînent : virement interne, non ; règle apprise, non ; dictionnaire, oui. Résultat : Courses, Supermarché, essentiel." width="100%">

Un libellé de banque est écrit pour la banque. Le marchand s'en extrait en retirant les préfixes, la carte masquée, les dates, les références et les montants recopiés ; sa clé, ses trois premiers mots sans les suffixes de société, reste la même d'un mois à l'autre. C'est elle qui porte les corrections, les noms choisis et les répétitions : renommer « Spotify P2f9 Stockholm » en « Spotify » renomme toutes ses opérations, y compris les prochaines.

Ce que rien ne reconnaît tombe dans « À classer » et attend dans **À vérifier**, signalé sur l'accueil. Une opération vérifiée se pointe, et porte une coche verte.

<img src="docs/sections/s06.png" alt="06 Virements, remboursements, espèces" width="100%">

<img src="docs/schemas/mouvements.svg" alt="Trois pièges d'un relevé. Un virement vers le livret, lu dans VIR VERS LIVRET A DE COMPTE COURANT, est hors budget et compte 200 euros mis de côté. Un chèque de 500 euros rembourse 300 euros d'un billet de train de 380 et 200 euros d'un restaurant de 260 : il reste 80 et 60 euros, et le chèque n'est pas un revenu. Un retrait de 50 euros puis 12 euros au marché en espèces : les retraits tombent à 38, les courses montent à 12, le portefeuille passe de 50 à 38, et les sorties du mois restent 50 euros." width="100%">

Un budget honnête ne compte pas deux fois le même argent.

- **Un virement entre ses comptes** n'est ni une dépense ni un revenu. Au Crédit Mutuel de Bretagne, il s'écrit `VIR VERS <destination> DE <source>` : le sens se lit dans le libellé. Il sort du budget, hachuré, et nourrit « mis de côté » ou « pioché ». Si la détection se trompe, dans un sens ou dans l'autre, la ligne **Mouvement** d'une opération la corrige.
- **Un remboursement** se lie aux dépenses qu'il rembourse, depuis l'une ou depuis l'autre. Elles ne comptent plus que pour leur reste à charge, et lui ne compte pas comme un revenu.
- **Une dépense en espèces** se saisit à la main. Elle se retranche des retraits du mois, et le **portefeuille**, s'il est ouvert, suit ce qui reste en poche.

<img src="docs/sections/s07.png" alt="07 L'écran déplié" width="100%">

<img src="docs/schemas/volets.svg" alt="L'écran déplié. Deux volets côte à côte à droite du rail. Toucher Logement pousse tout vers la gauche et ouvre Logement à droite, puis Loyer, puis l'opération Foncia Loyer. La ligne ouverte reste surlignée à gauche. Le geste retour, un toucher vert qui file du bord droit vers la gauche, referme les volets un à un. À droite, la liste des pages ouvertes s'allonge puis se vide." width="100%">

Un écran de téléphone étiré sur huit pouces ne ressemble plus à rien. Sur le Fold ouvert, les pages forment une seule grande page dont on voit les deux derniers volets : on descend de l'analyse à l'opération sans jamais perdre d'où l'on vient, et le geste retour de Samsung referme le dernier volet. Chaque colonne se resserre au besoin pour tout montrer d'un coup, sans défiler. Les saisies s'ouvrent dans une carte au-dessus du clavier, jamais dans une feuille qui monte du bas.

<img src="docs/sections/s08.png" alt="08 La pile" width="100%">

<img src="docs/schemas/stack.png" alt="Flutter 3 pour toute l'application. sqflite_sqlcipher pour SQLite chiffré, schéma en version 5. flutter_secure_storage pour la clé maîtresse dans le Keystore. cryptography pour HKDF, AES-GCM et PBKDF2. local_auth pour l'empreinte. flutter_riverpod pour l'état. go_router pour la navigation et la garde du verrou. java.security pour la signature RS256 des requêtes à la banque. intl pour les dates et les montants." width="100%">

<img src="docs/sections/s09.png" alt="09 Architecture" width="100%">

<img src="docs/schemas/couches.png" alt="Six couches. ecrans : ne lisent que des providers, aucune ligne de SQL. providers : une écriture fait tout relire. domaine : du Dart pur, lire un libellé, reconnaître un virement, classer, détecter les récurrences, faire le bilan. donnees : le seul endroit où s'écrit du SQL. banque : Enable Banking, la clé déchiffrée le temps d'un appel. security : le trousseau et le verrou." width="100%">

<img src="docs/schemas/modele.png" alt="Six tables. operations : libellé, montant en centimes, catégorie, origine, sens interne, identifiant bancaire unique, nom et note, pointée et espèces, mois de rattachement. categories : nom, icône, couleur, parent, genre, nature. comptes : nature courant, livret ou portefeuille, solde, motif. liens : l'entrée qui rembourse, la dépense remboursée, la part. regles : le marchand appris et sa catégorie. reglages : budget, début du mois, clé bancaire chiffrée, choix par marchand." width="100%">

Les montants sont des entiers, en centimes : jamais un flottant ne touche à l'argent. Le domaine ne connaît ni Flutter ni la base, ce qui le rend testable sans appareil.

<img src="docs/sections/s10.png" alt="10 Le chiffrement" width="100%">

<img src="docs/schemas/chiffrement.svg" alt="L'empreinte charge la clé maîtresse de 32 octets depuis le Keystore. HKDF-SHA256 en dérive la clé de la base SQLCipher et celle qui chiffre en AES-GCM la clé privée d'Enable Banking. La sauvegarde, elle, est chiffrée en AES-GCM par une clé tirée d'une phrase par PBKDF2 en 210 000 tours, relisible sur un autre téléphone." width="100%">

La clé maîtresse est tirée au hasard au premier lancement et ne quitte jamais le Keystore d'Android. Tout le reste en dérive : la base, et la clé privée d'Enable Banking, la donnée la plus sensible de l'application, puisqu'elle ouvre la lecture du compte. Elle vit chiffrée deux fois, par sa propre clé et dans une base elle-même chiffrée, et n'est déchiffrée que le temps d'une requête. La signature RS256 se fait côté natif, par `java.security`.

**Tout effacer** détruit la clé d'abord, puis la base et ses fichiers annexes : même interrompu, rien de lisible ne reste.

<img src="docs/sections/s11.png" alt="11 Modèle de confidentialité" width="100%">

<img src="docs/schemas/confidentialite.png" alt="Ce qui est vrai : aucun serveur, l'application ne parle qu'à Enable Banking ; la base est chiffrée et sa clé chargée après l'empreinte ; la clé bancaire est chiffrée deux fois ; la DSP2 ne donne que la lecture et expire en 180 jours ; l'écran est protégé. Ce qui ne l'est pas : Enable Banking voit passer les opérations ; l'application ouverte montre tout ; une sauvegarde vaut ce que vaut sa phrase ; perdre le téléphone sans sauvegarde, c'est perdre les données ; l'empreinte se coupe." width="100%">

<img src="docs/sections/s12.png" alt="12 Les tests" width="100%">

<img src="docs/schemas/tests.png" alt="Les tests : libellés, virements internes, récurrences, classement et dédoublonnage, bilan avec remboursements et espèces, portefeuille, sauvegarde chiffrée, signature RS256 identique à OpenSSL. Les 22 tests tournent sur un émulateur Android." width="100%">

SQLCipher et le Keystore n'existent que sur un appareil : les tests tournent sur un émulateur, jamais sur le téléphone qui porte les vrais comptes, car ils effacent la base.

```
flutter test integration_test -d emulator-5554
```

<img src="docs/sections/s13.png" alt="13 Licence et auteur" width="100%">

Le code est publié sous licence [MIT](LICENSE) : libre de le lire, de le reprendre et de le modifier, à condition de garder la mention de copyright. La police Figtree est sous licence SIL Open Font, les icônes Material Symbols sous licence Apache 2.0.

Conçu et écrit par **Tristan Joncour**, élève ingénieur en cyberdéfense à l'ENSIBS, pour tenir ses propres comptes. Le socle de sécurité, empreinte, trousseau et chiffrement, vient de son autre application, [BodyCount](https://github.com/Cybertrist/BodyCount).

**Ce qui ne sera jamais dans ce dépôt :** la clé privée d'Enable Banking, la clé de signature de l'APK, et la moindre donnée bancaire réelle. `.gitignore` refuse les fichiers `.pem`, `.p12`, `.jks` et `key.properties`.

<br>

<sub>Les images de cette page ne sortent d'aucun logiciel de dessin : ce sont des pages HTML que Chrome capture, et cinq SVG animés écrits à la main par <code>anime.js</code>. Les captures viennent d'un émulateur rempli par le jeu d'essai, rognées par <code>rogner.js</code>. Tout est dans <a href="docs/tools/">docs/tools</a>.</sub>

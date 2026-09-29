<div align="center">

<p>
  <img src="docs/langues/fr-on.png" alt="Français" width="150" />
  <a href="README.en.md"><img src="docs/langues/en-off.png" alt="English" width="150" /></a>
</p>

<img src="docs/banniere.png" alt="Smart Budget : votre argent, vos projets, votre avenir. Gardez le contrôle, profitez de l'essentiel. Flutter, Enable Banking, SQLCipher, AES-GCM, Fold." width="100%">

<br>

**Une application Android de budget, faite pour une seule personne et un seul compte : le sien.**

</div>

Elle lit le compte courant par la DSP2, range chaque opération dans sa catégorie, met à part ce qui n'est ni une dépense ni un revenu, et montre où part l'argent, mois après mois. Tout reste sur le téléphone, chiffré : aucun serveur, aucun compte à créer, aucune publicité.

Elle est née d'une envie simple : arrêter de dépenser sans regarder, et de piocher dans l'épargne. Le modèle, c'est Bankin ; le style, celui de Spotify, sobre et sombre, avec un seul vert.

<img src="docs/sections/s00.png" alt="00 Sommaire" width="100%">

<p align="center">
<a href="#fonctionnalites"><img src="docs/sommaire/01.png" alt="01 Fonctionnalités" width="31%"></a>
<a href="#ecrans"><img src="docs/sommaire/02.png" alt="02 Les écrans" width="31%"></a>
<a href="#installer"><img src="docs/sommaire/03.png" alt="03 Installer" width="31%"></a>
<br>
<a href="#relier"><img src="docs/sommaire/04.png" alt="04 Relier la banque" width="31%"></a>
<a href="#quotidien"><img src="docs/sommaire/05.png" alt="05 Au quotidien" width="31%"></a>
<a href="#lecture"><img src="docs/sommaire/06.png" alt="06 Lecture d'une opération" width="31%"></a>
<br>
<a href="#mouvements"><img src="docs/sommaire/07.png" alt="07 Virements et épargne" width="31%"></a>
<a href="#alerte"><img src="docs/sommaire/08.png" alt="08 L'alerte" width="31%"></a>
<a href="#deplie"><img src="docs/sommaire/09.png" alt="09 L'écran déplié" width="31%"></a>
<br>
<a href="#chiffrement"><img src="docs/sommaire/10.png" alt="10 Chiffrement" width="31%"></a>
<a href="#confidentialite"><img src="docs/sommaire/11.png" alt="11 Confidentialité" width="31%"></a>
<a href="#architecture"><img src="docs/sommaire/12.png" alt="12 Architecture" width="31%"></a>
<br>
<a href="#tests"><img src="docs/sommaire/13.png" alt="13 Les tests" width="31%"></a>
<a href="#versions"><img src="docs/sommaire/14.png" alt="14 Les versions" width="31%"></a>
<a href="#licence"><img src="docs/sommaire/15.png" alt="15 Licence" width="31%"></a>
</p>

<a id="fonctionnalites"></a>
<img src="docs/sections/s01.png" alt="01 Fonctionnalités" width="100%">

<img src="docs/schemas/fonctionnalites.png" alt="Douze fonctionnalités. Le compte, tout seul : le compte courant lu par la DSP2 via Enable Banking, douze mois d'historique, une synchronisation à chaque ouverture, et une alerte si le compte passe en négatif. Classé sans rien faire : 23 catégories, 180 sous-catégories, plus de 200 marchands reconnus, et une correction apprise. L'anneau des dépenses, sur le mois ouvert par le salaire, trois mois ou un an. Les virements internes à part, hors budget. Les remboursements liés à leurs dépenses. Les récurrences repérées seules. À vérifier et pointer. Espèces et portefeuille. Livrets et épargne tenus par les virements. La recherche dans toutes les opérations. Chiffré sur le téléphone. La sauvegarde chiffrée." width="100%">

<a id="ecrans"></a>
<img src="docs/sections/s02.png" alt="02 Les écrans" width="100%">

Sur le téléphone, une capsule flottante en bas pour naviguer. Toutes les captures viennent du jeu d'essai de la démo.

<img src="docs/schemas/captures-telephone.png" alt="Onze écrans sur téléphone. L'ouverture : le logo, l'accroche et l'empreinte. Le mois : le solde de tous les comptes, les opérations à vérifier, les comptes. Où part l'argent : budget, épargne, les cinq premières catégories, la répartition essentiel, plaisir, épargne, imprévu. L'anneau des sorties, dont le centre ouvre les opérations. Une catégorie et ses sous-catégories. Les récurrences payées, à venir et en retard. L'épargne, mis de côté et pioché, les livrets. À vérifier. Les opérations jour par jour, avec la recherche et le bouton espèces. Une opération, avec son nom, son mouvement, sa catégorie, son type et sa répétition. Les réglages, avec la banque, le budget, la sécurité et la sauvegarde. Toutes viennent du jeu d'essai." width="100%">

Sur l'écran déplié du Fold, un rail à gauche, et les pages deviennent des volets côte à côte.

<img src="docs/schemas/captures-deplie.png" alt="Six écrans sur l'écran déplié du Fold. Le mois en deux colonnes, sans défiler. L'analyse, l'anneau à gauche et les catégories à droite. Toucher Logement pousse tout vers la gauche, la ligne ouverte reste surlignée. Puis Loyer, un volet de plus. Jusqu'à l'opération Foncia Loyer, dont le titre porte le montant. L'épargne, les livrets à gauche et les mouvements du mois à droite." width="100%">

<img src="docs/schemas/palette.png" alt="Palette : vert #1ED760, néon du logo #50F48D, fond #121212, cartes #181818, épargne #3CE0FF, virements internes #8FA3B8, attention #FFC857, alerte #FF6B7A." width="100%">

<a id="installer"></a>
<img src="docs/sections/s03.png" alt="03 Installer" width="100%">

<p align="center">
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget.apk"><img src="docs/telecharger.png" alt="Télécharger Smart Budget, la version complète, Android 8 ou plus" width="400"></a>
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget-demo.apk"><img src="docs/telecharger-demo.png" alt="Essayer la démo de Smart Budget, sans banque, Android 8 ou plus" width="400"></a>
</p>

Deux applications, qui s'installent côte à côte sans se gêner.

- **SmartBudget**, la version complète : elle se relie à ta banque et ne contient que tes vraies opérations.
- **SmartBudget démo** : quatre mois d'opérations inventées, déjà chargées à l'ouverture, sans banque, sans empreinte, et les captures d'écran permises. Pour voir chaque écran avant de relier quoi que ce soit.

Les APK ne sont pas sur le Play Store : Android demande, une fois, d'autoriser l'installation depuis le navigateur. Chaque version est signée par la même clé : elle s'installe par-dessus la précédente sans rien perdre.

<details>
<summary><b>Vérifier le fichier téléchargé, ou construire soi-même</b></summary>

```
# SHA-256 de SmartBudget.apk, version 1.2.6
0b8ba947f2d5a8d697713ee7b3f50cd0497112cc34e05d5f87a1f0b0a4cbb850

# SHA-256 de SmartBudget-demo.apk, version 1.2.6
67a1c7100131d4d9ec81fad7ba9594c92c1c26a093e4c7230cf6cdd23562ad5a

# SHA-256 du certificat de signature, CN=SmartBudget, O=Cybertrist
55572db26550312a39ee80315ad81ce6c31e492f0e3aebfc8e5e0f2cffabcbef
```

```
flutter build apk --release --split-per-abi
# la démo, avec son propre identifiant et le jeu d'essai déjà chargé :
flutter build apk --release --split-per-abi --dart-define=DEMO=true
```

</details>

<a id="relier"></a>
<img src="docs/sections/s04.png" alt="04 Relier la banque" width="100%">

La banque ne parle pas aux particuliers : il faut un agrégateur agréé DSP2. [Enable Banking](https://enablebanking.com) en propose un, gratuit en mode restreint, c'est-à-dire limité aux comptes qu'on a soi-même reliés sur son portail.

**Il faut** SmartBudget installé, une adresse e-mail que l'on peut ouvrir sur le téléphone, et de quoi se connecter à sa banque en ligne. Compter une dizaine de minutes, une seule fois : ensuite, l'accès tient 180 jours.

<img src="docs/schemas/parcours-banque.svg" alt="Choisir et relier sa banque, en cinq étapes, sur un téléphone animé. 1, dans les réglages, la carte Ta banque, toucher Choisir la banque. 2, chercher la sienne par son nom ou son pays, ici mutuel bretagne, puis toucher Crédit Mutuel de Bretagne. 3, la page Obtenir ta clé : Ouvrir le portail ouvre le site d’Enable Banking dans le navigateur, et chaque valeur à coller a son bouton Copier. 4, Importer la clé : choisir dans les téléchargements le fichier .pem, sans le renommer ; il est chiffré aussitôt et sa copie effacée. 5, la page de la banque s’ouvre, on valide comme d’habitude, puis la carte affiche Synchronisé, accès encore 180 jours, et les opérations arrivent." width="100%">

### 1. Choisir la banque

Onglet **Réglages**, carte **Ta banque**, bouton **Choisir la banque**. La liste contient toutes les banques qu'Enable Banking sait lire pour un particulier, dans une trentaine de pays d'Europe : d'abord les grandes banques du pays du téléphone, puis toutes les autres de A à Z.

### 2. Chercher la sienne

Taper une partie du nom (`mutuel bretagne`) ou un pays (`belgique`), puis toucher sa banque. Chaque banque tient sur une ligne, avec son pays et l'icône de son application mobile, rangée dans SmartBudget : aucune image n'est chargée depuis Internet. La page **Obtenir ta clé** s'ouvre aussitôt.

### 3. Obtenir sa clé sur le portail d'Enable Banking

C'est la seule étape hors de l'application. La page **Obtenir ta clé** donne les consignes dans l'ordre, et chaque valeur à coller a son bouton **Copier** : il suffit d'aller et venir entre SmartBudget et le navigateur.

<img src="docs/schemas/portail.svg" alt="Sur le portail d’Enable Banking. Se connecter : taper son adresse e-mail, Continue, puis ouvrir le lien reçu. Créer l’application, Add a new application : Environment Production, Private key Generate in the browser, Application name SmartBudget, puis coller les valeurs copiées depuis SmartBudget : Allowed redirect URLs https://cybertrist.github.io/SmartBudget/, la description, Privacy URL et Terms URL ; Email for data protection, son adresse. Register : un fichier .pem se télécharge, c’est la clé, à ne jamais renommer. Puis Activate by linking accounts : pays, sa banque, type personal, Link, et l’on valide sur sa banque. L’application est active, en mode restreint gratuit." width="100%">

1. **Se connecter.** Toucher **Ouvrir le portail**, taper son adresse e-mail, **Continue**, puis ouvrir le lien reçu. Le compte Enable Banking se crée tout seul la première fois.
2. **Créer l'application.** Dans **API applications**, remplir **Add a new application** :
   - **Environment** : `Production`
   - **Private key** : laisser `Generate in the browser`
   - **Application name** : `SmartBudget`
   - **Allowed redirect URLs** : `https://cybertrist.github.io/SmartBudget/` (bouton Copier)
   - **Application description** : la phrase proposée (bouton Copier)
   - **Email for data protection** : sa propre adresse e-mail
   - **Privacy URL** et **Terms URL** : `https://github.com/Cybertrist/SmartBudget` (boutons Copier)
3. **Register.** Le portail télécharge un fichier `.pem` : c'est la clé privée de l'application. **Ne jamais le renommer** : son nom est l'identifiant de l'application.
4. **Relier son compte sur le portail.** Sur la fiche de l'application, **Activate by linking accounts**, choisir le pays, sa banque et le type `personal`, puis **Link**, et valider sur la page de la banque comme d'habitude.

### 4. Importer la clé

De retour dans SmartBudget, en bas de la page **Obtenir ta clé** : **Importer la clé**, et choisir le fichier `.pem` dans les téléchargements. Il est aussitôt chiffré dans le téléphone (AES-GCM, par une clé tirée du Keystore), et sa copie de travail effacée.

### 5. Relier le compte

La page de la banque s'ouvre une dernière fois, on valide, et SmartBudget reprend la main. La carte **Ta banque** affiche **Synchronisé**, avec les jours d'accès restants, et les douze derniers mois arrivent. Ensuite, il n'y a plus rien à faire.

L'accès expire au bout de 180 jours, par la loi : à moins de quinze jours de la fin, la carte de la banque passe au jaune, et une fois l'accès expiré, **Relier le compte** le renouvelle, avec la même clé. La DSP2 ne partage que le compte courant, que la banque appelle « CARTE BANCAIRE » : les livrets se saisissent à la main, puis vivent au fil des virements repérés. L'application a été écrite et testée avec le Crédit Mutuel de Bretagne ; ailleurs, le classement marche de la même façon, mais les virements vers les livrets peuvent demander d'être marqués à la main la première fois.

<details>
<summary><b>Si ça coince</b></summary>

- **« Le nom du fichier ne contient pas l'identifiant de l'application »** : le fichier `.pem` a été renommé, par exemple en `cle.pem`. Le télécharger de nouveau depuis la fiche de l'application, sans toucher à son nom.
- **« Ce fichier n'est pas une clé privée »** : le fichier choisi n'est pas le `.pem` du portail. Choisir celui téléchargé à l'étape 3.
- **« Enable Banking refuse la clé »** : la clé importée ne correspond pas à l'application, ou l'application n'est pas en `Production`. Refaire l'étape 3, puis importer la nouvelle clé (bouton **Nouvelle clé** de la carte).
- **« Pas de connexion à Internet. »** : la synchronisation reprendra seule à la prochaine ouverture avec du réseau.
- **« Trop de synchronisations aujourd'hui »** : la banque limite le nombre d'accès par jour. Il suffit d'attendre le lendemain.
- **« L'accès a expiré : reconnecte le compte. »** : les 180 jours sont passés. Toucher **Relier le compte** et valider sur la banque : la clé reste la même.
- **Sa banque n'est pas dans la liste** : Enable Banking ne la lit pas encore, ou pas pour les particuliers.

</details>

<details>
<summary><b>Ce qui se passe derrière</b></summary>

<img src="docs/schemas/banque.svg" alt="Relier la banque, un échange entre quatre acteurs : Smart Budget, Enable Banking, ta banque et GitHub Pages. Smart Budget envoie à Enable Banking un JWT signé en RS256 et un état tiré au hasard ; Enable Banking ouvre la page de la banque ; tu valides par Safetrans ; la banque revient sur GitHub Pages avec un code et l’état ; la page rend la main à l’application par smartbudget://banque ; l’application vérifie que l’état est le même qu’au départ, échange le code contre une session de 180 jours et les comptes, puis importe douze mois et se synchronise à chaque ouverture." width="100%">

Chaque requête vers Enable Banking porte un jeton signé en RS256 par la clé importée, déchiffrée le temps de l'appel seulement. Le retour de la banque passe par une page de GitHub Pages (`docs/index.html`), qui rend la main à l'application par le lien `smartbudget://banque` ; le jeton d'état, tiré au hasard au départ et vérifié au retour, empêche un lien fabriqué ailleurs de relier un autre compte.

</details>

<a id="quotidien"></a>
<img src="docs/sections/s05.png" alt="05 Au quotidien" width="100%">

SmartBudget se synchronise **à chaque ouverture**, et à chaque retour dans l'application dès que la dernière synchronisation a plus de dix minutes. Il n'y a rien d'autre à faire que regarder.

<img src="docs/schemas/synchro.svg" alt="La synchronisation à l’ouverture. Le téléphone s’ouvre par l’empreinte, l’accueil affiche Synchronisation…, et l’application demande à la banque les opérations depuis le 18 septembre, la dernière synchronisation moins sept jours. Cinq opérations reviennent. CB LE FOURNIL, 3,80 euros, a un identifiant déjà connu : elle est ignorée, rien ne compte deux fois. CB CARREFOUR MARKET, 54,20 euros, désormais comptabilisée, remplace l’opération en attente du même marchand et du même montant, à une semaine près, et garde ce qui avait été fait à la main : le nom Courses de la semaine, la catégorie Courses et la note partagé avec Léa. PRLV SEPA FREE MOBILE, 19,99 euros, est nouvelle et classée dans Abonnements, Forfait mobile. VIR VERS LIVRET A DE CARTE BANCAIRE, 100 euros, est un virement interne, hors budget, et le Livret A passe de 2 960 à 3 060 euros. CB SNCF CONNECT, 45 euros, arrive en attente, classée dans Transports. Puis le solde est relu et comparé à zéro. Le compteur ne compte que les vraies nouvelles : trois, et l’accueil affiche 3 nouvelles opérations et Mis à jour le 26 sept. Elle part à l’ouverture et à chaque retour si la dernière a plus de dix minutes ; la première fois elle importe douze mois ; l’accès dure 180 jours et la carte de la banque prévient quinze jours avant." width="100%">

Chaque synchronisation redemande les opérations depuis la dernière, moins sept jours, pour rattraper celles que la banque comptabilise en retard. Une opération déjà connue, à son identifiant bancaire, est ignorée : relancer ne double rien. Une opération **En attente**, comme un paiement par carte du jour, apparaît tout de suite ; une fois comptabilisée, elle est mise à jour sur place et garde ce que tu y avais fait à la main (nom, catégorie, note, mois) et ses liens de remboursement.

<img src="docs/schemas/accueil.svg" alt="L’accueil, le mois en cours en un coup d’œil, sur un téléphone animé. Onze opérations de septembre y entrent une à une, avec un budget de 1 500 euros. Foncia Loyer, 620 euros, et Carrefour Market, 182,40 euros, comptent. Un virement de 200 euros vers le Livret A est hors budget : il ne compte que dans l’épargne, et le livret passe à 3 060 euros. Le Comptoir, 86,50 euros, et SNCF Connect, 145 euros, comptent. Norauto, 380 euros, marqué imprévu à la main, fait passer la jauge au jaune, au-delà de 90 %. Pharmacie du Port, 30 euros, puis un remboursement de la CPAM de 23,50 euros lié à elle : il n’est pas un revenu, il allège la pharmacie, qui ne pèse plus que 6,50 euros. Leboncoin, 250 euros, est masquée : rien ne bouge. Zalando, 89,99 euros, fait dépasser le budget : la carte passe au rouge et affiche 10,39 euros de dépassement. Spotify, 11,12 euros, compte mais reste hors des cinq premières catégories. À la fin : 1 521,51 euros de sorties, 21,51 euros de dépassement ; les cinq premières catégories sont Logement, Transports, Courses, Shopping, Restaurants et sorties ; la répartition donne Essentiel 953,90 euros, Plaisir 187,61 euros, Épargne 200 euros et Imprévu 380 euros." width="100%">

L'accueil montre toujours le mois en cours. Le budget, c'est ce qui reste une fois les sorties retirées : vert, jaune dès 90 %, rouge au-delà, où il affiche le dépassement. Suivent les cinq catégories les plus lourdes, puis la répartition entre essentiel, plaisir, épargne et imprévu. Un virement vers un livret n'y compte que comme épargne, un remboursement lié allège la dépense qu'il rembourse, et une opération masquée n'apparaît nulle part.

<img src="docs/schemas/analyse.svg" alt="L’écran Analyse, sur un téléphone animé, en six gestes. 1, choisir le mois : la flèche de gauche passe de septembre à août 2026, où les sorties montent à 1 412,36 euros, puis la flèche de droite revient en septembre, et s’arrête au mois en cours ; les puces 1 mois, 3 mois et 1 an choisissent la période, qui se termine au mois affiché : 4 118,63 euros sur trois mois. 2, les onglets : Sorties, 1 349,91 euros ; Entrées, 1 309,40 euros, surtout le salaire ; Récurrences, 630,86 euros payés sur 633,16 attendus, avec ce qui est à venir et ce qui est payé. 3, l’anneau porte une icône par catégorie, et son centre ouvre les sorties du mois, jour par jour, avec la recherche et le bouton Espèces. 4, plus bas, la liste des catégories : toucher Logement ouvre son total, -556,77 euros, 41 % des dépenses du mois, et ses sous-catégories, Loyer et Électricité, puis en pastilles celles sans rien ce mois-ci. 5, toucher Loyer ouvre ses opérations jour par jour. 6, toucher Foncia Loyer ouvre l’opération : nom, mouvement, catégorie Logement › Loyer, type Essentiel, et Compte en Septembre. En bas, le chemin Analyse, Logement, Loyer, Foncia Loyer s’écrit au fil des pages. Au retour, l’analyse garde le mois, la période et l’onglet." width="100%">

L'analyse part d'un mois et descend jusqu'à l'opération. Les flèches changent de mois, les puces choisissent un mois, trois ou un an, et les onglets passent des sorties aux entrées et aux récurrences. Le centre de l'anneau ouvre les opérations qu'il compte ; une catégorie ouvre ses sous-catégories, une sous-catégorie ses opérations, jour par jour. Au retour, le mois, la période et l'onglet restent ceux qu'on avait choisis.

<a id="lecture"></a>
<img src="docs/sections/s06.png" alt="06 Comment une opération est lue" width="100%">

<img src="docs/schemas/classement.svg" alt="Comment une opération est lue. Le libellé PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09 perd son bruit : le préfixe, la carte masquée et la date sont barrés, il reste la clé du marchand CARREFOUR MARKET VANNES. Quatre questions s’enchaînent : virement interne, non ; règle apprise, non ; dictionnaire, oui ; à classer n’est pas atteint. Résultat : Courses, Supermarché, essentiel. Corriger une catégorie écrit une règle, suivie par les prochaines opérations du même marchand." width="100%">

Un libellé de banque est écrit pour la banque. Le marchand s'en extrait en retirant les préfixes, la carte masquée, les dates, les références et les montants recopiés ; sa clé, ses trois premiers mots sans les suffixes de société, reste la même d'un mois à l'autre. C'est elle qui porte les corrections, les noms choisis et les répétitions : renommer « Spotify P2f9 Stockholm » en « Spotify » renomme toutes ses opérations, y compris les prochaines.

<img src="docs/schemas/apprentissage.svg" alt="À vérifier, et la correction apprise, sur un téléphone animé. L’accueil signale 4 opérations à vérifier. La liste À vérifier montre celles que rien n’a reconnues, chacune avec Classer et Interne, et Garder pour une entrée reçue. On classe Sumup Atelier Kernevel du 8 septembre dans Loisirs, Hobbies : la correction devient une règle attachée à la clé du marchand, SUMUP ATELIER KERNEVEL, tirée du libellé PAIEMENT PAR CARTE X0000 SUMUP *ATELIER KERNEVEL 07/09. L’opération est classée à la main et pointée ; celle du 12 août, du même marchand et pas classée à la main, suit la règle, et les deux quittent la liste. On garde ensuite le remboursement de 25 euros reçu, qui quitte la liste lui aussi. Sur la fiche de l’opération, Renommer en Atelier Kernevel renomme toutes les opérations du marchand, passées et à venir. À la synchro suivante, l’opération du 7 octobre arrive déjà classée dans Hobbies par la règle apprise, déjà nommée Atelier Kernevel, sans passer par À vérifier. Une opération classée à la main n’est plus jamais touchée par une règle." width="100%">

Ce que rien ne reconnaît attend dans **À vérifier**, signalé sur l'accueil. Classer une opération écrit une règle sur la clé du marchand : ses autres opérations qui n'ont pas été classées à la main suivent tout de suite, et les prochaines arriveront déjà classées. Un chèque, une remise de chèque ou un retrait n'ont pas de marchand : les classer ne vaut que pour eux. Classer ou garder pointe l'opération, qui porte alors une coche verte.

<img src="docs/schemas/recurrences.svg" alt="Les récurrences, déduites des opérations sans rien saisir. Sur quatre mois, marchand par marchand, la lecture balaie jusqu’au 20 septembre et mesure l’écart entre deux passages. Foncia Loyer, 520 euros le 5 de chaque mois, et EDF, de 36,40 à 41,20 euros le 8, reviennent tous les 30 ou 31 jours : Chaque mois, déjà payées ce mois-ci. Basic Fit, 29,99 euros, attendu le 10 septembre, n’est pas passé : en retard. Netflix, 14,99 euros, et Vinted, deux achats à un mois d’écart, sont à venir. Carrefour Market n’a aucun rythme. Le club d’escalade, prélevé à 50 jours d’écart, n’est pas vu. Chaque écart doit tomber dans une fenêtre : 6 à 8 jours pour chaque semaine, 25 à 35 pour chaque mois, 85 à 95 pour chaque trimestre, 350 à 380 pour chaque année ; il faut au moins deux passages et un montant à 15 % de sa médiane, qui devient le montant attendu. Sur le téléphone, l’onglet Récurrences de l’analyse montre en retard, à venir et payées, et 558,90 euros payés sur 622,38 attendus. Sur la fiche de l’achat Vinted, la ligne Répétition passe de Chaque mois à Aucune : ce marchand ne revient pas, il sort de la liste. Sur celle du club d’escalade, elle passe de Aucune à Chaque mois : il apparaît à venir, dans 1 jour. Le choix vaut pour toutes les opérations du marchand et passe avant la détection." width="100%">

Les récurrences se déduisent seules : au moins deux passages d'un même marchand, un montant à 15 % près, et chaque écart dans une fenêtre (une semaine, un mois, un trimestre, un an). La prochaine date en découle, et l'analyse les range en retard (quatre jours de grâce), à venir ou payées. La ligne **Répétition** d'une opération corrige la détection pour tout le marchand : « Aucune » s'il ne revient pas, une fréquence s'il revient sans rythme.

<a id="mouvements"></a>
<img src="docs/sections/s07.png" alt="07 Virements, remboursements, épargne" width="100%">

<img src="docs/schemas/mouvements.svg" alt="Trois pièges d’un relevé, et comment l’application les défait. Un virement vers le livret A, lu dans VIR VERS LIVRET A DE CARTE BANCAIRE : l’argent passe du compte courant au livret, il est hors budget, compté 200 euros mis de côté, et le budget reste inchangé. Un chèque de 500 euros qui rembourse : 300 euros vont au billet de train de 380 euros, dont il reste 80, et 200 au restaurant de 260 euros, dont il reste 60 ; le chèque ne compte pas comme un revenu. Des espèces : un retrait de 50 euros, puis 12 euros au marché ; les retraits tombent à 38, les courses montent à 12, le portefeuille passe de 50 à 38 euros, et les sorties du mois restent 50 euros, pas 62." width="100%">

Un budget honnête ne compte pas deux fois le même argent.

- **Un virement entre ses comptes** n'est ni une dépense ni un revenu. Au Crédit Mutuel de Bretagne, il s'écrit `VIR VERS <destination> DE <source>` : le sens se lit dans le libellé. Il sort du budget, hachuré, et nourrit « mis de côté » ou « pioché ». Si la détection se trompe, la ligne **Mouvement** d'une opération la corrige.
- **Un remboursement** se lie aux dépenses qu'il rembourse. Elles ne comptent plus que pour leur reste à charge, et lui ne compte pas comme un revenu.
- **Une dépense en espèces** se saisit à la main. Elle puise dans le plus ancien retrait qui la précède, jusqu'à deux mois avant : retirer 50 € en septembre puis payer 20 € au marché en octobre compte 30 € de retrait en septembre et 20 € de courses en octobre, jamais 70. Le **portefeuille**, s'il est ouvert, suit ce qui reste en poche.

<img src="docs/schemas/remboursement.svg" alt="Lier un remboursement, dans les deux sens, sur un téléphone animé. A, depuis la dépense : sur la fiche du concert, 90 euros le 20 septembre, la ligne Remboursement dit Aucun ; la toucher ouvre Associer à un remboursement, qui propose l’argent reçu jusqu’à deux mois avant ou après l’achat. On coche le virement de Camille Roux, 30 euros reçus le 14 septembre, puis celui de Hugo Lefèvre, 30 euros reçus le 23 septembre ; la remise de chèque, déjà entièrement affectée ailleurs, reste grisée. En bas, le récapitulatif passe de Reste 90 euros à 2 sélectionnés, 60 euros, reste 30 euros. Valider 2 remboursements : la fiche affiche 60 euros reçus (2), elle ne compte plus que pour 30 euros, et les 60 euros de Camille et Hugo ne comptent plus comme un revenu. B, depuis l’entrée : sur la fiche du virement de Lucas Martin, 500 euros le 18 septembre, la carte Rembourse propose Lier des dépenses. L’écran liste les dépenses de deux mois avant à un mois après l’entrée ; cocher le billet de train de 380 euros propose 380 euros, corrigés à 300, puis cocher le restaurant de 260 euros propose les 200 qui restent, et la jauge Réparti atteint 500 sur 500. Lier 2 dépenses : le billet ne compte plus que 80 euros, le restaurant 60, tous deux en août, et les 500 euros de Lucas ne sont pas un revenu de septembre. Une entrée peut rembourser plusieurs dépenses et une dépense être remboursée par plusieurs entrées, jamais au-delà de l’une ou de l’autre." width="100%">

Le remboursement peut arriver avant l'achat ou après. Depuis la dépense, sa ligne **Remboursement** ouvre **Associer à un remboursement**, qui propose l'argent reçu jusqu'à deux mois avant ou après, avec ce qu'il en reste. Depuis l'entrée, **Lier des dépenses** la répartit sur plusieurs dépenses, et la jauge **Réparti** ne dépasse jamais le montant reçu. Une dépense peut être remboursée par plusieurs entrées, jamais au-delà de son montant. Chaque opération reste dans son mois : un achat d'août remboursé en septembre corrige août.

<img src="docs/schemas/epargne.svg" alt="L’épargne et les livrets, sur un téléphone animé. La banque ne partage par la DSP2 que le compte courant : les livrets ne passent pas par elle et se saisissent à la main. Sur l’écran Épargne, où seul le LDDS de 1 800 euros existe, toucher Ajouter ouvre Nouveau livret : le solde actuel, 3 200 euros, le type Livret A, le nom, et le mot qui le désigne sur le relevé, puis Ajouter le livret. Ensuite, chaque virement lu sur le compte courant fait vivre son solde. VIR VERS LIVRET A DE CARTE BANCAIRE, 200 euros, va vers le Livret A depuis le compte courant : mis de côté, le livret passe à 3 400 euros. VIR VERS CARTE BANCAIRE DE LIVRET A, 100 euros, revient au compte courant : pioché, le livret passe à 3 300 euros. Un paiement chez Carrefour Market de 64,30 euros, lui, est une dépense. Le budget du mois ne compte que ces 64,30 euros de dépenses et aucun revenu : les virements internes restent hors budget. L’écran Épargne affiche 5 100 euros au total, plus 100 euros ce mois-ci, 200 euros mis de côté, 100 euros piochés, le Livret A à 65 pour cent de l’épargne et les deux mouvements repérés. Seuls les virements arrivés après le solde saisi le font bouger, et toucher un livret corrige son solde." width="100%">

Chaque livret s'ajoute une fois, dans **Épargne**, **Mes livrets**, **Ajouter** : son solde actuel, son type, et le mot qui le désigne sur le relevé. Ensuite, chaque virement vers lui ou depuis lui, repéré sur le compte courant, fait bouger son solde, à condition d'être postérieur au solde saisi et plus en attente. Toucher un livret corrige son solde, tel que la banque l'affiche.

<img src="docs/schemas/mois.svg" alt="Le mois budgétaire, sur une frise du 20 novembre 2025 au 31 janvier 2026 et un téléphone animé. Onze opérations : un salaire de 1 850 euros le 25 novembre, des courses, le loyer de 520 euros le 5 décembre, des courses, un salaire versé en avance pour Noël le 19 décembre, des cadeaux le 23 décembre, des courses, le loyer le 5 janvier, une prime de 250 euros classée Salaire le 9 janvier, des courses, et le salaire du 27 janvier. 1, dans les réglages, Début du mois dit Salaire, vers le 25 : le jour habituel du salaire, trouvé tout seul, n’est qu’un repère. À jour fixe, décembre irait du 25 novembre au 24 décembre, avec deux salaires, 3 700 euros d’entrées, et janvier n’aurait que la prime, pour un solde de -393,70 euros. 2, chaque salaire ouvre son mois le jour où il arrive : celui du 19 décembre ouvre janvier ce jour-là, et sa fiche dit Compte en Janvier. Décembre va du 25 novembre au 18 décembre, 1 850 euros d’entrées pour 678,70 de sorties ; janvier du 19 décembre au 26 janvier, 2 100 euros d’entrées pour 808,60 de sorties ; le salaire du 27 janvier ouvre février. 3, seul un vrai salaire ouvre un mois : classé Salaire, au moins la moitié du salaire habituel, à dix jours au plus du jour habituel. La prime de 250 euros du 9 janvier n’ouvre rien." width="100%">

**Le mois budgétaire** s'ouvre avec le salaire : chaque salaire ouvre son mois le jour où il arrive, même versé en avance. Le salaire du 19 décembre, versé plus tôt pour Noël, ouvre janvier ce jour-là, et décembre ne compte jamais deux salaires. Dans les réglages, *Début du mois* affiche le jour habituel, par exemple « Salaire, vers le 25 » : SmartBudget le trouve tout seul, au milieu de tes salaires des six derniers mois, et il ne sert qu'aux mois dont le salaire n'est pas encore arrivé. On peut aussi le choisir à la main, du 1er au 28.

Seul un vrai salaire ouvre un mois : classé dans Salaire, au moins la moitié du salaire habituel, et à dix jours au plus du jour habituel. Une prime ou un remboursement n'ouvrent rien, et deux salaires pour le même mois n'en ouvrent qu'un. Si une opération tombe quand même du mauvais côté, un loyer payé pour le mois suivant par exemple, la ligne **Compte en** de l'opération la rattache au mois d'avant ou d'après.

<a id="alerte"></a>
<img src="docs/sections/s08.png" alt="08 L'alerte de compte en négatif" width="100%">

SmartBudget n'envoie qu'une seule notification : **« Compte courant en négatif »**, avec le montant, quand le compte vient de passer sous zéro. Pas de rappel de budget, pas de résumé de la semaine, pas de publicité : rien d'autre ne sonne.

<img src="docs/schemas/alerte.svg" alt="La veille du solde. Toutes les six heures, même application fermée, le solde du compte courant est relu. Sur deux jours, huit lectures : 320, 180 et 60 euros, puis -42,10 euros à minuit, et le téléphone verrouillé reçoit la notification Compte courant en négatif, Ton compte courant est à -42,10 euros. Aux deux lectures suivantes, -85 et -20 euros, pas de nouvelle alerte : déjà prévenu. À 150 euros, l’alerte se réarme. Quatre lectures par jour au plus, la limite de la DSP2 pour les accès faits sans l’utilisateur." width="100%">

- **Une seule alerte par passage sous zéro.** Tant que le compte reste en négatif, les lectures suivantes se taisent ; dès qu'il remonte, l'alerte se réarme.
- **Toutes les six heures, même application fermée**, Android réveille une petite tâche de fond, seulement quand il y a du réseau. Elle lit **le solde, et lui seul**, quatre fois par jour au plus, la limite que la DSP2 accorde aux accès faits sans toi. Chaque synchronisation dans l'application fait la même comparaison.
- **Le montant se lit sur l'écran verrouillé** : c'est voulu, l'alerte doit se voir sans déverrouiller. La toucher ouvre SmartBudget, derrière l'empreinte.

**Le prix de l'alerte.** Pour lire le solde, la tâche de fond a besoin de la clé bancaire, donc de la clé maîtresse : elle est chargée sans empreinte, le temps de cette lecture, puis oubliée. C'est la seule exception à la règle « rien ne s'ouvre sans l'empreinte », et le modèle de confidentialité la compte parmi ce qui n'est pas protégé.

<details>
<summary><b>L'activer, la faire taire, l'arrêter</b></summary>

- **L'activer** : rien à faire. Dès que le compte est relié, la veille démarre, et Android 13 ou plus récent demande une fois la permission d'envoyer des notifications. Répondre **Autoriser**.
- **La faire taire** : Paramètres d'Android, Applications, Smart Budget, Notifications, puis couper la catégorie **« Compte en négatif »**. La veille continue de lire le solde, mais ne sonne plus.
- **L'arrêter complètement** : **Délier** la banque dans les réglages de SmartBudget. Plus aucune lecture ne se fait en arrière-plan.
- **La démo** n'a pas de banque, donc pas de veille ni de notification.

</details>

<a id="deplie"></a>
<img src="docs/sections/s09.png" alt="09 L'écran déplié" width="100%">

<img src="docs/schemas/volets.svg" alt="L’écran déplié. Une tablette avec son rail à gauche montre deux volets côte à côte. Sur l’analyse, l’anneau à gauche et les sorties à droite, toucher Logement pousse tout vers la gauche et ouvre Logement à droite ; puis Loyer ; puis l’opération Foncia Loyer. La ligne ouverte reste surlignée dans le volet de gauche. Le geste retour, un toucher vert qui file du bord droit vers la gauche, referme les volets un à un, jusqu’à l’analyse. À droite, la liste des pages ouvertes, Analyse, Logement, Loyer, Foncia Loyer, s’allonge puis se vide." width="100%">

Un écran de téléphone étiré sur huit pouces ne ressemble plus à rien. Sur le Fold ouvert, les pages forment une seule grande page dont on voit les deux derniers volets : on descend de l'analyse à l'opération sans jamais perdre d'où l'on vient, et le geste retour de Samsung referme le dernier volet. Chaque page tient d'un coup, sans défiler ; la fiche d'une opération ouverte seule passe en deux colonnes. Les saisies s'ouvrent dans une carte au-dessus du clavier, jamais dans une feuille qui monte du bas.

<a id="chiffrement"></a>
<img src="docs/sections/s10.png" alt="10 Chiffrement et sauvegarde" width="100%">

<img src="docs/schemas/chiffrement.svg" alt="Le chiffrement. L’empreinte charge la clé maîtresse de 32 octets depuis le Keystore Android. HKDF-SHA256 en dérive deux clés : l’une ouvre la base SQLCipher, l’autre chiffre en AES-GCM la clé privée d’Enable Banking. À part, la sauvegarde : une phrase choisie à l’export passe par PBKDF2 en 210 000 tours, et chiffre en AES-GCM un fichier .sbx relisible sur un autre téléphone. Hors de la veille du solde, qui la charge toutes les six heures le temps de lire le solde, la clé n’entre en mémoire qu’après l’empreinte." width="100%">

La clé maîtresse est tirée au hasard au premier lancement et ne quitte jamais le Keystore d'Android. Tout le reste en dérive : la base, et la clé privée d'Enable Banking, la donnée la plus sensible de l'application, puisqu'elle ouvre la lecture du compte. Elle vit chiffrée deux fois, par sa propre clé et dans une base elle-même chiffrée, et n'est déchiffrée que le temps d'une requête. La signature RS256 se fait en Dart, par pointycastle, et donne octet pour octet celle d'OpenSSL. **Tout effacer** détruit la clé d'abord, puis la base : même interrompu, rien de lisible ne reste.

<img src="docs/schemas/sauvegarde.svg" alt="La sauvegarde, entre deux téléphones animés. Sur ce téléphone, Réglages, Sauvegarde, Exporter, chiffré : la carte Phrase de la sauvegarde demande une phrase d’au moins huit caractères, deux fois, et prévient que sans elle personne ne peut relire le fichier, pas même toi. Les six tables, catégories, comptes, opérations, règles, liens et réglages, partent dans le fichier avec la version de la base, compressées puis chiffrées par la phrase. Le sélecteur du système enregistre smartbudget-2026-09-26.sbx dans les Téléchargements : Sauvegarde enregistrée. Le fichier voyage, par les Téléchargements, un ordinateur ou un nuage, et reste illisible sans la phrase. Sur un autre téléphone où l’appli vient d’être installée, Restaurer une sauvegarde : on choisit le fichier, on confirme Remplacer, car tout ce qui est dans l’application sera remplacé. Une phrase fausse donne Phrase incorrecte, ou fichier abîmé, et rien n’est touché. La bonne phrase passe les contrôles : l’en-tête SBEX1 et le MAC d’AES-GCM, une sauvegarde de Smart Budget d’une version connue, puis tout est remplacé d’un bloc, en une seule transaction. Sauvegarde restaurée : l’accueil affiche les mêmes 4 125,33 euros que l’ancien téléphone. La phrase ne se retrouve pas : perdue, la sauvegarde l’est aussi." width="100%">

Réglages, Sauvegarde, **Exporter, chiffré** : la phrase se tape deux fois, pour ne pas chiffrer avec une faute de frappe. Le fichier peut voyager n'importe où : sans la phrase, il est illisible. Sur un autre téléphone, **Restaurer une sauvegarde** remplace tout en une seule transaction ; une phrase fausse ne touche à rien. La clé bancaire, chiffrée par la clé maîtresse de l'ancien téléphone, ne s'y relit pas : elle est oubliée, et il suffit de la réimporter pour relier le compte.

<a id="confidentialite"></a>
<img src="docs/sections/s11.png" alt="11 Modèle de confidentialité" width="100%">

<img src="docs/schemas/confidentialite.svg" alt="Le modèle de confidentialité. Au centre, le téléphone ; le seul fil qui en sort va vers Enable Banking, puis vers la banque, en lecture seule, pour un accès de 180 jours ; rien ne part vers un serveur, un compte, de l’analytique ou de la publicité. Un regard curieux essaie chaque porte, et elles tiennent. Aucun serveur à moi : l’application ne parle qu’à Enable Banking, pour lire le compte. La base est chiffrée par SQLCipher ; sa clé vit dans le Keystore et n’est chargée qu’après l’empreinte, hors la veille du solde. La clé bancaire est chiffrée deux fois, en AES-GCM par une clé dérivée, dans une base elle-même chiffrée. La DSP2 ne donne que la lecture : aucun virement ne peut partir de l’application, et l’accès expire au bout de 180 jours. L’écran est protégé : captures bloquées, aperçu du multitâche masqué, sauvegarde Android refusée. Puis, honnêtement, ce qui reste ouvert. Enable Banking voit passer les opérations le temps de les transmettre : c’est l’agrégateur agréé qui lit la banque. L’application ouverte montre tout : l’empreinte protège l’accès, pas ton épaule. Une sauvegarde voyage et vaut ce que vaut sa phrase ; sans la phrase, elle est perdue, pour tout le monde. Perdre le téléphone, c’est perdre les données qui n’ont pas été sauvegardées : la clé ne se recopie nulle part. La veille du solde se passe d’empreinte : toutes les six heures, la clé est chargée le temps de lire le solde, et l’alerte montre le montant sur l’écran verrouillé. L’empreinte se coupe dans les réglages ; les données restent chiffrées, mais s’ouvrent sans preuve." width="100%">

<a id="architecture"></a>
<img src="docs/sections/s12.png" alt="12 Architecture" width="100%">

<img src="docs/schemas/stack.svg" alt="La pile de SmartBudget. En socle, Flutter 3 : l’application entière, en Dart, un seul code pour le téléphone et l’écran déplié. Dessus, cinq prises, ce que l’application sert, et chaque paquet s’empile sur la sienne. L’écran : flutter_riverpod pour l’état, une écriture fait relire tout ce qui en dépend, d’un seul appel ; go_router pour la navigation et la garde du verrou sur chaque page ; intl pour les dates et les montants à la française ; material_symbols_icons, cinq cents icônes arrondies comme l’interface. La base : sqflite_sqlcipher, SQLite chiffré par SQLCipher, schéma en version 6, migrations sans perte. La clé : flutter_secure_storage, la clé maîtresse dans le Keystore Android, jamais sur le disque en clair ; cryptography, HKDF pour dériver les clés, AES-GCM pour la clé bancaire et la sauvegarde, PBKDF2 pour la phrase ; local_auth, l’empreinte, qui charge la clé, sans elle la base reste illisible. La banque : pointycastle, la signature RS256 des requêtes, en Dart, octet pour octet celle d’OpenSSL. La veille : workmanager, la veille du solde toutes les six heures, même application fermée ; flutter_local_notifications, l’unique notification, le compte courant passé en négatif. Deux trajets les traversent. À l’ouverture, l’empreinte charge la clé, la clé ouvre la base, l’écran se remplit. Toutes les six heures, la veille charge la clé, signe sa requête, lit le solde à la banque, et prévient s’il passe en négatif." width="100%">

<img src="docs/schemas/couches.svg" alt="Les six couches de SmartBudget, traversées par une écriture, étape par étape. ecrans : lisent des providers, écrivent par des dépôts, jamais de SQL ; sur l’écran déplié, les pages deviennent des volets. providers : Riverpod, une écriture monte un numéro de version et tout ce qui lit la base se relit, d’un seul appel. domaine : du Dart pur, testé sans appareil, qui lit un libellé, reconnaît un virement interne, classe, détecte les récurrences et fait le bilan. donnees : le seul endroit où s’écrit du SQL, avec les dépôts, le schéma et ses migrations, la sauvegarde et le jeu d’essai. security : le trousseau, clé maîtresse dans le Keystore, dérivations HKDF, verrou ; rien ne lit un fichier en passant outre. smartbudget.db : SQLite chiffré par SQLCipher, schéma en version 6. banque : Enable Banking, JWT signé, session, opérations, solde ; la clé privée n’est déchiffrée que le temps d’un appel ; elle est hors de ce trajet. Sur le téléphone, l’écran Associer à un remboursement du concert de 90 euros : on a coché le virement de Camille Roux pour 45 euros, la remise de chèque, déjà entièrement affectée ailleurs, reste grisée ; le récapitulatif dit 1 sélectionné, 45 euros, reste 45 euros. En vert, l’écriture qui descend : 1, toucher Valider 1 remboursement ; 2, ecrans appelle DepotLiens().rembourserPar() dans donnees, sans passer par providers ni domaine, grisés ; 3, donnees tient de security la clé de la base ; 4, dans une transaction, les liens du concert sont remplacés dans smartbudget.db : DELETE, puis INSERT INTO liens. En bleu, la relecture qui remonte : 5, ecrans appelle rafraichir(ref), et la version de providers monte d’un cran ; 6, providers relit par DepotBilan.du, qui fait un SELECT dans smartbudget.db ; 7, donnees passe le mois à calculerBilan() dans domaine ; 8, providers rend la nouvelle valeur à ecrans, et la fiche du concert se redessine : 45 euros reçus (1). Un écran n’écrit jamais de SQL, et rien n’ouvre la base sans passer par le trousseau." width="100%">

<img src="docs/schemas/modele.svg" alt="Le modèle de données de SmartBudget : six tables dans une base chiffrée par SQLCipher, au schéma en version 6. operations, 18 colonnes : id ; compte_id, vers comptes ; uid_banque, unique, pour que rien ne se double ; le, le jour de l’opération ; libelle, tel que la banque l’écrit ; montant_centimes, un entier, jamais un flottant ; categorie_id, vers categories ; origine, à la main, règle, dictionnaire, interne ou par défaut ; nature, vide pour suivre celle de sa catégorie ; mois_compte, pour la rattacher à un autre mois ; nom et note, choisis à la main ; masquee, hors de l’analyse ; recurrente, vide quand la détection décide ; interne, vers l’épargne, depuis l’épargne ou entre comptes ; pointee et especes, vérifiée et payée en liquide ; en_attente, pas encore comptabilisée. categories, 10 colonnes : id ; parent_id, pour une sous-catégorie ; nom, icone et couleur, ce qui se voit ; genre, dépense, revenu, épargne ou interne ; nature, essentiel, plaisir ou imprévu ; budget_centimes, son budget s’il en a un ; ordre, sa place dans la liste. comptes, 9 colonnes : id ; nature, courant, livret ou portefeuille ; nom et iban_fin ; uid_banque, le compte chez la banque ; solde_centimes, au dernier relevé, et solde_le, sa date ; motif, son nom dans les virements ; cree_le. liens : entree_id, le remboursement ; depense_id, la dépense remboursée ; montant_centimes, la part qui lui revient. regles : id ; motif, le marchand appris, unique ; categorie_id, où il va désormais. reglages : cle et valeur, pour le budget, l’épargne, debut_mois, le jour habituel du salaire, qui n’est qu’un repère, et debut_mois_auto, s’il est trouvé tout seul, les clés banque_ pour la clé chiffrée, la banque et la fin de l’accès, les choix par marchand en repetition: et nom:, et alerte_negatif. Les clés étrangères se tracent : operations.compte_id vers comptes, operations.categorie_id vers categories, categories.parent_id vers categories, liens.entree_id et liens.depense_id vers operations, regles.categorie_id vers categories. Puis une opération d’exemple se remplit colonne par colonne : id 1287, compte 1, le compte courant, le 20 septembre 2026, CB FNAC SPECTACLES 19/09, -9000 centimes, catégorie 164, Cinéma et concerts sous Loisirs, classée par le dictionnaire, nommée Concert ; son remboursement ajoute à liens la ligne 1262, Camille Roux, vers 1287, pour 4500 centimes, et la fiche montre 45 euros rendus, la dépense ne pesant plus que 45 euros. Le schéma garantit des centimes plutôt que des flottants, une paire entrée et dépense liée une seule fois, la suppression en cascade des opérations d’un compte et des liens d’une opération, et des migrations sans perte jusqu’à la version 6." width="100%">

Les montants sont des entiers, en centimes : jamais un flottant ne touche à l'argent. Le domaine ne connaît ni Flutter ni la base, ce qui le rend testable sans appareil.

<a id="tests"></a>
<img src="docs/sections/s13.png" alt="13 Les tests" width="100%">

<img src="docs/schemas/tests.svg" alt="Les tests, lancés un à un. Un compteur monte de 0 à 95 et un ruban de 95 cases passe au vert : d’abord les 33 tests de logique pure, sans appareil, par flutter test, puis les 62 qui tournent sur un émulateur Android, où SQLCipher et le Keystore existent, par flutter test integration_test. Les 95 finissent au vert. Chaque famille s’allume quand passe un test qui la vérifie. Libellés : le marchand sort du bruit de la banque, et sa clé ne change pas d’un mois à l’autre. Virements internes : vers le livret, depuis le livret, un livret au nom inhabituel, et un virement à quelqu’un qui n’en est pas un. Récurrences : un abonnement mensuel reconnu avec sa prochaine date, des courses irrégulières qui n’en sont pas. Classement : le dictionnaire, les corrections apprises et suivies, et une synchronisation relancée qui ne double rien. Bilan : remboursements répartis, remboursement marchand, dépense en espèces retirée des retraits. Portefeuille : 50 euros comptés, un retrait de 20 euros, 12 euros au marché, il en reste 58. Mois budgétaire : chaque salaire ouvre son mois, même en avance pour Noël, une prime n’en ouvre aucun, et les espèces d’un retrait comptent une seule fois. Sauvegarde : tout revient avec la bonne phrase, une phrase fausse ne touche à rien. Signature : le JWT signé en Dart est, octet pour octet, celui d’OpenSSL. Remboursements : six virements pour une dépense, lier dans les deux sens, jamais au-delà, même avec deux écritures au même instant. Synchronisations : attentes qui passent, changent de montant ou sont levées, un an d’historique, rien ne double, rien ne se perd. Jamais figée : chaque test borne ses accès à la base dans le temps, un verrou mort ferait échouer la suite au lieu de la geler. Sur appareil : 95 tests, 33 sur la logique pure, 62 sur un émulateur Android." width="100%">

SQLCipher et le Keystore n'existent que sur un appareil : les tests d'intégration tournent sur un émulateur, jamais sur le téléphone qui porte les vrais comptes, car ils effacent la base.

```
flutter test                                   # la logique pure
flutter test integration_test -d emulator-5554 # la base chiffrée, sur un émulateur
```

<a id="versions"></a>
<img src="docs/sections/s14.png" alt="14 Les versions" width="100%">

<img src="docs/schemas/versions.svg" alt="Les versions, onze en sept jours, du jeudi 24 au mercredi 30 septembre 2026, empilées l’une sur l’autre : chacune tombe sur la précédente, comme elle s’installe par-dessus sur le téléphone, sans rien perdre. En bas, le socle ne bouge pas : tes données, comptes, opérations, catégories, règles apprises et liens, et la même clé de signature, certificat SHA-256 55572db2…fabcbef ; un fil monte de la clé et scelle chaque version. Le 24 septembre, 1.0.0, la première version : reliée au Crédit Mutuel de Bretagne par Enable Banking, classement, virements internes, remboursements, récurrences, base chiffrée et écran déplié en volets. 1.0.1, un correctif : le bon numéro de version dans les réglages, qui affichaient encore 0.1.0. 1.0.2 : un groupe d’icônes Sorties et loisirs, grande roue, fête foraine, billets, cinéma, séparé du Sport. 1.0.3 : l’alerte de compte en négatif, le solde relu toutes les six heures, même application fermée, une notification par passage sous zéro. 1.1.0 : la démo, une seconde application installée à côté de la vraie, avec quatre mois d’opérations inventées, sans banque ni empreinte. Le 25 septembre, 1.2.0 : toutes les banques d’Enable Banking, par nom ou par pays, une page guide pour obtenir la clé, les opérations en attente et la synchronisation à chaque ouverture. Le 26 septembre, 1.2.2, l’audit complet : lier un remboursement ne gèle plus l’application, elle se reverrouille après un passage en arrière-plan, la synchronisation garde les liens des opérations en attente, plus de règle apprise sur le « N » d’un chèque, montants nets partout et récurrences justes sur les mois passés, la fiche d’une opération entière sur l’écran déplié. Le 27 septembre, 1.2.3, le mois suit le salaire : le mois commence tout seul le jour où le salaire arrive, et les espèces retirées un mois et dépensées le suivant ne comptent plus deux fois. Le 29 septembre, 1.2.4, plusieurs remboursements : une dépense remboursée par plusieurs virements, six amis à 23 euros chacun, avec des cases à cocher et ce qui reste à couvrir sous les yeux. Le même jour, 1.2.5 : l’écran extérieur du Fold reste en portrait, comme un téléphone, et l’écran intérieur tourne toujours librement. Le 30 septembre, 1.2.6, la version en cours, chaque salaire, son mois : chaque salaire ouvre son mois, même versé en avance pour Noël ; un mois qui s’ouvre dans la première quinzaine porte le nom de ce mois-là ; l’accueil n’est plus coupé en deux après un verrouillage pendant une saisie ; les récurrences payées disent « 3 fois, le 10 » plutôt que de répéter le jour ; les opérations déjà liées sortent d’À vérifier, dont le bouton dit « Interne » ; la fenêtre de l’empreinte a tous ses textes, sous le titre SmartBudget. 95 tests, tous au vert." width="100%">

Chaque Release, avec ses notes et ses empreintes SHA-256 : [github.com/Cybertrist/SmartBudget/releases](https://github.com/Cybertrist/SmartBudget/releases).

<a id="licence"></a>
<img src="docs/sections/s15.png" alt="15 Licence et auteur" width="100%">

Le code est publié sous licence [MIT](LICENSE) : libre de le lire, de le reprendre et de le modifier, à condition de garder la mention de copyright. La police Figtree est sous licence SIL Open Font, les icônes Material Symbols sous licence Apache 2.0.

Conçu et écrit par **Tristan Joncour**, élève ingénieur en cyberdéfense à l'ENSIBS, pour tenir ses propres comptes. Le socle de sécurité, empreinte, trousseau et chiffrement, vient de son autre application, [BodyCount](https://github.com/Cybertrist/BodyCount).

**Ce qui ne sera jamais dans ce dépôt :** la clé privée d'Enable Banking, la clé de signature de l'APK, et la moindre donnée bancaire réelle. `.gitignore` refuse les fichiers `.pem`, `.p12`, `.jks` et `key.properties`.

<br>

<sub>Les images de cette page ne sortent d'aucun logiciel de dessin : ce sont des pages HTML que Chrome capture, et vingt-trois SVG animés écrits par <code>anime.js</code> et les modules de <code>schemas/</code>. Les captures viennent d'un émulateur rempli par le jeu d'essai, rognées par <code>rogner.js</code>. Tout est dans <a href="docs/tools/">docs/tools</a>.</sub>

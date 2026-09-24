# Les outils qui dessinent ce README

Aucune image de ce dépôt ne sort d'un logiciel de dessin. Les figures fixes
sont des pages HTML que Chrome capture sans affichage, deux fois plus
denses que leur taille à l'écran ; les schémas animés sont des SVG écrits
par un script. Changer un texte, c'est changer une ligne.

## Refaire les images

    bash docs/tools/figures.sh     # bannière, bandeaux, grilles, couches, modèle, bouton
    bash docs/tools/captures.sh    # les deux planches de captures
    node docs/tools/anime.js       # les cinq schémas animés
    bash docs/tools/social.sh      # l'aperçu social (JPEG), à déposer dans Settings > Social preview

Chaque commande fait la version française, puis l'anglaise dans `docs/en/`.

## Ce que fait chaque fichier

- `rendu.sh` : le moteur commun. La page écrit sa hauteur réelle dans son
  `<title>` une fois les polices chargées, `--dump-dom` la lit, la capture
  suit à cette hauteur. `--virtual-time-budget` est indispensable, sinon
  Chrome capture avant l'arrivée des polices.
- `figures.sh` : tout le texte des figures fixes. C'est le seul fichier à
  ouvrir pour corriger une phrase.
- `captures.sh` : les planches du téléphone et de l'écran déplié, à partir
  de `src-captures/`.
- `rogner.js` : prépare les captures brutes de l'émulateur. Il retire la
  barre d'état et la barre de navigation d'après un `barres.txt` posé à
  côté, réduit et écrit en JPEG, par un canvas de Chrome. Repris de
  BodyCount.
- `anglais.json` : la traduction de chaque texte des figures et des schémas.
  Un texte absent du dictionnaire arrête le rendu anglais et s'affiche :
  aucune figure anglaise ne garde une phrase française par oubli.
- `traduire.js` : applique `anglais.json` à une page, appelé par `rendu.sh`
  quand `LANGUE=en`.
- `jpeg.js` : convertit l'aperçu social en JPEG, sous le mégaoctet de GitHub.
- `anime.js` : les SVG animés, la connexion à la banque, la lecture d'une
  opération, les virements, remboursements et espèces, le chiffrement et
  l'écran déplié. Les animations sont en SMIL, que GitHub joue dans une
  balise `<img>`. Pas de police externe : un SVG en `<img>` n'a pas le droit
  d'aller la chercher.

## Les captures

Elles viennent de l'émulateur, remplies par le jeu d'essai
(`--dart-define=ESSAIS=true`, puis Réglages, Remplir avec un jeu d'essai),
dans une version de débogage : la version publiée bloque les captures
d'écran. Aucun vrai montant ne doit jamais entrer dans `src-captures/`.

Le téléphone est l'émulateur à sa taille d'origine ; l'écran déplié se
simule par `adb shell wm size 2184x1650` et `adb shell wm density 420`.

## Ce dont ils dépendent

Chrome, cherché dans `C:\Program Files\Google\Chrome\Application` ; la
variable `CHROME` prend le dessus. Les polices, Syne, Space Grotesk,
JetBrains Mono et Material Symbols, viennent de Google Fonts au moment du
rendu : il faut une connexion.

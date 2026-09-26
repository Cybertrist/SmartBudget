// Les six couches de l'application, traversées par une écriture.
//
// À gauche, le téléphone : sur « Associer à un remboursement », le
// virement de Camille Roux est choisi, et le doigt touche « Valider ». Au
// milieu, les couches et la base, en une colonne. Des flèches numérotées
// vont d'une carte à l'autre dans l'ordre du code : en vert, à gauche,
// l'écriture qui descend ; en bleu, à droite, la relecture qui remonte.
// La bille suit chaque flèche, qui reste tracée : à la fin, tout le trajet
// se lit d'un coup. providers/ et domaine/ sont grisés pendant la
// descente, que l'écran fait sans eux ; banque/ reste hors du trajet.
//
// Tout suit le code : EcranChoisirRemboursement._valider appelle
// DepotLiens().rembourser (donnees/depots.dart), dont la base ne s'ouvre
// qu'avec la clé du KeyVault (donnees/base.dart), puis rafraichir(ref)
// monte versionProvider (providers/donnees.dart) ; bilanProvider relit par
// DepotBilan.du, qui passe le mois à calculerBilan (domaine/bilan.dart).
module.exports = (O) => {
  const { svg, t, visible, fondu, toucher, P, APP, MONO, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, VERT, NEON, BLEU, OR, ROSE, INTERNE } = O;
  const C = 24;
  const VIOLET = '#B08CFF';
  let corps = '';
  corps += t(60, 52, 'LES COUCHES', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + O.tr('LES COUCHES').length * 10.9 + 24), 52, 'Une écriture fait tout relire : toucher « Valider » descend jusqu’à la base, puis la relecture remonte jusqu’à l’écran.', { taille: 14 });

  // Les instants du cycle.
  const TAP = 0.07;          // le doigt touche « Valider »
  const POP = 0.53;          // l'écriture faite, la fiche revient
  const REDESSIN = 0.885;    // la fiche relue se redessine
  const FIN = 0.975;

  // ---------------------------------------------------------------- téléphone
  const PX = 60, PY = 88, PL = 316, PH = 640;
  const SX = PX + 12, SY = PY + 16, SL = PL - 24, SH = PH - 32;
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="40" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranCouches"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 34}" y="${PY + 6}" width="68" height="5" rx="2.5" fill="#1B222C"/>`;
  const ecran = (de, a, contenu) => `<g opacity="0">${visible(C, de, a, 0.004)}${contenu}</g>`;
  const barre = (titre, taille = 17) =>
    t(SX + 18, SY + 46, '‹', { taille: 24, couleur: APP.texte }) + t(SX + 38, SY + 46, titre, { taille, couleur: APP.texte, poids: 800 });
  const carteApp = (y, h) => `<rect x="${SX + 12}" y="${SY + y}" width="${SL - 24}" height="${h}" rx="16" fill="${APP.carte}"/>`;
  const surtitre = (y, s) => t(SX + 28, SY + y, s, { taille: 10.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.5"' });
  const icone = (y, dessin) => `<rect x="${SX + 26}" y="${SY + y - 14}" width="28" height="28" rx="9" fill="#FFFFFF" fill-opacity="0.05"/>
    <g transform="translate(${SX + 30},${SY + y - 10}) scale(0.72)">${dessin(APP.second)}</g>`;
  const ligne = (y, dessin, libelle, valeur, couleur = APP.second) => `${icone(y, dessin)}
    ${t(SX + 64, SY + y + 4.5, libelle, { taille: 13, couleur: APP.texte, poids: 600 })}
    ${t(SX + SL - 40, SY + y + 4.5, valeur, { taille: 12.5, couleur, poids: 700, ancre: 'end' })}
    ${t(SX + SL - 26, SY + y + 5, '›', { taille: 15, couleur: APP.discret, ancre: 'middle' })}`;
  const sep = (y) => `<line x1="${SX + 26}" y1="${SY + y}" x2="${SX + SL - 26}" y2="${SY + y}" stroke="${APP.trait}"/>`;
  const note = (c) => `<path d="M11 21 V7 L22 5 V18" fill="none" stroke="${c}" stroke-width="2.2" stroke-linejoin="round"/><circle cx="8" cy="21" r="3.2" fill="${c}"/><circle cx="19" cy="18" r="3.2" fill="${c}"/>`;
  const echange = (c) => `<path d="M5 10 H21 L17 6 M23 18 H7 L11 22" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`;
  const oeil = (c) => `<path d="M3 14 C7 7 21 7 25 14 C21 21 7 21 3 14 Z M6 5 L22 23" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"/>`;
  const etiquette = (c) => `<path d="M4 6 H15 L24 14 L15 22 H4 Z" fill="none" stroke="${c}" stroke-width="2.2" stroke-linejoin="round"/><circle cx="9" cy="14" r="1.8" fill="${c}"/>`;

  // A : « Associer à un remboursement », Camille Roux choisie.
  const entrees = [
    ['Vendredi 25 septembre', 'Salaire', 'Salaire', '+1 850,00 €'],
    ['Lundi 14 septembre', 'Camille Roux', 'Virements reçus', '+45,00 €'],
  ];
  const choisir = (enCours) => {
    let s = `${barre('Associer à un remboursement', 15)}
      ${['Pour « Concert », 90,00 €. Choisis l’argent reçu', 'qui la rembourse, avant ou après l’achat.'].map((l, i) => t(SX + 22, SY + 78 + i * 17, l, { taille: 12, couleur: APP.second })).join('')}`;
    entrees.forEach(([jour, nom, sous, montant], i) => {
      const y = 136 + i * 96;
      s += `${t(SX + 22, SY + y, jour, { taille: 12, couleur: APP.second, poids: 700 })}
        ${carteApp(y + 10, 62)}
        ${t(SX + 56, SY + y + 37, nom, { taille: 13.5, couleur: APP.texte, poids: 700 })}
        ${t(SX + 56, SY + y + 55, sous, { taille: 10.5, couleur: APP.discret })}
        ${t(SX + SL - 26, SY + y + 45, montant, { taille: 13, couleur: VERT, poids: 700, ancre: 'end' })}`;
      s += i === 1
        ? `<rect x="${SX + 12}" y="${SY + y + 10}" width="${SL - 24}" height="62" rx="16" fill="${VERT}" fill-opacity="0.08" stroke="${VERT}" stroke-opacity="0.6"/>
          <circle cx="${SX + 36}" cy="${SY + y + 41}" r="10" fill="${VERT}"/>
          <path d="M${SX + 31} ${SY + y + 41} l3.5 3.5 l6.5 -7" fill="none" stroke="#000000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`
        : `<circle cx="${SX + 36}" cy="${SY + y + 41}" r="8.5" fill="none" stroke="${APP.discret}" stroke-width="2"/>`;
    });
    // Le bouton, grisé tant que l'écriture n'est pas revenue.
    s += `<g opacity="${enCours ? 0.4 : 1}"><rect x="${SX + 14}" y="${SY + SH - 68}" width="${SL - 28}" height="48" rx="24" fill="${VERT}"/>
      ${t(SX + SL / 2, SY + SH - 39, 'Valider', { taille: 14.5, couleur: '#000000', poids: 800, ancre: 'middle' })}</g>`;
    if (enCours) {
      s += `<circle cx="${SX + SL / 2}" cy="${SY + SH - 100}" r="9" fill="none" stroke="${VERT}" stroke-width="2.4" stroke-dasharray="40 17">
        <animateTransform attributeName="transform" type="rotate" from="0 ${SX + SL / 2} ${SY + SH - 100}" to="360 ${SX + SL / 2} ${SY + SH - 100}" dur="0.9s" repeatCount="indefinite"/></circle>`;
    }
    return s;
  };
  // B et C : la fiche du concert, avant puis après la relecture.
  const fiche = (lie) => `${barre('Concert')}
    <rect x="${SX + SL / 2 - 22}" y="${SY + 64}" width="44" height="44" rx="14" fill="#C6F45A" fill-opacity="0.16" stroke="#C6F45A" stroke-opacity="0.45"/>
    <g transform="translate(${SX + SL / 2 - 14},${SY + 72})">${note('#C6F45A')}</g>
    ${t(SX + SL / 2, SY + 142, '-90,00 €', { taille: 28, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(SX + SL / 2, SY + 164, 'Concert', { taille: 13.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}
    ${t(SX + SL / 2, SY + 182, 'Dimanche 20 septembre 2026 · Compte courant', { taille: 10.5, couleur: APP.discret, ancre: 'middle' })}
    ${carteApp(196, 120)}
    ${surtitre(218, 'CLASSEMENT')}
    ${ligne(246, echange, 'Mouvement', 'Dépense')}
    ${sep(268)}
    ${ligne(290, etiquette, 'Catégorie', 'Loisirs › Ciné…', '#C6F45A')}
    ${carteApp(326, 120)}
    ${surtitre(348, 'SUIVI')}
    ${ligne(376, P.horloge, 'Répétition', 'Aucune')}
    ${sep(398)}
    ${icone(420, oeil)}
    ${t(SX + 64, SY + 424.5, 'Masquer de l’analyse', { taille: 13, couleur: APP.texte, poids: 600 })}
    <rect x="${SX + SL - 70}" y="${SY + 409}" width="42" height="22" rx="11" fill="#2A2A2A" stroke="#555555"/>
    <circle cx="${SX + SL - 59}" cy="${SY + 420}" r="6.5" fill="#8A8A8A"/>
    ${carteApp(456, lie ? 92 : 58)}
    ${ligne(485, P.lien, 'Remboursement', lie ? '45,00 € reçus' : 'Aucun', lie ? VERT : APP.second)}
    ${lie ? t(SX + 28, SY + 530, 'Elle ne compte plus que pour 45,00 €.', { taille: 12, couleur: APP.discret }) : ''}`;
  let ecrans = '';
  ecrans += ecran(0, TAP + 0.03, choisir(false) + toucher(SX + SL / 2, SY + SH - 44, C, TAP));
  ecrans += ecran(TAP + 0.03, POP, choisir(true));
  ecrans += ecran(POP, REDESSIN, fiche(false));
  ecrans += ecran(REDESSIN, FIN, `${fiche(true)}
    <rect x="${SX + 12}" y="${SY + 456}" width="${SL - 24}" height="92" rx="16" fill="none" stroke="${VERT}" stroke-opacity="0.7" filter="url(#halo)"/>`);
  corps += `<g clip-path="url(#ecranCouches)">${ecrans}</g>`;

  // ------------------------------------------------------------------ couches
  // Une colonne de cartes ; l'écriture passe à gauche, entre le téléphone et
  // les cartes, la relecture à droite. Chaque flèche va d'une carte à une
  // autre et ne coupe jamais un texte.
  const KX = 600, KL = 360, KY = 88, ECART = 20;
  const hCarte = (n) => 62 + (n - 1) * 17;
  const couches = [
    { cle: 'ecrans', nom: 'ecrans/', c: NEON, regle: ['Lisent des providers, écrivent par des dépôts,', 'jamais de SQL. Sur l’écran déplié, les pages', 'deviennent des volets.'] },
    { cle: 'providers', nom: 'providers/', c: BLEU, regle: ['Riverpod. Une écriture monte un numéro', 'de version : tout ce qui lit la base se relit,', 'd’un seul appel.'] },
    { cle: 'domaine', nom: 'domaine/', c: OR, regle: ['Du Dart pur, testé sans appareil : lire un libellé,', 'reconnaître un virement interne, classer, détecter', 'les récurrences, faire le bilan.'] },
    { cle: 'donnees', nom: 'donnees/', c: ROSE, regle: ['Le seul endroit où s’écrit du SQL : les dépôts,', 'le schéma et ses migrations, la sauvegarde,', 'le jeu d’essai.'] },
    { cle: 'security', nom: 'security/', c: VIOLET, regle: ['Le trousseau : clé maîtresse dans le Keystore,', 'dérivations HKDF, verrou. Rien ne lit un fichier', 'en passant outre.'] },
    { cle: 'base', nom: 'smartbudget.db', c: INTERNE, regle: ['SQLite chiffré par SQLCipher, schéma en version 6.'] },
    { cle: 'banque', nom: 'banque/', c: VERT, regle: ['Enable Banking : JWT signé, session, opérations,', 'solde. La clé privée n’est déchiffrée que le', 'temps d’un appel.'] },
  ];
  let yc = KY;
  const K = {};
  for (const k of couches) {
    k.h = hCarte(k.regle.length);
    k.y = yc;
    yc += k.h + ECART;
    K[k.cle] = k;
  }

  // Des pictogrammes dans une grille de 28, dessinés en traits.
  const trait = (c) => `fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"`;
  const I = {
    ecrans: (c) => `<g ${trait(c)}><rect x="3" y="3" width="10" height="13" rx="2.5"/><rect x="15" y="3" width="10" height="7" rx="2.5"/><rect x="15" y="12" width="10" height="13" rx="2.5"/><rect x="3" y="18" width="10" height="7" rx="2.5"/></g>`,
    providers: (c) => `<g ${trait(c)}><rect x="2" y="3" width="10" height="8" rx="2.5"/><rect x="16" y="3" width="10" height="8" rx="2.5"/><rect x="16" y="17" width="10" height="8" rx="2.5"/><path d="M12 7 H16 M14 7 V21 H16"/></g>`,
    domaine: (c) => `<path d="M21 5 H7 L15 14 L7 23 H21" ${trait(c)}/>`,
    donnees: (c) => `<g ${trait(c)}><rect x="3" y="3" width="22" height="6" rx="2"/><rect x="3" y="11" width="22" height="6" rx="2"/><rect x="3" y="19" width="22" height="6" rx="2"/></g><circle cx="7" cy="6" r="1.3" fill="${c}"/><circle cx="7" cy="14" r="1.3" fill="${c}"/><circle cx="7" cy="22" r="1.3" fill="${c}"/>`,
    security: (c) => `<g ${trait(c)}><path d="M14 2 L24 6 V13 C24 19 19.5 23.5 14 26 C8.5 23.5 4 19 4 13 V6 Z"/><rect x="10" y="13" width="8" height="6.5" rx="1.5"/><path d="M11.5 13 V11 A2.5 2.5 0 0 1 16.5 11 V13"/></g>`,
    base: P.base,
    banque: P.banque,
  };

  // Les étapes, dans l'ordre du code. [de, a] : le temps que met la bille.
  const E1 = [TAP + 0.005, 0.11], E2 = [0.13, 0.21], E3 = [0.24, 0.3], E4 = [0.33, 0.41];
  const E5 = [0.47, 0.52], E6a = [0.56, 0.62], E6b = [0.62, 0.67], E7 = [0.7, 0.76], E8a = [0.79, 0.83], E8b = [0.845, REDESSIN];

  // Les cartes, allumées quand une bille y arrive.
  const allume = {
    ecrans: [[E1[1], E2[0] + 0.02], [E5[0] - 0.02, E5[0] + 0.01], [E8a[1], E8b[0] + 0.01]],
    donnees: [[E2[1], E4[0] + 0.01], [E6a[1], E7[0] + 0.01]],
    security: [[E3[1], E3[1] + 0.05]],
    base: [[E4[1], E4[1] + 0.06], [E6b[1], E6b[1] + 0.03]],
    providers: [[E5[1], E6a[0] + 0.01], [E7[1], E8a[0] + 0.01]],
    domaine: [[E7[1], E7[1] + 0.05]],
    banque: [],
  };
  for (const k of couches) {
    const x = KX, y = k.y, h = k.h;
    corps += `<rect x="${x}" y="${y}" width="${KL}" height="${h}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${y + 14}" width="3" height="${h - 28}" rx="1.5" fill="${k.c}"/>
      <g transform="translate(${x + 16},${y + 11}) scale(0.82)">${I[k.cle](k.c)}</g>
      ${t(x + 50, y + 29, k.nom, { taille: 14.5, couleur: k.cle === 'base' ? TITRE : k.c, police: MONO, poids: 700 })}
      ${k.regle.map((l, i) => t(x + 20, y + 52 + i * 17, l, { taille: 12.5 })).join('')}`;
    for (const [de, a] of allume[k.cle]) {
      corps += `<rect x="${x}" y="${y}" width="${KL}" height="${h}" rx="13" fill="${k.c}" fill-opacity="0.05" stroke="${k.c}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, de, a, 0.006)}</rect>
        <g opacity="0">${visible(C, de, a, 0.006)}${k.regle.map((l, i) => t(x + 20, y + 52 + i * 17, l, { taille: 12.5, couleur: TITRE })).join('')}</g>`;
    }
  }
  // Pendant la descente, providers/ et domaine/ restent à l'écart : grisés.
  for (const cle of ['providers', 'domaine']) {
    corps += `<rect x="${KX}" y="${K[cle].y}" width="${KL}" height="${K[cle].h}" rx="13" fill="${FOND}" opacity="0">${fondu('opacity', C, [[0, 0], [E1[0], 0], [E1[0] + 0.01, 0.62], [E5[0] - 0.01, 0.62], [E5[0], 0], [1, 0]])}</rect>`;
  }
  // La banque, toujours à l'écart.
  corps += `<rect x="${KX}" y="${K.banque.y}" width="${KL}" height="${K.banque.h}" rx="13" fill="${FOND}" opacity="0.62"/>`;
  {
    const s = 'hors de ce trajet', l = Math.round(O.tr(s).length * 6.9 + 24);
    corps += `<rect x="${KX + KL - 16 - l}" y="${K.banque.y + 14}" width="${l}" height="24" rx="12" fill="${CARTE}" stroke="${DISCRET}" stroke-opacity="0.8"/>
      ${t(KX + KL - 16 - l / 2, K.banque.y + 30.5, s, { taille: 11.5, couleur: TEXTE, police: MONO, poids: 700, ancre: 'middle' })}`;
  }

  // --------------------------------------------------------------- flèches
  // Une cubique de A à B ; sa longueur et ses points, calculés ici.
  const bez = (p, u) => {
    const v = 1 - u;
    return [0, 1].map((i) => v * v * v * p[0][i] + 3 * v * v * u * p[1][i] + 3 * v * u * u * p[2][i] + u * u * u * p[3][i]);
  };
  const longueur = (p) => {
    let l = 0, a = p[0];
    for (let i = 1; i <= 60; i++) { const b = bez(p, i / 60); l += Math.hypot(b[0] - a[0], b[1] - a[1]); a = b; }
    return Math.ceil(l);
  };
  const r1 = (n) => Math.round(n * 10) / 10;
  // Un arc qui quitte le bord d'une carte et revient sur le bord d'une autre,
  // bombé jusqu'à [sommet] ; ou une ligne presque droite.
  const arc = (x, y1, y2, sommet) => {
    const xc = x + (sommet - x) / 0.75;
    return [[x, y1], [xc, y1], [xc, y2], [x, y2]];
  };
  const droit = (x1, y, x2) => [[x1, y], [x1 + (x2 - x1) / 3, y], [x1 + 2 * (x2 - x1) / 3, y], [x2, y]];

  const G = KX, D = KX + KL; // les bords gauche et droit des cartes
  const PD = PX + PL;        // le bord droit du téléphone
  const Ky = (cle, f) => K[cle].y + f;
  // [numéro, points, couleur, [de, a], étiquette (une ou deux lignes), où la poser (0..1)]
  const fleches = [
    ['1', droit(PD + 2, Ky('ecrans', 18), G - 2), NEON, E1, ['toucher Valider'], 0.5],
    ['2', arc(G - 2, Ky('ecrans', 82), Ky('donnees', 20), 488), NEON, E2, ['DepotLiens().rembourser()'], 0.5],
    ['3', arc(G - 2, Ky('donnees', 70), Ky('security', 40), 530), NEON, E3, ['la clé de', 'la base'], 0.5],
    ['4', arc(G - 2, Ky('donnees', 44), Ky('base', 31), 430), NEON, E4, ['INSERT INTO liens'], 0.75],
    ['5', arc(D + 2, Ky('ecrans', 84), Ky('providers', 16), 1058), BLEU, E5, ['rafraichir(ref)', 'version + 1'], 0.5],
    ['6', arc(D + 2, Ky('providers', 70), Ky('donnees', 24), 1178), BLEU, E6a, ['DepotBilan.du'], 0.5],
    ['6', arc(D + 2, Ky('donnees', 78), Ky('base', 31), 1110), BLEU, E6b, ['SELECT'], 0.5],
    ['7', arc(D + 2, Ky('donnees', 8), Ky('domaine', 40), 1058), BLEU, E7, ['calculerBilan()'], 0.5],
    ['8', arc(D + 2, Ky('providers', 44), Ky('ecrans', 56), 1168), BLEU, E8a, [], 0.5],
    ['8', droit(G - 2, Ky('ecrans', 52), PD + 2), BLEU, E8b, ['la fiche se redessine :', '45,00 € reçus'], 0.5],
  ];
  let traits = '', billes = '', etiquettes = '';
  for (const [n, p, c, [de, a], lignes, ou] of fleches) {
    const d = `M${p.map((q) => q.map(r1).join(' ')).join(' ').replace(/^(\S+ \S+) /, '$1 C')}`;
    const l = longueur(p);
    // Le trait se dessine derrière la bille, puis reste jusqu'à la fin.
    traits += `<path d="${d}" fill="none" stroke="${c}" stroke-width="3.5" stroke-linecap="round" stroke-dasharray="${l}" stroke-dashoffset="${l}" opacity="0">
      ${fondu('stroke-dashoffset', C, [[0, l], [de, l], [a, 0], [1, 0]])}${visible(C, de, FIN, 0.004)}</path>`;
    // La pointe, orientée comme la fin de la courbe.
    const [x2, y2] = p[3], [xa, ya] = bez(p, 0.97);
    const ang = Math.atan2(y2 - ya, x2 - xa) * 180 / Math.PI;
    traits += `<g opacity="0">${visible(C, a - 0.004, FIN, 0.004)}<path transform="translate(${r1(x2)},${r1(y2)}) rotate(${r1(ang)})" d="M-11 -7 L1 0 L-11 7 Z" fill="${c}"/></g>`;
    // La bille.
    billes += `<g filter="url(#halo)" opacity="0">${visible(C, de, a, 0.003)}
      <circle r="11" fill="${c}" opacity="0.25"><animateMotion dur="${C}s" repeatCount="indefinite" path="${d}" keyPoints="0;0;1;1" keyTimes="0;${de};${a};1" calcMode="linear"/></circle>
      <circle r="6.5" fill="${c}"><animateMotion dur="${C}s" repeatCount="indefinite" path="${d}" keyPoints="0;0;1;1" keyTimes="0;${de};${a};1" calcMode="linear"/></circle></g>`;
    // Le numéro dans sa pastille, et l'étiquette posée sur la flèche.
    const [cx, cy] = bez(p, ou);
    const larg = lignes.length ? Math.round(Math.max(...lignes.map((s) => O.tr(s).length)) * 6.9 + 44) : 28;
    const haut = lignes.length > 1 ? 40 : 26;
    const x0 = cx - larg / 2, y0 = cy - haut / 2;
    etiquettes += `<g opacity="0">${visible(C, de + 0.01, FIN, 0.005)}
      <rect x="${r1(x0)}" y="${r1(y0)}" width="${larg}" height="${haut}" rx="${lignes.length ? 10 : 14}" fill="${FOND}" stroke="${c}" stroke-width="1.5"/>
      <circle cx="${r1(x0 + 14)}" cy="${r1(cy)}" r="9.5" fill="${c}"/>
      ${t(r1(x0 + 14), r1(cy + 4), n, { taille: 11.5, couleur: '#000000', police: MONO, poids: 800, ancre: 'middle' })}
      ${lignes.map((s, i) => t(r1(x0 + 30), r1(cy + 4 + (i - (lignes.length - 1) / 2) * 15), s, { taille: 11.5, couleur: c, police: MONO, poids: 700 })).join('')}
    </g>`;
  }
  corps += traits + etiquettes + billes;

  // La légende, sous le téléphone.
  const LY = PY + PH + 34;
  corps += `<line x1="${PX + 4}" y1="${LY}" x2="${PX + 44}" y2="${LY}" stroke="${NEON}" stroke-width="3.5" stroke-linecap="round"/>
    <path transform="translate(${PX + 48},${LY})" d="M-11 -7 L1 0 L-11 7 Z" fill="${NEON}"/>
    ${t(PX + 62, LY + 4.5, 'l’écriture qui descend', { taille: 13, couleur: TITRE })}
    <line x1="${PX + 4}" y1="${LY + 30}" x2="${PX + 44}" y2="${LY + 30}" stroke="${BLEU}" stroke-width="3.5" stroke-linecap="round"/>
    <path transform="translate(${PX + 48},${LY + 30})" d="M-11 -7 L1 0 L-11 7 Z" fill="${BLEU}"/>
    ${t(PX + 62, LY + 34.5, 'la relecture qui remonte', { taille: 13, couleur: TITRE })}
    ${t(PX + 4, LY + 66, 'Les numéros suivent l’ordre du code.', { taille: 12, couleur: DISCRET })}`;

  const H = yc - ECART + 58;
  corps += t(640, H - 24, 'Un écran n’écrit jamais de SQL, et rien n’ouvre la base sans passer par le trousseau.', { taille: 13, couleur: DISCRET, ancre: 'middle' });

  svg('couches.svg', 1280, H, corps,
    'Les six couches de SmartBudget, traversées par une écriture, étape par étape. ecrans : lisent des providers, écrivent par des dépôts, jamais de SQL ; sur l’écran déplié, les pages deviennent des volets. providers : Riverpod, une écriture monte un numéro de version et tout ce qui lit la base se relit, d’un seul appel. domaine : du Dart pur, testé sans appareil, qui lit un libellé, reconnaît un virement interne, classe, détecte les récurrences et fait le bilan. donnees : le seul endroit où s’écrit du SQL, avec les dépôts, le schéma et ses migrations, la sauvegarde et le jeu d’essai. security : le trousseau, clé maîtresse dans le Keystore, dérivations HKDF, verrou ; rien ne lit un fichier en passant outre. smartbudget.db : SQLite chiffré par SQLCipher, schéma en version 6. banque : Enable Banking, JWT signé, session, opérations, solde ; la clé privée n’est déchiffrée que le temps d’un appel ; elle est hors de ce trajet. Sur le téléphone, on associe au concert de 90 euros le virement de 45 euros de Camille Roux. En vert, l’écriture qui descend : 1, toucher Valider ; 2, ecrans appelle DepotLiens().rembourser() dans donnees, sans passer par providers ni domaine, grisés ; 3, donnees tient de security la clé de la base ; 4, INSERT INTO liens dans smartbudget.db, dans une transaction. En bleu, la relecture qui remonte : 5, ecrans appelle rafraichir(ref), et la version de providers monte d’un cran ; 6, providers relit par DepotBilan.du, qui fait un SELECT dans smartbudget.db ; 7, donnees passe le mois à calculerBilan() dans domaine ; 8, providers rend la nouvelle valeur à ecrans, et la fiche du concert se redessine : 45 euros reçus. Un écran n’écrit jamais de SQL, et rien n’ouvre la base sans passer par le trousseau.');
};

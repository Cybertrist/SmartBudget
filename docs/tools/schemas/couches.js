// Les six couches de l'application, traversées par une écriture.
//
// À gauche, le téléphone : sur « Associer à un remboursement », le
// virement de Camille Roux est choisi, et le doigt touche « Valider ». À
// droite, les six couches, de l'écran au trousseau, et la base en dessous.
// Une bille verte descend avec l'écriture : l'écran appelle un dépôt, qui
// écrit dans une transaction, dans une base que seule la clé du trousseau
// ouvre. Puis l'écran monte la version (rafraichir), et une bille bleue
// remonte avec la relecture : les dépôts relisent, le domaine refait le
// bilan, les providers rendent leur nouvelle valeur, la fiche se redessine.
// La règle de chaque couche s'allume au passage ; la banque reste hors du
// trajet.
//
// Tout suit le code : EcranChoisirRemboursement._valider appelle
// DepotLiens().rembourser puis rafraichir(ref) ; versionProvider est lu
// par chaque provider ; DepotBilan.du relit le mois ; calculerBilan retire
// la part liée de la dépense et des entrées.
module.exports = (O) => {
  const { svg, t, visible, toucher, P, APP, MONO, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, NEON, BLEU, OR, ROSE, INTERNE } = O;
  const C = 24;
  const VIOLET = '#B08CFF';
  let corps = '';
  corps += t(60, 52, 'LES COUCHES', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + O.tr('LES COUCHES').length * 10.9 + 24), 52, 'Une écriture fait tout relire : toucher « Valider » descend jusqu’à la base, puis la relecture remonte jusqu’à l’écran.', { taille: 14 });

  // Les instants du cycle.
  const TAP = 0.07;          // le doigt touche « Valider »
  const POP = 0.56;          // l'écriture faite, la fiche revient
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
  const KX = 440, KL = 780, KY = 88, PAS = 100, KH = 86;
  const cy = (k) => KY + k * PAS + KH / 2;
  const RD = 394, RM = 416; // les deux rails : la descente, la remontée
  const BY = KY + 6 * PAS + 6, BH = 62, bcy = BY + BH / 2;

  // Des pictogrammes dans une grille de 28, dessinés en traits.
  const trait = (c) => `fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"`;
  const I = {
    ecrans: (c) => `<g ${trait(c)}><rect x="3" y="3" width="10" height="13" rx="2.5"/><rect x="15" y="3" width="10" height="7" rx="2.5"/><rect x="15" y="12" width="10" height="13" rx="2.5"/><rect x="3" y="18" width="10" height="7" rx="2.5"/></g>`,
    providers: (c) => `<g ${trait(c)}><rect x="2" y="3" width="10" height="8" rx="2.5"/><rect x="16" y="3" width="10" height="8" rx="2.5"/><rect x="16" y="17" width="10" height="8" rx="2.5"/><path d="M12 7 H16 M14 7 V21 H16"/></g>`,
    domaine: (c) => `<path d="M21 5 H7 L15 14 L7 23 H21" ${trait(c)}/>`,
    donnees: (c) => `<g ${trait(c)}><rect x="3" y="3" width="22" height="6" rx="2"/><rect x="3" y="11" width="22" height="6" rx="2"/><rect x="3" y="19" width="22" height="6" rx="2"/></g><circle cx="7" cy="6" r="1.3" fill="${c}"/><circle cx="7" cy="14" r="1.3" fill="${c}"/><circle cx="7" cy="22" r="1.3" fill="${c}"/>`,
    banque: P.banque,
    security: (c) => `<g ${trait(c)}><path d="M14 2 L24 6 V13 C24 19 19.5 23.5 14 26 C8.5 23.5 4 19 4 13 V6 Z"/><rect x="10" y="13" width="8" height="6.5" rx="1.5"/><path d="M11.5 13 V11 A2.5 2.5 0 0 1 16.5 11 V13"/></g>`,
  };

  // Ce que fait chaque couche au passage de l'écriture (vert), du signal
  // (or) et de la relecture (bleu) : [de, a, texte, couleur, allumée].
  const couches = [
    ['ecrans/', 'ecrans', NEON, ['Lisent des providers, écrivent par des dépôts, jamais de SQL.', 'Sur l’écran déplié, les pages deviennent des volets.'], [
      [TAP - 0.005, 0.15, 'toucher « Valider » : DepotLiens().rembourser(…)', NEON, true],
      [0.5, 0.56, 'puis rafraichir(ref), et la fiche revient', OR, true],
      [REDESSIN, FIN, 'la fiche se redessine : 45,00 € reçus', BLEU, true],
    ]],
    ['providers/', 'providers', BLEU, ['Riverpod. Une écriture monte un numéro de version :', 'tout ce qui lit la base se relit, d’un seul appel.'], [
      [0.545, 0.62, 'versionProvider + 1 : chaque provider qui le lit repart', OR, true],
      [0.8, 0.875, 'liensProvider, bilanProvider… rendent leur nouvelle valeur', BLEU, true],
    ]],
    ['domaine/', 'domaine', OR, ['Du Dart pur, testé sans appareil : lire un libellé, reconnaître un virement interne,', 'classer, détecter les récurrences, faire le bilan.'], [
      [0.71, 0.79, 'calculerBilan : Concert ne pèse plus que 45 €, et les 45 € ne sont pas un revenu', BLEU, true],
    ]],
    ['donnees/', 'donnees', ROSE, ['Le seul endroit où s’écrit du SQL : les dépôts, le schéma et ses migrations,', 'la sauvegarde, le jeu d’essai.'], [
      [0.19, 0.31, 'une transaction : la part est le plus petit des deux restes', NEON, true],
      [0.635, 0.705, 'DepotBilan.du(septembre) relit le mois et ses liens', BLEU, true],
    ]],
    ['banque/', 'banque', VERT, ['Enable Banking : JWT signé, session, opérations, solde.', 'La clé privée n’est déchiffrée que le temps d’un appel.'], [
      [0.3, 0.37, 'hors du trajet : elle ne sert qu’à la synchronisation', DISCRET, false],
      [0.6, 0.64, 'hors du trajet : elle ne sert qu’à la synchronisation', DISCRET, false],
    ]],
    ['security/', 'security', VIOLET, ['Le trousseau : clé maîtresse dans le Keystore, dérivations HKDF, verrou.', 'Rien ne lit un fichier en passant outre.'], [
      [0.36, 0.45, 'la base ne s’ouvre qu’avec la clé que HKDF tire du Keystore', NEON, true],
    ]],
  ];

  // Une étiquette, calée à droite sur la ligne du titre.
  const etiquette_ = (xd, y, texte, couleur) => {
    const l = Math.round(O.tr(texte).length * 6.3 + 26);
    return `<rect x="${xd - l}" y="${y - 12}" width="${l}" height="24" rx="12" fill="${couleur}" fill-opacity="0.12" stroke="${couleur}" stroke-opacity="0.55"/>
      ${t(xd - l / 2, y + 4.5, texte, { taille: 12, couleur, poids: 700, ancre: 'middle' })}`;
  };

  // Les rails, et les attaches vers chaque couche.
  corps += `<line x1="${RD}" y1="${cy(0)}" x2="${RD}" y2="${bcy}" stroke="${NEON}" stroke-opacity="0.18" stroke-width="2"/>
    <line x1="${RM}" y1="${cy(0)}" x2="${RM}" y2="${bcy}" stroke="${BLEU}" stroke-opacity="0.18" stroke-width="2"/>
    <line x1="${PX + PL}" y1="${cy(0)}" x2="${KX}" y2="${cy(0)}" stroke="${FIL}" stroke-width="2" stroke-dasharray="3 5"/>`;
  for (let k = 1; k < 6; k++) corps += `<line x1="${RD}" y1="${cy(k)}" x2="${KX}" y2="${cy(k)}" stroke="${FIL}" stroke-width="2" stroke-dasharray="3 5"/>`;
  corps += `<line x1="${RD}" y1="${bcy}" x2="${KX}" y2="${bcy}" stroke="${FIL}" stroke-width="2" stroke-dasharray="3 5"/>`;
  corps += t(RD, KY - 10, '↓', { taille: 13, couleur: NEON, ancre: 'middle', poids: 700 });
  corps += t(RM, KY - 10, '↑', { taille: 13, couleur: BLEU, ancre: 'middle', poids: 700 });

  couches.forEach(([nom, cle, accent, regle, passages], k) => {
    const y = KY + k * PAS;
    corps += `<rect x="${KX}" y="${y}" width="${KL}" height="${KH}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${KX}" y="${y + 14}" width="3" height="${KH - 28}" rx="1.5" fill="${accent}"/>
      <g transform="translate(${KX + 18},${y + 14})">${I[cle](accent)}</g>
      ${t(KX + 58, y + 30, nom, { taille: 14.5, couleur: accent, police: MONO, poids: 700 })}
      ${regle.map((l, i) => t(KX + 58, y + 53 + i * 18, l, { taille: 13 })).join('')}`;
    for (const [de, a, texte, couleur, allumee] of passages) {
      if (allumee) {
        corps += `<rect x="${KX}" y="${y}" width="${KL}" height="${KH}" rx="13" fill="${accent}" fill-opacity="0.05" stroke="${accent}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, de, a, 0.006)}</rect>
          <g opacity="0">${visible(C, de, a, 0.006)}${regle.map((l, i) => t(KX + 58, y + 53 + i * 18, l, { taille: 13, couleur: TITRE })).join('')}</g>`;
      }
      corps += `<g opacity="0">${visible(C, de, a, 0.006)}${etiquette_(KX + KL - 16, y + 25, texte, couleur)}</g>`;
    }
  });

  // La base, sous les couches.
  corps += `<rect x="${KX}" y="${BY}" width="${KL}" height="${BH}" rx="13" fill="#0F151D" stroke="${BORD}"/>
    <rect x="${KX}" y="${BY + 12}" width="3" height="${BH - 24}" rx="1.5" fill="${INTERNE}"/>
    <g transform="translate(${KX + 18},${BY + 17})">${P.base(INTERNE)}</g>
    ${t(KX + 58, BY + 27, 'smartbudget.db', { taille: 14.5, couleur: TITRE, police: MONO, poids: 700 })}
    ${t(KX + 58, BY + 47, 'SQLite chiffré par SQLCipher, schéma en version 6', { taille: 12.5 })}`;
  for (const [de, a, texte, couleur] of [
    [0.47, 0.565, 'INSERT INTO liens : 1262 → 1287, 4 500 centimes', NEON],
    [0.585, 0.64, 'SELECT : les opérations du mois, et leurs liens', BLEU],
  ]) {
    corps += `<rect x="${KX}" y="${BY}" width="${KL}" height="${BH}" rx="13" fill="none" stroke="${couleur}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, de, a, 0.006)}</rect>
      <g opacity="0">${visible(C, de, a, 0.006)}${etiquette_(KX + KL - 16, BY + BH / 2, texte, couleur)}</g>`;
  }

  // Les billes : une pause à chaque couche qui travaille.
  const trajet = (x, cles, couleur, de, a) => {
    const temps = [0, ...cles.map((c) => c[0]), 1].join(';');
    const ys = [cles[0][1], ...cles.map((c) => c[1]), cles.at(-1)[1]].join(';');
    const anim = `<animate attributeName="cy" dur="${C}s" repeatCount="indefinite" keyTimes="${temps}" values="${ys}"/>`;
    return `<g filter="url(#halo)" opacity="0">${visible(C, de, a, 0.004)}
      <circle cx="${x}" cy="${cles[0][1]}" r="11" fill="${couleur}" opacity="0.22">${anim}</circle>
      <circle cx="${x}" cy="${cles[0][1]}" r="6" fill="${couleur}">${anim}</circle></g>`;
  };
  // L'écriture descend : écran, dépôt, trousseau, base.
  corps += trajet(RD, [[TAP, cy(0)], [0.12, cy(0)], [0.19, cy(3)], [0.3, cy(3)], [0.36, cy(5)], [0.43, cy(5)], [0.47, bcy]], NEON, TAP, 0.52);
  // Le signal : l'écran monte la version.
  corps += trajet(RM, [[0.51, cy(0)], [0.545, cy(1)]], OR, 0.505, 0.56);
  // La relecture remonte : base, dépôt, domaine, providers, écran.
  corps += trajet(RM, [[0.585, bcy], [0.635, cy(3)], [0.69, cy(3)], [0.71, cy(2)], [0.78, cy(2)], [0.8, cy(1)], [0.86, cy(1)], [REDESSIN, cy(0)]], BLEU, 0.585, FIN);

  corps += t(640, 792, 'Un écran n’écrit jamais de SQL, et rien n’ouvre la base sans passer par le trousseau.', { taille: 13, couleur: DISCRET, ancre: 'middle' });

  svg('couches.svg', 1280, 820, corps,
    'Les six couches de SmartBudget, traversées par une écriture. ecrans : lisent des providers, écrivent par des dépôts, jamais de SQL ; sur l’écran déplié, les pages deviennent des volets. providers : Riverpod, une écriture monte un numéro de version et tout ce qui lit la base se relit, d’un seul appel. domaine : du Dart pur, testé sans appareil, qui lit un libellé, reconnaît un virement interne, classe, détecte les récurrences et fait le bilan. donnees : le seul endroit où s’écrit du SQL, avec les dépôts, le schéma et ses migrations, la sauvegarde et le jeu d’essai. banque : Enable Banking, JWT signé, session, opérations, solde ; la clé privée n’est déchiffrée que le temps d’un appel. security : le trousseau, clé maîtresse dans le Keystore, dérivations HKDF, verrou ; rien ne lit un fichier en passant outre. Sur le téléphone, on associe au concert de 90 euros le virement de 45 euros de Camille Roux, et l’on touche Valider. L’écriture descend : l’écran appelle DepotLiens().rembourser, le dépôt écrit dans une transaction une part égale au plus petit des deux restes, dans une base SQLCipher que seule la clé tirée du Keystore par HKDF ouvre, et une ligne entre dans la table liens. La banque reste hors du trajet. Puis l’écran appelle rafraichir : versionProvider monte d’un cran, et la relecture remonte. DepotBilan relit le mois et ses liens, calculerBilan établit que le concert ne pèse plus que 45 euros et que les 45 euros reçus ne sont pas un revenu, les providers rendent leur nouvelle valeur, et la fiche du concert affiche 45 euros reçus. Un écran n’écrit jamais de SQL, et rien n’ouvre la base sans passer par le trousseau.');
};

// Les récurrences : ce qui revient tout seul, déduit des opérations.
//
// À gauche, quatre mois d'opérations, marchand par marchand : la lecture
// balaie jusqu'à aujourd'hui, chaque écart entre deux passages se mesure,
// et ceux qui tombent dans une fenêtre font une fréquence, une prochaine
// date, un état. À droite, le téléphone montre l'onglet Récurrences de
// l'analyse se remplir, puis deux choix faits à la main sur la ligne
// Répétition d'une opération : « Aucune » pour un faux rythme, « Chaque
// mois » pour un vrai que la détection n'a pas vu.
module.exports = (O) => {
  const {
    svg, t, visible, fondu, toucher, APP,
    MONO, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, OR, ROSE, ROUGE,
  } = O;

  const C = 32;
  const SHOPPING = '#FF9F5A', LOISIRS = '#C6F45A', SURFACE = '#242424';
  const g = (de, a, contenu, douceur = 0.004) => `<g opacity="0">${visible(C, de, a, douceur)}${contenu}</g>`;

  // Les instants du récit.
  const T = {
    balaye: [0.02, 0.2], verdict: (i) => 0.22 + i * 0.02, resume: 0.36,
    vinted: 0.42, fiche1: 0.44, rep1: 0.47, choix1: 0.485, aucune: 0.54, ferme1: 0.555, liste2: 0.6,
    fiche2: 0.68, rep2: 0.72, choix2: 0.735, mois: 0.785, ferme2: 0.8, liste3: 0.845, fin: 0.985,
  };

  let corps = '';
  corps += t(60, 52, 'LES RÉCURRENCES', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(262, 52, 'Rien à saisir : un même marchand, un montant stable, un écart régulier.', { taille: 14 });

  // ------------------------------------------------------- la frise, à gauche
  const GX = 60, GL = 836, GY = 80, GH = 372;
  const X0 = 258, PXJ = 3.0; // 1er juin, pixels par jour
  const X = (j) => X0 + j * PXJ;
  const AUJ = 111; // 20 septembre
  corps += `<rect x="${GX}" y="${GY}" width="${GL}" height="${GH}" rx="16" fill="${CARTE}" stroke="${BORD}"/>`;
  corps += t(GX + 22, GY + 30, 'QUATRE MOIS D’OPÉRATIONS, MARCHAND PAR MARCHAND', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  // Les mois : 1er juin, 1er juillet, 1er août, 1er septembre, 1er octobre.
  const mois = [['juin', 0], ['juillet', 30], ['août', 61], ['septembre', 92], ['octobre', 122]];
  const haut = GY + 58, bas = GY + GH - 18;
  mois.forEach(([n, j], k) => {
    corps += `<line x1="${X(j)}" y1="${haut}" x2="${X(j)}" y2="${bas}" stroke="${FIL}" stroke-opacity="0.6" stroke-dasharray="2 5"/>`;
    const fin = k < mois.length - 1 ? mois[k + 1][1] : 136;
    corps += t((X(j) + X(fin)) / 2, haut - 6, n, { taille: 11.5, couleur: TEXTE, ancre: 'middle' });
  });
  // Aujourd'hui.
  corps += `<line x1="${X(AUJ)}" y1="${haut + 4}" x2="${X(AUJ)}" y2="${bas}" stroke="${VERT}" stroke-opacity="0.55" stroke-width="1.5"/>`;
  corps += `<rect x="${X(AUJ) - 44}" y="${bas - 2}" width="88" height="18" rx="9" fill="${FOND}" stroke="${VERT}" stroke-opacity="0.5"/>`;
  corps += t(X(AUJ), bas + 11, 'auj. 20 sept.', { taille: 10.5, couleur: VERT, poids: 700, ancre: 'middle' });
  // Le balayage : une ligne qui avance de juin jusqu'à aujourd'hui.
  const [b0, b1] = T.balaye;
  const quand = (j) => b0 + (b1 - b0) * (j / AUJ);
  corps += `<g opacity="0">${visible(C, b0, b1 + 0.01, 0.006)}
    <rect y="${haut + 4}" width="3" height="${bas - haut - 4}" fill="${VERT}" filter="url(#halo)">
      <animate attributeName="x" dur="${C}s" repeatCount="indefinite" keyTimes="0;${b0};${b1};1" values="${X0};${X0};${X(AUJ) - 1.5};${X(AUJ) - 1.5}"/></rect></g>`;

  // Les marchands.
  // [nom, montant, jours, écarts affichés, verdict, couleur, prochaine, état]
  const rangs = [
    ['Foncia Loyer', '520,00 €', [4, 34, 65, 96], 'Chaque mois', 126, 'payee'],
    ['Edf Clients Particuliers', '36,40 à 41,20 €', [7, 37, 68, 99], 'Chaque mois', 129, 'payee'],
    ['Basic Fit France', '29,99 €', [9, 39, 70], 'Chaque mois', 101, 'retard'],
    ['Netflix.com', '14,99 €', [26, 56, 87], 'Chaque mois', 118, 'avenir'],
    ['Vinted', '18,50 et 19,00 €', [53, 84], 'Chaque mois', 115, 'avenir'],
    ['Carrefour Market Vannes', 'de 31 à 74 €', [2, 6, 17, 23, 41, 44, 60, 79, 83, 97, 108], null, null, null],
    ['Club Escalade Vannes', '35,00 €', [31, 81], null, 112, 'avenir'],
  ];
  const couleurEtat = { payee: VERT, avenir: OR, retard: ROUGE };
  const texteEtat = { payee: 'payée', avenir: 'à venir', retard: 'en retard' };
  const RY0 = GY + 84, RPAS = 40;
  const PV = 680; // la colonne des verdicts
  const pill = (x, y, l, texte, c, opts = {}) => `<rect x="${x}" y="${y - 12}" width="${l}" height="24" rx="12" fill="${c}" fill-opacity="${opts.plein ? 0.16 : 0.08}" stroke="${c}" stroke-opacity="0.55"/>
    ${t(x + l / 2, y + 4, texte, { taille: 11, couleur: c, poids: 700, ancre: 'middle' })}`;
  rangs.forEach(([nom, montant, jours, verdict, prochaine, etat], i) => {
    const y = RY0 + i * RPAS, v = T.verdict(i);
    const vinted = nom === 'Vinted', club = nom === 'Club Escalade Vannes', carrefour = nom === 'Carrefour Market Vannes';
    corps += t(GX + 22, y - 1, nom, { taille: 12, couleur: TITRE, poids: 700 });
    corps += t(GX + 22, y + 14, montant, { taille: 10.5, couleur: DISCRET });
    corps += `<line x1="${X0}" y1="${y}" x2="${X(136)}" y2="${y}" stroke="${BORD}" stroke-width="1"/>`;
    // Les écarts, mesurés après le balayage.
    if (!carrefour) {
      for (let k = 1; k < jours.length; k++) {
        const a = X(jours[k - 1]), b = X(jours[k]), m = (a + b) / 2;
        const ecart = jours[k] - jours[k - 1];
        const dedans = ecart >= 25 && ecart <= 35;
        const c = dedans ? VERT : DISCRET;
        corps += g(v, 0.996, `<path d="M${a + 5} ${y - 5} Q${m} ${y - 17} ${b - 5} ${y - 5}" fill="none" stroke="${c}" stroke-opacity="0.7" stroke-width="1.5"/>
          ${t(m, y - 14, `${ecart} j`, { taille: 10, couleur: c, police: MONO, poids: 700, ancre: 'middle' })}`, 0.006);
      }
    }
    // Les passages, qui s'allument quand le balayage les atteint.
    jours.forEach((j) => {
      const s = quand(j);
      const c = carrefour ? TEXTE : ROSE;
      corps += `<circle cx="${X(j)}" cy="${y}" r="4.5" fill="${c}" opacity="0">${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.004, 1], [0.996, 1], [1, 0]])}</circle>`;
    });
    // La prochaine, projetée d'un mois après la dernière.
    const projette = (de, a) => {
      const derniere = jours[jours.length - 1], c = couleurEtat[etat];
      return g(de, a, `<path d="M${X(derniere) + 6} ${y} H${X(prochaine) - 7}" stroke="${c}" stroke-opacity="0.6" stroke-width="1.5" stroke-dasharray="3 4"/>
        <circle cx="${X(prochaine)}" cy="${y}" r="6" fill="${FOND}" stroke="${c}" stroke-width="2"/>
        ${etat === 'retard' ? `<circle cx="${X(prochaine)}" cy="${y}" r="6" fill="none" stroke="${c}" stroke-width="2">${fondu('r', 1.6, [[0, 6], [1, 16]])}${fondu('opacity', 1.6, [[0, 0.9], [1, 0]])}</circle>` : ''}`, 0.006);
    };
    const etiquette = (de, a) => g(de, a, pill(PV, y, 136, verdict, VERT), 0.006);
    if (carrefour) {
      corps += g(v, 0.996, pill(PV, y, 136, 'aucun rythme', DISCRET), 0.006);
    } else if (club) {
      corps += g(v, T.mois, pill(PV, y, 136, '50 j : rien', DISCRET), 0.006);
      corps += g(T.mois, 0.996, pill(PV, y, 136, 'Chaque mois, choisi', VERT, { plein: true }), 0.006);
      corps += projette(T.mois, 0.996);
      corps += `<rect x="${GX + 8}" y="${y - 19}" width="${GL - 16}" height="38" rx="10" fill="none" stroke="${VERT}" stroke-opacity="0.8" filter="url(#halo)" opacity="0">${visible(C, T.mois, T.mois + 0.07, 0.006)}</rect>`;
    } else if (vinted) {
      corps += etiquette(v, T.aucune);
      corps += projette(v, T.aucune);
      corps += g(T.aucune, 0.996, pill(PV, y, 136, 'Aucune, choisi', ROUGE, { plein: true }), 0.006);
      // Le faux rythme s'éteint.
      corps += `<rect x="${X0 - 8}" y="${y - 19}" width="${PV - X0}" height="34" fill="${CARTE}" opacity="0">${fondu('opacity', C, [[0, 0], [T.aucune, 0], [T.aucune + 0.01, 0.6], [0.996, 0.6], [1, 0]])}</rect>`;
      corps += `<rect x="${GX + 8}" y="${y - 19}" width="${GL - 16}" height="38" rx="10" fill="none" stroke="${ROUGE}" stroke-opacity="0.8" filter="url(#halo)" opacity="0">${visible(C, T.aucune, T.aucune + 0.07, 0.006)}</rect>`;
    } else {
      corps += etiquette(v, 0.996);
      corps += projette(v, 0.996);
    }
    // L'état : une pastille au bout.
    if (etat && !club) corps += g(v, vinted ? T.aucune : 0.996, t(PV + 144, y + 4, texteEtat[etat], { taille: 11, couleur: couleurEtat[etat], poids: 700 }), 0.006);
    if (club) corps += g(T.mois, 0.996, t(PV + 144, y + 4, texteEtat[etat], { taille: 11, couleur: couleurEtat[etat], poids: 700 }), 0.006);
  });

  // ------------------------------------------------------- les fenêtres
  const FY = 478;
  corps += t(GX, FY, 'LES FENÊTRES : CHAQUE ÉCART DOIT Y TOMBER', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const fenetres = [['6 à 8 j', 'Chaque semaine'], ['25 à 35 j', 'Chaque mois'], ['85 à 95 j', 'Chaque trimestre'], ['350 à 380 j', 'Chaque année']];
  const FL = 200, FG = (GL - 4 * FL) / 3;
  fenetres.forEach(([ecart, nom], k) => {
    const x = GX + k * (FL + FG), y = FY + 14;
    corps += `<rect x="${x}" y="${y}" width="${FL}" height="44" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      ${t(x + 16, y + 27, ecart, { taille: 12.5, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(x + FL - 16, y + 27, nom, { taille: 12.5, couleur: TEXTE, ancre: 'end' })}`;
    if (k === 1) corps += `<rect x="${x}" y="${y}" width="${FL}" height="44" rx="12" fill="${VERT}" fill-opacity="0.08" stroke="${VERT}" stroke-opacity="0.8" opacity="0">${visible(C, T.verdict(0), T.resume, 0.006)}</rect>`;
  });
  const regles = ['au moins deux passages', 'montant à 15 % de sa médiane', 'la médiane devient le montant attendu'];
  let rx = GX;
  regles.forEach((s) => {
    const l = s.length * 6.6 + 34;
    corps += `<circle cx="${rx + 8}" cy="${FY + 82}" r="7" fill="${VERT}" fill-opacity="0.15" stroke="${VERT}" stroke-opacity="0.6"/>
      <path d="M${rx + 5} ${FY + 82} l2 2 l4 -4" fill="none" stroke="${VERT}" stroke-width="1.6"/>
      ${t(rx + 22, FY + 86.5, s, { taille: 12.5, couleur: TEXTE })}`;
    rx += l + 20;
  });

  // ------------------------------------------------------- le choix à la main
  const CY = 598, CL = 400;
  const choix = [
    ['« Aucune » : il ne revient pas', ['Vinted, deux achats à un mois d’écart : un faux rythme.', 'La détection a beau le voir, il sort des récurrences.'], ROUGE, [T.fiche1, T.fiche2]],
    ['« Chaque mois » : il revient', ['Le club d’escalade, prélevé à 50 jours d’écart en été.', 'Choisi à la main, il compte, même sans rythme.'], VERT, [T.fiche2, 0.996]],
  ];
  choix.forEach(([titre, lignes, c, [de, a]], k) => {
    const x = GX + k * (CL + GL - 2 * CL);
    corps += `<rect x="${x}" y="${CY}" width="${CL}" height="92" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${CY}" width="${CL}" height="92" rx="12" fill="${c}" fill-opacity="0.05" stroke="${c}" stroke-opacity="0.8" opacity="0">${visible(C, de, a, 0.006)}</rect>
      <rect x="${x}" y="${CY}" width="${CL}" height="92" rx="12" fill="${c}" fill-opacity="0.05" stroke="${c}" stroke-opacity="0.3"/>
      ${t(x + 20, CY + 30, titre, { taille: 14, couleur: TITRE, poids: 700 })}
      ${lignes.map((s, i) => t(x + 20, CY + 53 + i * 19, s, { taille: 12.5, couleur: TEXTE })).join('')}`;
  });
  corps += t(GX, 728, 'Sur la ligne Répétition d’une opération : le choix vaut pour tout le marchand, et passe avant la détection.', { taille: 13, couleur: DISCRET });

  // ------------------------------------------------------- le téléphone
  const PX = 916, PY = 96, PL = 304, PH = 612;
  const SX = PX + 12, SY = PY + 16, SL = PL - 24, SH = PH - 32;
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="40" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranRecur"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 34}" y="${PY + 6}" width="68" height="5" rx="2.5" fill="#1B222C"/>`;
  let ecran = '';
  const carteApp = (x, y, l, h, fond = APP.carte) => `<rect x="${x}" y="${y}" width="${l}" height="${h}" rx="14" fill="${fond}"/>`;
  const tuileRond = (x, y, s, c) => `<rect x="${x}" y="${y}" width="${s}" height="${s}" rx="${s * 0.3}" fill="${c}" fill-opacity="0.16"/>
    <g transform="translate(${x + s / 2},${y + s / 2})"><path d="M-6 -2 A6.5 6.5 0 0 1 5.5 -3.5 M6 2 A6.5 6.5 0 0 1 -5.5 3.5" fill="none" stroke="${c}" stroke-width="1.8" stroke-linecap="round"/><path d="M5.5 -7 v3.8 h-3.8 M-5.5 7 v-3.8 h3.8" fill="none" stroke="${c}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></g>`;

  // L'analyse, onglet Récurrences.
  const entete = `${t(SX + 18, SY + 46, 'Analyse', { taille: 22, couleur: APP.texte, poids: 800 })}
    ${t(SX + 24, SY + 76, '‹', { taille: 16, couleur: APP.second })}${t(SX + SL / 2, SY + 76, 'Septembre 2026', { taille: 13, couleur: APP.texte, poids: 700, ancre: 'middle' })}${t(SX + SL - 24, SY + 76, '›', { taille: 16, couleur: APP.second, ancre: 'end' })}
    ${['1 mois', '3 mois', '1 an'].map((s, k) => {
      const l = (SL - 36) / 3, x = SX + 12 + k * (l + 6);
      return `<rect x="${x}" y="${SY + 88}" width="${l}" height="26" rx="13" fill="${k === 0 ? '#FFFFFF' : APP.carte}"/>${t(x + l / 2, SY + 105, s, { taille: 11, couleur: k === 0 ? '#000' : APP.second, poids: 700, ancre: 'middle' })}`;
    }).join('')}
    <rect x="${SX + 12}" y="${SY + 122}" width="${SL - 24}" height="30" rx="15" fill="${APP.carte}"/>
    ${['Sorties', 'Entrées', 'Récurrences'].map((s, k) => {
      const l = (SL - 28) / 3, x = SX + 14 + k * l;
      return `${k === 2 ? `<rect x="${x}" y="${SY + 124}" width="${l}" height="26" rx="13" fill="${VERT}"/>` : ''}${t(x + l / 2, SY + 141, s, { taille: 11, couleur: k === 2 ? '#000' : APP.second, poids: 700, ancre: 'middle' })}`;
    }).join('')}`;
  const resume = (paye, attendu, part) => `${carteApp(SX + 12, SY + 162, SL - 24, 80)}
    ${t(SX + SL / 2, SY + 194, paye, { taille: 24, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(SX + SL / 2, SY + 214, `payés sur ${attendu} attendus ce mois-ci`, { taille: 10.5, couleur: APP.second, ancre: 'middle' })}
    <rect x="${SX + 30}" y="${SY + 224}" width="${SL - 60}" height="6" rx="3" fill="#2A2A2A"/>
    <rect x="${SX + 30}" y="${SY + 224}" width="${(SL - 60) * part}" height="6" rx="3" fill="${VERT}"/>`;
  const ligneRec = (y, nom, montant, etat, c) => `${tuileRond(SX + 26, y + 6, 26, ROSE)}
    ${t(SX + 62, y + 17, nom, { taille: 12, couleur: APP.texte, poids: 700 })}
    ${t(SX + 62, y + 31, 'Chaque mois', { taille: 10, couleur: APP.discret })}
    ${t(SX + SL - 36, y + 17, montant, { taille: 11.5, couleur: APP.texte, poids: 700, ancre: 'end' })}
    ${t(SX + SL - 36, y + 31, etat, { taille: 9.5, couleur: c, poids: 700, ancre: 'end' })}
    <path d="M${SX + SL - 28} ${y + 15} l4 4 l-4 4" fill="none" stroke="${APP.discret}" stroke-width="1.5"/>`;
  const bloc = (y, titre, lignes, apparitions) => {
    const h = 24 + lignes.length * 38 + 4;
    let s = g(apparitions[0], 0.996, `${carteApp(SX + 12, y, SL - 24, h)}${t(SX + 26, y + 18, titre, { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.5"' })}`, 0.003);
    lignes.forEach((l, k) => {
      if (k > 0) s += g(apparitions[k], 0.996, `<line x1="${SX + 24}" y1="${y + 24 + k * 38}" x2="${SX + SL - 24}" y2="${y + 24 + k * 38}" stroke="${APP.trait}"/>`, 0.003);
      s += g(apparitions[k], 0.996, ligneRec(y + 24 + k * 38, ...l), 0.003);
    });
    return s;
  };
  const L = {
    basic: ['Basic Fit France', '-29,99 €', 'attendu il y a 10 j', ROUGE],
    vinted: ['Vinted', '-18,50 €', 'dans 4 j', OR],
    netflix: ['Netflix.com', '-14,99 €', 'dans 7 j', OR],
    club: ['Club Escalade Va…', '-35,00 €', 'dans 1 j', OR],
    loyer: ['Foncia Loyer', '-520,00 €', 'le 5', VERT],
    edf: ['Edf Clients Parti…', '-38,90 €', 'le 8', VERT],
  };
  // La liste de départ : chaque ligne s'ajoute quand la frise la trouve.
  const liste1 = `${bloc(SY + 252, 'EN RETARD', [L.basic], [T.verdict(2)])}
    ${bloc(SY + 326, 'À VENIR', [L.vinted, L.netflix], [T.verdict(3), T.verdict(4)].sort())}
    ${bloc(SY + 438, 'PAYÉES', [L.loyer, L.edf], [T.verdict(0), T.verdict(1)])}`;
  ecran += g(0.004, T.fiche1, `${entete}
    ${g(0.004, T.resume, `${carteApp(SX + 12, SY + 162, SL - 24, 80)}<circle cx="${SX + SL / 2}" cy="${SY + 202}" r="12" fill="none" stroke="${VERT}" stroke-width="3" stroke-dasharray="48 28" stroke-linecap="round"><animateTransform attributeName="transform" type="rotate" from="0 ${SX + SL / 2} ${SY + 202}" to="360 ${SX + SL / 2} ${SY + 202}" dur="1s" repeatCount="indefinite"/></circle>`)}
    ${g(T.resume, T.fiche1, resume('-558,90 €', '622,38 €', 558.9 / 622.38))}
    ${liste1}
    ${toucher(SX + 110, SY + 326 + 24 + 17, C, T.vinted)}
    <rect x="${SX + 16}" y="${SY + 350}" width="${SL - 32}" height="38" rx="10" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.6" opacity="0">${visible(C, T.vinted - 0.004, T.fiche1, 0.003)}</rect>`);

  // La fiche d'une opération : la ligne Répétition, puis la carte de choix.
  const fiche = (de, a, { montant, nom, libelle, date, categorie, c, avant, apres, bascule, touche, carte, toucheChoix, choisi }) => {
    const DX = SX + 16, DL = SL - 32, DY = SY + 150;
    const options = ['Aucune', 'Chaque semaine', 'Chaque mois', 'Chaque trimestre', 'Chaque année'];
    const valeur = (s, couleur) => t(SX + SL - 30, SY + 366, s, { taille: 12, couleur, poids: 700, ancre: 'end' });
    return g(de, a, `
      ${t(SX + 16, SY + 46, '‹', { taille: 24, couleur: APP.texte })}
      <rect x="${SX + SL / 2 - 26}" y="${SY + 30}" width="52" height="52" rx="16" fill="${c}" fill-opacity="0.16"/>
      <circle cx="${SX + SL / 2}" cy="${SY + 56}" r="10" fill="none" stroke="${c}" stroke-width="2.4"/>
      ${t(SX + SL / 2, SY + 122, montant, { taille: 28, couleur: APP.texte, poids: 800, ancre: 'middle' })}
      ${t(SX + SL / 2, SY + 144, nom, { taille: 13.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}
      ${t(SX + SL / 2, SY + 162, libelle, { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
      ${t(SX + SL / 2, SY + 176, date, { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
      ${carteApp(SX + 12, SY + 190, SL - 24, 112)}
      ${t(SX + 28, SY + 212, 'CLASSEMENT', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="2"' })}
      ${[['Nom', nom, APP.texte], ['Catégorie', categorie, c]].map(([n, v, cv], k) => `
        <line x1="${SX + 26}" y1="${SY + 224 + k * 38}" x2="${SX + SL - 26}" y2="${SY + 224 + k * 38}" stroke="${APP.trait}"/>
        ${t(SX + 28, SY + 248 + k * 38, n, { taille: 12, couleur: APP.second, poids: 600 })}
        ${t(SX + SL - 30, SY + 248 + k * 38, v, { taille: 12, couleur: cv, poids: 700, ancre: 'end' })}`).join('')}
      ${carteApp(SX + 12, SY + 314, SL - 24, 112)}
      ${t(SX + 28, SY + 336, 'SUIVI', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="2"' })}
      ${t(SX + 28, SY + 366, 'Répétition', { taille: 12, couleur: APP.second, poids: 600 })}
      ${g(de, bascule, valeur(avant[0], avant[1]))}${g(bascule, a, valeur(apres[0], apres[1]))}
      <rect x="${SX + 20}" y="${SY + 346}" width="${SL - 40}" height="30" rx="9" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.6" opacity="0">${visible(C, bascule, bascule + 0.03, 0.004)}</rect>
      <line x1="${SX + 26}" y1="${SY + 382}" x2="${SX + SL - 26}" y2="${SY + 382}" stroke="${APP.trait}"/>
      ${t(SX + 28, SY + 408, 'Masquer de l’analyse', { taille: 12, couleur: APP.second, poids: 600 })}
      <rect x="${SX + SL - 66}" y="${SY + 394}" width="36" height="20" rx="10" fill="#2C2C2C"/><circle cx="${SX + SL - 56}" cy="${SY + 404}" r="7" fill="${APP.second}"/>
      ${toucher(SX + SL - 70, SY + 361, C, touche)}
      ${g(carte, bascule - 0.004, `
        <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000" fill-opacity="0.7"/>
        <rect x="${DX}" y="${DY}" width="${DL}" height="300" rx="22" fill="${SURFACE}"/>
        ${t(SX + SL / 2, DY + 30, 'Toutes les opérations', { taille: 11.5, couleur: APP.second, ancre: 'middle' })}
        ${t(SX + SL / 2, DY + 47, `« ${nom} » suivent ce choix.`, { taille: 11.5, couleur: APP.second, ancre: 'middle' })}
        ${options.map((o, k) => {
          const y = DY + 66 + k * 44;
          return `<line x1="${DX + 14}" y1="${y}" x2="${DX + DL - 14}" y2="${y}" stroke="${APP.trait}"/>
            ${t(DX + 22, y + 28, o, { taille: 13.5, couleur: APP.texte, poids: 700 })}
            ${o === choisi ? `<path d="M${DX + DL - 34} ${y + 22} l4 4 l9 -9" fill="none" stroke="${VERT}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>` : ''}`;
        }).join('')}
        ${toucher(DX + 70, DY + 66 + toucheChoix * 44 + 22, C, bascule - 0.015)}`, 0.003)}`);
  };
  ecran += fiche(T.fiche1, T.liste2, {
    montant: '-19,00 €', nom: 'Vinted', libelle: 'PAIEMENT PAR CARTE X0000 VINTED 23/08', date: 'Lundi 24 août 2026 · Compte courant',
    categorie: 'Shopping › Seconde main', c: SHOPPING, avant: ['Chaque mois', VERT], apres: ['Aucune', APP.texte],
    bascule: T.ferme1, touche: T.rep1, carte: T.choix1, toucheChoix: 0, choisi: 'Chaque mois',
  });
  // Sans Vinted.
  const liste2 = `${bloc(SY + 252, 'EN RETARD', [L.basic], [0.004])}
    ${bloc(SY + 326, 'À VENIR', [L.netflix], [0.004])}
    ${bloc(SY + 400, 'PAYÉES', [L.loyer, L.edf], [0.004, 0.004])}`;
  ecran += g(T.liste2, T.fiche2, `${entete}${resume('-558,90 €', '603,88 €', 558.9 / 603.88)}${liste2}`);
  ecran += fiche(T.fiche2, T.liste3, {
    montant: '-35,00 €', nom: 'Club Escalade Vannes', libelle: 'PRLV SEPA CLUB ESCALADE VANNES', date: 'Vendredi 21 août 2026 · Compte courant',
    categorie: 'Loisirs › Sport et activités', c: LOISIRS, avant: ['Aucune', APP.texte], apres: ['Chaque mois', VERT],
    bascule: T.ferme2, touche: T.rep2, carte: T.choix2, toucheChoix: 2, choisi: 'Aucune',
  });
  // Avec le club.
  const liste3 = `${bloc(SY + 252, 'EN RETARD', [L.basic], [0.004])}
    ${bloc(SY + 326, 'À VENIR', [L.club, L.netflix], [0.004, 0.004])}
    ${bloc(SY + 438, 'PAYÉES', [L.loyer, L.edf], [0.004, 0.004])}`;
  ecran += g(T.liste3, T.fin, `${entete}${resume('-558,90 €', '638,88 €', 558.9 / 638.88)}${liste3}
    <rect x="${SX + 16}" y="${SY + 350}" width="${SL - 32}" height="38" rx="10" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.7" filter="url(#halo)" opacity="0">${visible(C, T.liste3, T.liste3 + 0.08, 0.006)}</rect>`);
  corps += `<g clip-path="url(#ecranRecur)">${ecran}</g>`;

  svg('recurrences.svg', 1280, 752, corps,
    'Les récurrences, déduites des opérations sans rien saisir. Sur quatre mois, marchand par marchand, la lecture balaie jusqu’au 20 septembre et mesure l’écart entre deux passages. Foncia Loyer, 520 euros le 5 de chaque mois, et EDF, de 36,40 à 41,20 euros le 8, reviennent tous les 30 ou 31 jours : Chaque mois, déjà payées ce mois-ci. Basic Fit, 29,99 euros, attendu le 10 septembre, n’est pas passé : en retard. Netflix, 14,99 euros, et Vinted, deux achats à un mois d’écart, sont à venir. Carrefour Market n’a aucun rythme. Le club d’escalade, prélevé à 50 jours d’écart, n’est pas vu. Chaque écart doit tomber dans une fenêtre : 6 à 8 jours pour chaque semaine, 25 à 35 pour chaque mois, 85 à 95 pour chaque trimestre, 350 à 380 pour chaque année ; il faut au moins deux passages et un montant à 15 % de sa médiane, qui devient le montant attendu. Sur le téléphone, l’onglet Récurrences de l’analyse montre en retard, à venir et payées, et 558,90 euros payés sur 622,38 attendus. Sur la fiche de l’achat Vinted, la ligne Répétition passe de Chaque mois à Aucune : ce marchand ne revient pas, il sort de la liste. Sur celle du club d’escalade, elle passe de Aucune à Chaque mois : il apparaît à venir, dans 1 jour. Le choix vaut pour toutes les opérations du marchand et passe avant la détection.');
};

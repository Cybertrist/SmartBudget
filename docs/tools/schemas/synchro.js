// La synchronisation à l'ouverture : ce que la banque renvoie, et ce que
// l'application en garde.
//
// À gauche, le téléphone s'ouvre et l'accueil dit « Synchronisation… ». Au
// milieu, les opérations renvoyées par la banque passent une à une : la
// déjà connue est ignorée à son identifiant, la comptabilisée remplace son
// attente en gardant ce qui a été fait à la main, les nouvelles sont
// classées et comptées. À droite, les opérations du téléphone.
module.exports = (O) => {
  const { svg, t, fondu, visible, paliers, toucher, P, APP, MONO, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, NEON, BLEU, OR, INTERNE } = O;
  const C = 26;
  const FIN = 0.97;
  let corps = '';
  corps += t(60, 52, 'LA SYNCHRONISATION', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + O.tr('LA SYNCHRONISATION').length * 10.9 + 24), 52, 'Elle part seule à l’ouverture. Rien ne compte deux fois, rien de ce que tu as corrigé ne se perd.', { taille: 14 });

  // Les cinq opérations renvoyées, dans l'ordre de la banque : les
  // comptabilisées d'abord, puis celles en attente.
  const ops = [
    { lib: 'CB LE FOURNIL 17/09', mt: '-3,80 €', statut: 'COMPTABILISÉE', id: 'id 7Q2K-0417', sorte: 'connue' },
    { lib: 'CB CARREFOUR MARKET 24/09', mt: '-54,20 €', statut: 'COMPTABILISÉE', id: 'id 7Q3H-2045', sorte: 'remplace' },
    { lib: 'PRLV SEPA FREE MOBILE', mt: '-19,99 €', statut: 'COMPTABILISÉE', id: 'id 7Q3F-1188', sorte: 'nouvelle' },
    { lib: 'VIR VERS LIVRET A DE CARTE BANCAIRE', mt: '-100,00 €', statut: 'COMPTABILISÉE', id: 'id 7Q3M-3310', sorte: 'interne' },
    { lib: 'CB SNCF CONNECT 26/09', mt: '-45,00 €', statut: 'EN ATTENTE', id: 'empreinte', sorte: 'attente' },
  ];
  const s = (i) => 0.16 + i * 0.11; // l'instant où chacune est jugée
  const SOLDE = 0.71, TERMINE = 0.77;
  const Y = (i) => 196 + i * 84; // le centre de chaque rangée
  const BX = 370, BL = 290, LX = 660, LL = 220, RX = 880, RL = 340;
  // De petits pictogrammes pour les tuiles, dessinés dans un carré de 16.
  const ICONE = {
    pain: (c) => `<path d="M2 11 C2 5 14 5 14 11 V13 H2 Z M6 7 V10 M10 7 V10" fill="none" stroke="${c}" stroke-width="1.6" stroke-linejoin="round"/>`,
    panier: (c) => `<path d="M1 3 H4 L6 11 H13 L15 5 H5" fill="none" stroke="${c}" stroke-width="1.6" stroke-linejoin="round"/><circle cx="7" cy="14" r="1.3" fill="${c}"/><circle cx="12" cy="14" r="1.3" fill="${c}"/>`,
    abonnement: (c) => `<path d="M13 6 A5.5 5.5 0 0 0 3 5 M3 10 A5.5 5.5 0 0 0 13 11 M3 2 V5 H6 M13 14 V11 H10" fill="none" stroke="${c}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>`,
    interne: (c) => `<path d="M2 5 H13 M10 2 L13 5 L10 8 M14 11 H3 M6 8 L3 11 L6 14" fill="none" stroke="${c}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>`,
    train: (c) => `<rect x="3" y="1.5" width="10" height="10" rx="2.5" fill="none" stroke="${c}" stroke-width="1.6"/><path d="M3 7 H13 M5 15 L6.5 11.5 M11 15 L9.5 11.5" stroke="${c}" stroke-width="1.6" stroke-linecap="round"/>`,
  };

  // ---------------------------------------------------------- le téléphone
  const PX = 60, PY = 100, PL = 280, PH = 562;
  const SX = PX + 10, SY = PY + 14, SL = PL - 20, SH = PH - 28;
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="36" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranSynchro"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="26"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="26" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 30}" y="${PY + 5}" width="60" height="5" rx="2.5" fill="#1B222C"/>`;
  let ecran = '';
  const OUVERT = 0.055;
  // L'ouverture : l'empreinte.
  ecran += `<g opacity="0">${visible(C, 0.004, OUVERT, 0.004)}
    <text x="${SX + SL / 2}" y="${SY + 220}" font-family="${O.SANS}" font-size="28" font-weight="800" text-anchor="middle" fill="${APP.texte}">Smart <tspan fill="${NEON}">Budget</tspan></text>
    ${t(SX + SL / 2, SY + 250, 'Votre argent. Vos projets. Votre avenir.', { taille: 11.5, couleur: APP.second, ancre: 'middle' })}
    <rect x="${SX + 40}" y="${SY + 290}" width="${SL - 80}" height="46" rx="23" fill="${VERT}"/>
    <g transform="translate(${SX + 78},${SY + 299})">${P.empreinte('#000000')}</g>
    ${t(SX + SL / 2 + 14, SY + 318, 'Ouvrir', { taille: 14, couleur: '#000000', poids: 800, ancre: 'middle' })}
    ${toucher(SX + SL / 2, SY + 313, C, 0.03)}
  </g>`;
  // L'accueil : avant, pendant, après.
  const avant = (a) => `<g>${paliers('opacity', C, [[0, 1], [a, 0]])}`;
  const apres = (a) => `<g opacity="0">${paliers('opacity', C, [[0, 0], [a, 1]])}`;
  const entre = (de, a) => `<g opacity="0">${paliers('opacity', C, [[0, 0], [de, 1], [a, 0]])}`;
  const DEBUT = 0.075;
  ecran += `<g opacity="0">${visible(C, OUVERT, FIN, 0.004)}
    <text x="${SX + 16}" y="${SY + 44}" font-family="${O.SANS}" font-size="19" font-weight="800" fill="${APP.texte}">Smart <tspan fill="${NEON}">Budget</tspan></text>
    ${t(SX + SL - 16, SY + 43, 'Septembre 2026', { taille: 11, couleur: APP.second, poids: 700, ancre: 'end' })}
    ${t(SX + 18, SY + 80, 'Sur tes comptes', { taille: 11.5, couleur: APP.second, poids: 600 })}
    ${avant(TERMINE)}${t(SX + 16, SY + 116, '4 244,52 €', { taille: 31, couleur: APP.texte, poids: 800 })}</g>
    ${apres(TERMINE)}${t(SX + 16, SY + 116, '4 125,33 €', { taille: 31, couleur: APP.texte, poids: 800 })}</g>
    ${avant(DEBUT)}${t(SX + 36, SY + 144, 'Mis à jour le 25 sept.', { taille: 11.5, couleur: APP.discret })}</g>
    ${entre(DEBUT, TERMINE)}
      <circle cx="${SX + 24}" cy="${SY + 140}" r="5" fill="none" stroke="${APP.discret}" stroke-width="1.6" stroke-dasharray="22 10">
        <animateTransform attributeName="transform" type="rotate" from="0 ${SX + 24} ${SY + 140}" to="360 ${SX + 24} ${SY + 140}" dur="0.9s" repeatCount="indefinite"/></circle>
      ${t(SX + 36, SY + 144, 'Synchronisation…', { taille: 11.5, couleur: APP.second })}</g>
    ${apres(TERMINE)}${t(SX + 36, SY + 144, 'Mis à jour le 26 sept.', { taille: 11.5, couleur: APP.discret })}</g>
    ${avant(DEBUT)}<path d="M${SX + 19} ${SY + 137} a5 5 0 1 1 1 7" fill="none" stroke="${APP.discret}" stroke-width="1.6"/></g>
    ${apres(TERMINE)}<path d="M${SX + 19} ${SY + 137} a5 5 0 1 1 1 7" fill="none" stroke="${APP.discret}" stroke-width="1.6"/></g>
    <rect x="${SX + 10}" y="${SY + 166}" width="${SL - 20}" height="160" rx="14" fill="${APP.carte}"/>
    ${t(SX + 24, SY + 192, 'MES COMPTES', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
    ${t(SX + SL - 24, SY + 192, '2 comptes', { taille: 10.5, couleur: APP.discret, ancre: 'end' })}
    <rect x="${SX + 24}" y="${SY + 208}" width="34" height="34" rx="10" fill="${VERT}" fill-opacity="0.16" stroke="${VERT}" stroke-opacity="0.5"/>
    <rect x="${SX + 32}" y="${SY + 219}" width="18" height="12" rx="2" fill="none" stroke="${VERT}" stroke-width="1.8"/><path d="M${SX + 32} ${SY + 223} h18" stroke="${VERT}" stroke-width="2"/>
    ${t(SX + 68, SY + 222, 'Compte courant', { taille: 12.5, couleur: APP.texte, poids: 700 })}
    ${t(SX + 68, SY + 238, 'Crédit Mutuel de Bretagne', { taille: 10, couleur: APP.discret })}
    ${avant(TERMINE)}${t(SX + SL - 22, SY + 222, '1 284,52 €', { taille: 12, couleur: APP.texte, police: MONO, poids: 700, ancre: 'end' })}</g>
    ${apres(TERMINE)}${t(SX + SL - 22, SY + 222, '1 065,33 €', { taille: 12, couleur: APP.texte, police: MONO, poids: 700, ancre: 'end' })}</g>
    <line x1="${SX + 24}" y1="${SY + 256}" x2="${SX + SL - 24}" y2="${SY + 256}" stroke="${APP.trait}"/>
    <rect x="${SX + 24}" y="${SY + 270}" width="34" height="34" rx="10" fill="${BLEU}" fill-opacity="0.16" stroke="${BLEU}" stroke-opacity="0.5"/>
    ${t(SX + 41, SY + 292, "€", { taille: 16, couleur: BLEU, poids: 800, ancre: "middle" })}
    ${t(SX + 68, SY + 284, 'Livret A', { taille: 12.5, couleur: APP.texte, poids: 700 })}
    ${t(SX + 68, SY + 300, 'Livret d’épargne', { taille: 10, couleur: APP.discret })}
    ${avant(s(3) + 0.02)}${t(SX + SL - 22, SY + 284, '2 960,00 €', { taille: 12, couleur: APP.texte, police: MONO, poids: 700, ancre: 'end' })}</g>
    ${apres(s(3) + 0.02)}${t(SX + SL - 22, SY + 284, '3 060,00 €', { taille: 12, couleur: BLEU, police: MONO, poids: 700, ancre: 'end' })}</g>
    <rect x="${SX + 10}" y="${SY + 340}" width="${(SL - 30) / 2}" height="118" rx="14" fill="${APP.carte}"/>
    <rect x="${SX + 20 + (SL - 30) / 2}" y="${SY + 340}" width="${(SL - 30) / 2}" height="118" rx="14" fill="${APP.carte}"/>
    ${t(SX + 24, SY + 366, 'BUDGET', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
    ${t(SX + 34 + (SL - 30) / 2, SY + 366, 'ÉPARGNE', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
    ${avant(TERMINE)}${t(SX + 24, SY + 398, '312,40 €', { taille: 18, couleur: VERT, poids: 800 })}</g>
    ${apres(TERMINE)}${t(SX + 24, SY + 398, '247,41 €', { taille: 18, couleur: VERT, poids: 800 })}</g>
    ${t(SX + 24, SY + 416, 'restants sur 1 500 €', { taille: 10, couleur: APP.second })}
    <rect x="${SX + 24}" y="${SY + 436}" width="${(SL - 30) / 2 - 28}" height="6" rx="3" fill="#2A2A2A"/>
    <rect x="${SX + 24}" y="${SY + 436}" height="6" rx="3" fill="${VERT}" width="${((SL - 30) / 2 - 28) * 0.79}">${paliers('width', C, [[0, ((SL - 30) / 2 - 28) * 0.79], [TERMINE, ((SL - 30) / 2 - 28) * 0.835]])}</rect>
    ${avant(s(3) + 0.02)}${t(SX + 34 + (SL - 30) / 2, SY + 398, '2 960,00 €', { taille: 15, couleur: APP.texte, poids: 800 })}${t(SX + 34 + (SL - 30) / 2, SY + 416, '59 % de 5 000 €', { taille: 10, couleur: APP.second })}</g>
    ${apres(s(3) + 0.02)}${t(SX + 34 + (SL - 30) / 2, SY + 398, '3 060,00 €', { taille: 15, couleur: APP.texte, poids: 800 })}${t(SX + 34 + (SL - 30) / 2, SY + 416, '61 % de 5 000 €', { taille: 10, couleur: APP.second })}</g>
    <g opacity="0">${visible(C, TERMINE + 0.01, FIN, 0.004)}
      <rect x="${SX + 10}" y="${SY + SH - 66}" width="${SL - 20}" height="42" rx="10" fill="#2E2E2E"/>
      ${t(SX + 24, SY + SH - 40, '3 nouvelles opérations.', { taille: 12, couleur: APP.texte })}
    </g>
  </g>`;
  corps += `<g clip-path="url(#ecranSynchro)">${ecran}</g>`;

  // ------------------------------------------------ ce que la banque renvoie
  corps += t(BX, 116, 'CE QUE LA BANQUE RENVOIE', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  corps += `<g opacity="0">${visible(C, 0.08, FIN, 0.006)}
    <rect x="${BX}" y="128" width="${BL}" height="28" rx="14" fill="${BLEU}" fill-opacity="0.1" stroke="${BLEU}" stroke-opacity="0.5"/>
    ${t(BX + 14, 146.5, 'depuis le 18 sept. : la dernière, moins 7 jours', { taille: 11.5, couleur: BLEU })}
  </g>`;
  corps += t(RX, 116, 'TES OPÉRATIONS, DANS LE TÉLÉPHONE', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });

  const couleurs = { connue: DISCRET, remplace: OR, nouvelle: VERT, interne: INTERNE, attente: VERT };
  const verdicts = {
    connue: ['déjà connue', 'même identifiant : ignorée'],
    remplace: ['remplace son attente', 'même marchand, même montant'],
    nouvelle: ['nouvelle · +1', 'classée : Abonnements'],
    interne: ['nouvelle · +1', 'virement interne : Livret A'],
    attente: ['nouvelle · +1', 'en attente, classée : Transports'],
  };
  ops.forEach((o, i) => {
    const y = Y(i), de = 0.1 + i * 0.012, c = couleurs[o.sorte];
    const attente = o.statut === 'EN ATTENTE';
    // La rangée de la banque.
    corps += `<g opacity="0">${visible(C, de, FIN, 0.006)}
      <rect x="${BX}" y="${y - 32}" width="${BL}" height="64" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${BX}" y="${y - 32}" width="${BL}" height="64" rx="12" fill="none" stroke="${c}" stroke-width="1.5" opacity="0">${visible(C, s(i), s(i) + 0.09, 0.006)}</rect>
      ${t(BX + 14, y - 8, o.lib, { taille: 11, couleur: TITRE, police: MONO, poids: 600 })}
      <rect x="${BX + 14}" y="${y + 5}" width="${attente ? 78 : 104}" height="18" rx="9" fill="${attente ? OR : TEXTE}" fill-opacity="0.12"/>
      ${t(BX + 14 + (attente ? 39 : 52), y + 17.5, o.statut, { taille: 9.5, couleur: attente ? OR : TEXTE, police: MONO, poids: 700, ancre: 'middle' })}
      ${t(BX + (attente ? 100 : 126), y + 18, o.id, { taille: 10, couleur: DISCRET, police: MONO })}
      ${t(BX + BL - 14, y + 18, o.mt, { taille: 11.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' })}
    </g>`;
    // Le paquet qui file vers le téléphone, et le verdict.
    const x1 = LX + 8, x2 = o.sorte === 'connue' ? LX + LL - 60 : RX - 10;
    const long = x2 - x1, a = s(i), b = a + 0.035;
    corps += `<g opacity="0">${visible(C, a, FIN, 0.004)}
      <line x1="${x1}" y1="${y}" x2="${x2}" y2="${y}" stroke="${c}" stroke-width="2" ${o.sorte === 'connue' ? 'stroke-opacity="0.6"' : ''} stroke-dasharray="${long}" stroke-dashoffset="${long}">
        ${fondu('stroke-dashoffset', C, [[0, long], [a, long], [b, 0], [1, 0]])}</line>
      <g opacity="0">${visible(C, b, FIN, 0.004)}${o.sorte === 'connue'
        ? `<path d="M${x2 + 2} ${y - 6} l12 12 M${x2 + 14} ${y - 6} l-12 12" stroke="${c}" stroke-width="2.2" stroke-linecap="round"/>`
        : `<path d="M${x2 - 7} ${y - 6} L${x2 + 1} ${y} L${x2 - 7} ${y + 6}" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`}</g>
      ${t(LX + LL / 2, y - 10, verdicts[o.sorte][0], { taille: 12, couleur: c === DISCRET ? TEXTE : c, poids: 700, ancre: 'middle' })}
      ${t(LX + LL / 2, y + 20, verdicts[o.sorte][1], { taille: 11, couleur: TEXTE, ancre: 'middle' })}
      ${o.sorte === 'remplace' ? t(LX + LL / 2, y + 36, 'nom, catégorie et note gardés', { taille: 11, couleur: OR, ancre: 'middle' }) : ''}
    </g>`;
    corps += `<g filter="url(#halo)" opacity="0">${fondu('opacity', C, [[0, 0], [a, 0], [a + 0.004, 1], [b, 1], [b + 0.006, 0], [1, 0]])}
      <circle cy="${y}" r="5.5" fill="${c}"><animate attributeName="cx" dur="${C}s" repeatCount="indefinite" keyTimes="0;${a};${b};1" values="${x1};${x1};${x2};${x2}" calcMode="spline" keySplines="0 0 1 1;0.45 0 0.25 1;0 0 1 1"/></circle>
    </g>`;
  });

  // ------------------------------------------------ les opérations du téléphone
  const rangee = (i, nom, mt, sous, { couleur = TITRE, ligne3 = '', c3 = DISCRET, tuile = VERT, icone = null } = {}) => {
    const y = Y(i);
    return `<rect x="${RX}" y="${y - 32}" width="${RL}" height="64" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${RX + 14}" y="${y - 15}" width="30" height="30" rx="9" fill="${tuile}" fill-opacity="0.16" stroke="${tuile}" stroke-opacity="0.55"/>
      ${icone ? `<g transform="translate(${RX + 21},${y - 8})">${ICONE[icone](tuile)}</g>` : ''}
      ${t(RX + 56, y - 7, nom, { taille: 13, couleur, poids: 700 })}
      ${t(RX + RL - 14, y - 7, mt, { taille: 11.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' })}
      ${sous ? t(RX + 56, y + 10, sous, { taille: 11, couleur: TEXTE }) : ''}
      ${ligne3 ? t(RX + 56, y + 25, ligne3, { taille: 10.5, couleur: c3 }) : ''}`;
  };
  const flash = (i, c, a) => `<rect x="${RX}" y="${Y(i) - 32}" width="${RL}" height="64" rx="12" fill="${c}" fill-opacity="0.08" stroke="${c}" stroke-width="1.5" opacity="0">${visible(C, a, a + 0.07, 0.006)}</rect>`;
  // 0. Déjà là : la banque la renvoie, rien ne change.
  corps += rangee(0, 'Le Fournil', '-3,80 €', 'Courses · Boulangerie', { icone: 'pain', tuile: '#50F48D', ligne3: 'id 7Q2K-0417', c3: DISCRET });
  corps += flash(0, TEXTE, s(0) + 0.035);
  corps += `<g opacity="0">${visible(C, s(0) + 0.035, FIN, 0.006)}${t(RX + RL - 14, Y(0) + 25, 'déjà là', { taille: 10.5, couleur: TEXTE, poids: 700, ancre: 'end' })}</g>`;
  // 1. L'attente, retouchée à la main, puis remplacée.
  const r1 = s(1) + 0.035;
  corps += rangee(1, 'Courses de la semaine', '-54,20 €', '', { tuile: NEON, icone: 'panier' });
  corps += `<g>${paliers('opacity', C, [[0, 1], [r1, 0]])}
    ${t(RX + 56, Y(1) + 10, 'En attente · Courses, à la main', { taille: 11, couleur: OR })}</g>`;
  corps += `<g opacity="0">${paliers('opacity', C, [[0, 0], [r1, 1]])}
    ${t(RX + 56, Y(1) + 10, 'Compte courant · Courses, à la main', { taille: 11, couleur: TEXTE })}</g>`;
  corps += t(RX + 56, Y(1) + 25, 'note : partagé avec Léa', { taille: 10.5, couleur: DISCRET });
  corps += flash(1, OR, r1);
  // 2 à 4. Les nouvelles, qui apparaissent.
  const nouvelle = (i, contenu, c) => `<g opacity="0">${visible(C, s(i) + 0.035, FIN, 0.006)}${contenu}</g>${flash(i, c, s(i) + 0.035)}`;
  corps += nouvelle(2, rangee(2, 'Free Mobile', '-19,99 €', 'Abonnements · Forfait mobile', { tuile: '#FF8FD1', icone: 'abonnement', ligne3: 'le dictionnaire l’a reconnue', c3: DISCRET }), VERT);
  corps += nouvelle(3, rangee(3, 'Livret A', '-100,00 €', 'Virements internes · Vers l’épargne', { tuile: INTERNE, icone: 'interne', ligne3: 'hors budget ; le Livret A monte de 100 €', c3: INTERNE }), INTERNE);
  corps += nouvelle(4, rangee(4, 'SNCF Connect', '-45,00 €', '', { tuile: '#9B8CFF', icone: 'train' }) + t(RX + 56, Y(4) + 10, 'En attente · Transports, Train', { taille: 11, couleur: OR }) + t(RX + 56, Y(4) + 25, 'remplacée quand la banque la comptabilise', { taille: 10.5, couleur: DISCRET }), VERT);
  // Les places vides, en attendant.
  for (let i = 2; i < 5; i++) {
    corps += `<g>${paliers('opacity', C, [[0, 1], [s(i) + 0.035, 0], [FIN, 1]])}<rect x="${RX}" y="${Y(i) - 32}" width="${RL}" height="64" rx="12" fill="none" stroke="${FIL}" stroke-dasharray="4 6"/></g>`;
  }

  // Le solde, puis le compteur.
  corps += `<g opacity="0">${visible(C, SOLDE, FIN, 0.006)}
    <rect x="${BX}" y="590" width="${BL}" height="52" rx="12" fill="${VERT}" fill-opacity="0.07" stroke="${VERT}" stroke-opacity="0.45"/>
    ${t(BX + 14, 611, 'puis le solde : 1 065,33 €', { taille: 12.5, couleur: TITRE, poids: 700 })}
    ${t(BX + 14, 629, 'comparé à zéro, comme le fait la veille', { taille: 11, couleur: TEXTE })}
  </g>`;
  corps += `<rect x="${RX}" y="590" width="${RL}" height="52" rx="12" fill="${CARTE}" stroke="${BORD}"/>
    ${t(RX + 16, 611, 'Le compteur', { taille: 12.5, couleur: TITRE, poids: 700 })}
    ${t(RX + 16, 629, 'la remplaçante ne compte pas : déjà annoncée', { taille: 11, couleur: TEXTE })}`;
  const compte = [[0, '0'], [s(2) + 0.035, '1'], [s(3) + 0.035, '2'], [s(4) + 0.035, '3']];
  compte.forEach(([de, n], k) => {
    const a = k + 1 < compte.length ? compte[k + 1][0] : null;
    const e = [[0, k === 0 ? 1 : 0]];
    if (k > 0) e.push([de, 1]);
    if (a) e.push([a, 0]);
    else e.push([FIN, 0]);
    if (k === 0) e.push([FIN, 1]);
    corps += `<g opacity="${k === 0 ? 1 : 0}">${paliers('opacity', C, e)}${t(RX + RL - 18, 628, n, { taille: 30, couleur: k === 0 ? DISCRET : VERT, police: MONO, poids: 800, ancre: 'end' })}</g>`;
  });

  // ------------------------------------------------ trois faits, en bas
  const faits = [
    ['Quand elle part', ['À l’ouverture, et à chaque retour dans l’appli', 'si la dernière a plus de dix minutes.', 'Sans bruit : un message s’il y a du neuf.']],
    ['Ce qu’elle relit', ['La première fois, les douze derniers mois.', 'Ensuite, depuis la dernière moins sept jours :', 'les retardataires sont rattrapées.']],
    ['L’accès, 180 jours', ['Accordé par ta banque, puis à renouveler.', 'La carte jaunit quinze jours avant ; ensuite,', '« Relier le compte », avec la même clé.']],
  ];
  const FY = 692, FL = 373, FH = 94;
  faits.forEach(([titre, lignes], k) => {
    const x = 60 + k * (FL + 20);
    corps += `<rect x="${x}" y="${FY}" width="${FL}" height="${FH}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${FY}" width="${FL}" height="${FH}" rx="13" fill="${[VERT, BLEU, OR][k]}" fill-opacity="0.05" stroke="${[VERT, BLEU, OR][k]}" stroke-opacity="0.3"/>
      ${t(x + 20, FY + 26, titre, { taille: 14, couleur: TITRE, police: MONO, poids: 700 })}
      ${lignes.map((l, j) => t(x + 20, FY + 47 + j * 17, l, { taille: 12 })).join('')}`;
  });
  // La jauge des 180 jours, dans la troisième carte.
  const jx = 60 + 2 * (FL + 20) + 230, jl = 124;
  corps += `<rect x="${jx}" y="${FY + 17}" width="${jl}" height="8" rx="4" fill="#1B232E"/>
    <rect x="${jx}" y="${FY + 17}" width="${jl * 142 / 180}" height="8" rx="4" fill="${VERT}"/>
    <rect x="${jx + jl * 165 / 180}" y="${FY + 17}" width="${jl * 15 / 180}" height="8" rx="2" fill="${OR}" fill-opacity="0.8"/>`;
  corps += t(jx + jl, FY + 40, 'encore 142 jours', { taille: 10.5, couleur: VERT, ancre: 'end' });

  svg('synchro.svg', 1280, 806, corps,
    'La synchronisation à l’ouverture. Le téléphone s’ouvre par l’empreinte, l’accueil affiche Synchronisation…, et l’application demande à la banque les opérations depuis le 18 septembre, la dernière synchronisation moins sept jours. Cinq opérations reviennent. CB LE FOURNIL, 3,80 euros, a un identifiant déjà connu : elle est ignorée, rien ne compte deux fois. CB CARREFOUR MARKET, 54,20 euros, désormais comptabilisée, remplace l’opération en attente du même marchand et du même montant, à une semaine près, et garde ce qui avait été fait à la main : le nom Courses de la semaine, la catégorie Courses et la note partagé avec Léa. PRLV SEPA FREE MOBILE, 19,99 euros, est nouvelle et classée dans Abonnements, Forfait mobile. VIR VERS LIVRET A DE CARTE BANCAIRE, 100 euros, est un virement interne, hors budget, et le Livret A passe de 2 960 à 3 060 euros. CB SNCF CONNECT, 45 euros, arrive en attente, classée dans Transports. Puis le solde est relu et comparé à zéro. Le compteur ne compte que les vraies nouvelles : trois, et l’accueil affiche 3 nouvelles opérations et Mis à jour le 26 sept. Elle part à l’ouverture et à chaque retour si la dernière a plus de dix minutes ; la première fois elle importe douze mois ; l’accès dure 180 jours et la carte de la banque prévient quinze jours avant.');
};

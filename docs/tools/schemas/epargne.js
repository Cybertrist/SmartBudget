// L'épargne et les livrets.
//
// La DSP2 ne donne que le compte courant : les livrets se saisissent à la
// main, avec leur solde, puis vivent au fil des virements repérés sur le
// compte courant. À gauche, le téléphone : l'écran Épargne, « Nouveau
// livret », puis l'écran Épargne qui suit chaque virement. À droite, d'où
// vient chaque chiffre : la banque, le compte courant et ses libellés,
// les livrets, le budget et ce qui reste hors budget.
//
// Tout suit le code : EcranEpargne et EcranNouveauLivret pour les
// libellés, reconnaitreInterne (VIR VERS <destination> DE <source>, CARTE
// BANCAIRE étant le compte courant), DepotOperations.importer (le solde
// d'un livret ne bouge qu'avec un virement postérieur au solde saisi, et
// pas tant qu'il est en attente) et calculerBilan (un virement interne
// n'est ni dépense ni revenu, il nourrit mis de côté et pioché).
module.exports = (O) => {
  const { svg, t, tr, visible, fondu, bille, fil, toucher, P, APP, MONO, CARTE, BORD, TITRE, TEXTE, DISCRET, FOND, FIL, VERT, BLEU, ROUGE, INTERNE } = O;
  const C = 30;
  const EPARGNE = BLEU;
  let corps = '';
  corps += t(60, 52, 'L’ÉPARGNE ET LES LIVRETS', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(330, 52, 'La banque ne montre que le compte courant : les livrets se saisissent une fois, puis suivent les virements.', { taille: 14 });

  // Les instants.
  const E1 = [0.004, 0.1], E2 = [0.1, 0.3], E3 = [0.3, 0.996];
  const tapAjouter = 0.075, tapLivret = 0.26, ajoute = 0.28;
  const v1 = 0.44, v2 = 0.58, v3 = 0.72;
  const durant = (de, a, contenu) => `<g opacity="0">${visible(C, de, a, 0.003)}${contenu}</g>`;

  // ---------------------------------------------------------------- téléphone
  const PX = 60, PY = 96, PL = 316, PH = 640;
  const SX = PX + 12, SY = PY + 16, SL = PL - 24, SH = PH - 32;
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="40" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranEpargne"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28"/></clipPath>
    <linearGradient id="lueurEpargne" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#123038" stop-opacity="0.55"/><stop offset="1" stop-color="#121212" stop-opacity="0"/></linearGradient>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 34}" y="${PY + 6}" width="68" height="5" rx="2.5" fill="#1B222C"/>`;
  const carteApp = (y, h, fond = APP.carte, x = SX + 12, l = SL - 24) => `<rect x="${x}" y="${SY + y}" width="${l}" height="${h}" rx="16" fill="${fond}"/>`;
  const surtitre = (x, y, s, couleur = APP.second) => t(x, SY + y, s, { taille: 10.5, couleur, poids: 700, extra: 'letter-spacing="1.5"' });
  const tirelire = (x, y, taille, couleur) => `<rect x="${x}" y="${y}" width="${taille}" height="${taille}" rx="${taille * 0.3}" fill="${couleur}" fill-opacity="0.14" stroke="${couleur}" stroke-opacity="0.4"/>
    <path transform="translate(${x + taille * 0.2},${y + taille * 0.2}) scale(${(taille * 0.6) / 960}) translate(0,960)" d="${require('../symboles.json').savings}" fill="${couleur}"/>`;
  const echange = (x, y, taille) => `<rect x="${x}" y="${y}" width="${taille}" height="${taille}" rx="${taille * 0.34}" fill="${INTERNE}" fill-opacity="0.1" stroke="${INTERNE}" stroke-opacity="0.3"/>
    <path d="M${x + taille * 0.24} ${y + taille * 0.38} H${x + taille * 0.74} l-4 -4 M${x + taille * 0.76} ${y + taille * 0.62} H${x + taille * 0.26} l4 4" fill="none" stroke="${INTERNE}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`;

  // L'écran Épargne, dans un état donné.
  const ecranEpargne = (e) => {
    let s = `<rect x="${SX}" y="${SY}" width="${SL}" height="220" fill="url(#lueurEpargne)"/>
      ${surtitre(SX + 20, 40, 'SUR TES LIVRETS')}
      ${t(SX + 20, SY + 72, 'Épargne', { taille: 26, couleur: APP.texte, poids: 800 })}
      ${t(SX + 20, SY + 104, 'Mis de côté au total', { taille: 12, couleur: APP.second, poids: 600 })}
      ${t(SX + 20, SY + 144, e.total, { taille: 34, couleur: APP.texte, poids: 800 })}
      ${t(SX + 20, SY + 170, e.mois, { taille: 12.5, couleur: e.couleurMois, poids: 700 })}`;
    // Mis de côté, pioché.
    const l = (SL - 36) / 2;
    s += `${carteApp(186, 70, '#181818', SX + 12, l)}${carteApp(186, 70, e.pioche === '0,00 €' ? '#181818' : '#2B1519', SX + 24 + l, l)}
      ${surtitre(SX + 26, 208, 'MIS DE CÔTÉ')}${surtitre(SX + 38 + l, 208, 'PIOCHÉ')}
      ${t(SX + 26, SY + 240, e.misDeCote, { taille: 19, couleur: VERT, poids: 800 })}
      ${t(SX + 38 + l, SY + 240, e.pioche, { taille: 19, couleur: ROUGE, poids: 800 })}`;
    // Mes livrets.
    const hL = 40 + e.livrets.length * 62;
    s += `${carteApp(268, hL)}
      ${surtitre(SX + 28, 292, 'MES LIVRETS')}
      ${t(SX + SL - 28, SY + 292, '+ Ajouter', { taille: 12, couleur: VERT, poids: 700, ancre: 'end' })}`;
    e.livrets.forEach(([nom, pct, montant, part], i) => {
      const y = 304 + i * 62;
      s += `<line x1="${SX + 28}" y1="${SY + y}" x2="${SX + SL - 28}" y2="${SY + y}" stroke="${APP.trait}"/>
        ${tirelire(SX + 28, SY + y + 9, 32, EPARGNE)}
        ${t(SX + 70, SY + y + 23, nom, { taille: 13.5, couleur: APP.texte, poids: 700 })}
        ${t(SX + 70, SY + y + 39, pct, { taille: 10.5, couleur: APP.discret })}
        ${t(SX + SL - 28, SY + y + 30, montant, { taille: 13.5, couleur: APP.texte, poids: 700, ancre: 'end' })}
        <rect x="${SX + 28}" y="${SY + y + 50}" width="${SL - 56}" height="5" rx="2.5" fill="#FFFFFF" fill-opacity="0.05"/>
        <rect x="${SX + 28}" y="${SY + y + 50}" width="${((SL - 56) * part).toFixed(1)}" height="5" rx="2.5" fill="${EPARGNE}"/>`;
    });
    // Mouvements repérés.
    const yM = 268 + hL + 12;
    s += `${carteApp(yM, SH - yM - 10)}
      ${surtitre(SX + 28, yM + 24, 'MOUVEMENTS REPÉRÉS')}
      ${t(SX + SL - 28, SY + yM + 24, 'Tous', { taille: 12, couleur: VERT, poids: 700, ancre: 'end' })}`;
    if (!e.mouvements.length) {
      s += t(SX + 28, SY + yM + 52, 'Aucun virement vers ou depuis un livret', { taille: 11.5, couleur: APP.second }) +
        t(SX + 28, SY + yM + 68, 'ce mois-ci.', { taille: 11.5, couleur: APP.second });
    }
    e.mouvements.forEach(([titre, detail, montant, couleur], i) => {
      const y = yM + 36 + i * 52;
      s += `<line x1="${SX + 28}" y1="${SY + y}" x2="${SX + SL - 28}" y2="${SY + y}" stroke="${APP.trait}"/>
        ${echange(SX + 28, SY + y + 10, 32)}
        ${t(SX + 70, SY + y + 24, titre, { taille: 12, couleur: APP.texte, poids: 700 })}
        ${t(SX + 70, SY + y + 40, detail, { taille: 10.5, couleur, poids: 700 })}
        ${t(SX + SL - 26, SY + y + 31, montant, { taille: 12, couleur, poids: 700, ancre: 'end' })}`;
    });
    return s;
  };
  const avant = {
    total: '1 800,00 €', mois: 'Rien de déplacé ce mois-ci', couleurMois: APP.second, misDeCote: '0,00 €', pioche: '0,00 €',
    livrets: [['LDDS', '100 % de l’épargne', '1 800,00 €', 1]], mouvements: [],
  };
  const mdc = ['Compte courant → Liv…', '15 sept. · mis de côté', '+200,00 €', VERT];
  const pio = ['Livret A → Compte c…', '22 sept. · pioché', '+100,00 €', ROUGE];
  const etats = [
    [E3[0], v1, {
      total: '5 000,00 €', mois: 'Rien de déplacé ce mois-ci', couleurMois: APP.second, misDeCote: '0,00 €', pioche: '0,00 €',
      livrets: [['LDDS', '36 % de l’épargne', '1 800,00 €', 0.36], ['Livret A', '64 % de l’épargne', '3 200,00 €', 0.64]], mouvements: [],
    }],
    [v1, v2, {
      total: '5 200,00 €', mois: '+200,00 € ce mois-ci', couleurMois: VERT, misDeCote: '+200,00 €', pioche: '0,00 €',
      livrets: [['LDDS', '35 % de l’épargne', '1 800,00 €', 0.346], ['Livret A', '65 % de l’épargne', '3 400,00 €', 0.654]], mouvements: [mdc],
    }],
    [v2, E3[1], {
      total: '5 100,00 €', mois: '+100,00 € ce mois-ci', couleurMois: VERT, misDeCote: '+200,00 €', pioche: '-100,00 €',
      livrets: [['LDDS', '35 % de l’épargne', '1 800,00 €', 0.353], ['Livret A', '65 % de l’épargne', '3 300,00 €', 0.647]], mouvements: [pio, mdc],
    }],
  ];

  let ecrans = '';
  ecrans += durant(...E1, `${ecranEpargne(avant)}
    <rect x="${SX + SL - 100}" y="${SY + 276}" width="80" height="26" rx="13" fill="${VERT}" fill-opacity="0.12" stroke="${VERT}" stroke-opacity="0.5" opacity="0">${visible(C, tapAjouter - 0.01, E1[1], 0.003)}</rect>
    ${toucher(SX + SL - 58, SY + 288, C, tapAjouter)}`);
  for (const [de, a, e] of etats) ecrans += durant(de, a, ecranEpargne(e));
  // Le livret ajouté s'allume à son arrivée, puis à chaque virement.
  const eclat = (de, a) => `<rect x="${SX + 16}" y="${SY + 370}" width="${SL - 32}" height="58" rx="12" fill="none" stroke="${EPARGNE}" stroke-opacity="0.8" filter="url(#halo)" opacity="0">${visible(C, de, a, 0.004)}</rect>`;
  ecrans += eclat(E3[0], E3[0] + 0.04) + eclat(v1, v1 + 0.04) + eclat(v2, v2 + 0.04);

  // « Nouveau livret ».
  const types = ['Livret A', 'LDDS', 'LEP', 'Livret jeune', 'PEL', 'CEL', 'Assurance vie', 'Autre'];
  let puces = '', px = SX + 28, py = 262;
  for (const [i, nom] of types.entries()) {
    const l = nom.length * 6.6 + 26;
    if (px + l > SX + SL - 26) { px = SX + 28; py += 34; }
    const actif = i === 0;
    puces += `<rect x="${px}" y="${SY + py}" width="${l}" height="28" rx="14" fill="${actif ? EPARGNE : '#1E1E1E'}" fill-opacity="${actif ? 0.12 : 1}" stroke="${actif ? EPARGNE : '#333333'}" stroke-opacity="${actif ? 0.45 : 1}"/>
      ${t(px + l / 2, SY + py + 18.5, nom, { taille: 11.5, couleur: actif ? APP.texte : APP.second, poids: actif ? 800 : 600, ancre: 'middle' })}`;
    px += l + 7;
  }
  const champ = (y, texte, couleur) => `<rect x="${SX + 28}" y="${SY + y}" width="${SL - 56}" height="32" rx="9" fill="#242424"/>
    ${t(SX + 40, SY + y + 21, texte, { taille: 12.5, couleur, poids: 600 })}`;
  ecrans += durant(...E2, `${t(SX + 18, SY + 46, '‹', { taille: 24, couleur: APP.texte })}
    ${t(SX + 38, SY + 46, 'Nouveau livret', { taille: 17, couleur: APP.texte, poids: 800 })}
    ${carteApp(64, 150)}
    ${tirelire(SX + SL / 2 - 24, SY + 78, 48, EPARGNE)}
    <g opacity="0">${visible(C, E2[0], 0.13, 0.003)}${t(SX + SL / 2 - 6, SY + 170, '0', { taille: 38, couleur: '#555555', poids: 800, ancre: 'middle' })}</g>
    <clipPath id="frappeSolde"><rect x="${SX + SL / 2 - 62}" y="${SY + 128}" height="52" width="0">${fondu('width', C, [[0, 0], [0.13, 0], [0.18, 118], [1, 118]])}</rect></clipPath>
    <g clip-path="url(#frappeSolde)">${t(SX + SL / 2 - 60, SY + 170, '3 200', { taille: 38, couleur: APP.texte, poids: 800 })}</g>
    ${t(SX + SL / 2 + 56, SY + 168, '€', { taille: 24, couleur: APP.second, poids: 700 })}
    ${t(SX + SL / 2, SY + 198, 'Solde actuel du livret', { taille: 12, couleur: APP.second, ancre: 'middle' })}
    ${carteApp(226, py - 226 + 44)}
    ${surtitre(SX + 28, 250, 'TYPE')}
    ${puces}
    ${carteApp(py + 56, 162)}
    ${surtitre(SX + 28, py + 78, 'NOM')}
    ${champ(py + 88, 'Livret A', APP.texte)}
    ${surtitre(SX + 28, py + 140, 'SUR TON RELEVÉ')}
    ${t(SX + 28, SY + py + 155, 'Le mot du libellé quand tu verses sur ce livret.', { taille: 9.5, couleur: APP.discret })}
    ${t(SX + 28, SY + py + 168, 'Laisse vide si c’est le nom.', { taille: 9.5, couleur: APP.discret })}
    ${champ(py + 176, 'LIVRET A', '#666666')}
    <rect x="${SX + 14}" y="${SY + SH - 62}" width="${SL - 28}" height="46" rx="23" fill="${VERT}"/>
    ${t(SX + SL / 2, SY + SH - 34, 'Ajouter le livret', { taille: 14.5, couleur: '#000000', poids: 800, ancre: 'middle' })}
    ${toucher(SX + SL / 2, SY + SH - 39, C, tapLivret)}`);
  corps += `<g clip-path="url(#ecranEpargne)">${ecrans}</g>`;

  // ------------------------------------------------------------- les comptes
  const noeud = (x, y, l, titre, sous, couleur, dessin) => `<rect x="${x}" y="${y}" width="${l}" height="70" rx="13" fill="${CARTE}" stroke="${BORD}"/>
    <rect x="${x}" y="${y + 14}" width="3" height="42" rx="1.5" fill="${couleur}"/>
    <g transform="translate(${x + 18},${y + 21})">${dessin(couleur)}</g>
    ${t(x + 58, y + 32, titre, { taille: 14.5, couleur: TITRE, police: MONO, poids: 700 })}
    ${t(x + 58, y + 51, sous, { taille: 12 })}`;
  const halo = (x, y, l, couleur, de, a) => `<rect x="${x}" y="${y}" width="${l}" height="70" rx="13" fill="none" stroke="${couleur}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, de, a, 0.004)}</rect>`;
  const tirelirePicto = (c) => `<path transform="scale(${28 / 960}) translate(0,960)" d="${require('../symboles.json').savings}" fill="${c}"/>`;
  const Y1 = 100;
  corps += fil('M630 135 H700') + fil('M920 135 H1000');
  // Les billes passent sous les cartes : elles ne se voient que sur les fils.
  corps += bille('M600 135 H730', C, '0;0;1;1', '0;0.02;0.08;1', VERT, 5);
  corps += bille('M890 135 H1030', C, '0;0;1;1', `0;${v1 - 0.05};${v1};1`, VERT, 5);
  corps += bille('M1030 135 H890', C, '0;0;1;1', `0;${v2 - 0.05};${v2};1`, ROUGE, 5);
  corps += noeud(420, Y1, 210, 'Ta banque', 'DSP2 : lecture seule', VERT, P.banque);
  const carteBancaire = (c) => `<rect x="1" y="5" width="26" height="18" rx="3" fill="none" stroke="${c}" stroke-width="2"/><path d="M1 10 H27 M5 18 H11" stroke="${c}" stroke-width="2"/>`;
  corps += noeud(700, Y1, 220, 'Compte courant', 'le seul qu’elle partage', TITRE, carteBancaire);
  corps += t(665, Y1 + 26, 'DSP2', { taille: 11, couleur: VERT, police: MONO, poids: 700, ancre: 'middle' });
  // Les livrets : jamais par la DSP2.
  corps += `<path d="M525 170 V236 H1000" fill="none" stroke="${ROUGE}" stroke-opacity="0.55" stroke-width="2" stroke-dasharray="4 6"/>
    <circle cx="760" cy="236" r="11" fill="${FOND}" stroke="${ROUGE}" stroke-width="2"/>
    <path d="M755 231 l10 10 M765 231 l-10 10" stroke="${ROUGE}" stroke-width="2.2" stroke-linecap="round"/>
    ${t(780, 256, 'les livrets ne passent pas par la DSP2', { taille: 12, couleur: ROUGE })}`;
  corps += noeud(1000, 186, 220, 'LDDS', 'saisi à la main', EPARGNE, tirelirePicto);
  corps += t(1204, 186 + 32, '1 800 €', { taille: 13.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' });
  // Le Livret A n'existe qu'une fois ajouté.
  corps += `<g>${fondu('opacity', C, [[0, 1], [ajoute, 1], [ajoute + 0.004, 0], [0.996, 0], [1, 1]])}
    <rect x="1000" y="${Y1}" width="220" height="70" rx="13" fill="${FOND}" stroke="${FIL}" stroke-dasharray="5 6"/>
    ${t(1110, Y1 + 40, '+ un livret, à la main', { taille: 12.5, couleur: DISCRET, ancre: 'middle' })}</g>`;
  const soldes = [[ajoute, v1, '3 200 €'], [v1, v2, '3 400 €'], [v2, 0.996, '3 300 €']];
  corps += durant(ajoute, 0.996, `${noeud(1000, Y1, 220, 'Livret A', 'saisi à la main', EPARGNE, tirelirePicto)}
    ${soldes.map(([de, a, s]) => durant(de, a, t(1204, Y1 + 32, s, { taille: 13.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' }))).join('')}`);
  corps += halo(1000, Y1, 220, EPARGNE, ajoute, ajoute + 0.05) + halo(1000, Y1, 220, VERT, v1, v1 + 0.05) + halo(1000, Y1, 220, ROUGE, v2, v2 + 0.05);

  // --------------------------------------------------- le compte courant, lu
  const LY = 288, LH = 188;
  corps += `<rect x="420" y="${LY}" width="800" height="${LH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>`;
  corps += t(444, LY + 28, 'SUR LE COMPTE COURANT', { taille: 12, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  corps += t(1196, LY + 28, 'VIR VERS <destination> DE <source>', { taille: 12, couleur: INTERNE, police: MONO, ancre: 'end' });
  const lignes = [
    ['VIR VERS LIVRET A DE CARTE BANCAIRE', '-200,00 €', 'vers le Livret A, depuis le compte courant', 'mis de côté', VERT, v1],
    ['VIR VERS CARTE BANCAIRE DE LIVRET A', '+100,00 €', 'vers le compte courant, depuis le Livret A', 'pioché', ROUGE, v2],
    ['CB CARREFOUR MARKET 23/09', '-64,30 €', 'ni VERS ni DE : un paiement', 'dépense · Courses', TITRE, v3],
  ];
  lignes.forEach(([libelle, montant, lu, verdict, couleur, s], i) => {
    const y = LY + 48 + i * 44;
    const interne = i < 2;
    corps += durant(s - 0.06, 0.996, `
      <rect x="436" y="${y}" width="768" height="40" rx="9" fill="#FFFFFF" fill-opacity="0.03"/>
      <rect x="436" y="${y}" width="768" height="40" rx="9" fill="none" stroke="${couleur}" stroke-opacity="0.6" opacity="0">${visible(C, s - 0.06, s + 0.02, 0.004)}</rect>
      ${t(452, y + 18, libelle, { taille: 12.5, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(452, y + 33, lu, { taille: 11, couleur: interne ? INTERNE : TEXTE })}
      ${t(862, y + 25, montant, { taille: 13, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' })}
      <g opacity="0">${visible(C, s - 0.03, 0.996, 0.004)}
        <rect x="${1188 - tr(verdict).length * 7.2 - 24}" y="${y + 8}" width="${tr(verdict).length * 7.2 + 24}" height="24" rx="12" fill="${couleur}" fill-opacity="0.12" stroke="${couleur}" stroke-opacity="0.55"/>
        ${t(1188 - (tr(verdict).length * 7.2 + 24) / 2, y + 24.5, verdict, { taille: 12, couleur, poids: 700, ancre: 'middle' })}
      </g>`);
  });

  // --------------------------------------------------- budget, hors budget
  const BY = 492, BH = 228, BL = 390;
  corps += `<rect x="420" y="${BY}" width="${BL}" height="${BH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>`;
  corps += t(444, BY + 28, 'LE BUDGET DU MOIS', { taille: 12, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const valeur = (x, y, etapes, opts) => etapes.map(([de, a, s]) => durant(de, a, t(x, y, s, opts))).join('');
  corps += t(444, BY + 70, 'Dépenses', { taille: 14, couleur: TITRE });
  corps += valeur(786, BY + 70, [[0.004, v3, '0,00 €'], [v3, 0.996, '64,30 €']], { taille: 15, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' });
  corps += `<line x1="444" y1="${BY + 90}" x2="786" y2="${BY + 90}" stroke="${BORD}"/>`;
  corps += t(444, BY + 120, 'Revenus', { taille: 14, couleur: TITRE });
  corps += t(786, BY + 120, '0,00 €', { taille: 15, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' });
  corps += t(444, BY + 168, 'Les 200 € mis de côté et les 100 € repris', { taille: 12.5 });
  corps += t(444, BY + 186, 'n’y entrent pas : l’argent n’a fait que', { taille: 12.5 });
  corps += t(444, BY + 204, 'changer de compte.', { taille: 12.5 });
  corps += `<rect x="420" y="${BY}" width="${BL}" height="${BH}" rx="14" fill="none" stroke="${TITRE}" stroke-opacity="0.6" filter="url(#halo)" opacity="0">${visible(C, v3, v3 + 0.05, 0.004)}</rect>`;

  const HX = 830;
  corps += `<rect x="${HX}" y="${BY}" width="${BL}" height="${BH}" rx="14" fill="url(#hachures)" stroke="#2A3542"/>
    <rect x="${HX}" y="${BY}" width="${BL}" height="${BH}" rx="14" fill="${FOND}" fill-opacity="0.55"/>`;
  corps += t(HX + 24, BY + 28, 'HORS BUDGET, L’ÉPARGNE', { taille: 12, couleur: INTERNE, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  corps += t(HX + 24, BY + 70, 'Mis de côté', { taille: 14, couleur: TITRE });
  corps += valeur(HX + BL - 24, BY + 70, [[0.004, v1, '0,00 €'], [v1, 0.996, '+200,00 €']], { taille: 15, couleur: VERT, police: MONO, poids: 700, ancre: 'end' });
  corps += t(HX + 24, BY + 110, 'Pioché', { taille: 14, couleur: TITRE });
  corps += valeur(HX + BL - 24, BY + 110, [[0.004, v2, '0,00 €'], [v2, 0.996, '-100,00 €']], { taille: 15, couleur: ROUGE, police: MONO, poids: 700, ancre: 'end' });
  corps += `<line x1="${HX + 24}" y1="${BY + 130}" x2="${HX + BL - 24}" y2="${BY + 130}" stroke="#2A3542"/>`;
  corps += t(HX + 24, BY + 160, 'Net ce mois-ci', { taille: 14, couleur: TITRE, poids: 700 });
  corps += valeur(HX + BL - 24, BY + 160, [[0.004, v1, '0,00 €'], [v1, v2, '+200,00 €'], [v2, 0.996, '+100,00 €']], { taille: 16, couleur: VERT, police: MONO, poids: 800, ancre: 'end' });
  corps += t(HX + 24, BY + 196, 'Ce que montre l’écran Épargne, à gauche.', { taille: 12.5, couleur: INTERNE });
  corps += `<rect x="${HX}" y="${BY}" width="${BL}" height="${BH}" rx="14" fill="none" stroke="${VERT}" stroke-opacity="0.6" filter="url(#halo)" opacity="0">${visible(C, v1, v1 + 0.05, 0.004)}</rect>`;
  corps += `<rect x="${HX}" y="${BY}" width="${BL}" height="${BH}" rx="14" fill="none" stroke="${ROUGE}" stroke-opacity="0.6" filter="url(#halo)" opacity="0">${visible(C, v2, v2 + 0.05, 0.004)}</rect>`;

  corps += t(640, 766, 'Seuls les virements arrivés après le solde saisi le font bouger. Toucher un livret corrige son solde, tel que ta banque l’affiche.', { taille: 13, couleur: DISCRET, ancre: 'middle' });

  svg('epargne.svg', 1280, 792, corps,
    'L’épargne et les livrets, sur un téléphone animé. La banque ne partage par la DSP2 que le compte courant : les livrets ne passent pas par elle et se saisissent à la main. Sur l’écran Épargne, où seul le LDDS de 1 800 euros existe, toucher Ajouter ouvre Nouveau livret : le solde actuel, 3 200 euros, le type Livret A, le nom, et le mot qui le désigne sur le relevé, puis Ajouter le livret. Ensuite, chaque virement lu sur le compte courant fait vivre son solde. VIR VERS LIVRET A DE CARTE BANCAIRE, 200 euros, va vers le Livret A depuis le compte courant : mis de côté, le livret passe à 3 400 euros. VIR VERS CARTE BANCAIRE DE LIVRET A, 100 euros, revient au compte courant : pioché, le livret passe à 3 300 euros. Un paiement chez Carrefour Market de 64,30 euros, lui, est une dépense. Le budget du mois ne compte que ces 64,30 euros de dépenses et aucun revenu : les virements internes restent hors budget. L’écran Épargne affiche 5 100 euros au total, plus 100 euros ce mois-ci, 200 euros mis de côté, 100 euros piochés, le Livret A à 65 pour cent de l’épargne et les deux mouvements repérés. Seuls les virements arrivés après le solde saisi le font bouger, et toucher un livret corrige son solde.');
};

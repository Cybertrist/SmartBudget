// Le modèle de confidentialité : ce qui est vrai, et ce qui ne l'est pas.
//
// Le téléphone au centre, le seul fil qui en sort va vers Enable Banking
// puis la banque, en lecture seule. Un regard curieux essaie chaque porte :
// les cinq premières tiennent (vert), puis, honnêtement, les six qui
// restent ouvertes (or). En bas, la liste complète, qui s'allume au
// passage de chaque porte : elle se lit aussi sans l'animation.
// Les faits viennent de lib/security, lib/banque/veille.dart,
// lib/donnees/sauvegarde.dart et du manifeste Android (allowBackup=false).
module.exports = (O) => {
  const { svg, t, fondu, visible, bille, fil, carte, P, APP, tr, MONO, SANS, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, NEON, BLEU, OR, ROUGE, INTERNE } = O;
  const C = 54, N = 12, PAS = 0.078;
  const S = (i) => 0.01 + i * PAS; // début de l'étape i
  const E = (i) => S(i) + PAS - 0.004; // fin de l'étape i
  const FIN = 0.985;
  const ROSE_ = O.ROSE; // le regard curieux
  const d = 0.004;
  let corps = '';

  // L'en-tête.
  corps += t(60, 52, 'CONFIDENTIALITÉ', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + tr('CONFIDENTIALITÉ').length * 10.9 + 24), 52, 'Un regard curieux essaie chaque porte : celles qui tiennent, puis celles qui restent ouvertes.', { taille: 14 });

  // Opacité par plages : [[de, a], ...].
  const plages = (brutes, bas = 0, haut = 1) => {
    // Deux plages qui se touchent n'en font qu'une.
    const liste = [];
    for (const [de, a] of brutes) {
      if (liste.length && de - liste.at(-1)[1] <= 2 * d) liste.at(-1)[1] = a;
      else liste.push([de, a]);
    }
    const e = [[0, liste[0][0] <= 0 ? haut : bas]];
    for (const [de, a] of liste) {
      if (de > 0) e.push([de - d, bas], [de, haut]);
      if (a < 1) e.push([a, haut], [a + d, bas]);
    }
    e.push([1, liste.at(-1)[1] >= 1 ? haut : bas]);
    return fondu('opacity', C, e);
  };

  // ---------------------------------------------------------- le téléphone
  const PX = 540, PY = 100, PL = 200, PH = 322;
  const SX = PX + 10, SY = PY + 12, SL = PL - 20, SH = PH - 24;
  const MX = SX + SL / 2;

  // Les écrans.
  const verrouille = `<text x="${MX}" y="${SY + 44}" font-family="${SANS}" font-size="17" font-weight="800" fill="${APP.texte}" text-anchor="middle">Smart <tspan fill="${NEON}">Budget</tspan></text>
    <circle cx="${MX}" cy="${SY + 150}" r="38" fill="${VERT}" fill-opacity="0.08" stroke="${VERT}" stroke-opacity="0.45"/>
    <g transform="translate(${MX - 28},${SY + 122}) scale(2)">${P.empreinte(VERT)}</g>
    ${t(MX, SY + 222, 'Pose ton doigt', { taille: 12, couleur: APP.second, ancre: 'middle' })}
    ${t(MX, SY + 240, 'pour ouvrir', { taille: 12, couleur: APP.second, ancre: 'middle' })}`;
  const ligne = (y, nom, mt, c) => `<rect x="${SX + 12}" y="${y}" width="24" height="24" rx="7" fill="${c}" fill-opacity="0.16" stroke="${c}" stroke-opacity="0.5"/>
    ${glyphe(y, c)}
    ${t(SX + 44, y + 10, nom, { taille: 10.5, couleur: APP.texte, poids: 700 })}
    ${t(SX + 44, y + 24, mt, { taille: 10, couleur: APP.second, police: MONO, poids: 700 })}`;
  // Une carte bancaire, ou le € du livret.
  function glyphe(y, c) {
    return c === VERT
      ? `<rect x="${SX + 17}" y="${y + 7}" width="14" height="10" rx="2" fill="none" stroke="${c}" stroke-width="1.6"/><path d="M${SX + 17} ${y + 10.5} h14" stroke="${c}" stroke-width="1.8"/>`
      : t(SX + 24, y + 17, '€', { taille: 13, couleur: c, poids: 800, ancre: 'middle' });
  }
  const ouvert = `<text x="${SX + 14}" y="${SY + 40}" font-family="${SANS}" font-size="15" font-weight="800" fill="${APP.texte}">Smart <tspan fill="${NEON}">Budget</tspan></text>
    ${t(SX + 14, SY + 72, 'Sur tes comptes', { taille: 10.5, couleur: APP.second, poids: 600 })}
    ${t(SX + 14, SY + 102, '4 125,33 €', { taille: 24, couleur: APP.texte, poids: 800 })}
    <rect x="${SX + 6}" y="${SY + 122}" width="${SL - 12}" height="86" rx="12" fill="${APP.carte}"/>
    ${ligne(SY + 132, 'Compte courant', '1 065,33 €', VERT)}
    <line x1="${SX + 14}" y1="${SY + 166}" x2="${SX + SL - 14}" y2="${SY + 166}" stroke="${APP.trait}"/>
    ${ligne(SY + 174, 'Livret A', '3 060,00 €', BLEU)}
    <rect x="${SX + 6}" y="${SY + 218}" width="${SL - 12}" height="66" rx="12" fill="${APP.carte}"/>
    ${t(SX + 16, SY + 240, 'BUDGET', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.4"' })}
    ${t(SX + 16, SY + 262, '247,41 €', { taille: 15, couleur: VERT, poids: 800 })}
    <rect x="${SX + 16}" y="${SY + 272}" width="${SL - 32}" height="5" rx="2.5" fill="#2A2A2A"/>
    <rect x="${SX + 16}" y="${SY + 272}" width="${(SL - 32) * 0.835}" height="5" rx="2.5" fill="${VERT}"/>`;
  const alerte = `${t(MX, SY + 70, '06:02', { taille: 36, couleur: APP.texte, poids: 300, ancre: 'middle' })}
    ${t(MX, SY + 92, 'Écran verrouillé', { taille: 10.5, couleur: APP.discret, ancre: 'middle' })}
    <rect x="${SX + 8}" y="${SY + 116}" width="${SL - 16}" height="92" rx="14" fill="#1A2230" stroke="${ROUGE}" stroke-opacity="0.5"/>
    <circle cx="${SX + 28}" cy="${SY + 136}" r="9" fill="${ROUGE}" fill-opacity="0.18" stroke="${ROUGE}"/>
    <path d="M${SX + 24} ${SY + 140} v-3 M${SX + 28} ${SY + 140} v-6 M${SX + 32} ${SY + 140} v-9" stroke="${ROUGE}" stroke-width="2" stroke-linecap="round"/>
    ${t(SX + 44, SY + 140, 'Smart Budget · maintenant', { taille: 9, couleur: APP.discret })}
    ${t(SX + 18, SY + 166, 'Compte courant en négatif', { taille: 11, couleur: APP.texte, poids: 700 })}
    ${t(SX + 18, SY + 184, 'Ton compte courant', { taille: 10.5, couleur: APP.second })}
    ${t(SX + 18, SY + 199, 'est à -42,10 €.', { taille: 10.5, couleur: APP.second })}
    <g opacity="0">${visible(C, S(10) + 0.02, E(10), d)}
      <circle cx="${MX}" cy="${SY + 238}" r="16" fill="none" stroke="${OR}" stroke-opacity="0.7" stroke-dasharray="3 4"/>
      <g transform="translate(${MX - 14},${SY + 224})">${P.cle(OR)}</g>
      ${t(MX, SY + 272, 'clé chargée', { taille: 10, couleur: OR, police: MONO, poids: 700, ancre: 'middle' })}
      ${t(MX, SY + 286, 'sans empreinte', { taille: 10, couleur: OR, police: MONO, poids: 700, ancre: 'middle' })}
    </g>`;
  const reglages = `${t(SX + 14, SY + 44, 'Réglages', { taille: 19, couleur: APP.texte, poids: 800 })}
    <rect x="${SX + 6}" y="${SY + 70}" width="${SL - 12}" height="110" rx="12" fill="${APP.carte}"/>
    ${t(SX + 16, SY + 92, 'SÉCURITÉ', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.4"' })}
    ${t(SX + 16, SY + 124, 'Empreinte à l’ouverture', { taille: 9.5, couleur: APP.texte, poids: 600 })}
    <line x1="${SX + 16}" y1="${SY + 142}" x2="${SX + SL - 16}" y2="${SY + 142}" stroke="${APP.trait}"/>
    ${t(SX + 16, SY + 166, 'Verrouiller après', { taille: 10, couleur: APP.texte, poids: 600 })}
    ${t(SX + SL - 16, SY + 166, '1 minute', { taille: 9.5, couleur: APP.discret, ancre: 'end' })}
    <g transform="translate(0,${SY + 120})">
      <rect x="${SX + SL - 40}" y="-9" width="28" height="18" rx="9" fill="${VERT}">${fondu('fill', C, [[0, VERT], [S(11) + 0.018, VERT], [S(11) + 0.022, '#3A3A3A'], [1, '#3A3A3A']])}</rect>
    </g>
    <circle cx="${SX + SL - 21}" cy="${SY + 120}" r="6" fill="#000000">
      ${fondu('cx', C, [[0, SX + SL - 21], [S(11) + 0.018, SX + SL - 21], [S(11) + 0.022, SX + SL - 31], [1, SX + SL - 31]])}
      ${fondu('fill', C, [[0, '#000000'], [S(11) + 0.018, '#000000'], [S(11) + 0.022, '#9A9A9A'], [1, '#9A9A9A']])}</circle>
    <circle cx="${SX + SL - 26}" cy="${SY + 120}" r="10" fill="none" stroke="#FFFFFF" stroke-width="2" opacity="0">
      ${fondu('opacity', C, [[0, 0], [S(11) + 0.016, 0], [S(11) + 0.018, 0.8], [S(11) + 0.04, 0], [1, 0]])}
      ${fondu('r', C, [[0, 10], [S(11) + 0.016, 10], [S(11) + 0.04, 28], [1, 28]])}</circle>
    <rect x="${SX + 6}" y="${SY + 196}" width="${SL - 12}" height="60" rx="12" fill="${OR}" fill-opacity="0.08" stroke="${OR}" stroke-opacity="0.5" opacity="0">${visible(C, S(11) + 0.026, S(11) + 0.05, d)}</rect>
    <g opacity="0">${visible(C, S(11) + 0.026, S(11) + 0.05, d)}
      ${t(MX, SY + 222, 'Plus de preuve', { taille: 11, couleur: OR, poids: 700, ancre: 'middle' })}
      ${t(MX, SY + 240, 'à l’ouverture', { taille: 11, couleur: OR, poids: 700, ancre: 'middle' })}
    </g>`;

  // Les portes : des plaques sur le flanc gauche du téléphone.
  const PLX = PX - 46, PLT = 36;
  const icVirement = (c) => `<path d="M3 10 H23 M18 5 L23 10 L18 15 M25 19 H5 M10 14 L5 19 L10 24" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`;
  const icEcran = (c) => `<rect x="4" y="3" width="20" height="22" rx="3" fill="none" stroke="${c}" stroke-width="2"/><circle cx="14" cy="14" r="4" fill="none" stroke="${c}" stroke-width="2"/><path d="M9 3 L11 0 H17 L19 3" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/>`;
  // [y, icône, étape où le regard l'essaie]
  const portes = [
    [150, icEcran, 5],
    [206, P.base, 1],
    [262, P.cle, 2],
    [318, P.cadenas, 3],
    [374, icVirement, 4],
  ];
  let plaques = '';
  for (const [y, ic, i] of portes) {
    const x = PLX, y0 = y - PLT / 2;
    plaques += `<line x1="${x + PLT}" y1="${y}" x2="${PX}" y2="${y}" stroke="${FIL}" stroke-width="2"/>
      <rect x="${x}" y="${y0}" width="${PLT}" height="${PLT}" rx="10" fill="${CARTE}" stroke="${BORD}"/>
      <g transform="translate(${x + 4},${y0 + 4})">${ic(DISCRET)}</g>
      <g opacity="0">${visible(C, S(i) + 0.03, FIN, d)}
        <rect x="${x}" y="${y0}" width="${PLT}" height="${PLT}" rx="10" fill="#10251A" stroke="${VERT}"/>
        <g transform="translate(${x + 4},${y0 + 4})">${ic(VERT)}</g>
        <circle cx="${x + 2}" cy="${y0 + 2}" r="7" fill="${VERT}"/>
        <path d="M${x - 1.5} ${y0 + 2} l2.5 2.5 l4.5 -5" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      </g>
      <circle cx="${x + PLT / 2}" cy="${y}" r="18" fill="none" stroke="${VERT}" stroke-width="2" opacity="0">
        ${fondu('opacity', C, [[0, 0], [S(i) + 0.03, 0], [S(i) + 0.032, 0.9], [S(i) + 0.06, 0], [1, 0]])}
        ${fondu('r', C, [[0, 18], [S(i) + 0.03, 18], [S(i) + 0.06, 40], [1, 40]])}</circle>`;
  }
  // La clé maîtresse, chargée sans empreinte par la veille : la porte
  // passe à l'or le temps de l'étape.
  plaques += `<g opacity="0">${visible(C, S(10) + 0.02, E(10), d)}
    <rect x="${PLX}" y="${262 - PLT / 2}" width="${PLT}" height="${PLT}" rx="10" fill="#261F0E" stroke="${OR}" filter="url(#halo)"/>
    <g transform="translate(${PLX + 4},${262 - PLT / 2 + 4})">${P.cle(OR)}</g>
    <circle cx="${PLX + 2}" cy="${262 - PLT / 2 + 2}" r="7" fill="${OR}"/>
    <path d="M${PLX + 2} ${262 - PLT / 2 - 1.5} v3.5 M${PLX + 2} ${262 - PLT / 2 + 5} v0.5" stroke="#000000" stroke-width="2" stroke-linecap="round"/>
  </g>`;

  const telephone = `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="34" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranConf"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="24"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="24" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 28}" y="${PY + 5}" width="56" height="5" rx="2.5" fill="#1B222C"/>
    <g clip-path="url(#ecranConf)">
      <g>${plages([[0, S(7)], [FIN, 1]])}${verrouille}</g>
      <g opacity="0">${plages([[S(7), S(9)], [S(11) + 0.05, FIN]])}${ouvert}</g>
      <g opacity="0">${plages([[S(10), E(10)]])}${alerte}</g>
      <g opacity="0">${plages([[S(11), S(11) + 0.05]])}${reglages}</g>
    </g>
    ${plaques}`;
  // Perdu : le téléphone s'efface, il ne reste qu'un contour.
  corps += `<g>${fondu('opacity', C, [[0, 1], [S(9), 1], [S(9) + 0.02, 0.1], [E(9) - 0.01, 0.1], [E(9) + 0.01, 1], [1, 1]])}${telephone}</g>`;
  corps += `<g opacity="0">${visible(C, S(9) + 0.02, E(9) - 0.01, d)}
    <rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="34" fill="none" stroke="${OR}" stroke-width="2" stroke-dasharray="8 8"/>
    ${t(MX, PY + PH / 2 - 4, '?', { taille: 64, couleur: OR, poids: 300, ancre: 'middle' })}
    ${t(MX, PY + PH / 2 + 34, 'la clé est partie', { taille: 12, couleur: OR, police: MONO, poids: 700, ancre: 'middle' })}
    ${t(MX, PY + PH / 2 + 52, 'avec lui', { taille: 12, couleur: OR, police: MONO, poids: 700, ancre: 'middle' })}
  </g>`;

  // --------------------------------------------- Enable Banking et la banque
  const EX = 900, EL = 320, EH = 64, EY = 104, BY = 250;
  const aller = `M${PX + PL} 150 C820 150 820 ${EY + EH / 2} ${EX} ${EY + EH / 2} H1060 V${BY + EH / 2}`;
  const retour = `M1060 ${BY + EH / 2} V${EY + EH / 2} H${EX} C820 ${EY + EH / 2} 820 150 ${PX + PL} 150`;
  let flux = fil(`M${PX + PL} 150 C820 150 820 ${EY + EH / 2} ${EX} ${EY + EH / 2}`, BLEU) + fil(`M1060 ${EY + EH} V${BY}`, INTERNE);
  flux += bille(aller, 5, '0;1', '0;1', VERT, 4) + bille(retour, 5, '0;0;1', '0;0.5;1', BLEU, 4);
  corps += `<g>${fondu('opacity', C, [[0, 1], [S(9), 1], [S(9) + 0.02, 0.15], [E(9) - 0.01, 0.15], [E(9) + 0.01, 1], [1, 1]])}${flux}</g>`;
  corps += t(815, 122, 'le seul fil', { taille: 12, couleur: BLEU, police: MONO, poids: 700, ancre: 'middle' });
  corps += carte(EX, EY, EL, EH, 'Enable Banking', 'l’agrégateur agréé, accès DSP2', BLEU, { icone: P.nuage });
  corps += carte(EX, BY, EL, EH, 'Ta banque', 'le compte courant', INTERNE, { icone: P.banque });
  // Enable Banking voit passer les opérations.
  corps += `<g opacity="0">${visible(C, S(6) + 0.01, E(6), d)}
    <rect x="${EX}" y="${EY}" width="${EL}" height="${EH}" rx="13" fill="none" stroke="${OR}" stroke-width="1.5" filter="url(#halo)"/>
    <rect x="${EX + EL - 78}" y="${EY + 20}" width="64" height="24" rx="12" fill="${OR}" fill-opacity="0.14" stroke="${OR}" stroke-opacity="0.7"/>
    <g transform="translate(${EX + EL - 46},${EY + 32})"><path d="M-14 0 Q0 -10 14 0 Q0 10 -14 0 Z" fill="none" stroke="${OR}" stroke-width="1.8"/><circle r="3.6" fill="${OR}"/></g>
  </g>`;
  // Lecture seule, 180 jours.
  const LX = 1074;
  corps += t(LX, 198, 'lecture seule', { taille: 12, couleur: TITRE, police: MONO, poids: 700 });
  corps += t(LX, 218, 'accès : 180 jours', { taille: 12, couleur: TEXTE, police: MONO });
  corps += `<rect x="${LX}" y="228" width="130" height="5" rx="2.5" fill="#1D2530"/>
    <rect x="${LX}" y="228" width="130" height="5" rx="2.5" fill="${BLEU}">${fondu('width', C, [[0, 130], [S(4) + 0.02, 130], [E(4) - 0.01, 0], [E(4), 0], [E(4) + 0.01, 130], [1, 130]])}</rect>`;
  corps += `<g opacity="0">${visible(C, E(4) - 0.012, E(4), d)}${t(LX + 136, 233, 'expiré', { taille: 10.5, couleur: ROUGE, police: MONO, poids: 700 })}</g>`;
  // Un virement tente de partir : il s'arrête à mi-chemin.
  const courbe = `M${PX + PL} 150 C820 150 820 ${EY + EH / 2} ${EX} ${EY + EH / 2}`;
  corps += `<g opacity="0" filter="url(#halo)">${visible(C, S(4) + 0.012, S(4) + 0.04, d)}
    <circle r="6" fill="${ROUGE}"><animateMotion dur="${C}s" repeatCount="indefinite" path="${courbe}" keyPoints="0;0;0.5;0.5" keyTimes="0;${S(4) + 0.012};${S(4) + 0.03};1" calcMode="linear"/></circle>
  </g>`;
  corps += `<g opacity="0">${visible(C, S(4) + 0.03, E(4), d)}
    <circle cx="820" cy="143" r="12" fill="${FOND}" stroke="${ROUGE}" stroke-width="2"/>
    <path d="M815 138 l10 10 M825 138 l-10 10" stroke="${ROUGE}" stroke-width="2.4" stroke-linecap="round"/>
    ${t(820, 176, 'aucun virement', { taille: 12, couleur: ROUGE, police: MONO, poids: 700, ancre: 'middle' })}
  </g>`;
  // Rien d'autre : ni serveur, ni compte, ni analytique, ni publicité.
  const RY = 388;
  corps += `<path d="M${PX + PL} ${RY} H880" stroke="${FIL}" stroke-width="2" stroke-dasharray="3 6"/>`;
  corps += t(812, RY - 12, 'rien d’autre', { taille: 12, couleur: DISCRET, police: MONO, poids: 700, ancre: 'middle' });
  corps += `<g opacity="0">${visible(C, S(0) + 0.03, FIN, d)}
    <circle cx="858" cy="${RY}" r="10" fill="${FOND}" stroke="${VERT}" stroke-width="2"/>
    <path d="M854 ${RY - 4} l8 8 M862 ${RY - 4} l-8 8" stroke="${VERT}" stroke-width="2.2" stroke-linecap="round"/>
  </g>`;
  ['serveur', 'compte', 'analytique', 'publicité'].forEach((s, k) => {
    const x = EX + k * 82, l = 74;
    corps += `<rect x="${x}" y="${RY - 16}" width="${l}" height="32" rx="16" fill="${CARTE}" stroke="${BORD}"/>
      ${t(x + l / 2, RY + 4.5, s, { taille: 11.5, couleur: TEXTE, ancre: 'middle' })}
      <line x1="${x + 10}" y1="${RY + 0.5}" x2="${x + 10}" y2="${RY + 0.5}" stroke="${VERT}" stroke-width="1.8">
        ${fondu('x2', C, [[0, x + 10], [S(0) + 0.03 + k * 0.006, x + 10], [S(0) + 0.045 + k * 0.006, x + l - 10], [FIN, x + l - 10], [FIN + 0.005, x + 10], [1, x + 10]])}</line>`;
  });

  // La veille, toutes les six heures.
  corps += `<g opacity="0">${visible(C, S(10) + 0.01, E(10), d)}
    <rect x="${PX + PL + 14}" y="228" width="136" height="34" rx="17" fill="${OR}" fill-opacity="0.12" stroke="${OR}" stroke-opacity="0.7"/>
    <g transform="translate(${PX + PL + 20},231)">${P.horloge(OR)}</g>
    ${t(PX + PL + 54, 250, 'toutes les 6 h', { taille: 11.5, couleur: OR, police: MONO, poids: 700 })}
  </g>`;

  // La sauvegarde qui voyage.
  const FX = 150, FY = 322;
  corps += `<g opacity="0">${visible(C, S(8), E(8), d)}
    <animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${S(8)};${S(8) + 0.022};1" values="330 0;330 0;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.3 0 0.2 1;0 0 1 1"/>
    <rect x="${FX}" y="${FY}" width="210" height="60" rx="12" fill="${CARTE}" stroke="${OR}" stroke-opacity="0.7"/>
    <g transform="translate(${FX + 14},${FY + 16})">${P.fichier(OR)}</g>
    ${t(FX + 52, FY + 26, 'smartbudget.sbx', { taille: 12.5, couleur: TITRE, police: MONO, poids: 700 })}
    ${t(FX + 52, FY + 45, 'phrase : ••••••••', { taille: 11.5, couleur: OR, police: MONO })}
  </g>`;

  // ------------------------------------------------------ le regard curieux
  // Sa place à chaque étape.
  const places = [
    [800, 432], [440, 206], [440, 262], [440, 318], [440, 374], [440, 150],
    [440, 150], [505, 84], [405, 352], [440, 262], [505, 84], [505, 84],
  ];
  const kt = [0], kv = [places[0]];
  for (let i = 1; i < N; i++) { kt.push(S(i), S(i) + 0.016); kv.push(places[i - 1], places[i]); }
  kt.push(FIN, 1); kv.push(places[N - 1], places[0]);
  const lisse = kt.slice(1).map(() => '0.45 0 0.25 1').join(';');
  // Estompé quand ce n'est pas lui qui regarde.
  const presence = fondu('opacity', C, [[0, 1], [S(6), 1], [S(6) + 0.01, 0.3], [E(6), 0.3], [S(7), 1], [S(9), 1], [S(9) + 0.01, 0.3], [E(9), 0.3], [S(10), 1], [1, 1]]);
  corps += `<g>${presence}
    <animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="${kt.join(';')}" values="${kv.map((p) => p.join(' ')).join(';')}" calcMode="spline" keySplines="${lisse}"/>
    <g filter="url(#halo)">
      <path d="M-22 0 Q0 -17 22 0 Q0 17 -22 0 Z" fill="${FOND}" stroke="${ROSE_}" stroke-width="2.2"/>
      <circle r="7.5" fill="none" stroke="${ROSE_}" stroke-width="2"/>
      <circle r="3.5" fill="${ROSE_}"/>
    </g>
  </g>`;
  // Le regard qui vise la porte.
  for (const [y, , i] of portes) {
    corps += `<line x1="466" y1="${y}" x2="${PLX - 4}" y2="${y}" stroke="${ROSE_}" stroke-width="2" stroke-dasharray="4 4" opacity="0">${visible(C, S(i) + 0.016, S(i) + 0.03, d)}</line>`;
  }
  // Par-dessus l'épaule.
  for (const i of [7, 10, 11]) {
    corps += `<path d="M522 96 L${PX + 20} ${PY + 22}" stroke="${OR}" stroke-width="2" stroke-dasharray="4 4" opacity="0">${visible(C, S(i) + 0.018, E(i), d)}</path>`;
  }

  // --------------------------------------------------------- les légendes
  const KX = 60, KY = 112, KL = 336, KH = 178;
  const etapes = [
    ['Trouver un serveur qui garde tout', ['Il n’y en a pas : l’application ne parle', 'qu’à Enable Banking, pour lire le compte.']],
    ['Lire le fichier de la base', ['Du bruit : SQLCipher chiffre la base entière,', 'et sa clé n’est pas posée à côté.']],
    ['Prendre la clé en mémoire', ['Elle n’y est pas : le Keystore ne la donne', 'qu’après l’empreinte.']],
    ['Voler la clé bancaire', ['Chiffrée en AES-GCM par une clé dérivée,', 'dans une base elle-même chiffrée.']],
    ['Faire partir un virement', ['Impossible : la DSP2 ne donne que la lecture,', 'et l’accès expire au bout de 180 jours.']],
    ['Capturer l’écran', ['Capture noire, aperçu du multitâche masqué,', 'sauvegarde Android refusée.']],
    ['Regarder passer les opérations', ['Enable Banking les voit, le temps de les', 'transmettre : c’est lui qui lit la banque.']],
    ['Regarder par-dessus l’épaule', ['L’application ouverte montre tout :', 'l’empreinte protège l’accès, pas ton épaule.']],
    ['Deviner la phrase d’une sauvegarde', ['Le fichier voyage, et vaut ce que vaut sa', 'phrase. Sans elle, il est perdu pour tous.']],
    ['Le téléphone est perdu', ['Ce qui n’a pas été sauvegardé l’est aussi :', 'la clé ne se recopie nulle part.']],
    ['Lire l’écran verrouillé', ['Toutes les six heures, la veille charge la clé', 'sans empreinte ; l’alerte montre le montant.']],
    ['Ouvrir sans empreinte', ['Coupée dans les réglages, elle ne protège', 'plus : les données s’ouvrent sans preuve.']],
  ];
  corps += `<rect x="${KX}" y="${KY}" width="${KL}" height="${KH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>`;
  etapes.forEach(([quoi, verdict], i) => {
    const ferme = i < 6, c = ferme ? VERT : OR;
    corps += `<g opacity="0">${visible(C, S(i), E(i), d)}
      <rect x="${KX}" y="${KY}" width="${KL}" height="${KH}" rx="14" fill="none" stroke="${c}" stroke-opacity="0.7"/>
      ${t(KX + 22, KY + 32, ferme ? 'IL ESSAIE' : 'CE QUI RESTE OUVERT', { taille: 11, couleur: ROSE_, police: MONO, poids: 700, extra: 'letter-spacing="2"' })}
      ${t(KX + KL - 20, KY + 32, `${ferme ? i + 1 : i - 5} / 6`, { taille: 11, couleur: DISCRET, police: MONO, ancre: 'end' })}
      ${t(KX + 22, KY + 60, quoi, { taille: 15, couleur: TITRE, poids: 700 })}
      ${verdict.map((l, k) => t(KX + 22, KY + 88 + k * 19, l, { taille: 13 })).join('')}
      <rect x="${KX + 22}" y="${KY + KH - 44}" width="${ferme ? 124 : 138}" height="28" rx="14" fill="${c}" fill-opacity="0.14" stroke="${c}" stroke-opacity="0.7"/>
      ${t(KX + 22 + (ferme ? 62 : 69), KY + KH - 25, ferme ? 'porte fermée' : 'porte ouverte', { taille: 12, couleur: c, police: MONO, poids: 700, ancre: 'middle' })}
    </g>`;
  });
  // Entre deux cycles, la légende attend.
  corps += `<g opacity="0">${plages([[S(N), 1]])}
    ${t(KX + KL / 2, KY + KH / 2 - 6, '6 portes fermées', { taille: 15, couleur: VERT, police: MONO, poids: 700, ancre: 'middle' })}
    ${t(KX + KL / 2, KY + KH / 2 + 18, '6 restées ouvertes', { taille: 15, couleur: OR, police: MONO, poids: 700, ancre: 'middle' })}
  </g>`;

  // ---------------------------------------------- la liste, toujours lisible
  const vrai = [
    ['Aucun serveur à moi.', ['L’application ne parle qu’à Enable Banking, pour lire le compte.', 'Pas de compte, pas d’analytique, pas de publicité.'], [0]],
    ['La base est chiffrée par SQLCipher.', ['Sa clé vit dans le Keystore et n’est chargée qu’après l’empreinte,', 'hors la veille du solde.'], [1, 2]],
    ['La clé bancaire est chiffrée deux fois', ['En AES-GCM par une clé dérivée, dans une base elle-même chiffrée.'], [3]],
    ['La DSP2 ne donne que la lecture.', ['Aucun virement ne peut partir de l’application,', 'et l’accès expire au bout de 180 jours.'], [4]],
    ['L’écran est protégé', ['Captures bloquées, aperçu du multitâche masqué, sauvegarde Android refusée.'], [5]],
  ];
  const pas = [
    ['Enable Banking voit passer les opérations', ['le temps de les transmettre : c’est l’agrégateur agréé qui lit la banque.'], [6]],
    ['L’application ouverte montre tout.', ['L’empreinte protège l’accès, pas ton épaule.'], [7]],
    ['Une sauvegarde voyage et vaut ce que vaut sa phrase.', ['Sans la phrase, elle est perdue, pour tout le monde.'], [8]],
    ['Perdre le téléphone, c’est perdre les données', ['qui n’ont pas été sauvegardées : la clé ne se recopie nulle part.'], [9]],
    ['La veille du solde se passe d’empreinte', ['Toutes les six heures, la clé est chargée le temps de lire le solde,', 'et l’alerte montre le montant sur l’écran verrouillé.'], [10]],
    ['L’empreinte se coupe', ['dans les réglages ; les données restent chiffrées, mais s’ouvrent sans preuve.'], [11]],
  ];
  const HY = 486, LY = 506, LH = 19, GAP = 10, CL = 568;
  const hauteur = (n) => 42 + (n - 1) * LH;
  const total = pas.reduce((s, [, l]) => s + hauteur(l.length + 1), 0) + (pas.length - 1) * GAP;
  const colonne = (x, titre, liste, c, marque) => {
    let s = `<g transform="translate(${x},${HY - 18})">${marque === '✓'
      ? `<path d="M11 1 L20 5 V11 C20 17 16 21 11 23 C6 21 2 17 2 11 V5 Z" fill="${c}" fill-opacity="0.14" stroke="${c}" stroke-width="1.8" stroke-linejoin="round"/><path d="M7 12 l3 3 l5 -6" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`
      : `<circle cx="11" cy="12" r="10" fill="${c}" fill-opacity="0.14" stroke="${c}" stroke-width="1.8"/><path d="M11 7 V13" stroke="${c}" stroke-width="2.2" stroke-linecap="round"/><circle cx="11" cy="17" r="1.4" fill="${c}"/>`}</g>
      ${t(x + 32, HY, titre, { taille: 17, couleur: c, poids: 800 })}`;
    const brut = liste.reduce((a, [, l]) => a + hauteur(l.length + 1), 0);
    const plus = (total - brut - (liste.length - 1) * GAP) / liste.length;
    let y = LY;
    liste.forEach(([gras, lignes, quand]) => {
      const h = hauteur(lignes.length + 1) + plus;
      const y1 = y + h / 2 - ((lignes.length) * LH) / 2 + 5;
      s += `<rect x="${x}" y="${y}" width="${CL}" height="${h}" rx="12" fill="${CARTE}" stroke="${BORD}"/>
        <rect x="${x}" y="${y}" width="${CL}" height="${h}" rx="12" fill="${c}" fill-opacity="0.06" stroke="${c}" stroke-width="1.5" opacity="0">${plages(quand.map((i) => [S(i), E(i)]))}</rect>
        <rect x="${x}" y="${y}" width="${CL}" height="${h}" rx="12" fill="${c}" fill-opacity="0.05" stroke="${c}" stroke-opacity="0.3"/>
        <circle cx="${x + 26}" cy="${y1 - 5}" r="5" fill="${c}" fill-opacity="0.25" stroke="${c}"/>
        ${t(x + 44, y1, gras, { taille: 14, couleur: TITRE, poids: 700 })}
        ${lignes.map((l, k) => t(x + 44, y1 + (k + 1) * LH, l, { taille: 12.5 })).join('')}`;
      y += h + GAP;
    });
    return s;
  };
  corps += colonne(60, 'Ce qui est vrai', vrai, VERT, '✓');
  corps += colonne(652, 'Ce qui ne l’est pas', pas, OR, '!');
  const H = LY + total + 34;

  svg('confidentialite.svg', 1280, H, corps,
    'Le modèle de confidentialité. Au centre, le téléphone ; le seul fil qui en sort va vers Enable Banking, puis vers la banque, en lecture seule, pour un accès de 180 jours ; rien ne part vers un serveur, un compte, de l’analytique ou de la publicité. Un regard curieux essaie chaque porte, et elles tiennent. Aucun serveur à moi : l’application ne parle qu’à Enable Banking, pour lire le compte. La base est chiffrée par SQLCipher ; sa clé vit dans le Keystore et n’est chargée qu’après l’empreinte, hors la veille du solde. La clé bancaire est chiffrée deux fois, en AES-GCM par une clé dérivée, dans une base elle-même chiffrée. La DSP2 ne donne que la lecture : aucun virement ne peut partir de l’application, et l’accès expire au bout de 180 jours. L’écran est protégé : captures bloquées, aperçu du multitâche masqué, sauvegarde Android refusée. Puis, honnêtement, ce qui reste ouvert. Enable Banking voit passer les opérations le temps de les transmettre : c’est l’agrégateur agréé qui lit la banque. L’application ouverte montre tout : l’empreinte protège l’accès, pas ton épaule. Une sauvegarde voyage et vaut ce que vaut sa phrase ; sans la phrase, elle est perdue, pour tout le monde. Perdre le téléphone, c’est perdre les données qui n’ont pas été sauvegardées : la clé ne se recopie nulle part. La veille du solde se passe d’empreinte : toutes les six heures, la clé est chargée le temps de lire le solde, et l’alerte montre le montant sur l’écran verrouillé. L’empreinte se coupe dans les réglages ; les données restent chiffrées, mais s’ouvrent sans preuve.');
};

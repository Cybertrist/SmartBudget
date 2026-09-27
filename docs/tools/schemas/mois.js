// Le mois budgétaire : le jour où il commence, et « Compte en ».
//
// En haut, dix opérations sur dix semaines, et les mois qui les
// rassemblent : des mois civils d'abord, puis, le début réglé au 28, des
// mois qui partent de la paie. Un salaire versé en avance tombe alors
// dans le mois qui s'achève ; « Compte en » le rattache au suivant. En
// bas, le téléphone fait les deux gestes, et les totaux de septembre et
// d'octobre changent à chaque fois.
//
// Les règles sont celles de domaine/mois.dart et domaine/bilan.dart ; les
// montants sont inventés.
module.exports = (O) => {
  const { svg, t, fondu, visible, paliers, toucher, APP, MONO, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, OR, ROSE, BLEU } = O;

  const C = 30;
  // Les trois états : début au 1er, début au 28, puis « Compte en ».
  const E1 = 0.23, E2 = 0.62, FIN = 0.97;
  const etat = (a, b, c) => [[0, a], [E1, b], [E2, c], [FIN, a]];

  // ----------------------------------------------------------------------
  // La frise : du 24 août au 31 octobre 2026, un jour par colonne.
  const X0 = 92, JOUR = 15.9;
  const X = (i) => X0 + i * JOUR;
  /// Le rang d'une date depuis le 24 août.
  const rang = (j, m) => (m === 8 ? j - 24 : m === 9 ? 8 + j - 1 : m === 10 ? 38 + j - 1 : 69);
  const AXE = 222, HAUT = 116, BAS = 318;

  const MOIS = [
    ['Août', '#8B99A8', [0, 8], [0, 4]],
    ['Septembre', VERT, [8, 38], [4, 35]],
    ['Octobre', BLEU, [38, 69], [35, 65]],
    ['Novembre', ROSE, [69, 69], [65, 69]],
  ];
  // [jour, mois, nom, centimes, mois compté : début au 1er, au 28, puis avec Compte en, étage]
  const OPS = [
    [28, 8, 'Salaire', 185000, 0, 1, 1, 0],
    [31, 8, 'Courses', -7240, 0, 1, 1, 2],
    [5, 9, 'Loyer', -52000, 1, 1, 1, 1],
    [14, 9, 'Courses', -8630, 1, 1, 1, 2],
    [21, 9, 'Restaurant', -4150, 1, 1, 1, 1],
    [25, 9, 'Salaire', 185000, 1, 1, 2, 0],
    [30, 9, 'Courses', -6480, 1, 2, 2, 2],
    [5, 10, 'Loyer', -52000, 2, 2, 2, 1],
    [12, 10, 'Courses', -5890, 2, 2, 2, 2],
    [28, 10, 'Salaire', 185000, 2, 3, 3, 0],
  ];
  const NOMS_MOIS = { 8: 'août', 9: 'septembre', 10: 'octobre' };

  const eur = (c, signe = false) => {
    const a = Math.abs(c);
    const ent = String(Math.trunc(a / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    return `${c < 0 ? '-' : signe && c > 0 ? '+' : ''}${ent},${String(a % 100).padStart(2, '0')} €`;
  };
  /// Un texte qui change de valeur selon l'état : trois textes superposés.
  const selon = (valeurs, f) => valeurs.map((v, k) => {
    const op = [0, 1, 2].map((e) => (valeurs[e] === v ? 1 : 0));
    // Deux états qui montrent la même chose : un seul texte suffit.
    if (valeurs.indexOf(v) !== k) return '';
    return `<g>${paliers('opacity', C, etat(op[0], op[1], op[2]))}${f(v)}</g>`;
  }).join('');

  let frise = `<rect x="60" y="80" width="1160" height="270" rx="16" fill="${CARTE}" stroke="${BORD}"/>`;
  frise += `<clipPath id="moFrise"><rect x="${X(0)}" y="${HAUT}" width="${X(69) - X(0)}" height="${BAS - HAUT}"/></clipPath>`;
  // Les colonnes des mois, qui glissent quand le début change.
  const glisse = (a, b) => `keyTimes="0;0.18;${E1};${FIN};1" values="${a};${a};${b};${b};${a}" calcMode="spline" keySplines="0 0 1 1;0.45 0 0.2 1;0 0 1 1;0.45 0 0.2 1"`;
  let colonnes = '';
  for (const [nom, c, [a0, a1], [b0, b1]] of MOIS) {
    const xa = X(a0), la = X(a1) - X(a0), xb = X(b0), lb = X(b1) - X(b0);
    colonnes += `<rect y="${HAUT}" height="${BAS - HAUT}" fill="${c}" fill-opacity="0.07" x="${xa}" width="${la}">
        <animate attributeName="x" dur="${C}s" repeatCount="indefinite" ${glisse(xa, xb)}/><animate attributeName="width" dur="${C}s" repeatCount="indefinite" ${glisse(la, lb)}/></rect>
      <rect y="${HAUT}" height="3" fill="${c}" x="${xa + 2}" width="${Math.max(la - 4, 0)}">
        <animate attributeName="x" dur="${C}s" repeatCount="indefinite" ${glisse(xa + 2, xb + 2)}/><animate attributeName="width" dur="${C}s" repeatCount="indefinite" ${glisse(Math.max(la - 4, 0), Math.max(lb - 4, 0))}/></rect>
      <text x="${xa + la / 2}" y="${HAUT + 22}" font-family="${O.SANS}" font-size="13" font-weight="700" fill="${c}" text-anchor="middle" ${la < 70 ? 'opacity="0"' : ''}>${O.esc(O.tr(nom))}
        <animate attributeName="x" dur="${C}s" repeatCount="indefinite" ${glisse(xa + la / 2, xb + lb / 2)}/>
        ${la < 70 || lb < 70 ? fondu('opacity', C, [[0, la < 70 ? 0 : 1], [0.18, la < 70 ? 0 : 1], [E1, lb < 70 ? 0 : 1], [FIN, lb < 70 ? 0 : 1], [1, la < 70 ? 0 : 1]]) : ''}</text>`;
  }
  // Les séparations : le 1er, puis le 28. Le trait reste dans la frise,
  // la date se lit dessous.
  const bornes = (liste, de, avecTrait) => liste.map(([i, s]) => `<g opacity="0">${fondu('opacity', C, de === 0
    ? [[0, 1], [0.18, 1], [0.2, 0], [FIN, 0], [1, 1]]
    : [[0, 0], [0.2, 0], [E1, 1], [FIN, 1], [1, 0]])}
      ${avecTrait
        ? `<line x1="${X(i)}" y1="${HAUT}" x2="${X(i)}" y2="${BAS}" stroke="${TITRE}" stroke-opacity="0.35" stroke-dasharray="3 4"/>`
        : t(X(i), BAS + 20, s, { taille: 11.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'middle' })}</g>`).join('');
  const PREMIERS = [[8, '1er sept.'], [38, '1er oct.']], VINGT_HUIT = [[4, '28 août'], [35, '28 sept.'], [65, '28 oct.']];
  colonnes += bornes(PREMIERS, 0, true) + bornes(VINGT_HUIT, 1, true);
  frise += `<g clip-path="url(#moFrise)">${colonnes}</g>`;
  frise += bornes(PREMIERS, 0, false) + bornes(VINGT_HUIT, 1, false);

  // L'axe des jours.
  frise += `<line x1="${X(0)}" y1="${AXE}" x2="${X(69)}" y2="${AXE}" stroke="${FIL}" stroke-width="2"/>`;
  for (let i = 0; i <= 69; i++) {
    const premier = i === 8 || i === 38;
    frise += `<line x1="${X(i)}" y1="${AXE - (premier ? 7 : 3)}" x2="${X(i)}" y2="${AXE + (premier ? 7 : 3)}" stroke="${premier ? TEXTE : FIL}" stroke-width="${premier ? 1.5 : 1}"/>`;
  }

  // Les opérations : leur point prend la couleur du mois où elles comptent.
  OPS.forEach(([j, m, nom, c, a, b, cc, etage], k) => {
    const i = rang(j, m), cx = X(i + 0.5);
    const coul = [a, b, cc].map((e) => MOIS[e][1]);
    const change = [a !== b ? E1 : null, b !== cc ? E2 : null].filter((v) => v !== null);
    const date = `${j} ${NOMS_MOIS[m]}`;
    if (etage === 0) {
      const l = 124, py = 150;
      frise += `<rect x="${cx - l / 2}" y="${py}" width="${l}" height="42" rx="12" fill="${FOND}" stroke="${coul[0]}" stroke-opacity="0.7">
          ${paliers('stroke', C, etat(...coul))}</rect>
        ${t(cx, py + 17, `${nom} · ${date}`, { taille: 11, couleur: TEXTE, ancre: 'middle' })}
        ${t(cx, py + 34, eur(c, true), { taille: 12.5, couleur: VERT, police: MONO, poids: 700, ancre: 'middle' })}
        <line x1="${cx}" y1="${py + 42}" x2="${cx}" y2="${AXE - 7}" stroke="${FIL}" stroke-width="1.5"/>`;
    } else {
      const py = etage === 1 ? 248 : 282;
      frise += `<line x1="${cx}" y1="${AXE + 7}" x2="${cx}" y2="${py - 2}" stroke="${FIL}" stroke-width="1.5"/>
        ${t(cx, py + 10, `${nom} · ${date}`, { taille: 10.5, couleur: DISCRET, ancre: 'middle' })}
        ${t(cx, py + 26, eur(c), { taille: 11.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'middle' })}`;
    }
    frise += `<circle cx="${cx}" cy="${AXE}" r="6.5" fill="${coul[0]}" stroke="${FOND}" stroke-width="2">${paliers('fill', C, etat(...coul))}</circle>`;
    // Une onde quand l'opération change de mois.
    for (const s of change) {
      frise += `<circle cx="${cx}" cy="${AXE}" r="7" fill="none" stroke="${s === E1 ? coul[1] : coul[2]}" stroke-width="2" opacity="0">
        ${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.005, 0.9], [s + 0.05, 0], [1, 0]])}${fondu('r', C, [[0, 7], [s, 7], [s + 0.05, 30], [1, 30]])}</circle>`;
    }
  });
  // Deux salaires dans le même mois : ils s'allument en or.
  const iA = rang(28, 8), iB = rang(25, 9);
  for (const i of [iA, iB]) {
    frise += `<rect x="${X(i + 0.5) - 66}" y="146" width="132" height="50" rx="15" fill="none" stroke="${OR}" stroke-width="2" opacity="0" filter="url(#halo)">${visible(C, 0.27, 0.45, 0.01)}</rect>`;
  }
  // Compte en octobre : la flèche qui emporte le salaire du 25.
  const xs = X(iB + 0.5), xo = X(rang(3, 10));
  frise += `<g opacity="0">${visible(C, 0.585, FIN - 0.01, 0.01)}
    <path d="M${xs + 64} 170 C${xs + 120} 160 ${xo - 70} 198 ${xo - 14} 198" fill="none" stroke="${BLEU}" stroke-width="2" stroke-dasharray="5 5"/>
    <path d="M${xo - 22} 192 L${xo - 12} 198 L${xo - 22} 204" fill="none" stroke="${BLEU}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    <rect x="${xo - 8}" y="186" width="140" height="24" rx="12" fill="${FOND}"/>
    <rect x="${xo - 8}" y="186" width="140" height="24" rx="12" fill="${BLEU}" fill-opacity="0.14" stroke="${BLEU}" stroke-opacity="0.6"/>
    ${t(xo + 62, 202.5, 'compte en octobre', { taille: 11.5, couleur: BLEU, poids: 700, ancre: 'middle' })}</g>`;
  frise += t(84, 104, 'DU 24 AOÛT AU 31 OCTOBRE 2026', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  frise += `<g>${paliers('opacity', C, etat(1, 0, 0))}${t(1196, 104, 'le mois commence le 1er : des mois civils', { taille: 12.5, couleur: TEXTE, ancre: 'end' })}</g>`;
  frise += `<g opacity="0">${paliers('opacity', C, etat(0, 1, 0))}${t(1196, 104, 'le mois commence le 28 : il part de la paie', { taille: 12.5, couleur: VERT, poids: 700, ancre: 'end' })}</g>`;
  frise += `<g opacity="0">${paliers('opacity', C, etat(0, 0, 1))}${t(1196, 104, 'le 28, et le salaire du 25 compte en octobre', { taille: 12.5, couleur: BLEU, poids: 700, ancre: 'end' })}</g>`;

  // ----------------------------------------------------------------------
  // Le téléphone : les réglages, puis l'opération.
  const PX = 60, PY = 368, PL = 292, PH = 428;
  const SX = PX + 12, SY = PY + 14, SL = PL - 24, SH = PH - 28;
  const x = (v) => SX + v, y = (v) => SY + v;
  const T = { reglage: 0.07, jour28: 0.14, ferme1: 0.155, operation: 0.42, compteEn: 0.47, octobre: 0.55, ferme2: 0.565 };
  const I = {
    retour: 'M19 12 H5 M11 6 L5 12 L11 18', droite: 'M9.5 6 L15.5 12 L9.5 18',
    cible: 'M12 21 A9 9 0 1 1 12 3 A9 9 0 1 1 12 21 M12 16 A4 4 0 1 1 12 8 A4 4 0 1 1 12 16',
    tirelire: 'M5 11 A7 6 0 0 1 19 11 V15 L17 16 V19 H14 V17 H10 V19 H7 V16 A6 6 0 0 1 5 11 Z M10 6 A2.5 2.5 0 0 1 14 6',
    agenda: 'M4 5.5 H20 V20 H4 Z M4 10 H20 M8.5 3 V7 M15.5 3 V7',
    edit: 'M4 20 H8 L19 9 L15 5 L4 16 Z', sync: 'M4 9 H18 M14 5 L18 9 M20 15 H6 M10 19 L6 15', label: 'M4 6 H15 L20 12 L15 18 H4 Z',
    payments: 'M3 6 H21 V18 H3 Z M12 15 A3 3 0 1 1 12 9 A3 3 0 1 1 12 15', coche: 'M5 12.5 L10 17 L19 7.5',
    bouclier: 'M12 3 L19 6 V11 C19 15.5 16 19 12 21 C8 19 5 15.5 5 11 V6 Z M9 12 L11.2 14.2 L15.5 9.8',
  };
  const ico = (nom, cx, cy, taille, couleur, ep = 2.2) =>
    `<g transform="translate(${cx - taille / 2},${cy - taille / 2}) scale(${taille / 24})"><path d="${I[nom]}" fill="none" stroke="${couleur}" stroke-width="${ep}" stroke-linecap="round" stroke-linejoin="round"/></g>`;
  const ligne = (py, icone, libelle, valeurs, couleur = APP.second) => `<line x1="${x(26)}" y1="${y(py)}" x2="${x(SL - 26)}" y2="${y(py)}" stroke="#FFFFFF" stroke-opacity="0.07"/>
    <rect x="${x(26)}" y="${y(py + 8)}" width="28" height="28" rx="9" fill="#FFFFFF" fill-opacity="0.04"/>${ico(icone, x(40), y(py + 22), 14, APP.second)}
    ${t(x(62), y(py + 26.5), libelle, { taille: 11.5, couleur: APP.texte, poids: 600 })}
    ${valeurs}
    ${ico('droite', x(SL - 30), y(py + 22), 13, APP.discret)}`;
  const valeur = (py, s, couleur = APP.second) => t(x(SL - 40), y(py + 26.5), s, { taille: 11.5, couleur, poids: 700, ancre: 'end' });
  const voile = (de, a, contenu) => `<g opacity="0">${visible(C, de, a, 0.006)}<rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000000" fill-opacity="0.7"/>${contenu}</g>`;

  // Les réglages, le bloc Budget.
  const debut = (s, de, a) => `<g opacity="0">${visible(C, de, a, 0.004)}${valeur(160, s, s === '28' ? VERT : APP.second)}</g>`;
  let grille = '';
  for (let j = 1; j <= 28; j++) {
    const col = (j - 1) % 7, lig = Math.floor((j - 1) / 7);
    const cx = x(26 + 14 + col * 26.3), cy = y(142 + lig * 34);
    const actif = (s) => `<circle cx="${cx}" cy="${cy}" r="13" fill="${VERT}"/>${t(cx, cy + 4, String(j), { taille: 11.5, couleur: '#000000', poids: 800, ancre: 'middle' })}`;
    if (j === 1) grille += `<g>${paliers('opacity', C, [[0, 1], [T.jour28 + 0.003, 0]])}${actif()}</g><g opacity="0">${paliers('opacity', C, [[0, 0], [T.jour28 + 0.003, 1]])}${t(cx, cy + 4, '1', { taille: 11.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}</g>`;
    else if (j === 28) grille += `<g>${paliers('opacity', C, [[0, 1], [T.jour28 + 0.003, 0]])}${t(cx, cy + 4, '28', { taille: 11.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}</g><g opacity="0">${paliers('opacity', C, [[0, 0], [T.jour28 + 0.003, 1]])}${actif()}</g>`;
    else grille += t(cx, cy + 4, String(j), { taille: 11.5, couleur: APP.texte, poids: 700, ancre: 'middle' });
  }
  const reglages = `<g>${visible(C, 0, T.operation, 0.006)}
    ${t(x(16), y(40), 'Réglages', { taille: 19, couleur: APP.texte, poids: 800 })}
    <rect x="${x(12)}" y="${y(60)}" width="${SL - 24}" height="162" rx="16" fill="#181818"/>
    ${t(x(26), y(84), 'BUDGET', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
    ${ligne(92, 'cible', 'Budget mensuel', valeur(92, '1 500 €'))}
    ${ligne(126, 'tirelire', 'Objectif d’épargne', valeur(126, '6 000 €'))}
    ${ligne(160, 'agenda', 'Le mois commence le', debut('1er', 0, T.ferme1) + debut('28', T.ferme1, T.operation))}
    <rect x="${x(12)}" y="${y(236)}" width="${SL - 24}" height="98" rx="16" fill="#181818"/>
    <rect x="${x(26)}" y="${y(252)}" width="30" height="30" rx="10" fill="${VERT}" fill-opacity="0.15" stroke="${VERT}" stroke-opacity="0.4"/>${ico('bouclier', x(41), y(267), 16, VERT)}
    ${t(x(66), y(264), 'Tes données restent ici', { taille: 12, couleur: APP.texte, poids: 800 })}
    ${['Aucun serveur, aucun compte,', 'aucune publicité. Tout est', 'chiffré sur ce téléphone.'].map((s, i) => t(x(66), y(282 + i * 15), s, { taille: 10, couleur: APP.second })).join('')}
    ${toucher(x(SL / 2), y(182), C, T.reglage)}
    ${voile(T.reglage + 0.008, T.ferme1, `<rect x="${x(14)}" y="${y(116)}" width="${SL - 28}" height="150" rx="20" fill="#181818"/>${grille}${toucher(x(26 + 14 + 6 * 26.3), y(142 + 3 * 34), C, T.jour28)}`)}
  </g>`;

  // L'opération : le salaire versé en avance.
  const compteEn = (s, de, a) => `<g opacity="0">${visible(C, de, a, 0.004)}${valeur(288, s, s === 'Octobre' ? BLEU : APP.second)}</g>`;
  const choix = (py, s, de, a) => `<g opacity="0">${visible(C, de, a, 0.004)}${ico('coche', x(SL - 40), y(py), 16, VERT, 2.6)}</g>`;
  const operation = `<g opacity="0">${visible(C, T.operation, 0.996, 0.006)}
    <g><animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${T.operation};${T.operation + 0.01};1" values="30 0;30 0;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.2 0 0.2 1;0 0 1 1"/>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="${APP.fond}"/>
    <circle cx="${x(30)}" cy="${y(34)}" r="16" fill="#1C1C1C"/>${ico('retour', x(30), y(34), 16, APP.texte)}
    ${t(x(56), y(39.5), 'Salaire', { taille: 15, couleur: APP.texte, poids: 700 })}
    <rect x="${x(SL / 2 - 24)}" y="${y(60)}" width="48" height="48" rx="15" fill="#1BCC6D" fill-opacity="0.15" stroke="#1BCC6D" stroke-opacity="0.4"/>${ico('payments', x(SL / 2), y(84), 24, '#1BCC6D')}
    ${t(x(SL / 2), y(138), eur(185000, true), { taille: 24, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(x(SL / 2), y(158), 'VIR SEPA RECU SALAIRE', { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
    ${t(x(SL / 2), y(172), 'Vendredi 25 septembre 2026 · Compte courant', { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
    <rect x="${x(12)}" y="${y(186)}" width="${SL - 24}" height="${SH - 196}" rx="16" fill="#181818"/>
    ${t(x(26), y(208), 'CLASSEMENT', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
    ${ligne(216, 'sync', 'Mouvement', valeur(216, 'Revenu'))}
    ${ligne(252, 'label', 'Catégorie', valeur(252, 'Salaire', '#1BCC6D'))}
    ${ligne(288, 'agenda', 'Compte en', compteEn('Septembre', 0, T.ferme2) + compteEn('Octobre', T.ferme2, 0.996))}
    ${toucher(x(SL / 2), y(310), C, T.compteEn)}
    ${voile(T.compteEn + 0.008, T.ferme2, `<rect x="${x(14)}" y="${y(124)}" width="${SL - 28}" height="150" rx="20" fill="#181818"/>
      ${['Août 2026', 'Septembre 2026', 'Octobre 2026'].map((s, i) => t(x(32), y(158 + i * 42), s, { taille: 12.5, couleur: APP.texte })).join('')}
      ${choix(196, 'Septembre 2026', 0, T.octobre + 0.003)}${choix(238, 'Octobre 2026', T.octobre + 0.003, 1)}
      ${toucher(x(SL / 2), y(234), C, T.octobre)}`)}
    </g></g>`;
  // Pas de ligne Type dans le classement : elle n'existe que pour une
  // dépense.
  const telephone = `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="36" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="moEcran"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="24"/></clipPath>
    <rect x="${PX + PL / 2 - 30}" y="${PY + 5}" width="60" height="5" rx="2.5" fill="#1B222C"/>
    <g clip-path="url(#moEcran)"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="${APP.fond}"/>${reglages}${operation}</g>`;

  // ----------------------------------------------------------------------
  // Les trois temps, au milieu.
  const etapes = [
    ['Le mois commence le 28', ['Réglages, Budget : le jour de la paie.', 'Le salaire du 28 août ouvre septembre,', 'qui court jusqu’au 27.'], 0, E1 + 0.03],
    ['Un salaire en avance', ['Versé le 25 septembre, il tombe dans', 'septembre : deux salaires, et aucun', 'en octobre.'], E1 + 0.03, T.operation],
    ['« Compte en » octobre', ['Sur l’opération : le mois d’avant, le sien', 'ou celui d’après. Ce choix passe avant', 'le jour de début.'], T.operation, 0.996],
  ];
  const EX = 376, EY = 400, PAS = 132;
  let milieu = '';
  etapes.forEach(([titre, lignes, de, a], k) => {
    const ey = EY + k * PAS;
    milieu += `<rect x="${EX}" y="${ey - 30}" width="392" height="${PAS - 14}" rx="14" fill="${CARTE}" stroke="${VERT}" stroke-opacity="0.5" opacity="0">${visible(C, de + 0.004, a - 0.004, 0.006)}</rect>
      <circle cx="${EX + 30}" cy="${ey}" r="17" fill="${FOND}" stroke="${FIL}" stroke-width="2"/>
      <circle cx="${EX + 30}" cy="${ey}" r="17" fill="${VERT}" opacity="0" filter="url(#halo)">${visible(C, de + 0.004, FIN, 0.006)}</circle>
      ${t(EX + 30, ey + 5, String(k + 1), { taille: 14, couleur: TEXTE, police: MONO, poids: 700, ancre: 'middle' })}
      <g opacity="0">${visible(C, de + 0.004, FIN, 0.006)}${t(EX + 30, ey + 5, String(k + 1), { taille: 14, couleur: '#000000', police: MONO, poids: 800, ancre: 'middle' })}</g>
      ${t(EX + 62, ey + 5, titre, { taille: 17, couleur: TITRE, poids: 700 })}
      ${lignes.map((s, i) => t(EX + 62, ey + 28 + i * 19, s, { taille: 13.5 })).join('')}`;
  });

  // ----------------------------------------------------------------------
  // Les totaux de septembre et d'octobre, à droite.
  const TX = 790, TL = 430;
  const totaux = (ty, nom, couleur, periodes, valeurs) => {
    let s = `<rect x="${TX}" y="${ty}" width="${TL}" height="196" rx="16" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${TX}" y="${ty}" width="${TL}" height="196" rx="16" fill="${couleur}" fill-opacity="0.05" stroke="${couleur}" stroke-opacity="0.3"/>
      ${t(TX + 22, ty + 32, nom, { taille: 15, couleur, police: MONO, poids: 700 })}
      ${selon(periodes, (p) => t(TX + TL - 22, ty + 32, p, { taille: 12.5, couleur: TEXTE, ancre: 'end' }))}`;
    [['Entrées', 0], ['Sorties', 1], ['Solde du mois', 2]].forEach(([libelle, n], i) => {
      const ly = ty + 72 + i * 42;
      const v = valeurs.map((e) => e[n]);
      s += `<line x1="${TX + 22}" y1="${ly - 24}" x2="${TX + TL - 22}" y2="${ly - 24}" stroke="${BORD}"/>`;
      // Une lueur sur la ligne quand elle change.
      for (const [e, instant] of [[1, E1], [2, E2]]) {
        if (v[e] !== v[e - 1]) s += `<rect x="${TX + 12}" y="${ly - 21}" width="${TL - 24}" height="34" rx="9" fill="${e === 1 ? OR : BLEU}" fill-opacity="0.12" opacity="0">${fondu('opacity', C, [[0, 0], [instant, 0], [instant + 0.01, 1], [instant + 0.09, 0], [1, 0]])}</rect>`;
      }
      s += t(TX + 22, ly + 1, libelle, { taille: 14, couleur: n === 2 ? TITRE : TEXTE, poids: n === 2 ? 700 : 400 });
      s += selon(v, (val) => t(TX + TL - 22, ly + 1, eur(val, n !== 1), {
        taille: 15, police: MONO, poids: 700, ancre: 'end',
        couleur: n === 1 ? TITRE : val > 0 ? VERT : val < 0 ? '#FF6B7A' : TEXTE,
      }));
    });
    return s;
  };
  // [entrées, sorties, solde] au 1er, au 28, puis avec Compte en.
  let droite = totaux(360, 'Septembre', VERT, ['du 1er au 30 septembre', 'du 28 août au 27 septembre', 'du 28 août au 27 septembre'],
    [[185000, 71260, 113740], [370000, 72020, 297980], [185000, 72020, 112980]]);
  droite += totaux(572, 'Octobre', BLEU, ['du 1er au 31 octobre', 'du 28 septembre au 27 octobre', 'du 28 septembre au 27 octobre'],
    [[185000, 57890, 127110], [0, 64370, -64370], [185000, 64370, 120630]]);
  // Les signaux : deux salaires en septembre, aucun en octobre.
  droite += `<g opacity="0">${visible(C, 0.27, T.operation, 0.01)}
    <rect x="${TX + 160}" y="421" width="112" height="22" rx="11" fill="${OR}" fill-opacity="0.14" stroke="${OR}" stroke-opacity="0.6"/>${t(TX + 216, 436, 'deux salaires', { taille: 11.5, couleur: OR, poids: 700, ancre: 'middle' })}
    <rect x="${TX + 160}" y="633" width="112" height="22" rx="11" fill="${OR}" fill-opacity="0.14" stroke="${OR}" stroke-opacity="0.6"/>${t(TX + 216, 648, 'aucun salaire', { taille: 11.5, couleur: OR, poids: 700, ancre: 'middle' })}</g>`;

  let corps = '';
  corps += t(60, 52, 'LE MOIS BUDGÉTAIRE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  // Le sous-titre suit la longueur du titre, qui change en anglais.
  corps += t(60 + O.tr('LE MOIS BUDGÉTAIRE').length * 10.9 + 32, 52, 'Il peut partir du jour de la paie, et une opération peut compter dans le mois d’à côté.', { taille: 14 });
  corps += frise + telephone + milieu + droite;
  svg('mois.svg', 1280, 812, corps,
    'Le mois budgétaire, sur une frise du 24 août au 31 octobre 2026 et un téléphone animé. Dix opérations : un salaire de 1 850 euros le 28 août, des courses le 31 août, le loyer de 520 euros le 5 septembre, des courses et un restaurant, un salaire versé en avance le 25 septembre, des courses le 30 septembre, le loyer le 5 octobre, des courses, et le salaire du 28 octobre. D’abord le mois commence le 1er : septembre va du 1er au 30, 1 850 euros d’entrées, 712,60 de sorties. 1, dans les réglages, Le mois commence le passe de 1er à 28 : les mois glissent, septembre va du 28 août au 27 septembre, et le salaire du 28 août, qui paie septembre, y entre. 2, mais le salaire du 25 septembre, versé en avance, tombe lui aussi en septembre : deux salaires, 3 700 euros d’entrées, et octobre aucun, un solde de -643,70 euros. 3, sur l’opération, Compte en passe de Septembre à Octobre : le salaire compte en octobre, septembre revient à 1 850 euros d’entrées pour 720,20 de sorties, octobre à 1 850 euros pour 643,70. Compte en propose le mois d’avant, le sien ou celui d’après, et passe avant le jour de début.');
};

// Le mois budgétaire : chaque salaire ouvre son mois le jour où il arrive.
//
// En haut, onze opérations sur dix semaines, de la fin novembre à la fin
// janvier, et les mois qui les rassemblent. D'abord à jour fixe, le 25 :
// le salaire versé en avance pour Noël, le 19 décembre, tombe dans
// décembre, qui en compte deux, et janvier aucun. Puis chaque salaire
// ouvre son mois : janvier commence le 19 décembre. Enfin, une prime
// classée Salaire n'ouvre rien. En bas, le téléphone montre le réglage,
// puis les deux fiches, et les totaux de décembre et de janvier suivent.
//
// Les règles sont celles de domaine/mois.dart (Calendrier,
// ouverturesDuSalaire, jourDuSalaire) ; les montants sont inventés.
module.exports = (O) => {
  const { svg, t, fondu, visible, paliers, toucher, APP, MONO, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, OR, ROSE, BLEU } = O;

  const C = 30;
  // Les trois états : à jour fixe, puis chaque salaire ouvre son mois,
  // puis la prime.
  const E1 = 0.3, E2 = 0.64, FIN = 0.97;
  const etat = (a, b, c) => [[0, a], [E1, b], [E2, c], [FIN, a]];

  // ----------------------------------------------------------------------
  // La frise : du 20 novembre 2025 au 31 janvier 2026, un jour par colonne.
  const X0 = 92, JOUR = 15.03;
  const X = (i) => X0 + i * JOUR;
  /// Le rang d'une date depuis le 20 novembre.
  const rang = (j, m) => (m === 11 ? j - 20 : m === 12 ? 11 + j - 1 : 42 + j - 1);
  const FINI = 73;
  const AXE = 222, HAUT = 116, BAS = 318;

  // [nom, couleur, colonnes à jour fixe, colonnes quand le salaire ouvre]
  const MOIS = [
    ['Novembre', '#8B99A8', [0, 5], [0, 5]],
    ['Décembre', VERT, [5, 35], [5, 29]],
    ['Janvier', BLEU, [35, 66], [29, 68]],
    ['Février', ROSE, [66, FINI], [68, FINI]],
  ];
  // [jour, mois, nom, centimes, mois compté : à jour fixe, puis quand le
  // salaire ouvre (deux fois), étage]
  const OPS = [
    [25, 11, 'Salaire', 185000, 1, 1, 1, 0],
    [28, 11, 'Courses', -7240, 1, 1, 1, 2],
    [5, 12, 'Loyer', -52000, 1, 1, 1, 1],
    [12, 12, 'Courses', -8630, 1, 1, 1, 2],
    [19, 12, 'Salaire', 185000, 1, 2, 2, 0],
    [23, 12, 'Cadeaux', -16490, 1, 2, 2, 1],
    [30, 12, 'Courses', -6480, 2, 2, 2, 2],
    [5, 1, 'Loyer', -52000, 2, 2, 2, 1],
    [9, 1, 'Prime', 25000, 2, 2, 2, 0],
    [14, 1, 'Courses', -5890, 2, 2, 2, 2],
    [27, 1, 'Salaire', 185000, 3, 3, 3, 0],
  ];
  const NOMS_MOIS = { 11: 'novembre', 12: 'décembre', 1: 'janvier' };

  const eur = (c, signe = false) => {
    const a = Math.abs(c);
    const ent = String(Math.trunc(a / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    return `${c < 0 ? '-' : signe && c > 0 ? '+' : ''}${ent},${String(a % 100).padStart(2, '0')} €`;
  };
  /// Un texte qui change de valeur selon l'état : un texte par valeur.
  const selon = (valeurs, f) => valeurs.map((v, k) => {
    const op = [0, 1, 2].map((e) => (valeurs[e] === v ? 1 : 0));
    // Deux états qui montrent la même chose : un seul texte suffit.
    if (valeurs.indexOf(v) !== k) return '';
    return `<g${op[0] ? '' : ' opacity="0"'}>${paliers('opacity', C, etat(op[0], op[1], op[2]))}${f(v)}</g>`;
  }).join('');

  let frise = `<rect x="60" y="80" width="1160" height="270" rx="16" fill="${CARTE}" stroke="${BORD}"/>`;
  frise += `<clipPath id="moFrise"><rect x="${X(0)}" y="${HAUT}" width="${X(FINI) - X(0)}" height="${BAS - HAUT}"/></clipPath>`;
  // Les colonnes des mois, qui glissent quand les salaires ouvrent les mois.
  const G = E1 - 0.035;
  const glisse = (a, b) => `keyTimes="0;${G};${E1};${FIN};1" values="${a};${a};${b};${b};${a}" calcMode="spline" keySplines="0 0 1 1;0.45 0 0.2 1;0 0 1 1;0.45 0 0.2 1"`;
  const anime = (attr, a, b) => (a === b ? '' : `<animate attributeName="${attr}" dur="${C}s" repeatCount="indefinite" ${glisse(a, b)}/>`);
  let colonnes = '';
  for (const [nom, c, [a0, a1], [b0, b1]] of MOIS) {
    const xa = X(a0), la = X(a1) - X(a0), xb = X(b0), lb = X(b1) - X(b0);
    colonnes += `<rect y="${HAUT}" height="${BAS - HAUT}" fill="${c}" fill-opacity="0.07" x="${xa}" width="${la}">${anime('x', xa, xb)}${anime('width', la, lb)}</rect>
      <rect y="${HAUT}" height="3" fill="${c}" x="${xa + 2}" width="${la - 4}">${anime('x', xa + 2, xb + 2)}${anime('width', la - 4, lb - 4)}</rect>`;
    // Novembre n'a que cinq jours ici : son nom ne tiendrait pas.
    if (nom !== 'Novembre') colonnes += `<text x="${xa + la / 2}" y="${HAUT + 22}" font-family="${O.SANS}" font-size="13" font-weight="700" fill="${c}" text-anchor="middle">${O.esc(O.tr(nom))}${anime('x', xa + la / 2, xb + lb / 2)}</text>`;
  }
  // Les séparations : un trait dans la frise, la date dessous. Le 25
  // novembre ne bouge pas ; le 25 décembre devient le 19, le 25 janvier
  // le 27.
  const borne = ([i, s], op) => {
    const contenu = `<line x1="${X(i)}" y1="${HAUT}" x2="${X(i)}" y2="${BAS}" stroke="${TITRE}" stroke-opacity="0.35" stroke-dasharray="3 4"/>`;
    const date = t(X(i), BAS + 20, s, { taille: 11.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'middle' });
    if (!op) return { trait: contenu, date };
    const f = (x) => `<g${op[0] ? '' : ' opacity="0"'}>${fondu('opacity', C, op)}${x}</g>`;
    return { trait: f(contenu), date: f(date) };
  };
  const FIXE = [[0, 1], [G, 1], [G + 0.01, 0], [FIN, 0], [1, 1]];
  const OUVERT = [[0, 0], [E1 - 0.01, 0], [E1, 1], [FIN, 1], [1, 0]];
  const bornes = [
    borne([5, '25 nov.']),
    borne([35, '25 déc.'], FIXE), borne([66, '25 janv.'], FIXE),
    borne([29, '19 déc.'], OUVERT), borne([68, '27 janv.'], OUVERT),
  ];
  colonnes += bornes.map((b) => b.trait).join('');
  frise += `<g clip-path="url(#moFrise)">${colonnes}</g>`;
  frise += bornes.map((b) => b.date).join('');

  // L'axe des jours, avec le 1er de chaque mois un peu plus marqué.
  frise += `<line x1="${X(0)}" y1="${AXE}" x2="${X(FINI)}" y2="${AXE}" stroke="${FIL}" stroke-width="2"/>`;
  let graduations = '';
  for (let i = 0; i <= FINI; i++) {
    const premier = i === 11 || i === 42;
    graduations += `M${X(i)} ${AXE - (premier ? 7 : 3)}V${AXE + (premier ? 7 : 3)}`;
  }
  frise += `<path d="${graduations}" stroke="${FIL}" stroke-width="1"/>`;

  // Les opérations : leur point prend la couleur du mois où elles comptent.
  OPS.forEach(([j, m, nom, c, a, b, cc, etage]) => {
    const i = rang(j, m), cx = X(i + 0.5);
    const coul = [a, b, cc].map((e) => MOIS[e][1]);
    const date = `${j} ${NOMS_MOIS[m]}`;
    if (etage === 0) {
      const l = 124, py = 150;
      const bord = coul[0] === coul[1] ? '' : paliers('stroke', C, etat(...coul));
      frise += `<rect x="${cx - l / 2}" y="${py}" width="${l}" height="42" rx="12" fill="${FOND}" stroke="${coul[0]}" stroke-opacity="0.7">${bord}</rect>
        ${t(cx, py + 17, `${nom} · ${date}`, { taille: 11, couleur: TEXTE, ancre: 'middle' })}
        ${t(cx, py + 34, eur(c, true), { taille: 12.5, couleur: VERT, police: MONO, poids: 700, ancre: 'middle' })}
        <line x1="${cx}" y1="${py + 42}" x2="${cx}" y2="${AXE - 7}" stroke="${FIL}" stroke-width="1.5"/>`;
    } else {
      const py = etage === 1 ? 248 : 282;
      frise += `<line x1="${cx}" y1="${AXE + 7}" x2="${cx}" y2="${py - 2}" stroke="${FIL}" stroke-width="1.5"/>
        ${t(cx, py + 10, `${nom} · ${date}`, { taille: 10.5, couleur: DISCRET, ancre: 'middle' })}
        ${t(cx, py + 26, eur(c), { taille: 11.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'middle' })}`;
    }
    const remplit = coul[0] === coul[1] ? '' : paliers('fill', C, etat(...coul));
    frise += `<circle cx="${cx}" cy="${AXE}" r="6.5" fill="${coul[0]}" stroke="${FOND}" stroke-width="2">${remplit}</circle>`;
    // Une onde quand l'opération change de mois.
    if (a !== b) {
      frise += `<circle cx="${cx}" cy="${AXE}" r="7" fill="none" stroke="${coul[1]}" stroke-width="2" opacity="0">
        ${fondu('opacity', C, [[0, 0], [E1, 0], [E1 + 0.005, 0.9], [E1 + 0.05, 0], [1, 0]])}${fondu('r', C, [[0, 7], [E1, 7], [E1 + 0.05, 30], [1, 30]])}</circle>`;
    }
  });
  // À jour fixe, deux salaires dans décembre : ils s'entourent d'or. Pas
  // de halo flou : un simple cadre, qui ne coûte rien à animer.
  const iA = rang(25, 11), iB = rang(19, 12), iP = rang(9, 1);
  for (const i of [iA, iB]) {
    frise += `<rect x="${X(i + 0.5) - 67}" y="145" width="134" height="52" rx="15" fill="none" stroke="${OR}" stroke-width="2" opacity="0">${visible(C, 0.06, G - 0.01, 0.01)}</rect>`;
  }
  // Puis le salaire de Noël ouvre janvier, et la prime n'ouvre rien.
  const etiquette = (cx, texte, couleur, l, de, a) => `<g opacity="0">${visible(C, de, a, 0.01)}
    <rect x="${cx}" y="159" width="${l}" height="24" rx="12" fill="${FOND}"/>
    <rect x="${cx}" y="159" width="${l}" height="24" rx="12" fill="${couleur}" fill-opacity="0.14" stroke="${couleur}" stroke-opacity="0.6"/>
    ${t(cx + l / 2, 175.5, texte, { taille: 11.5, couleur, poids: 700, ancre: 'middle' })}</g>`;
  frise += etiquette(X(iB + 0.5) + 70, 'ouvre janvier', BLEU, 112, E1 + 0.02, FIN - 0.01);
  frise += etiquette(X(iP + 0.5) + 70, 'n’ouvre rien', OR, 108, E2 + 0.02, FIN - 0.01);
  frise += t(84, 104, 'DU 20 NOVEMBRE 2025 AU 31 JANVIER 2026', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  frise += `<g>${paliers('opacity', C, etat(1, 0, 0))}${t(1196, 104, 'à jour fixe, le 25 : le salaire de Noël tombe en décembre', { taille: 12.5, couleur: OR, poids: 700, ancre: 'end' })}</g>`;
  frise += `<g opacity="0">${paliers('opacity', C, etat(0, 1, 0))}${t(1196, 104, 'chaque salaire ouvre son mois, le jour où il arrive', { taille: 12.5, couleur: VERT, poids: 700, ancre: 'end' })}</g>`;
  frise += `<g opacity="0">${paliers('opacity', C, etat(0, 0, 1))}${t(1196, 104, 'la prime n’est pas un salaire : elle n’ouvre aucun mois', { taille: 12.5, couleur: TITRE, poids: 700, ancre: 'end' })}</g>`;

  // ----------------------------------------------------------------------
  // Le téléphone : le réglage, puis la fiche du salaire de Noël, puis
  // celle de la prime.
  const PX = 60, PY = 368, PL = 316, PH = 428;
  const SX = PX + 12, SY = PY + 14, SL = PL - 24, SH = PH - 28;
  const x = (v) => SX + v, y = (v) => SY + v;
  const T = { reglage: 0.07, garde: 0.2 };
  const I = {
    retour: 'M19 12 H5 M11 6 L5 12 L11 18', droite: 'M9.5 6 L15.5 12 L9.5 18',
    cible: 'M12 21 A9 9 0 1 1 12 3 A9 9 0 1 1 12 21 M12 16 A4 4 0 1 1 12 8 A4 4 0 1 1 12 16',
    tirelire: 'M5 11 A7 6 0 0 1 19 11 V15 L17 16 V19 H14 V17 H10 V19 H7 V16 A6 6 0 0 1 5 11 Z M10 6 A2.5 2.5 0 0 1 14 6',
    agenda: 'M4 5.5 H20 V20 H4 Z M4 10 H20 M8.5 3 V7 M15.5 3 V7',
    sync: 'M4 9 H18 M14 5 L18 9 M20 15 H6 M10 19 L6 15', label: 'M4 6 H15 L20 12 L15 18 H4 Z',
    payments: 'M3 6 H21 V18 H3 Z M12 15 A3 3 0 1 1 12 9 A3 3 0 1 1 12 15', coche: 'M5 12.5 L10 17 L19 7.5',
    bouclier: 'M12 3 L19 6 V11 C19 15.5 16 19 12 21 C8 19 5 15.5 5 11 V6 Z M9 12 L11.2 14.2 L15.5 9.8',
  };
  const ico = (nom, cx, cy, taille, couleur, ep = 2.2) =>
    `<g transform="translate(${cx - taille / 2},${cy - taille / 2}) scale(${taille / 24})"><path d="${I[nom]}" fill="none" stroke="${couleur}" stroke-width="${ep}" stroke-linecap="round" stroke-linejoin="round"/></g>`;
  const ligne = (py, icone, libelle, valeurs) => `<line x1="${x(26)}" y1="${y(py)}" x2="${x(SL - 26)}" y2="${y(py)}" stroke="#FFFFFF" stroke-opacity="0.07"/>
    <rect x="${x(26)}" y="${y(py + 8)}" width="28" height="28" rx="9" fill="#FFFFFF" fill-opacity="0.04"/>${ico(icone, x(40), y(py + 22), 14, APP.second)}
    ${t(x(62), y(py + 26.5), libelle, { taille: 11.5, couleur: APP.texte, poids: 600 })}
    ${valeurs}
    ${ico('droite', x(SL - 30), y(py + 22), 13, APP.discret)}`;
  const valeur = (py, s, couleur = APP.second) => t(x(SL - 40), y(py + 26.5), s, { taille: 11, couleur, poids: 700, ancre: 'end' });

  // Les réglages, le bloc Budget, et la carte du début du mois.
  let grille = '';
  for (let j = 1; j <= 28; j++) {
    const col = (j - 1) % 7, lig = Math.floor((j - 1) / 7);
    grille += t(x(44 + col * 34), y(262 + lig * 30), String(j), { taille: 11, couleur: APP.second, poids: 700, ancre: 'middle' });
  }
  const choix = `<g opacity="0">${visible(C, T.reglage + 0.008, T.garde + 0.004, 0.006)}
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000000" fill-opacity="0.7"/>
    <rect x="${x(12)}" y="${y(96)}" width="${SL - 24}" height="276" rx="20" fill="#181818"/>
    ${t(x(28), y(126), 'Début du mois', { taille: 14, couleur: APP.texte, poids: 800 })}
    <rect x="${x(24)}" y="${y(140)}" width="${SL - 48}" height="88" rx="14" fill="${VERT}" fill-opacity="0.12"/>
    ${ico('payments', x(46), y(166), 18, VERT)}
    ${t(x(66), y(168), 'Le jour du salaire', { taille: 12, couleur: APP.texte, poids: 700 })}
    ${ico('coche', x(SL - 44), y(166), 16, VERT, 2.6)}
    ${['Chaque salaire ouvre son mois le jour', 'où il arrive, même en avance. Le jour', 'habituel est repéré tout seul.'].map((s, i) => t(x(66), y(188 + i * 14), s, { taille: 10, couleur: APP.second })).join('')}
    ${grille}
    ${toucher(x(SL / 2), y(184), C, T.garde)}
  </g>`;
  const reglages = `<g>${visible(C, 0, E1 - 0.012, 0.006)}
    ${t(x(16), y(40), 'Réglages', { taille: 19, couleur: APP.texte, poids: 800 })}
    <rect x="${x(12)}" y="${y(60)}" width="${SL - 24}" height="162" rx="16" fill="#181818"/>
    ${t(x(26), y(84), 'BUDGET', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
    ${ligne(92, 'cible', 'Budget mensuel', valeur(92, '1 500 €'))}
    ${ligne(126, 'tirelire', 'Objectif d’épargne', valeur(126, '6 000 €'))}
    ${ligne(160, 'agenda', 'Début du mois', valeur(160, 'Salaire, vers le 25', VERT))}
    <rect x="${x(12)}" y="${y(236)}" width="${SL - 24}" height="98" rx="16" fill="#181818"/>
    <rect x="${x(26)}" y="${y(252)}" width="30" height="30" rx="10" fill="${VERT}" fill-opacity="0.15" stroke="${VERT}" stroke-opacity="0.4"/>${ico('bouclier', x(41), y(267), 16, VERT)}
    ${t(x(66), y(264), 'Tes données restent ici', { taille: 12, couleur: APP.texte, poids: 800 })}
    ${['Aucun serveur, aucun compte,', 'aucune publicité. Tout est', 'chiffré sur ce téléphone.'].map((s, i) => t(x(66), y(282 + i * 15), s, { taille: 10, couleur: APP.second })).join('')}
    ${toucher(x(SL / 2), y(182), C, T.reglage)}
    ${choix}
  </g>`;

  // Une fiche d'opération : le salaire de Noël, puis la prime.
  const fiche = (nom, montant, categorie, libelle, date, de, a, cadre = false) => `<g opacity="0">${visible(C, de, a, 0.006)}
    <g><animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${de};${de + 0.012};1" values="30 0;30 0;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.2 0 0.2 1;0 0 1 1"/>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="${APP.fond}"/>
    <circle cx="${x(30)}" cy="${y(34)}" r="16" fill="#1C1C1C"/>${ico('retour', x(30), y(34), 16, APP.texte)}
    ${t(x(56), y(39.5), nom, { taille: 15, couleur: APP.texte, poids: 700 })}
    <rect x="${x(SL / 2 - 24)}" y="${y(60)}" width="48" height="48" rx="15" fill="#1BCC6D" fill-opacity="0.15" stroke="#1BCC6D" stroke-opacity="0.4"/>${ico('payments', x(SL / 2), y(84), 24, '#1BCC6D')}
    ${t(x(SL / 2), y(138), eur(montant, true), { taille: 24, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(x(SL / 2), y(158), libelle, { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
    ${t(x(SL / 2), y(172), date, { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
    <rect x="${x(12)}" y="${y(186)}" width="${SL - 24}" height="${SH - 196}" rx="16" fill="#181818"/>
    ${t(x(26), y(208), 'CLASSEMENT', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
    ${ligne(216, 'sync', 'Mouvement', valeur(216, 'Revenu'))}
    ${ligne(252, 'label', 'Catégorie', valeur(252, categorie, '#1BCC6D'))}
    ${cadre ? `<rect x="${x(20)}" y="${y(292)}" width="${SL - 40}" height="36" rx="10" fill="${BLEU}" fill-opacity="0.1" stroke="${BLEU}" stroke-opacity="0.45"/>` : ''}
    ${ligne(288, 'agenda', 'Compte en', valeur(288, 'Janvier', BLEU))}
    </g></g>`;
  // Pas de ligne Type dans le classement : elle n'existe que pour une
  // dépense.
  const telephone = `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="36" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="moEcran"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="24"/></clipPath>
    <rect x="${PX + PL / 2 - 30}" y="${PY + 5}" width="60" height="5" rx="2.5" fill="#1B222C"/>
    <g clip-path="url(#moEcran)"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="${APP.fond}"/>${reglages}
    ${fiche('Salaire', 185000, 'Salaire', 'VIR SEPA RECU SALAIRE DECEMBRE', 'Vendredi 19 décembre 2025 · Compte courant', E1 + 0.004, E2 - 0.012, true)}
    ${fiche('Prime', 25000, 'Salaire › Primes', 'VIR SEPA RECU PRIME FIN ANNEE', 'Vendredi 9 janvier 2026 · Compte courant', E2 + 0.004, 0.992)}</g>`;

  // ----------------------------------------------------------------------
  // Les trois temps, au milieu.
  const etapes = [
    ['Un repère : vers le 25', ['Réglages, Début du mois : le jour habituel', 'du salaire, trouvé tout seul. À jour fixe,', 'décembre aurait deux salaires.'], 0, E1],
    ['Chaque salaire ouvre son mois', ['Versé le 19 décembre pour Noël, il ouvre', 'janvier le jour même. Décembre s’arrête', 'le 18, avec un seul salaire.'], E1, E2],
    ['Un vrai salaire seulement', ['Classé Salaire, au moins la moitié du', 'salaire habituel, à dix jours au plus du 25.', 'La prime du 9 janvier n’ouvre rien.'], E2, 0.996],
  ];
  const EX = 396, EL = 378, EY = 400, PAS = 132;
  let milieu = '';
  etapes.forEach(([titre, lignes, de, a], k) => {
    const ey = EY + k * PAS;
    milieu += `<rect x="${EX}" y="${ey - 30}" width="${EL}" height="${PAS - 14}" rx="14" fill="${CARTE}" stroke="${VERT}" stroke-opacity="0.5" opacity="0">${visible(C, de + 0.004, a - 0.004, 0.006)}</rect>
      <circle cx="${EX + 30}" cy="${ey}" r="17" fill="${FOND}" stroke="${FIL}" stroke-width="2"/>
      <g opacity="0">${visible(C, de + 0.004, FIN, 0.006)}<circle cx="${EX + 30}" cy="${ey}" r="17" fill="${VERT}"/>
      ${t(EX + 30, ey + 5, String(k + 1), { taille: 14, couleur: '#000000', police: MONO, poids: 800, ancre: 'middle' })}</g>
      <g>${fondu('opacity', C, [[0, 1], [de, 1], [de + 0.004, 0], [FIN, 0], [1, 1]])}${t(EX + 30, ey + 5, String(k + 1), { taille: 14, couleur: TEXTE, police: MONO, poids: 700, ancre: 'middle' })}</g>
      ${t(EX + 60, ey + 5, titre, { taille: 16.5, couleur: TITRE, poids: 700 })}
      ${lignes.map((s, i) => t(EX + 60, ey + 28 + i * 19, s, { taille: 13 })).join('')}`;
  });

  // ----------------------------------------------------------------------
  // Les totaux de décembre et de janvier, à droite.
  const TX = 792, TL = 428;
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
      if (v[1] !== v[0]) s += `<rect x="${TX + 12}" y="${ly - 21}" width="${TL - 24}" height="34" rx="9" fill="${VERT}" fill-opacity="0.12" opacity="0">${fondu('opacity', C, [[0, 0], [E1, 0], [E1 + 0.01, 1], [E1 + 0.09, 0], [1, 0]])}</rect>`;
      s += t(TX + 22, ly + 1, libelle, { taille: 14, couleur: n === 2 ? TITRE : TEXTE, poids: n === 2 ? 700 : 400 });
      s += selon(v, (val) => t(TX + TL - 22, ly + 1, eur(val, n !== 1), {
        taille: 15, police: MONO, poids: 700, ancre: 'end',
        couleur: n === 1 ? TITRE : val > 0 ? VERT : val < 0 ? '#FF6B7A' : TEXTE,
      }));
    });
    return s;
  };
  // [entrées, sorties, solde] à jour fixe, puis quand le salaire ouvre.
  let droite = totaux(360, 'Décembre', VERT, ['du 25 novembre au 24 décembre', 'du 25 novembre au 18 décembre', 'du 25 novembre au 18 décembre'],
    [[370000, 84360, 285640], [185000, 67870, 117130], [185000, 67870, 117130]]);
  droite += totaux(572, 'Janvier', BLEU, ['du 25 décembre au 24 janvier', 'du 19 décembre au 26 janvier', 'du 19 décembre au 26 janvier'],
    [[25000, 64370, -39370], [210000, 80860, 129140], [210000, 80860, 129140]]);
  // À jour fixe : deux salaires en décembre, la prime seule en janvier.
  const signal = (py, s) => `<rect x="${TX + 150}" y="${py}" width="120" height="22" rx="11" fill="${OR}" fill-opacity="0.14" stroke="${OR}" stroke-opacity="0.6"/>${t(TX + 210, py + 15, s, { taille: 11.5, couleur: OR, poids: 700, ancre: 'middle' })}`;
  droite += `<g opacity="0">${visible(C, 0.06, G - 0.01, 0.01)}${signal(421, 'deux salaires')}${signal(633, 'la prime seule')}</g>`;

  let corps = '';
  corps += t(60, 52, 'LE MOIS BUDGÉTAIRE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  // Le sous-titre suit la longueur du titre, qui change en anglais.
  corps += t(60 + O.tr('LE MOIS BUDGÉTAIRE').length * 10.9 + 32, 52, 'Chaque salaire ouvre son mois le jour où il arrive, même en avance pour Noël.', { taille: 14 });
  corps += frise + telephone + milieu + droite;
  svg('mois.svg', 1280, 812, corps,
    'Le mois budgétaire, sur une frise du 20 novembre 2025 au 31 janvier 2026 et un téléphone animé. Onze opérations : un salaire de 1 850 euros le 25 novembre, des courses, le loyer de 520 euros le 5 décembre, des courses, un salaire versé en avance pour Noël le 19 décembre, des cadeaux le 23 décembre, des courses, le loyer le 5 janvier, une prime de 250 euros classée Salaire le 9 janvier, des courses, et le salaire du 27 janvier. 1, dans les réglages, Début du mois dit Salaire, vers le 25 : le jour habituel du salaire, trouvé tout seul, n’est qu’un repère. À jour fixe, décembre irait du 25 novembre au 24 décembre, avec deux salaires, 3 700 euros d’entrées, et janvier n’aurait que la prime, pour un solde de -393,70 euros. 2, chaque salaire ouvre son mois le jour où il arrive : celui du 19 décembre ouvre janvier ce jour-là, et sa fiche dit Compte en Janvier. Décembre va du 25 novembre au 18 décembre, 1 850 euros d’entrées pour 678,70 de sorties ; janvier du 19 décembre au 26 janvier, 2 100 euros d’entrées pour 808,60 de sorties ; le salaire du 27 janvier ouvre février. 3, seul un vrai salaire ouvre un mois : classé Salaire, au moins la moitié du salaire habituel, à dix jours au plus du jour habituel. La prime de 250 euros du 9 janvier n’ouvre rien.');
};

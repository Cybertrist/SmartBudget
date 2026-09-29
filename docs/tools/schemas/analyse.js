// L'écran Analyse, du mois choisi jusqu'à une opération.
//
// À gauche, le téléphone : on change de mois et de période, on passe
// d'un onglet à l'autre, le centre de l'anneau ouvre les opérations, puis
// on descend de Logement à Loyer, jusqu'à Foncia Loyer. À droite, les six
// gestes s'allument tour à tour, et le chemin parcouru s'écrit en bas.
//
// Les montants sont ceux du jeu d'essai, inventés.
const path = require('path');

module.exports = (O) => {
  const { svg, t, fondu, visible, toucher, APP, MONO, FOND, CARTE, BORD, TITRE, DISCRET, FIL, VERT, OR, ROSE, BLEU } = O;
  const S = require(path.join(__dirname, '..', 'symboles.json'));

  const C = 40;
  const PX = 70, PY = 96, PL = 330, PH = 660;
  const SX = PX + 12, SY = PY + 16, SL = PL - 24, SH = PH - 32;
  const x = (v) => SX + v, y = (v) => SY + v;
  const MIL = SL / 2;

  // Les couleurs des catégories, celles de assets/categories.json.
  const K = {
    logement: '#5AB2FF', courses: '#50F48D', resto: '#FFC857', shopping: '#FF9F5A', transports: '#9B8CFF',
    abonnements: '#FF8FD1', aclasser: '#71877A', salaire: '#1BCC6D', autres: '#7FE0A8', sante: '#4DE2D0',
  };

  // Des pictogrammes en traits, sur une grille de 24.
  const I = {
    home: 'M4 11 L12 4 L20 11 M6 9.5 V20 H18 V9.5',
    cart: 'M2.5 4.5 H5.5 L8 15 H18 L20.5 7.5 H6.5 M9 19.5 h0.1 M17 19.5 h0.1',
    resto: 'M7 3 V21 M4 3 V8 A3 3 0 0 0 10 8 V3 M17 3 C13.5 5 13.5 11 17 12.5 V21',
    bag: 'M5 8 H19 L18 21 H6 Z M9 8 V6.5 A3 3 0 0 1 15 6.5 V8',
    car: 'M3.5 16 V12 L6 7 H18 L20.5 12 V16 Z M3.5 12 H20.5 M7 16 V19 M17 16 V19',
    autorenew: 'M19 12 A7 7 0 0 1 6.5 16.8 M5 12 A7 7 0 0 1 17.5 7.2 M17.8 3.5 V7.5 H13.8 M6.2 20.5 V16.5 H10.2',
    help: 'M12 21 A9 9 0 1 1 12 3 A9 9 0 1 1 12 21 M9.5 9.5 A2.5 2.5 0 1 1 13.2 11.7 C12.4 12.2 12 12.8 12 13.8 M12 17 v0.1',
    key: 'M8 16 A4 4 0 1 1 8 8 A4 4 0 1 1 8 16 M12 12 H21 M18 12 V15 M21 12 V14.5',
    bolt: 'M13.5 3 L6 13.5 H11.5 L10.5 21 L18 10.5 H12.5 Z',
    payments: 'M3 6 H21 V18 H3 Z M12 15 A3 3 0 1 1 12 9 A3 3 0 1 1 12 15',
    trending: 'M3 17 L9 11 L13 15 L21 7 M15 7 H21 V13',
    medical: 'M9 3 H15 V9 H21 V15 H15 V21 H9 V15 H3 V9 H9 Z',
    retour: 'M19 12 H5 M11 6 L5 12 L11 18',
    gauche: 'M14.5 6 L8.5 12 L14.5 18',
    droite: 'M9.5 6 L15.5 12 L9.5 18',
    chercher: 'M10.5 17 A6.5 6.5 0 1 1 10.5 4 A6.5 6.5 0 1 1 10.5 17 M15.5 15.5 L20.5 20.5',
    plus: 'M12 5 V19 M5 12 H19',
    note: 'M5 4 H19 V20 H5 Z M8.5 9 H15.5 M8.5 13 H15.5 M8.5 17 H12.5',
    edit: 'M4 20 H8 L19 9 L15 5 L4 16 Z',
    sync: 'M4 9 H18 M14 5 L18 9 M20 15 H6 M10 19 L6 15',
    label: 'M4 6 H15 L20 12 L15 18 H4 Z',
    coeur: 'M12 20 L4.8 12.8 A4.3 4.3 0 0 1 12 7 A4.3 4.3 0 0 1 19.2 12.8 Z',
    agenda: 'M4 5.5 H20 V20 H4 Z M4 10 H20 M8.5 3 V7 M15.5 3 V7',
    coche: 'M5 12.5 L10 17 L19 7.5',
    horloge: 'M12 21 A9 9 0 1 1 12 3 A9 9 0 1 1 12 21 M12 7.5 V12 L15 14',
  };
  const ico = (nom, cx, cy, taille, couleur, ep = 2.2) =>
    `<g transform="translate(${cx - taille / 2},${cy - taille / 2}) scale(${taille / 24})"><path d="${I[nom]}" fill="none" stroke="${couleur}" stroke-width="${ep}" stroke-linecap="round" stroke-linejoin="round"/></g>`;
  const tuile = (cx, cy, taille, nom, couleur) =>
    `<rect x="${cx - taille / 2}" y="${cy - taille / 2}" width="${taille}" height="${taille}" rx="${taille * 0.32}" fill="${couleur}" fill-opacity="0.15" stroke="${couleur}" stroke-opacity="0.4"/>${ico(nom, cx, cy, taille * 0.5, couleur)}`;

  // « 1 349,91 € », comme format.dart.
  const eur = (c, signe = false) => {
    const a = Math.abs(c);
    const ent = String(Math.trunc(a / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    return `${c < 0 ? '-' : signe && c > 0 ? '+' : ''}${ent},${String(a % 100).padStart(2, '0')} €`;
  };

  /// Une opacité en paliers, allumée sur chacune des [fenetres].
  const fen = (fenetres) => {
    const e = [[0, fenetres.some(([d]) => d <= 0) ? 1 : 0]];
    const bornes = [...new Set(fenetres.flat().filter((v) => v > 0 && v < 1))].sort((a, b) => a - b);
    for (const b of bornes) e.push([b, fenetres.some(([d, f]) => d <= b && b < f) ? 1 : 0]);
    return `<animate attributeName="opacity" dur="${C}s" repeatCount="indefinite" calcMode="discrete" keyTimes="${e.map((v) => v[0]).join(';')}" values="${e.map((v) => v[1]).join(';')}"/>`;
  };
  const dans = (fenetres, contenu) => `<g opacity="0">${fen(fenetres)}${contenu}</g>`;
  /// Une page poussée : elle glisse depuis la droite en apparaissant.
  const page = (de, a, contenu) => `<g opacity="0">${visible(C, de, a, 0.004)}
    <g><animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${de};${de + 0.008};1" values="36 0;36 0;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.2 0 0.2 1;0 0 1 1"/>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="${APP.fond}"/>${contenu}</g></g>`;

  // Les instants, en fraction du cycle.
  const T = {
    moisAvant: 0.04, moisApres: 0.09, trois: 0.13, un: 0.175,
    entrees: 0.22, recurrences: 0.28, sorties: 0.34,
    centre: 0.39, retour: 0.49, glisse: 0.525, logement: 0.6, loyer: 0.73, foncia: 0.84,
  };
  const d = 0.005; // l'écran change juste après le toucher
  const B = [0, 0.2, 0.36, 0.52, T.loyer + d, T.foncia + d, 1];

  // ----------------------------------------------------------------------
  // L'anneau, comme graphiques.dart : les petites parts portées à 3,5 %,
  // les icônes au milieu de leur arc, écartées si elles se touchent.
  function anneau(cx, cy, r, parts) {
    const total = parts.reduce((s, p) => s + p.v, 0);
    const brut = parts.map((p) => p.v / total);
    const petites = brut.filter((p) => p < 0.035).length;
    const rendu = brut.filter((p) => p >= 0.035).reduce((s, p) => s + p, 0);
    const angles = brut.map((p) => (p < 0.035 ? 0.035 : (p / rendu) * (1 - petites * 0.035)) * 2 * Math.PI);
    let s = `<circle cx="${cx}" cy="${cy}" r="${r + 12}" fill="none" stroke="#FFFFFF" stroke-opacity="0.05"/><circle cx="${cx}" cy="${cy}" r="${r - 12}" fill="none" stroke="#FFFFFF" stroke-opacity="0.05"/>`;
    let a0 = -Math.PI / 2;
    const milieux = [];
    parts.forEach((p, i) => {
      const a1 = a0 + angles[i] - 0.045;
      const grand = a1 - a0 > Math.PI ? 1 : 0;
      s += `<path d="M${(cx + r * Math.cos(a0)).toFixed(1)} ${(cy + r * Math.sin(a0)).toFixed(1)} A${r} ${r} 0 ${grand} 1 ${(cx + r * Math.cos(a1)).toFixed(1)} ${(cy + r * Math.sin(a1)).toFixed(1)}" fill="none" stroke="${p.c}" stroke-width="13"/>`;
      milieux.push(a0 + angles[i] / 2);
      a0 += angles[i];
    });
    const R = r + 28, ecart = 30 / R;
    const m = [...milieux];
    for (let passe = 0; passe < 40; passe++) {
      let bouge = false;
      for (let i = 0; i < m.length && m.length > 1; i++) {
        const j = (i + 1) % m.length;
        let e = m[j] - m[i];
        if (j === 0) e += 2 * Math.PI;
        if (e < ecart) { m[i] -= (ecart - e) / 2; m[j] += (ecart - e) / 2; bouge = true; }
      }
      if (!bouge) break;
    }
    parts.forEach((p, i) => {
      const bx = cx + R * Math.cos(m[i]), by = cy + R * Math.sin(m[i]);
      s += `<rect x="${(bx - 13).toFixed(1)}" y="${(by - 13).toFixed(1)}" width="26" height="26" rx="8" fill="#181818" stroke="${p.c}" stroke-opacity="0.45"/>${ico(p.i, bx, by, 15, p.c)}`;
    });
    return s;
  }

  // Les quatre états de l'anneau des sorties, et celui des entrées.
  const SEPT = [
    ['Logement', 55677, K.logement, 'home'], ['Courses', 26852, K.courses, 'cart'],
    ['Restaurants et sorties', 15230, K.resto, 'resto'], ['Shopping', 12407, K.shopping, 'bag'],
    ['Transports', 10478, K.transports, 'car'], ['Abonnements', 7409, K.abonnements, 'autorenew'],
    ['À classer', 6938, K.aclasser, 'help'],
  ];
  const AOUT = [
    ['Logement', 55912, K.logement, 'home'], ['Courses', 30144, K.courses, 'cart'],
    ['Restaurants et sorties', 18860, K.resto, 'resto'], ['Transports', 13120, K.transports, 'car'],
    ['Shopping', 9630, K.shopping, 'bag'], ['Abonnements', 7409, K.abonnements, 'autorenew'],
    ['À classer', 6161, K.aclasser, 'help'],
  ];
  const TROIS = [
    ['Logement', 167245, K.logement, 'home'], ['Courses', 84210, K.courses, 'cart'],
    ['Restaurants et sorties', 47108, K.resto, 'resto'], ['Transports', 33042, K.transports, 'car'],
    ['Shopping', 30176, K.shopping, 'bag'], ['À classer', 27855, K.aclasser, 'help'],
    ['Abonnements', 22227, K.abonnements, 'autorenew'],
  ];
  const ENTREES = [['Salaire', 128540, K.salaire, 'payments'], ['Autres revenus', 2400, K.autres, 'trending']];

  const RY = 322, RR = 74;
  const centre = (titre, montant, nb) => `
    ${t(x(MIL), y(RY - 22), titre, { taille: 10, couleur: APP.second, poids: 700, ancre: 'middle', extra: 'letter-spacing="1.6"' })}
    ${t(x(MIL), y(RY + 8), eur(montant), { taille: 23, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(x(MIL - 4), y(RY + 30), `${nb} opérations`, { taille: 11, couleur: VERT, poids: 700, ancre: 'middle' })}
    ${ico('droite', x(MIL + 40), y(RY + 26), 13, VERT, 2.6)}`;
  const vueAnneau = (liste, titre, nb) => {
    const parts = liste.map(([, v, c, i]) => ({ v, c, i }));
    const total = liste.reduce((s, l) => s + l[1], 0);
    return `<g transform="translate(${x(0)},${y(0)})">${anneau(MIL, RY, RR, parts)}</g>${centre(titre, total, nb)}`;
  };

  const pilule = (py, texte) => {
    const l = texte.length * 5.35 + 40;
    return `<rect x="${x(MIL - l / 2)}" y="${y(py)}" width="${l}" height="26" rx="13" fill="#1A1A1A" stroke="#8FA3B8" stroke-opacity="0.3"/>
      ${ico('sync', x(MIL - l / 2 + 16), y(py + 13), 12, '#8FA3B8', 2.4)}
      ${t(x(MIL - l / 2 + 28), y(py + 17), texte, { taille: 10.5, couleur: APP.second, poids: 700 })}`;
  };
  const carteApp = (py, h) => `<rect x="${x(14)}" y="${y(py)}" width="${SL - 28}" height="${h}" rx="16" fill="#181818"/>`;
  const surtitre = (px, py, s) => t(x(px), y(py), s, { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' });
  const jauge = (px, py, l, part, couleur, h = 4) =>
    `<rect x="${x(px)}" y="${y(py)}" width="${l}" height="${h}" rx="${h / 2}" fill="#2A2A2A"/><rect x="${x(px)}" y="${y(py)}" width="${Math.max(l * part, h)}" height="${h}" rx="${h / 2}" fill="${couleur}"/>`;

  // Le bas de l'analyse : la pilule des virements, le budget, la liste.
  const bas = (liste, virements, budget) => {
    let s = pilule(446, `Hors virements internes · ${eur(virements)} déplacés`);
    let ly = 486;
    if (budget) {
      const total = liste.reduce((a, l) => a + l[1], 0);
      s += `${carteApp(486, 94)}
        ${t(x(30), y(512), 'Budget du mois', { taille: 12.5, couleur: APP.texte, poids: 700 })}
        ${t(x(SL - 30), y(512), `${Math.round((total * 100) / 150000)} %`, { taille: 11.5, couleur: APP.second, ancre: 'end' })}
        ${jauge(30, 526, SL - 60, total / 150000, OR, 7)}
        ${t(x(30), y(558), `${eur(total)} dépensés`, { taille: 10.5, couleur: APP.discret })}
        ${t(x(SL - 30), y(558), '1 500 €', { taille: 10.5, couleur: APP.discret, ancre: 'end' })}`;
      ly = 594;
    }
    const plusGrand = liste[0][1];
    s += `<rect x="${x(14)}" y="${y(ly)}" width="${SL - 28}" height="${liste.length * 54 + 44}" rx="16" fill="#181818"/>
      ${surtitre(30, ly + 26, 'CATÉGORIES')}
      ${t(x(SL - 30), y(ly + 26), 'Toutes', { taille: 11, couleur: VERT, poids: 700, ancre: 'end' })}`;
    liste.forEach(([nom, v, c, i], k) => {
      const ry = ly + 38 + k * 54;
      if (k) s += `<line x1="${x(28)}" y1="${y(ry)}" x2="${x(SL - 28)}" y2="${y(ry)}" stroke="#FFFFFF" stroke-opacity="0.07"/>`;
      s += `${tuile(x(46), y(ry + 27), 36, i, c)}
        ${t(x(74), y(ry + 24), nom, { taille: 12.5, couleur: APP.texte, poids: 700 })}
        ${t(x(SL - 28), y(ry + 24), eur(v), { taille: 12, couleur: APP.texte, poids: 700, ancre: 'end' })}
        ${jauge(74, ry + 34, SL - 102, v / plusGrand, c)}`;
    });
    return s;
  };

  // Les récurrences : payées sur attendues, puis à venir et payées.
  const ligneRec = (ry, nom, montant, etat, couleur, icone) => `
    ${tuile(x(46), y(ry + 24), 34, 'autorenew', ROSE)}
    ${t(x(72), y(ry + 20), nom, { taille: 12.5, couleur: APP.texte, poids: 700 })}
    ${t(x(72), y(ry + 36), 'Chaque mois', { taille: 10.5, couleur: APP.discret })}
    ${t(x(SL - 42), y(ry + 20), eur(montant), { taille: 12, couleur: APP.texte, poids: 700, ancre: 'end' })}
    ${ico(icone, x(SL - 42 - etat.length * 5.6 - 10), y(ry + 32), 11, couleur, 2.6)}
    ${t(x(SL - 42), y(ry + 36), etat, { taille: 10.5, couleur, poids: 700, ancre: 'end' })}
    ${ico('droite', x(SL - 30), y(ry + 26), 13, APP.discret)}`;
  const vueRecurrences = `
    ${carteApp(210, 112)}
    ${t(x(MIL), y(254), eur(-63086), { taille: 26, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(x(MIL), y(278), `payés sur ${eur(63316)} attendus ce mois-ci`, { taille: 11, couleur: APP.second, ancre: 'middle' })}
    ${jauge(30, 296, SL - 60, 0.996, VERT, 6)}
    ${carteApp(336, 84)}
    ${surtitre(30, 360, 'À VENIR')}
    ${ligneRec(366, 'Frais Cotisation Carte', -230, 'dans 4 j', OR, 'agenda')}
    ${carteApp(434, 140)}
    ${surtitre(30, 458, 'PAYÉES')}
    ${ligneRec(464, 'Foncia Loyer', -52000, 'le 5', VERT, 'coche')}
    <line x1="${x(28)}" y1="${y(516)}" x2="${x(SL - 28)}" y2="${y(516)}" stroke="#FFFFFF" stroke-opacity="0.07"/>
    ${ligneRec(518, 'Free Mobile', -1799, 'le 6', VERT, 'coche')}`;

  // ----------------------------------------------------------------------
  // L'écran Analyse. Tout défile, sauf la barre du bas.
  const SEPT_ = [[0, T.moisAvant + d], [T.moisApres + d, T.trois + d], [T.un + d, T.entrees + d], [T.sorties + d, 1]];
  const AOUT_ = [[T.moisAvant + d, T.moisApres + d]];
  const TROIS_ = [[T.trois + d, T.un + d]];
  const ENTREES_ = [[T.entrees + d, T.recurrences + d]];
  const RECUR_ = [[T.recurrences + d, T.sorties + d]];
  const puce = (i, texte, actif) => {
    const l = (SL - 28 - 12) / 3, px = 14 + i * (l + 6);
    return `<rect x="${x(px)}" y="${y(112)}" width="${l}" height="30" rx="11" fill="${actif ? VERT : 'none'}" fill-opacity="${actif ? 0.08 : 0}" stroke="${actif ? VERT : '#FFFFFF'}" stroke-opacity="${actif ? 0.33 : 0.07}"/>
      ${t(x(px + l / 2), y(131), texte, { taille: 11.5, couleur: actif ? VERT : APP.second, poids: 800, ancre: 'middle' })}`;
  };
  const onglet = (i, texte, actif) => {
    const l = (SL - 38) / 3, px = 19 + i * l;
    return `${actif ? `<rect x="${x(px)}" y="${y(155)}" width="${l}" height="34" rx="12" fill="${VERT}"/>` : ''}
      ${t(x(px + l / 2), y(176), texte, { taille: 12, couleur: actif ? '#000000' : APP.second, poids: 700, ancre: 'middle' })}`;
  };
  const puces = (k) => ['1 mois', '3 mois', '1 an'].map((s, i) => puce(i, s, i === k)).join('');
  const onglets = (k) => ['Sorties', 'Entrées', 'Récurrences'].map((s, i) => onglet(i, s, i === k)).join('');

  let analyse = `
    ${t(x(18), y(44), 'Analyse', { taille: 22, couleur: APP.texte, poids: 800 })}
    <rect x="${x(14)}" y="${y(60)}" width="${SL - 28}" height="44" rx="16" fill="#1A1A1A" stroke="#FFFFFF" stroke-opacity="0.06"/>
    ${ico('gauche', x(38), y(82), 20, APP.second, 2.4)}
    ${dans([[0, T.moisAvant + d], [T.moisApres + d, 1]], `${t(x(MIL), y(87), 'Septembre 2026', { taille: 13.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}${ico('droite', x(SL - 38), y(82), 20, '#3A3A3A', 2.4)}`)}
    ${dans(AOUT_, `${t(x(MIL), y(87), 'Août 2026', { taille: 13.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}${ico('droite', x(SL - 38), y(82), 20, APP.second, 2.4)}`)}
    ${dans([[0, T.trois + d], [T.un + d, 1]], puces(0))}
    ${dans(TROIS_, puces(1))}
    <rect x="${x(14)}" y="${y(150)}" width="${SL - 28}" height="44" rx="16" fill="#1A1A1A" stroke="#FFFFFF" stroke-opacity="0.06"/>
    ${dans([[0, T.entrees + d], [T.sorties + d, 1]], onglets(0))}
    ${dans(ENTREES_, onglets(1))}
    ${dans(RECUR_, onglets(2))}
    ${dans(SEPT_, vueAnneau(SEPT, 'SORTIES', 27) + bas(SEPT.map(([n, v, c, i]) => [n, v, c, i]), 35000, true))}
    ${dans(AOUT_, vueAnneau(AOUT, 'SORTIES', 31) + bas(AOUT, 20000, true))}
    ${dans(TROIS_, vueAnneau(TROIS, 'SORTIES', 84) + bas(TROIS, 75000, false))}
    ${dans(ENTREES_, vueAnneau(ENTREES, 'ENTRÉES', 2) + bas(ENTREES, 35000, false))}
    ${dans(RECUR_, vueRecurrences)}`;
  // Le défilement : le doigt remonte la page jusqu'à la liste.
  const DEFILE = 330;
  analyse = `<g>${analyse}<animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${T.glisse};${T.glisse + 0.025};1" values="0 0;0 0;0 -${DEFILE};0 -${DEFILE}" calcMode="spline" keySplines="0 0 1 1;0.3 0 0.2 1;0 0 1 1"/></g>`;
  // La barre du bas, avec les symboles de l'application.
  const nav = `<rect x="${x(12)}" y="${y(SH - 70)}" width="${SL - 24}" height="56" rx="28" fill="#1C1C1C" stroke="#FFFFFF" stroke-opacity="0.07"/>
    ${[['home', 'Mois'], ['pie_chart', 'Analyse'], ['savings', 'Épargne'], ['settings', 'Réglages']].map(([s, n], k) => {
      const cx = x(12 + (SL - 24) * (k + 0.5) / 4), actif = k === 1;
      return `${actif ? `<rect x="${cx - 32}" y="${y(SH - 64)}" width="64" height="44" rx="22" fill="#FFFFFF" fill-opacity="0.1"/>` : ''}
        <path transform="translate(${cx - 10},${y(SH - 60)}) scale(${20 / 960}) translate(0,960)" d="${S[actif ? s + '-fill' : s]}" fill="${actif ? APP.texte : APP.discret}"/>
        ${t(cx, y(SH - 26), n, { taille: 9.5, couleur: actif ? APP.texte : APP.discret, poids: actif ? 700 : 400, ancre: 'middle' })}`;
    }).join('')}`;
  const ecranAnalyse = `<g opacity="1">${fen([[0, T.centre + d], [T.retour + d, T.logement + d]])}
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="${APP.fond}"/>${analyse}${nav}</g>`;

  // ----------------------------------------------------------------------
  // Les pages poussées.
  const barre = (titre) => `<circle cx="${x(34)}" cy="${y(40)}" r="18" fill="#1C1C1C"/>${ico('retour', x(34), y(40), 18, APP.texte)}
    ${t(x(64), y(46), titre, { taille: 16, couleur: APP.texte, poids: 700 })}`;
  const jour = (py, nom, total) => `${t(x(20), y(py), nom, { taille: 11.5, couleur: APP.second, poids: 700 })}
    ${t(x(SL - 20), y(py), eur(total), { taille: 11, couleur: APP.discret, ancre: 'end' })}`;
  const ligneOp = (py, nom, montant, icone, couleur) => `
    <rect x="${x(14)}" y="${y(py)}" width="${SL - 28}" height="60" rx="16" fill="#181818"/>
    ${tuile(x(50), y(py + 30), 38, icone, couleur)}
    ${t(x(80), y(py + 27), nom, { taille: 13, couleur: APP.texte, poids: 700 })}
    ${t(x(80), y(py + 44), 'Compte courant', { taille: 10.5, couleur: APP.discret })}
    ${t(x(SL - 30), y(py + 35), eur(montant), { taille: 13, couleur: APP.texte, poids: 700, ancre: 'end' })}`;

  // Le centre de l'anneau : les sorties de la période, jour par jour.
  const ops = [
    ['Jeudi 24 septembre', 'Esso Kerlann', -5158, 'car', K.transports],
    ['Mercredi 23 septembre', 'Uber Eats', -1662, 'resto', K.resto],
    ['Mardi 22 septembre', 'Pharmacie du Port', -769, 'medical', K.sante],
    ['Lundi 21 septembre', 'Lidl Vannes', -3400, 'cart', K.courses],
    ['Samedi 19 septembre', 'Parking Republique', -360, 'car', K.transports],
  ];
  const ecranOps = page(T.centre + d, T.retour + d, `
    ${barre('Sorties')}
    <rect x="${x(14)}" y="${y(70)}" width="186" height="44" rx="22" fill="#1C1C1C"/>
    ${ico('chercher', x(36), y(92), 17, APP.second)}
    ${t(x(54), y(96), 'Chercher un nom, une…', { taille: 11.5, couleur: APP.discret })}
    <rect x="${x(208)}" y="${y(70)}" width="84" height="44" rx="22" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.35"/>
    ${ico('plus', x(224), y(92), 15, VERT, 2.8)}
    ${t(x(236), y(96.5), 'Espèces', { taille: 11.5, couleur: VERT, poids: 700 })}
    ${ops.map(([j, nom, m, i, c], k) => jour(146 + k * 94, j, m) + ligneOp(156 + k * 94, nom, m, i, c)).join('')}`);

  // Logement : son total, sa part, ses sous-catégories.
  const lueur = (id, c) => `<linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c}" stop-opacity="0.28"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></linearGradient>
    <rect x="${SX}" y="${SY}" width="${SL}" height="260" fill="url(#${id})"/>`;
  const vides = ['Gaz', 'Eau', 'Assurance habitation', 'Charges diverses', 'Entretien et bricolage', 'Décoration', 'Mobilier', 'Électroménager', 'Extérieur et jardin', 'Autres'];
  let pastilles = '', pxv = 28, pyv = 452;
  for (const n of vides) {
    const l = n.length * 5.7 + 22;
    if (pxv + l > SL - 28) { pxv = 28; pyv += 30; }
    pastilles += `<rect x="${x(pxv)}" y="${y(pyv)}" width="${l}" height="26" rx="13" fill="#1E1E1E" stroke="#FFFFFF" stroke-opacity="0.08"/>
      ${t(x(pxv + l / 2), y(pyv + 17), n, { taille: 10.5, couleur: APP.second, poids: 600, ancre: 'middle' })}`;
    pxv += l + 7;
  }
  const ligneSous = (py, nom, icone, montant) => `<line x1="${x(28)}" y1="${y(py)}" x2="${x(SL - 28)}" y2="${y(py)}" stroke="#FFFFFF" stroke-opacity="0.07"/>
    ${tuile(x(45), y(py + 25), 32, icone, K.logement)}
    ${t(x(72), y(py + 30), nom, { taille: 13, couleur: APP.texte, poids: 700 })}
    ${t(x(SL - 44), y(py + 30), eur(montant), { taille: 12.5, couleur: APP.texte, poids: 700, ancre: 'end' })}
    ${ico('droite', x(SL - 32), y(py + 25), 14, APP.discret)}`;
  const ecranLogement = page(T.logement + d, T.loyer + d, `
    ${lueur('anLueurLogement', K.logement)}
    ${barre('Logement')}
    <rect x="${x(14)}" y="${y(64)}" width="${SL - 28}" height="40" rx="16" fill="#1A1A1A" stroke="#FFFFFF" stroke-opacity="0.06"/>
    ${ico('gauche', x(38), y(84), 18, APP.second, 2.4)}${ico('droite', x(SL - 38), y(84), 18, '#3A3A3A', 2.4)}
    ${t(x(MIL), y(89), 'Septembre 2026', { taille: 13, couleur: APP.texte, poids: 700, ancre: 'middle' })}
    ${tuile(x(MIL), y(146), 52, 'home', K.logement)}
    ${t(x(MIL), y(212), eur(-55677), { taille: 29, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(x(MIL), y(236), '41 % de tes dépenses du mois', { taille: 11.5, couleur: APP.second, ancre: 'middle' })}
    <rect x="${x(14)}" y="${y(254)}" width="${SL - 28}" height="${SH - 266}" rx="16" fill="#181818"/>
    ${surtitre(30, 280, 'SOUS-CATÉGORIES')}
    ${t(x(SL - 30), y(280), '12', { taille: 11, couleur: APP.discret, ancre: 'end' })}
    <rect x="${x(30)}" y="${y(294)}" width="${Math.round((SL - 60) * 0.934) - 3}" height="7" rx="3.5" fill="${K.logement}"/>
    <rect x="${x(30 + Math.round((SL - 60) * 0.934))}" y="${y(294)}" width="${Math.round((SL - 60) * 0.066)}" height="7" rx="3.5" fill="#7FC3FF"/>
    ${ligneSous(312, 'Loyer', 'key', 52000)}
    ${ligneSous(362, 'Électricité', 'bolt', 3677)}
    ${t(x(30), y(440), 'Rien ce mois-ci', { taille: 11, couleur: APP.discret, poids: 600 })}
    ${pastilles}`);

  // Loyer : ses opérations, jour par jour.
  const ecranLoyer = page(T.loyer + d, T.foncia + 0.025, `
    ${lueur('anLueurLoyer', K.logement)}
    ${barre('Loyer')}
    ${t(x(24), y(84), 'Logement  ›  Loyer', { taille: 11.5, couleur: APP.discret })}
    ${tuile(x(MIL), y(134), 52, 'key', K.logement)}
    ${t(x(MIL), y(200), eur(-52000), { taille: 29, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(x(MIL), y(224), 'en septembre 2026', { taille: 11.5, couleur: APP.second, ancre: 'middle' })}
    ${jour(270, 'Samedi 5 septembre', -52000)}
    ${ligneOp(280, 'Foncia Loyer', -52000, 'key', K.logement)}`);

  // L'opération : ce qui se lit, et ce qui se corrige.
  const ligneClasse = (py, icone, libelle, valeur, couleur = APP.second) => `<line x1="${x(28)}" y1="${y(py)}" x2="${x(SL - 28)}" y2="${y(py)}" stroke="#FFFFFF" stroke-opacity="0.07"/>
    <rect x="${x(28)}" y="${y(py + 9)}" width="30" height="30" rx="10" fill="#FFFFFF" fill-opacity="0.04"/>${ico(icone, x(43), y(py + 24), 15, APP.second)}
    ${t(x(68), y(py + 29), libelle, { taille: 12.5, couleur: APP.texte, poids: 600 })}
    ${t(x(SL - 44), y(py + 29), valeur, { taille: 12, couleur, poids: 700, ancre: 'end' })}
    ${ico('droite', x(SL - 32), y(py + 24), 14, APP.discret)}`;
  const ecranOperation = page(T.foncia + 0.025, 0.996, `
    ${barre('Foncia Loyer')}
    ${tuile(x(MIL), y(104), 60, 'key', K.logement)}
    ${t(x(MIL), y(170), eur(-52000), { taille: 31, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(x(MIL), y(194), 'Foncia Loyer', { taille: 13.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}
    ${t(x(MIL), y(214), 'PRLV SEPA FONCIA LOYER', { taille: 10.5, couleur: APP.discret, ancre: 'middle' })}
    ${t(x(MIL), y(230), 'Samedi 5 septembre 2026 · Compte courant', { taille: 10.5, couleur: APP.discret, ancre: 'middle' })}
    <rect x="${x(14)}" y="${y(248)}" width="${SL - 28}" height="44" rx="16" fill="#181818"/>
    ${ico('note', x(36), y(270), 16, APP.second)}${t(x(54), y(274.5), 'Ajouter une note', { taille: 12, couleur: APP.discret })}
    <rect x="${x(14)}" y="${y(304)}" width="${SL - 28}" height="290" rx="16" fill="#181818"/>
    ${surtitre(30, 330, 'CLASSEMENT')}
    ${ligneClasse(340, 'edit', 'Nom', 'Foncia Loyer')}
    ${ligneClasse(388, 'sync', 'Mouvement', 'Dépense')}
    ${ligneClasse(436, 'label', 'Catégorie', 'Logement › Loyer', K.logement)}
    ${ligneClasse(484, 'coeur', 'Type', 'Essentiel', K.logement)}
    ${ligneClasse(532, 'agenda', 'Compte en', 'Septembre')}`);

  // Les touchers et le défilement.
  const doigts = [
    [38, 82, T.moisAvant], [SL - 38, 82, T.moisApres], [MIL, 127, T.trois], [14 + (SL - 40) / 6, 127, T.un],
    [MIL, 172, T.entrees], [19 + 2.5 * (SL - 38) / 3, 172, T.recurrences], [19 + (SL - 38) / 6, 172, T.sorties],
    [MIL, RY + 4, T.centre], [34, 40, T.retour], [150, 594 + 38 + 27 - DEFILE, T.logement], [150, 337, T.loyer], [150, 310, T.foncia],
  ].map(([cx, cy, a]) => toucher(x(cx), y(cy), C, a)).join('');
  const g0 = T.glisse - 0.006, g1 = T.glisse + 0.025;
  const glisse = `<g opacity="0">${fondu('opacity', C, [[0, 0], [g0, 0], [g0 + 0.004, 1], [g1, 1], [g1 + 0.006, 0], [1, 0]])}
    <circle cx="${x(MIL + 40)}" r="13" fill="#FFFFFF" fill-opacity="0.28" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="1.5">
      <animate attributeName="cy" dur="${C}s" repeatCount="indefinite" keyTimes="0;${T.glisse};${g1};1" values="${y(500)};${y(500)};${y(200)};${y(200)}" calcMode="spline" keySplines="0 0 1 1;0.3 0 0.2 1;0 0 1 1"/></circle></g>`;

  let corps = '';
  corps += t(60, 52, 'L’ÉCRAN ANALYSE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  // Le sous-titre suit la longueur du titre, qui change en anglais.
  corps += t(60 + O.tr('L’ÉCRAN ANALYSE').length * 10.9 + 32, 52, 'Du mois choisi jusqu’à une opération : chaque ligne s’ouvre, le retour remonte d’un cran.', { taille: 14 });
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="42" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="anEcran"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="30"/></clipPath>
    <rect x="${PX + PL / 2 - 34}" y="${PY + 6}" width="68" height="5" rx="2.5" fill="#1B222C"/>
    <g clip-path="url(#anEcran)"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="${APP.fond}"/>
    ${ecranAnalyse}${ecranOps}${ecranLogement}${ecranLoyer}${ecranOperation}${doigts}${glisse}</g>`;

  // Les six gestes, à droite.
  const etapes = [
    ['Choisir le mois', ['Les flèches changent de mois ; celle de droite s’arrête au mois en cours.', '1 mois, 3 mois ou 1 an : la période se termine au mois affiché.']],
    ['Sorties, Entrées, Récurrences', ['Où part l’argent, d’où il vient, et ce qui revient chaque mois.', 'Les récurrences : payées, à venir ou en retard, sur ce qui était attendu.']],
    ['Le centre de l’anneau', ['Il ouvre les opérations que l’anneau compte, jour par jour.', 'Autour, une icône par catégorie, au milieu de son arc.']],
    ['Une catégorie', ['Plus bas, la liste des catégories. Logement : son total, sa part', 'des dépenses du mois, et ses sous-catégories, même vides.']],
    ['Une sous-catégorie', ['Loyer : ses opérations de la période, jour par jour,', 'sous le chemin Logement › Loyer.']],
    ['Une opération', ['Foncia Loyer : son nom, son mouvement, sa catégorie, son type,', 'et le mois où elle compte. Tout se corrige d’un toucher.']],
  ];
  const EX = 470, EY = 144, PAS = 94, N = etapes.length;
  corps += `<line x1="${EX + 22}" y1="${EY}" x2="${EX + 22}" y2="${EY + PAS * (N - 1)}" stroke="${FIL}" stroke-width="2"/>`;
  corps += `<line x1="${EX + 22}" y1="${EY}" x2="${EX + 22}" y2="${EY}" stroke="${VERT}" stroke-width="2">
    ${fondu('y2', C, [[0, EY], ...etapes.map((_, k) => [Math.max(B[k + 1] - 0.01, 0.001), EY + PAS * k]), [1, EY + PAS * (N - 1)]])}</line>`;
  etapes.forEach(([titre, lignes], k) => {
    const ey = EY + k * PAS;
    corps += `<rect x="${EX - 14}" y="${ey - 36}" width="${1220 - EX + 14}" height="${PAS - 14}" rx="14" fill="${CARTE}" stroke="${VERT}" stroke-opacity="0.5" opacity="0">${visible(C, B[k] + 0.004, B[k + 1] - 0.004, 0.006)}</rect>
      <circle cx="${EX + 22}" cy="${ey}" r="20" fill="${FOND}" stroke="${FIL}" stroke-width="2"/>
      <circle cx="${EX + 22}" cy="${ey}" r="20" fill="${VERT}" opacity="0" filter="url(#halo)">${visible(C, B[k] + 0.004, 0.996, 0.006)}</circle>
      ${t(EX + 22, ey + 6, String(k + 1), { taille: 16, couleur: '#8B99A8', police: MONO, poids: 700, ancre: 'middle' })}
      <g opacity="0">${visible(C, B[k] + 0.004, 0.996, 0.006)}${t(EX + 22, ey + 6, String(k + 1), { taille: 16, couleur: '#000000', police: MONO, poids: 800, ancre: 'middle' })}</g>
      ${t(EX + 62, ey - 6, titre, { taille: 18, couleur: TITRE, poids: 700 })}
      ${lignes.map((s, i) => t(EX + 62, ey + 15 + i * 19, s, { taille: 13.5 })).join('')}`;
  });

  // Le chemin parcouru : chaque page ouverte s'ajoute.
  const chemin = [['Analyse', 0], ['Logement', T.logement + d], ['Loyer', T.loyer + d], ['Foncia Loyer', T.foncia + d]];
  let cx = EX - 14;
  corps += t(cx, 712, 'LE CHEMIN', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  cx += 104;
  chemin.forEach(([nom, de], k) => {
    const l = nom.length * 8 + 30;
    if (k) corps += `<g opacity="${de ? 0 : 1}">${de ? visible(C, de, 0.996, 0.004) : ''}${t(cx - 14, 713, '›', { taille: 18, couleur: DISCRET, ancre: 'middle' })}</g>`;
    corps += `<g opacity="${de ? 0 : 1}">${de ? visible(C, de, 0.996, 0.004) : ''}
      <rect x="${cx}" y="${690}" width="${l}" height="32" rx="16" fill="${BLEU}" fill-opacity="0.08" stroke="${k ? '#5AB2FF' : VERT}" stroke-opacity="0.55"/>
      ${t(cx + l / 2, 711, nom, { taille: 13.5, couleur: TITRE, poids: 700, ancre: 'middle' })}</g>`;
    cx += l + 28;
  });
  corps += t(EX - 14, 748, 'L’analyse garde le mois, la période et l’onglet choisis : au retour, rien n’a bougé.', { taille: 13, couleur: DISCRET });

  svg('analyse.svg', 1280, 790, corps,
    'L’écran Analyse, sur un téléphone animé, en six gestes. 1, choisir le mois : la flèche de gauche passe de septembre à août 2026, où les sorties montent à 1 412,36 euros, puis la flèche de droite revient en septembre, et s’arrête au mois en cours ; les puces 1 mois, 3 mois et 1 an choisissent la période, qui se termine au mois affiché : 4 118,63 euros sur trois mois. 2, les onglets : Sorties, 1 349,91 euros ; Entrées, 1 309,40 euros, surtout le salaire ; Récurrences, 630,86 euros payés sur 633,16 attendus, avec ce qui est à venir et ce qui est payé. 3, l’anneau porte une icône par catégorie, et son centre ouvre les sorties du mois, jour par jour, avec la recherche et le bouton Espèces. 4, plus bas, la liste des catégories : toucher Logement ouvre son total, -556,77 euros, 41 % des dépenses du mois, et ses sous-catégories, Loyer et Électricité, puis en pastilles celles sans rien ce mois-ci. 5, toucher Loyer ouvre ses opérations jour par jour. 6, toucher Foncia Loyer ouvre l’opération : nom, mouvement, catégorie Logement › Loyer, type Essentiel, et Compte en Septembre. En bas, le chemin Analyse, Logement, Loyer, Foncia Loyer s’écrit au fil des pages. Au retour, l’analyse garde le mois, la période et l’onglet.');
};

// Les schémas animés du README.
//
// Des SVG plutôt que des GIF : quelques kilo-octets, nets à toute taille,
// et le texte reste du texte. Les animations sont en SMIL, que les
// navigateurs jouent même quand le SVG est chargé par une balise <img>,
// ce qui est le cas sur GitHub. Aucune police externe : un SVG affiché en
// <img> n'a pas le droit d'aller la chercher, on s'en tient aux familles
// du système.
//
//   node docs/tools/anime.js
const fs = require('fs');
const path = require('path');

const SORTIE = path.join(__dirname, '..', 'schemas');
fs.mkdirSync(SORTIE, { recursive: true });

const MONO = 'ui-monospace,SFMono-Regular,Menlo,Consolas,monospace';
const SANS = 'system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif';
const FOND = '#0D1117';
const CARTE = '#131A24';
const BORD = '#1F2833';
const TITRE = '#F0F4F8';
const TEXTE = '#8B99A8';
const DISCRET = '#5C6A7A';
const FIL = '#2F3A47';
const VERT = '#1ED760';
const NEON = '#50F48D';
const BLEU = '#3CE0FF';
const OR = '#FFC857';
const ROSE = '#FF8FD1';
const ROUGE = '#FF6B7A';
const INTERNE = '#8FA3B8';

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/// Le cadre commun : fond, grille estompée, filtre de halo.
function svg(nom, largeur, hauteur, corps, titre) {
  const contenu = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${largeur} ${hauteur}" width="${largeur}" height="${hauteur}" role="img" aria-label="${esc(titre)}">
<title>${esc(titre)}</title>
<defs>
  <filter id="halo" x="-50%" y="-50%" width="200%" height="200%">
    <feGaussianBlur stdDeviation="6" result="b"/>
    <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <pattern id="grille" width="40" height="40" patternUnits="userSpaceOnUse">
    <path d="M40 0H0V40" fill="none" stroke="#1ED760" stroke-opacity="0.05"/>
  </pattern>
  <pattern id="hachures" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="10" height="10" fill="#161D27"/><line x1="0" y1="0" x2="0" y2="10" stroke="#2A3542" stroke-width="4"/>
  </pattern>
  <radialGradient id="lueur" cx="50%" cy="0%" r="80%">
    <stop offset="0" stop-color="#1ED760" stop-opacity="0.10"/><stop offset="1" stop-color="#1ED760" stop-opacity="0"/>
  </radialGradient>
</defs>
<rect width="${largeur}" height="${hauteur}" rx="16" fill="${FOND}"/>
<rect width="${largeur}" height="${hauteur}" rx="16" fill="url(#grille)"/>
<rect width="${largeur}" height="${hauteur}" rx="16" fill="url(#lueur)"/>
${corps}
</svg>`;
  fs.writeFileSync(path.join(SORTIE, nom), contenu);
  console.log(`  ${nom}  ${(contenu.length / 1024).toFixed(1)} Ko`);
}

/// Un texte.
const t = (x, y, s, { taille = 14, couleur = TEXTE, police = SANS, poids = 400, ancre = 'start', extra = '' } = {}) =>
  `<text x="${x}" y="${y}" font-family="${police}" font-size="${taille}" font-weight="${poids}" fill="${couleur}" text-anchor="${ancre}" ${extra}>${esc(s)}</text>`;

/// Une valeur qui change par paliers au fil d'un cycle : [instant 0..1, valeur].
function paliers(attribut, cycle, etapes, extra = '') {
  const temps = etapes.map((e) => e[0]).join(';');
  const valeurs = etapes.map((e) => e[1]).join(';');
  return `<animate attributeName="${attribut}" dur="${cycle}s" repeatCount="indefinite" keyTimes="${temps}" values="${valeurs}" calcMode="discrete" ${extra}/>`;
}

/// Une valeur qui glisse d'un palier au suivant.
function fondu(attribut, cycle, etapes) {
  const temps = etapes.map((e) => e[0]).join(';');
  const valeurs = etapes.map((e) => e[1]).join(';');
  return `<animate attributeName="${attribut}" dur="${cycle}s" repeatCount="indefinite" keyTimes="${temps}" values="${valeurs}"/>`;
}

/// Apparaît à [de], disparaît à [a], sur un cycle.
function visible(cycle, de, a, douceur = 0.02) {
  const e = [[0, 0]];
  if (de > douceur) e.push([de - douceur, 0]);
  e.push([de, 1], [Math.min(a, 1), 1]);
  if (a + douceur < 1) e.push([a + douceur, 0], [1, 0]);
  return fondu('opacity', cycle, e);
}

/// Une carte de schéma : liseré coloré, titre en chasse fixe, sous-titre.
function carte(x, y, l, h, titre, sous, accent, { icone = '', allume = null, cycle = 10 } = {}) {
  const bord = allume
    ? `<rect x="${x}" y="${y}" width="${l}" height="${h}" rx="13" fill="none" stroke="${accent}" stroke-width="1.5" opacity="0" filter="url(#halo)">${visible(cycle, allume[0], allume[1])}</rect>`
    : '';
  return `<g>
  <rect x="${x}" y="${y}" width="${l}" height="${h}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
  ${bord}
  <rect x="${x}" y="${y + 14}" width="3" height="${h - 28}" rx="1.5" fill="${accent}"/>
  ${icone ? `<g transform="translate(${x + 18},${y + h / 2 - 14})">${icone(accent)}</g>` : ''}
  ${t(x + (icone ? 58 : 20), y + h / 2 - 3, titre, { taille: 14.5, couleur: TITRE, police: MONO, poids: 700 })}
  ${t(x + (icone ? 58 : 20), y + h / 2 + 17, sous, { taille: 12.5 })}
</g>`;
}

/// Une bille lumineuse qui suit un chemin, avec une pause par étape.
function bille(chemin, cycle, points, temps, couleur = NEON, rayon = 6) {
  return `<g filter="url(#halo)">
  <circle r="${rayon + 5}" fill="${couleur}" opacity="0.22">
    <animateMotion dur="${cycle}s" repeatCount="indefinite" path="${chemin}" keyPoints="${points}" keyTimes="${temps}" calcMode="linear"/>
  </circle>
  <circle r="${rayon}" fill="${couleur}">
    <animateMotion dur="${cycle}s" repeatCount="indefinite" path="${chemin}" keyPoints="${points}" keyTimes="${temps}" calcMode="linear"/>
  </circle>
</g>`;
}

/// Un fil pointillé qui court.
const fil = (d, couleur = FIL) =>
  `<path d="${d}" fill="none" stroke="${couleur}" stroke-width="2" stroke-dasharray="6 7">
  <animate attributeName="stroke-dashoffset" from="26" to="0" dur="1.2s" repeatCount="indefinite"/></path>`;

// Des pictogrammes simples, dessinés en traits : cadenas, banque, clé…
const P = {
  telephone: (c) => `<rect x="4" y="0" width="20" height="28" rx="4" fill="none" stroke="${c}" stroke-width="2"/><circle cx="14" cy="23" r="1.6" fill="${c}"/>`,
  banque: (c) => `<path d="M2 11 L14 3 L26 11 Z M5 13 H23 M7 14 V23 M12 14 V23 M16 14 V23 M21 14 V23 M3 25 H25" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/>`,
  nuage: (c) => `<path d="M8 22 H22 A5 5 0 0 0 21 12 A7 7 0 0 0 8 13 A4.5 4.5 0 0 0 8 22 Z" fill="none" stroke="${c}" stroke-width="2"/>`,
  page: (c) => `<rect x="4" y="2" width="20" height="24" rx="3" fill="none" stroke="${c}" stroke-width="2"/><path d="M9 10 H19 M9 15 H19 M9 20 H15" stroke="${c}" stroke-width="2"/>`,
  lien: (c) => `<path d="M11 17 L17 11 M9 13 L6 16 A4 4 0 0 0 12 22 L15 19 M19 15 L22 12 A4 4 0 0 0 16 6 L13 9" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
  horloge: (c) => `<circle cx="14" cy="14" r="11" fill="none" stroke="${c}" stroke-width="2"/><path d="M14 8 V14 L18 17" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
  cle: (c) => `<circle cx="9" cy="14" r="5" fill="none" stroke="${c}" stroke-width="2"/><path d="M14 14 H26 M22 14 V18 M25 14 V17" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
  cadenas: (c) => `<rect x="5" y="12" width="18" height="14" rx="3" fill="none" stroke="${c}" stroke-width="2"/><path d="M9 12 V8 A5 5 0 0 1 19 8 V12" fill="none" stroke="${c}" stroke-width="2"/>`,
  base: (c) => `<ellipse cx="14" cy="6" rx="10" ry="4" fill="none" stroke="${c}" stroke-width="2"/><path d="M4 6 V22 A10 4 0 0 0 24 22 V6 M4 14 A10 4 0 0 0 24 14" fill="none" stroke="${c}" stroke-width="2"/>`,
  empreinte: (c) => `<path d="M6 10 A9 9 0 0 1 22 10 M8 23 A12 12 0 0 1 7 16 A7 7 0 0 1 21 16 C21 19 20 21 19 23 M11 24 A10 10 0 0 1 10 16 A4 4 0 0 1 18 16 C18 19 17 21 15 24 M14 16 V20" fill="none" stroke="${c}" stroke-width="1.8" stroke-linecap="round"/>`,
  fichier: (c) => `<path d="M6 2 H17 L23 8 V26 H6 Z M17 2 V8 H23" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/>`,
  phrase: (c) => `<rect x="2" y="8" width="24" height="12" rx="3" fill="none" stroke="${c}" stroke-width="2"/><path d="M7 14 H8 M12 14 H13 M17 14 H18 M22 14 H22.5" stroke="${c}" stroke-width="3" stroke-linecap="round"/>`,
};

// ------------------------------------------------------------------------
// 1. Relier la banque : l'aller-retour qui ouvre l'accès au compte.
{
  const C = 14;
  const L = 330, H = 78;
  const xs = [60, 475, 890], hauts = 96, bas = 290;
  const etapes = [
    [xs[0], hauts, 'Smart Budget', 'JWT signé en RS256', P.telephone, VERT],
    [xs[1], hauts, 'Enable Banking', 'POST /auth, état au hasard', P.nuage, BLEU],
    [xs[2], hauts, 'Crédit Mutuel', 'tu valides par Safetrans', P.banque, OR],
    [xs[2], bas, 'GitHub Pages', 'cybertrist.github.io/SmartBudget', P.page, ROSE],
    [xs[1], bas, 'smartbudget://banque', 'état vérifié, POST /sessions', P.lien, NEON],
    [xs[0], bas, 'Session de 180 jours', '12 mois importés, puis à l’ouverture', P.horloge, VERT],
  ];
  // Le chemin passe par le centre de chaque carte.
  const cx = (i) => etapes[i][0] + L / 2, cy = (i) => etapes[i][1] + H / 2;
  const chemin = `M${cx(0)} ${cy(0)} H${cx(1)} H${cx(2)} V${cy(3)} H${cx(4)} H${cx(5)} V${cy(0)}`;
  // Longueurs relatives : 415, 415, 194, 415, 415, 194 sur 2048.
  const seg = [0, 415, 830, 1024, 1439, 1854, 2048].map((v) => (v / 2048).toFixed(4));
  const pts = [], tps = [];
  for (let i = 0; i < 6; i++) {
    const a = i / 6, b = a + 0.1;
    pts.push(seg[i], seg[i]); tps.push(a.toFixed(3), b.toFixed(3));
  }
  pts.push(seg[6]); tps.push('1');
  let corps = '';
  corps += t(60, 52, 'RELIER LA BANQUE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(270, 52, 'Un aller-retour, une fois tous les 180 jours. La clé privée ne quitte jamais le téléphone.', { taille: 14 });
  corps += fil(`M${cx(0) + L / 2} ${cy(0)} H${xs[1]} M${cx(1) + L / 2} ${cy(1)} H${xs[2]} M${cx(2)} ${hauts + H} V${bas} M${xs[2]} ${cy(3)} H${cx(4) + L / 2} M${xs[1]} ${cy(4)} H${cx(5) + L / 2}`);
  etapes.forEach((e, i) => {
    corps += carte(e[0], e[1], L, H, e[2], e[3], e[5], { icone: e[4], allume: [i / 6, i / 6 + 0.16], cycle: C });
  });
  // Les numéros d'étape.
  etapes.forEach((e, i) => {
    corps += `<circle cx="${e[0] + L - 22}" cy="${e[1] + 20}" r="11" fill="${FOND}" stroke="${e[5]}" stroke-opacity="0.5"/>` +
      t(e[0] + L - 22, e[1] + 24.5, String(i + 1), { taille: 12, couleur: e[5], police: MONO, poids: 700, ancre: 'middle' });
  });
  corps += bille(chemin, C, pts.join(';'), tps.join(';'));
  corps += t(640, 418, 'Le jeton d’état tiré au hasard empêche un lien fabriqué ailleurs de relier un autre compte.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('banque.svg', 1280, 440, corps,
    'Relier la banque, en six étapes qui s’allument tour à tour : Smart Budget signe un JWT en RS256 ; Enable Banking ouvre une demande avec un état tiré au hasard ; tu valides au Crédit Mutuel de Bretagne par Safetrans ; la banque revient sur GitHub Pages ; la page rend la main à l’application par smartbudget://banque, qui vérifie l’état et ouvre la session ; la session dure 180 jours, douze mois sont importés, puis une synchronisation à chaque ouverture.');
}

// ------------------------------------------------------------------------
// 2. Comment une opération est lue : du libellé brut à sa catégorie.
{
  const C = 12;
  let corps = '';
  corps += t(60, 52, 'COMMENT UNE OPÉRATION EST LUE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  // Le libellé, découpé en morceaux : le bruit s'éteint, le marchand reste.
  const morceaux = [
    ['PAIEMENT PAR CARTE', 'bruit', 212],
    ['X4057', 'bruit', 78],
    ['CARREFOUR MARKET VANNES', 'marchand', 266],
    ['12/09', 'bruit', 72],
  ];
  let x = 60;
  corps += t(60, 92, 'Le libellé, tel que la banque l’écrit', { taille: 13, couleur: DISCRET });
  for (const [texte, sorte, l] of morceaux) {
    const marchand = sorte === 'marchand';
    corps += `<g>
      <rect x="${x}" y="106" width="${l}" height="42" rx="9" fill="${CARTE}" stroke="${BORD}">
        ${marchand ? fondu('stroke', C, [[0, BORD], [0.14, BORD], [0.2, VERT], [0.92, VERT], [1, BORD]]) : ''}
      </rect>
      ${t(x + l / 2, 133, texte, { taille: 16, couleur: TITRE, police: MONO, poids: 600, ancre: 'middle', extra: '' })}
      ${marchand ? '' : `<line x1="${x + 10}" y1="127" x2="${x + l - 10}" y2="127" stroke="${ROUGE}" stroke-width="2" opacity="0">${visible(C, 0.1, 0.92)}</line>`}
      ${marchand ? '' : `<rect x="${x}" y="106" width="${l}" height="42" rx="9" fill="${FOND}" opacity="0">${fondu('opacity', C, [[0, 0], [0.12, 0], [0.2, 0.65], [0.92, 0.65], [1, 0]])}</rect>`}
    </g>`;
    x += l + 12;
  }
  corps += `<g opacity="0">${visible(C, 0.2, 0.92)}${t(x + 8, 133, 'clé du marchand : CARREFOUR MARKET VANNES', { taille: 13.5, couleur: VERT, police: MONO })}</g>`;

  // Les quatre questions, dans l'ordre : la première qui répond l'emporte.
  const qs = [
    ['Virement interne ?', 'VIR VERS … DE …', 'non', 0.3],
    ['Règle apprise ?', 'une correction passée', 'non', 0.42],
    ['Dictionnaire', '250 marchands connus', 'oui', 0.54],
    ['À classer', 'si rien ne répond', 'saut', 0.66],
  ];
  const l = 268, y = 206, h = 86;
  qs.forEach(([titre, sous, rep, instant], i) => {
    const xq = 60 + i * (l + 22);
    const couleur = rep === 'oui' ? VERT : rep === 'non' ? ROUGE : DISCRET;
    corps += `<g>
      <rect x="${xq}" y="${y}" width="${l}" height="${h}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${xq}" y="${y}" width="${l}" height="${h}" rx="13" fill="none" stroke="${couleur}" stroke-width="1.5" opacity="0" ${rep === 'oui' ? 'filter="url(#halo)"' : ''}>${visible(C, instant, rep === 'oui' ? 0.92 : instant + 0.1)}</rect>
      ${t(xq + 20, y + 36, titre, { taille: 15, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(xq + 20, y + 60, sous, { taille: 12.5 })}
      <g opacity="0">${visible(C, instant + 0.03, 0.92)}
        <circle cx="${xq + l - 30}" cy="${y + 30}" r="13" fill="${couleur}" fill-opacity="0.15" stroke="${couleur}"/>
        ${t(xq + l - 30, y + 35, rep === 'oui' ? '✓' : rep === 'non' ? '✕' : '·', { taille: 15, couleur, ancre: 'middle', poids: 700 })}
      </g>
    </g>`;
    if (i < 3) corps += `<path d="M${xq + l + 4} ${y + h / 2} h14" stroke="${FIL}" stroke-width="2" marker-end=""/><path d="M${xq + l + 14} ${y + h / 2 - 5} l5 5 l-5 5" fill="none" stroke="${FIL}" stroke-width="2"/>`;
  });

  // Le résultat.
  corps += `<g opacity="0">${visible(C, 0.62, 0.92)}
    <path d="M${60 + 2 * (l + 22) + l / 2} ${y + h + 4} V342" stroke="${VERT}" stroke-width="2" stroke-dasharray="4 5"/>
    <rect x="380" y="344" width="520" height="62" rx="14" fill="#10251A" stroke="${VERT}" filter="url(#halo)"/>
    <rect x="398" y="358" width="34" height="34" rx="9" fill="${VERT}" fill-opacity="0.18" stroke="${VERT}"/>
    <path d="M405 368 h4 l3 12 h12 l2 -8 h-15" fill="none" stroke="${VERT}" stroke-width="2" stroke-linejoin="round"/><circle cx="413" cy="385" r="1.8" fill="${VERT}"/><circle cx="422" cy="385" r="1.8" fill="${VERT}"/>
    ${t(446, 372, 'Courses › Supermarché', { taille: 16, couleur: TITRE, police: MONO, poids: 700 })}
    ${t(446, 393, 'Carrefour Market Vannes · essentiel · origine : dictionnaire', { taille: 12.5 })}
  </g>`;
  corps += t(640, 440, 'Corriger une catégorie écrit une règle : les prochaines opérations du même marchand la suivent, et passent avant le dictionnaire.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('classement.svg', 1280, 464, corps,
    'Comment une opération est lue. Le libellé PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09 perd son bruit : le préfixe, la carte masquée et la date sont barrés, il reste la clé du marchand CARREFOUR MARKET VANNES. Quatre questions s’enchaînent : virement interne, non ; règle apprise, non ; dictionnaire, oui ; à classer n’est pas atteint. Résultat : Courses, Supermarché, essentiel. Corriger une catégorie écrit une règle, suivie par les prochaines opérations du même marchand.');
}

// ------------------------------------------------------------------------
// 3. Virements, remboursements, espèces : ce qui ne doit pas compter deux fois.
{
  const C = 12;
  let corps = '';
  corps += t(60, 52, 'CE QUI NE DOIT PAS COMPTER', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(380, 52, 'Trois pièges d’un relevé bancaire, et comment l’application les défait.', { taille: 14 });

  // Trois colonnes.
  const col = (x, titre, accent) =>
    `<rect x="${x}" y="80" width="370" height="330" rx="16" fill="${CARTE}" stroke="${BORD}"/>
     <rect x="${x}" y="80" width="370" height="48" rx="16" fill="${accent}" fill-opacity="0.08"/>
     ${t(x + 22, 110, titre, { taille: 14, couleur: accent, police: MONO, poids: 700 })}`;

  // a. Virement interne.
  const a = 60;
  corps += col(a, 'Un virement vers le livret', INTERNE);
  corps += t(a + 22, 158, 'VIR VERS LIVRET CMB', { taille: 12.5, couleur: TITRE, police: MONO });
  corps += t(a + 22, 176, 'DE CARTE BANCAIRE', { taille: 12.5, couleur: TITRE, police: MONO });
  corps += `<rect x="${a + 22}" y="198" width="120" height="58" rx="11" fill="#0F151D" stroke="${BORD}"/>${t(a + 82, 222, 'Compte', { taille: 12, ancre: 'middle' })}${t(a + 82, 240, 'courant', { taille: 12, ancre: 'middle' })}`;
  corps += `<rect x="${a + 228}" y="198" width="120" height="58" rx="11" fill="#0F151D" stroke="${BLEU}" stroke-opacity="0.5"/>${t(a + 288, 222, 'Livret', { taille: 12, couleur: BLEU, ancre: 'middle' })}${t(a + 288, 240, 'CMB', { taille: 12, couleur: BLEU, ancre: 'middle' })}`;
  corps += fil(`M${a + 144} 227 H${a + 226}`);
  corps += `<g>${bille(`M${a + 144} 227 H${a + 226}`, 3, '0;1', '0;1', BLEU, 5)}</g>`;
  corps += `<rect x="${a + 22}" y="276" width="326" height="36" rx="9" fill="url(#hachures)" stroke="#2A3542"/>${t(a + 185, 299, 'hors budget : ni dépense, ni revenu', { taille: 12.5, couleur: INTERNE, ancre: 'middle' })}`;
  corps += `<g>${t(a + 22, 344, 'Mis de côté', { taille: 13 })}<g>${t(a + 348, 344, '+200 €', { taille: 15, couleur: VERT, police: MONO, poids: 700, ancre: 'end' })}${visible(C, 0.1, 0.95)}</g></g>`;
  corps += t(a + 22, 370, 'Budget du mois', { taille: 13 }) + t(a + 348, 370, 'inchangé', { taille: 13, couleur: TITRE, police: MONO, ancre: 'end' });
  corps += t(a + 22, 396, 'Le sens se lit dans « VERS … DE … ».', { taille: 12, couleur: DISCRET });

  // b. Remboursement lié : 500 € répartis sur deux dépenses.
  const b = 455;
  corps += col(b, 'Un chèque qui rembourse', ROSE);
  corps += `<rect x="${b + 22}" y="146" width="326" height="44" rx="10" fill="#0F151D" stroke="${ROSE}" stroke-opacity="0.5"/>${t(b + 40, 173, 'Remise de chèque', { taille: 13, couleur: TITRE })}${t(b + 330, 173, '+500 €', { taille: 14, couleur: VERT, police: MONO, poids: 700, ancre: 'end' })}`;
  const barre = (y, nom, total, reste, part, debut) => {
    const L = 326, w0 = L, w1 = Math.round((reste / total) * L);
    return `${t(b + 22, y, nom, { taille: 13, couleur: TITRE })}
      ${t(b + 348, y, '', {})}
      <text x="${b + 348}" y="${y}" font-family="${MONO}" font-size="13.5" font-weight="700" fill="${TITRE}" text-anchor="end">-${total} €${paliers('opacity', C, [[0, 1], [debut + 0.12, 0], [0.95, 1]])}</text>
      <text x="${b + 348}" y="${y}" font-family="${MONO}" font-size="13.5" font-weight="700" fill="${ROSE}" text-anchor="end" opacity="0">reste ${reste} €${paliers('opacity', C, [[0, 0], [debut + 0.12, 1], [0.95, 0]])}</text>
      <rect x="${b + 22}" y="${y + 10}" width="${L}" height="9" rx="4.5" fill="#1D2530"/>
      <rect x="${b + 22}" y="${y + 10}" width="${w0}" height="9" rx="4.5" fill="${ROSE}">${fondu('width', C, [[0, w0], [debut, w0], [debut + 0.12, w1], [0.92, w1], [1, w0]])}</rect>
      ${t(b + 22, y + 38, `${part} € du chèque`, { taille: 11.5, couleur: DISCRET })}`;
  };
  corps += barre(222, 'Billet de train', 380, 80, 300, 0.12);
  corps += barre(286, 'Restaurant', 260, 60, 200, 0.3);
  corps += fil(`M${b + 185} 190 V212`);
  corps += t(b + 22, 370, 'Revenu compté', { taille: 13 }) + `<g>${t(b + 348, 370, '0 €', { taille: 13, couleur: TITRE, police: MONO, ancre: 'end' })}</g>`;
  corps += t(b + 22, 396, 'Les dépenses ne pèsent que leur reste.', { taille: 12, couleur: DISCRET });

  // c. Espèces : retiré puis dépensé, compté une fois.
  const c = 850;
  corps += col(c, 'Des espèces', OR);
  const ligne = (y, nom, montant, couleur, de) =>
    `<g opacity="0">${visible(C, de, 0.95)}<rect x="${c + 22}" y="${y}" width="326" height="40" rx="10" fill="#0F151D" stroke="${BORD}"/>${t(c + 38, y + 25, nom, { taille: 13, couleur: TITRE })}${t(c + 332, y + 25, montant, { taille: 13.5, couleur, police: MONO, poids: 700, ancre: 'end' })}</g>`;
  corps += ligne(146, 'Retrait au distributeur', '-50 €', TITRE, 0.05);
  corps += ligne(194, 'Marché, payé en espèces', '-12 €', TITRE, 0.3);
  corps += `<g opacity="0">${visible(C, 0.5, 0.95)}${t(c + 22, 264, 'Retraits', { taille: 13 })}${t(c + 348, 264, '38 €', { taille: 13.5, couleur: OR, police: MONO, poids: 700, ancre: 'end' })}${t(c + 22, 290, 'Courses', { taille: 13 })}${t(c + 348, 290, '12 €', { taille: 13.5, couleur: VERT, police: MONO, poids: 700, ancre: 'end' })}</g>`;
  corps += `<rect x="${c + 22}" y="306" width="326" height="36" rx="9" fill="${OR}" fill-opacity="0.08" stroke="${OR}" stroke-opacity="0.35"/>`;
  corps += `<g>${t(c + 185, 329, 'Portefeuille : 50 €', { taille: 13, couleur: OR, police: MONO, poids: 700, ancre: 'middle' })}${paliers('opacity', C, [[0, 1], [0.32, 0], [0.95, 1]])}</g>`;
  corps += `<g opacity="0">${t(c + 185, 329, 'Portefeuille : 38 €', { taille: 13, couleur: OR, police: MONO, poids: 700, ancre: 'middle' })}${paliers('opacity', C, [[0, 0], [0.32, 1], [0.95, 0]])}</g>`;
  corps += t(c + 22, 370, 'Sorties du mois', { taille: 13 }) + t(c + 348, 370, '50 €, pas 62', { taille: 13, couleur: TITRE, police: MONO, ancre: 'end' });
  corps += t(c + 22, 396, 'Le même billet ne compte qu’une fois.', { taille: 12, couleur: DISCRET });

  svg('mouvements.svg', 1280, 440, corps,
    'Trois pièges d’un relevé, et comment l’application les défait. Un virement vers le livret CMB, lu dans VIR VERS LIVRET CMB DE CARTE BANCAIRE : l’argent passe du compte courant au livret, il est hors budget, compté 200 euros mis de côté, et le budget reste inchangé. Un chèque de 500 euros qui rembourse : 300 euros vont au billet de train de 380 euros, dont il reste 80, et 200 au restaurant de 260 euros, dont il reste 60 ; le chèque ne compte pas comme un revenu. Des espèces : un retrait de 50 euros, puis 12 euros au marché ; les retraits tombent à 38, les courses montent à 12, le portefeuille passe de 50 à 38 euros, et les sorties du mois restent 50 euros, pas 62.');
}

// ------------------------------------------------------------------------
// 4. Le chiffrement : une empreinte, une clé, trois usages.
{
  const C = 10;
  let corps = '';
  corps += t(60, 52, 'LE CHIFFREMENT', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(240, 52, 'L’empreinte ne déverrouille pas un écran : elle charge la clé.', { taille: 14 });
  const L = 250, H = 76;
  corps += carte(60, 172, L, H, 'Empreinte', 'local_auth', VERT, { icone: P.empreinte, allume: [0, 0.2], cycle: C });
  corps += carte(360, 172, L, H, 'Keystore', 'clé maîtresse, 32 octets', NEON, { icone: P.cle, allume: [0.12, 0.35], cycle: C });
  corps += carte(660, 90, L, H, 'HKDF-SHA256', 'smartbudget/db/v1', BLEU, { icone: P.cadenas, allume: [0.3, 0.6], cycle: C });
  corps += carte(660, 254, L, H, 'HKDF-SHA256', 'smartbudget/banque/v1', ROSE, { icone: P.cadenas, allume: [0.3, 0.6], cycle: C });
  corps += carte(960, 90, 260, H, 'SQLCipher', 'la base, tout entière', BLEU, { icone: P.base, allume: [0.45, 0.8], cycle: C });
  corps += carte(960, 254, 260, H, 'AES-GCM', 'la clé d’Enable Banking', ROSE, { icone: P.cle, allume: [0.45, 0.8], cycle: C });
  const p1 = 'M310 210 H360', p2 = 'M610 210 C635 210 635 128 660 128 M910 128 H960', p3 = 'M610 210 C635 210 635 292 660 292 M910 292 H960';
  corps += fil(p1) + fil(p2) + fil(p3);
  corps += bille('M310 210 H360 H610 C635 210 635 128 660 128 H910 H960', C, '0;0;1;1', '0;0.1;0.55;1', BLEU, 5);
  corps += bille('M310 210 H360 H610 C635 210 635 292 660 292 H910 H960', C, '0;0;1;1', '0;0.1;0.55;1', ROSE, 5);
  // La sauvegarde, qui ne dépend pas du téléphone.
  corps += `<rect x="60" y="364" width="1160" height="1" fill="${BORD}"/>`;
  corps += carte(60, 392, L, H, 'Ta phrase', 'choisie à l’export', OR, { icone: P.phrase, allume: [0.5, 0.75], cycle: C });
  corps += carte(360, 392, L, H, 'PBKDF2', '210 000 tours, sel', OR, { icone: P.cadenas, allume: [0.6, 0.85], cycle: C });
  corps += carte(660, 392, 560, H, 'smartbudget-2026-09-24.sbx', 'AES-GCM : SBEX1 · sel 16 · nonce 12 · chiffré · MAC 16, relisible ailleurs', OR, { icone: P.fichier, allume: [0.7, 0.95], cycle: C });
  corps += fil('M310 430 H360 M610 430 H660');
  corps += bille('M310 430 H660', C, '0;0;1;1', '0;0.5;0.8;1', OR, 5);
  corps += t(640, 508, 'Sans l’empreinte, la clé n’est pas en mémoire : contourner l’écran d’ouverture ne donnerait accès à rien.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('chiffrement.svg', 1280, 530, corps,
    'Le chiffrement. L’empreinte charge la clé maîtresse de 32 octets depuis le Keystore Android. HKDF-SHA256 en dérive deux clés : l’une ouvre la base SQLCipher, l’autre chiffre en AES-GCM la clé privée d’Enable Banking. À part, la sauvegarde : une phrase choisie à l’export passe par PBKDF2 en 210 000 tours, et chiffre en AES-GCM un fichier .sbx relisible sur un autre téléphone. Sans l’empreinte, la clé n’est pas en mémoire, et contourner l’écran d’ouverture ne donne accès à rien.');
}

// ------------------------------------------------------------------------
// 5. L'écran déplié : les volets glissent, le geste retour les referme.
{
  const C = 16;
  const V = 360, GAP = 1; // largeur d'un volet
  const X0 = 190, Y0 = 96, HT = 300;
  // Les cinq pages de la pile.
  const pages = [
    ['VUE D’ENSEMBLE', 'Analyse', 'anneau'],
    ['SEPTEMBRE', 'Dépenses', ['Logement', 'Courses', 'Transports', 'Restaurants']],
    ['DÉPENSES', 'Logement', ['Loyer', 'Électricité']],
    ['LOGEMENT', 'Loyer', ['Foncia Loyer']],
    ['LOYER', 'Foncia Loyer', 'operation'],
  ];
  const couleurs = [BLEU, VERT, BLEU, BLEU, BLEU];
  const volet = (i, x) => {
    const [sur, titre, contenu] = pages[i];
    let s = `<g transform="translate(${x},0)">
      <rect x="0" y="${Y0}" width="${V}" height="${HT}" fill="#111820"/>
      ${t(24, Y0 + 36, sur, { taille: 10.5, couleur: DISCRET, police: MONO, extra: 'letter-spacing="2"' })}
      ${t(24, Y0 + 66, titre, { taille: 22, couleur: TITRE, poids: 800 })}`;
    if (contenu === 'anneau') {
      const cx = V / 2, cy = Y0 + 180, r = 72;
      const arcs = [[0, 0.41, BLEU], [0.43, 0.6, VERT], [0.62, 0.72, '#B08CFF'], [0.74, 0.82, OR], [0.84, 0.9, ROSE], [0.92, 0.98, '#7FB3A0']];
      for (const [d, f, c] of arcs) {
        const a0 = d * 2 * Math.PI - Math.PI / 2, a1 = f * 2 * Math.PI - Math.PI / 2;
        const large = f - d > 0.5 ? 1 : 0;
        s += `<path d="M${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} A${r} ${r} 0 ${large} 1 ${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)}" fill="none" stroke="${c}" stroke-width="14" stroke-linecap="round"/>`;
      }
      s += t(cx, cy + 6, '1 349 €', { taille: 18, couleur: TITRE, police: MONO, poids: 700, ancre: 'middle' });
    } else if (contenu === 'operation') {
      ['Nom', 'Mouvement', 'Catégorie', 'Répétition'].forEach((n, k) => {
        s += `<rect x="20" y="${Y0 + 96 + k * 46}" width="${V - 40}" height="38" rx="9" fill="${CARTE}"/>${t(36, Y0 + 120 + k * 46, n, { taille: 12.5, couleur: TITRE })}`;
      });
    } else {
      contenu.forEach((n, k) => {
        const y = Y0 + 96 + k * 48;
        s += `<rect x="20" y="${y}" width="${V - 40}" height="40" rx="10" fill="${CARTE}"/>
          <rect x="32" y="${y + 9}" width="22" height="22" rx="6" fill="${couleurs[i]}" fill-opacity="0.25" stroke="${couleurs[i]}" stroke-opacity="0.6"/>
          ${t(66, y + 25, n, { taille: 13, couleur: TITRE })}`;
      });
    }
    return s + '</g>';
  };
  // Une bande de cinq volets qui glisse dans une fenêtre de deux.
  const pas = V + GAP;
  const positions = [0, 0, -pas, -pas, -2 * pas, -2 * pas, -3 * pas, -3 * pas, -2 * pas, -2 * pas, -pas, -pas, 0, 0];
  const instants = [0, 0.1, 0.16, 0.26, 0.32, 0.42, 0.48, 0.6, 0.66, 0.72, 0.78, 0.84, 0.9, 1];
  let bande = '';
  for (let i = 0; i < 5; i++) bande += volet(i, i * pas);
  // Les lignes surlignées, dans le volet de gauche, au moment où elles s'ouvrent.
  const surligne = (i, k, de, a) => `<rect x="${i * pas + 18}" y="${Y0 + 94 + k * 48}" width="${V - 36}" height="44" rx="11" fill="${couleurs[i]}" fill-opacity="0.10" stroke="${couleurs[i]}" stroke-opacity="0.7" opacity="0">${visible(C, de, a)}</rect>`;
  bande += surligne(1, 0, 0.12, 0.3) + surligne(2, 0, 0.28, 0.44) + surligne(3, 0, 0.44, 0.7);
  let corps = '';
  corps += t(60, 52, 'L’ÉCRAN DÉPLIÉ', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(222, 52, 'Toucher une ligne pousse tout vers la gauche. Glisser depuis le bord referme le dernier volet.', { taille: 14 });
  // Le cadre de la tablette et son rail.
  corps += `<rect x="${X0 - 104}" y="${Y0 - 14}" width="${2 * V + GAP + 118}" height="${HT + 28}" rx="24" fill="#0A0E14" stroke="#2F3A47"/>`;
  corps += `<rect x="${X0 - 90}" y="${Y0}" width="88" height="${HT}" rx="0" fill="#0F141B"/>`;
  // Les mêmes symboles que l'application, pleins pour l'onglet actif.
  const S = require('./symboles.json');
  [['home', 'Mois'], ['pie_chart', 'Analyse'], ['savings', 'Épargne'], ['settings', 'Réglages']].forEach(([s, n], k) => {
    const y = Y0 + 70 + k * 56, actif = k === 1;
    const d = S[actif ? s + '-fill' : s];
    corps += `<rect x="${X0 - 76}" y="${y - 20}" width="60" height="30" rx="15" fill="${actif ? '#FFFFFF1A' : 'none'}"/>${t(X0 - 46, y + 26, n, { taille: 10.5, couleur: actif ? TITRE : DISCRET, ancre: 'middle' })}
      <path transform="translate(${X0 - 57},${y - 16}) scale(${22 / 960}) translate(0,960)" d="${d}" fill="${actif ? TITRE : DISCRET}"/>`;
  });
  corps += `<clipPath id="fenetre"><rect x="${X0}" y="${Y0}" width="${2 * V + GAP}" height="${HT}"/></clipPath>`;
  corps += `<g clip-path="url(#fenetre)"><g transform="translate(${X0},0)">
    <g>${bande}<animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="${instants.join(';')}" values="${positions.map((p) => `${p} 0`).join(';')}" calcMode="spline" keySplines="${instants.slice(1).map(() => '0.4 0 0.2 1').join(';')}"/></g>
  </g></g>`;
  corps += `<rect x="${X0 + V}" y="${Y0}" width="${GAP}" height="${HT}" fill="${BORD}"/>`;
  // Le doigt : un toucher, puis le geste retour.
  const doigt = (x, y, de) => `<circle cx="${x}" cy="${y}" r="16" fill="${NEON}" opacity="0">${fondu('opacity', C, [[0, 0], [de, 0], [de + 0.015, 0.5], [de + 0.05, 0], [1, 0]])}${fondu('r', C, [[0, 10], [de, 10], [de + 0.05, 26], [1, 26]])}</circle>`;
  corps += doigt(X0 + V + 60, Y0 + 116, 0.1) + doigt(X0 + V + 60, Y0 + 116, 0.26) + doigt(X0 + V + 60, Y0 + 116, 0.42);
  // Le geste retour, trois fois : le même toucher vert que pour ouvrir,
  // posé au bord droit, qui file vers la gauche en laissant une traînée,
  // puis s'éteint en onde quand le doigt lâche et que le volet se referme.
  const bord = X0 + 2 * V + GAP, milieu = Y0 + HT / 2, course = 210;
  corps += `<linearGradient id="trainee" x1="0" x2="1"><stop offset="0" stop-color="${NEON}" stop-opacity="0.75"/><stop offset="1" stop-color="${NEON}" stop-opacity="0"/></linearGradient>`;
  const retour = (de) => {
    const a = de + 0.04; // le doigt lâche, le volet se referme
    const x0 = bord - 14, x1 = x0 - course;
    const glisse = (v0, v1) => `keyTimes="0;${de};${a};1" values="${v0};${v0};${v1};${v1}" calcMode="spline" keySplines="0 0 1 1;0.45 0 0.2 1;0 0 1 1"`;
    const vie = [[0, 0], [de - 0.004, 0], [de, 1], [a, 1], [a + 0.012, 0], [1, 0]];
    return `<g>
      <circle cx="${x0}" cy="${milieu}" r="10" fill="${NEON}" opacity="0">${fondu('opacity', C, [[0, 0], [de, 0], [de + 0.012, 0.5], [de + 0.04, 0], [1, 0]])}${fondu('r', C, [[0, 10], [de, 10], [de + 0.04, 28], [1, 28]])}</circle>
      <rect y="${milieu - 5}" height="10" rx="5" fill="url(#trainee)" opacity="0">${fondu('opacity', C, vie)}
        <animate attributeName="x" dur="${C}s" repeatCount="indefinite" ${glisse(x0, x1)}/>
        <animate attributeName="width" dur="${C}s" repeatCount="indefinite" ${glisse(0, course)}/></rect>
      <g filter="url(#halo)" opacity="0">${fondu('opacity', C, vie)}
        <circle cy="${milieu}" r="13" fill="${NEON}"><animate attributeName="cx" dur="${C}s" repeatCount="indefinite" ${glisse(x0, x1)}/></circle>
      </g>
      <circle cx="${x1}" cy="${milieu}" r="13" fill="none" stroke="${NEON}" stroke-width="2" opacity="0">${fondu('opacity', C, [[0, 0], [a, 0], [a + 0.003, 0.8], [a + 0.035, 0], [1, 0]])}${fondu('r', C, [[0, 13], [a, 13], [a + 0.035, 34], [1, 34]])}</circle>
    </g>`;
  };
  corps += `<g clip-path="url(#fenetre)">${retour(0.55) + retour(0.67) + retour(0.79)}</g>`;
  // La pile, à droite : chaque page ouverte s'y ajoute, chaque retour
  // retire la dernière.
  const px = 968, pl = 196, ph = 38, pas_ = 48, py = Y0 + 34;
  const nombres = [2, 2, 3, 3, 4, 4, 5, 5, 4, 4, 3, 3, 2, 2];
  corps += t(px, Y0 + 12, 'PAGES OUVERTES', { taille: 11, couleur: DISCRET, police: MONO, extra: 'letter-spacing="2"' });
  // Le fil qui relie les pages, de la plus ancienne à la plus récente.
  corps += `<line x1="${px + 14}" y1="${py + ph / 2}" x2="${px + 14}" y2="${py + ph / 2}" stroke="${FIL}" stroke-width="2">
    ${fondu('y2', C, instants.map((ins, i) => [ins, py + ph / 2 + (nombres[i] - 1) * pas_]))}</line>`;
  pages.forEach((p, k) => {
    const y = py + k * pas_;
    const op = nombres.map((n) => (k < n ? 1 : 0));
    corps += `<g>${fondu('opacity', C, instants.map((ins, i) => [ins, op[i]]))}
      <circle cx="${px + 14}" cy="${y + ph / 2}" r="5" fill="${FOND}" stroke="${couleurs[k]}" stroke-width="2"/>
      <rect x="${px + 30}" y="${y}" width="${pl - 30}" height="${ph}" rx="9" fill="${CARTE}" stroke="${BORD}"/>
      ${t(px + 44, y + 24, p[1], { taille: 13, couleur: TITRE })}
    </g>`;
  });
  corps += t(640, 440, 'Les deux dernières pages ouvertes se montrent côte à côte ; la ligne ouverte à droite reste surlignée à gauche.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('volets.svg', 1280, 462, corps,
    'L’écran déplié. Une tablette avec son rail à gauche montre deux volets côte à côte. Toucher Logement dans la liste des dépenses pousse tout vers la gauche et ouvre Logement à droite ; puis Loyer ; puis l’opération Foncia Loyer. La ligne ouverte reste surlignée dans le volet de gauche. Le geste retour, un toucher vert qui file du bord droit vers la gauche, referme les volets un à un, jusqu’à l’analyse. À droite, la liste des pages ouvertes s’allonge puis se vide.');
}

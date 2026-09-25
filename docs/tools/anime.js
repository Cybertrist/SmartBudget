// Les huit schémas animés du README.
//
// Des SVG plutôt que des GIF : quelques kilo-octets, nets à toute taille,
// et le texte reste du texte. Les animations sont en SMIL, que les
// navigateurs jouent même quand le SVG est chargé par une balise <img>,
// ce qui est le cas sur GitHub. Aucune police externe : un SVG affiché en
// <img> n'a pas le droit d'aller la chercher, on s'en tient aux familles
// du système.
//
//   node docs/tools/anime.js
//
// Il se relance ensuite avec LANGUE=en : chaque texte passe alors par
// anglais.json, et les schémas vont dans docs/en/schemas.
const fs = require('fs');
const path = require('path');

const EN = process.env.LANGUE === 'en';
const SORTIE = path.join(__dirname, '..', ...(EN ? ['en'] : []), 'schemas');
const { traduire } = require('./traduire.js');
const manque = new Set();
/// Un texte dans la langue du rendu.
const tr = (s) => (EN ? traduire(s, manque) : s);
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
  titre = tr(titre);
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
  `<text x="${x}" y="${y}" font-family="${police}" font-size="${taille}" font-weight="${poids}" fill="${couleur}" text-anchor="${ancre}" ${extra}>${esc(tr(s))}</text>`;

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
  else if (a < 1) e.push([1, 1]);
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
//
// Un diagramme d'échanges : quatre acteurs en colonnes, et chaque message
// file de l'un à l'autre, sa flèche se trace et son libellé reste. La
// colonne qui reçoit s'allume.
{
  const C = 18;
  const acteurs = [
    [160, 'Smart Budget', 'le téléphone', P.telephone, VERT],
    [480, 'Enable Banking', 'l’accès DSP2', P.nuage, BLEU],
    [800, 'Ta banque', 'tu valides', P.banque, OR],
    [1120, 'GitHub Pages', 'la page de retour', P.page, ROSE],
  ];
  // [de, vers, libellé] ; de === vers : une étape sur place.
  const messages = [
    [0, 1, 'POST /auth : un JWT signé en RS256, et un état tiré au hasard'],
    [1, 2, 'ouvre la page de la banque'],
    [2, 2, 'tu valides par Safetrans'],
    [2, 3, 'revient avec ?code=…&state=…'],
    [3, 0, 'rend la main : smartbudget://banque'],
    [0, 0, 'l’état est le même qu’au départ ✓'],
    [0, 1, 'POST /sessions : échange le code'],
    [1, 0, 'une session de 180 jours, et les comptes'],
    [0, 0, '12 mois importés, puis à chaque ouverture'],
  ];
  const Y = 196, PAS = 44, trajet = 0.05;
  const debut = (i) => 0.03 + i * 0.098;
  const fin = 0.95;
  const hL = 64, hY = 86;
  let corps = '';
  corps += t(60, 52, 'RELIER LA BANQUE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(270, 52, 'Un aller-retour, une fois tous les 180 jours. La clé privée ne quitte jamais le téléphone.', { taille: 14 });
  // Les lignes de vie, puis les en-têtes.
  const basVie = Y + (messages.length - 1) * PAS + 22;
  for (const [x, , , , c] of acteurs) {
    corps += `<line x1="${x}" y1="${hY + hL}" x2="${x}" y2="${basVie}" stroke="${c}" stroke-opacity="0.28" stroke-width="2" stroke-dasharray="3 6"/>`;
  }
  acteurs.forEach(([x, titre, sous, icone, c], k) => {
    const l = 236, x0 = x - l / 2;
    corps += `<rect x="${x0}" y="${hY}" width="${l}" height="${hL}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x0}" y="${hY + 12}" width="3" height="${hL - 24}" rx="1.5" fill="${c}"/>
      <g transform="translate(${x0 + 18},${hY + hL / 2 - 14})">${icone(c)}</g>
      ${t(x0 + 58, hY + 29, titre, { taille: 14.5, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(x0 + 58, hY + 48, sous, { taille: 12.5 })}`;
    // Elle s'allume à chaque message qu'elle reçoit.
    messages.forEach(([, vers], i) => {
      if (vers !== k) return;
      const a = debut(i) + trajet;
      corps += `<rect x="${x0}" y="${hY}" width="${l}" height="${hL}" rx="13" fill="none" stroke="${c}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, a, a + 0.07)}</rect>`;
    });
  });
  // Les messages.
  messages.forEach(([de, vers, libelle], i) => {
    const y = Y + i * PAS, s = debut(i), c = acteurs[de][4];
    const xa = acteurs[de][0], xb = acteurs[vers][0];
    if (de === vers) {
      // Une pastille accrochée à sa colonne, qui s'ouvre vers la droite.
      const l = tr(libelle).length * 6.9 + 36, x0 = xa - 14;
      corps += `<g opacity="0">${visible(C, s, fin)}
        <rect x="${x0}" y="${y - 14}" width="${l}" height="28" rx="14" fill="${FOND}"/>
        <rect x="${x0}" y="${y - 14}" width="${l}" height="28" rx="14" fill="${c}" fill-opacity="0.14" stroke="${c}" stroke-opacity="0.8"/>
        <circle cx="${xa}" cy="${y}" r="4" fill="${c}"/>
        ${t(x0 + 26, y + 4.5, libelle, { taille: 12.5, couleur: TITRE })}
      </g>`;
      return;
    }
    const sens = xb > xa ? 1 : -1;
    const x1 = xa + sens * 8, x2 = xb - sens * 10, long = Math.abs(x2 - x1);
    corps += `<g opacity="0">${visible(C, s, fin)}
      <line x1="${x1}" y1="${y}" x2="${x2}" y2="${y}" stroke="${c}" stroke-width="2" stroke-dasharray="${long}" stroke-dashoffset="${long}">
        ${fondu('stroke-dashoffset', C, [[0, long], [s, long], [s + trajet, 0], [1, 0]])}</line>
      <path d="M${x2 - sens * 7} ${y - 6} L${x2 + sens * 1} ${y} L${x2 - sens * 7} ${y + 6}" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" opacity="0">${visible(C, s + trajet, fin)}</path>
      <circle cx="${xa}" cy="${y}" r="4" fill="${c}"/>
      ${t((xa + xb) / 2, y - 10, libelle, { taille: 12.5, couleur: TITRE, ancre: 'middle' })}
    </g>`;
    // Le paquet qui file le long de la flèche.
    corps += `<g filter="url(#halo)" opacity="0">${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.004, 1], [s + trajet, 1], [s + trajet + 0.006, 0], [1, 0]])}
      <circle cy="${y}" r="6" fill="${c}"><animate attributeName="cx" dur="${C}s" repeatCount="indefinite" keyTimes="0;${s};${s + trajet};1" values="${x1};${x1};${x2};${x2}" calcMode="spline" keySplines="0 0 1 1;0.45 0 0.25 1;0 0 1 1"/></circle>
    </g>`;
  });
  corps += t(640, 604, 'Le jeton d’état, tiré au hasard au départ et vérifié au retour, empêche un lien fabriqué ailleurs de relier un autre compte.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('banque.svg', 1280, 630, corps,
    'Relier la banque, un échange entre quatre acteurs : Smart Budget, Enable Banking, ta banque et GitHub Pages. Smart Budget envoie à Enable Banking un JWT signé en RS256 et un état tiré au hasard ; Enable Banking ouvre la page de la banque ; tu valides par Safetrans ; la banque revient sur GitHub Pages avec un code et l’état ; la page rend la main à l’application par smartbudget://banque ; l’application vérifie que l’état est le même qu’au départ, échange le code contre une session de 180 jours et les comptes, puis importe douze mois et se synchronise à chaque ouverture.');
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
    const couleur = rep === 'oui' ? VERT : ROUGE;
    // La dernière question n'est pas posée : la carte s'éteint.
    if (rep === 'saut') {
      corps += `<g>
      <rect x="${xq}" y="${y}" width="${l}" height="${h}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      ${t(xq + 20, y + 36, titre, { taille: 15, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(xq + 20, y + 60, sous, { taille: 12.5 })}
      <rect x="${xq}" y="${y}" width="${l}" height="${h}" rx="13" fill="${FOND}" opacity="0">${fondu('opacity', C, [[0, 0], [instant, 0], [instant + 0.04, 0.6], [0.92, 0.6], [1, 0]])}</rect>
      <g opacity="0">${visible(C, instant + 0.03, 0.92)}${t(xq + l - 20, y + 35, 'pas atteint', { taille: 12, couleur: DISCRET, police: MONO, ancre: 'end' })}</g>
    </g>`;
      return;
    }
    corps += `<g>
      <rect x="${xq}" y="${y}" width="${l}" height="${h}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${xq}" y="${y}" width="${l}" height="${h}" rx="13" fill="none" stroke="${couleur}" stroke-width="1.5" opacity="0" ${rep === 'oui' ? 'filter="url(#halo)"' : ''}>${visible(C, instant, rep === 'oui' ? 0.92 : instant + 0.1)}</rect>
      ${t(xq + 20, y + 36, titre, { taille: 15, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(xq + 20, y + 60, sous, { taille: 12.5 })}
      <g opacity="0">${visible(C, instant + 0.03, 0.92)}
        <circle cx="${xq + l - 30}" cy="${y + 30}" r="13" fill="${couleur}" fill-opacity="0.15" stroke="${couleur}"/>
        ${t(xq + l - 30, y + 35, rep === 'oui' ? '✓' : '✕', { taille: 15, couleur, ancre: 'middle', poids: 700 })}
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
  corps += t(a + 22, 158, 'VIR VERS LIVRET A', { taille: 12.5, couleur: TITRE, police: MONO });
  corps += t(a + 22, 176, 'DE COMPTE COURANT', { taille: 12.5, couleur: TITRE, police: MONO });
  corps += `<rect x="${a + 22}" y="198" width="120" height="58" rx="11" fill="#0F151D" stroke="${BORD}"/>${t(a + 82, 222, 'Compte', { taille: 12, ancre: 'middle' })}${t(a + 82, 240, 'courant', { taille: 12, ancre: 'middle' })}`;
  corps += `<rect x="${a + 228}" y="198" width="120" height="58" rx="11" fill="#0F151D" stroke="${BLEU}" stroke-opacity="0.5"/>${t(a + 288, 231, 'Livret A', { taille: 12.5, couleur: BLEU, ancre: 'middle' })}`;
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
      <text x="${b + 348}" y="${y}" font-family="${MONO}" font-size="13.5" font-weight="700" fill="${TITRE}" text-anchor="end">${tr(`-${total} €`)}${paliers('opacity', C, [[0, 1], [debut + 0.12, 0], [0.95, 1]])}</text>
      <text x="${b + 348}" y="${y}" font-family="${MONO}" font-size="13.5" font-weight="700" fill="${ROSE}" text-anchor="end" opacity="0">${tr(`reste ${reste} €`)}${paliers('opacity', C, [[0, 0], [debut + 0.12, 1], [0.95, 0]])}</text>
      <rect x="${b + 22}" y="${y + 10}" width="${L}" height="9" rx="4.5" fill="#1D2530"/>
      <rect x="${b + 22}" y="${y + 10}" width="${w0}" height="9" rx="4.5" fill="${ROSE}">${fondu('width', C, [[0, w0], [debut, w0], [debut + 0.12, w1], [0.95, w1], [0.99, w0], [1, w0]])}</rect>
      <g opacity="0">${visible(C, debut + 0.02, 0.95)}${t(b + 22, y + 38, `${part} € du chèque`, { taille: 11.5, couleur: ROSE })}</g>`;
  };
  corps += barre(222, 'Billet de train', 380, 80, 300, 0.12);
  corps += barre(286, 'Restaurant', 260, 60, 200, 0.3);
  // Le chèque se partage : un fil rose vers chaque dépense qu'il rembourse.
  const branche = (y, de) => `<path d="M${b + 22} 168 H${b + 11} V${y} H${b + 20}" fill="none" stroke="${ROSE}" stroke-opacity="0.6" stroke-width="1.5" stroke-linejoin="round" opacity="0">${visible(C, de, 0.95)}</path>`;
  corps += branche(236, 0.12) + branche(300, 0.3);
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
  corps += t(c + 22, 370, 'Sorties du mois', { taille: 13 }) + `<g>${t(c + 348, 370, '50 €', { taille: 13, couleur: TITRE, police: MONO, ancre: 'end' })}${paliers('opacity', C, [[0, 1], [0.5, 0], [0.95, 1]])}</g><g opacity="0">${t(c + 348, 370, '50 €, pas 62', { taille: 13, couleur: TITRE, police: MONO, ancre: 'end' })}${paliers('opacity', C, [[0, 0], [0.5, 1], [0.95, 0]])}</g>`;
  corps += t(c + 22, 396, 'Le même billet ne compte qu’une fois.', { taille: 12, couleur: DISCRET });

  svg('mouvements.svg', 1280, 440, corps,
    'Trois pièges d’un relevé, et comment l’application les défait. Un virement vers le livret A, lu dans VIR VERS LIVRET A DE COMPTE COURANT : l’argent passe du compte courant au livret, il est hors budget, compté 200 euros mis de côté, et le budget reste inchangé. Un chèque de 500 euros qui rembourse : 300 euros vont au billet de train de 380 euros, dont il reste 80, et 200 au restaurant de 260 euros, dont il reste 60 ; le chèque ne compte pas comme un revenu. Des espèces : un retrait de 50 euros, puis 12 euros au marché ; les retraits tombent à 38, les courses montent à 12, le portefeuille passe de 50 à 38 euros, et les sorties du mois restent 50 euros, pas 62.');
}

// ------------------------------------------------------------------------
// 4. Le chiffrement : une empreinte, une clé, trois usages.
{
  const C = 10;
  let corps = '';
  corps += t(60, 52, 'LE CHIFFREMENT', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(240, 52, 'L’empreinte ne déverrouille pas un écran : elle charge la clé.', { taille: 14 });
  const L = 250, H = 76;
  // Les billes passent sous les cartes : elles ne se voient que sur les fils.
  // Verte de l'empreinte au Keystore, puis bleue et rose une fois la clé
  // dérivée ; la dorée attend son tour, cachée dans la carte de la phrase.
  corps += bille('M185 210 H485', C, '0;0;1;1', '0;0.03;0.18;1', VERT, 5);
  corps += bille('M485 210 H610 C635 210 635 128 660 128 H1090', C, '0;0;1;1', '0;0.18;0.5;1', BLEU, 5);
  corps += bille('M485 210 H610 C635 210 635 292 660 292 H1090', C, '0;0;1;1', '0;0.18;0.5;1', ROSE, 5);
  corps += bille('M185 430 H940', C, '0;0;1;1', '0;0.5;0.8;1', OR, 5);
  corps += carte(60, 172, L, H, 'Empreinte', 'local_auth', VERT, { icone: P.empreinte, allume: [0, 0.2], cycle: C });
  corps += carte(360, 172, L, H, 'Keystore', 'clé maîtresse, 32 octets', NEON, { icone: P.cle, allume: [0.12, 0.35], cycle: C });
  corps += carte(660, 90, L, H, 'HKDF-SHA256', 'smartbudget/db/v1', BLEU, { icone: P.cadenas, allume: [0.3, 0.6], cycle: C });
  corps += carte(660, 254, L, H, 'HKDF-SHA256', 'smartbudget/banque/v1', ROSE, { icone: P.cadenas, allume: [0.3, 0.6], cycle: C });
  corps += carte(960, 90, 260, H, 'SQLCipher', 'la base, tout entière', BLEU, { icone: P.base, allume: [0.45, 0.8], cycle: C });
  corps += carte(960, 254, 260, H, 'AES-GCM', 'la clé d’Enable Banking', ROSE, { icone: P.cle, allume: [0.45, 0.8], cycle: C });
  const p1 = 'M310 210 H360', p2 = 'M610 210 C635 210 635 128 660 128 M910 128 H960', p3 = 'M610 210 C635 210 635 292 660 292 M910 292 H960';
  corps += fil(p1) + fil(p2) + fil(p3);
  // La sauvegarde, qui ne dépend pas du téléphone.
  corps += `<rect x="60" y="364" width="1160" height="1" fill="${BORD}"/>`;
  corps += carte(60, 392, L, H, 'Ta phrase', 'choisie à l’export', OR, { icone: P.phrase, allume: [0.5, 0.75], cycle: C });
  corps += carte(360, 392, L, H, 'PBKDF2', '210 000 tours, sel', OR, { icone: P.cadenas, allume: [0.6, 0.85], cycle: C });
  corps += carte(660, 392, 560, H, 'smartbudget-2026-09-24.sbx', 'AES-GCM : SBEX1 · sel 16 · nonce 12 · chiffré · MAC 16, relisible ailleurs', OR, { icone: P.fichier, allume: [0.7, 0.95], cycle: C });
  corps += fil('M310 430 H360 M610 430 H660');
  corps += t(640, 508, 'Hors de la veille du solde, toutes les six heures, la clé n’entre en mémoire qu’après l’empreinte.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('chiffrement.svg', 1280, 530, corps,
    'Le chiffrement. L’empreinte charge la clé maîtresse de 32 octets depuis le Keystore Android. HKDF-SHA256 en dérive deux clés : l’une ouvre la base SQLCipher, l’autre chiffre en AES-GCM la clé privée d’Enable Banking. À part, la sauvegarde : une phrase choisie à l’export passe par PBKDF2 en 210 000 tours, et chiffre en AES-GCM un fichier .sbx relisible sur un autre téléphone. Hors de la veille du solde, qui la charge toutes les six heures le temps de lire le solde, la clé n’entre en mémoire qu’après l’empreinte.');
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

// ------------------------------------------------------------------------
// 6. La veille du solde : une lecture toutes les six heures, une seule
// alerte par passage en négatif.
{
  const C = 16;
  let corps = '';
  corps += t(60, 52, 'LA VEILLE DU SOLDE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(262, 52, 'Toutes les six heures, même application fermée. Une seule alerte par passage en négatif.', { taille: 14 });

  // Huit lectures, sur deux jours : le solde passe sous zéro à la
  // quatrième, y reste deux lectures, puis remonte.
  const lectures = [
    ['lun. 6 h', 32000, '06:02'],
    ['12 h', 18000, '12:05'],
    ['18 h', 6000, '18:01'],
    ['mar. 0 h', -4210, '00:04'],
    ['6 h', -8500, '06:03'],
    ['12 h', -2000, '12:02'],
    ['18 h', 15000, '18:04'],
    ['mer. 0 h', 9000, '00:01'],
  ];
  const etats = ['lu', 'lu', 'lu', 'alerte', 'déjà prévenu', 'déjà prévenu', 'réarmée', 'lu'];
  const couleurEtat = { lu: DISCRET, alerte: ROUGE, 'déjà prévenu': DISCRET, réarmée: VERT };
  const instant = (i) => 0.06 + i * 0.105;
  const fin = 0.95;
  const X = (i) => 130 + i * 94;
  const ZERO = 298;
  const Y = (c) => ZERO - c * 0.0043;
  // « 320 € », « -42,10 € » : les centimes seulement quand il y en a.
  const montant = (c) => {
    const e = Math.trunc(Math.abs(c) / 100), ct = Math.abs(c) % 100;
    return `${c < 0 ? '-' : ''}${e}${ct ? ',' + String(ct).padStart(2, '0') : ''} €`;
  };

  // Le cadre du graphique.
  corps += `<rect x="60" y="80" width="800" height="352" rx="16" fill="${CARTE}" stroke="${BORD}"/>`;
  corps += t(84, 110, 'Solde du compte courant', { taille: 12, couleur: DISCRET, police: MONO, extra: 'letter-spacing="1.5"' });
  corps += `<line x1="100" y1="${ZERO}" x2="830" y2="${ZERO}" stroke="${FIL}" stroke-width="1.5" stroke-dasharray="5 6"/>`;
  corps += t(826, ZERO - 8, '0 €', { taille: 11.5, couleur: DISCRET, police: MONO, ancre: 'end' });

  // La courbe se trace lecture après lecture : verte au-dessus de zéro,
  // rouge en dessous, par deux découpes de la même ligne.
  const pts = lectures.map(([, c], i) => [X(i), Y(c)]);
  const d = 'M' + pts.map((p) => p.join(' ')).join(' L');
  const longueurs = [0];
  for (let i = 1; i < pts.length; i++) {
    longueurs.push(longueurs[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
  }
  const L = Math.ceil(longueurs.at(-1));
  const trace = [[0, L], ...lectures.map((_, i) => [instant(i), L - longueurs[i]]), [fin, 0], [0.98, L], [1, L]];
  corps += `<clipPath id="dessus"><rect x="60" y="80" width="800" height="${ZERO - 80}"/></clipPath>`;
  corps += `<clipPath id="dessous"><rect x="60" y="${ZERO}" width="800" height="${432 - ZERO}"/></clipPath>`;
  for (const [clip, couleur] of [['dessus', VERT], ['dessous', ROUGE]]) {
    corps += `<path d="${d}" fill="none" stroke="${couleur}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"
      clip-path="url(#${clip})" stroke-dasharray="${L}" stroke-dashoffset="${L}">${fondu('stroke-dashoffset', C, trace)}</path>`;
  }

  // Chaque lecture : une onde au point, le montant, l'heure, et ce qu'en
  // fait la veille.
  lectures.forEach(([heure, c], i) => {
    const [x, y] = pts[i];
    const s = instant(i);
    const coul = c < 0 ? ROUGE : VERT;
    corps += t(x, 386, heure, { taille: 11.5, couleur: DISCRET, police: MONO, ancre: 'middle' });
    corps += `<circle cx="${x}" cy="${y}" r="6" fill="${coul}" opacity="0">${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.012, 0.6], [s + 0.045, 0], [1, 0]])}${fondu('r', C, [[0, 6], [s, 6], [s + 0.045, 24], [1, 24]])}</circle>`;
    corps += `<g opacity="0">${visible(C, s, fin)}
      <circle cx="${x}" cy="${y}" r="5" fill="${FOND}" stroke="${coul}" stroke-width="2.5"/>
      ${t(x, c < 0 ? y + 24 : y - 14, montant(c), { taille: 12, couleur: TITRE, police: MONO, poids: 700, ancre: 'middle' })}
      ${t(x, 412, etats[i], { taille: 11.5, couleur: couleurEtat[etats[i]], police: MONO, poids: etats[i] === 'lu' ? 400 : 700, ancre: 'middle' })}
    </g>`;
  });

  // Le téléphone verrouillé : l'heure de la dernière lecture, et la
  // notification qui descend à la première lecture en négatif.
  const px = 900, pw = 320;
  corps += `<rect x="${px}" y="80" width="${pw}" height="352" rx="34" fill="#0A0E14" stroke="#2F3A47" stroke-width="1.5"/>`;
  corps += `<rect x="${px + 10}" y="90" width="${pw - 20}" height="332" rx="26" fill="#0E141C"/>`;
  corps += `<rect x="${px + pw / 2 - 30}" y="98" width="60" height="7" rx="3.5" fill="#1B232E"/>`;
  lectures.forEach(([, , heure], i) => {
    const de = i === 0 ? 0 : instant(i);
    const a = i === lectures.length - 1 ? 1 : instant(i + 1);
    corps += `<g opacity="${i === 0 ? 1 : 0}">${paliers('opacity', C, [[0, i === 0 ? 1 : 0], ...(i === 0 ? [] : [[de, 1]]), ...(a < 1 ? [[a, 0]] : [])])}
      ${t(px + pw / 2, 172, heure, { taille: 44, couleur: TITRE, poids: 300, ancre: 'middle' })}</g>`;
  });
  corps += t(px + pw / 2, 198, 'Écran verrouillé', { taille: 12, couleur: DISCRET, ancre: 'middle' });
  const s = instant(3);
  corps += `<g opacity="0">
    ${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.02, 1], [fin, 1], [0.98, 0], [1, 0]])}
    <animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite"
      keyTimes="0;${s};${s + 0.03};1" values="0 -30;0 -30;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.3 0 0.2 1;0 0 1 1"/>
    <rect x="${px + 20}" y="222" width="${pw - 40}" height="78" rx="18" fill="#1A2230" stroke="${ROUGE}" stroke-opacity="0.45"/>
    <circle cx="${px + 46}" cy="248" r="13" fill="${ROUGE}" fill-opacity="0.18" stroke="${ROUGE}"/>
    <path d="M${px + 40} 254 v-4 M${px + 46} 254 v-9 M${px + 52} 254 v-13" stroke="${ROUGE}" stroke-width="3" stroke-linecap="round"/>
    ${t(px + 68, 244, 'Smart Budget · maintenant', { taille: 10.5, couleur: DISCRET })}
    ${t(px + 68, 262, 'Compte courant en négatif', { taille: 13, couleur: TITRE, poids: 700 })}
    ${t(px + 68, 282, `Ton compte courant est à ${montant(-4210)}.`, { taille: 12, couleur: TEXTE })}
  </g>`;
  // Au retour au-dessus de zéro, l'alerte se réarme.
  const r = instant(6);
  corps += `<g opacity="0">${visible(C, r, fin)}
    <rect x="${px + 60}" y="330" width="${pw - 120}" height="30" rx="15" fill="${VERT}" fill-opacity="0.12" stroke="${VERT}" stroke-opacity="0.6"/>
    ${t(px + pw / 2, 350, 'alerte réarmée', { taille: 12, couleur: VERT, police: MONO, poids: 700, ancre: 'middle' })}
  </g>`;

  corps += t(640, 458, 'Quatre lectures par jour au plus : la limite que la DSP2 accorde aux accès faits sans toi.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('alerte.svg', 1280, 480, corps,
    'La veille du solde. Toutes les six heures, même application fermée, le solde du compte courant est relu. Sur deux jours, huit lectures : 320, 180 et 60 euros, puis -42,10 euros à minuit, et le téléphone verrouillé reçoit la notification Compte courant en négatif, Ton compte courant est à -42,10 euros. Aux deux lectures suivantes, -85 et -20 euros, pas de nouvelle alerte : déjà prévenu. À 150 euros, l’alerte se réarme. Quatre lectures par jour au plus, la limite de la DSP2 pour les accès faits sans l’utilisateur.');
}

// ------------------------------------------------------------------------
// Outils partagés par les deux schémas du choix de la banque : un toucher
// du doigt, un texte qui se tape, les couleurs de l'application.
const APP = { fond: '#121212', carte: '#1C1C1C', trait: '#2A2A2A', texte: '#FFFFFF', second: '#B3B3B3', discret: '#7A7A7A' };

/// Un toucher : le doigt se pose, une onde s'ouvre.
function toucher(cx, cy, cycle, a) {
  return `<g opacity="0">${visible(cycle, a - 0.018, a + 0.012, 0.004)}
    <circle cx="${cx}" cy="${cy}" r="13" fill="#FFFFFF" fill-opacity="0.28" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="1.5"/>
  </g>
  <circle cx="${cx}" cy="${cy}" r="10" fill="none" stroke="#FFFFFF" stroke-width="2" opacity="0">
    ${fondu('opacity', cycle, [[0, 0], [a, 0], [a + 0.002, 0.8], [a + 0.035, 0], [1, 0]])}
    ${fondu('r', cycle, [[0, 10], [a, 10], [a + 0.035, 30], [1, 30]])}
  </circle>`;
}

let _frappes = 0;
/// Un texte qui se tape lettre à lettre, de [de] à [a].
function frappe(x, y, s, cycle, de, a, opts = {}) {
  const id = `frappe${_frappes++}`;
  const l = tr(s).length * (opts.taille || 14) * 0.62 + 6;
  return `<clipPath id="${id}"><rect x="${x - 2}" y="${y - 20}" height="28" width="0">
    ${fondu('width', cycle, [[0, 0], [de, 0], [a, l], [1, l]])}</rect></clipPath>
  <g clip-path="url(#${id})">${t(x, y, s, opts)}</g>`;
}

/// Un bouton en pilule.
const pilule = (x, y, l, h, texte, couleur, { plein = false, taille = 12.5 } = {}) =>
  `<rect x="${x}" y="${y}" width="${l}" height="${h}" rx="${h / 2}" fill="${plein ? couleur : couleur}" fill-opacity="${plein ? 1 : 0.1}" stroke="${couleur}" stroke-opacity="${plein ? 1 : 0.45}"/>
  ${t(x + l / 2, y + h / 2 + taille * 0.36, texte, { taille, couleur: plein ? '#000000' : couleur, poids: 800, ancre: 'middle' })}`;

/// Une pastille de banque : ses initiales dans un rond de couleur.
const pastille = (x, y, initiales, couleur) =>
  `<circle cx="${x}" cy="${y}" r="15" fill="${couleur}" fill-opacity="0.16" stroke="${couleur}" stroke-opacity="0.6"/>
  ${t(x, y + 4.5, initiales, { taille: 11, couleur, poids: 800, ancre: 'middle' })}`;

// ------------------------------------------------------------------------
// 7. Choisir et relier sa banque : le parcours dans l'application.
//
// À gauche, le téléphone passe d'écran en écran et le doigt touche ce
// qu'il faut toucher ; à droite, les cinq étapes s'allument tour à tour.
{
  const C = 32, N = 5;
  const de = (k) => k / N + 0.004, a = (k) => (k + 1) / N - 0.004;
  const dans = (k, f) => k / N + f / N;
  const PX = 80, PY = 112, PL = 304, PH = 612;
  const SX = PX + 12, SY = PY + 16, SL = PL - 24, SH = PH - 32;
  let corps = '';
  corps += t(60, 52, 'CHOISIR ET RELIER SA BANQUE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(360, 52, 'Tout part des réglages. Une dizaine de minutes la première fois, puis plus rien à faire pendant 180 jours.', { taille: 14 });

  // Le téléphone.
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="40" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranParcours"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 34}" y="${PY + 6}" width="68" height="5" rx="2.5" fill="#1B222C"/>`;
  let ecrans = '';
  const titre = (s) => t(SX + 18, SY + 54, s, { taille: 22, couleur: APP.texte, poids: 800 });
  const carteApp = (y, h) => `<rect x="${SX + 12}" y="${y}" width="${SL - 24}" height="${h}" rx="16" fill="${APP.carte}"/>`;
  const message = (s, k, f1, f2) => `<g opacity="0">${visible(C, dans(k, f1), dans(k, f2), 0.004)}
      <rect x="${SX + 10}" y="${SY + SH - 70}" width="${SL - 20}" height="44" rx="10" fill="#2E2E2E"/>
      ${t(SX + 24, SY + SH - 43, s, { taille: 12, couleur: APP.texte })}</g>`;

  // 1. Les réglages : la carte de la banque, encore vide.
  ecrans += `<g opacity="0">${visible(C, de(0), a(0), 0.004)}
    ${titre('Réglages')}
    ${carteApp(SY + 76, 164)}
    <rect x="${SX + 28}" y="${SY + 94}" width="40" height="40" rx="12" fill="${VERT}" fill-opacity="0.14" stroke="${VERT}" stroke-opacity="0.5"/>
    <g transform="translate(${SX + 34},${SY + 100})">${P.banque(VERT)}</g>
    ${t(SX + 80, SY + 110, 'Ta banque', { taille: 15, couleur: APP.texte, poids: 800 })}
    ${t(SX + 80, SY + 128, 'Choisis ta banque, puis', { taille: 11.5, couleur: APP.second })}
    ${t(SX + 80, SY + 144, 'SmartBudget te guide pour la relier.', { taille: 11.5, couleur: APP.second })}
    ${pilule(SX + 28, SY + 170, 170, 40, 'Choisir la banque', VERT)}
    ${carteApp(SY + 256, 170)}
    ${t(SX + 30, SY + 286, 'BUDGET', { taille: 11, couleur: APP.second, poids: 700, extra: 'letter-spacing="2"' })}
    ${['Budget mensuel', 'Objectif d’épargne', 'Le mois commence le'].map((s, i) =>
      `<line x1="${SX + 28}" y1="${SY + 300 + i * 40}" x2="${SX + SL - 28}" y2="${SY + 300 + i * 40}" stroke="${APP.trait}"/>
      ${t(SX + 30, SY + 326 + i * 40, s, { taille: 13, couleur: APP.texte, poids: 600 })}`).join('')}
    ${toucher(SX + 113, SY + 190, C, dans(0, 0.7))}
  </g>`;

  // 2. La liste des banques : la recherche filtre, le doigt choisit.
  const banques = [['BNP Paribas', 'BP', '#1ED760'], ['Crédit Agricole', 'CA', '#3CE0FF'], ['Crédit Mutuel de Bretagne', 'CM', '#FFC857'], ['La Banque Postale', 'LB', '#FFC857'], ['Société Générale', 'SG', '#FF6B7A'], ['Boursorama', 'BO', '#FF8FD1']];
  const ligneBanque = (y, [nom, ini, c], clair = false) => `
    ${clair ? `<rect x="${SX + 16}" y="${y - 24}" width="${SL - 32}" height="48" rx="12" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.5"/>` : ''}
    ${pastille(SX + 42, y, ini, c)}
    ${t(SX + 68, y - 2, nom, { taille: 13, couleur: APP.texte, poids: 700 })}
    ${t(SX + 68, y + 15, 'France', { taille: 11, couleur: APP.discret })}`;
  const bascule = dans(1, 0.45);
  ecrans += `<g opacity="0">${visible(C, de(1), a(1), 0.004)}
    ${t(SX + 18, SY + 54, '‹', { taille: 24, couleur: APP.texte })}
    ${t(SX + 38, SY + 54, 'Ta banque', { taille: 20, couleur: APP.texte, poids: 800 })}
    ${t(SX + 18, SY + 80, 'Celles de ton pays en tête, puis de A à Z.', { taille: 11.5, couleur: APP.second })}
    <rect x="${SX + 14}" y="${SY + 96}" width="${SL - 28}" height="42" rx="21" fill="${APP.carte}"/>
    <circle cx="${SX + 36}" cy="${SY + 115}" r="6" fill="none" stroke="${APP.second}" stroke-width="2"/><path d="M${SX + 40} ${SY + 119} l5 5" stroke="${APP.second}" stroke-width="2" stroke-linecap="round"/>
    <g opacity="0">${visible(C, de(1), dans(1, 0.15), 0.004)}${t(SX + 54, SY + 122, 'Nom de la banque, ou pays', { taille: 12.5, couleur: APP.discret })}</g>
    ${frappe(SX + 54, SY + 122, 'mutuel bretagne', C, dans(1, 0.15), dans(1, 0.42), { taille: 13, couleur: APP.texte })}
    <g opacity="0">${visible(C, de(1), bascule, 0.004)}
      ${t(SX + 22, SY + 168, 'LES GRANDES BANQUES · FRANCE', { taille: 10.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.5"' })}
      ${banques.map((b, i) => ligneBanque(SY + 200 + i * 54, b)).join('')}
    </g>
    <g opacity="0">${visible(C, bascule, a(1), 0.004)}
      ${t(SX + 22, SY + 168, 'TOUTES LES BANQUES, DE A À Z', { taille: 10.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.5"' })}
      <g>${ligneBanque(SY + 200, banques[2])}
        <rect x="${SX + 16}" y="${SY + 176}" width="${SL - 32}" height="48" rx="12" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.6" opacity="0">${visible(C, dans(1, 0.72), a(1), 0.004)}</rect>
      </g>
    </g>
    ${toucher(SX + 150, SY + 200, C, dans(1, 0.7))}
  </g>`;

  // 3. Le guide : le portail s'ouvre, les valeurs se copient.
  const etapeGuide = (y, n, titreEtape, lignes, h) => `
    ${carteApp(y, h)}
    <circle cx="${SX + 38}" cy="${y + 26}" r="12" fill="${VERT}" fill-opacity="0.14"/>
    ${t(SX + 38, y + 30.5, n, { taille: 12, couleur: VERT, poids: 800, ancre: 'middle' })}
    ${t(SX + 58, y + 31, titreEtape, { taille: 13.5, couleur: APP.texte, poids: 800 })}
    ${lignes.map((s, i) => t(SX + 58, y + 50 + i * 16, s, { taille: 11, couleur: APP.second })).join('')}`;
  ecrans += `<g opacity="0">${visible(C, de(2), a(2), 0.004)}
    ${t(SX + 18, SY + 54, '‹', { taille: 24, couleur: APP.texte })}
    ${t(SX + 38, SY + 54, 'Obtenir ta clé', { taille: 20, couleur: APP.texte, poids: 800 })}
    ${etapeGuide(SY + 72, '1', 'Se connecter au portail', ['Ton adresse e-mail, puis le lien reçu.'], 104)}
    ${pilule(SX + 58, SY + 136, 150, 30, 'Ouvrir le portail ↗', VERT, { taille: 11.5 })}
    ${etapeGuide(SY + 186, '2', 'Créer l’application', ['Production · SmartBudget'], 72)}
    ${carteApp(SY + 268, 108)}
    ${t(SX + 30, SY + 294, 'À COLLER DANS LE FORMULAIRE', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.2"' })}
    ${t(SX + 30, SY + 318, 'Allowed redirect URLs', { taille: 10.5, couleur: APP.discret, poids: 700 })}
    ${t(SX + 30, SY + 336, 'cybertrist.github.io/SmartBudget/', { taille: 11.5, couleur: APP.texte })}
    ${t(SX + SL - 30, SY + 330, 'Copier', { taille: 12, couleur: VERT, poids: 800, ancre: 'end' })}
    ${t(SX + 30, SY + 362, 'Description, Privacy URL, Terms URL…', { taille: 10.5, couleur: APP.discret })}
    ${etapeGuide(SY + 386, '3', 'Relier ton compte', ['« Activate by linking accounts »'], 72)}
    ${toucher(SX + 133, SY + 151, C, dans(2, 0.28))}
    ${toucher(SX + SL - 50, SY + 326, C, dans(2, 0.62))}
    ${message('Allowed redirect URLs copié.', 2, 0.64, 0.92)}
  </g>`;

  // 4. L'import de la clé : le fichier .pem téléchargé par le portail.
  ecrans += `<g opacity="0">${visible(C, de(3), a(3), 0.004)}
    ${t(SX + 18, SY + 54, '‹', { taille: 24, couleur: APP.texte })}
    ${t(SX + 38, SY + 54, 'Obtenir ta clé', { taille: 20, couleur: APP.texte, poids: 800 })}
    ${etapeGuide(SY + 72, '4', 'Importer la clé ici', ['Le fichier .pem téléchargé,', 'sans le renommer : son nom est', 'l’identifiant de ton application.'], 172)}
    <rect x="${SX + 28}" y="${SY + 188}" width="${SL - 56}" height="42" rx="21" fill="${VERT}"/>
    <g transform="translate(${SX + 62},${SY + 195})">${P.cle('#000000')}</g>
    ${t(SX + SL / 2 + 14, SY + 214, 'Importer la clé', { taille: 13.5, couleur: '#000000', poids: 800, ancre: 'middle' })}
    ${toucher(SX + SL / 2, SY + 209, C, dans(3, 0.2))}
    <g opacity="0">${visible(C, dans(3, 0.27), dans(3, 0.62), 0.004)}
      <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000000" fill-opacity="0.6"/>
      <rect x="${SX + 14}" y="${SY + 150}" width="${SL - 28}" height="220" rx="18" fill="#242424"/>
      ${t(SX + 34, SY + 186, 'Téléchargements', { taille: 15, couleur: APP.texte, poids: 800 })}
      ${[['a3f9c2e1-7b4d-….pem', true], ['releve-aout.pdf', false], ['billet-train.pdf', false]].map(([nom, cle], i) => `
        <g transform="translate(${SX + 32},${SY + 206 + i * 50})">${(cle ? P.cle : P.fichier)(cle ? OR : APP.discret)}</g>
        ${t(SX + 72, SY + 225 + i * 50, nom, { taille: 12.5, couleur: cle ? APP.texte : APP.discret, poids: cle ? 700 : 400, police: cle ? MONO : SANS })}`).join('')}
      ${toucher(SX + 140, SY + 220, C, dans(3, 0.5))}
    </g>
    <g opacity="0">${visible(C, dans(3, 0.64), a(3), 0.004)}
      <rect x="${SX + 12}" y="${SY + 262}" width="${SL - 24}" height="120" rx="16" fill="${VERT}" fill-opacity="0.08" stroke="${VERT}" stroke-opacity="0.45"/>
      <circle cx="${SX + 48}" cy="${SY + 300}" r="15" fill="${VERT}"/>
      <path d="M${SX + 41} ${SY + 300} l5 5 l9 -10" fill="none" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
      ${t(SX + 74, SY + 296, 'Clé importée', { taille: 14, couleur: APP.texte, poids: 800 })}
      ${t(SX + 74, SY + 314, 'Chiffrée aussitôt, copie effacée.', { taille: 11.5, couleur: APP.second })}
      ${t(SX + 30, SY + 358, 'La liaison du compte s’enchaîne…', { taille: 12, couleur: VERT, poids: 700 })}
    </g>
  </g>`;

  // 5. La banque, puis le retour : relié, synchronisé.
  const retour = dans(4, 0.5);
  ecrans += `<g opacity="0">${visible(C, de(4), retour, 0.004)}
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#F4F1EA"/>
    <rect x="${SX}" y="${SY}" width="${SL}" height="86" fill="#1F3B73"/>
    ${t(SX + 20, SY + 50, 'Crédit Mutuel de Bretagne', { taille: 15, couleur: '#FFFFFF', poids: 800 })}
    ${t(SX + 20, SY + 70, 'Espace client', { taille: 11, couleur: '#C9D4EA' })}
    ${t(SX + 20, SY + 130, 'Enable Banking demande', { taille: 15, couleur: '#1A1A1A', poids: 800 })}
    ${t(SX + 20, SY + 150, 'à consulter ton compte courant.', { taille: 15, couleur: '#1A1A1A', poids: 800 })}
    ${t(SX + 20, SY + 180, 'Lecture seule, pendant 180 jours.', { taille: 12, couleur: '#555555' })}
    <rect x="${SX + 20}" y="${SY + 206}" width="${SL - 40}" height="96" rx="12" fill="#FFFFFF" stroke="#DDD6C8"/>
    <g transform="translate(${SX + 36},${SY + 238})">${P.telephone('#1F3B73')}</g>
    ${t(SX + 76, SY + 246, 'Valide sur ton téléphone', { taille: 12.5, couleur: '#1A1A1A', poids: 700 })}
    ${t(SX + 76, SY + 264, 'comme d’habitude (Safetrans).', { taille: 11.5, couleur: '#555555' })}
    <rect x="${SX + 20}" y="${SY + 330}" width="${SL - 40}" height="44" rx="22" fill="#1F3B73"/>
    ${t(SX + SL / 2, SY + 357, 'Valider', { taille: 14, couleur: '#FFFFFF', poids: 800, ancre: 'middle' })}
    ${toucher(SX + SL / 2, SY + 352, C, dans(4, 0.36))}
  </g>
  <g opacity="0">${visible(C, retour, a(4), 0.004)}
    ${titre('Réglages')}
    ${carteApp(SY + 76, 168)}
    <rect x="${SX + 28}" y="${SY + 94}" width="40" height="40" rx="12" fill="${VERT}" fill-opacity="0.14" stroke="${VERT}" stroke-opacity="0.5"/>
    <g transform="translate(${SX + 34},${SY + 100})">${P.banque(VERT)}</g>
    ${t(SX + 80, SY + 110, 'Crédit Mutuel de Bretagne', { taille: 13.5, couleur: APP.texte, poids: 800 })}
    ${t(SX + 80, SY + 128, 'Synchronisé aujourd’hui', { taille: 11.5, couleur: VERT })}
    ${t(SX + 80, SY + 144, 'accès encore 180 jours', { taille: 11.5, couleur: VERT })}
    ${pilule(SX + 28, SY + 172, 128, 38, 'Synchroniser', VERT)}
    ${pilule(SX + 166, SY + 172, 86, 38, 'Délier', APP.second)}
    ${message('312 nouvelles opérations.', 4, 0.62, 0.99)}
  </g>`;
  corps += `<g clip-path="url(#ecranParcours)">${ecrans}</g>`;

  // Les cinq étapes, à droite.
  const etapes = [
    ['Choisir la banque', ['Réglages, carte « Ta banque », Choisir la banque.', 'Toutes celles d’Enable Banking, dans une trentaine de pays.']],
    ['Chercher la sienne', ['Par son nom ou son pays, puis la toucher.', 'Une ligne par banque : rien à déplier.']],
    ['Suivre le guide du portail', ['Le portail d’Enable Banking s’ouvre dans le navigateur.', 'Chaque valeur à coller a son bouton Copier (schéma suivant).']],
    ['Importer la clé', ['Le fichier .pem que le portail vient de télécharger,', 'sans le renommer. Chiffré aussitôt, la copie effacée.']],
    ['Relier le compte', ['La page de ta banque s’ouvre : tu valides comme d’habitude.', 'Douze mois importés, puis une synchro à chaque ouverture.']],
  ];
  const EX = 470, EY = 150, PAS = 112;
  corps += `<line x1="${EX + 22}" y1="${EY}" x2="${EX + 22}" y2="${EY + PAS * (N - 1)}" stroke="${FIL}" stroke-width="2"/>`;
  corps += `<line x1="${EX + 22}" y1="${EY}" x2="${EX + 22}" y2="${EY}" stroke="${VERT}" stroke-width="2">
    ${fondu('y2', C, [[0, EY], ...etapes.map((_, k) => [(k + 1) / N - 0.01, EY + PAS * k]), [1, EY + PAS * (N - 1)]])}</line>`;
  etapes.forEach(([titreEtape, lignes], k) => {
    const y = EY + k * PAS;
    corps += `<rect x="${EX - 14}" y="${y - 38}" width="${1220 - EX + 14}" height="${PAS - 16}" rx="14" fill="${CARTE}" stroke="${VERT}" stroke-opacity="0.5" opacity="0">${visible(C, de(k), a(k), 0.006)}</rect>
      <circle cx="${EX + 22}" cy="${y}" r="20" fill="${FOND}" stroke="${FIL}" stroke-width="2"/>
      <circle cx="${EX + 22}" cy="${y}" r="20" fill="${VERT}" opacity="0" filter="url(#halo)">${visible(C, de(k), 0.996, 0.006)}</circle>
      ${t(EX + 22, y + 6, String(k + 1), { taille: 16, couleur: TEXTE, police: MONO, poids: 700, ancre: 'middle' })}
      <g opacity="0">${visible(C, de(k), 0.996, 0.006)}${t(EX + 22, y + 6, String(k + 1), { taille: 16, couleur: '#000000', police: MONO, poids: 800, ancre: 'middle' })}</g>
      ${t(EX + 62, y - 6, titreEtape, { taille: 18, couleur: TITRE, poids: 700 })}
      ${lignes.map((s, i) => t(EX + 62, y + 16 + i * 19, s, { taille: 13.5 })).join('')}`;
  });
  corps += t(EX - 14, 712, 'Les étapes 3 et 4 ne se font qu’une fois : la clé reste dans le téléphone, chiffrée.', { taille: 13, couleur: DISCRET });
  svg('parcours-banque.svg', 1280, 760, corps,
    'Choisir et relier sa banque, en cinq étapes, sur un téléphone animé. 1, dans les réglages, la carte Ta banque, toucher Choisir la banque. 2, chercher la sienne par son nom ou son pays, ici mutuel bretagne, puis toucher Crédit Mutuel de Bretagne. 3, la page Obtenir ta clé : Ouvrir le portail ouvre le site d’Enable Banking dans le navigateur, et chaque valeur à coller a son bouton Copier. 4, Importer la clé : choisir dans les téléchargements le fichier .pem, sans le renommer ; il est chiffré aussitôt et sa copie effacée. 5, la page de la banque s’ouvre, on valide comme d’habitude, puis la carte affiche Synchronisé, accès encore 180 jours, et les opérations arrivent.');
}

// ------------------------------------------------------------------------
// 8. Sur le portail d'Enable Banking : ce que la page guide fait faire.
//
// Un navigateur à gauche : la connexion par e-mail, le formulaire qui se
// remplit champ après champ, la clé qui se télécharge, puis le compte
// relié. À droite, la liste se coche au fur et à mesure.
{
  const C = 30;
  const BX = 60, BY = 96, BL = 790, BH = 590;
  const CX = BX + 30, CY = BY + 76;
  let corps = '';
  corps += t(60, 52, 'SUR LE PORTAIL D’ENABLE BANKING', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(420, 52, 'Gratuit, pour tes propres comptes. SmartBudget te donne quoi taper et quoi coller.', { taille: 14 });
  // Le navigateur.
  corps += `<rect x="${BX}" y="${BY}" width="${BL}" height="${BH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>
    <path d="M${BX} ${BY + 44} H${BX + BL}" stroke="${BORD}"/>
    ${[ROUGE, OR, VERT].map((c, i) => `<circle cx="${BX + 22 + i * 18}" cy="${BY + 22}" r="5.5" fill="${c}" fill-opacity="0.7"/>`).join('')}
    <rect x="${BX + 90}" y="${BY + 10}" width="${BL - 110}" height="24" rx="12" fill="${FOND}"/>
    <g transform="translate(${BX + 100},${BY + 13}) scale(0.62)">${P.cadenas(DISCRET)}</g>`;
  const adresse = (s, de, a) => `<g opacity="0">${visible(C, de, a, 0.004)}${t(BX + 124, BY + 27, s, { taille: 12, couleur: TEXTE, police: MONO })}</g>`;
  corps += adresse('enablebanking.com/sign-in', 0.004, 0.2);
  corps += adresse('enablebanking.com/cp/applications/new', 0.2, 0.62);
  corps += adresse('enablebanking.com/cp/applications/a3f9c2e1…', 0.62, 0.996);
  const champ = (x, y, l, texte, couleur = TITRE) => `<rect x="${x}" y="${y}" width="${l}" height="34" rx="8" fill="${FOND}" stroke="${BORD}"/>
    ${t(x + 12, y + 22, texte, { taille: 12.5, couleur, police: MONO })}`;
  let page = '';

  // A. Se connecter par e-mail.
  page += `<g opacity="0">${visible(C, 0.004, 0.2, 0.004)}
    ${t(CX, CY + 20, 'Sign in', { taille: 24, couleur: TITRE, poids: 800 })}
    ${t(CX, CY + 48, 'Enter your email, we’ll send you a sign-in link.', { taille: 13 })}
    <rect x="${CX}" y="${CY + 70}" width="360" height="40" rx="8" fill="${FOND}" stroke="${BORD}"/>
    ${frappe(CX + 14, CY + 96, 'toi@exemple.fr', C, 0.02, 0.07, { taille: 13.5, couleur: TITRE, police: MONO })}
    ${pilule(CX, CY + 124, 140, 38, 'Continue', BLEU, { plein: true })}
    ${toucher(CX + 70, CY + 143, C, 0.085)}
    <g opacity="0">${visible(C, 0.1, 0.2, 0.004)}
      <rect x="${CX}" y="${CY + 190}" width="${BL - 60}" height="84" rx="12" fill="${BLEU}" fill-opacity="0.08" stroke="${BLEU}" stroke-opacity="0.45"/>
      <path d="M${CX + 22} ${CY + 214} h34 v26 h-34 z M${CX + 22} ${CY + 214} l17 13 l17 -13" fill="none" stroke="${BLEU}" stroke-width="2" stroke-linejoin="round"/>
      ${t(CX + 74, CY + 226, 'Check your inbox', { taille: 14, couleur: TITRE, poids: 700 })}
      ${t(CX + 74, CY + 246, 'Ouvre le lien reçu : le compte se crée tout seul la première fois.', { taille: 12.5 })}
    </g>
  </g>`;

  // B. Le formulaire, champ après champ.
  const champs = [
    ['Environment', 'Production', null],
    ['Private key', 'Generate in the browser', null],
    ['Application name', 'SmartBudget', null],
    ['Allowed redirect URLs', 'https://cybertrist.github.io/SmartBudget/', 'collé'],
    ['Application description', 'Application personnelle de suivi de budget…', 'collé'],
    ['Email for data protection', 'toi@exemple.fr', null],
    ['Privacy URL', 'https://github.com/Cybertrist/SmartBudget', 'collé'],
    ['Terms URL', 'https://github.com/Cybertrist/SmartBudget', 'collé'],
  ];
  const remplir = (i) => 0.22 + i * 0.037;
  page += `<g opacity="0">${visible(C, 0.2, 0.62, 0.004)}
    ${t(CX, CY + 14, 'Add a new application', { taille: 20, couleur: TITRE, poids: 800 })}
    ${champs.map(([nom, valeur, colle], i) => {
      const y = CY + 36 + i * 46, s = remplir(i);
      return `${t(CX, y + 22, nom, { taille: 12.5, couleur: TEXTE, poids: 600 })}
        <rect x="${CX + 200}" y="${y}" width="${BL - 260}" height="34" rx="8" fill="${FOND}" stroke="${BORD}">
          ${fondu('stroke', C, [[0, BORD], [s, BORD], [s + 0.004, colle ? VERT : BLEU], [s + 0.03, colle ? VERT : BLEU], [s + 0.034, BORD], [1, BORD]])}</rect>
        <g opacity="0">${visible(C, s, 0.62, 0.004)}${t(CX + 212, y + 22, valeur, { taille: 12, couleur: TITRE, police: MONO })}</g>
        ${colle ? `<g opacity="0">${visible(C, s, 0.62, 0.004)}<rect x="${CX + BL - 128}" y="${y + 7}" width="60" height="20" rx="10" fill="${VERT}" fill-opacity="0.14"/>${t(CX + BL - 98, y + 21, colle, { taille: 10.5, couleur: VERT, poids: 700, ancre: 'middle' })}</g>` : ''}`;
    }).join('')}
    ${pilule(CX, CY + 412, 130, 38, 'Register', BLEU, { plein: true })}
    ${toucher(CX + 65, CY + 431, C, 0.53)}
    <g opacity="0">${visible(C, 0.55, 0.62, 0.004)}
      <rect x="${CX + 150}" y="${CY + 408}" width="${BL - 210}" height="46" rx="10" fill="${OR}" fill-opacity="0.1" stroke="${OR}" stroke-opacity="0.6"/>
      <g transform="translate(${CX + 164},${CY + 417})">${P.cle(OR)}</g>
      ${t(CX + 204, CY + 429, 'a3f9c2e1-7b4d-4e0a-9c11-5d2f8e6b7a90.pem', { taille: 12, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(CX + 204, CY + 446, 'téléchargé : c’est ta clé, garde ce nom', { taille: 11.5, couleur: OR })}
    </g>
  </g>`;

  // C. L'application créée : relier son compte.
  const relie = 0.9;
  page += `<g opacity="0">${visible(C, 0.62, 0.996, 0.004)}
    ${t(CX, CY + 20, 'SmartBudget', { taille: 22, couleur: TITRE, poids: 800 })}
    ${pilule(CX + 150, CY + 2, 90, 24, 'Production', BLEU, { taille: 10.5 })}
    ${pilule(CX + 250, CY + 2, 96, 24, 'Restricted', OR, { taille: 10.5 })}
    ${t(CX, CY + 60, 'Linked accounts', { taille: 13, couleur: TEXTE, poids: 600 })}
    <g opacity="0">${visible(C, 0.62, relie, 0.004)}${t(CX + 140, CY + 60, '0', { taille: 13, couleur: TITRE, police: MONO, poids: 700 })}</g>
    <g opacity="0">${visible(C, relie, 0.996, 0.004)}${t(CX + 140, CY + 60, '1 · Crédit Mutuel de Bretagne', { taille: 13, couleur: VERT, police: MONO, poids: 700 })}</g>
    ${pilule(CX, CY + 82, 260, 40, 'Activate by linking accounts', BLEU)}
    ${toucher(CX + 130, CY + 102, C, 0.67)}
    <g opacity="0">${visible(C, 0.69, 0.86, 0.004)}
      <rect x="${CX + 40}" y="${CY + 140}" width="${BL - 140}" height="270" rx="14" fill="#18212D" stroke="${BLEU}" stroke-opacity="0.5"/>
      ${t(CX + 66, CY + 176, 'Link accounts', { taille: 17, couleur: TITRE, poids: 800 })}
      ${[['Country', 'France', 0.7], ['ASPSP', 'Crédit Mutuel de Bretagne', 0.73], ['PSU type', 'personal', 0.76]].map(([nom, valeur, s], i) => `
        ${t(CX + 66, CY + 214 + i * 46, nom, { taille: 12.5, couleur: TEXTE, poids: 600 })}
        ${champ(CX + 190, CY + 192 + i * 46, 340, '')}
        <g opacity="0">${visible(C, s, 0.86, 0.004)}${t(CX + 202, CY + 214 + i * 46, valeur, { taille: 12.5, couleur: TITRE, police: MONO })}</g>`).join('')}
      ${pilule(CX + 66, CY + 344, 110, 38, 'Link', BLEU, { plein: true })}
      ${toucher(CX + 121, CY + 363, C, 0.8)}
      <g opacity="0">${visible(C, 0.815, 0.86, 0.004)}${t(CX + 196, CY + 368, '→ ta banque s’ouvre : tu valides comme d’habitude', { taille: 12.5, couleur: OR })}</g>
    </g>
    <g opacity="0">${visible(C, relie, 0.996, 0.004)}
      <rect x="${CX}" y="${CY + 150}" width="${BL - 60}" height="80" rx="12" fill="${VERT}" fill-opacity="0.08" stroke="${VERT}" stroke-opacity="0.5"/>
      <circle cx="${CX + 36}" cy="${CY + 190}" r="15" fill="${VERT}"/>
      <path d="M${CX + 29} ${CY + 190} l5 5 l9 -10" fill="none" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
      ${t(CX + 64, CY + 185, 'Application active, en mode restreint gratuit.', { taille: 14, couleur: TITRE, poids: 700 })}
      ${t(CX + 64, CY + 205, 'Retour dans SmartBudget : Importer la clé.', { taille: 12.5, couleur: VERT })}
    </g>
  </g>`;
  corps += page;

  // La liste qui se coche, à droite.
  const LX = 890;
  const liste = [
    ['Se connecter par e-mail', 'le lien reçu, ouvert dans le navigateur', 0.1],
    ['Créer l’application', 'Production, clé générée dans le navigateur', 0.3],
    ['Coller les valeurs copiées', 'adresse de retour, description, liens', 0.48],
    ['Register', 'le fichier .pem se télécharge', 0.56],
    ['Relier son compte', 'sa banque, type personal, puis Link', relie],
  ];
  corps += t(LX, 128, 'À COCHER', { taille: 12, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  liste.forEach(([titreItem, sous, fait], i) => {
    const y = 170 + i * 92;
    corps += `<rect x="${LX}" y="${y - 22}" width="330" height="76" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${LX}" y="${y - 22}" width="330" height="76" rx="12" fill="none" stroke="${VERT}" stroke-opacity="0.55" opacity="0">${visible(C, fait, 0.996, 0.004)}</rect>
      <rect x="${LX + 18}" y="${y - 2}" width="24" height="24" rx="7" fill="none" stroke="${FIL}" stroke-width="2"/>
      <g opacity="0">${visible(C, fait, 0.996, 0.004)}
        <rect x="${LX + 18}" y="${y - 2}" width="24" height="24" rx="7" fill="${VERT}"/>
        <path d="M${LX + 24} ${y + 10} l4 4 l8 -9" fill="none" stroke="#000000" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
      </g>
      ${t(LX + 58, y + 10, titreItem, { taille: 15, couleur: TITRE, poids: 700 })}
      ${t(LX + 58, y + 30, sous, { taille: 12.5 })}`;
  });
  corps += t(LX, 660, 'Ne renomme jamais le fichier .pem :', { taille: 13, couleur: OR, poids: 700 });
  corps += t(LX, 680, 'son nom est l’identifiant de ton application.', { taille: 13, couleur: OR });
  svg('portail.svg', 1280, 720, corps,
    'Sur le portail d’Enable Banking. Se connecter : taper son adresse e-mail, Continue, puis ouvrir le lien reçu. Créer l’application, Add a new application : Environment Production, Private key Generate in the browser, Application name SmartBudget, puis coller les valeurs copiées depuis SmartBudget : Allowed redirect URLs https://cybertrist.github.io/SmartBudget/, la description, Privacy URL et Terms URL ; Email for data protection, son adresse. Register : un fichier .pem se télécharge, c’est la clé, à ne jamais renommer. Puis Activate by linking accounts : pays, sa banque, type personal, Link, et l’on valide sur sa banque. L’application est active, en mode restreint gratuit.');
}

if (EN && manque.size) {
  console.error('  Absent de anglais.json :');
  for (const s of manque) console.error('    ' + s);
  process.exit(1);
}
if (!EN) {
  require('child_process').execFileSync(process.execPath, [__filename], { env: { ...process.env, LANGUE: 'en' }, stdio: 'inherit' });
}

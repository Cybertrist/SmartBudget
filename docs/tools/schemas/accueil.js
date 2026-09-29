// L'accueil : le mois en un coup d'œil, et comment chaque opération y entre.
//
// À gauche, les opérations de septembre passent une à une. Au milieu,
// l'accueil du téléphone se met à jour à chacune : le budget et sa jauge,
// les cinq premières catégories, la répartition. Les chiffres sont
// calculés ici, avec les règles du bilan : un virement interne ne compte
// que dans l'épargne, un remboursement lié allège sa dépense, une
// opération masquée ne compte nulle part. À droite, les quatre règles
// s'allument quand elles jouent.
module.exports = (O) => {
  const { svg, t, fondu, visible, paliers, APP, MONO, SANS, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, BLEU, OR, ROUGE, INTERNE } = O;
  const C = 30, FIN = 0.97;
  const BUDGET = 150000, OBJECTIF = 500000, LIVRET = 286000;

  // Les catégories de départ, avec leurs couleurs dans l'application.
  const CAT = {
    Logement: '#5AB2FF', Courses: '#50F48D', 'Restaurants et sorties': '#FFC857', Transports: '#9B8CFF',
    Santé: '#4DE2D0', Shopping: '#FF9F5A', Abonnements: '#FF8FD1',
  };
  const NAT = { essentiel: '#5AB2FF', plaisir: '#FF8FD1', epargne: '#3CE0FF', imprevu: '#FF9F5A' };
  // Les pictogrammes des natures, pleins, comme dans l'application.
  const PICTO = {
    essentiel: (c) => `<path d='M8 14 L2.5 8.5 A3.2 3.2 0 0 1 8 4 A3.2 3.2 0 0 1 13.5 8.5 Z' fill='${c}'/>`,
    plaisir: (c) => `<path d='M2 7 H5 V14 H2 Z M6 14 H12 L14 8 V7 H10 L11 3 C11 2 9.5 1.5 9 2.5 L6 7 Z' fill='${c}'/>`,
    epargne: (c) => `<ellipse cx='7.5' cy='9' rx='5.8' ry='4.6' fill='${c}'/><rect x='12' y='7.2' width='3' height='3.4' rx='1' fill='${c}'/><path d='M4.5 5.5 L5.5 2.2 L8.5 4.6 Z' fill='${c}'/><rect x='4' y='12' width='2' height='3' fill='${c}'/><rect x='9' y='12' width='2' height='3' fill='${c}'/>`,
    imprevu: (c) => `<path d='M9.5 1 L3 9 H7.5 L6.5 15 L13 7 H8.5 Z' fill='${c}'/>`,
  };
  const ICONE = {
    maison: (c) => `<path d="M2 8 L8 2.5 L14 8 M4 7 V14 H12 V7" fill="none" stroke="${c}" stroke-width="1.6" stroke-linejoin="round"/>`,
    panier: (c) => `<path d="M1 3 H4 L6 11 H13 L15 5 H5" fill="none" stroke="${c}" stroke-width="1.6" stroke-linejoin="round"/><circle cx="7" cy="14" r="1.3" fill="${c}"/><circle cx="12" cy="14" r="1.3" fill="${c}"/>`,
    interne: (c) => `<path d="M2 5 H13 M10 2 L13 5 L10 8 M14 11 H3 M6 8 L3 11 L6 14" fill="none" stroke="${c}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>`,
    couverts: (c) => `<path d="M4 1.5 V14.5 M2 1.5 V5 A2 2 0 0 0 6 5 V1.5 M11.5 14.5 V1.5 C9 3 9 8 11.5 8" fill="none" stroke="${c}" stroke-width="1.6" stroke-linecap="round"/>`,
    train: (c) => `<rect x="3" y="1.5" width="10" height="10" rx="2.5" fill="none" stroke="${c}" stroke-width="1.6"/><path d="M3 7 H13 M5 15 L6.5 11.5 M11 15 L9.5 11.5" stroke="${c}" stroke-width="1.6" stroke-linecap="round"/>`,
    voiture: (c) => `<path d="M2 11 V8 L4 3.5 H12 L14 8 V11 Z M2 8 H14" fill="none" stroke="${c}" stroke-width="1.6" stroke-linejoin="round"/><circle cx="5" cy="12.5" r="1.4" fill="${c}"/><circle cx="11" cy="12.5" r="1.4" fill="${c}"/>`,
    croix: (c) => `<path d="M6 2 H10 V6 H14 V10 H10 V14 H6 V10 H2 V6 H6 Z" fill="none" stroke="${c}" stroke-width="1.6" stroke-linejoin="round"/>`,
    retour: (c) => `<path d="M13 9 A5 5 0 1 1 8 4 H11 M9 1.5 L11.5 4 L9 6.5" fill="none" stroke="${c}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>`,
    sac: (c) => `<path d="M3 5 H13 L12 14.5 H4 Z M5.5 5 V4 A2.5 2.5 0 0 1 10.5 4 V5" fill="none" stroke="${c}" stroke-width="1.6" stroke-linejoin="round"/>`,
    note: (c) => `<path d="M6 12 V3 L13 1.5 V10.5" fill="none" stroke="${c}" stroke-width="1.6"/><circle cx="4.5" cy="12.5" r="2" fill="${c}"/><circle cx="11.5" cy="11" r="2" fill="${c}"/>`,
  };
  const ICONE_CAT = { Logement: 'maison', Courses: 'panier', 'Restaurants et sorties': 'couverts', Transports: 'voiture', Santé: 'croix', Shopping: 'sac', Abonnements: 'note' };

  // Le mois, opération par opération. [sorte] : ce que le bilan en fait.
  const ops = [
    { nom: 'Foncia Loyer', m: -62000, cat: 'Logement', nat: 'essentiel', sous: 'Logement · essentiel', icone: 'maison', verdict: 'compté' },
    { nom: 'Carrefour Market', m: -18240, cat: 'Courses', nat: 'essentiel', sous: 'Courses · essentiel', icone: 'panier', verdict: 'compté' },
    { nom: 'Virement Livret A', m: -20000, sorte: 'interne', sous: 'Virement interne · vers l’épargne', icone: 'interne', couleur: INTERNE, verdict: 'hors budget · Épargne' },
    { nom: 'Le Comptoir', m: -8650, cat: 'Restaurants et sorties', nat: 'plaisir', sous: 'Restaurants et sorties · plaisir', icone: 'couverts', verdict: 'compté' },
    { nom: 'SNCF Connect', m: -14500, cat: 'Transports', nat: 'essentiel', sous: 'Transports · essentiel', icone: 'train', verdict: 'compté' },
    { nom: 'Norauto', m: -38000, cat: 'Transports', nat: 'imprevu', sous: 'Transports · imprévu, à la main', icone: 'voiture', verdict: 'compté · imprévu' },
    { nom: 'Pharmacie du Port', m: -3000, cat: 'Santé', nat: 'essentiel', sous: 'Santé · essentiel', icone: 'croix', verdict: 'compté', id: 'pharmacie' },
    { nom: 'CPAM', m: 2350, sorte: 'rembourse', lien: 'pharmacie', sous: 'Remboursements · lié à la pharmacie', icone: 'retour', couleur: OR, verdict: 'allège la pharmacie' },
    { nom: 'Leboncoin', m: -25000, sorte: 'masquee', cat: 'Shopping', sous: 'Shopping · masquée', icone: 'sac', couleur: DISCRET, verdict: 'masquée : ignorée' },
    { nom: 'Zalando', m: -8999, cat: 'Shopping', nat: 'plaisir', sous: 'Shopping · plaisir', icone: 'sac', verdict: 'compté · dépassé' },
    { nom: 'Spotify', m: -1112, cat: 'Abonnements', nat: 'plaisir', sous: 'Abonnements · plaisir', icone: 'note', verdict: 'compté · hors des cinq' },
  ];
  const N = ops.length;
  const s = (k) => 0.05 + k * 0.069; // l'instant où l'opération k entre
  // Les états de l'accueil : avant tout, puis après chaque opération.
  const etats = [];
  {
    const parCat = {}, nat = { essentiel: 0, plaisir: 0, epargne: 0, imprevu: 0 };
    let sorties = 0, livret = LIVRET;
    const faites = [];
    etats.push(JSON.parse(JSON.stringify({ parCat, nat, sorties, livret })));
    for (const o of ops) {
      if (o.sorte === 'interne') {
        nat.epargne += -o.m;
        livret += -o.m;
      } else if (o.sorte === 'rembourse') {
        // La part liée vient en déduction de la dépense qu'il rembourse.
        const d = ops.find((x) => x.id === o.lien);
        parCat[d.cat] -= o.m;
        nat[d.nat] -= o.m;
        sorties -= o.m;
      } else if (o.sorte !== 'masquee') {
        parCat[o.cat] = (parCat[o.cat] || 0) - o.m;
        nat[o.nat] += -o.m;
        sorties += -o.m;
      }
      faites.push(o);
      etats.push(JSON.parse(JSON.stringify({ parCat, nat, sorties, livret })));
    }
  }
  const euros = (c) => {
    const a = Math.abs(c), e = Math.trunc(a / 100), ct = a % 100;
    return `${c < 0 ? '-' : ''}${String(e).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')},${String(ct).padStart(2, '0')} €`;
  };
  const entier = (c) => `${String(Math.trunc(c / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} €`;

  let corps = '';
  corps += t(60, 52, 'L’ACCUEIL', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + O.tr('L’ACCUEIL').length * 10.9 + 24), 52, 'Le mois en cours, en un coup d’œil. Chaque opération y entre, ou pas : voici comment.', { taille: 14 });

  // ----------------------------------------------- les opérations du mois
  const LX = 60, LL = 410, LY = 142, PAS = 48;
  corps += t(LX, 116, 'SEPTEMBRE, OPÉRATION PAR OPÉRATION', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  ops.forEach((o, k) => {
    const y = LY + k * PAS, a = s(k + 1) - 0.004;
    const c = o.couleur || VERT;
    const tuile = o.sorte === 'interne' ? INTERNE : o.sorte === 'rembourse' ? '#7FE0A8' : CAT[o.cat];
    const exclue = o.sorte === 'interne' || o.sorte === 'masquee' || o.sorte === 'rembourse';
    corps += `<g>
      <rect x="${LX}" y="${y}" width="${LL}" height="42" rx="10" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${LX}" y="${y}" width="${LL}" height="42" rx="10" fill="${c}" fill-opacity="0.08" stroke="${c}" stroke-width="1.5" opacity="0">${visible(C, a, a + 0.06, 0.004)}</rect>
      <rect x="${LX + 10}" y="${y + 7}" width="28" height="28" rx="8" fill="${tuile}" fill-opacity="0.16" stroke="${tuile}" stroke-opacity="0.5"/>
      <g transform="translate(${LX + 16},${y + 13})">${ICONE[o.icone](tuile)}</g>
      ${t(LX + 48, y + 18, o.nom, { taille: 12.5, couleur: TITRE, poids: 700 })}
      ${t(LX + 48, y + 34, o.sous, { taille: 10.5, couleur: o.sorte === 'masquee' ? DISCRET : TEXTE })}
      ${t(LX + LL - 12, y + 18, (o.m > 0 ? '+' : '') + euros(o.m), { taille: 11.5, couleur: o.m > 0 ? VERT : TITRE, police: MONO, poids: 700, ancre: 'end' })}
      <g opacity="0">${visible(C, a, FIN, 0.004)}
        ${exclue ? `<line x1="${LX + LL - 12 - O.tr(euros(o.m)).length * 6.7 - (o.m > 0 ? 7 : 0) + 2}" y1="${y + 14}" x2="${LX + LL - 10}" y2="${y + 14}" stroke="${c}" stroke-width="1.6"/>` : ''}
        ${t(LX + LL - 12, y + 34, o.verdict, { taille: 10.5, couleur: c, poids: 700, ancre: 'end' })}
      </g>
    </g>`;
  });
  // Le curseur qui descend la liste.
  corps += `<path d="M${LX - 14} 0 l8 6 l-8 6 z" fill="${VERT}" opacity="0">
    ${fondu('opacity', C, [[0, 0], [s(1) - 0.01, 0], [s(1), 1], [s(N), 1], [s(N) + 0.05, 0], [1, 0]])}
    <animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" calcMode="discrete"
      keyTimes="${[0, ...ops.map((_, k) => s(k + 1) - 0.004)].map((x) => x.toFixed(4)).join(';')}" values="${[LY + 15, ...ops.map((_, k) => LY + k * PAS + 15)].map((y) => `0 ${y}`).join(';')}"/></path>`;

  // ------------------------------------------------------ le téléphone
  const PX = 510, PY = 92, PL = 300, PH = 650;
  const SX = PX + 10, SY = PY + 14, SL = PL - 20, SH = PH - 28;
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="38" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranAccueil"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 30}" y="${PY + 5}" width="60" height="5" rx="2.5" fill="#1B222C"/>`;
  const barre = (x, y, l, parts) => {
    const total = parts.reduce((a, p) => a + Math.max(p[0], 0), 0);
    if (!total) return `<rect x="${x}" y="${y}" width="${l}" height="7" rx="3.5" fill="#2A2A2A"/>`;
    const vis = parts.filter((p) => p[0] > 0);
    const gap = 3, utile = l - gap * (vis.length - 1);
    let cx = x, sortie = '';
    for (const [v, c] of vis) {
      const w = Math.max(utile * v / total, 3);
      sortie += `<rect x="${cx.toFixed(1)}" y="${y}" width="${w.toFixed(1)}" height="7" rx="3.5" fill="${c}"/>`;
      cx += w + gap;
    }
    return sortie;
  };
  const vue = (e) => {
    const cartes = SY + 44, depY = SY + 186, repY = SY + 408;
    const demi = (SL - 30) / 2;
    const reste = BUDGET - e.sorties, part = e.sorties / BUDGET;
    const coul = part >= 1 ? ROUGE : part >= 0.9 ? OR : VERT;
    const top = Object.entries(e.parCat).filter(([, v]) => v > 0).sort((a, b) => b[1] - a[1]);
    const lignesNat = [['Essentiel', 'essentiel'], ['Plaisir', 'plaisir'], ['Épargne', 'epargne'], ['Imprévu', 'imprevu']];
    const totalNat = lignesNat.reduce((a, [, k]) => a + Math.max(e.nat[k], 0), 0);
    let v = '';
    // Budget et épargne.
    v += `<rect x="${SX + 10}" y="${cartes}" width="${demi}" height="124" rx="14" fill="${APP.carte}"/>
      <rect x="${SX + 20 + demi}" y="${cartes}" width="${demi}" height="124" rx="14" fill="${APP.carte}"/>
      ${t(SX + 24, cartes + 26, 'BUDGET', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
      ${t(SX + 24, cartes + 60, euros(reste), { taille: 19, couleur: coul, poids: 800 }).replace('>-', '>')}
      ${t(SX + 24, cartes + 79, reste >= 0 ? 'restants sur 1 500 €' : 'de dépassement', { taille: 10.5, couleur: APP.second })}
      <rect x="${SX + 24}" y="${cartes + 100}" width="${demi - 28}" height="6" rx="3" fill="#2A2A2A"/>
      <rect x="${SX + 24}" y="${cartes + 100}" width="${((demi - 28) * Math.min(part, 1)).toFixed(1)}" height="6" rx="3" fill="${coul}"/>
      ${t(SX + 34 + demi, cartes + 26, 'ÉPARGNE', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
      ${t(SX + 34 + demi, cartes + 60, euros(e.livret), { taille: 16, couleur: APP.texte, poids: 800 })}
      ${t(SX + 34 + demi, cartes + 79, `${Math.round(e.livret * 100 / OBJECTIF)} % de 5 000 €`, { taille: 10.5, couleur: APP.second })}
      <rect x="${SX + 34 + demi}" y="${cartes + 100}" width="${demi - 28}" height="6" rx="3" fill="#2A2A2A"/>
      <rect x="${SX + 34 + demi}" y="${cartes + 100}" width="${((demi - 28) * e.livret / OBJECTIF).toFixed(1)}" height="6" rx="3" fill="${BLEU}"/>`;
    // Dépenses par catégorie : la barre les montre toutes, la liste cinq.
    v += `<rect x="${SX + 10}" y="${depY}" width="${SL - 20}" height="208" rx="14" fill="${APP.carte}"/>
      ${t(SX + 24, depY + 26, 'DÉPENSES PAR CATÉGORIE', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.4"' })}
      ${t(SX + SL - 24, depY + 26, euros(e.sorties), { taille: 11.5, couleur: APP.texte, police: MONO, poids: 700, ancre: 'end' })}
      ${barre(SX + 24, depY + 38, SL - 48, top.map(([n, x]) => [x, CAT[n]]))}`;
    if (!top.length) v += t(SX + 24, depY + 78, 'Aucune dépense ce mois-ci.', { taille: 12, couleur: APP.second });
    top.slice(0, 5).forEach(([n, x], i) => {
      const y = depY + 58 + i * 29;
      v += `<rect x="${SX + 24}" y="${y}" width="24" height="24" rx="7" fill="${CAT[n]}" fill-opacity="0.16" stroke="${CAT[n]}" stroke-opacity="0.5"/>
        <g transform="translate(${SX + 28},${y + 4}) scale(0.95)">${ICONE[ICONE_CAT[n]](CAT[n])}</g>
        ${t(SX + 58, y + 16.5, n, { taille: 12.5, couleur: APP.texte, poids: 600 })}
        ${t(SX + SL - 24, y + 16.5, euros(x), { taille: 11.5, couleur: APP.texte, police: MONO, poids: 700, ancre: 'end' })}`;
    });
    // La répartition.
    v += `<rect x="${SX + 10}" y="${repY}" width="${SL - 20}" height="196" rx="14" fill="${APP.carte}"/>
      ${t(SX + 24, repY + 26, 'RÉPARTITION DES DÉPENSES', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.4"' })}
      ${barre(SX + 24, repY + 38, SL - 48, lignesNat.map(([, k]) => [e.nat[k], NAT[k]]))}`;
    lignesNat.forEach(([nom, k], i) => {
      const y = repY + 58 + i * 33, x = e.nat[k], plein = x > 0;
      v += `<circle cx="${SX + 37}" cy="${y + 13}" r="13" fill="${NAT[k]}" fill-opacity="${plein ? 1 : 0.18}"/>
        <g transform="translate(${SX + 29},${y + 5})">${PICTO[k](plein ? '#000000' : NAT[k])}</g>
        ${t(SX + 60, y + 11, nom, { taille: 12.5, couleur: APP.texte, poids: 600 })}
        ${totalNat ? t(SX + 60, y + 25, `${Math.round(Math.max(x, 0) * 100 / totalNat)} %`, { taille: 10, couleur: APP.discret }) : ''}
        ${t(SX + SL - 24, y + 17, euros(x), { taille: 11.5, couleur: plein ? APP.texte : APP.discret, police: MONO, poids: 700, ancre: 'end' })}`;
    });
    return v;
  };
  let ecran = `<text x="${SX + 16}" y="${SY + 32}" font-family="${SANS}" font-size="18" font-weight="800" fill="${APP.texte}">Smart <tspan fill="#50F48D">Budget</tspan></text>
    ${t(SX + SL - 16, SY + 31, 'Septembre 2026', { taille: 11, couleur: APP.second, poids: 700, ancre: 'end' })}`;
  etats.forEach((e, k) => {
    const de = k === 0 ? 0 : s(k), a = k === N ? FIN : s(k + 1);
    const pas = [[0, k === 0 ? 1 : 0]];
    if (k > 0) pas.push([de, 1]);
    pas.push([a, 0]);
    if (k === 0) pas.push([FIN, 1]);
    ecran += `<g opacity="${k === 0 ? 1 : 0}">${paliers('opacity', C, pas)}${vue(e)}</g>`;
  });
  // Un éclat sur ce qui vient de bouger.
  const eclat = (y, h, de, c = VERT) => `<rect x="${SX + 10}" y="${y}" width="${SL - 20}" height="${h}" rx="14" fill="none" stroke="${c}" stroke-width="1.8" opacity="0">${visible(C, de, de + 0.05, 0.004)}</rect>`;
  const demi = (SL - 30) / 2;
  ops.forEach((o, k) => {
    const de = s(k + 1);
    if (o.sorte === 'masquee') {
      ecran += `<g opacity="0">${visible(C, de, de + 0.06, 0.004)}<rect x="${SX + SL - 132}" y="${SY + 12}" width="118" height="26" rx="13" fill="#2E2E2E"/>${t(SX + SL - 73, SY + 29.5, 'rien ne bouge', { taille: 11.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}</g>`;
      return;
    }
    if (o.sorte === 'interne') {
      ecran += `<rect x="${SX + 20 + demi}" y="${SY + 44}" width="${demi}" height="124" rx="14" fill="none" stroke="${BLEU}" stroke-width="1.8" opacity="0">${visible(C, de, de + 0.05, 0.004)}</rect>`;
      ecran += eclat(SY + 408, 196, de, BLEU);
      return;
    }
    // La carte du budget s'éclaire de la couleur qu'elle prend : verte,
    // jaune dès 90 %, rouge au-delà.
    const part = etats[k + 1].sorties / BUDGET;
    const coulBudget = part >= 1 ? ROUGE : part >= 0.9 ? OR : VERT;
    ecran += `<rect x="${SX + 10}" y="${SY + 44}" width="${demi}" height="124" rx="14" fill="none" stroke="${coulBudget}" stroke-width="1.8" opacity="0">${visible(C, de, de + 0.05, 0.004)}</rect>`;
    ecran += eclat(SY + 186, 208, de, o.sorte === 'rembourse' ? OR : VERT);
  });
  corps += `<g clip-path="url(#ecranAccueil)">${ecran}</g>`;

  // --------------------------------------------------------- les règles
  const RX = 850, RL = 370;
  const regles = [
    ['Le budget', VERT, ['Le budget du mois, moins les sorties.', 'Vert, puis jaune dès 90 %, rouge au-delà :', 'le reste devient « de dépassement ».'], [1, 6, 10]],
    ['Les cinq premières', '#9B8CFF', ['Les catégories de dépenses, de la plus', 'lourde à la plus légère. La barre les montre', 'toutes, la liste s’arrête à cinq.'], [6, 10, 11]],
    ['La répartition', BLEU, ['Essentiel ou plaisir, selon la catégorie.', 'Imprévu : choisi à la main sur l’opération.', 'Épargne : ce qui part vers les livrets.'], [3, 6]],
    ['Ce qui ne compte pas', INTERNE, ['Un virement interne : hors budget.', 'Un remboursement allège sa dépense,', 'ce n’est pas un revenu. Masquée : nulle part.'], [3, 8, 9]],
  ];
  corps += t(RX, 116, 'CE QUE L’ACCUEIL COMPTE', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  regles.forEach(([titre, c, lignes, quand], i) => {
    const y = 136 + i * 136;
    corps += `<rect x="${RX}" y="${y}" width="${RL}" height="122" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${RX}" y="${y}" width="${RL}" height="122" rx="13" fill="${c}" fill-opacity="0.05" stroke="${c}" stroke-opacity="0.3"/>
      ${t(RX + 20, y + 32, titre, { taille: 15, couleur: TITRE, police: MONO, poids: 700 })}
      ${lignes.map((l, j) => t(RX + 20, y + 58 + j * 20, l, { taille: 12.5 })).join('')}`;
    for (const k of quand) {
      const de = s(k);
      corps += `<rect x="${RX}" y="${y}" width="${RL}" height="122" rx="13" fill="none" stroke="${i === 0 ? ({ 6: OR, 10: ROUGE }[k] || c) : c}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, de, de + 0.06, 0.006)}</rect>`;
    }
  });

  corps += t(640, 778, 'Toujours le mois en cours : il s’ouvre le jour où arrive le salaire.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('accueil.svg', 1280, 800, corps,
    `L’accueil, le mois en cours en un coup d’œil, sur un téléphone animé. Onze opérations de septembre y entrent une à une, avec un budget de 1 500 euros. Foncia Loyer, 620 euros, et Carrefour Market, 182,40 euros, comptent. Un virement de 200 euros vers le Livret A est hors budget : il ne compte que dans l’épargne, et le livret passe à 3 060 euros. Le Comptoir, 86,50 euros, et SNCF Connect, 145 euros, comptent. Norauto, 380 euros, marqué imprévu à la main, fait passer la jauge au jaune, au-delà de 90 %. Pharmacie du Port, 30 euros, puis un remboursement de la CPAM de 23,50 euros lié à elle : il n’est pas un revenu, il allège la pharmacie, qui ne pèse plus que 6,50 euros. Leboncoin, 250 euros, est masquée : rien ne bouge. Zalando, 89,99 euros, fait dépasser le budget : la carte passe au rouge et affiche 10,39 euros de dépassement. Spotify, 11,12 euros, compte mais reste hors des cinq premières catégories. À la fin : 1 521,51 euros de sorties, 21,51 euros de dépassement ; les cinq premières catégories sont Logement, Transports, Courses, Shopping, Restaurants et sorties ; la répartition donne Essentiel 953,90 euros, Plaisir 187,61 euros, Épargne 200 euros et Imprévu 380 euros.`);
};

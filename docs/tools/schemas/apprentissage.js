// À vérifier, et la correction apprise.
//
// À gauche, le téléphone : l'accueil signale quatre opérations à vérifier,
// on en classe une, les deux du même marchand quittent la liste, on garde
// une entrée, puis on renomme le marchand ; à la synchro suivante, sa
// nouvelle opération arrive déjà classée et déjà nommée. À droite, ce que
// l'application retient : la clé du marchand, la règle, le nom, et chaque
// opération de ce marchand qui suit.
module.exports = (O) => {
  const {
    svg, t, esc, visible, fondu, toucher, frappe, bille, APP,
    MONO, SANS, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, BLEU, OR, INTERNE,
  } = O;

  const C = 34;
  const LOISIRS = '#C6F45A', LOGEMENT = '#5AB2FF', COURSES = '#50F48D';
  const SURFACE = '#242424';
  const PX = 60, PY = 96, PL = 304, PH = 612;
  const SX = PX + 12, SY = PY + 16, SL = PL - 24, SH = PH - 32;

  // Les instants du récit, en fraction du cycle.
  const T = {
    puce: 0.07, liste: 0.095, classer: 0.14, choix: 0.155, loisirs: 0.19, sous: 0.205, hobbies: 0.245,
    classe: 0.265, suit: 0.285, liste2: 0.3, garder: 0.35, liste3: 0.39,
    fiche: 0.44, nom: 0.48, renommer: 0.495, efface: 0.515, tape: [0.52, 0.575], enregistrer: 0.595, renomme: 0.61,
    synchro: 0.74, arrive: 0.8, fin: 0.985,
  };

  let corps = '';
  corps += t(60, 52, 'À VÉRIFIER, ET CE QUI S’APPREND', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(420, 52, 'Une correction vaut pour tout le marchand : ce qui est déjà là, et ce qui viendra.', { taille: 14 });

  // ---------------------------------------------------------------- outils
  /// Une tuile d'icône, comme celles de l'application.
  const tuile = (x, y, s, c, glyphe) => `<rect x="${x}" y="${y}" width="${s}" height="${s}" rx="${s * 0.3}" fill="${c}" fill-opacity="0.16"/>
    <g transform="translate(${x + s / 2},${y + s / 2}) scale(${s / 40})">${glyphe(c)}</g>`;
  const G = {
    aide: (c) => `<circle r="10" fill="none" stroke="${c}" stroke-width="2.4"/><path d="M-3.4 -3 A3.6 3.6 0 1 1 1.2 0.6 C0 1.2 0 2 0 3.4" fill="none" stroke="${c}" stroke-width="2.4" stroke-linecap="round"/><circle cy="6.6" r="1.5" fill="${c}"/>`,
    loisirs: (c) => `<circle cy="-2" r="8.5" fill="none" stroke="${c}" stroke-width="2.2"/><path d="M0 -10.5 V6.5 M-8.5 -2 H8.5 M-6 -8 L6 4 M6 -8 L-6 4 M-6 11 L0 -2 L6 11" fill="none" stroke="${c}" stroke-width="1.8" stroke-linecap="round"/>`,
    logement: (c) => `<path d="M-10 -1 L0 -10 L10 -1 M-7 -3 V9 H7 V-3" fill="none" stroke="${c}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round"/>`,
    courses: (c) => `<path d="M-11 -8 H-7 L-4 5 H8 L10 -4 H-6" fill="none" stroke="${c}" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"/><circle cx="-3" cy="9" r="1.8" fill="${c}"/><circle cx="7" cy="9" r="1.8" fill="${c}"/>`,
  };
  /// La pastille verte cochée d'une opération pointée.
  const coche = (cx, cy, r = 7) => `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${VERT}" stroke="${SURFACE}" stroke-width="2"/>
    <path d="M${cx - r * 0.45} ${cy} l${r * 0.3} ${r * 0.3} l${r * 0.6} ${-r * 0.62}" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>`;
  const carteApp = (x, y, l, h, fond = APP.carte) => `<rect x="${x}" y="${y}" width="${l}" height="${h}" rx="16" fill="${fond}"/>`;
  const retour = (titre) => `${t(SX + 16, SY + 48, '‹', { taille: 24, couleur: APP.texte })}${t(SX + 36, SY + 48, titre, { taille: 20, couleur: APP.texte, poids: 800 })}`;
  /// Une petite pilule d'action, comme sous chaque ligne à vérifier.
  const action = (x, y, l, texte, c) => `<rect x="${x}" y="${y}" width="${l}" height="26" rx="13" fill="${c}" fill-opacity="0.08" stroke="${c}" stroke-opacity="0.3"/>
    ${t(x + l / 2, y + 17, texte, { taille: 10.5, couleur: c, poids: 700, ancre: 'middle' })}`;
  const g = (de, a, contenu, douceur = 0.004) => `<g opacity="0">${visible(C, de, a, douceur)}${contenu}</g>`;

  // ------------------------------------------------------------- téléphone
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="40" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranApprend"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 34}" y="${PY + 6}" width="68" height="5" rx="2.5" fill="#1B222C"/>`;
  let ecran = '';

  // 1. L'accueil : la puce des opérations à vérifier.
  ecran += g(0.004, T.liste, `
    ${t(SX + 18, SY + 50, 'Smart Budget', { taille: 20, couleur: APP.texte, poids: 800 })}
    ${t(SX + SL - 18, SY + 50, 'Septembre 2026', { taille: 11.5, couleur: APP.second, poids: 700, ancre: 'end' })}
    ${t(SX + 22, SY + 94, 'Sur tes comptes', { taille: 12, couleur: APP.second, poids: 600 })}
    ${t(SX + 22, SY + 132, '4 244,52 €', { taille: 32, couleur: APP.texte, poids: 800 })}
    <path d="M${SX + 24} ${SY + 159} a5 5 0 1 1 1.5 3.6 M${SX + 24} ${SY + 155} v4 h4" fill="none" stroke="${APP.discret}" stroke-width="1.5" stroke-linecap="round"/>
    ${t(SX + 38, SY + 163, 'Mis à jour le 26 sept.', { taille: 11, couleur: APP.discret })}
    <rect x="${SX + 20}" y="${SY + 178}" width="206" height="32" rx="16" fill="${OR}" fill-opacity="0.1" stroke="${OR}" stroke-opacity="0.35"/>
    <rect x="${SX + 32}" y="${SY + 187}" width="12" height="14" rx="2" fill="none" stroke="${OR}" stroke-width="1.6"/><path d="M${SX + 35} ${SY + 194} l2 2 l4 -4" fill="none" stroke="${OR}" stroke-width="1.6"/>
    ${t(SX + 52, SY + 199, '4 opérations à vérifier ›', { taille: 12, couleur: OR, poids: 700 })}
    ${carteApp(SX + 12, SY + 232, SL - 24, 150)}
    ${t(SX + 30, SY + 262, 'MES COMPTES', { taille: 10.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="2"' })}
    ${[['Compte courant', '1 284,52 €'], ['Livret CMB', '2 960,00 €']].map(([n, m], i) => `
      <line x1="${SX + 28}" y1="${SY + 276 + i * 46}" x2="${SX + SL - 28}" y2="${SY + 276 + i * 46}" stroke="${APP.trait}"/>
      ${t(SX + 30, SY + 304 + i * 46, n, { taille: 13, couleur: APP.texte, poids: 600 })}
      ${t(SX + SL - 30, SY + 304 + i * 46, m, { taille: 13, couleur: APP.texte, poids: 700, ancre: 'end' })}`).join('')}
    ${toucher(SX + 122, SY + 194, C, T.puce)}`);

  // 2. À vérifier : quatre opérations, puis deux, puis une.
  const LX = SX + 8, LL = SL - 16, PAS = 88;
  const ops = {
    legall: ['Remboursement M Le…', 'Samedi 12 septembre · VIR SEPA RECU…', '+25,00 €', VERT, true],
    gocard: ['Gocardless Ltd', 'Vendredi 11 septembre · PRLV SEPA GO…', '-9,99 €', APP.texte, false],
    sept: ['Sumup Atelier Kernevel', 'Mardi 8 septembre · PAIEMENT PAR C…', '-18,50 €', APP.texte, false],
    aout: ['Sumup Atelier Kernevel', 'Mercredi 12 août · PAIEMENT PAR CA…', '-22,00 €', APP.texte, false],
  };
  const ligne = (y, [titre, sous, montant, couleur, entree], separateur) => `
    ${separateur ? `<line x1="${LX + 12}" y1="${y}" x2="${LX + LL - 12}" y2="${y}" stroke="${APP.trait}"/>` : ''}
    ${tuile(LX + 12, y + 12, 32, OR, G.aide)}
    ${t(LX + 54, y + 27, titre, { taille: 12.5, couleur: APP.texte, poids: 700 })}
    ${t(LX + 54, y + 43, sous, { taille: 9.5, couleur: APP.discret })}
    ${t(LX + LL - 12, y + 27, montant, { taille: 12.5, couleur, poids: 700, ancre: 'end' })}
    ${entree
      ? action(LX + 54, y + 54, 56, 'Classer', VERT) + action(LX + 116, y + 54, 64, 'Virem…', INTERNE) + action(LX + 186, y + 54, 58, 'Garder', APP.second)
      : action(LX + 54, y + 54, 84, 'Classer', VERT) + action(LX + 144, y + 54, 100, 'Virement int…', INTERNE)}`;
  const listeY = SY + 124;
  const tete = `${retour('À vérifier')}
    ${t(SX + 18, SY + 74, 'Ces opérations n’ont pas été reconnues.', { taille: 11, couleur: APP.second })}
    ${t(SX + 18, SY + 89, 'Donne-leur une catégorie : les prochaines', { taille: 11, couleur: APP.second })}
    ${t(SX + 18, SY + 104, 'du même marchand suivront.', { taille: 11, couleur: APP.second })}`;
  // L'état à quatre : les deux lignes du marchand s'allument puis s'effacent.
  const efface = (k, de) => `<g>
      <rect x="${LX + 4}" y="${listeY + k * PAS + 4}" width="${LL - 8}" height="${PAS - 8}" rx="12" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.7" opacity="0">${visible(C, de, T.liste2, 0.003)}</rect>
      <rect x="${LX}" y="${listeY + k * PAS}" width="${LL}" height="${PAS}" fill="${APP.carte}" opacity="0">${fondu('opacity', C, [[0, 0], [de + 0.012, 0], [T.liste2 - 0.002, 1], [T.liste2, 0], [1, 0]])}</rect>
      ${g(de, T.liste2, `<rect x="${LX + 50}" y="${listeY + k * PAS + 50}" width="${LL - 56}" height="32" fill="#1F2A20"/>` + t(LX + 54, listeY + k * PAS + 71, '→ Loisirs › Hobbies', { taille: 11.5, couleur: LOISIRS, poids: 700 }), 0.003)}
    </g>`;
  ecran += g(T.liste, T.fiche, tete);
  ecran += g(T.liste, T.liste2, `
    ${carteApp(LX, listeY, LL, 4 * PAS)}
    ${ligne(listeY, ops.legall, false)}${ligne(listeY + PAS, ops.gocard, true)}${ligne(listeY + 2 * PAS, ops.sept, true)}${ligne(listeY + 3 * PAS, ops.aout, true)}
    ${efface(2, T.classe)}${efface(3, T.suit - 0.012)}
    ${toucher(LX + 96, listeY + 2 * PAS + 67, C, T.classer)}`);
  ecran += g(T.liste2, T.liste3, `
    ${carteApp(LX, listeY, LL, 2 * PAS)}
    ${ligne(listeY, ops.legall, false)}${ligne(listeY + PAS, ops.gocard, true)}
    <rect x="${LX}" y="${listeY}" width="${LL}" height="${PAS}" rx="16" fill="${APP.carte}" opacity="0">${fondu('opacity', C, [[0, 0], [T.garder + 0.015, 0], [T.liste3 - 0.004, 1], [T.liste3, 0], [1, 0]])}</rect>
    ${toucher(LX + 215, listeY + 67, C, T.garder)}`);
  ecran += g(T.liste3, T.fiche, `
    ${carteApp(LX, listeY, LL, PAS)}
    ${ligne(listeY, ops.gocard, false)}`);

  // Le choix de la catégorie : une carte au centre, Loisirs, puis Hobbies.
  const racines = [
    ['Courses', COURSES], ['Restaurants et sorties', '#FFC857'], ['Logement', LOGEMENT], ['Transports', '#9B8CFF'],
    ['Abonnements', '#FF8FD1'], ['Shopping', '#FF9F5A'], ['Santé', '#4DE2D0'], ['Soins et beauté', '#F5A3FF'], ['Loisirs', LOISIRS],
  ];
  const DX = SX + 14, DL = SL - 28, DY = SY + 70;
  const rond = (x, y, c) => `<rect x="${x}" y="${y}" width="24" height="24" rx="7" fill="${c}" fill-opacity="0.18" stroke="${c}" stroke-opacity="0.5"/>`;
  ecran += g(T.choix, T.classe, `
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000" fill-opacity="0.7"/>
    <rect x="${DX}" y="${DY}" width="${DL}" height="420" rx="22" fill="${SURFACE}"/>
    ${g(T.choix, T.sous, `${racines.map(([n, c], i) => `${rond(DX + 16, DY + 16 + i * 44, c)}
      ${t(DX + 52, DY + 33 + i * 44, n, { taille: 13, couleur: APP.texte, poids: 700 })}
      <path d="M${DX + DL - 26} ${DY + 25 + i * 44} l5 5 l5 -5" fill="none" stroke="${APP.discret}" stroke-width="1.6"/>`).join('')}
      ${toucher(DX + 80, DY + 16 + 8 * 44 + 12, C, T.loisirs)}`)}
    ${g(T.sous, T.classe, `${rond(DX + 16, DY + 16, LOISIRS)}
      ${t(DX + 52, DY + 33, 'Loisirs', { taille: 13, couleur: APP.texte, poids: 700 })}
      <path d="M${DX + DL - 26} ${DY + 30} l5 -5 l5 5" fill="none" stroke="${APP.discret}" stroke-width="1.6"/>
      ${['Sport et activités', 'Sports d’hiver', 'Voyages et vacances', 'Hôtels et hébergement', 'Sorties culturelles', 'Cinéma et concerts', 'Divertissements', 'Hobbies'].map((n, i) => `
        <circle cx="${DX + 58}" cy="${DY + 76 + i * 40}" r="4" fill="${LOISIRS}" fill-opacity="0.8"/>
        ${t(DX + 74, DY + 80 + i * 40, n, { taille: 12.5, couleur: APP.texte })}`).join('')}
      <rect x="${DX + 8}" y="${DY + 56 + 7 * 40}" width="${DL - 16}" height="40" rx="10" fill="${VERT}" fill-opacity="0.12" stroke="${VERT}" stroke-opacity="0.6" opacity="0">${visible(C, T.hobbies - 0.006, T.classe, 0.003)}</rect>
      ${toucher(DX + 110, DY + 76 + 7 * 40, C, T.hobbies)}`)}`);

  // 3. La fiche de l'opération : Renommer.
  const nomAvant = 'Sumup Atelier Kernevel', nomApres = 'Atelier Kernevel';
  const deux = (x, y, avant, apres, opts, bascule = T.renomme) =>
    g(T.fiche, bascule, t(x, y, avant, opts)) + g(bascule, T.synchro, t(x, y, apres, opts));
  const LCX = SX + 12, LCL = SL - 24;
  ecran += g(T.fiche, T.synchro, `
    ${t(SX + 16, SY + 48, '‹', { taille: 24, couleur: APP.texte })}
    ${tuile(SX + SL / 2 - 26, SY + 30, 52, LOISIRS, G.loisirs)}${coche(SX + SL / 2 + 24, SY + 80, 8)}
    ${t(SX + SL / 2, SY + 124, '-18,50 €', { taille: 28, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(SX + SL / 2, SY + 146, 'PAIEMENT PAR CARTE X0000 SUMUP *ATELIER…', { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
    ${t(SX + SL / 2, SY + 160, 'Mardi 8 septembre 2026 · Compte courant', { taille: 9.5, couleur: APP.discret, ancre: 'middle' })}
    ${carteApp(LCX, SY + 176, LCL, 170)}
    ${t(LCX + 16, SY + 200, 'CLASSEMENT', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="2"' })}
    ${[['Nom', null], ['Mouvement', 'Dépense'], ['Catégorie', 'Loisirs › Hobbies']].map(([n, v], i) => {
      const y = SY + 232 + i * 40;
      return `<line x1="${LCX + 14}" y1="${y - 22}" x2="${LCX + LCL - 14}" y2="${y - 22}" stroke="${APP.trait}"/>
        ${t(LCX + 16, y, n, { taille: 12, couleur: APP.second, poids: 600 })}
        ${v ? t(LCX + LCL - 16, y, v, { taille: 12, couleur: i === 2 ? LOISIRS : APP.texte, poids: 700, ancre: 'end' })
          : deux(LCX + LCL - 16, y, nomAvant, nomApres, { taille: 12, couleur: APP.texte, poids: 700, ancre: 'end' })}`;
    }).join('')}
    <rect x="${LCX}" y="${SY + 358}" width="${LCL}" height="84" rx="14" fill="${VERT}" fill-opacity="0.05" stroke="${VERT}" stroke-opacity="0.15"/>
    <path d="M${LCX + 14} ${SY + 378} l4 4 l8 -8" fill="none" stroke="${VERT}" stroke-width="2" stroke-linecap="round"/>
    ${['Reclassée à la main. Les prochaines', 'opérations « Sumup Atelier Kernevel »', 'iront d’elles-mêmes dans Hobbies.'].map((s, i) =>
      t(LCX + 34, SY + 382 + i * 18, s, { taille: 11, couleur: APP.second })).join('')}
    ${carteApp(LCX, SY + 452, LCL, 46)}${t(LCX + 16, SY + 480, 'Répétition', { taille: 12, couleur: APP.second, poids: 600 })}${t(LCX + LCL - 16, SY + 480, 'Aucune', { taille: 12, couleur: APP.texte, poids: 700, ancre: 'end' })}
    <rect x="${LCX}" y="${SY + 510}" width="${LCL}" height="42" rx="21" fill="${VERT}" fill-opacity="0.08" stroke="${VERT}" stroke-opacity="0.4"/>
    <circle cx="${SX + SL / 2 - 44}" cy="${SY + 531}" r="7" fill="none" stroke="${VERT}" stroke-width="1.8"/><path d="M${SX + SL / 2 - 47} ${SY + 531} l2 2 l4 -4" fill="none" stroke="${VERT}" stroke-width="1.6"/>
    ${t(SX + SL / 2 - 30, SY + 536, 'Pointée', { taille: 13.5, couleur: VERT, poids: 800 })}
    ${toucher(LCX + LCL - 70, SY + 228, C, T.nom)}`);
  // La carte Renommer.
  const RY = SY + 60;
  ecran += g(T.renommer, T.renomme, `
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000" fill-opacity="0.7"/>
    <rect x="${SX + 12}" y="${RY}" width="${SL - 24}" height="222" rx="22" fill="${SURFACE}"/>
    ${t(SX + 30, RY + 36, 'Renommer', { taille: 17, couleur: APP.texte, poids: 800 })}
    ${['Toutes les opérations', '« Sumup Atelier Kernevel » prendront', 'ce nom, les prochaines aussi.'].map((s, i) =>
      t(SX + 30, RY + 58 + i * 16, s, { taille: 11, couleur: APP.second })).join('')}
    <rect x="${SX + 28}" y="${RY + 104}" width="${SL - 56}" height="40" rx="10" fill="#2C2C2C"/>
    <line x1="${SX + 30}" y1="${RY + 143}" x2="${SX + SL - 30}" y2="${RY + 143}" stroke="${VERT}" stroke-width="2"/>
    ${g(T.renommer, T.efface, `<rect x="${SX + 38}" y="${RY + 112}" width="${160}" height="24" fill="${VERT}" fill-opacity="0.3" opacity="0">${visible(C, T.efface - 0.012, T.efface, 0.002)}</rect>${t(SX + 40, RY + 130, nomAvant, { taille: 14, couleur: APP.texte })}`)}
    ${frappe(SX + 40, RY + 130, nomApres, C, T.tape[0], T.tape[1], { taille: 14, couleur: APP.texte })}
    ${t(SX + 118, RY + 190, 'Annuler', { taille: 12.5, couleur: VERT, poids: 700, ancre: 'middle' })}
    <rect x="${SX + 152}" y="${RY + 168}" width="${SL - 184}" height="36" rx="18" fill="${VERT}"/>
    ${t(SX + 152 + (SL - 184) / 2, RY + 191, 'Enregistrer', { taille: 12.5, couleur: '#000', poids: 800, ancre: 'middle' })}
    ${toucher(SX + 200, RY + 186, C, T.enregistrer)}`);

  // 4. La synchro suivante : la nouvelle arrive classée et nommée.
  const jourTete = (y, s, somme) => `${t(SX + 22, y, s, { taille: 11.5, couleur: APP.second, poids: 700 })}${t(SX + SL - 22, y, somme, { taille: 11.5, couleur: APP.discret, ancre: 'end' })}`;
  const opLigne = (y, nom, montant, c, glyphe) => `${tuile(LX + 14, y + 10, 32, c, glyphe)}
    ${t(LX + 58, y + 25, nom, { taille: 13, couleur: APP.texte, poids: 700 })}
    ${t(LX + 58, y + 41, 'Compte courant', { taille: 10.5, couleur: APP.discret })}
    ${t(LX + LL - 14, y + 25, montant, { taille: 12.5, couleur: APP.texte, poids: 700, ancre: 'end' })}`;
  const groupe = (y, jour, somme, nom, montant, c, glyphe) => `${jourTete(y, jour, somme)}${carteApp(LX, y + 10, LL, 54)}${opLigne(y + 10, nom, montant, c, glyphe)}`;
  const enTete = `${t(SX + 18, SY + 40, 'OCTOBRE 2026', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="2"' })}
    ${t(SX + 18, SY + 66, 'Opérations', { taille: 22, couleur: APP.texte, poids: 800 })}
    <rect x="${SX + 12}" y="${SY + 82}" width="170" height="38" rx="19" fill="${SURFACE}"/>
    <circle cx="${SX + 32}" cy="${SY + 100}" r="5.5" fill="none" stroke="${APP.second}" stroke-width="1.8"/><path d="M${SX + 36} ${SY + 104} l4 4" stroke="${APP.second}" stroke-width="1.8" stroke-linecap="round"/>
    ${t(SX + 46, SY + 105, 'Chercher un nom, une…', { taille: 11, couleur: APP.discret })}
    <rect x="${SX + 190}" y="${SY + 82}" width="${SL - 202}" height="38" rx="19" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.35"/>
    ${t(SX + 190 + (SL - 202) / 2, SY + 105, '+ Espèces', { taille: 11.5, couleur: VERT, poids: 700, ancre: 'middle' })}`;
  ecran += g(T.synchro, T.fin, enTete);
  ecran += g(T.synchro, T.arrive, `
    <circle cx="${SX + 26}" cy="${SY + 146}" r="5" fill="none" stroke="${APP.discret}" stroke-width="1.6" stroke-dasharray="20 12"><animateTransform attributeName="transform" type="rotate" from="0 ${SX + 26} ${SY + 146}" to="360 ${SX + 26} ${SY + 146}" dur="1s" repeatCount="indefinite"/></circle>
    ${t(SX + 38, SY + 150, 'Synchronisation…', { taille: 11, couleur: APP.discret })}
    ${groupe(SY + 188, 'Lundi 5 octobre', '-520,00 €', 'Foncia Loyer', '-520,00 €', LOGEMENT, G.logement)}
    ${groupe(SY + 272, 'Vendredi 2 octobre', '-54,20 €', 'Biocoop Vannes', '-54,20 €', COURSES, G.courses)}`);
  ecran += g(T.arrive, T.fin, `
    ${groupe(SY + 148, 'Mercredi 7 octobre', '-31,00 €', nomApres, '-31,00 €', LOISIRS, G.loisirs)}
    <rect x="${LX}" y="${SY + 158}" width="${LL}" height="54" rx="16" fill="none" stroke="${VERT}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, T.arrive, T.arrive + 0.08, 0.01)}</rect>
    ${groupe(SY + 232, 'Lundi 5 octobre', '-520,00 €', 'Foncia Loyer', '-520,00 €', LOGEMENT, G.logement)}
    ${groupe(SY + 316, 'Vendredi 2 octobre', '-54,20 €', 'Biocoop Vannes', '-54,20 €', COURSES, G.courses)}`);
  corps += `<g clip-path="url(#ecranApprend)">${ecran}</g>`;

  // ---------------------------------------------------- à droite : la mémoire
  const RX = 420, RL = 800;
  // Les cinq temps du récit.
  const temps = [
    ['Repérée', 'dans À vérifier', 0, T.classer + 0.01],
    ['Classée', 'la règle s’écrit', T.classer + 0.01, T.garder - 0.015],
    ['Gardée', 'une entrée reçue', T.garder - 0.015, T.fiche],
    ['Renommée', 'tout le marchand', T.fiche, T.synchro],
    ['La suivante', 'classée seule', T.synchro, 0.996],
  ];
  const TL = 148, TG = (RL - 5 * TL) / 4;
  temps.forEach(([titre, sous, de, a], k) => {
    const x = RX + k * (TL + TG), y = 80;
    corps += `<rect x="${x}" y="${y}" width="${TL}" height="54" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${y}" width="${TL}" height="54" rx="12" fill="${VERT}" fill-opacity="0.07" stroke="${VERT}" stroke-opacity="0.8" opacity="0">${visible(C, de, a, 0.006)}</rect>
      <circle cx="${x + 22}" cy="${y + 27}" r="12" fill="${FOND}" stroke="${FIL}" stroke-width="2"/>
      <circle cx="${x + 22}" cy="${y + 27}" r="12" fill="${VERT}" opacity="0">${visible(C, de, 0.996, 0.006)}</circle>
      ${t(x + 22, y + 31.5, String(k + 1), { taille: 12, couleur: TEXTE, police: MONO, poids: 700, ancre: 'middle' })}
      ${g(de, 0.996, t(x + 22, y + 31.5, String(k + 1), { taille: 12, couleur: '#000', police: MONO, poids: 800, ancre: 'middle' }), 0.006)}
      ${t(x + 42, y + 24, titre, { taille: 13.5, couleur: TITRE, poids: 700 })}
      ${t(x + 42, y + 41, sous, { taille: 11, couleur: TEXTE })}`;
    if (k < 4) corps += `<path d="M${x + TL + 3} ${y + 27} h${TG - 6}" stroke="${FIL}" stroke-width="2"/>`;
  });

  // La clé du marchand, tirée du libellé.
  corps += t(RX, 170, 'LA CLÉ DU MARCHAND', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const morceau = (s, c) => `<tspan fill="${c}">${esc(s)}</tspan>`;
  corps += `<text x="${RX}" y="196" font-family="${MONO}" font-size="12.5">${morceau('PAIEMENT PAR CARTE X0000 ', DISCRET)}${morceau('SUMUP', VERT)}${morceau(' *', DISCRET)}${morceau('ATELIER KERNEVEL', VERT)}${morceau(' 07/09', DISCRET)}</text>`;
  corps += `<path d="M${RX + 408} 191 h26" stroke="${FIL}" stroke-width="2"/><path d="M${RX + 430} 186 l5 5 l-5 5" fill="none" stroke="${FIL}" stroke-width="2"/>`;
  corps += `<rect x="${RX + 446}" y="176" width="200" height="28" rx="8" fill="${VERT}" fill-opacity="0.1" stroke="${VERT}" stroke-opacity="0.5"/>`;
  corps += `<text x="${RX + 546}" y="195" font-family="${MONO}" font-size="12.5" font-weight="700" fill="${VERT}" text-anchor="middle">SUMUP ATELIER KERNEVEL</text>`;
  corps += t(RX + 660, 195, 'la même chaque mois', { taille: 12, couleur: DISCRET });

  // Ce que l'application retient : la règle, le nom.
  const MY = 222, ML = 390, MH = 84;
  const memoire = (x, titre, vide, valeur, couleurValeur, sous, de) => `
    <rect x="${x}" y="${MY}" width="${ML}" height="${MH}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
    <rect x="${x}" y="${MY}" width="${ML}" height="${MH}" rx="13" fill="${couleurValeur}" fill-opacity="0.05" stroke="${couleurValeur}" stroke-opacity="0.3"/>
    <rect x="${x}" y="${MY}" width="${ML}" height="${MH}" rx="13" fill="none" stroke="${couleurValeur}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, de, de + 0.06, 0.006)}</rect>
    ${t(x + 20, MY + 26, titre, { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' })}
    ${g(0.004, de, t(x + 20, MY + 54, vide, { taille: 13, couleur: DISCRET, extra: 'font-style="italic"' }))}
    ${g(de, 0.996, `<text x="${x + 20}" y="${MY + 52}" font-family="${MONO}" font-size="12" fill="${TITRE}">SUMUP ATELIER KERNEVEL</text>
      <path d="M${x + 190} ${MY + 48} h18 m-5 -5 l5 5 l-5 5" fill="none" stroke="${FIL}" stroke-width="2"/>
      ${t(x + 218, MY + 53, valeur, { taille: 14, couleur: couleurValeur, poids: 700 })}
      ${t(x + 20, MY + 72, sous, { taille: 11.5, couleur: TEXTE })}`, 0.006)}`;
  // La clé reste en capitales, telle qu'elle est en base : elle ne se traduit pas.
  corps += memoire(RX, 'RÈGLE APPRISE', 'aucune règle pour ce marchand', 'Loisirs › Hobbies', LOISIRS, 'passe avant le dictionnaire, à chaque import', T.classe);
  corps += memoire(RX + RL - ML, 'NOM CHOISI', 'le nom tiré du libellé', nomApres, BLEU, 'repris par chaque opération qui arrive', T.renomme);

  // Les opérations de ce marchand.
  corps += t(RX, 340, 'LES OPÉRATIONS DE CE MARCHAND', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const OY = 354, OH = 62, OP = 72;
  const badge = (x, y, texte, c) => `<rect x="${x}" y="${y}" width="128" height="26" rx="13" fill="${c}" fill-opacity="0.12" stroke="${c}" stroke-opacity="0.55"/>
    ${t(x + 64, y + 17.5, texte, { taille: 11.5, couleur: c, poids: 700, ancre: 'middle' })}`;
  const rangee = (k, date, montant, etats) => {
    const y = OY + k * OP;
    let s = `<rect x="${RX}" y="${y}" width="${RL}" height="${OH}" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      ${t(RX + 20, y + 36, date, { taille: 12.5, couleur: TEXTE, police: MONO })}
      ${t(RX + RL - 20, y + 37, montant, { taille: 14, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' })}`;
    // Chaque état : [de, a, catégorie, couleur, glyphe, badge, couleur du badge, pointée].
    for (const [de, a, cat, c, glyphe, texte, cb, pointee] of etats) {
      s += g(de, a, `${tuile(RX + 100, y + 15, 32, c, glyphe)}${pointee ? coche(RX + 130, y + 45, 7) : ''}
        ${t(RX + 146, y + 48, cat, { taille: 12, couleur: c, poids: 600 })}
        ${badge(RX + 470, y + 18, texte, cb)}
        ${t(RX + 616, y + 36, pointee ? '✓ pointée' : 'pas pointée', { taille: 12, couleur: pointee ? VERT : DISCRET, poids: pointee ? 700 : 400 })}`, 0.006);
      if (de <= 0.004) s += `<rect x="${RX}" y="${y}" width="${RL}" height="${OH}" rx="12" fill="none" stroke="${OR}" stroke-opacity="0.5" opacity="0">${visible(C, 0.004, a, 0.006)}</rect>`;
    }
    return s;
  };
  const nom = (k, de) => {
    const y = OY + k * OP + 29;
    const o = { taille: 14, couleur: TITRE, poids: 700 };
    return (de < T.renomme ? g(de, T.renomme, t(RX + 146, y, nomAvant, o), 0.006) : '') + g(Math.max(de, T.renomme), 0.996, t(RX + 146, y, nomApres, o), 0.006);
  };
  const aClasser = ['À classer', OR, G.aide, 'à vérifier', OR, false];
  corps += rangee(0, '12 août', '-22,00', [
    [0.004, T.suit, ...aClasser],
    [T.suit, 0.996, 'Loisirs › Hobbies', LOISIRS, G.loisirs, 'suit la règle', BLEU, false],
  ]) + nom(0, 0.004);
  corps += rangee(1, '8 sept.', '-18,50', [
    [0.004, T.classe, ...aClasser],
    [T.classe, 0.996, 'Loisirs › Hobbies', LOISIRS, G.loisirs, 'à la main', VERT, true],
  ]) + nom(1, 0.004);
  // La troisième n'existe pas encore : un emplacement en pointillés.
  const y3 = OY + 2 * OP;
  corps += `<g opacity="1">${fondu('opacity', C, [[0, 1], [T.arrive - 0.01, 1], [T.arrive, 0], [0.996, 0], [1, 1]])}
    <rect x="${RX}" y="${y3}" width="${RL}" height="${OH}" rx="12" fill="none" stroke="${FIL}" stroke-width="1.5" stroke-dasharray="6 6"/>
    ${t(RX + RL / 2, y3 + 36, 'la prochaine de ce marchand, à une synchro suivante', { taille: 13, couleur: DISCRET, ancre: 'middle' })}
  </g>`;
  corps += g(T.arrive, 0.996, rangee(2, '7 oct.', '-31,00', [[T.arrive, 0.996, 'Loisirs › Hobbies', LOISIRS, G.loisirs, 'règle apprise', BLEU, false]]) + nom(2, T.arrive), 0.006);
  corps += `<rect x="${RX}" y="${y3}" width="${RL}" height="${OH}" rx="12" fill="none" stroke="${VERT}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, T.arrive, T.arrive + 0.07, 0.008)}</rect>`;
  // Les billes : la règle descend vers la ligne d'août, puis la règle et le
  // nom vers celle d'octobre.
  const passe = (d, de, a, c) => `<g opacity="0">${visible(C, de, a + 0.004, 0.003)}${bille(d, C, '0;0;1;1', `0;${de};${a};1`, c, 5)}</g>`;
  corps += passe(`M${RX} ${MY + MH / 2} H${RX - 16} V${OY + 31} H${RX + 116}`, T.classe + 0.004, T.suit, LOISIRS);
  corps += passe(`M${RX} ${MY + MH / 2} H${RX - 16} V${y3 + 31} H${RX + 116}`, T.arrive - 0.03, T.arrive, LOISIRS);
  corps += passe(`M${RX + RL} ${MY + MH / 2} H${RX + RL + 16} V${y3 + 31} H${RX + RL - 2}`, T.arrive - 0.03, T.arrive, BLEU);
  // Le renommage balaie les trois lignes.
  corps += `<rect x="${RX + 136}" y="${OY + 4}" width="300" height="${OP + OH - 8}" rx="10" fill="${BLEU}" fill-opacity="0.08" stroke="${BLEU}" stroke-opacity="0.5" opacity="0">${visible(C, T.renomme, T.renomme + 0.06, 0.006)}</rect>`;

  // Trois règles à retenir.
  const NY = 590, NL = 256, NG = (RL - 3 * NL) / 2;
  const notes = [
    ['Garder', ['Une entrée reçue peut garder ce', 'qui est proposé : elle quitte la liste.'], APP.second, [T.garder - 0.015, T.fiche]],
    ['Pointer', ['Classer ou garder pointe l’opération :', 'une coche verte, vérifiée.'], VERT, [T.classe, T.garder - 0.015]],
    ['Déjà classée à la main', ['Une règle ne la touche plus :', 'la main passe toujours avant.'], OR, [T.suit, T.garder - 0.015]],
  ];
  notes.forEach(([titre, lignes, c, [de, a]], k) => {
    const x = RX + k * (NL + NG);
    corps += `<rect x="${x}" y="${NY}" width="${NL}" height="86" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${NY}" width="${NL}" height="86" rx="12" fill="none" stroke="${c}" stroke-opacity="0.8" opacity="0">${visible(C, de, a, 0.006)}</rect>
      <rect x="${x}" y="${NY}" width="${NL}" height="86" rx="12" fill="${c}" fill-opacity="0.05" stroke="${c}" stroke-opacity="0.3"/>
      ${t(x + 18, NY + 28, titre, { taille: 13.5, couleur: TITRE, poids: 700 })}
      ${lignes.map((s, i) => t(x + 18, NY + 50 + i * 18, s, { taille: 12, couleur: TEXTE })).join('')}`;
  });

  corps += t(RX, 712, 'Renommer ne touche pas à la clé : la règle, le nom et la répétition restent attachés au marchand.', { taille: 13, couleur: DISCRET });

  svg('apprentissage.svg', 1280, 740, corps,
    'À vérifier, et la correction apprise, sur un téléphone animé. L’accueil signale 4 opérations à vérifier. La liste À vérifier montre celles que rien n’a reconnues, chacune avec Classer et Virement interne, et Garder pour une entrée reçue. On classe Sumup Atelier Kernevel du 8 septembre dans Loisirs, Hobbies : la correction devient une règle attachée à la clé du marchand, SUMUP ATELIER KERNEVEL, tirée du libellé PAIEMENT PAR CARTE X0000 SUMUP *ATELIER KERNEVEL 07/09. L’opération est classée à la main et pointée ; celle du 12 août, du même marchand et pas classée à la main, suit la règle, et les deux quittent la liste. On garde ensuite le remboursement de 25 euros reçu, qui quitte la liste lui aussi. Sur la fiche de l’opération, Renommer en Atelier Kernevel renomme toutes les opérations du marchand, passées et à venir. À la synchro suivante, l’opération du 7 octobre arrive déjà classée dans Hobbies par la règle apprise, déjà nommée Atelier Kernevel, sans passer par À vérifier. Une opération classée à la main n’est plus jamais touchée par une règle.');
};

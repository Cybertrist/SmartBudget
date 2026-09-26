// Lier un remboursement, dans les deux sens.
//
// À gauche, le téléphone : d'abord depuis la dépense (sa fiche, la ligne
// Remboursement, l'écran « Associer à un remboursement », Valider), puis
// depuis l'entrée (« Lier des dépenses », la jauge Réparti qui se
// remplit). À droite, les étapes, la frise des dates et ce que le bilan
// compte avant et après le lien.
//
// Tout suit le code : remboursementsPossibles (deux mois avant la dépense,
// deux mois après), depensesRemboursables (deux mois avant l'entrée, un
// mois après ; chaque case cochée propose ce qui reste à répartir),
// rembourser (la part est le plus petit des deux restes) et calculerBilan (la part
// liée sort des entrées et se retranche de la dépense, chacune dans son
// mois).
module.exports = (O) => {
  const { svg, t, visible, fondu, toucher, P, APP, MONO, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, FOND, VERT, BLEU, ROSE, ROUGE } = O;
  const C = 36;
  const MENTHE = '#7FE0A8';
  let corps = '';
  corps += t(60, 52, 'LIER UN REMBOURSEMENT', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(318, 52, 'Depuis la dépense ou depuis l’entrée : la dépense ne compte plus que son reste, l’entrée n’est plus un revenu.', { taille: 14 });

  // Les instants : A depuis la dépense, B depuis l'entrée.
  const A1 = [0.004, 0.1], A2 = [0.1, 0.3], A3 = [0.3, 0.48];
  const B1 = [0.48, 0.56], B2 = [0.56, 0.84], B3 = [0.84, 0.996];
  const tapLigne = 0.075, tapChoix = 0.17, tapValider = 0.26;
  const tapLier = 0.53, tapTrain = 0.6, tapChamp = 0.655, retape = 0.685, tapResto = 0.735, tapBouton = 0.8;

  // ---------------------------------------------------------------- téléphone
  const PX = 60, PY = 96, PL = 316, PH = 640;
  const SX = PX + 12, SY = PY + 16, SL = PL - 24, SH = PH - 32;
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="40" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
    <clipPath id="ecranRembourse"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28"/></clipPath>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="28" fill="${APP.fond}"/>
    <rect x="${PX + PL / 2 - 34}" y="${PY + 6}" width="68" height="5" rx="2.5" fill="#1B222C"/>`;

  const ecran = ([de, a], contenu) => `<g opacity="0">${visible(C, de, a, 0.004)}${contenu}</g>`;
  const durant = (de, a, contenu) => `<g opacity="0">${visible(C, de, a, 0.003)}${contenu}</g>`;
  const barre = (titre, taille = 17) =>
    t(SX + 18, SY + 46, '‹', { taille: 24, couleur: APP.texte }) + t(SX + 38, SY + 46, titre, { taille, couleur: APP.texte, poids: 800 });
  const carteApp = (y, h, fond = APP.carte) => `<rect x="${SX + 12}" y="${SY + y}" width="${SL - 24}" height="${h}" rx="16" fill="${fond}"/>`;
  const surtitre = (y, s, droite = '') =>
    t(SX + 28, SY + y, s, { taille: 10.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.5"' }) +
    (droite ? t(SX + SL - 28, SY + y, droite, { taille: 11, couleur: APP.discret, ancre: 'end' }) : '');
  // La petite icône carrée des lignes de la fiche.
  const icone = (y, dessin) => `<rect x="${SX + 26}" y="${SY + y - 14}" width="28" height="28" rx="9" fill="#FFFFFF" fill-opacity="0.05"/>
    <g transform="translate(${SX + 30},${SY + y - 10}) scale(0.72)">${dessin(APP.second)}</g>`;
  const ligne = (y, dessin, libelle, valeur, couleur = APP.second) => `${icone(y, dessin)}
    ${t(SX + 64, SY + y + 4.5, libelle, { taille: 13, couleur: APP.texte, poids: 600 })}
    ${t(SX + SL - 40, SY + y + 4.5, valeur, { taille: 12.5, couleur, poids: 700, ancre: 'end' })}
    ${t(SX + SL - 26, SY + y + 5, '›', { taille: 15, couleur: APP.discret, ancre: 'middle' })}`;
  const interrupteur = (y, libelle, dessin) => `${icone(y, dessin)}
    ${t(SX + 64, SY + y + 4.5, libelle, { taille: 13, couleur: APP.texte, poids: 600 })}
    <rect x="${SX + SL - 70}" y="${SY + y - 11}" width="42" height="22" rx="11" fill="#2A2A2A" stroke="#555555"/>
    <circle cx="${SX + SL - 59}" cy="${SY + y}" r="6.5" fill="#8A8A8A"/>`;
  const sep = (y) => `<line x1="${SX + 26}" y1="${SY + y}" x2="${SX + SL - 26}" y2="${SY + y}" stroke="${APP.trait}"/>`;

  // Des pictogrammes, dans une grille de 28.
  const note = (c) => `<path d="M11 21 V7 L22 5 V18" fill="none" stroke="${c}" stroke-width="2.2" stroke-linejoin="round"/><circle cx="8" cy="21" r="3.2" fill="${c}"/><circle cx="19" cy="18" r="3.2" fill="${c}"/>`;
  const recu = (c) => `<path d="M21 7 L8 20 M8 11 V20 H17" fill="none" stroke="${c}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`;
  const echange = (c) => `<path d="M5 10 H21 L17 6 M23 18 H7 L11 22" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`;
  const etiquette = (c) => `<path d="M4 6 H15 L24 14 L15 22 H4 Z" fill="none" stroke="${c}" stroke-width="2.2" stroke-linejoin="round"/><circle cx="9" cy="14" r="1.8" fill="${c}"/>`;
  const oeil = (c) => `<path d="M3 14 C7 7 21 7 25 14 C21 21 7 21 3 14 Z M6 5 L22 23" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"/>`;
  const tuile = (y, couleur, dessin) => `<rect x="${SX + SL / 2 - 22}" y="${SY + y}" width="44" height="44" rx="14" fill="${couleur}" fill-opacity="0.16" stroke="${couleur}" stroke-opacity="0.45"/>
    <g transform="translate(${SX + SL / 2 - 14},${SY + y + 8})">${dessin(couleur)}</g>`;
  // Le haut d'une fiche, sur téléphone : tuile, montant, titre, date.
  const tete = (titre, couleur, dessin, montant, date) => `${barre(titre)}
    ${tuile(64, couleur, dessin)}
    ${t(SX + SL / 2, SY + 142, montant, { taille: 28, couleur: APP.texte, poids: 800, ancre: 'middle' })}
    ${t(SX + SL / 2, SY + 164, titre, { taille: 13.5, couleur: APP.texte, poids: 700, ancre: 'middle' })}
    ${t(SX + SL / 2, SY + 182, date, { taille: 10.5, couleur: APP.discret, ancre: 'middle' })}`;
  const boutonVert = (texte) => `<rect x="${SX + 14}" y="${SY + SH - 68}" width="${SL - 28}" height="48" rx="24" fill="${VERT}"/>
    ${t(SX + SL / 2, SY + SH - 39, texte, { taille: 14.5, couleur: '#000000', poids: 800, ancre: 'middle' })}`;
  const coche = (x, y) => `<rect x="${x}" y="${y}" width="18" height="18" rx="4" fill="${VERT}"/>
    <path d="M${x + 4} ${y + 9} l3.5 3.5 l7 -7.5" fill="none" stroke="#000000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`;
  const caseVide = (x, y) => `<rect x="${x + 1}" y="${y + 1}" width="16" height="16" rx="3.5" fill="none" stroke="${APP.second}" stroke-width="2"/>`;

  let ecrans = '';

  // A1 et A3 : la fiche de la dépense, avant et après le lien.
  const ficheConcert = (lie) => `${tete('Concert', '#C6F45A', note, '-90,00 €', 'Dimanche 20 septembre 2026 · Compte courant')}
    ${carteApp(196, 120)}
    ${surtitre(218, 'CLASSEMENT')}
    ${ligne(246, echange, 'Mouvement', 'Dépense')}
    ${sep(268)}
    ${ligne(290, etiquette, 'Catégorie', 'Loisirs › Ciné…', '#C6F45A')}
    ${carteApp(326, 120)}
    ${surtitre(348, 'SUIVI')}
    ${ligne(376, P.horloge, 'Répétition', 'Aucune')}
    ${sep(398)}
    ${interrupteur(420, 'Masquer de l’analyse', oeil)}
    ${carteApp(456, lie ? 92 : 58)}
    ${ligne(485, P.lien, 'Remboursement', lie ? '45,00 € reçus' : 'Aucun', lie ? VERT : APP.second)}
    ${lie ? t(SX + 28, SY + 530, 'Elle ne compte plus que pour 45,00 €.', { taille: 12, couleur: APP.discret }) : ''}`;
  ecrans += ecran(A1, `${ficheConcert(false)}
    <rect x="${SX + 12}" y="${SY + 456}" width="${SL - 24}" height="58" rx="16" fill="none" stroke="${VERT}" stroke-opacity="0.7" opacity="0">${visible(C, tapLigne - 0.012, A1[1], 0.003)}</rect>
    ${toucher(SX + 150, SY + 485, C, tapLigne)}`);
  ecrans += ecran(A3, `${ficheConcert(true)}
    <rect x="${SX + 12}" y="${SY + 456}" width="${SL - 24}" height="92" rx="16" fill="none" stroke="${VERT}" stroke-opacity="0.7" filter="url(#halo)"/>`);

  // A2 : « Associer à un remboursement », les entrées autour de la date.
  const entrees = [
    ['Vendredi 25 septembre', 'Salaire', 'Salaire', '+1 850,00 €'],
    ['Lundi 14 septembre', 'Camille Roux', 'Virements reçus', '+45,00 €'],
    ['Vendredi 21 août', 'Remise de chèque', 'Remboursements', '+120,00 €'],
  ];
  let liste = '';
  entrees.forEach(([jour, nom, sous, montant], i) => {
    const y = 126 + i * 96;
    const choisie = i === 1;
    liste += `${t(SX + 22, SY + y, jour, { taille: 12, couleur: APP.second, poids: 700 })}
      ${carteApp(y + 10, 62)}
      <circle cx="${SX + 36}" cy="${SY + y + 41}" r="8.5" fill="none" stroke="${APP.discret}" stroke-width="2"/>
      ${t(SX + 56, SY + y + 37, nom, { taille: 13.5, couleur: APP.texte, poids: 700 })}
      ${t(SX + 56, SY + y + 55, sous, { taille: 10.5, couleur: APP.discret })}
      ${t(SX + SL - 26, SY + y + 45, montant, { taille: 13, couleur: VERT, poids: 700, ancre: 'end' })}`;
    if (choisie) {
      liste += durant(tapChoix, A2[1], `<rect x="${SX + 12}" y="${SY + y + 10}" width="${SL - 24}" height="62" rx="16" fill="${VERT}" fill-opacity="0.08" stroke="${VERT}" stroke-opacity="0.6"/>
        <circle cx="${SX + 36}" cy="${SY + y + 41}" r="10" fill="${VERT}"/>
        <path d="M${SX + 31} ${SY + y + 41} l3.5 3.5 l6.5 -7" fill="none" stroke="#000000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`);
      liste += toucher(SX + 120, SY + y + 41, C, tapChoix);
    }
  });
  ecrans += ecran(A2, `${barre('Associer à un remboursement', 15.5)}
    ${['Pour « Concert », 90,00 €. Choisis l’argent reçu', 'qui la rembourse, avant ou après l’achat.'].map((l, i) => t(SX + 22, SY + 78 + i * 17, l, { taille: 12, couleur: APP.second })).join('')}
    ${liste}
    ${durant(A2[0], tapChoix, boutonVert('Aucun remboursement'))}
    ${durant(tapChoix, A2[1], boutonVert('Valider'))}
    ${toucher(SX + SL / 2, SY + SH - 44, C, tapValider)}`);

  // B1 et B3 : la fiche de l'entrée, sa carte « Rembourse ».
  const ficheLucas = (lie) => `${tete('Lucas Martin', MENTHE, recu, '+500,00 €', 'Vendredi 18 septembre 2026 · Compte courant')}
    ${carteApp(196, 120)}
    ${surtitre(218, 'CLASSEMENT')}
    ${ligne(246, echange, 'Mouvement', 'Revenu')}
    ${sep(268)}
    ${ligne(290, etiquette, 'Catégorie', 'Autres revenus…', MENTHE)}
    ${carteApp(326, 120)}
    ${surtitre(348, 'SUIVI')}
    ${interrupteur(376, 'C’est un remboursement', echange)}
    ${sep(398)}
    ${interrupteur(420, 'Masquer de l’analyse', oeil)}
    ${carteApp(456, 140)}
    ${surtitre(478, 'REMBOURSE', lie ? '2 dépenses' : '0 dépense')}
    ${lie
      ? t(SX + 28, SY + 502, '500,00 € répartis sur 500,00 €.', { taille: 12, couleur: APP.second }) +
        t(SX + 28, SY + 519, 'Reste 0,00 €.', { taille: 12, couleur: APP.second })
      : ['Si cette entrée rembourse des dépenses, lie-les :', 'elles ne compteront plus que pour leur reste', 'à charge, et elle ne comptera pas comme un revenu.']
        .map((s, i) => t(SX + 28, SY + 498 + i * 14.5, s, { taille: 10, couleur: APP.second })).join('')}
    <rect x="${SX + 26}" y="${SY + 546}" width="${SL - 52}" height="38" rx="19" fill="none" stroke="${MENTHE}" stroke-opacity="0.4"/>
    <g transform="translate(${SX + (lie ? 44 : 78)},${SY + 555}) scale(0.72)">${P.lien(MENTHE)}</g>
    ${t(SX + SL / 2 + 12, SY + 570, lie ? 'Modifier les dépenses liées' : 'Lier des dépenses', { taille: 12.5, couleur: MENTHE, poids: 700, ancre: 'middle' })}`;
  ecrans += ecran(B1, `${ficheLucas(false)}${toucher(SX + SL / 2, SY + 565, C, tapLier)}`);
  ecrans += ecran(B3, `${ficheLucas(true)}
    <rect x="${SX + 12}" y="${SY + 456}" width="${SL - 24}" height="140" rx="16" fill="none" stroke="${MENTHE}" stroke-opacity="0.7" filter="url(#halo)"/>`);

  // B2 : « Lier des dépenses », la jauge Réparti.
  const JX = SX + 16, JL = SL - 32;
  const reparti = [
    [B2[0], tapTrain, '0,00 € / 500,00 €'],
    [tapTrain, retape, '380,00 € / 500,00 €'],
    [retape, tapResto, '300,00 € / 500,00 €'],
    [tapResto, B2[1], '500,00 € / 500,00 €'],
  ];
  const depenses = [
    ['Pharmacie', '25 sept. · -23,90 €', null],
    ['Carrefour Market', '12 sept. · -64,30 €', null],
    ['Restaurant', '29 août · -260,00 €', [[tapResto, B2[1], '200,00']]],
    ['Billet de train', '8 août · -380,00 €', [[tapTrain, retape, '380,00'], [retape, B2[1], '300,00']]],
  ];
  let lignes = '';
  depenses.forEach(([nom, sous, parts], i) => {
    const y = 198 + i * 60;
    const coche_ = parts ? parts[0][0] : null;
    lignes += `<line x1="${SX + 16}" y1="${SY + y}" x2="${SX + SL - 16}" y2="${SY + y}" stroke="${APP.trait}"/>
      ${caseVide(SX + 22, SY + y + 22)}
      ${coche_ ? durant(coche_, B2[1], coche(SX + 22, SY + y + 22)) : ''}
      ${t(SX + 52, SY + y + 28, nom, { taille: 13, couleur: APP.texte, poids: 700 })}
      ${t(SX + 52, SY + y + 45, sous, { taille: 10.5, couleur: APP.discret })}`;
    if (!parts) return;
    lignes += durant(coche_, B2[1], `<line x1="${SX + SL - 104}" y1="${SY + y + 43}" x2="${SX + SL - 20}" y2="${SY + y + 43}" stroke="${APP.discret}"/>
      ${t(SX + SL - 20, SY + y + 36, '€', { taille: 12, couleur: APP.discret, ancre: 'end' })}`);
    for (const [de, a, v] of parts) {
      lignes += durant(de, a, t(SX + SL - 36, SY + y + 36, v, { taille: 13.5, couleur: APP.texte, poids: 600, ancre: 'end' }));
    }
    lignes += toucher(SX + 31, SY + y + 31, C, coche_);
    if (i === 3) {
      // Le champ touché : la part se corrige à la main.
      lignes += durant(tapChamp, retape + 0.02, `<line x1="${SX + SL - 104}" y1="${SY + y + 43}" x2="${SX + SL - 20}" y2="${SY + y + 43}" stroke="${VERT}" stroke-width="2"/>`);
      lignes += toucher(SX + SL - 64, SY + y + 32, C, tapChamp);
    }
  });
  const part = (s) => (JL * s).toFixed(1);
  ecrans += ecran(B2, `${barre('Lier des dépenses')}
    ${carteApp(64, 56, '#16231C')}
    <rect x="${SX + 26}" y="${SY + 74}" width="36" height="36" rx="11" fill="${MENTHE}" fill-opacity="0.16" stroke="${MENTHE}" stroke-opacity="0.45"/>
    <g transform="translate(${SX + 32},${SY + 80}) scale(0.86)">${recu(MENTHE)}</g>
    ${t(SX + 74, SY + 90, 'Lucas Martin', { taille: 13.5, couleur: APP.texte, poids: 700 })}
    ${t(SX + 74, SY + 107, '18 sept.', { taille: 11, couleur: APP.discret })}
    ${t(SX + SL - 26, SY + 97, '+500,00 €', { taille: 13.5, couleur: MENTHE, poids: 700, ancre: 'end' })}
    ${t(SX + 16, SY + 148, 'Réparti', { taille: 12.5, couleur: APP.second })}
    ${reparti.map(([de, a, s]) => durant(de, a, t(SX + SL - 16, SY + 148, s, { taille: 12.5, couleur: APP.texte, poids: 700, ancre: 'end' }))).join('')}
    <rect x="${JX}" y="${SY + 158}" width="${JL}" height="8" rx="4" fill="#FFFFFF" fill-opacity="0.05"/>
    <rect x="${JX}" y="${SY + 158}" width="0" height="8" rx="4" fill="${VERT}">
      <animate attributeName="width" dur="${C}s" repeatCount="indefinite" calcMode="spline"
        keyTimes="0;${tapTrain};${tapTrain + 0.012};${retape};${retape + 0.012};${tapResto};${tapResto + 0.012};1"
        values="0;0;${part(0.76)};${part(0.76)};${part(0.6)};${part(0.6)};${JL};${JL}"
        keySplines="0 0 1 1;0.3 0 0.2 1;0 0 1 1;0.3 0 0.2 1;0 0 1 1;0.3 0 0.2 1;0 0 1 1"/></rect>
    ${t(SX + 16, SY + 190, 'DÉPENSES, DEUX MOIS AVANT À UN MOIS APRÈS', { taille: 9.5, couleur: APP.second, poids: 700, extra: 'letter-spacing="0.6"' })}
    ${lignes}
    ${durant(B2[0], tapTrain, boutonVert('Enregistrer'))}
    ${durant(tapTrain, tapResto, boutonVert('Lier 1 dépense'))}
    ${durant(tapResto, B2[1], boutonVert('Lier 2 dépenses'))}
    ${toucher(SX + SL / 2, SY + SH - 44, C, tapBouton)}`);
  corps += `<g clip-path="url(#ecranRembourse)">${ecrans}</g>`;

  // ------------------------------------------------------------- les étapes
  const RX = 420, RL = 800;
  const panneau = (x, lettre, titre, couleur, [de, a], etapes) => {
    const l = 390;
    let s = `<rect x="${x}" y="96" width="${l}" height="196" rx="14" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="96" width="${l}" height="196" rx="14" fill="none" stroke="${couleur}" stroke-opacity="0.7" opacity="0">${visible(C, de, a, 0.006)}</rect>
      <circle cx="${x + 30}" cy="124" r="12" fill="${couleur}" fill-opacity="0.16" stroke="${couleur}"/>
      ${t(x + 30, 128.5, lettre, { taille: 12, couleur, police: MONO, poids: 700, ancre: 'middle' })}
      ${t(x + 52, 129, titre, { taille: 12.5, couleur, police: MONO, poids: 700, extra: 'letter-spacing="2"' })}`;
    etapes.forEach(([titreEtape, sous, [e0, e1]], i) => {
      const y = 166 + i * 44;
      s += `<circle cx="${x + 30}" cy="${y - 4}" r="10" fill="${FOND}" stroke="${FIL}" stroke-width="2"/>
        <circle cx="${x + 30}" cy="${y - 4}" r="10" fill="${couleur}" opacity="0">${visible(C, e0, e1, 0.004)}</circle>
        ${t(x + 30, y, String(i + 1), { taille: 11, couleur: TEXTE, police: MONO, poids: 700, ancre: 'middle' })}
        <g opacity="0">${visible(C, e0, e1, 0.004)}${t(x + 30, y, String(i + 1), { taille: 11, couleur: '#000000', police: MONO, poids: 800, ancre: 'middle' })}</g>
        ${t(x + 52, y - 1, titreEtape, { taille: 13.5, couleur: TITRE, poids: 700 })}
        ${t(x + 52, y + 16, sous, { taille: 11.5 })}`;
    });
    return s;
  };
  corps += panneau(RX, 'A', 'DEPUIS LA DÉPENSE', ROSE, [0.004, 0.48], [
    ['Sa fiche, ligne « Remboursement »', 'elle dit Aucun tant que rien n’est lié', A1],
    ['« Associer à un remboursement »', 'l’argent reçu deux mois avant ou après l’achat', A2],
    ['Choisir l’entrée, puis Valider', 'la part liée : le plus petit des deux restes', A3],
  ]);
  corps += panneau(RX + 410, 'B', 'DEPUIS L’ENTRÉE', MENTHE, [0.48, 0.996], [
    ['Sa fiche, « Lier des dépenses »', 'dans la carte Rembourse', B1],
    ['Cocher, puis ajuster les parts', 'chaque case propose ce qui reste à répartir', [B2[0], tapBouton]],
    ['« Lier 2 dépenses »', 'la jauge Réparti ne dépasse jamais 500 €', [tapBouton, 0.996]],
  ]);

  // ---------------------------------------------------------- la frise
  const FY = 312, FH = 190;
  corps += `<rect x="${RX}" y="${FY}" width="${RL}" height="${FH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>`;
  corps += t(RX + 24, FY + 28, 'QUAND L’ARGENT REVIENT', { taille: 12, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const J0 = Date.UTC(2026, 6, 15), X0 = RX + 30, PXJ = (RL - 60) / 133;
  const X = (m, j) => X0 + ((Date.UTC(2026, m - 1, j) - J0) / 86400000) * PXJ;
  const AXE = FY + 122;
  for (const [m, nom] of [[8, 'août'], [9, 'septembre'], [10, 'octobre'], [11, 'novembre']]) {
    const x = X(m, 1);
    corps += `<line x1="${x}" y1="${FY + 42}" x2="${x}" y2="${FY + FH - 14}" stroke="${FIL}" stroke-dasharray="2 5"/>`;
    corps += t(x + 6, FY + 52, nom, { taille: 11, couleur: DISCRET, police: MONO });
  }
  corps += `<line x1="${X0}" y1="${AXE}" x2="${RX + RL - 30}" y2="${AXE}" stroke="${FIL}" stroke-width="2"/>`;
  // La fenêtre de ce que l'écran propose.
  const fenetre = (x1, x2, couleur, texte, [de, a]) => `<g opacity="0">${visible(C, de, a, 0.006)}
    <rect x="${x1}" y="${AXE - 9}" width="${x2 - x1}" height="18" rx="9" fill="${couleur}" fill-opacity="0.12" stroke="${couleur}" stroke-opacity="0.5" stroke-dasharray="4 4"/>
    ${t(RX + RL - 24, FY + 28, texte, { taille: 12, couleur, poids: 700, ancre: 'end' })}</g>`;
  // Un point : l'entrée au-dessus de l'axe, la dépense en dessous.
  const point = (x, haut, couleur, nom, montant, [de, a]) => {
    const y = haut ? AXE - 16 : AXE + 16;
    return `<g opacity="0">${visible(C, de, a, 0.006)}
      <line x1="${x}" y1="${AXE}" x2="${x}" y2="${y}" stroke="${couleur}" stroke-width="1.5"/>
      <circle cx="${x}" cy="${y}" r="6" fill="${FOND}" stroke="${couleur}" stroke-width="2.5"/>
      ${t(x, haut ? y - 30 : y + 26, nom, { taille: 12, couleur: TITRE, poids: 700, ancre: 'middle' })}
      ${t(x, haut ? y - 14 : y + 42, montant, { taille: 11.5, couleur, police: MONO, poids: 700, ancre: 'middle' })}</g>`;
  };
  // Le lien, qui se trace de l'entrée vers la dépense.
  const lien = (xa, xb, s, a) => {
    const d = `M${xa} ${AXE - 16} C${xa} ${AXE + 4} ${xb} ${AXE - 4} ${xb} ${AXE + 16}`;
    const L = Math.ceil(Math.hypot(xb - xa, 32) * 1.3);
    return `<path d="${d}" fill="none" stroke="${VERT}" stroke-width="2.5" stroke-dasharray="${L}" stroke-dashoffset="${L}" opacity="0">
      ${fondu('stroke-dashoffset', C, [[0, L], [s, L], [s + 0.02, 0], [1, 0]])}${visible(C, s, a, 0.004)}</path>`;
  };
  const PA = [0.004, 0.48], PB = [0.48, 0.996];
  corps += fenetre(X(7, 20), X(11, 21), BLEU, 'entrées proposées : deux mois avant la dépense, deux mois après', PA);
  corps += point(X(9, 14), true, VERT, 'Camille', '+45 €', PA);
  corps += point(X(9, 20), false, ROSE, 'Concert', '-90 €', PA);
  corps += lien(X(9, 14), X(9, 20), tapValider, 0.48);
  corps += `<g opacity="0">${visible(C, tapValider + 0.02, 0.48, 0.004)}${t(X(9, 20) + 30, AXE - 26, 'reçu six jours avant l’achat', { taille: 12, couleur: VERT, poids: 700 })}</g>`;
  corps += fenetre(X(7, 18), X(10, 19), BLEU, 'dépenses proposées : deux mois avant l’entrée, un mois après', PB);
  corps += point(X(9, 18), true, VERT, 'Lucas', '+500 €', PB);
  corps += point(X(8, 8), false, ROSE, 'Train', '-380 €', PB);
  corps += point(X(8, 29), false, ROSE, 'Restaurant', '-260 €', PB);
  corps += point(X(9, 12), false, FIL, 'Carrefour', '-64,30 €', PB);
  corps += point(X(9, 25), false, FIL, 'Pharmacie', '-23,90 €', PB);
  corps += lien(X(9, 18), X(8, 8), tapBouton, 0.996) + lien(X(9, 18), X(8, 29), tapBouton, 0.996);
  corps += `<g opacity="0">${visible(C, tapBouton + 0.02, 0.996, 0.004)}${t(X(9, 18) + 30, AXE - 26, 'reçu après les achats', { taille: 12, couleur: VERT, poids: 700 })}</g>`;

  // ------------------------------------------------------ ce que compte le bilan
  const LY = 518, LH = 206;
  corps += `<rect x="${RX}" y="${LY}" width="${RL}" height="${LH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>`;
  corps += t(RX + 24, LY + 28, 'CE QUE COMPTE LE BILAN', { taille: 12, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const BL = RL - 48;
  // Une ligne : le libellé, le montant avant puis après, la barre qui fond.
  const rangee = (y, libelle, avant, apres, max, couleur, s, [de, a]) => {
    const w0 = (BL * avant) / max, w1 = (BL * apres) / max;
    const fmt = (v) => `${v} €`;
    return `<g opacity="0">${visible(C, de, a, 0.006)}
      ${t(RX + 24, y, libelle, { taille: 13, couleur: TITRE })}
      <g>${visible(C, de, s + 0.01, 0.003)}${t(RX + RL - 24, y, fmt(avant), { taille: 13.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' })}</g>
      <g opacity="0">${visible(C, s + 0.01, a, 0.003)}${t(RX + RL - 24, y, apres === 0 ? '0 €' : `reste ${apres} €`, { taille: 13.5, couleur, police: MONO, poids: 700, ancre: 'end' })}</g>
      <rect x="${RX + 24}" y="${y + 9}" width="${BL}" height="8" rx="4" fill="#1D2530"/>
      <rect x="${RX + 24}" y="${y + 9}" width="${w0}" height="8" rx="4" fill="${couleur}">
        ${fondu('width', C, [[0, w0], [s, w0], [s + 0.03, w1], [1, w1]])}</rect></g>`;
  };
  corps += rangee(LY + 60, 'Concert, dépense de septembre', 90, 45, 90, ROSE, tapValider, PA);
  corps += rangee(LY + 104, 'Camille Roux, compté en revenu de septembre', 45, 0, 90, VERT, tapValider, PA);
  corps += `<g opacity="0">${visible(C, tapValider + 0.03, 0.48, 0.006)}${t(RX + 24, LY + 188, 'Les 45 € de Camille ne sont plus un revenu : ils paient la moitié du concert.', { taille: 12.5, couleur: TEXTE })}</g>`;
  corps += rangee(LY + 56, 'Billet de train, dépense d’août', 380, 80, 500, ROSE, tapBouton, PB);
  corps += rangee(LY + 98, 'Restaurant, dépense d’août', 260, 60, 500, ROSE, tapBouton, PB);
  corps += rangee(LY + 140, 'Lucas Martin, compté en revenu de septembre', 500, 0, 500, VERT, tapBouton, PB);
  corps += `<g opacity="0">${visible(C, tapBouton + 0.03, 0.996, 0.006)}${t(RX + 24, LY + 190, 'Chaque opération reste dans son mois : août est corrigé, même payé en septembre.', { taille: 12.5, couleur: TEXTE })}</g>`;

  corps += t(640, 766, 'Une entrée peut rembourser plusieurs dépenses, une dépense l’être par plusieurs entrées : jamais plus que l’une ou l’autre.', { taille: 13, couleur: DISCRET, ancre: 'middle' });

  svg('remboursement.svg', 1280, 792, corps,
    'Lier un remboursement, dans les deux sens, sur un téléphone animé. A, depuis la dépense : sur la fiche du concert, 90 euros le 20 septembre, la ligne Remboursement dit Aucun ; la toucher ouvre Associer à un remboursement, qui propose l’argent reçu jusqu’à deux mois avant ou après l’achat. On choisit le virement de Camille Roux, 45 euros reçus le 14 septembre, six jours avant l’achat, puis Valider : la part liée est le plus petit des deux restes. La fiche affiche 45 euros reçus, elle ne compte plus que pour 45 euros, et les 45 euros de Camille ne comptent plus comme un revenu. B, depuis l’entrée : sur la fiche du virement de Lucas Martin, 500 euros le 18 septembre, la carte Rembourse propose Lier des dépenses. L’écran liste les dépenses de deux mois avant à un mois après l’entrée ; cocher le billet de train de 380 euros propose 380 euros, corrigés à 300, puis cocher le restaurant de 260 euros propose les 200 qui restent, et la jauge Réparti atteint 500 sur 500. Lier 2 dépenses : le billet ne compte plus que 80 euros, le restaurant 60, tous deux en août, et les 500 euros de Lucas ne sont pas un revenu de septembre. Une entrée peut rembourser plusieurs dépenses et une dépense être remboursée par plusieurs entrées, jamais au-delà de l’une ou de l’autre.');
};

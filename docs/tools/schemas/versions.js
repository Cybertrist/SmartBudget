// Les versions : huit en quatre jours, empilées l'une sur l'autre.
//
// Chaque version tombe sur la précédente, comme elle s'installe sur le
// téléphone : par-dessus, sans rien effacer. En bas, le socle ne bouge
// jamais : tes données, et la clé de signature, la même de 1.0.0 à 1.2.3
// (le certificat que donne chaque Release). Un fil monte de la clé et
// scelle chaque version qui arrive. À gauche, la frise : le temps monte,
// du jeudi 24 au dimanche 27 septembre. La dernière, 1.2.3, reste allumée,
// avec ses 83 tests, tous au vert.
module.exports = (O) => {
  const { svg, t, tr, esc, visible, fondu, pilule, P, MONO, SANS, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, NEON, BLEU, OR, ROSE, ROUGE, INTERNE } = O;

  const C = 26, FIN = 0.97;
  const g = (de, a, contenu, douceur = 0.006) => `<g opacity="0">${visible(C, de, a, douceur)}${contenu}</g>`;

  // Un paragraphe coupé à la largeur donnée, dans la langue du rendu.
  const chasse = (ch) => {
    if (ch === ' ' || ch === ' ') return 0.28;
    if (/[iljI.,;:'’!|()]/.test(ch)) return 0.27;
    if (/[ftr]/.test(ch)) return 0.35;
    if (/[mwMW]/.test(ch)) return 0.84;
    if (/[A-Z]/.test(ch)) return 0.65;
    if (/[0-9]/.test(ch)) return 0.56;
    return 0.51;
  };
  const largeur = (s, taille) => [...s].reduce((a, ch) => a + chasse(ch), 0) * taille;
  const couper = (s, l, taille) => {
    const insecable = s.replace(/ ([:;!?»€])/g, ' $1').replace(/« /g, '« ');
    const lignes = [''];
    for (const m of insecable.split(' ')) {
      const der = lignes[lignes.length - 1];
      const essai = der ? `${der} ${m}` : m;
      if (der && largeur(essai, taille) > l) lignes.push(m);
      else lignes[lignes.length - 1] = essai;
    }
    return lignes;
  };

  // Les icônes, dessinées en traits comme celles de P.
  const I = {
    banque: P.banque,
    reglages: (c) => `<circle cx="14" cy="14" r="4.5" fill="none" stroke="${c}" stroke-width="2"/>${[0, 1, 2, 3, 4, 5, 6, 7].map((k) => {
      const a = (k * Math.PI) / 4, x1 = 14 + 7.5 * Math.cos(a), y1 = 14 + 7.5 * Math.sin(a), x2 = 14 + 11 * Math.cos(a), y2 = 14 + 11 * Math.sin(a);
      return `<path d="M${x1.toFixed(1)} ${y1.toFixed(1)} L${x2.toFixed(1)} ${y2.toFixed(1)}" stroke="${c}" stroke-width="2.4" stroke-linecap="round"/>`;
    }).join('')}<circle cx="14" cy="14" r="8" fill="none" stroke="${c}" stroke-width="1.6"/>`,
    roue: (c) => `<circle cx="14" cy="12" r="9.5" fill="none" stroke="${c}" stroke-width="2"/><path d="M14 2.5 V21.5 M4.5 12 H23.5 M7.3 5.3 L20.7 18.7 M20.7 5.3 L7.3 18.7" stroke="${c}" stroke-width="1.3"/><path d="M10 27 L14 12 L18 27 M7 27 H21" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><circle cx="14" cy="12" r="2" fill="${c}"/>`,
    cloche: (c) => `<path d="M7 20 V13 A7 7 0 0 1 21 13 V20 L23 23 H5 Z" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/><path d="M11.5 25.5 A2.6 2.6 0 0 0 16.5 25.5 M14 3.5 V6" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
    deux: (c) => `<rect x="1.5" y="3" width="11.5" height="22" rx="3" fill="none" stroke="${c}" stroke-width="2"/><rect x="15" y="3" width="11.5" height="22" rx="3" fill="none" stroke="${c}" stroke-width="2" stroke-dasharray="3 2.4"/><circle cx="7.25" cy="21" r="1.2" fill="${c}"/><circle cx="20.75" cy="21" r="1.2" fill="${c}"/>`,
    loupe: (c) => `<circle cx="12" cy="12" r="8.5" fill="none" stroke="${c}" stroke-width="2"/><path d="M18.3 18.3 L25.5 25.5" stroke="${c}" stroke-width="2.6" stroke-linecap="round"/><path d="M7.5 11 L12 8 L16.5 11 M8.5 12.5 V15.5 M12 12.5 V15.5 M15.5 12.5 V15.5" fill="none" stroke="${c}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>`,
    bouclier: (c) => `<path d="M14 2.5 L24 6.5 V13 C24 19.5 19.5 24 14 26 C8.5 24 4 19.5 4 13 V6.5 Z" fill="none" stroke="${c}" stroke-width="2" stroke-linejoin="round"/><path d="M9.5 14 L12.8 17.3 L18.8 10.8" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`,
    salaire: (c) => `<rect x="3" y="5" width="22" height="20" rx="3" fill="none" stroke="${c}" stroke-width="2"/><path d="M3 11 H25 M9 2.5 V7 M19 2.5 V7" stroke="${c}" stroke-width="2" stroke-linecap="round"/><path d="M14 13.5 V22.5 M10.5 18.5 L14 22.5 L17.5 18.5" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`,
  };

  // De la plus ancienne à la plus récente. [numéro, jour, sous-titre,
  // couleur, icône, puces]
  const VIOLET = '#B08CFF';
  const JOURS = [['24 sept.', 'jeudi', VERT], ['25 sept.', 'vendredi', BLEU], ['26 sept.', 'samedi', VIOLET], ['27 sept.', 'dimanche', NEON]];
  const versions = [
    ['1.0.0', 0, 'la première version', VERT, I.banque, [
      'Reliée au Crédit Mutuel de Bretagne par Enable Banking',
      'Classement, virements internes, remboursements, récurrences',
      'Base chiffrée, écran déplié en volets',
    ]],
    ['1.0.1', 0, 'un correctif', INTERNE, I.reglages, [
      'Le bon numéro de version dans les réglages',
      'Ils affichaient encore 0.1.0',
    ]],
    ['1.0.2', 0, 'sorties et loisirs', ROSE, I.roue, [
      'Un groupe d’icônes Sorties et loisirs, séparé du Sport',
      'Grande roue, fête foraine, billets, cinéma',
    ]],
    ['1.0.3', 0, 'l’alerte du solde', ROUGE, I.cloche, [
      'L’alerte de compte en négatif',
      'Le solde relu toutes les six heures, même application fermée',
      'Une notification par passage sous zéro',
    ]],
    ['1.1.0', 0, 'la démo, à côté', OR, I.deux, [
      'Une seconde application, installée à côté de la vraie',
      'Quatre mois d’opérations inventées, déjà chargées',
      'Sans banque ni empreinte',
    ]],
    ['1.2.0', 1, 'choisir sa banque', BLEU, I.loupe, [
      'Toutes les banques d’Enable Banking, par nom ou par pays',
      'Une page guide pour obtenir la clé',
      'Les opérations en attente, et la synchro à chaque ouverture',
    ]],
    ['1.2.2', 2, 'l’audit complet', VIOLET, I.bouclier, [
      'Lier un remboursement ne gèle plus l’application',
      'Reverrouillée après un passage en arrière-plan',
      'La synchro garde les liens des opérations en attente',
      'Plus de règle apprise sur le « N » d’un chèque',
      'Montants nets partout, récurrences justes sur les mois passés',
      'La fiche d’une opération tient entière sur l’écran déplié',
    ]],
    ['1.2.3', 3, 'le mois suit le salaire', NEON, I.salaire, [
      'Le mois commence tout seul le jour où le salaire arrive',
      'Les espèces retirées un mois et dépensées le suivant ne comptent plus deux fois',
      '83 tests, tous au vert',
    ]],
  ];
  const N = versions.length;
  const arrive = (i) => 0.04 + i * 0.088;       // la version tombe sur la pile
  const pose = (i) => arrive(i) + 0.022;       // elle est posée, scellée

  // La pile : de bas en haut, au-dessus du socle.
  const X = 156, XF = 1240, SOCLE = 786, H1 = 62, HP = 104, HN = 140, ECART = 10;
  const PREC = N - 2; // 1.2.2 : ses six puces sur deux rangs
  const ys = [];
  let bas = SOCLE - 12;
  versions.forEach((v, i) => {
    const h = i === N - 1 ? HN : i === PREC ? HP : H1;
    ys.push([bas - h, h]);
    bas -= h + ECART;
  });
  const cyRang = (i) => (i === N - 1 ? ys[i][0] + 40 : i === PREC ? ys[i][0] + 32 : ys[i][0] + ys[i][1] / 2);
  const COLS = [380, 646, 912], LCOL = 228, SCEAU = 1206;

  let corps = '';
  corps += t(60, 52, 'LES VERSIONS', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + tr('LES VERSIONS').length * 10.9 + 24), 52, 'Huit versions en quatre jours. Chacune s’installe par-dessus la précédente, signée par la même clé : rien ne se perd.', { taille: 14 });

  // Une puce : un point, et son texte sur une ou deux lignes, centré sur cy.
  const puce = (x, cy, s, couleur) => {
    const lignes = couper(tr(s), LCOL, 12.5);
    const y0 = cy - ((lignes.length - 1) * 16) / 2 + 4.5;
    return `<circle cx="${x + 3}" cy="${y0 - 4.2}" r="2.6" fill="${couleur}"/>
      <text font-family="${SANS}" font-size="12.5" fill="${TEXTE}">${lignes.map((li, k) => `<tspan x="${x + 14}" y="${y0 + k * 16}">${esc(li)}</tspan>`).join('')}</text>`;
  };

  // ------------------------------------------------------------ la pile
  versions.forEach(([num, , sous, c, icone, puces], i) => {
    const [y, h] = ys[i], s = arrive(i), dernier = i === N - 1;
    const cur = dernier ? FIN : arrive(i + 1);
    let r = `<rect x="${X}" y="${y}" width="${XF - X}" height="${h}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${X}" y="${y}" width="${XF - X}" height="${h}" rx="13" fill="${c}" fill-opacity="0.05" stroke="${c}" stroke-opacity="0.3"/>`;
    if (dernier) {
      r += `<rect x="${X}" y="${y}" width="${XF - X}" height="${h}" rx="13" fill="${c}" fill-opacity="0.035"/>
        <g transform="translate(${X + 18},${y + 22})">${icone(c)}</g>
        ${t(X + 58, y + 44, num, { taille: 26, couleur: TITRE, police: MONO, poids: 700 })}
        ${pilule(X + 58, y + 58, 86, 20, 'EN COURS', c, { plein: true, taille: 10.5 })}
        ${t(X + 58, y + 98, sous, { taille: 13.5, couleur: TITRE, poids: 600 })}`;
      puces.forEach((p, k) => { r += puce(COLS[k], y + 40, p, c); });
    } else if (i === PREC) {
      r += `<g transform="translate(${X + 18},${y + 18})">${icone(c)}</g>
        ${t(X + 58, y + 37, num, { taille: 17, couleur: TITRE, police: MONO, poids: 700 })}
        ${t(X + 58, y + 55, sous, { taille: 12 })}`;
      puces.forEach((p, k) => { r += puce(COLS[k % 3], y + 32 + Math.floor(k / 3) * 42, p, c); });
    } else {
      r += `<g transform="translate(${X + 18},${y + h / 2 - 14})">${icone(c)}</g>
        ${t(X + 58, y + h / 2 - 2, num, { taille: 17, couleur: TITRE, police: MONO, poids: 700 })}
        ${t(X + 58, y + h / 2 + 16, sous, { taille: 12 })}`;
      puces.forEach((p, k) => { r += puce(COLS[k], y + h / 2, p, c); });
    }
    // Allumée tant qu'elle est la dernière installée.
    r += `<rect x="${X}" y="${y}" width="${XF - X}" height="${h}" rx="13" fill="none" stroke="${c}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, pose(i), cur, 0.008)}</rect>`;
    corps += `<g opacity="0">${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.012, 1], [FIN, 1], [FIN + 0.015, 0], [1, 0]])}
      <g><animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${s};${pose(i)};1" values="0 -34;0 -34;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.3 0 0.25 1;0 0 1 1"/>${r}</g></g>`;
  });

  // Les 83 tests de 1.2.3, tous au vert.
  {
    const [y] = ys[N - 1], RY = y + 112, RX = X + 58, RL = 820, NT = 83;
    const pas = RL / NT, de = pose(N - 1) + 0.03, a = 0.88;
    let ruban = '';
    for (let k = 0; k < NT; k++) {
      const q = de + ((a - de) * k) / NT, x = (RX + k * pas).toFixed(1);
      ruban += `<rect x="${x}" y="${RY}" width="${(pas - 2.4).toFixed(1)}" height="13" rx="2.5" fill="#1A2230" stroke="${BORD}"/>
        <rect x="${x}" y="${RY}" width="${(pas - 2.4).toFixed(1)}" height="13" rx="2.5" fill="${VERT}" opacity="0">${visible(C, q + 0.002, FIN, 0.002)}</rect>`;
    }
    corps += g(pose(N - 1), FIN, ruban);
    corps += g(a, FIN, t(RX + RL + 14, RY + 11, '83 au vert', { taille: 13, couleur: VERT, police: MONO, poids: 700 }));
  }

  // ------------------------------------------------------------ le socle
  const FH = 80;
  corps += `<rect x="${X}" y="${SOCLE}" width="${XF - X}" height="${FH}" rx="13" fill="url(#hachures)" stroke="#2A3542"/>
    <rect x="${X}" y="${SOCLE}" width="${XF - X}" height="${FH}" rx="13" fill="#0F151D" fill-opacity="0.82"/>
    <g transform="translate(${X + 18},${SOCLE + FH / 2 - 14})">${P.base(BLEU)}</g>
    ${t(X + 58, SOCLE + 35, 'TES DONNÉES', { taille: 14.5, couleur: TITRE, police: MONO, poids: 700 })}
    ${t(X + 58, SOCLE + 55, 'comptes, opérations, catégories, règles apprises, liens', { taille: 12.5 })}
    <g transform="translate(${SCEAU - 14},${SOCLE + FH / 2 - 14})">${P.cle(VERT)}</g>
    ${t(SCEAU - 30, SOCLE + 35, 'MÊME CLÉ DE SIGNATURE', { taille: 14.5, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' })}
    ${t(SCEAU - 30, SOCLE + 55, 'certificat SHA-256 55572db2…fabcbef', { taille: 12.5, police: MONO, ancre: 'end' })}`;
  // Ce que dit chaque installation, au milieu du socle.
  const MX = 660;
  versions.forEach(([num], i) => {
    const de = pose(i), a = i === N - 1 ? FIN : pose(i + 1);
    const phrase = i === 0 ? '1.0.0 installée : la première' : `${num} par-dessus ${versions[i - 1][0]} : rien de perdu`;
    corps += g(de, a, `${t(MX, SOCLE + 35, 'INSTALLÉE', { taille: 10.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' })}
      ${t(MX, SOCLE + 55, phrase, { taille: 13, couleur: VERT, poids: 600 })}`);
  });
  // Le socle luit à chaque version posée dessus.
  versions.forEach((v, i) => {
    corps += `<rect x="${X}" y="${SOCLE}" width="${XF - X}" height="${FH}" rx="13" fill="none" stroke="${VERT}" stroke-width="1.5" filter="url(#halo)" opacity="0">${fondu('opacity', C, [[0, 0], [pose(i), 0], [pose(i) + 0.004, 0.9], [pose(i) + 0.05, 0], [1, 0]])}</rect>`;
  });

  // ------------------------------------------------------------ le fil de la clé
  // Il monte de la clé, par la marge droite des cartes, jusqu'à la
  // dernière version posée, et la scelle.
  const montee = [[0, SOCLE + 28], [pose(0) - 0.01, SOCLE + 28]];
  versions.forEach((v, i) => {
    montee.push([pose(i), cyRang(i)]);
    if (i < N - 1) montee.push([pose(i + 1) - 0.01, cyRang(i)]);
  });
  montee.push([FIN, cyRang(N - 1)], [FIN + 0.015, SOCLE + 28], [1, SOCLE + 28]);
  corps += `<line x1="${SCEAU}" y1="${SOCLE + 28}" x2="${SCEAU}" y2="${SOCLE + 28}" stroke="${VERT}" stroke-opacity="0.55" stroke-width="2" stroke-dasharray="4 4">${fondu('y1', C, montee)}</line>`;
  versions.forEach(([, , , c], i) => {
    const cy = cyRang(i), s = pose(i);
    corps += g(s, FIN, `<circle cx="${SCEAU}" cy="${cy}" r="11" fill="${CARTE}" stroke="${VERT}" stroke-width="1.5"/>
      <path d="M${SCEAU - 5} ${cy} l3.5 3.5 l6.5 -7" fill="none" stroke="${VERT}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`, 0.004);
    corps += `<circle cx="${SCEAU}" cy="${cy}" r="11" fill="none" stroke="${NEON}" stroke-width="2" opacity="0">
      ${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.003, 0.9], [s + 0.045, 0], [1, 0]])}${fondu('r', C, [[0, 11], [s, 11], [s + 0.045, 26], [1, 26]])}</circle>`;
  });

  // ------------------------------------------------------------ la frise
  const AX = 56;
  const bas0 = cyRang(0) + 16;
  corps += `<line x1="${AX}" y1="${bas0}" x2="${AX}" y2="${ys[N - 1][0]}" stroke="${FIL}" stroke-width="2" stroke-dasharray="3 6"/>`;
  const trace = [[0, bas0], [pose(0) - 0.01, bas0]];
  versions.forEach((v, i) => {
    trace.push([pose(i), cyRang(i)]);
    if (i < N - 1) trace.push([pose(i + 1) - 0.01, cyRang(i)]);
  });
  trace.push([FIN, cyRang(N - 1)], [FIN + 0.015, bas0], [1, bas0]);
  corps += `<line x1="${AX}" y1="${bas0}" x2="${AX}" y2="${bas0}" stroke="${VERT}" stroke-width="2">${fondu('y1', C, trace)}</line>`;
  // La flèche du temps, en haut.
  corps += `<path d="M${AX - 6} ${ys[N - 1][0] + 6} L${AX} ${ys[N - 1][0] - 1} L${AX + 6} ${ys[N - 1][0] + 6}" fill="none" stroke="${FIL}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`;
  // Les jours : l'étiquette face à la première version du jour.
  JOURS.forEach(([date, nom, c], j) => {
    const i = versions.findIndex((v) => v[1] === j), cy = cyRang(i);
    corps += g(pose(i), FIN, `${t(AX + 14, cy + 1, date, { taille: 12.5, couleur: c, police: MONO, poids: 700 })}
      ${t(AX + 14, cy + 17, nom, { taille: 11.5, couleur: TEXTE })}`);
  });
  // Entre deux jours, un trait en travers de la frise.
  [4, 5, 6].forEach((i) => {
    const y = (ys[i][0] + ys[i + 1][0] + ys[i + 1][1]) / 2;
    corps += `<line x1="${AX - 10}" y1="${y}" x2="${AX + 10}" y2="${y}" stroke="${DISCRET}" stroke-width="2"/>`;
  });
  versions.forEach(([, j], i) => {
    const cy = cyRang(i), c = JOURS[j][2];
    corps += `<circle cx="${AX}" cy="${cy}" r="5" fill="${CARTE}" stroke="${FIL}" stroke-width="2"/>`;
    corps += g(pose(i), FIN, `<circle cx="${AX}" cy="${cy}" r="5.5" fill="${c}" filter="url(#halo)"/>`, 0.004);
  });

  corps += t(640, 900, 'Chaque Release donne l’empreinte SHA-256 de l’APK et celle du certificat, pour vérifier avant d’installer.', { taille: 13, couleur: DISCRET, ancre: 'middle' });

  svg('versions.svg', 1280, 926, corps,
    'Les versions, huit en quatre jours, du jeudi 24 au dimanche 27 septembre 2026, empilées l’une sur l’autre : chacune tombe sur la précédente, comme elle s’installe par-dessus sur le téléphone, sans rien perdre. En bas, le socle ne bouge pas : tes données, comptes, opérations, catégories, règles apprises et liens, et la même clé de signature, certificat SHA-256 55572db2…fabcbef ; un fil monte de la clé et scelle chaque version. Le 24 septembre, 1.0.0, la première version : reliée au Crédit Mutuel de Bretagne par Enable Banking, classement, virements internes, remboursements, récurrences, base chiffrée et écran déplié en volets. 1.0.1, un correctif : le bon numéro de version dans les réglages, qui affichaient encore 0.1.0. 1.0.2 : un groupe d’icônes Sorties et loisirs, grande roue, fête foraine, billets, cinéma, séparé du Sport. 1.0.3 : l’alerte de compte en négatif, le solde relu toutes les six heures, même application fermée, une notification par passage sous zéro. 1.1.0 : la démo, une seconde application installée à côté de la vraie, avec quatre mois d’opérations inventées, sans banque ni empreinte. Le 25 septembre, 1.2.0 : toutes les banques d’Enable Banking, par nom ou par pays, une page guide pour obtenir la clé, les opérations en attente et la synchronisation à chaque ouverture. Le 26 septembre, 1.2.2, l’audit complet : lier un remboursement ne gèle plus l’application, elle se reverrouille après un passage en arrière-plan, la synchronisation garde les liens des opérations en attente, plus de règle apprise sur le « N » d’un chèque, montants nets partout et récurrences justes sur les mois passés, la fiche d’une opération entière sur l’écran déplié. Le 27 septembre, 1.2.3, la version en cours, le mois suit le salaire : le mois commence tout seul le jour où le salaire arrive, et les espèces retirées un mois et dépensées le suivant ne comptent plus deux fois. 83 tests, tous au vert.');
};

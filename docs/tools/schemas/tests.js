// Les tests : la suite qui tourne, un test après l'autre.
//
// En haut, la console et un ruban de 97 cases : les 34 tests de logique
// pure passent d'abord, sans appareil, puis les 63 qui tournent sur un
// émulateur Android, où SQLCipher et le Keystore existent. Le compteur
// monte, chaque case passe au vert. En bas, les familles : chacune s'allume quand passe un vrai test
// qui la vérifie, dont le nom s'affiche dans la console.
module.exports = (O) => {
  const { svg, t, tr, esc, visible, fondu, paliers, MONO, SANS, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, NEON, BLEU } = O;

  const C = 24, FIN = 0.985;
  const g = (de, a, contenu, douceur = 0.004) => `<g opacity="0">${visible(C, de, a, douceur)}${contenu}</g>`;

  // Un paragraphe coupé à la largeur donnée, dans la langue du rendu.
  const chasse = (ch) => {
    if (ch === ' ' || ch === ' ') return 0.28;
    if (/[iljI.,;:'’!|()]/.test(ch)) return 0.27;
    if (/[ftr]/.test(ch)) return 0.35;
    if (/[mwMW]/.test(ch)) return 0.84;
    if (/[A-Z]/.test(ch)) return 0.65;
    if (/[0-9]/.test(ch)) return 0.56;
    return 0.51;
  };
  const largeur = (s, taille) => [...s].reduce((a, ch) => a + chasse(ch), 0) * taille;
  const couper = (s, l, taille) => {
    const insecable = s.replace(/ ([:;!?»€])/g, ' $1').replace(/« /g, '« ');
    const lignes = [''];
    for (const m of insecable.split(' ')) {
      const der = lignes[lignes.length - 1];
      const essai = der ? `${der} ${m}` : m;
      if (der && largeur(essai, taille) > l) lignes.push(m);
      else lignes[lignes.length - 1] = essai;
    }
    return lignes;
  };
  const para = (x, y, s, l, { taille = 12.5, couleur = TEXTE, pas = 18 } = {}) =>
    `<text font-family="${SANS}" font-size="${taille}" fill="${couleur}">${couper(tr(s), l, taille)
      .map((li, k) => `<tspan x="${x}" y="${y + k * pas}">${esc(li)}</tspan>`).join('')}</text>`;

  let corps = '';
  corps += t(60, 52, 'LES TESTS', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + tr('LES TESTS').length * 10.9 + 24), 52, 'Ce que vérifient les 97 tests, famille par famille, et où ils tournent.', { taille: 14 });

  // ------------------------------------------------------- le déroulé
  const N = 97, PURS = 34;
  // L'instant où chaque test passe : la logique pure d'abord, vite, puis
  // l'émulateur, après l'installation de l'application de test.
  const quand = (i) => (i < PURS ? 0.05 + i * 0.0054 : 0.285 + (i - PURS) * 0.0091);
  const INSTALLE = 0.235, TOUT = quand(N - 1) + 0.012;

  // Le cadre du haut.
  const PX = 40, PY = 74, PL = 1200, PH = 184;
  corps += `<rect x="${PX}" y="${PY}" width="${PL}" height="${PH}" rx="16" fill="${CARTE}" stroke="${BORD}"/>`;

  // Le compteur : une valeur par test lancé.
  let compteur = '';
  for (let v = 0; v <= N; v++) {
    const de = v === 0 ? 0 : quand(v - 1), a = v === N ? null : quand(v);
    const etapes = v === 0 ? [[0, 1], [a, 0]] : a === null ? [[0, 0], [de, 1]] : [[0, 0], [de, 1], [a, 0]];
    compteur += `<text x="170" y="150" font-family="${MONO}" font-size="56" font-weight="700" fill="${v === N ? VERT : TITRE}" text-anchor="end" opacity="0">${v}${paliers('opacity', C, etapes)}</text>`;
  }
  corps += compteur;
  corps += t(178, 150, '/ 97', { taille: 22, couleur: DISCRET, police: MONO, poids: 700 });
  corps += t(66, 178, 'tests lancés', { taille: 12.5, couleur: TEXTE });

  // La console : la commande, le fichier, le dernier test qui compte.
  const KX = 272, KY = 92, KL = 944, KH = 86;
  corps += `<rect x="${KX}" y="${KY}" width="${KL}" height="${KH}" rx="11" fill="${FOND}" stroke="${BORD}"/>`;
  const commande = (s, de, a) => g(de, a, `${t(KX + 20, KY + 30, '$', { taille: 13, couleur: VERT, police: MONO, poids: 700 })}
    ${t(KX + 38, KY + 30, s, { taille: 13, couleur: TITRE, police: MONO, poids: 700 })}`, 0.003);
  corps += commande('flutter test', 0.004, INSTALLE);
  corps += commande('flutter test integration_test', INSTALLE, FIN);
  const fichiers = [
    ['test/audit_donnees_test.dart', 0.02, quand(32)],
    ['test/rs256_test.dart', quand(32), INSTALLE],
    ['integration_test/audit_synchro_test.dart', INSTALLE, quand(65)],
    ['integration_test/donnees_test.dart', quand(65), FIN],
  ];
  for (const [f, de, a] of fichiers) corps += g(de, a, t(KX + KL - 20, KY + 30, f, { taille: 11.5, couleur: DISCRET, police: MONO, ancre: 'end' }), 0.003);
  // [indice du test, nom, carte qu'il allume]
  const vus = [
    [0, 'une dépense remboursée par deux entrées ne devient pas un gain', 'Bilan'],
    [1, 'un chèque reclassé n’apprend pas la règle « N »', 'Classement'],
    [4, 'un abonnement du 31 janvier revient fin février, pas le 3 mars', 'Récurrences'],
    [21, 'le salaire du 19 décembre ouvre janvier', 'Mois budgétaire'],
    [24, 'une prime ou un remboursement rangé en salaire n’ouvre rien', null],
    [33, 'la signature RS256 est celle d’OpenSSL', 'Signature'],
    [PURS, 'A1 une attente dont le montant change en passant (pourboire) garde note, catégorie, mois et lien', null],
    [40, 'A7 synchro relancée trois fois : rien ne double, rien ne bouge', 'Synchronisations'],
    [55, 'D5 espèces dépensées le mois suivant le retrait : pas comptées deux fois', null],
    [61, 'F2 repartir et rembourser sur la même dépense en même temps : pas plus que la dépense', 'Remboursements'],
    [63, 'F4 un lien vers une attente que la synchro efface : rien ne gèle, pas de lien orphelin', 'Jamais figée'],
    [66, 'le marchand sort du bruit de la banque', 'Libellés'],
    [68, 'vers le livret : mis de côté', 'Virements internes'],
    [82, 'six amis remboursent la même dépense : 192 € ne comptent plus que pour 54 €', null],
    [86, 'un salaire versé avant Noël ouvre janvier, pas un second décembre', null],
    [89, 'une récurrence arrêtée n’est plus attendue, et reprend si elle repasse', null],
    [90, 'le portefeuille vit des retraits et des dépenses en espèces', 'Portefeuille'],
    [91, 'une sauvegarde chiffrée se relit, avec la bonne phrase seulement', 'Sauvegarde'],
  ];
  const ligne = (signe, c, s, de, a, couleur = TITRE) => g(de, a, `${t(KX + 20, KY + 62, signe, { taille: 14, couleur: c, poids: 700 })}
    ${t(KX + 42, KY + 62, s, { taille: 13.5, couleur })}`, 0.003);
  vus.forEach(([i, nom], k) => {
    const de = quand(i), a = k + 1 < vus.length ? quand(vus[k + 1][0]) : TOUT;
    if (i === PURS) return; // A1 : affiché dès l'arrivée sur l'émulateur, plus bas.
    const a1 = i === PURS - 1 ? INSTALLE : a;
    corps += ligne('✓', VERT, nom, de, a1);
  });
  corps += ligne('…', BLEU, 'l’application de test s’installe sur l’émulateur Android', INSTALLE, quand(PURS) - 0.012, TEXTE);
  corps += ligne('✓', VERT, vus.find(([i]) => i === PURS)[1], quand(PURS) - 0.012, quand(39));
  corps += ligne('✓', VERT, '97 au vert : 34 sans appareil, 63 sur l’émulateur.', TOUT, FIN, VERT);

  // Le ruban : une case par test.
  const RX = 66, RL = 1148, RY = 196, ECART = 26;
  const pas = (RL - ECART) / N, CL = pas - 3.5;
  const xCase = (i) => RX + i * pas + (i >= PURS ? ECART : 0);
  let ruban = '';
  for (let i = 0; i < N; i++) {
    const s = quand(i), x = xCase(i).toFixed(1), c = VERT;
    ruban += `<rect x="${x}" y="${RY}" width="${CL.toFixed(1)}" height="20" rx="3.5" fill="#1A2230" stroke="${BORD}"/>
      <rect x="${x}" y="${RY}" width="${CL.toFixed(1)}" height="20" rx="3.5" fill="${c}" opacity="0">${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.002, 1], [FIN, 1], [FIN + 0.006, 0], [1, 0]])}</rect>`;
  }
  // Le curseur, sur le test qui tourne.
  const pos = [];
  for (let i = 0; i < N; i++) pos.push([i === 0 ? 0 : quand(i - 1), xCase(i).toFixed(1)]);
  pos.push([quand(N - 1), xCase(N - 1).toFixed(1)]);
  ruban += `<rect y="${RY - 3}" width="${(CL + 4).toFixed(1)}" height="26" rx="5" fill="none" stroke="#FFFFFF" stroke-width="1.5" filter="url(#halo)" opacity="0" transform="translate(-2,0)">
    ${paliers('x', C, pos)}${fondu('opacity', C, [[0, 0], [0.04, 0], [0.045, 1], [quand(PURS - 1), 1], [quand(PURS - 1) + 0.005, 0], [quand(PURS) - 0.012, 0], [quand(PURS) - 0.008, 1], [quand(N - 1), 1], [quand(N - 1) + 0.005, 0], [1, 0]])}</rect>`;
  corps += ruban;
  const finPurs = xCase(PURS - 1) + CL;
  corps += t(RX, RY + 44, '34', { taille: 12.5, couleur: TITRE, police: MONO, poids: 700 });
  corps += t(RX + 24, RY + 44, 'logique pure, sans appareil', { taille: 12.5 });
  corps += `<path d="M${RX} ${RY + 27} H${finPurs}" stroke="${BLEU}" stroke-opacity="0.7" stroke-width="2"/>`;
  corps += t(xCase(PURS), RY + 44, '63', { taille: 12.5, couleur: TITRE, police: MONO, poids: 700 });
  corps += t(xCase(PURS) + 24, RY + 44, 'sur un émulateur Android, où SQLCipher et le Keystore existent', { taille: 12.5 });
  corps += `<path d="M${xCase(PURS)} ${RY + 27} H${RX + RL}" stroke="${VERT}" stroke-opacity="0.7" stroke-width="2"/>`;

  // ------------------------------------------------------- les familles
  const familles = [
    ['Libellés', 'Le marchand sort du bruit de la banque, et sa clé ne change pas d\'un mois à l\'autre.'],
    ['Virements internes', 'Vers le livret, depuis le livret, un livret au nom inhabituel, et un virement à quelqu\'un qui n\'en est pas un.'],
    ['Récurrences', 'Un abonnement mensuel reconnu avec sa prochaine date, des courses irrégulières qui n\'en sont pas.'],
    ['Classement', 'Le dictionnaire, les corrections apprises et suivies, et une synchronisation relancée qui ne double rien.'],
    ['Bilan', 'Remboursements répartis, remboursement marchand, dépense en espèces retirée des retraits.'],
    ['Portefeuille', '50 € comptés, un retrait de 20 €, 12 € au marché : il en reste 58.'],
    ['Mois budgétaire', 'Chaque salaire ouvre son mois, même en avance pour Noël ; une prime n’en ouvre aucun. Les espèces d’un retrait comptent une seule fois.'],
    ['Sauvegarde', 'Tout revient avec la bonne phrase ; une phrase fausse ne touche à rien.'],
    ['Signature', 'Le JWT signé en Dart est, octet pour octet, celui d\'OpenSSL.'],
    ['Remboursements', 'Six virements pour une dépense, lier dans les deux sens, jamais au-delà, même avec deux écritures au même instant.'],
    ['Synchronisations', 'Attentes qui passent, changent de montant ou sont levées, un an d\'historique : rien ne double, rien ne se perd.'],
    ['Jamais figée', 'Chaque test borne ses accès à la base dans le temps : un verrou mort ferait échouer la suite au lieu de la geler.'],
    ['Sur appareil', '97 tests : 34 sur la logique pure, 63 sur un émulateur Android, où SQLCipher et le Keystore existent.'],
  ];
  const allume = {};
  for (const [i, , f] of vus) if (f) allume[f] = quand(i);
  allume['Sur appareil'] = TOUT;
  const CY0 = 278, CW = 392, CH = 108, CG = 12;
  // Douze familles en grille ; « Sur appareil », qui les résume, en bande dessous.
  const BY = CY0 + 4 * (CH + CG), BH = 64;
  familles.forEach(([titre, texte], k) => {
    const bande = k === 12;
    const x = bande ? PX : PX + (k % 3) * (CW + CG), y = bande ? BY : CY0 + Math.floor(k / 3) * (CH + CG), s = allume[titre];
    const l = bande ? PL : CW, h = bande ? BH : CH;
    const ox = x + 32, oy = bande ? y + BH / 2 : y + 30;
    corps += `<rect x="${x}" y="${y}" width="${l}" height="${h}" rx="13" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${y}" width="${l}" height="${h}" rx="13" fill="${VERT}" fill-opacity="0.04" stroke="${VERT}" stroke-opacity="0.45" opacity="0">${visible(C, s, FIN, 0.004)}</rect>
      <rect x="${x}" y="${y}" width="${l}" height="${h}" rx="13" fill="none" stroke="${VERT}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, s, s + 0.06, 0.006)}</rect>
      <circle cx="${ox}" cy="${oy}" r="12" fill="none" stroke="${FIL}" stroke-width="2" stroke-dasharray="4 4"/>
      ${g(s, FIN, `<circle cx="${ox}" cy="${oy}" r="12" fill="${VERT}"/>
        <path d="M${ox - 5.5} ${oy} l4 4 l7.5 -8" fill="none" stroke="#000000" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>`, 0.003)}
      <circle cx="${ox}" cy="${oy}" r="12" fill="none" stroke="${NEON}" stroke-width="2" opacity="0">
        ${fondu('opacity', C, [[0, 0], [s, 0], [s + 0.002, 0.9], [s + 0.05, 0], [1, 0]])}${fondu('r', C, [[0, 12], [s, 12], [s + 0.05, 28], [1, 28]])}</circle>
      ${bande ? `${t(x + 58, y + 27, titre, { taille: 14.5, couleur: TITRE, police: MONO, poids: 700 })}
        ${t(x + 58, y + 47, texte, { taille: 12.5 })}`
    : `${t(x + 58, y + 35, titre, { taille: 14.5, couleur: TITRE, police: MONO, poids: 700 })}
        ${para(x + 58, y + 58, texte, CW - 58 - 30)}`}`;
  });

  svg('tests.svg', 1280, BY + BH + 22, corps,
    'Les tests, lancés un à un. Un compteur monte de 0 à 97 et un ruban de 97 cases passe au vert : d’abord les 34 tests de logique pure, sans appareil, par flutter test, puis les 63 qui tournent sur un émulateur Android, où SQLCipher et le Keystore existent, par flutter test integration_test. Les 97 finissent au vert. Chaque famille s’allume quand passe un test qui la vérifie. Libellés : le marchand sort du bruit de la banque, et sa clé ne change pas d’un mois à l’autre. Virements internes : vers le livret, depuis le livret, un livret au nom inhabituel, et un virement à quelqu’un qui n’en est pas un. Récurrences : un abonnement mensuel reconnu avec sa prochaine date, des courses irrégulières qui n’en sont pas. Classement : le dictionnaire, les corrections apprises et suivies, et une synchronisation relancée qui ne double rien. Bilan : remboursements répartis, remboursement marchand, dépense en espèces retirée des retraits. Portefeuille : 50 euros comptés, un retrait de 20 euros, 12 euros au marché, il en reste 58. Mois budgétaire : chaque salaire ouvre son mois, même en avance pour Noël, une prime n’en ouvre aucun, et les espèces d’un retrait comptent une seule fois. Sauvegarde : tout revient avec la bonne phrase, une phrase fausse ne touche à rien. Signature : le JWT signé en Dart est, octet pour octet, celui d’OpenSSL. Remboursements : six virements pour une dépense, lier dans les deux sens, jamais au-delà, même avec deux écritures au même instant. Synchronisations : attentes qui passent, changent de montant ou sont levées, un an d’historique, rien ne double, rien ne se perd. Jamais figée : chaque test borne ses accès à la base dans le temps, un verrou mort ferait échouer la suite au lieu de la geler. Sur appareil : 97 tests, 34 sur la logique pure, 63 sur un émulateur Android.');
};

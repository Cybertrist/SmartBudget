// Le modèle de données : les six tables de la base, en version 6.
//
// Les tables apparaissent une à une, avec toutes leurs colonnes telles que
// les crée lib/donnees/base.dart. Puis les clés étrangères se tracent :
// operations.compte_id vers comptes, operations.categorie_id vers
// categories, categories.parent_id vers elle-même, liens.entree_id et
// liens.depense_id vers operations, regles.categorie_id vers categories.
// Enfin une opération d'exemple, le concert du 20 septembre, se remplit
// colonne par colonne ; ses clés allument la ligne qu'elles désignent, et
// son remboursement ajoute une ligne à liens. À gauche, en bas, la fiche
// que l'application en tire se compose au même rythme.
module.exports = (O) => {
  const { svg, t, visible, fondu, P, MONO, FOND, CARTE, BORD, TITRE, TEXTE, DISCRET, VERT, BLEU, OR, ROSE, INTERNE } = O;
  const C = 28;
  const VIOLET = '#B08CFF';
  const NOM = '#C3CCD7';
  const FIN = 0.975;
  let corps = '';
  corps += t(60, 52, 'LE MODÈLE DE DONNÉES', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + O.tr('LE MODÈLE DE DONNÉES').length * 10.9 + 24), 52, 'Six tables, en centimes et en clés : ce que la base chiffrée garde de chaque opération.', { taille: 14 });

  // ---------------------------------------------------------------- tables
  const HH = 44, RH = 24;
  const hauteur = (n) => HH + n * RH + 10;
  const rangY = (tb, i) => tb.y + HH + 5 + i * RH + RH / 2; // le milieu d'une rangée
  const trait = (c) => `fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"`;
  const I = {
    operations: (c) => `<g ${trait(c)}><path d="M6 3 H22 V25 L19 23 L16 25 L13 23 L10 25 L6 23 Z"/><path d="M10 9 H18 M10 14 H18 M10 19 H15"/></g>`,
    categories: (c) => `<g ${trait(c)}><path d="M14 3 L20 13 H8 Z"/><circle cx="8.5" cy="20" r="4.5"/><rect x="16" y="16" width="9" height="9" rx="1.5"/></g>`,
    comptes: (c) => `<g ${trait(c)}><rect x="3" y="7" width="22" height="16" rx="3"/><path d="M3 12 H25 M18 17 H21"/><path d="M6 7 L19 3 L21 7"/></g>`,
    liens: P.lien,
    regles: (c) => `<g ${trait(c)}><path d="M2 11 L14 5 L26 11 L14 17 Z"/><path d="M7 13.5 V19 C10 22 18 22 21 19 V13.5 M26 11 V18"/></g>`,
    reglages: (c) => `<g ${trait(c)}><path d="M4 8 H24 M4 14 H24 M4 20 H24"/></g><circle cx="10" cy="8" r="2.6" fill="${FOND}" stroke="${c}" stroke-width="2"/><circle cx="18" cy="14" r="2.6" fill="${FOND}" stroke="${c}" stroke-width="2"/><circle cx="12" cy="20" r="2.6" fill="${FOND}" stroke="${c}" stroke-width="2"/>`,
  };

  // Les instants : les tables, puis les clés, puis l'exemple.
  const R = { compte: 0.24, categorie: 0.3, parent: 0.36, liens: 0.42, regles: 0.48 };
  const REMPLI = (i) => 0.57 + i * 0.019;
  const LIE = [0.885, 0.9, 0.915];

  // [nom, pictogramme, couleur, x, y, largeur, apparition, colonnes,
  //  rangées : [colonne, rôle, (valeur d'exemple, instant)]]
  const X_G = 60, X_M = 450, X_D = 890, L_C = 330, L_M = 380;
  const tables = {
    operations: { x: X_M, y: 96, l: L_M, c: VERT, de: 0.02, n: 18, rangs: [
      ['id', 'la clé', '1287'],
      ['compte_id', 'vers comptes', '1'],
      ['uid_banque', 'unique : rien ne se double', '7Q2V-1834'],
      ['le', 'le jour de l’opération', '2026-09-20'],
      ['libelle', 'tel que la banque l’écrit', 'CB FNAC SPECTACLES 19/09'],
      ['montant_centimes', 'un entier, jamais un flottant', '-9000'],
      ['categorie_id', 'vers categories', '164'],
      ['origine', 'main, règle, dictionnaire, interne, défaut', 'dictionnaire'],
      ['nature', 'vide : celle de sa catégorie', 'NULL'],
      ['mois_compte', 'rattachée à un autre mois', 'NULL'],
      ['nom · note', 'choisis à la main', '\'Concert\' · NULL'],
      ['masquee', 'hors de l’analyse', '0'],
      ['recurrente', 'vide : la détection décide', 'NULL'],
      ['interne', 'vers l’épargne, depuis, entre comptes', 'NULL'],
      ['pointee · especes', 'vérifiée, payée en liquide', '0 · 0'],
      ['en_attente', 'pas encore comptabilisée', '0'],
    ].map(([a, b, v], i) => [a, b, v, REMPLI(i)]) },
    comptes: { x: X_D, y: 96, l: L_C, c: BLEU, de: 0.08, n: 9, rangs: [
      ['id', 'la clé', '1 · Compte courant', REMPLI(1)],
      ['nature', 'courant, livret, portefeuille'],
      ['nom · iban_fin', 'ce qui se voit'],
      ['uid_banque', 'le compte chez la banque'],
      ['solde_centimes', 'au dernier relevé'],
      ['solde_le', 'la date de ce solde'],
      ['motif', 'son nom dans les virements'],
      ['cree_le', 'sa création'],
    ] },
    categories: { x: X_D, y: 0, l: L_C, c: OR, de: 0.05, n: 10, rangs: [
      ['id', 'la clé', '164 · Cinéma et concerts', REMPLI(6)],
      ['parent_id', 'une sous-catégorie', '12 · Loisirs', REMPLI(6) + 0.008],
      ['nom · icone · couleur', 'ce qui se voit'],
      ['genre', 'dépense, revenu, épargne, interne'],
      ['nature', 'essentiel, plaisir, imprévu'],
      ['budget_centimes', 'son budget, s’il en a un'],
      ['ordre', 'sa place dans la liste'],
    ] },
    regles: { x: X_D, y: 0, l: L_C, c: VIOLET, de: 0.14, n: 3, rangs: [
      ['id', 'la clé'],
      ['motif', 'le marchand appris, unique'],
      ['categorie_id', 'où il va désormais'],
    ] },
    liens: { x: X_G, y: 96, l: L_C, c: ROSE, de: 0.11, n: 3, rangs: [
      ['entree_id', 'le remboursement', '1262 · Camille Roux', LIE[0]],
      ['depense_id', 'la dépense remboursée', '1287 · Concert', LIE[1]],
      ['montant_centimes', 'la part qui lui revient', '4500', LIE[2]],
    ] },
    reglages: { x: X_G, y: 0, l: L_C, c: INTERNE, de: 0.17, n: 2, rangs: [
      ['cle · valeur', 'une ligne par réglage'],
      ['budget · objectif_epargne', 'en centimes'],
      ['debut_mois', 'le jour où commence le mois'],
      ['banque_*', 'clé chiffrée, banque, fin de l’accès'],
      ['repetition:* · nom:*', 'choix par marchand'],
      ['alerte_negatif', 'déjà prévenu'],
    ] },
  };
  const T = tables;
  T.categories.y = T.comptes.y + hauteur(T.comptes.rangs.length) + 35;
  T.regles.y = T.categories.y + hauteur(T.categories.rangs.length) + 35;
  T.reglages.y = T.liens.y + hauteur(T.liens.rangs.length) + 28;

  // Une rangée allumée : le temps d'une clé qui se trace, ou d'une valeur
  // qui s'écrit.
  const eclat = (tb, i, couleur, de, a) =>
    `<rect x="${tb.x + 1}" y="${rangY(tb, i) - RH / 2}" width="${tb.l - 2}" height="${RH}" fill="${couleur}" fill-opacity="0.13" opacity="0">${visible(C, de, a, 0.005)}</rect>`;

  for (const [nom, tb] of Object.entries(T)) {
    const h = hauteur(tb.rangs.length);
    let g = `<rect x="${tb.x}" y="${tb.y}" width="${tb.l}" height="${h}" rx="14" fill="${CARTE}" stroke="${BORD}"/>
      <clipPath id="tete-${nom}"><rect x="${tb.x}" y="${tb.y}" width="${tb.l}" height="${HH}" rx="14"/><rect x="${tb.x}" y="${tb.y + 20}" width="${tb.l}" height="${HH - 20}"/></clipPath>
      <linearGradient id="teinte-${nom}" x1="0" x2="1"><stop offset="0" stop-color="${tb.c}" stop-opacity="0.14"/><stop offset="1" stop-color="${tb.c}" stop-opacity="0"/></linearGradient>
      <rect x="${tb.x}" y="${tb.y}" width="${tb.l}" height="${HH}" fill="url(#teinte-${nom})" clip-path="url(#tete-${nom})"/>
      <line x1="${tb.x}" y1="${tb.y + HH}" x2="${tb.x + tb.l}" y2="${tb.y + HH}" stroke="${BORD}"/>
      <g transform="translate(${tb.x + 14},${tb.y + 10}) scale(0.86)">${I[nom](tb.c)}</g>
      <!-- Le nom de la table, un identifiant du schéma : jamais traduit. -->
      <text x="${tb.x + 46}" y="${tb.y + 27.5}" font-family="${MONO}" font-size="14.5" font-weight="700" fill="${tb.c}">${nom}</text>
      ${t(tb.x + tb.l - 16, tb.y + 27, `${tb.n} colonnes`, { taille: 11.5, couleur: DISCRET, ancre: 'end' })}`;
    tb.rangs.forEach(([col, role, valeur, quand], i) => {
      const y = rangY(tb, i);
      if (i > 0) g += `<line x1="${tb.x + 12}" y1="${y - RH / 2}" x2="${tb.x + tb.l - 12}" y2="${y - RH / 2}" stroke="#1A222C"/>`;
      if (valeur) g += eclat(tb, i, tb === T.operations ? VERT : tb.c, quand, quand + 0.03);
      // Dans reglages, sous ses deux colonnes, les familles de clés.
      g += t(tb.x + 16, y + 4.5, col, { taille: 12, couleur: tb === T.reglages && i > 0 ? INTERNE : NOM, police: MONO, poids: 500 });
      if (!valeur) {
        g += t(tb.x + tb.l - 16, y + 4.5, role, { taille: 12, ancre: 'end' });
        return;
      }
      // Le rôle s'efface, la valeur d'exemple prend sa place.
      g += `<g>${fondu('opacity', C, [[0, 1], [quand - 0.009, 1], [quand - 0.004, 0], [FIN, 0], [FIN + 0.012, 1], [1, 1]])}${t(tb.x + tb.l - 16, y + 4.5, role, { taille: 12, ancre: 'end' })}</g>`;
      const nul = /NULL$/.test(valeur) && !/'/.test(valeur);
      g += `<g opacity="0">${visible(C, quand, FIN, 0.003)}${t(tb.x + tb.l - 16, y + 4.5, valeur, { taille: 12, couleur: nul ? DISCRET : (tb === T.operations ? VERT : tb.c), police: MONO, poids: 700, ancre: 'end' })}</g>`;
    });
    corps += `<g opacity="0">${visible(C, tb.de, 0.99, 0.02)}
      <animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${tb.de - 0.02};${tb.de};1" values="0 14;0 14;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.3 0 0.2 1;0 0 1 1"/>
      ${g}</g>`;
  }

  // ---------------------------------------------------------------- clés
  // Un chemin à angles droits qui se trace, puis sa pointe.
  const cle = (points, couleur, de, pointe = true) => {
    let long = 0;
    for (let k = 1; k < points.length; k++) long += Math.abs(points[k][0] - points[k - 1][0]) + Math.abs(points[k][1] - points[k - 1][1]);
    long = Math.ceil(long);
    const d = 'M' + points.map((p) => p.join(' ')).join(' L');
    const [xa, ya] = points.at(-2), [xb, yb] = points.at(-1);
    const sens = xb > xa ? 1 : -1;
    let s = `<path d="${d}" fill="none" stroke="${couleur}" stroke-width="2" stroke-linejoin="round" stroke-dasharray="${long}" stroke-dashoffset="${long}" opacity="0">
      ${fondu('stroke-dashoffset', C, [[0, long], [de, long], [de + 0.035, 0], [1, 0]])}${visible(C, de, 0.99, 0.004)}</path>
      <circle cx="${points[0][0]}" cy="${points[0][1]}" r="3.5" fill="${couleur}" opacity="0">${visible(C, de, 0.99, 0.004)}</circle>`;
    if (pointe && ya === yb) {
      s += `<path d="M${xb - sens * 7} ${yb - 5.5} L${xb} ${yb} L${xb - sens * 7} ${yb + 5.5}" fill="none" stroke="${couleur}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" opacity="0">${visible(C, de + 0.035, 0.99, 0.004)}</path>`;
    }
    return s;
  };
  const op = T.operations, co = T.comptes, ca = T.categories, re = T.regles, li = T.liens;
  // operations.compte_id vers comptes.id.
  corps += cle([[op.x + op.l, rangY(op, 1)], [op.x + op.l + 22, rangY(op, 1)], [op.x + op.l + 22, rangY(co, 0)], [co.x - 1, rangY(co, 0)]], BLEU, R.compte);
  corps += eclat(op, 1, BLEU, R.compte, R.compte + 0.055) + eclat(co, 0, BLEU, R.compte + 0.03, R.compte + 0.055);
  // operations.categorie_id vers categories.id.
  corps += cle([[op.x + op.l, rangY(op, 6)], [op.x + op.l + 38, rangY(op, 6)], [op.x + op.l + 38, rangY(ca, 0)], [ca.x - 1, rangY(ca, 0)]], OR, R.categorie);
  corps += eclat(op, 6, OR, R.categorie, R.categorie + 0.055) + eclat(ca, 0, OR, R.categorie + 0.03, R.categorie + 0.055);
  // categories.parent_id vers categories.id : une boucle sur la droite.
  corps += cle([[ca.x + ca.l, rangY(ca, 1)], [ca.x + ca.l + 16, rangY(ca, 1)], [ca.x + ca.l + 16, rangY(ca, 0) - 4], [ca.x + ca.l + 1, rangY(ca, 0) - 4]], OR, R.parent);
  corps += eclat(ca, 1, OR, R.parent, R.parent + 0.055) + eclat(ca, 0, OR, R.parent + 0.03, R.parent + 0.055);
  // liens.entree_id et liens.depense_id vers operations.id.
  corps += cle([[li.x + li.l, rangY(li, 0)], [op.x - 1, rangY(op, 0)]], ROSE, R.liens);
  corps += cle([[li.x + li.l, rangY(li, 1)], [li.x + li.l + 30, rangY(li, 1)], [li.x + li.l + 30, rangY(li, 0)]], ROSE, R.liens + 0.02, false);
  corps += eclat(li, 0, ROSE, R.liens, R.liens + 0.06) + eclat(li, 1, ROSE, R.liens + 0.02, R.liens + 0.06) + eclat(op, 0, ROSE, R.liens + 0.035, R.liens + 0.06);
  // regles.categorie_id vers categories.id, par l'extérieur.
  corps += cle([[re.x + re.l, rangY(re, 2)], [re.x + re.l + 32, rangY(re, 2)], [re.x + re.l + 32, rangY(ca, 0) + 4], [ca.x + ca.l + 1, rangY(ca, 0) + 4]], VIOLET, R.regles);
  corps += eclat(re, 2, VIOLET, R.regles, R.regles + 0.055) + eclat(ca, 0, VIOLET, R.regles + 0.03, R.regles + 0.055);

  // ------------------------------------------------ la fiche qui se compose
  const FX = X_G, FY = T.reglages.y + hauteur(T.reglages.rangs.length) + 28, FL = L_C, FH = 760 - FY;
  corps += `<rect x="${FX}" y="${FY}" width="${FL}" height="${FH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>
    <rect x="${FX}" y="${FY}" width="${FL}" height="${FH}" rx="14" fill="${VERT}" fill-opacity="0.05" stroke="${VERT}" stroke-opacity="0.3"/>
    ${t(FX + 20, FY + 28, 'CE QUE L’APPLICATION EN MONTRE', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="1.5"' })}`;
  const deOp = (i) => REMPLI(i);
  const apparait = (de, contenu, a = FIN) => `<g opacity="0">${visible(C, de, a, 0.005)}${contenu}</g>`;
  corps += apparait(0.02, t(FX + 20, FY + 60, 'Elle se compose au fil des colonnes.', { taille: 12.5, couleur: DISCRET }), deOp(0));
  // Le titre : le nom tiré du libellé, puis le nom choisi.
  corps += apparait(deOp(4), t(FX + 20, FY + 62, 'Fnac Spectacles', { taille: 19, couleur: TITRE, poids: 800 }), deOp(10));
  corps += apparait(deOp(10), t(FX + 20, FY + 62, 'Concert', { taille: 19, couleur: TITRE, poids: 800 }));
  corps += apparait(deOp(5), t(FX + FL - 20, FY + 62, '-90,00 €', { taille: 17, couleur: TITRE, police: MONO, poids: 700, ancre: 'end' }));
  corps += apparait(deOp(3), t(FX + 20, FY + 84, 'Dimanche 20 septembre 2026', { taille: 12, couleur: TEXTE }));
  corps += apparait(deOp(1), t(FX + 20, FY + 102, 'Compte courant', { taille: 12, couleur: BLEU }));
  corps += apparait(deOp(6), `<rect x="${FX + 20}" y="${FY + 118}" width="${FL - 40}" height="30" rx="9" fill="${OR}" fill-opacity="0.1" stroke="${OR}" stroke-opacity="0.45"/>
    ${t(FX + 34, FY + 137.5, 'Loisirs › Cinéma et concerts', { taille: 12.5, couleur: OR, poids: 700 })}`);
  corps += apparait(deOp(7), t(FX + 20, FY + 170, 'classée par le dictionnaire', { taille: 12, couleur: TEXTE }));
  corps += apparait(deOp(8), t(FX + 20, FY + 188, 'plaisir, comme sa catégorie', { taille: 12, couleur: TEXTE }));
  corps += apparait(LIE[1], `<rect x="${FX + 20}" y="${FY + 206}" width="${FL - 40}" height="52" rx="10" fill="${ROSE}" fill-opacity="0.08" stroke="${ROSE}" stroke-opacity="0.45"/>
    <g transform="translate(${FX + 30},${FY + 218}) scale(0.9)">${P.lien(ROSE)}</g>
    ${t(FX + 62, FY + 227, '45,00 € rendus par Camille Roux', { taille: 12.5, couleur: TITRE, poids: 700 })}
    ${t(FX + 62, FY + 245, 'elle ne pèse plus que 45,00 €', { taille: 12, couleur: ROSE })}`);

  // ------------------------------------------------ ce que le schéma garantit
  const GY = op.y + hauteur(op.rangs.length) + 26, GH = 760 - GY;
  corps += `<rect x="${X_M}" y="${GY}" width="${L_M}" height="${GH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>
    ${t(X_M + 20, GY + 28, 'CE QUE LE SCHÉMA GARANTIT', { taille: 11, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="1.5"' })}`;
  [
    [VERT, 'Des centimes, jamais un double :', 'un flottant ne sait pas écrire 0,10 €.'],
    [ROSE, 'Une entrée et une dépense ne se lient', 'qu’une fois : la paire est la clé de liens.'],
    [BLEU, 'Supprimer un compte emporte ses opérations,', 'et une opération ses liens.'],
    [INTERNE, 'Version 6 : pointee, nom, especes, puis', 'en_attente, ajoutées sans rien perdre.'],
  ].forEach(([c, l1, l2], k) => {
    const y = GY + 52 + k * 40;
    corps += `<circle cx="${X_M + 26}" cy="${y - 4}" r="4" fill="${c}"/>
      ${t(X_M + 40, y, l1, { taille: 12.5, couleur: TITRE })}
      ${t(X_M + 40, y + 17, l2, { taille: 12.5 })}`;
  });

  // ------------------------------------------------ la légende qui suit
  const legendes = [
    [0.02, R.compte - 0.01, 'Six tables, dans une base chiffrée par SQLCipher, au schéma en version 6.', TEXTE],
    [R.compte, R.categorie, 'operations.compte_id → comptes.id : chaque opération appartient à un compte.', BLEU],
    [R.categorie, R.parent, 'operations.categorie_id → categories.id : jamais d’opération sans catégorie.', OR],
    [R.parent, R.liens, 'categories.parent_id → categories.id : une sous-catégorie pointe sur sa catégorie.', OR],
    [R.liens, R.regles, 'liens.entree_id et liens.depense_id → operations.id : une entrée rembourse une dépense, pour une part.', ROSE],
    [R.regles, 0.555, 'regles.categorie_id → categories.id : un marchand appris, et la catégorie qu’il suit désormais.', VIOLET],
    [0.565, LIE[0] - 0.01, 'Une opération d’exemple, colonne par colonne : le concert du 20 septembre.', VERT],
    [LIE[0], FIN, 'Puis son remboursement : une ligne dans liens, 45,00 € de Camille Roux pour ce concert.', ROSE],
  ];
  for (const [de, a, s, c] of legendes) {
    corps += `<g opacity="0">${visible(C, de, a, 0.006)}${t(640, 792, s, { taille: 13, couleur: c, ancre: 'middle' })}</g>`;
  }

  svg('modele.svg', 1280, 818, corps,
    'Le modèle de données de SmartBudget : six tables dans une base chiffrée par SQLCipher, au schéma en version 6. operations, 18 colonnes : id ; compte_id, vers comptes ; uid_banque, unique, pour que rien ne se double ; le, le jour de l’opération ; libelle, tel que la banque l’écrit ; montant_centimes, un entier, jamais un flottant ; categorie_id, vers categories ; origine, à la main, règle, dictionnaire, interne ou par défaut ; nature, vide pour suivre celle de sa catégorie ; mois_compte, pour la rattacher à un autre mois ; nom et note, choisis à la main ; masquee, hors de l’analyse ; recurrente, vide quand la détection décide ; interne, vers l’épargne, depuis l’épargne ou entre comptes ; pointee et especes, vérifiée et payée en liquide ; en_attente, pas encore comptabilisée. categories, 10 colonnes : id ; parent_id, pour une sous-catégorie ; nom, icone et couleur, ce qui se voit ; genre, dépense, revenu, épargne ou interne ; nature, essentiel, plaisir ou imprévu ; budget_centimes, son budget s’il en a un ; ordre, sa place dans la liste. comptes, 9 colonnes : id ; nature, courant, livret ou portefeuille ; nom et iban_fin ; uid_banque, le compte chez la banque ; solde_centimes, au dernier relevé, et solde_le, sa date ; motif, son nom dans les virements ; cree_le. liens : entree_id, le remboursement ; depense_id, la dépense remboursée ; montant_centimes, la part qui lui revient. regles : id ; motif, le marchand appris, unique ; categorie_id, où il va désormais. reglages : cle et valeur, pour le budget, l’épargne et le début du mois, les clés banque_ pour la clé chiffrée, la banque et la fin de l’accès, les choix par marchand en repetition: et nom:, et alerte_negatif. Les clés étrangères se tracent : operations.compte_id vers comptes, operations.categorie_id vers categories, categories.parent_id vers categories, liens.entree_id et liens.depense_id vers operations, regles.categorie_id vers categories. Puis une opération d’exemple se remplit colonne par colonne : id 1287, compte 1, le compte courant, le 20 septembre 2026, CB FNAC SPECTACLES 19/09, -9000 centimes, catégorie 164, Cinéma et concerts sous Loisirs, classée par le dictionnaire, nommée Concert ; son remboursement ajoute à liens la ligne 1262, Camille Roux, vers 1287, pour 4500 centimes, et la fiche montre 45 euros rendus, la dépense ne pesant plus que 45 euros. Le schéma garantit des centimes plutôt que des flottants, une paire entrée et dépense liée une seule fois, la suppression en cascade des opérations d’un compte et des liens d’une opération, et des migrations sans perte jusqu’à la version 6.');
};

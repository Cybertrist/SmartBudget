// La pile : ce sur quoi l'application est bâtie.
//
// Flutter 3 en socle, cinq prises posées dessus, ce que l'application
// sert : l'écran, la base, la clé, la banque, la veille. Les onze paquets
// tombent un à un et s'empilent sur la prise qu'ils servent. Puis deux
// trajets les traversent : l'ouverture de l'application, de l'empreinte
// jusqu'à l'écran, et la veille du solde, de la tâche d'arrière-plan
// jusqu'à la notification.
module.exports = (O) => {
  const { svg, t, tr, esc, visible, fondu, P, MONO, SANS, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, NEON, BLEU, OR, ROSE, ROUGE } = O;

  const C = 26, FIN = 0.975;
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
  // La hauteur ne change pas d'une langue à l'autre : on compte les lignes
  // des deux, et l'on garde la plus haute.
  const DICO = require('../anglais.json');
  const nLignes = (s, l, taille) => Math.max(couper(s, l, taille).length, couper(DICO[s] || s, l, taille).length);
  const para = (x, y, s, l, { taille = 12, couleur = TEXTE, pas = 16.5 } = {}) =>
    `<text font-family="${SANS}" font-size="${taille}" fill="${couleur}">${couper(tr(s), l, taille)
      .map((li, k) => `<tspan x="${x}" y="${y + k * pas}">${esc(li)}</tspan>`).join('')}</text>`;

  let corps = '';
  corps += t(60, 52, 'LA PILE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + tr('LA PILE').length * 10.9 + 24), 52, 'Flutter en socle, et chaque paquet branché sur ce qu’il sert : l’écran, la base, la clé, la banque, la veille.', { taille: 14 });

  // ------------------------------------------------------- les prises
  const prises = [
    ['ecran', 'L’écran', 'ce que tu vois et touches', P.telephone, VERT],
    ['base', 'La base', 'chiffrée, sur le téléphone', P.base, BLEU],
    ['cle', 'La clé', 'dans le Keystore Android', P.cle, OR],
    ['banque', 'La banque', 'Enable Banking, par la DSP2', P.banque, ROSE],
    ['veille', 'La veille', 'même application fermée', P.horloge, ROUGE],
  ];
  const X0 = 40, CL = 228, CG = 15;
  const colonne = {};
  prises.forEach(([id, , , , c], k) => { colonne[id] = { x: X0 + k * (CL + CG), c, pile: [] }; });

  // Les paquets, dans l'ordre où ils tombent : [nom, rôle, prise].
  const paquets = [
    ['sqflite_sqlcipher', 'SQLite chiffré par SQLCipher, schéma en version 6, migrations sans perte.', 'base'],
    ['flutter_secure_storage', 'La clé maîtresse dans le Keystore Android, jamais sur le disque en clair.', 'cle'],
    ['cryptography', 'HKDF pour dériver les clés, AES-GCM pour la clé bancaire et la sauvegarde, PBKDF2 pour la phrase.', 'cle'],
    ['local_auth', 'L\'empreinte, qui charge la clé : sans elle, la base reste illisible.', 'cle'],
    ['flutter_riverpod', 'L\'état : une écriture fait relire tout ce qui en dépend, d\'un seul appel.', 'ecran'],
    ['go_router', 'La navigation, et la garde du verrou sur chaque page.', 'ecran'],
    ['pointycastle', 'La signature RS256 des requêtes à la banque, en Dart, octet pour octet celle d\'OpenSSL.', 'banque'],
    ['workmanager', 'La veille du solde, toutes les six heures, même application fermée.', 'veille'],
    ['flutter_local_notifications', 'L\'unique notification : le compte courant passé en négatif.', 'veille'],
    ['intl', 'Les dates et les montants à la française.', 'ecran'],
    ['material_symbols_icons', 'Cinq cents icônes au choix, arrondies comme l\'interface.', 'ecran'],
  ];
  const TL = CL - 36, TAILLE = 12, PAS = 16.5, ECART = 9;
  const hauteur = (role) => 40 + nLignes(role, TL, TAILLE) * PAS;
  // Les piles, de bas en haut, pour trouver la plus haute.
  const piles = {};
  for (const [, role, id] of paquets) {
    piles[id] = (piles[id] || 0) + hauteur(role) + ECART;
  }
  const HAUT = 80;
  const HY = HAUT + Math.max(...Object.values(piles)) + 4; // le haut des prises
  const PH = 64, SY = HY + PH + 18, SH = 62; // prises, puis socle

  // Le socle.
  const SX = X0, SL = 1200;
  corps += g(0.02, FIN, `<rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="14" fill="${CARTE}" stroke="${BORD}"/>
    <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="14" fill="${BLEU}" fill-opacity="0.04" stroke="${BLEU}" stroke-opacity="0.35"/>
    <path d="M${SX + 30} ${SY + 22} l-9 9 l9 9 M${SX + 44} ${SY + 22} l9 9 l-9 9 M${SX + 40} ${SY + 20} l-6 22" fill="none" stroke="${BLEU}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
    ${t(SX + 72, SY + 38, 'Flutter 3', { taille: 16, couleur: TITRE, police: MONO, poids: 700 })}
    ${t(SX + 190, SY + 38, 'L\'application entière, en Dart, un seul code pour le téléphone et l\'écran déplié.', { taille: 13.5 })}`, 0.01);

  // Les prises, posées sur le socle.
  prises.forEach(([id, titre, sous, icone, c], k) => {
    const x = colonne[id].x, de = 0.05 + k * 0.012;
    colonne[id].hub = [x + CL / 2, HY + PH / 2];
    corps += g(de, FIN, `
      <path d="M${x + CL / 2 - 30} ${HY + PH} V${SY} M${x + CL / 2 + 30} ${HY + PH} V${SY}" stroke="${c}" stroke-opacity="0.5" stroke-width="2"/>
      <circle cx="${x + CL / 2 - 30}" cy="${SY}" r="3.5" fill="${c}"/><circle cx="${x + CL / 2 + 30}" cy="${SY}" r="3.5" fill="${c}"/>
      <rect x="${x}" y="${HY}" width="${CL}" height="${PH}" rx="13" fill="${CARTE}" stroke="${c}" stroke-opacity="0.55"/>
      <rect x="${x}" y="${HY}" width="${CL}" height="${PH}" rx="13" fill="${c}" fill-opacity="0.07"/>
      <g transform="translate(${x + 16},${HY + PH / 2 - 14})">${icone(c)}</g>
      ${t(x + 56, HY + 28, titre, { taille: 15, couleur: TITRE, poids: 800 })}
      ${t(x + 56, HY + 47, sous, { taille: 12, couleur: c })}`, 0.006);
  });

  // Les paquets tombent et s'empilent.
  const TOMBE = (i) => 0.12 + i * 0.028;
  const hautPile = {};
  const briques = {};
  paquets.forEach(([nom, role, id], i) => {
    const col = colonne[id], h = hauteur(role);
    const bas = (hautPile[id] ?? HY - 5);
    const y = bas - ECART + 4 - h;
    hautPile[id] = y;
    const x = col.x, s = TOMBE(i), c = col.c;
    briques[nom] = { x, y, h, c, centre: [x + CL / 2, y + h / 2], s };
    corps += `<g opacity="0">${visible(C, s, FIN, 0.004)}<g>
      <animateTransform attributeName="transform" type="translate" dur="${C}s" repeatCount="indefinite" keyTimes="0;${s.toFixed(4)};${(s + 0.022).toFixed(4)};1" values="0 -70;0 -70;0 0;0 0" calcMode="spline" keySplines="0 0 1 1;0.5 0 0.8 1;0 0 1 1"/>
      <rect x="${x}" y="${y}" width="${CL}" height="${h}" rx="11" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${y}" width="${CL}" height="${h}" rx="11" fill="${c}" fill-opacity="0.05" stroke="${c}" stroke-opacity="0.3"/>
      ${t(x + 18, y + 26, nom, { taille: nom.length > 22 ? 12 : 13.5, couleur: TITRE, police: MONO, poids: 700 })}
      ${para(x + 18, y + 47, role, TL, { taille: TAILLE, pas: PAS })}
    </g></g>`;
    // Il se branche : la prise s'allume.
    corps += `<rect x="${x}" y="${HY}" width="${CL}" height="${PH}" rx="13" fill="none" stroke="${c}" stroke-width="1.8" filter="url(#halo)" opacity="0">${visible(C, s + 0.02, s + 0.05, 0.006)}</rect>`;
    corps += `<rect x="${x}" y="${y}" width="${CL}" height="${h}" rx="11" fill="none" stroke="${c}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, s + 0.02, s + 0.045, 0.006)}</rect>`;
  });

  // ------------------------------------------------------- deux trajets
  const trajets = [
    {
      de: 0.47, pas: 0.036, couleur: NEON,
      legende: 'À l’ouverture : l’empreinte charge la clé, la clé ouvre la base, l’écran se remplit.',
      arrets: ['local_auth', 'flutter_secure_storage', 'cryptography', 'sqflite_sqlcipher', 'flutter_riverpod', 'go_router'],
    },
    {
      de: 0.71, pas: 0.038, couleur: OR,
      legende: 'Toutes les six heures : la veille charge la clé, signe sa requête, lit le solde, et prévient s’il passe en négatif.',
      arrets: ['workmanager', 'flutter_secure_storage', 'cryptography', 'pointycastle', 'banque', 'flutter_local_notifications'],
    },
  ];
  const LY = SY + SH + 34;
  corps += g(0.1, 0.455, t(640, LY, 'Onze paquets, chacun branché sur ce qu’il sert, tous posés sur Flutter 3.', { taille: 14, couleur: TEXTE, ancre: 'middle' }));
  trajets.forEach(({ de, pas, couleur, legende, arrets }) => {
    const fin = de + (arrets.length - 1) * pas + 0.05;
    corps += g(de - 0.01, fin, t(640, LY, legende, { taille: 14, couleur: TITRE, poids: 700, ancre: 'middle' }), 0.006);
    // Chaque arrêt : une brique, ou une prise. Le numéro se pose sur son bord droit.
    const boites = arrets.map((a) => (briques[a] ? [briques[a].x, briques[a].y, CL, briques[a].h, 11] : [colonne[a].x, HY, CL, PH, 13]));
    const points = boites.map(([x, y, l, h]) => [x + l, y + h / 2]);
    boites.forEach(([x, y, l, h, r], k) => {
      const s = de + k * pas;
      corps += `<rect x="${x}" y="${y}" width="${l}" height="${h}" rx="${r}" fill="${couleur}" fill-opacity="0.06" stroke="${couleur}" stroke-width="1.8" opacity="0">${visible(C, s, fin, 0.004)}</rect>`;
      corps += `<rect x="${x}" y="${y}" width="${l}" height="${h}" rx="${r}" fill="none" stroke="${couleur}" stroke-width="2" filter="url(#halo)" opacity="0">${visible(C, s, s + 0.03, 0.004)}</rect>`;
    });
    // La bille file d'un numéro au suivant, et attend à chacun.
    const d = points.map(([x, y], k) => `${k ? 'L' : 'M'}${x.toFixed(1)} ${y.toFixed(1)}`).join(' ');
    const longueurs = [0];
    for (let k = 1; k < points.length; k++) {
      longueurs.push(longueurs[k - 1] + Math.hypot(points[k][0] - points[k - 1][0], points[k][1] - points[k - 1][1]));
    }
    const total = longueurs[longueurs.length - 1];
    const kp = [0], kt = [0];
    points.forEach((_, k) => {
      const s = de + k * pas, f = (longueurs[k] / total).toFixed(4);
      kt.push(s.toFixed(4)); kp.push(f);
      if (k < points.length - 1) { kt.push((s + pas * 0.4).toFixed(4)); kp.push(f); }
    });
    kt.push(1); kp.push(1);
    const motion = `<animateMotion dur="${C}s" repeatCount="indefinite" path="${d}" keyPoints="${kp.join(';')}" keyTimes="${kt.join(';')}" calcMode="linear"/>`;
    corps += `<g opacity="0" filter="url(#halo)">${visible(C, de, fin, 0.004)}
      <circle r="15" fill="${couleur}" opacity="0.25">${motion}</circle>
      <circle r="7" fill="${couleur}">${motion}</circle></g>`;
    points.forEach(([x, y], k) => {
      const s = de + k * pas;
      corps += g(s, fin, `<circle cx="${x}" cy="${y}" r="11" fill="${couleur}" stroke="#0D1117" stroke-width="2"/>${t(x, y + 4.2, String(k + 1), { taille: 12, couleur: '#000000', police: MONO, poids: 700, ancre: 'middle' })}`, 0.004);
    });
  });

  const H = LY + 30;
  svg('stack.svg', 1280, H, corps,
    'La pile de SmartBudget. En socle, Flutter 3 : l’application entière, en Dart, un seul code pour le téléphone et l’écran déplié. Dessus, cinq prises, ce que l’application sert, et chaque paquet s’empile sur la sienne. L’écran : flutter_riverpod pour l’état, une écriture fait relire tout ce qui en dépend, d’un seul appel ; go_router pour la navigation et la garde du verrou sur chaque page ; intl pour les dates et les montants à la française ; material_symbols_icons, cinq cents icônes arrondies comme l’interface. La base : sqflite_sqlcipher, SQLite chiffré par SQLCipher, schéma en version 6, migrations sans perte. La clé : flutter_secure_storage, la clé maîtresse dans le Keystore Android, jamais sur le disque en clair ; cryptography, HKDF pour dériver les clés, AES-GCM pour la clé bancaire et la sauvegarde, PBKDF2 pour la phrase ; local_auth, l’empreinte, qui charge la clé, sans elle la base reste illisible. La banque : pointycastle, la signature RS256 des requêtes, en Dart, octet pour octet celle d’OpenSSL. La veille : workmanager, la veille du solde toutes les six heures, même application fermée ; flutter_local_notifications, l’unique notification, le compte courant passé en négatif. Deux trajets les traversent. À l’ouverture, l’empreinte charge la clé, la clé ouvre la base, l’écran se remplit. Toutes les six heures, la veille charge la clé, signe sa requête, lit le solde à la banque, et prévient s’il passe en négatif.');
};

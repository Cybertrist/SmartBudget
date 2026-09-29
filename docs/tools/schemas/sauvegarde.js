// La sauvegarde : un fichier chiffré par une phrase, qui passe d'un
// téléphone à un autre.
//
// À gauche, ce téléphone exporte : la phrase deux fois, le chiffrement,
// l'enregistrement. Au milieu, ce qui part dans le fichier, et le voyage
// du fichier, illisible en route. À droite, l'autre téléphone restaure :
// une phrase fausse ne touche à rien, la bonne remplace tout d'un bloc.
// Le détail du chiffrement est dans chiffrement.svg : il n'est pas refait.
module.exports = (O) => {
  const { svg, t, fondu, visible, paliers, toucher, frappe, P, APP, MONO, SANS, CARTE, BORD, TITRE, TEXTE, DISCRET, FIL, VERT, NEON, BLEU, OR, ROUGE } = O;
  const C = 36, FIN = 0.975;
  let corps = '';
  corps += t(60, 52, 'LA SAUVEGARDE', { taille: 13, couleur: VERT, police: MONO, poids: 700, extra: 'letter-spacing="3"' });
  corps += t(Math.round(66 + O.tr('LA SAUVEGARDE').length * 10.9 + 24), 52, 'Un fichier chiffré par une phrase que toi seul connais, relisible sur un autre téléphone.', { taille: 14 });

  const PY = 104, PL = 280, PH = 610;
  const telephones = { A: 60, B: 940 };
  corps += t(telephones.A + PL / 2, 90, 'CE TÉLÉPHONE', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, ancre: 'middle', extra: 'letter-spacing="2"' });
  corps += t(telephones.B + PL / 2, 90, 'UN AUTRE TÉLÉPHONE', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, ancre: 'middle', extra: 'letter-spacing="2"' });

  // Un écran visible de [de] à [a].
  // Il n'entre qu'une fois l'écran d'avant sorti : aucun fondu ne se superpose.
  const ecran = (de, a, contenu) => `<g opacity="0">${visible(C, de < 0.01 ? de : de + 0.006, a, 0.003)}${contenu}</g>`;

  // Les briques d'écran, pour un téléphone donné.
  const briques = (X) => {
    const SX = X + 10, SY = PY + 14, SL = PL - 20, SH = PH - 28;
    const b = { SX, SY, SL, SH };
    b.cadre = (id) => `<rect x="${X}" y="${PY}" width="${PL}" height="${PH}" rx="36" fill="#07090C" stroke="#2F3A47" stroke-width="2"/>
      <clipPath id="${id}"><rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="26"/></clipPath>
      <rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" rx="26" fill="${APP.fond}"/>
      <rect x="${X + PL / 2 - 30}" y="${PY + 5}" width="60" height="5" rx="2.5" fill="#1B222C"/>`;
    b.message = (s, de, a) => ecran(de, a, `<rect x="${SX + 10}" y="${SY + SH - 64}" width="${SL - 20}" height="42" rx="10" fill="#2E2E2E"/>
      ${t(SX + 24, SY + SH - 38, s, { taille: 11.5, couleur: APP.texte })}`);
    // L'accueil, rempli ou tout neuf.
    b.accueil = (plein) => {
      const ligne = (y, nom, detail, mt, c, icone) => `
        <rect x="${SX + 24}" y="${y}" width="34" height="34" rx="10" fill="${c}" fill-opacity="0.16" stroke="${c}" stroke-opacity="0.5"/>
        ${icone}
        ${t(SX + 68, y + 14, nom, { taille: 12.5, couleur: APP.texte, poids: 700 })}
        ${t(SX + 68, y + 30, detail, { taille: 10, couleur: APP.discret })}
        ${t(SX + SL - 22, y + 14, mt, { taille: 12, couleur: APP.texte, police: MONO, poids: 700, ancre: 'end' })}`;
      const carteIcone = (y) => `<rect x="${SX + 32}" y="${y + 11}" width="18" height="12" rx="2" fill="none" stroke="${VERT}" stroke-width="1.8"/><path d="M${SX + 32} ${y + 15} h18" stroke="${VERT}" stroke-width="2"/>`;
      const demi = (SL - 30) / 2;
      return `<text x="${SX + 16}" y="${SY + 44}" font-family="${SANS}" font-size="19" font-weight="800" fill="${APP.texte}">Smart <tspan fill="${NEON}">Budget</tspan></text>
        ${t(SX + SL - 16, SY + 43, 'Septembre 2026', { taille: 11, couleur: APP.second, poids: 700, ancre: 'end' })}
        ${t(SX + 18, SY + 80, 'Sur tes comptes', { taille: 11.5, couleur: APP.second, poids: 600 })}
        ${t(SX + 16, SY + 116, plein ? '4 125,33 €' : '0,00 €', { taille: 31, couleur: APP.texte, poids: 800 })}
        ${plein ? t(SX + 18, SY + 144, 'Mis à jour le 26 sept.', { taille: 11.5, couleur: APP.discret }) : ''}
        <rect x="${SX + 10}" y="${SY + 166}" width="${SL - 20}" height="${plein ? 160 : 100}" rx="14" fill="${APP.carte}"/>
        ${t(SX + 24, SY + 192, 'MES COMPTES', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
        ${t(SX + SL - 24, SY + 192, plein ? '2 comptes' : '1 compte', { taille: 10.5, couleur: APP.discret, ancre: 'end' })}
        ${ligne(SY + 208, 'Compte courant', plein ? 'Crédit Mutuel de Bretagne' : 'Compte bancaire', plein ? '1 065,33 €' : '0,00 €', VERT, carteIcone(SY + 208))}
        ${plein ? `<line x1="${SX + 24}" y1="${SY + 256}" x2="${SX + SL - 24}" y2="${SY + 256}" stroke="${APP.trait}"/>
          ${ligne(SY + 270, 'Livret A', 'Livret d’épargne', '3 060,00 €', BLEU, t(SX + 41, SY + 292, '€', { taille: 16, couleur: BLEU, poids: 800, ancre: 'middle' }))}` : ''}
        <g transform="translate(0,${plein ? 0 : -60})">
          <rect x="${SX + 10}" y="${SY + 340}" width="${demi}" height="118" rx="14" fill="${APP.carte}"/>
          <rect x="${SX + 20 + demi}" y="${SY + 340}" width="${demi}" height="118" rx="14" fill="${APP.carte}"/>
          ${t(SX + 24, SY + 366, 'BUDGET', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
          ${t(SX + 34 + demi, SY + 366, 'ÉPARGNE', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
          ${plein
            ? `${t(SX + 24, SY + 398, '247,41 €', { taille: 18, couleur: VERT, poids: 800 })}
              ${t(SX + 24, SY + 416, 'restants sur 1 500 €', { taille: 10, couleur: APP.second })}
              <rect x="${SX + 24}" y="${SY + 436}" width="${demi - 28}" height="6" rx="3" fill="#2A2A2A"/>
              <rect x="${SX + 24}" y="${SY + 436}" width="${(demi - 28) * 0.835}" height="6" rx="3" fill="${VERT}"/>
              ${t(SX + 34 + demi, SY + 398, '3 060,00 €', { taille: 15, couleur: APP.texte, poids: 800 })}
              ${t(SX + 34 + demi, SY + 416, '61 % de 5 000 €', { taille: 10, couleur: APP.second })}`
            : `${t(SX + 24, SY + 396, 'Fixer un', { taille: 13, couleur: VERT, poids: 800 })}
              ${t(SX + 24, SY + 413, 'budget', { taille: 13, couleur: VERT, poids: 800 })}
              ${t(SX + 24, SY + 434, 'pour voir ce qu’il reste', { taille: 9.5, couleur: APP.second })}
              ${t(SX + 34 + demi, SY + 396, 'Ajouter', { taille: 13, couleur: BLEU, poids: 800 })}
              ${t(SX + 34 + demi, SY + 413, 'un livret', { taille: 13, couleur: BLEU, poids: 800 })}
              ${t(SX + 34 + demi, SY + 434, 'la banque ne les', { taille: 9.5, couleur: APP.second })}
              ${t(SX + 34 + demi, SY + 447, 'partage pas', { taille: 9.5, couleur: APP.second })}`}
        </g>`;
    };
    // Les réglages, descendus jusqu'à la sauvegarde.
    b.reglages = () => {
      const bascule = (y, on) => `<rect x="${SX + SL - 60}" y="${y - 10}" width="34" height="20" rx="10" fill="${on ? VERT : '#3A3A3A'}"/><circle cx="${SX + SL - (on ? 36 : 50)}" cy="${y}" r="7" fill="${on ? '#000000' : '#9A9A9A'}"/>`;
      const ligneR = (y, s, droite = '', tuile = false) => `<line x1="${SX + 24}" y1="${y - 26}" x2="${SX + SL - 24}" y2="${y - 26}" stroke="${APP.trait}"/>
        ${tuile ? `<rect x="${SX + 24}" y="${y - 17}" width="30" height="30" rx="10" fill="#FFFFFF" fill-opacity="0.04"/>` : ''}
        ${t(SX + (tuile ? 64 : 26), y + 4, s, { taille: tuile ? 12.5 : 11.5, couleur: APP.texte, poids: 600 })}${droite}`;
      const chevron = (y) => `<path d="M${SX + SL - 34} ${y - 5} l5 5 l-5 5" fill="none" stroke="${APP.discret}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>`;
      const fleche = (y, haut) => `<path d="M${SX + 39} ${y + (haut ? 6 : -6)} V${y + (haut ? -6 : 6)} M${SX + 34} ${y + (haut ? -1 : 1)} L${SX + 39} ${y + (haut ? -6 : 6)} L${SX + 44} ${y + (haut ? -1 : 1)}" fill="none" stroke="${APP.second}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>`;
      return `${t(SX + 18, SY + 50, 'Réglages', { taille: 22, couleur: APP.texte, poids: 800 })}
                <rect x="${SX + 10}" y="${SY + 88}" width="${SL - 20}" height="196" rx="14" fill="${APP.carte}"/>
        ${t(SX + 24, SY + 114, 'SÉCURITÉ', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
        ${ligneR(SY + 156, 'Empreinte à l’ouverture', bascule(SY + 152, true))}
        ${ligneR(SY + 208, 'Verrouiller après', t(SX + SL - 26, SY + 212, '1 minute', { taille: 11, couleur: APP.discret, ancre: 'end' }))}
        ${ligneR(SY + 260, 'Masquer dans le multitâche', bascule(SY + 256, true))}
        <rect x="${SX + 10}" y="${SY + 298}" width="${SL - 20}" height="146" rx="14" fill="${APP.carte}"/>
        ${t(SX + 24, SY + 324, 'SAUVEGARDE', { taille: 10, couleur: APP.second, poids: 700, extra: 'letter-spacing="1.6"' })}
        ${ligneR(SY + 366, 'Exporter, chiffré', chevron(SY + 362), true)}${fleche(SY + 362, true)}
        ${ligneR(SY + 418, 'Restaurer une sauvegarde', chevron(SY + 414), true)}${fleche(SY + 414, false)}`;
    };
    b.lignes = { exporter: SY + 362, restaurer: SY + 414 };
    // La carte de la phrase, posée sur le clavier.
    b.phrase = (nouvelle, de, frappes, puces2) => {
      const cy = SY + (nouvelle ? 146 : 196), h = nouvelle ? 250 : 172;
      const aide = nouvelle
        ? ['Elle chiffre le fichier. Sans elle,', 'personne ne peut le relire, toi non', 'plus : note-la bien.']
        : ['Celle choisie au moment de l’export.'];
      const champ = (y, indice, f) => `<rect x="${SX + 26}" y="${y}" width="${SL - 52}" height="34" rx="9" fill="#2A2A2A"/>
        <g>${fondu('opacity', C, [[0, 1], [f[0], 1], [f[0] + 0.002, 0], [1, 0]])}${t(SX + 38, y + 22, indice, { taille: 11.5, couleur: APP.discret })}</g>
        ${frappe(SX + 38, y + 23, f[2], C, f[0], f[1], { taille: 13, couleur: APP.texte, police: MONO, poids: 800 })}`;
      let s = `<rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000000" fill-opacity="0.55"/>
        <rect x="${SX + 10}" y="${cy}" width="${SL - 20}" height="${h}" rx="18" fill="#242424"/>
        ${t(SX + 26, cy + 32, 'Phrase de la sauvegarde', { taille: 15, couleur: APP.texte, poids: 800 })}
        ${aide.map((l, i) => t(SX + 26, cy + 54 + i * 16, l, { taille: 11, couleur: APP.second })).join('')}`;
      const y1 = cy + (nouvelle ? 104 : 76);
      s += champ(y1, 'Au moins 8 caractères', frappes[0]);
      if (nouvelle) s += champ(y1 + 44, 'La même, une seconde fois', frappes[1]);
      const by = cy + h - 50;
      s += `${t(SX + SL - 150, by + 23, 'Annuler', { taille: 12.5, couleur: VERT, poids: 700, ancre: 'middle' })}
        <rect x="${SX + SL - 110}" y="${by}" width="88" height="36" rx="18" fill="${VERT}"/>
        ${t(SX + SL - 66, by + 23, nouvelle ? 'Chiffrer' : 'Restaurer', { taille: 12, couleur: '#000000', poids: 800, ancre: 'middle' })}`;
      // Le clavier.
      const ky = SY + SH - 168;
      s += `<rect x="${SX}" y="${ky}" width="${SL}" height="168" fill="#1A1A1A"/>`;
      [10, 9, 7].forEach((n, r) => {
        const w = (SL - 16 - (n - 1) * 4) / 10;
        const x0 = SX + 8 + (10 - n) * (w + 4) / 2;
        for (let i = 0; i < n; i++) s += `<rect x="${(x0 + i * (w + 4)).toFixed(1)}" y="${ky + 12 + r * 38}" width="${w.toFixed(1)}" height="30" rx="5" fill="#333333"/>`;
      });
      s += `<rect x="${SX + 60}" y="${ky + 126}" width="${SL - 120}" height="30" rx="5" fill="#333333"/>`;
      return { svg: s, bouton: [SX + SL - 66, by + 18] };
    };
    // Le sélecteur de fichiers du système.
    b.selecteur = (titre, fichiers, enregistrer) => {
      let s = `<rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#1B1B1F"/>
        <path d="M${SX + 20} ${SY + 40} h16 M${SX + 20} ${SY + 46} h16 M${SX + 20} ${SY + 52} h16" stroke="#E3E3E8" stroke-width="2" stroke-linecap="round"/>
        ${t(SX + 50, SY + 51, titre, { taille: 16, couleur: '#E3E3E8', poids: 700 })}
        ${t(SX + 20, SY + 92, 'Téléchargements', { taille: 10.5, couleur: '#A9A9B2', poids: 700 })}`;
      fichiers.forEach(([nom, clair], i) => {
        const y = SY + 108 + i * 52;
        s += `<rect x="${SX + 12}" y="${y}" width="${SL - 24}" height="44" rx="10" fill="${clair ? VERT : '#FFFFFF'}" fill-opacity="${clair ? 0.12 : 0.03}" ${clair ? `stroke="${VERT}" stroke-opacity="0.5"` : ''}/>
          <g transform="translate(${SX + 20},${y + 8})">${P.fichier(clair ? VERT : '#8A8A94')}</g>
          ${t(SX + 56, y + 27, nom, { taille: 11, couleur: clair ? '#FFFFFF' : '#8A8A94', police: MONO, poids: clair ? 700 : 400 })}`;
      });
      if (enregistrer) {
        s += `<rect x="${SX}" y="${SY + SH - 96}" width="${SL}" height="96" fill="#26262B"/>
          <rect x="${SX + 14}" y="${SY + SH - 82}" width="${SL - 28}" height="30" rx="6" fill="#1B1B1F" stroke="#4A4A55"/>
          ${t(SX + 22, SY + SH - 62, 'smartbudget-2026-09-26.sbx', { taille: 10.5, couleur: '#FFFFFF', police: MONO })}
          <rect x="${SX + SL - 118}" y="${SY + SH - 44}" width="104" height="30" rx="15" fill="#A8C7FA"/>
          ${t(SX + SL - 66, SY + SH - 24.5, 'Enregistrer', { taille: 11.5, couleur: '#062E6F', poids: 700, ancre: 'middle' })}`;
      }
      return s;
    };
    // La boîte « Restaurer cette sauvegarde ? ».
    b.dialogue = () => `<rect x="${SX}" y="${SY}" width="${SL}" height="${SH}" fill="#000000" fill-opacity="0.6"/>
      <rect x="${SX + 16}" y="${SY + 200}" width="${SL - 32}" height="172" rx="22" fill="#2A2A2A"/>
      ${t(SX + 34, SY + 236, 'Restaurer cette sauvegarde ?', { taille: 14, couleur: APP.texte, poids: 800 })}
      ${['Tout ce qui est dans l’application', 'sera remplacé par le contenu de', 'la sauvegarde.'].map((l, i) => t(SX + 34, SY + 262 + i * 17, l, { taille: 11.5, couleur: APP.second })).join('')}
      ${t(SX + SL - 128, SY + 350, 'Annuler', { taille: 12.5, couleur: VERT, poids: 700, ancre: 'middle' })}
      ${t(SX + SL - 58, SY + 350, 'Remplacer', { taille: 12.5, couleur: ROUGE, poids: 700, ancre: 'middle' })}`;
    b.tapDialogue = [SX + SL - 58, SY + 346];
    return b;
  };

  // --------------------------------------------------- ce téléphone : l'export
  const A = briques(telephones.A);
  corps += A.cadre('ecranSauvA');
  let ea = '';
  const phraseA = A.phrase(true, 0, [[0.098, 0.128, '●●●●●●●●●●●●●'], [0.134, 0.162, '●●●●●●●●●●●●●']]);
  ea += ecran(0.003, 0.04, A.accueil(true));
  ea += ecran(0.04, 0.085, A.reglages() + toucher(A.SX + 130, A.lignes.exporter, C, 0.072));
  ea += ecran(0.085, 0.186, A.reglages() + phraseA.svg + toucher(phraseA.bouton[0], phraseA.bouton[1], C, 0.176));
  ea += ecran(0.186, 0.25, A.reglages());
  ea += A.message('Chiffrement de la sauvegarde…', 0.188, 0.25);
  ea += ecran(0.25, 0.315, A.selecteur('Enregistrer dans', [['releve-aout.pdf', false], ['billet-train.pdf', false]], true) + toucher(A.SX + A.SL - 66, A.SY + A.SH - 29, C, 0.3));
  ea += ecran(0.315, 0.42, A.reglages());
  ea += ecran(0.42, FIN, A.accueil(true));
  ea += A.message('Sauvegarde enregistrée.', 0.318, 0.418);
  corps += `<g clip-path="url(#ecranSauvA)">${ea}</g>`;

  // ------------------------------------------- l'autre téléphone : la restauration
  const B = briques(telephones.B);
  corps += B.cadre('ecranSauvB');
  let eb = '';
  const ouvrir = (de, a, tap) => ecran(de, a, B.selecteur('Ouvrir depuis', [['smartbudget-2026-09-26.sbx', true], ['photo-identite.jpg', false]], false) + toucher(B.SX + 130, B.SY + 130, C, tap));
  const phraseB1 = B.phrase(false, 0, [[0.608, 0.636, '●●●●●●●●●●●']]);
  const phraseB2 = B.phrase(false, 0, [[0.772, 0.794, '●●●●●●●●●●●●●']]);
  eb += ecran(0.003, 0.455, B.accueil(false));
  eb += `<g opacity="0">${visible(C, 0.02, 0.44, 0.004)}<rect x="${B.SX + 40}" y="${B.SY + B.SH - 58}" width="${B.SL - 80}" height="30" rx="15" fill="#2E2E2E"/>${t(B.SX + B.SL / 2, B.SY + B.SH - 38.5, 'l’appli vient d’être installée', { taille: 11, couleur: APP.second, ancre: 'middle' })}</g>`;
  eb += ecran(0.455, 0.5, B.reglages() + toucher(B.SX + 130, B.lignes.restaurer, C, 0.485));
  eb += ouvrir(0.5, 0.545, 0.532);
  eb += ecran(0.545, 0.597, B.reglages() + B.dialogue() + toucher(B.tapDialogue[0], B.tapDialogue[1], C, 0.584));
  eb += ecran(0.597, 0.667, B.reglages() + phraseB1.svg + toucher(phraseB1.bouton[0], phraseB1.bouton[1], C, 0.654));
  eb += ecran(0.667, 0.725, B.reglages());
  eb += B.message('Déchiffrement…', 0.668, 0.684);
  eb += ecran(0.684, 0.724, `<rect x="${B.SX + 10}" y="${B.SY + B.SH - 64}" width="${B.SL - 20}" height="42" rx="10" fill="#2E2E2E" stroke="${ROUGE}" stroke-opacity="0.5"/>
    ${t(B.SX + 22, B.SY + B.SH - 38, 'Phrase incorrecte, ou fichier abîmé.', { taille: 11, couleur: APP.texte })}`);
  // Le second essai, plus vite : les mêmes écrans, la bonne phrase.
  eb += ecran(0.725, 0.738, B.reglages() + toucher(B.SX + 130, B.lignes.restaurer, C, 0.731));
  eb += ouvrir(0.738, 0.752, 0.746);
  eb += ecran(0.752, 0.766, B.reglages() + B.dialogue() + toucher(B.tapDialogue[0], B.tapDialogue[1], C, 0.76));
  eb += ecran(0.766, 0.806, B.reglages() + phraseB2.svg + toucher(phraseB2.bouton[0], phraseB2.bouton[1], C, 0.8));
  eb += ecran(0.806, 0.852, B.reglages());
  eb += B.message('Déchiffrement…', 0.807, 0.852);
  eb += ecran(0.852, FIN, B.accueil(true));
  eb += B.message('Sauvegarde restaurée.', 0.853, FIN);
  corps += `<g clip-path="url(#ecranSauvB)">${eb}</g>`;

  // --------------------------------------------------------- au milieu
  const MX = 380, ML = 520;
  // 1. Ce qui part dans le fichier.
  corps += t(MX, 128, 'CE QUI PART DANS LE FICHIER', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const tables = ['catégories', 'comptes', 'opérations', 'règles', 'liens', 'réglages'];
  const tl = (ML - 5 * 8) / 6;
  tables.forEach((n, i) => {
    const de = 0.19 + i * 0.005;
    corps += `<rect x="${MX + i * (tl + 8)}" y="142" width="${tl}" height="34" rx="9" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${MX + i * (tl + 8)}" y="142" width="${tl}" height="34" rx="9" fill="${OR}" fill-opacity="0.1" stroke="${OR}" stroke-opacity="0.6" opacity="0">${visible(C, de, FIN, 0.004)}</rect>
      ${t(MX + i * (tl + 8) + tl / 2, 163.5, n, { taille: 11.5, couleur: TITRE, poids: 600, ancre: 'middle' })}`;
  });
  corps += t(MX, 200, 'Les six tables, ligne par ligne, et la version de la base. Puis compressé,', { taille: 12 });
  corps += t(MX, 217, 'et chiffré par ta phrase : le schéma du chiffrement le détaille.', { taille: 12 });
  // Le fichier, qui naît chiffré.
  const NE = 0.235;
  corps += `<rect x="${MX}" y="232" width="${ML}" height="62" rx="13" fill="${CARTE}" stroke="${BORD}"/>
    <rect x="${MX}" y="232" width="${ML}" height="62" rx="13" fill="none" stroke="${OR}" stroke-width="1.5" filter="url(#halo)" opacity="0">${visible(C, NE, NE + 0.05, 0.004)}</rect>
    <rect x="${MX}" y="232" width="${ML}" height="62" rx="13" fill="${OR}" fill-opacity="0.05" stroke="${OR}" stroke-opacity="0.3"/>
    <g transform="translate(${MX + 18},249)">${P.fichier(OR)}</g>
    <g opacity="0.35">${paliers('opacity', C, [[0, 0.35], [NE, 1], [FIN, 0.35]])}
      ${t(MX + 58, 258, 'smartbudget-2026-09-26.sbx', { taille: 14, couleur: TITRE, police: MONO, poids: 700 })}
      ${t(MX + 58, 278, 'le nom du jour ; environ une seconde de calcul pour le chiffrer', { taille: 12 })}
    </g>`;

  // 2. Le voyage.
  corps += t(MX, 330, 'IL VOYAGE, ILLISIBLE', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const arrets = [
    [MX + 40, 'Téléchargements', P.fichier],
    [MX + ML / 2, 'un ordinateur', (c) => `<rect x="2" y="4" width="24" height="16" rx="2" fill="none" stroke="${c}" stroke-width="2"/><path d="M9 25 H19 M14 20 V25" stroke="${c}" stroke-width="2"/>`],
    [MX + ML - 40, 'un nuage', P.nuage],
  ];
  const TY = 378;
  corps += `<line x1="${telephones.A + PL + 4}" y1="${TY}" x2="${telephones.B - 4}" y2="${TY}" stroke="${FIL}" stroke-width="2" stroke-dasharray="4 7"/>`;
  arrets.forEach(([x, nom, icone], i) => {
    const de = 0.34 + i * 0.045;
    corps += `<circle cx="${x}" cy="${TY}" r="22" fill="${CARTE}" stroke="${BORD}" stroke-width="1.5"/>
      <circle cx="${x}" cy="${TY}" r="22" fill="none" stroke="${OR}" stroke-width="1.8" opacity="0">${visible(C, de, de + 0.04, 0.004)}</circle>
      <g transform="translate(${x - 14},${TY - 14})">${icone(TEXTE)}</g>
      ${t(x, TY + 40, nom, { taille: 12, couleur: TEXTE, ancre: 'middle' })}`;
  });
  corps += `<g filter="url(#halo)" opacity="0">${fondu('opacity', C, [[0, 0], [0.32, 0], [0.325, 1], [0.45, 1], [0.455, 0], [1, 0]])}
    <circle cy="${TY}" r="6" fill="${OR}"><animate attributeName="cx" dur="${C}s" repeatCount="indefinite" keyTimes="0;0.325;0.45;1" values="${telephones.A + PL};${telephones.A + PL};${telephones.B};${telephones.B}"/></circle></g>`;
  // Ce qu'on en voit, vu de dehors.
  corps += `<rect x="${MX}" y="436" width="${ML}" height="62" rx="12" fill="#0A0E14" stroke="${BORD}"/>
    ${t(MX + 16, 460, '53 42 45 58 31  9f 3a c1 7e 02 b4 5d e8 71 0c a6 3f 94 …', { taille: 12, couleur: DISCRET, police: MONO })}
    ${t(MX + 16, 482, 'Sans la phrase, rien ne se relit : ni un curieux, ni toi.', { taille: 12, couleur: OR })}`;

  // 3. À la restauration.
  corps += t(MX, 534, 'À LA RESTAURATION', { taille: 11.5, couleur: DISCRET, police: MONO, poids: 700, extra: 'letter-spacing="2"' });
  const controles = [
    ['Phrase fausse : rien n’est touché', 'le MAC ne concorde pas, on s’arrête', ROUGE, 0.686],
    ['Bonne phrase, fichier intact', 'en-tête SBEX1, MAC d’AES-GCM juste', VERT, 0.815],
    ['Une sauvegarde de Smart Budget', 'd’une version que l’appli sait relire', VERT, 0.828],
    ['Tout remplacé d’un bloc', 'une seule transaction : tout, ou rien', VERT, 0.841],
  ];
  const CL = (ML - 12) / 2;
  controles.forEach(([titre, sous, c, de], i) => {
    const x = MX + (i % 2) * (CL + 12), y = 548 + Math.floor(i / 2) * 84;
    corps += `<rect x="${x}" y="${y}" width="${CL}" height="72" rx="12" fill="${CARTE}" stroke="${BORD}"/>
      <rect x="${x}" y="${y}" width="${CL}" height="72" rx="12" fill="${c}" fill-opacity="0.06" stroke="${c}" stroke-opacity="0.6" opacity="0">${visible(C, de, FIN, 0.004)}</rect>
      <circle cx="${x + 24}" cy="${y + 26}" r="10" fill="none" stroke="${FIL}" stroke-width="2"/>
      <g opacity="0">${visible(C, de, FIN, 0.004)}
        <circle cx="${x + 24}" cy="${y + 26}" r="10" fill="${c}"/>
        ${c === ROUGE
          ? `<path d="M${x + 20} ${y + 22} l8 8 M${x + 28} ${y + 22} l-8 8" stroke="#000000" stroke-width="2.4" stroke-linecap="round"/>`
          : `<path d="M${x + 19} ${y + 26} l3.5 3.5 l7 -7" fill="none" stroke="#000000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`}
      </g>
      ${t(x + 44, y + 30, titre, { taille: 12.5, couleur: TITRE, poids: 700 })}
      ${t(x + 44, y + 50, sous, { taille: 11, couleur: TEXTE })}`;
  });

  corps += t(640, 748, 'La phrase ne se retrouve pas : perdue, la sauvegarde l’est aussi. Garde-la ailleurs que dans le téléphone.', { taille: 13, couleur: DISCRET, ancre: 'middle' });
  svg('sauvegarde.svg', 1280, 772, corps,
    'La sauvegarde, entre deux téléphones animés. Sur ce téléphone, Réglages, Sauvegarde, Exporter, chiffré : la carte Phrase de la sauvegarde demande une phrase d’au moins huit caractères, deux fois, et prévient que sans elle personne ne peut relire le fichier, pas même toi. Les six tables, catégories, comptes, opérations, règles, liens et réglages, partent dans le fichier avec la version de la base, compressées puis chiffrées par la phrase. Le sélecteur du système enregistre smartbudget-2026-09-26.sbx dans les Téléchargements : Sauvegarde enregistrée. Le fichier voyage, par les Téléchargements, un ordinateur ou un nuage, et reste illisible sans la phrase. Sur un autre téléphone où l’appli vient d’être installée, Restaurer une sauvegarde : on choisit le fichier, on confirme Remplacer, car tout ce qui est dans l’application sera remplacé. Une phrase fausse donne Phrase incorrecte, ou fichier abîmé, et rien n’est touché. La bonne phrase passe les contrôles : l’en-tête SBEX1 et le MAC d’AES-GCM, une sauvegarde de Smart Budget d’une version connue, puis tout est remplacé d’un bloc, en une seule transaction. Sauvegarde restaurée : l’accueil affiche les mêmes 4 125,33 euros que l’ancien téléphone. La phrase ne se retrouve pas : perdue, la sauvegarde l’est aussi.');
};

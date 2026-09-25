// Récupère, une fois, l'icône de l'application mobile des banques, celle de
// leur fiche Google Play. Les icônes sont rangées dans assets/banques/ et
// l'application les lit de là : elle ne demande jamais rien à un service
// tiers.
//
// Deux passes :
// 1. les grandes banques, à la main : une recherche, et le titre attendu
//    (ou l'identifiant de l'application quand la recherche se trompe) ;
// 2. toutes les autres banques d'Enable Banking, une par une : la fiche
//    n'est prise que si elle est rangée en Finance et que son titre porte
//    les mots qui distinguent la banque.
//
// Chaque icône est ensuite remise d'aplomb : fond blanc intégré (comme le
// lanceur d'Android pour une icône transparente), coins arrondis et marges
// transparentes retirés, 144 pixels en WebP. Les icônes identiques ne sont
// gardées qu'une fois.
//
// Génère enfin lib/banque/logos_banques.dart.
//
//   cd tool && npm install && node logos_banques.mjs
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import sharp from 'sharp';

const racine = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1')), '..');
const dossier = path.join(racine, 'assets/banques');
const cache = path.join(racine, 'tool/.cache/icones');

// [fichier, recherche sur Google Play, ce que le titre de la fiche doit
// contenir, motif sur le nom d'Enable Banking sans accents ni majuscules,
// et l'identifiant de l'application quand la recherche se trompe]
const grandes = [
  // France
  ['bnp', 'Mes Comptes BNP Paribas', 'bnp', 'bnp paribas(?! fortis)'],
  ['sg', "L'Appli Société Générale", 'societe generale|sg', 'societe generale|^sg\\b'],
  ['ca', 'Ma Banque Crédit Agricole', 'credit agricole|ma banque', 'credit agricole'],
  ['cmb', 'CMB suivi de compte', 'cmb', 'credit mutuel de bretagne'],
  ['cmso', 'CMSO banque', 'cmso', 'credit mutuel du sud-ouest|cmso'],
  ['cm', 'Crédit Mutuel banque', 'credit mutuel', 'credit mutuel(?! ?maritime)'],
  ['cic', 'CIC banque mobile', 'cic', '^cic\\b'],
  ['lcl', 'LCL Mes Comptes', 'lcl', '^lcl\\b'],
  ['lbp', 'La Banque Postale', 'banque postale', 'banque postale'],
  ['ce', "Caisse d'Epargne", 'banxo', 'caisse d.epargne', 'com.caisseepargne.android.mobilebanking'],
  // La BRED avant les Banques Populaires : son nom contient le leur.
  ['bred', 'BRED', 'bred', '^bred\\b'],
  ['bp', 'Banque Populaire', 'banque populaire', 'banque populaire'],
  ['bourso', 'BoursoBank', 'bourso', 'boursorama|boursobank'],
  ['fortuneo', 'Fortuneo', 'fortuneo', 'fortuneo'],
  ['hello', 'Hello bank!', 'hello', 'hello ?bank'],
  ['bforbank', 'BforBank', 'bforbank', 'bforbank'],
  ['monabanq', 'Monabanq', 'monabanq', 'monabanq'],
  ['nickel', 'Nickel compte', 'nickel', '^nickel'],
  ['shine', 'Shine compte pro', 'shine', '^shine'],
  ['qonto', 'Qonto', 'qonto', '^qonto'],
  ['axa', 'AXA Banque', 'axa', 'axa banque'],
  ['hsbc', 'HSBC UK', 'hsbc', '^hsbc', 'uk.co.hsbc.hsbcukmobilebanking'],
  ['sumeria', 'Sumeria Lydia', 'sumeria|lydia', 'lydia|sumeria'],
  ['coop', 'Crédit Coopératif', 'cooperatif', 'credit cooperatif'],
  // Néobanques et banques en ligne européennes
  ['revolut', 'Revolut', 'revolut', '^revolut'],
  ['n26', 'N26', 'n26', '^n26'],
  ['wise', 'Wise', 'wise', '^wise\\b'],
  ['bunq', 'bunq', 'bunq', '^bunq'],
  ['traderepublic', 'Trade Republic', 'trade republic', 'trade republic'],
  ['ing', 'ING France', 'ing', '^ing\\b'],
  // Allemagne
  ['deutsche', 'Deutsche Bank Mobile', 'deutsche bank', 'deutsche bank'],
  ['commerzbank', 'Commerzbank Banking', 'commerzbank', 'commerzbank'],
  ['sparkasse', 'Sparkasse Ihre mobile Filiale', 'sparkasse', 'sparkasse'],
  ['volksbank', 'VR Banking', 'vr banking|volksbank', 'volksbank|raiffeisenbank|vr ?bank'],
  ['dkb', 'DKB', 'dkb', '^dkb\\b|deutsche kreditbank'],
  ['comdirect', 'comdirect', 'comdirect', 'comdirect'],
  ['postbank', 'Postbank', 'postbank', 'postbank'],
  // Espagne, Italie, Portugal
  ['santander', 'Santander', 'santander', 'santander'],
  ['bbva', 'BBVA España', 'bbva', '^bbva'],
  ['caixabank', 'CaixaBank', 'caixabank', 'caixabank|la caixa'],
  ['sabadell', 'Banco Sabadell', 'sabadell', 'sabadell'],
  ['bankinter', 'Bankinter', 'bankinter', 'bankinter'],
  ['intesa', 'Intesa Sanpaolo Mobile', 'intesa', 'intesa sanpaolo'],
  ['unicredit', 'UniCredit', 'unicredit', 'unicredit'],
  ['fineco', 'Fineco', 'fineco', 'fineco'],
  ['millennium', 'Millennium bcp', 'millennium', 'millennium'],
  ['cgd', 'Caixadirecta', 'caixadirecta|cgd', 'caixa geral'],
  // Benelux
  ['kbc', 'KBC Mobile', 'kbc', '^kbc'],
  ['belfius', 'Belfius Mobile', 'belfius', 'belfius'],
  ['fortis', 'Easy Banking BNP Paribas Fortis', 'fortis|easy banking', 'bnp paribas fortis'],
  ['abnamro', 'ABN AMRO', 'abn amro', 'abn amro'],
  ['rabobank', 'Rabo Bankieren', 'rabo', 'rabobank'],
  // Nord
  ['nordea', 'Nordea Mobile', 'nordea', 'nordea'],
  ['danske', 'Danske Mobile Banking', 'danske', 'danske bank', 'com.danskebank.mobilebank3.dk'],
  ['swedbank', 'Swedbank', 'swedbank', 'swedbank'],
  ['seb', 'SEB', '^seb', '^seb\\b', 'se.seb.privatkund'],
  ['handelsbanken', 'Handelsbanken', 'handelsbanken', 'handelsbanken'],
  ['dnb', 'DNB', 'dnb', '^dnb\\b'],
  // Royaume-Uni
  ['barclays', 'Barclays', 'barclays', 'barclays'],
  ['lloyds', 'Lloyds Bank Mobile Banking', 'lloyds', '^lloyds'],
  ['natwest', 'NatWest', 'natwest', 'natwest'],
  ['monzo', 'Monzo', 'monzo', '^monzo'],
  ['starling', 'Starling Bank', 'starling', '^starling'],
];

// Les banques dont la fiche trouvée est celle d'une autre, relues une à
// une sur les planches : elles gardent leurs initiales.
const exclues = new Set([
  'Bundesbank', // une application d'avantages pour les agents
  'Croatia Banka', // George, l'application d'Erste
  'Generali Bank', // Banca Generali, une autre banque
  'Banca Galileo',
  'Cherry Bank',
  'National-Bank', // la Banque Nationale du Canada
  'Unicre', // UniCredit
  'Union-Bank', // Union ease, sans rapport
  'SpareBank 1 Sør-Norge', // Sparebanken Norge, une autre caisse
  'Smart Bank',
  'Solution Bank',
  'YAP', // YAP Pakistan
  'ZKB Credito Cooperativo', // la banque cantonale de Zurich
  'ibank',
  'Julius Baer', // l'application indienne
  'MUFG Bank', // un gestionnaire de cartes, sans le logo
  'Banco Pichincha', // l'application équatorienne
]);

// Les mots qui ne distinguent aucune banque : ils ne suffisent jamais à
// reconnaître une fiche.
const generiques = new Set(`bank banks banque banca banco bancaria bancario banka banken bankas banka
  de des du der die das den di del della delle dei la le les el los the of and und et y e i
  ag eg sa spa s.p.a scpa ab asa as a/s plc ltd limited group groupe gruppo holding nv bv
  private privee privat privata europe international sucursal branch filiale france italia
  espana deutschland credit credito cooperativo cooperativa kredit kreditbank sparbank sparebank
  cassa caixa caisse caja kasse mutuel mutua popolare popular raiffeisen online mobile app`.split(/\s+/));

const entetes = {
  'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36',
  'accept-language': 'fr-FR,fr;q=0.9',
};
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));
const simple = (s) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/’/g, "'");
const decoder = (s) => s.replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"');

async function texte(url) {
  for (let essai = 0; essai < 3; essai++) {
    try {
      const r = await fetch(url, { headers: entetes, signal: AbortSignal.timeout(30000) });
      if (r.status === 429) {
        await attendre(20000);
        continue;
      }
      if (!r.ok) throw new Error(`${r.status}`);
      return await r.text();
    } catch (e) {
      if (essai === 2) throw e;
      await attendre(3000);
    }
  }
}

// Ce que Google Play a déjà répondu, gardé d'une fois sur l'autre : on
// peut retoucher le traitement des images sans tout redemander.
const fichierMemoire = path.join(cache, '..', 'play.json');
const memoire = fs.existsSync(fichierMemoire) ? JSON.parse(fs.readFileSync(fichierMemoire, 'utf8')) : { fiches: {}, recherches: {} };
const retenir = () => fs.writeFileSync(fichierMemoire, JSON.stringify(memoire));

/// Une fiche Google Play : son titre, son icône, et si elle est en Finance.
async function lireFiche(id) {
  if (memoire.fiches[id]) return memoire.fiches[id];
  const html = await texte(`https://play.google.com/store/apps/details?id=${id}&hl=fr&gl=FR`);
  memoire.fiches[id] = {
    id,
    nom: decoder(/<meta property="og:title" content="([^"]+)"/.exec(html)?.[1] ?? '').split(' – ')[0],
    image: /<meta property="og:image" content="([^"=]+)=/.exec(html)?.[1],
    finance: /"applicationCategory":"FINANCE"/.test(html),
  };
  retenir();
  return memoire.fiches[id];
}

async function chercher(recherche, accepter, max = 4) {
  let ids = memoire.recherches[recherche];
  if (!ids) {
    const page = await texte(`https://play.google.com/store/search?q=${encodeURIComponent(recherche)}&c=apps&hl=fr&gl=FR`);
    ids = memoire.recherches[recherche] = [...new Set([...page.matchAll(/details\?id=([a-zA-Z0-9._]+)/g)].map((m) => m[1]))].slice(0, 4);
    retenir();
    await attendre(400);
  }
  ids = ids.slice(0, max);
  for (const id of ids) {
    const f = await lireFiche(id);
    if (f.image && accepter(f)) return f;
  }
  return null;
}

/// Télécharge l'icône d'une fiche, une seule fois : le cache garde tout.
async function icone(f) {
  const brut = path.join(cache, `${f.id}.png`);
  if (!fs.existsSync(brut)) {
    const r = await fetch(`${f.image}=s256`, { headers: entetes, signal: AbortSignal.timeout(30000) });
    fs.writeFileSync(brut, Buffer.from(await r.arrayBuffer()));
  }
  return brut;
}

/// Sur un fond uni, le logo doit tenir dans notre arrondi sans y être
/// perdu : trop petit (un logo au milieu d'un grand blanc), il est agrandi ;
/// collé aux bords, il reçoit de l'air. Les icônes pleines, aux couleurs de
/// la banque jusqu'aux bords, ne bougent pas.
async function recentrer(png, profondeur = 0) {
  const { data, info } = await sharp(png).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: w, height: h } = info;
  const px = (x, y) => data.slice((y * w + x) * 3, (y * w + x) * 3 + 3);
  const ecart = (a, b) => Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) + Math.abs(a[2] - b[2]);
  const fond = px(1, 1);
  const coins = [px(w - 2, 1), px(1, h - 2), px(w - 2, h - 2)];
  if (coins.some((c) => ecart(c, fond) > 24)) return sharp(png);
  let [x0, y0, x1, y1] = [w, h, -1, -1];
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (ecart(px(x, y), fond) > 60) [x0, y0, x1, y1] = [Math.min(x0, x), Math.min(y0, y), Math.max(x1, x), Math.max(y1, y)];
    }
  }
  if (x1 < 0) return sharp(png);
  // Le contenu est lui-même une forme pleine (une icône dans l'icône) :
  // elle prend toute la place.
  let pleins = 0;
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) if (ecart(px(x, y), fond) > 60) pleins++;
  const carre = (x1 - x0 + 1) / (y1 - y0 + 1);
  if (profondeur === 0 && pleins / ((x1 - x0 + 1) * (y1 - y0 + 1)) > 0.85 && carre > 0.9 && carre < 1.1) {
    const forme = await sharp(png).extract({ left: x0, top: y0, width: x1 - x0 + 1, height: y1 - y0 + 1 }).resize(w, h, { fit: 'fill' }).png().toBuffer();
    // Puis son propre contenu, à son tour, dans cette forme.
    return recentrer(forme, 1);
  }
  const cote = Math.max(x1 - x0 + 1, y1 - y0 + 1);
  const marge = Math.min(x0, y0, w - 1 - x1, h - 1 - y1) / w;
  const part = cote / w;
  // Entre les deux, l'icône est déjà bien posée.
  if (part >= 0.5 && marge >= 0.08) return sharp(png);
  const cible = Math.round(w * 0.72);
  const logo = await sharp(png)
    .extract({ left: x0, top: y0, width: x1 - x0 + 1, height: y1 - y0 + 1 })
    .resize(cible, cible, { fit: 'inside' })
    .toBuffer({ resolveWithObject: true });
  // L'assemblage est figé ici : sharp redimensionne avant de composer.
  const pose = await sharp({ create: { width: w, height: h, channels: 3, background: { r: fond[0], g: fond[1], b: fond[2] } } })
    .composite([{ input: logo.data, left: Math.round((w - logo.info.width) / 2), top: Math.round((h - logo.info.height) / 2) }])
    .png()
    .toBuffer();
  return sharp(pose);
}

/// Remet une icône d'aplomb et rend son nom de fichier, tiré de son
/// contenu : deux banques à la même application partagent la même icône.
async function preparer(brut) {
  const source = sharp(brut).ensureAlpha();
  const { data, info } = await source.clone().raw().toBuffer({ resolveWithObject: true });
  const alpha = (x, y) => data[(y * info.width + x) * 4 + 3];
  const w = info.width;
  const h = info.height;
  let img = source.clone().flatten({ background: '#ffffff' });
  if ([alpha(0, 0), alpha(w - 1, 0), alpha(0, h - 1), alpha(w - 1, h - 1)].some((a) => a < 200)) {
    // Des coins transparents : soit une icône déjà arrondie, parfois dans
    // une marge, soit un logo seul posé sur rien. La zone visible le dit :
    // pleine, c'est une forme ; clairsemée, c'est un logo. Seuls les pixels
    // opaques comptent : une ombre portée ne fait pas partie de la forme.
    let [x0, y0, x1, y1] = [w, h, -1, -1];
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        if (alpha(x, y) > 240) [x0, y0, x1, y1] = [Math.min(x0, x), Math.min(y0, y), Math.max(x1, x), Math.max(y1, y)];
      }
    }
    let pleins = 0;
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) if (alpha(x, y) > 240) pleins++;
    const surface = (x1 - x0 + 1) * (y1 - y0 + 1);
    const carre = (x1 - x0 + 1) / (y1 - y0 + 1);
    // Un logo rectangulaire plein (CIC) n'est pas une forme d'icône : il
    // faut qu'elle soit à peu près carrée.
    if (x1 >= 0 && pleins / surface > 0.75 && carre > 0.9 && carre < 1.1) {
      // Une forme : on la recadre, et ses coins prennent la couleur de son
      // bord pour que notre arrondi ne laisse rien voir dessous.
      const cote = Math.max(x1 - x0, y1 - y0) + 1;
      // La couleur du bord, lue juste à l'intérieur au milieu de chaque
      // côté : la plus fréquente, pour ne pas tomber sur le logo.
      const [mx, my] = [Math.floor((x0 + x1) / 2), Math.floor((y0 + y1) / 2)];
      const lus = [[x0 + 3, my], [x1 - 3, my], [mx, y0 + 3], [mx, y1 - 3]].map(([x, y]) => {
        const i = (y * w + x) * 4;
        return `${data[i]},${data[i + 1]},${data[i + 2]}`;
      });
      const [r, g, b] = lus.sort((a, z) => lus.filter((v) => v === z).length - lus.filter((v) => v === a).length)[0].split(',').map(Number);
      const fond = { r, g, b };
      img = sharp(await source.clone().extract({ left: x0, top: y0, width: x1 - x0 + 1, height: y1 - y0 + 1 }).png().toBuffer())
        .resize(cote, cote, { fit: 'contain', background: { ...fond, alpha: 0 } })
        .flatten({ background: fond });
    }
    // Sinon, un logo seul : sur fond blanc, sans recadrer, comme le
    // lanceur d'Android.
  }
  img = await recentrer(await img.png().toBuffer());
  const sortie = await img.resize(144, 144, { fit: 'cover' }).webp({ quality: 90 }).toBuffer();
  const nom = `${crypto.createHash('sha1').update(sortie).digest('hex').slice(0, 12)}.webp`;
  fs.writeFileSync(path.join(dossier, nom), sortie);
  return nom;
}

/// Les mots qui distinguent une banque, dans l'ordre de son nom.
const distinctifs = (nom) =>
  simple(nom)
    .replace(/[^a-z0-9 ]/g, ' ')
    .split(/\s+/)
    .filter((m) => m.length >= 3 && !generiques.has(m));

fs.mkdirSync(cache, { recursive: true });
fs.rmSync(dossier, { recursive: true, force: true });
fs.mkdirSync(dossier, { recursive: true });

// 1. Les grandes banques.
const motifs = [];
for (const [, recherche, titre, motif, impose] of grandes) {
  try {
    const f = impose
      ? await lireFiche(impose)
      : await chercher(recherche, (f) => new RegExp(titre).test(simple(f.nom)));
    if (!f) {
      console.log(`--   ${recherche}`);
      continue;
    }
    motifs.push([motif, await preparer(await icone(f))]);
    console.log(`ok   ${recherche.padEnd(34)} ${f.nom}`);
  } catch (e) {
    console.log(`--   ${recherche} : ${e.message}`);
  }
}

// 2. Toutes les autres banques d'Enable Banking, une par une.
const liste = JSON.parse(await texte('https://enablebanking.com/api/aspsps')).aspsps;
const noms = [...new Set(liste.filter((a) => (a.psu_types ?? ['personal']).includes('personal')).map((a) => a.name))].sort();
const couvert = (n) => motifs.some(([m]) => new RegExp(m).test(simple(n)));
const restants = noms.filter((n) => !couvert(n));
console.log(`\n${noms.length} banques, ${noms.length - restants.length} couvertes par les grandes, ${restants.length} à chercher`);

// Deux noms peuvent se confondre une fois simplifiés (Easybank, easybank) :
// un seul suffit.
const exacts = new Map();
let fait = 0;
for (const nom of restants) {
  fait++;
  const mots = distinctifs(nom).slice(0, 2);
  if (mots.length === 0 || exclues.has(nom)) continue;
  try {
    // Une minute au plus par banque : une réponse qui ne vient jamais ne
    // doit pas bloquer les mille suivantes.
    const f = await Promise.race([
      chercher(nom, (f) => f.finance && mots.every((m) => simple(f.nom).includes(m)), 3),
      attendre(60000).then(() => Promise.reject(new Error('trop long'))),
    ]);
    if (f) {
      exacts.set(simple(nom), await preparer(await icone(f)));
      console.log(`ok   ${String(fait).padStart(4)} ${nom.padEnd(44)} ${f.nom}`);
    }
  } catch (e) {
    console.log(`!!   ${nom} : ${e.message}`);
  }
}

const echapper = (s) => s.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
const dart = `// Généré par tool/logos_banques.mjs : ne pas modifier à la main.

/// L'icône d'une grande banque, celle de son application mobile, reconnue
/// à son nom chez Enable Banking. Les motifs se lisent dans l'ordre : le
/// plus précis d'abord.
const logosBanques = <(String, String)>[
${motifs.map(([m, f]) => `  (r'${m}', 'assets/banques/${f}'),`).join('\n')}
];

/// Les autres banques qui ont une application, par leur nom exact, sans
/// accents ni majuscules.
const logosExacts = <String, String>{
${[...exacts].map(([n, f]) => `  '${echapper(n)}': 'assets/banques/${f}',`).join('\n')}
};
`;
fs.writeFileSync(path.join(racine, 'lib/banque/logos_banques.dart'), dart);
const fichiers = fs.readdirSync(dossier);
const poids = fichiers.reduce((s, f) => s + fs.statSync(path.join(dossier, f)).size, 0);
console.log(`\n${motifs.length} grandes, ${exacts.size} autres, ${fichiers.length} fichiers, ${(poids / 1024).toFixed(0)} Ko`);

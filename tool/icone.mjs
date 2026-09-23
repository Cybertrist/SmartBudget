// Génère l'icône Android depuis assets/logo.png, par un canvas de Chrome.
//
// L'icône adaptative d'Android est faite de deux calques que le lanceur
// découpe à sa forme : cercle, carré arrondi, forme de Samsung. Un contour
// dessiné dans le logo ne suit jamais cette découpe, il ressort en carré
// tronqué ou décalé. On fait l'inverse : le calque du fond est vert néon,
// celui du dessus est une plaque sombre à la forme des icônes de Samsung,
// à peine plus petite. Le mince liseré vert qui reste visible, c'est le
// bord même de l'icône : il épouse la découpe.
//
// - mipmap-*/ic_launcher.png : le logo entier, pour les anciens Android ;
// - mipmap-*/ic_launcher_foreground.png : la plaque et les barres ;
// - values/couleurs.xml : le vert du liseré, fond de l'icône adaptative ;
// - drawable-nodpi/logo_demarrage.png : l'icône de l'écran de démarrage.
//
//   node tool/icone.mjs
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const racine = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1')), '..');
const chrome = process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const logo = fs.readFileSync(path.join(racine, 'assets/logo.png')).toString('base64');
const res = path.join(racine, 'android/app/src/main/res');

// Ce que le lanceur de Samsung laisse voir des 108 dp du calque : un peu
// moins que les 72 dp de la norme.
const VISIBLE = 64 / 108;
// L'épaisseur du liseré, en part du côté visible.
const LISERE = 0.028;
// La hauteur des barres, en part du côté visible.
const BARRES = 0.5;

const tailles = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
const cibles = [];
for (const [d, t] of Object.entries(tailles)) {
  cibles.push({ fichier: `mipmap-${d}/ic_launcher.png`, taille: t, sorte: 'entier' });
  cibles.push({ fichier: `mipmap-${d}/ic_launcher_foreground.png`, taille: Math.round(t * 108 / 48), sorte: 'plaque' });
}
cibles.push({ fichier: 'drawable-nodpi/logo_demarrage.png', taille: 288, sorte: 'barres' });

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'icone-'));
const page = path.join(temp, 'page.html');
fs.writeFileSync(page, `<!doctype html><body><script>
const img = new Image();
img.onload = () => {
  const s = document.createElement('canvas'); s.width = img.width; s.height = img.height;
  const g0 = s.getContext('2d'); g0.drawImage(img, 0, 0);
  const d = g0.getImageData(0, 0, img.width, img.height).data;
  const px = (x, y) => { const i = (y * img.width + x) * 4; return [d[i], d[i + 1], d[i + 2]]; };
  // La couleur de la plaque, à l'intérieur du cadre.
  const fond = px(Math.round(img.width * 0.5), Math.round(img.height * 0.2));
  // La boîte des barres : les pixels verts et clairs, à l'écart du cadre.
  let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1;
  const marge = Math.round(img.width * 0.15);
  for (let y = marge; y < img.height - marge; y++) for (let x = marge; x < img.width - marge; x++) {
    const [r, g] = px(x, y);
    if (g > 120 && g > r + 20) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
  }
  const hex = (c) => '#' + c.map((v) => v.toString(16).padStart(2, '0')).join('');
  const sortie = { fond: hex(fond) };

  // Les barres seules, centrées sur leur propre boîte, de hauteur h.
  function barres(g, cx, cy, h) {
    const e = h / (y1 - y0);
    const p = 0.05 * img.width;
    g.drawImage(img, x0 - p, y0 - p, x1 - x0 + 2 * p, y1 - y0 + 2 * p,
      cx - (x1 - x0) * e / 2 - p * e, cy - h / 2 - p * e, (x1 - x0 + 2 * p) * e, h + 2 * p * e);
  }
  // La forme des icônes de Samsung : une superellipse.
  function forme(g, cx, cy, cote) {
    const r = cote / 2, n = 4.2;
    g.beginPath();
    for (let i = 0; i <= 360; i++) {
      const a = i / 360 * 2 * Math.PI, c = Math.cos(a), s = Math.sin(a);
      const x = cx + r * Math.sign(c) * Math.pow(Math.abs(c), 2 / n);
      const y = cy + r * Math.sign(s) * Math.pow(Math.abs(s), 2 / n);
      i ? g.lineTo(x, y) : g.moveTo(x, y);
    }
    g.closePath();
  }

  for (const c of ${JSON.stringify(cibles)}) {
    const k = document.createElement('canvas'); k.width = k.height = c.taille;
    const g = k.getContext('2d'); g.imageSmoothingQuality = 'high';
    const m = c.taille / 2;
    if (c.sorte === 'entier') {
      g.drawImage(img, 0, 0, c.taille, c.taille);
    } else if (c.sorte === 'plaque') {
      const v = c.taille * ${VISIBLE};
      const cote = v * (1 - 2 * ${LISERE});
      // La plaque sombre, et au bord un léger halo vert vers l'intérieur,
      // comme le néon du logo.
      g.save();
      forme(g, m, m, cote);
      g.fillStyle = sortie.fond; g.fill();
      g.clip();
      g.shadowColor = 'rgba(80,244,141,0.5)'; g.shadowBlur = v * 0.05;
      g.lineWidth = v * 0.02; g.strokeStyle = 'rgba(80,244,141,0.3)';
      forme(g, m, m, cote + v * 0.02); g.stroke();
      g.restore();
      barres(g, m, m, v * ${BARRES});
    } else {
      g.fillStyle = sortie.fond; g.fillRect(0, 0, c.taille, c.taille);
      barres(g, m, m, c.taille * 0.36);
    }
    sortie[c.fichier] = k.toDataURL('image/png');
  }
  document.body.textContent = JSON.stringify(sortie);
};
img.src = 'data:image/png;base64,${logo}';
</script></body>`);
const dom = execFileSync(chrome, ['--headless=new', '--disable-gpu', '--virtual-time-budget=15000', '--dump-dom', 'file:///' + page.replace(/\\/g, '/')], { maxBuffer: 256 * 1024 * 1024 }).toString();
const json = JSON.parse(dom.slice(dom.indexOf('{'), dom.lastIndexOf('}') + 1).replace(/&amp;/g, '&'));
for (const c of cibles) {
  const f = path.join(res, c.fichier);
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.writeFileSync(f, Buffer.from(json[c.fichier].split(',')[1], 'base64'));
}
fs.writeFileSync(path.join(res, 'values/couleurs.xml'), `<?xml version="1.0" encoding="utf-8"?>
<!-- Généré par tool/icone.mjs. -->
<resources>
    <!-- Le fond de l'icône adaptative : le vert du liseré. -->
    <color name="fond_icone">#3FD97F</color>
    <!-- La plaque du logo, pour l'écran de démarrage. -->
    <color name="plaque">${json.fond}</color>
    <color name="fond">#121212</color>
</resources>
`);
fs.writeFileSync(path.join(res, 'mipmap-anydpi-v26/ic_launcher.xml'), `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/fond_icone" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
`);
fs.rmSync(temp, { recursive: true, force: true });
console.log('plaque', json.fond, '·', cibles.length, 'images');

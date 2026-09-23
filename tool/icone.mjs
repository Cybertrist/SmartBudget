// Génère l'icône Android depuis assets/logo.png, par un canvas de Chrome.
//
// - mipmap-*/ic_launcher.png : le logo entier, pour les anciens Android ;
// - mipmap-*/ic_launcher_foreground.png : le logo entier dans la zone sûre
//   de l'icône adaptative, cadre néon compris, sur la couleur exacte du
//   fond du logo : Android découpe le cercle ou le carré arrondi
//   lui-même, sans double contour ;
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

const tailles = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'icone-'));

// Toutes les images en un seul passage : chaque cible est un canvas, son
// PNG revient par le DOM.
const cibles = [];
for (const [d, t] of Object.entries(tailles)) {
  cibles.push({ fichier: `mipmap-${d}/ic_launcher.png`, taille: t, zoom: 1 });
  // 108 dp de côté, dont 72 visibles : le logo agrandi remplit la zone sûre.
  cibles.push({ fichier: `mipmap-${d}/ic_launcher_foreground.png`, taille: Math.round(t * 108 / 48), zoom: 0.64, fond: true, plein: true, contour: true });
}
// Android 12 ne montre du démarrage qu'un disque des deux tiers de l'icône :
// le logo y est posé en grand, le cadre néon tombe hors du disque et seules
// les barres restent. L'animation de Flutter redessine le cadre ensuite.
cibles.push({ fichier: 'drawable-nodpi/logo_demarrage.png', taille: 288, zoom: 0.95, fond: true, plein: true });

const page = path.join(temp, 'page.html');
fs.writeFileSync(page, `<!doctype html><body><script>
const img = new Image();
img.onload = () => {
  // La couleur du fond du logo, prise à l'intérieur du cadre néon.
  const s = document.createElement('canvas'); s.width = img.width; s.height = img.height;
  const g0 = s.getContext('2d'); g0.drawImage(img, 0, 0);
  const px = g0.getImageData(Math.round(img.width * 0.5), Math.round(img.height * 0.2), 1, 1).data;
  const fond = '#' + [px[0], px[1], px[2]].map((v) => v.toString(16).padStart(2, '0')).join('');
  const sortie = { fond };
  for (const c of ${JSON.stringify(cibles)}) {
    const k = document.createElement('canvas'); k.width = k.height = c.taille;
    const g = k.getContext('2d'); g.imageSmoothingQuality = 'high';
    if (c.fond) { g.fillStyle = fond; g.fillRect(0, 0, c.taille, c.taille); }
    const cote = c.taille * c.zoom * (c.fond && !c.plein ? 72 / 108 : 1);
    const x = (c.taille - cote) / 2;
    if (c.plein) {
      // Le logo sans son propre cadre : chaque lanceur découpe l'icône à
      // sa forme, et un cadre dessiné dans le fichier ressortirait en petit
      // carré tronqué. On garde l'intérieur du logo, à la même échelle.
      const m = cote * 0.1;
      g.save(); g.beginPath(); g.roundRect(x + m, x + m, cote - 2 * m, cote - 2 * m, cote * 0.12); g.clip();
      g.drawImage(img, x, x, cote, cote);
      g.restore();
    } else {
      g.drawImage(img, x, x, cote, cote);
    }
    if (c.contour) {
      // Le contour néon, redessiné à la forme des icônes Android : un carré
      // arrondi posé juste à l'intérieur de la zone visible (72 dp sur 108),
      // qui épouse le bord de l'icône sur le lanceur de Samsung.
      const v = c.taille * 72 / 108;
      const cx = (c.taille - v) / 2 + v * 0.09;
      const w = v * 0.82;
      g.save();
      g.shadowColor = 'rgba(80,244,141,0.55)'; g.shadowBlur = c.taille * 0.022;
      g.strokeStyle = 'rgba(80,244,141,0.9)'; g.lineWidth = c.taille * 0.0075;
      g.beginPath(); g.roundRect(cx, cx, w, w, w * 0.3); g.stroke();
      g.restore();
    }
    sortie[c.fichier] = k.toDataURL('image/png');
  }
  document.body.textContent = JSON.stringify(sortie);
};
img.src = 'data:image/png;base64,${logo}';
</script></body>`);
const dom = execFileSync(chrome, ['--headless=new', '--disable-gpu', '--virtual-time-budget=8000', '--dump-dom', 'file:///' + page.replace(/\\/g, '/')], { maxBuffer: 256 * 1024 * 1024 }).toString();
const json = JSON.parse(dom.slice(dom.indexOf('{'), dom.lastIndexOf('}') + 1).replace(/&amp;/g, '&'));
for (const c of cibles) {
  const f = path.join(res, c.fichier);
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.writeFileSync(f, Buffer.from(json[c.fichier].split(',')[1], 'base64'));
}
fs.mkdirSync(path.join(res, 'values'), { recursive: true });
fs.writeFileSync(path.join(res, 'values/couleurs.xml'), `<?xml version="1.0" encoding="utf-8"?>
<!-- Généré par tool/icone.mjs : la couleur de la plaque du logo. -->
<resources>
    <color name="fond_icone">${json.fond}</color>
    <color name="fond">#121212</color>
</resources>
`);
fs.mkdirSync(path.join(res, 'mipmap-anydpi-v26'), { recursive: true });
fs.writeFileSync(path.join(res, 'mipmap-anydpi-v26/ic_launcher.xml'), `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/fond_icone" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
`);
fs.rmSync(temp, { recursive: true, force: true });
console.log('fond de la plaque', json.fond, '·', cibles.length, 'images');

// Génère lib/config/icones_symbols.dart depuis tool/icones.json.
//
// Chaque icône est une constante Symbols.xxx_rounded : la version de
// publication ne garde de la police Material Symbols que les glyphes
// réellement cités, quelques dizaines de kilo-octets au lieu de quinze
// mégaoctets. Les noms absents de la police sont écartés, et signalés.
//
//   node tool/icones.mjs
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const racine = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1')), '..');
const cache = path.join(os.homedir(), 'AppData/Local/Pub/Cache/hosted/pub.dev');
const paquet = fs.readdirSync(cache).filter((d) => d.startsWith('material_symbols_icons-')).sort().pop();
const symbols = fs.readFileSync(path.join(cache, paquet, 'lib/symbols.dart'), 'utf8');
const existe = (n) => symbols.includes(`static const IconData ${n}_rounded =`);

const groupes = JSON.parse(fs.readFileSync(path.join(racine, 'tool/icones.json'), 'utf8'));
// Les icônes des catégories de départ doivent exister aussi.
const depart = [...fs.readFileSync(path.join(racine, 'lib/donnees/icones.dart'), 'utf8').matchAll(/: '([a-z0-9_]+)',/g)].map((m) => m[1]);
const extra = ['arrow_back', 'chevron_left', 'chevron_right', 'search', 'lock', 'fingerprint', 'add', 'check', 'close', 'more_horiz', 'edit', 'visibility_off', 'autorenew', 'call_made', 'call_received', 'warning', 'sync', 'north', 'south', 'home', 'pie_chart', 'savings', 'settings', 'calendar_month', 'category', 'help', 'link', 'schedule', 'check_circle', 'expand_more', 'tune', 'delete', 'download', 'upload', 'key', 'shield', 'bolt', 'sticky_note_2', 'receipt_long', 'trending_down', 'trending_up', 'filter_list', 'label', 'swap_horiz', 'sync_alt', 'timer', 'target', 'auto_awesome', 'thumb_up', 'favorite', 'credit_card', 'radio_button_unchecked', 'task_alt', 'fact_check'];

const retenus = new Set();
const manquants = [];
const sortieGroupes = groupes.map(([nom, liste]) => {
  const ok = [...new Set(liste.split(' '))].filter((n) => (existe(n) ? true : (manquants.push(n), false)));
  ok.forEach((n) => retenus.add(n));
  return [nom, ok];
});
for (const n of [...depart, ...extra]) (existe(n) ? retenus.add(n) : manquants.push(n));

const lignes = [...retenus].sort().map((n) => `  '${n}': Symbols.${n}_rounded,`);
const dart = `// Généré par tool/icones.mjs : ne pas modifier à la main.
// ignore_for_file: constant_identifier_names
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Toutes les icônes que l'application peut afficher, par nom.
const iconesSymbols = <String, IconData>{
${lignes.join('\n')}
};

/// Les icônes proposées au choix, rangées par thème.
const groupesIcones = <(String, List<String>)>[
${sortieGroupes.map(([n, l]) => `  ('${n.replace(/'/g, "\\'")}', [${l.map((x) => `'${x}'`).join(', ')}]),`).join('\n')}
];
`;
fs.writeFileSync(path.join(racine, 'lib/config/icones_symbols.dart'), dart);
console.log(`${retenus.size} icônes, ${sortieGroupes.reduce((s, g) => s + g[1].length, 0)} au choix`);
if (manquants.length) console.log('absentes de la police :', [...new Set(manquants)].join(' '));

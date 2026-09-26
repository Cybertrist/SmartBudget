#!/bin/bash
# Toutes les figures fixes du README : la bannière, les bandeaux de
# section, les fonctionnalités, la palette et le bouton de
# téléchargement. Les tests, la pile, les couches, le modèle de données
# et la confidentialité sont devenus des schémas animés, dans
# docs/tools/schemas/. C'est le seul fichier à ouvrir pour changer un
# texte des figures fixes.
#
#   bash docs/tools/figures.sh
source "$(dirname "${BASH_SOURCE[0]}")/rendu.sh"
mkdir -p "$DOCS/sections" "$DOCS/schemas"
LOGO="file:///$DOCS/logo.png"
ICONES='<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,500,1,0" rel="stylesheet">'

# ------------------------------------------------------------- bannière
{ entete 1280; echo "$ICONES"; cat <<HTML
<style>
.w{width:1280px;height:340px;position:relative;overflow:hidden;
   background:radial-gradient(55% 140% at 10% 0%,#1ED76026 0%,transparent 60%),linear-gradient(135deg,#0D1117 0%,#0D1117 55%,#04060A 100%)}
.grille{position:absolute;inset:0;opacity:.35;
  background-image:linear-gradient(#1ED76012 1px,transparent 1px),linear-gradient(90deg,#1ED76012 1px,transparent 1px);
  background-size:46px 46px;-webkit-mask-image:radial-gradient(70% 100% at 8% 50%,#000 0%,transparent 72%)}
.cat{position:absolute;top:26px;right:30px;display:flex;gap:8px}
.cat b{font-family:'JetBrains Mono',monospace;font-weight:500;font-size:12px;letter-spacing:2.2px;
  color:#1ED760E0;border:1px solid #1ED76046;background:#1ED76012;border-radius:5px;padding:7px 13px}
.in{position:absolute;inset:0;display:flex;align-items:center;gap:48px;padding:0 66px}
.logo{width:150px;height:150px;flex-shrink:0;filter:drop-shadow(0 0 26px #50F48D55) drop-shadow(0 14px 30px #000A)}
h1{font-family:Syne,sans-serif;font-weight:800;font-size:58px;line-height:1;letter-spacing:-1.5px}
h1 em{font-style:normal;color:var(--neon)}
p{font-family:'Space Grotesk',sans-serif;font-size:19px;line-height:1.5;color:#94A3B0;max-width:800px;margin-top:14px}
.sl{font-size:23px;line-height:1.55;margin-top:18px}.sl b{font-weight:500;color:#E6EDF3}.sl em{font-style:normal;color:var(--neon)}
.pl{display:flex;gap:8px;margin-top:18px}
.pl span{font-family:'Space Grotesk',sans-serif;font-size:12.5px;font-weight:500;letter-spacing:.6px;
  color:#1ED760D0;border:1px solid #1ED7603A;background:#1ED7600E;border-radius:6px;padding:6px 11px}
.ln{position:absolute;left:0;right:0;bottom:0;height:3px;background:linear-gradient(90deg,#1ED760 0%,#50F48D 40%,transparent 90%)}
</style></head><body>
<div class="w"><div class="grille"></div>
<div class="cat"><b>ANDROID</b><b>FINANCES</b><b>OPEN SOURCE</b></div>
<div class="in"><img class="logo" src="$LOGO">
<div><h1>Smart <em>Budget</em></h1>
<p class="sl"><b>Votre argent. Vos projets. Votre avenir.</b><br>Gardez le <em>contrôle</em>, profitez de l’<em>essentiel</em>.</p>
<div class="pl"><span>Flutter</span><span>Enable Banking</span><span>SQLCipher</span><span>AES-GCM</span><span>Fold</span></div></div></div>
<div class="ln"></div></div>
HTML
pied; } > "$D/html/banniere.html"
rendre banniere.html "$DOCS/banniere.png"

# -------------------------------------------------------------- bandeaux
bandeau () {
{ entete 1280; cat <<HTML
<style>
.w{height:118px;display:flex;flex-direction:column;justify-content:center;gap:18px;padding:0 60px}
.l{display:flex;align-items:center;gap:20px;height:40px}
.ix{width:52px;height:40px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-family:'JetBrains Mono',monospace;
  font-size:15px;color:#1ED760;border:1.5px solid #1ED7604D;background:#1ED7601C;border-radius:6px}
h2{font-family:Syne,sans-serif;font-weight:800;font-size:29px;letter-spacing:5px;text-transform:uppercase;white-space:nowrap}
.r{height:2px;display:flex}.r .a{width:52px;background:#1ED760}.r .b{flex:1;background:linear-gradient(90deg,#3A4450,#222A34 42%,transparent)}
</style></head><body>
<div class="w"><div class="l"><div class="ix">$1</div><h2>$2</h2></div><div class="r"><i class="a"></i><i class="b"></i></div></div>
<script>
// Un titre trop long se resserre jusqu'à tenir dans la marge de droite.
document.fonts.ready.then(()=>{const h=document.querySelector('h2');let s=29;
  while(h.getBoundingClientRect().right>1220&&s>16){s--;h.style.fontSize=s+'px';h.style.letterSpacing=(s/29*5).toFixed(2)+'px';}});
</script>
HTML
pied; } > "$D/html/s$1.html"
rendre "s$1.html" "$DOCS/sections/s$1.png"
}
n=1
for titre in "Fonctionnalités" "Les écrans" "Installer" "Relier la banque" "Au quotidien" "Comment une opération est lue" \
             "Virements, remboursements, épargne" "L'alerte de compte en négatif" "L'écran déplié" \
             "Chiffrement et sauvegarde" "Modèle de confidentialité" "Architecture" "Les tests" "Licence et auteur"; do
  bandeau "$(printf '%02d' $n)" "$titre"; n=$((n+1))
done
bandeau "00" "Sommaire"

# --------------------------------------------------------------- sommaire
# Une tuile par section : son icône, son numéro, son titre. Une image
# chacune, pour que chaque tuile du README mène à sa section.
tuile () {
{ entete 250; echo "$ICONES"; cat <<HTML
<style>
.c{height:64px;display:flex;align-items:center;gap:13px;padding:0 14px;background:var(--carte);border:1px solid var(--bord);border-radius:14px}
.ic{font-family:'Material Symbols Rounded';font-size:22px;width:38px;height:38px;flex-shrink:0;border-radius:11px;
  display:flex;align-items:center;justify-content:center;color:#1ED760;background:#1ED76014;border:1px solid #1ED76038;box-shadow:0 0 16px #1ED76026}
.n{font-family:'JetBrains Mono',monospace;font-size:11px;color:#1ED760B0;letter-spacing:1px}
h3{font-family:'Space Grotesk',sans-serif;font-size:14.5px;font-weight:600;line-height:1.2;margin-top:2px}
</style></head><body>
<div class="c"><span class="ic">$2</span><div><div class="n">$1</div><h3>$3</h3></div></div>
HTML
pied; } > "$D/html/sommaire-$1.html"
rendre "sommaire-$1.html" "$DOCS/sommaire/$1.png" 250
}
mkdir -p "$DOCS/sommaire"
tuile 01 auto_awesome 'Fonctionnalités'
tuile 02 smartphone 'Les écrans'
tuile 03 download 'Installer'
tuile 04 account_balance 'Relier la banque'
tuile 05 today 'Au quotidien'
tuile 06 receipt_long 'Lecture d’une opération'
tuile 07 sync_alt 'Virements et épargne'
tuile 08 notifications_active 'L’alerte'
tuile 09 devices_fold 'L’écran déplié'
tuile 10 lock 'Chiffrement'
tuile 11 shield 'Confidentialité'
tuile 12 account_tree 'Architecture'
tuile 13 task_alt 'Les tests'
tuile 14 gavel 'Licence'

# ------------------------------------------------------------- les grilles
# grille <nom> <colonnes> "icone|titre|texte" ...
grille () {
local nom="$1" cols="$2"; shift 2
local cartes=""
for e in "$@"; do
  IFS='|' read -r ic ti tx <<< "$e"
  cartes+="<div class=\"c\"><span class=\"ic\">$ic</span><div><h3>$ti</h3><p>$tx</p></div></div>"
done
{ entete 1280; echo "$ICONES"; cat <<HTML
<style>
.w{padding:22px 56px;display:grid;grid-template-columns:repeat($cols,1fr);gap:14px}
.c{background:var(--carte);border:1px solid var(--bord);border-radius:14px;padding:18px;display:flex;gap:15px;align-items:flex-start}
.ic{font-family:'Material Symbols Rounded';font-size:24px;width:46px;height:46px;flex-shrink:0;border-radius:13px;
  display:flex;align-items:center;justify-content:center;color:#1ED760;background:#1ED76014;border:1px solid #1ED76038;
  box-shadow:0 0 18px #1ED76022}
h3{font-family:'Space Grotesk',sans-serif;font-size:16px;font-weight:700;margin:2px 0 5px}
p{font-family:'Space Grotesk',sans-serif;font-size:13.5px;line-height:1.5;color:var(--texte)}
code{font-family:'JetBrains Mono',monospace;font-size:12.5px;color:#C3CCD7}
</style></head><body><div class="w">$cartes</div>
HTML
pied; } > "$D/html/$nom.html"
rendre "$nom.html" "$DOCS/schemas/$nom.png"
}

grille fonctionnalites 3 \
  "account_balance|Le compte, tout seul|Ton compte courant, lu par la DSP2 via Enable Banking : douze mois d'historique, une synchronisation à chaque ouverture, et une alerte s'il passe en négatif." \
  "category|Classé sans rien faire|23 catégories, 180 sous-catégories, 250 marchands reconnus. Une correction est apprise et suivie par les prochaines opérations." \
  "pie_chart|L'anneau des dépenses|Le mois, trois mois ou un an : où part l'argent, catégorie par catégorie, jusqu'à l'opération." \
  "sync_alt|Les virements internes à part|Vers le livret, depuis le livret : ni dépense ni revenu, hachurés, hors budget. Mis de côté et pioché, suivis." \
  "link|Les remboursements liés|Un chèque de 500 € réparti sur deux dépenses : elles ne comptent plus que pour leur reste à charge." \
  "autorenew|Les récurrences|Loyer, forfait, abonnements : repérés seuls, réglables à la main, en retard, à venir ou payés." \
  "fact_check|À vérifier, et pointer|Ce que rien ne reconnaît attend sa catégorie. Une coche verte dit qu'une opération a été vérifiée." \
  "payments|Espèces et portefeuille|Une dépense en espèces se saisit ; elle se retranche des retraits, et le portefeuille suit ce qui reste." \
  "savings|Livrets et épargne|Saisis une fois avec leur solde, puis tenus à jour par les virements repérés sur le compte courant." \
  "search|La recherche|Toutes les opérations, depuis la première : un nom, une note, un montant." \
  "lock|Chiffré sur le téléphone|SQLCipher, clé dans le Keystore, déverrouillée par l'empreinte. Captures et aperçu du multitâche bloqués." \
  "backup|La sauvegarde chiffrée|Un fichier AES-GCM, clé tirée d'une phrase par PBKDF2, qui se relit sur un autre téléphone."

# ---------------------------------------------------------------- palette
pastille () { printf '<div class="p"><i style="background:%s"></i><b>%s</b><span>%s</span></div>' "$1" "$2" "$1"; }
{ entete 1280; cat <<HTML
<style>
.w{padding:22px 56px;display:grid;grid-template-columns:repeat(8,1fr);gap:12px}
.p{background:var(--carte);border:1px solid var(--bord);border-radius:12px;padding:12px;display:flex;flex-direction:column;gap:8px}
.p i{height:54px;border-radius:9px;border:1px solid #FFFFFF14}
.p b{font-family:'Space Grotesk',sans-serif;font-size:13px}
.p span{font-family:'JetBrains Mono',monospace;font-size:11.5px;color:var(--texte)}
</style></head><body><div class="w">
$(pastille '#1ED760' 'Vert') $(pastille '#50F48D' 'Néon du logo') $(pastille '#121212' 'Fond') $(pastille '#181818' 'Cartes')
$(pastille '#3CE0FF' 'Épargne') $(pastille '#8FA3B8' 'Interne') $(pastille '#FFC857' 'Attention') $(pastille '#FF6B7A' 'Alerte')
</div>
HTML
pied; } > "$D/html/palette.html"
rendre palette.html "$DOCS/schemas/palette.png"

# ----------------------------------------------------- boutons télécharger
# Deux applications, deux boutons : la complète (SmartBudget.apk), reliée à
# la banque, et la démo (SmartBudget-demo.apk), remplie d'un jeu d'essai.
# Comme BodyCount : le logo à gauche, le nom, la version, et un carré de
# téléchargement. Seuls les coins arrondis sont transparents : GitHub rend
# les README sur blanc comme sur noir.
VERSION="$(grep '^version:' "$D/../../pubspec.yaml" | sed 's/version: *//; s/+.*//')"

# bouton <fichier.png> <apk> <titre> <sous-titre> <bord> <fond> <carré> <trait>
bouton () {
local apk="$D/../../build/sortie/$2"
local taille="$([ -f "$apk" ] && awk "BEGIN{printf \" · %.0f Mo\", $(stat -c%s "$apk" 2>/dev/null || echo 0)/1048576}")"
[ "$LANGUE" = en ] && taille="${taille/Mo/MB}"
{ entete 720; cat <<HTML
<style>
html,body{width:720px;height:132px;overflow:hidden;background:transparent}
.w{width:720px;height:132px;display:flex;align-items:center;gap:22px;padding:0 30px 0 22px;
   border-radius:18px;border:1.5px solid $5;background:$6}
.i{width:84px;height:84px;flex-shrink:0;filter:drop-shadow(0 10px 18px rgba(30,215,96,.35))}
.t{flex:1;min-width:0;display:flex;flex-direction:column;gap:9px}
.t b{font-family:Syne,sans-serif;font-weight:800;font-size:22px;letter-spacing:0;color:#F0F4F8;white-space:nowrap}
.t span{font-family:'JetBrains Mono',monospace;font-size:14px;color:#9AA5B1;letter-spacing:.3px}
.f{width:58px;height:58px;border-radius:16px;flex-shrink:0;display:flex;align-items:center;justify-content:center;$7}
</style></head><body><div class="w">
  <img class="i" src="$LOGO">
  <div class="t"><b>$3</b><span>v$VERSION · Android 8+ · $4$taille</span></div>
  <div class="f"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$8" stroke-width="2.6"
    stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v12"/><path d="M6 11l6 6 6-6"/><path d="M5 21h14"/></svg></div>
</div>
HTML
pied; } > "$D/html/${1%.png}.html"
rendre "${1%.png}.html" "$DOCS/$1" 720
}

if [ "$LANGUE" = en ]; then COMPLETE='full version'; DEMO='demo, no bank'; else COMPLETE='version complète'; DEMO='démo, sans banque'; fi
bouton telecharger.png SmartBudget.apk 'Télécharger Smart Budget' "$COMPLETE" '#1E4A30'   'linear-gradient(100deg,#0E2016 0%,#0C1712 55%,#0A120E 100%)' 'background:linear-gradient(135deg,#1ED760,#50F48D)' '#04130A'
bouton telecharger-demo.png SmartBudget-demo.apk 'Essayer la démo' "$DEMO" '#26382D'   'linear-gradient(100deg,#111A14 0%,#0E1410 55%,#0B100D 100%)' 'border:2px solid #1ED760' '#1ED760'

# Puis la même chose en anglais, dans docs/en/.
[ -z "$LANGUE" ] && LANGUE=en bash "${BASH_SOURCE[0]}"

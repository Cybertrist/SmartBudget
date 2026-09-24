#!/bin/bash
# Toutes les figures fixes du README : la bannière, les bandeaux de
# section, les fonctionnalités, les planches de captures, la pile, les
# couches, le modèle de données, les tests, la confidentialité, la palette
# et le bouton de téléchargement. C'est le seul fichier à ouvrir pour
# changer un texte.
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
.pl{display:flex;gap:8px;margin-top:18px}
.pl span{font-family:'Space Grotesk',sans-serif;font-size:12.5px;font-weight:500;letter-spacing:.6px;
  color:#1ED760D0;border:1px solid #1ED7603A;background:#1ED7600E;border-radius:6px;padding:6px 11px}
.ln{position:absolute;left:0;right:0;bottom:0;height:3px;background:linear-gradient(90deg,#1ED760 0%,#50F48D 40%,transparent 90%)}
</style></head><body>
<div class="w"><div class="grille"></div>
<div class="cat"><b>ANDROID</b><b>FINANCES</b><b>OPEN SOURCE</b></div>
<div class="in"><img class="logo" src="$LOGO">
<div><h1>Smart <em>Budget</em></h1>
<p>Votre argent. Vos projets. Votre avenir.<br>Le compte du Crédit Mutuel de Bretagne, lu par la DSP2, classé, analysé et chiffré sur le téléphone.</p>
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
.ix{width:52px;height:40px;display:flex;align-items:center;justify-content:center;font-family:'JetBrains Mono',monospace;
  font-size:15px;color:#1ED760;border:1.5px solid #1ED7604D;background:#1ED7601C;border-radius:6px}
h2{font-family:Syne,sans-serif;font-weight:800;font-size:29px;letter-spacing:5px;text-transform:uppercase;white-space:nowrap}
.r{height:2px;display:flex}.r .a{width:52px;background:#1ED760}.r .b{flex:1;background:linear-gradient(90deg,#3A4450,#222A34 42%,transparent)}
</style></head><body>
<div class="w"><div class="l"><div class="ix">$1</div><h2>$2</h2></div><div class="r"><i class="a"></i><i class="b"></i></div></div>
HTML
pied; } > "$D/html/s$1.html"
rendre "s$1.html" "$DOCS/sections/s$1.png"
}
n=1
for titre in "Fonctionnalités" "Les écrans" "Installer" "Relier la banque" "Comment une opération est lue" \
             "Virements, remboursements, espèces" "L'écran déplié" "La pile" "Architecture" \
             "Le chiffrement" "Modèle de confidentialité" "Les tests" "Licence et auteur"; do
  bandeau "$(printf '%02d' $n)" "$titre"; n=$((n+1))
done

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
  "account_balance|Le compte, tout seul|Le Crédit Mutuel de Bretagne lu par la DSP2 via Enable Banking : douze mois d'historique, puis une synchronisation à chaque ouverture." \
  "category|Classé sans rien faire|23 catégories, 180 sous-catégories, 250 marchands reconnus. Une correction est apprise et suivie par les prochaines opérations." \
  "donut_large|L'anneau des dépenses|Le mois, trois mois ou un an : où part l'argent, catégorie par catégorie, jusqu'à l'opération." \
  "sync_alt|Les virements internes à part|Vers le livret, depuis le livret : ni dépense ni revenu, hachurés, hors budget. Mis de côté et pioché, suivis." \
  "link|Les remboursements liés|Un chèque de 500 € réparti sur deux dépenses : elles ne comptent plus que pour leur reste à charge." \
  "autorenew|Les récurrences|Loyer, forfait, abonnements : repérés seuls, réglables à la main, en retard, à venir ou payés." \
  "fact_check|À vérifier, et pointer|Ce que rien ne reconnaît attend sa catégorie. Une coche verte dit qu'une opération a été vérifiée." \
  "payments|Espèces et portefeuille|Une dépense en espèces se saisit ; elle se retranche des retraits, et le portefeuille suit ce qui reste." \
  "savings|Livrets et épargne|Saisis une fois avec leur solde, puis tenus à jour par les virements repérés sur le compte courant." \
  "search|La recherche|Toutes les opérations, depuis la première : un nom, une note, un montant." \
  "lock|Chiffré sur le téléphone|SQLCipher, clé dans le Keystore, déverrouillée par l'empreinte. Captures et aperçu du multitâche bloqués." \
  "backup|La sauvegarde chiffrée|Un fichier AES-GCM, clé tirée d'une phrase par PBKDF2, qui se relit sur un autre téléphone."

grille stack 3 \
  "code|Flutter 3|L'application entière, en Dart, un seul code pour le téléphone et l'écran déplié." \
  "database|sqflite_sqlcipher|SQLite chiffré par SQLCipher, schéma en version 5, migrations sans perte." \
  "key|flutter_secure_storage|La clé maîtresse dans le Keystore Android, jamais sur le disque en clair." \
  "enhanced_encryption|cryptography|HKDF pour dériver les clés, AES-GCM pour la clé bancaire et la sauvegarde, PBKDF2 pour la phrase." \
  "fingerprint|local_auth|L'empreinte, qui charge la clé : sans elle, la base reste illisible." \
  "account_tree|flutter_riverpod|L'état : une écriture fait relire tout ce qui en dépend, d'un seul appel." \
  "route|go_router|La navigation, et la garde du verrou sur chaque page." \
  "draw|java.security|La signature RS256 des requêtes à la banque, côté natif Kotlin." \
  "calendar_month|intl|Les dates et les montants à la française."

grille tests 3 \
  "rule|Libellés|Le marchand sort du bruit de la banque, et sa clé ne change pas d'un mois à l'autre." \
  "sync_alt|Virements internes|Vers le livret, depuis le livret, un livret au nom inhabituel, et un virement à quelqu'un qui n'en est pas un." \
  "autorenew|Récurrences|Un abonnement mensuel reconnu avec sa prochaine date, des courses irrégulières qui n'en sont pas." \
  "category|Classement|Le dictionnaire, les corrections apprises et suivies, et une synchronisation relancée qui ne double rien." \
  "calculate|Bilan|Remboursements répartis, remboursement marchand, dépense en espèces retirée des retraits." \
  "account_balance_wallet|Portefeuille|50 € comptés, un retrait de 20 €, 12 € au marché : il en reste 58." \
  "backup|Sauvegarde|Tout revient avec la bonne phrase ; une phrase fausse ne touche à rien." \
  "draw|Signature|Le JWT signé par le natif est, octet pour octet, celui d'OpenSSL." \
  "phone_android|Sur appareil|Les 22 tests tournent sur un émulateur Android : SQLCipher et le Keystore n'existent que là."

# --------------------------------------------------------------- couches
{ entete 1280; echo "$ICONES"; cat <<'HTML'
<style>
.w{padding:24px 56px;display:flex;flex-direction:column;gap:10px}
.c{display:grid;grid-template-columns:220px 1fr;align-items:center;gap:22px;background:var(--carte);border:1px solid var(--bord);
  border-radius:14px;padding:16px 20px;position:relative}
.c:before{content:'';position:absolute;left:0;top:14px;bottom:14px;width:3px;border-radius:2px;background:var(--a)}
.n{display:flex;align-items:center;gap:12px;font-family:'JetBrains Mono',monospace;font-size:14px;color:var(--a)}
.n span{font-family:'Material Symbols Rounded';font-size:22px}
p{font-family:'Space Grotesk',sans-serif;font-size:14px;line-height:1.5;color:var(--texte)}
code{font-family:'JetBrains Mono',monospace;font-size:12.5px;color:#C3CCD7}
.f{text-align:center;font-family:'Material Symbols Rounded';color:#2F3A47;font-size:20px;line-height:1;margin:-4px 0}
</style></head><body><div class="w">
<div class="c" style="--a:#50F48D"><div class="n"><span>smartphone</span>ecrans/</div><p>Ne lisent que des providers et n'écrivent que par des dépôts. Aucune ligne de SQL. Sur l'écran déplié, les pages deviennent des volets.</p></div>
<div class="f">south</div>
<div class="c" style="--a:#3CE0FF"><div class="n"><span>account_tree</span>providers/</div><p>Riverpod. Une écriture monte un numéro de version : tout ce qui lit la base se relit, d'un seul appel.</p></div>
<div class="f">south</div>
<div class="c" style="--a:#FFC857"><div class="n"><span>functions</span>domaine/</div><p>Du Dart pur, testé sans appareil : lire un libellé, reconnaître un virement interne, classer, détecter les récurrences, faire le bilan.</p></div>
<div class="f">south</div>
<div class="c" style="--a:#FF8FD1"><div class="n"><span>storage</span>donnees/</div><p>Le seul endroit où s'écrit du SQL : les dépôts, le schéma et ses migrations, la sauvegarde, le jeu d'essai.</p></div>
<div class="f">south</div>
<div class="c" style="--a:#1ED760"><div class="n"><span>account_balance</span>banque/</div><p>Enable Banking : le JWT signé, l'autorisation, la session, les opérations et le solde. La clé privée n'est déchiffrée que le temps d'un appel.</p></div>
<div class="f">south</div>
<div class="c" style="--a:#B08CFF"><div class="n"><span>shield_lock</span>security/</div><p>Le trousseau : clé maîtresse dans le Keystore, dérivations HKDF, verrou. Rien ne lit un fichier en passant outre.</p></div>
</div>
HTML
pied; } > "$D/html/couches.html"
rendre couches.html "$DOCS/schemas/couches.png"

# ---------------------------------------------------------------- modèle
table () {
  local nom="$1" ic="$2" coul="$3"; shift 3
  printf '<div class="t" style="--a:%s"><div class="h"><span>%s</span>%s</div>' "$coul" "$ic" "$nom"
  for ch in "$@"; do IFS=':' read -r a b <<< "$ch"; printf '<div class="r"><b>%s</b><i>%s</i></div>' "$a" "$b"; done
  printf '</div>'
}
{ entete 1280; echo "$ICONES"; cat <<HTML
<style>
.w{padding:24px 56px;display:grid;grid-template-columns:repeat(3,1fr);gap:14px;align-items:start}
.t{background:var(--carte);border:1px solid var(--bord);border-radius:14px;overflow:hidden}
.h{display:flex;align-items:center;gap:10px;padding:13px 16px;font-family:'JetBrains Mono',monospace;font-size:14px;font-weight:700;
  color:var(--a);border-bottom:1px solid var(--bord);background:linear-gradient(90deg,color-mix(in srgb,var(--a) 12%,transparent),transparent)}
.h span{font-family:'Material Symbols Rounded';font-size:20px;font-weight:400}
.r{display:flex;justify-content:space-between;gap:12px;padding:7px 16px;border-top:1px solid #1A222C}
.r:first-of-type{border-top:0}
.r b{font-family:'JetBrains Mono',monospace;font-size:12.5px;font-weight:500;color:#C3CCD7}
.r i{font-style:normal;font-family:'Space Grotesk',sans-serif;font-size:12.5px;color:var(--texte);text-align:right}
</style></head><body><div class="w">
$(table operations receipt_long '#1ED760' "libelle:tel que la banque l'écrit" "montant_centimes:un entier, jamais un flottant" "categorie_id:vers categories" "origine:main, règle, dictionnaire, interne" "interne:vers ou depuis l'épargne" "uid_banque:unique : rien ne se double" "nom · note:choisis à la main" "pointee · especes:vérifiée, payée en liquide" "mois_compte:rattachée à un autre mois")
$(table categories category '#FFC857' "nom · icone · couleur:ce qui se voit" "parent_id:une sous-catégorie" "genre:dépense, revenu, épargne, interne" "nature:essentiel, plaisir, imprévu")
$(table comptes account_balance_wallet '#3CE0FF' "nature:courant, livret, portefeuille" "solde_centimes:au dernier relevé" "motif:son nom dans les virements")
$(table liens link '#FF8FD1' "entree_id:le remboursement" "depense_id:la dépense remboursée" "montant_centimes:la part qui lui revient")
$(table regles school '#B08CFF' "motif:le marchand appris" "categorie_id:où il va désormais")
$(table reglages tune '#8FA3B8' "cle · valeur:budget, début du mois" "banque_*:clé chiffrée, session" "repetition · nom:choix par marchand")
</div>
HTML
pied; } > "$D/html/modele.html"
rendre modele.html "$DOCS/schemas/modele.png"

# ------------------------------------------------------- confidentialité
{ entete 1280; echo "$ICONES"; cat <<'HTML'
<style>
.w{padding:24px 56px;display:grid;grid-template-columns:1fr 1fr;gap:16px}
.col{background:var(--carte);border:1px solid var(--bord);border-radius:14px;padding:18px 20px}
h3{display:flex;align-items:center;gap:10px;font-family:Syne,sans-serif;font-size:19px;margin-bottom:10px;color:var(--a)}
h3 span{font-family:'Material Symbols Rounded';font-size:24px}
li{list-style:none;display:flex;gap:10px;padding:9px 0;border-top:1px solid #1A222C;font-family:'Space Grotesk',sans-serif;font-size:14px;line-height:1.5;color:var(--texte)}
li:first-child{border-top:0}
li:before{content:'';flex-shrink:0;width:6px;height:6px;border-radius:50%;margin-top:8px;background:var(--a)}
b{color:#DDE4EC;font-weight:600}
</style></head><body><div class="w">
<div class="col" style="--a:#1ED760"><h3><span>verified_user</span>Ce qui est vrai</h3><ul>
<li><span><b>Aucun serveur à moi.</b> L'application ne parle qu'à Enable Banking, pour lire le compte. Pas de compte, pas d'analytique, pas de publicité.</span></li>
<li><span><b>La base est chiffrée</b> par SQLCipher ; sa clé vit dans le Keystore et n'est chargée qu'après l'empreinte.</span></li>
<li><span><b>La clé bancaire est chiffrée deux fois</b> : en AES-GCM par une clé dérivée, dans une base elle-même chiffrée.</span></li>
<li><span><b>La DSP2 ne donne que la lecture.</b> Aucun virement ne peut partir de l'application, et l'accès expire au bout de 180 jours.</span></li>
<li><span><b>L'écran est protégé</b> : captures bloquées, aperçu du multitâche masqué, sauvegarde Android refusée.</span></li>
</ul></div>
<div class="col" style="--a:#FFC857"><h3><span>info</span>Ce qui ne l'est pas</h3><ul>
<li><span><b>Enable Banking voit passer les opérations</b> le temps de les transmettre : c'est l'agrégateur agréé qui lit la banque.</span></li>
<li><span><b>L'application ouverte montre tout.</b> L'empreinte protège l'accès, pas ton épaule.</span></li>
<li><span><b>Une sauvegarde voyage</b> et vaut ce que vaut sa phrase. Sans la phrase, elle est perdue, pour tout le monde.</span></li>
<li><span><b>Perdre le téléphone, c'est perdre les données</b> qui n'ont pas été sauvegardées : la clé ne se recopie nulle part.</span></li>
<li><span><b>L'empreinte se coupe</b> dans les réglages ; les données restent chiffrées, mais s'ouvrent sans preuve.</span></li>
</ul></div>
</div>
HTML
pied; } > "$D/html/confidentialite.html"
rendre confidentialite.html "$DOCS/schemas/confidentialite.png"

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

# ------------------------------------------------------ bouton télécharger
VERSION="$(grep '^version:' "$D/../../pubspec.yaml" | sed 's/version: *//; s/+.*//')"
APK="$D/../../build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
TAILLE="$([ -f "$APK" ] && awk "BEGIN{printf \"%.0f Mo\", $(stat -c%s "$APK")/1048576}" || echo '')"
# Comme BodyCount : le logo de l'application à gauche, le nom, la version,
# et un carré vert de téléchargement. Seuls les coins arrondis sont
# transparents : GitHub rend les README sur blanc comme sur noir.
{ entete 720; cat <<HTML
<style>
html,body{width:720px;height:132px;overflow:hidden;background:transparent}
.w{width:720px;height:132px;display:flex;align-items:center;gap:22px;padding:0 30px 0 22px;
   border-radius:18px;border:1.5px solid #1E4A30;background:linear-gradient(100deg,#0E2016 0%,#0C1712 55%,#0A120E 100%)}
.i{width:84px;height:84px;flex-shrink:0;filter:drop-shadow(0 10px 18px rgba(30,215,96,.35))}
.t{flex:1;min-width:0;display:flex;flex-direction:column;gap:9px}
.t b{font-family:Syne,sans-serif;font-weight:800;font-size:22px;letter-spacing:0;color:#F0F4F8;white-space:nowrap}
.t span{font-family:'JetBrains Mono',monospace;font-size:14px;color:#9AA5B1;letter-spacing:.3px}
.f{width:58px;height:58px;border-radius:16px;flex-shrink:0;display:flex;align-items:center;justify-content:center;
   background:linear-gradient(135deg,#1ED760,#50F48D)}
</style></head><body><div class="w">
  <img class="i" src="$LOGO">
  <div class="t"><b>Télécharger Smart Budget</b><span>v$VERSION · Android 8+ · arm64 · $TAILLE</span></div>
  <div class="f"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#04130A" stroke-width="2.6"
    stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v12"/><path d="M6 11l6 6 6-6"/><path d="M5 21h14"/></svg></div>
</div>
HTML
pied; } > "$D/html/telecharger.html"
rendre telecharger.html "$DOCS/telecharger.png" 720

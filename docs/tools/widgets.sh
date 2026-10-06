#!/bin/bash
# La planche des widgets de l'écran d'accueil.
#
# Les sources sont dans src-widgets/ : les images que l'application
# dessine elle-même, sorties de la démo en débogage (seule version où tous
# les widgets sont photographiés), donc remplies par le jeu d'essai. Aucun
# vrai montant n'apparaît jamais ici. Ce sont aussi les aperçus du
# sélecteur de widgets, dans android/app/src/main/res/drawable-nodpi/.
#
#   bash docs/tools/widgets.sh
source "$(dirname "${BASH_SOURCE[0]}")/rendu.sh"
mkdir -p "$DOCS/schemas"
SRC="file:///$B/src-widgets"

# widget <colonnes> <fichier> <largeur> <titre> <taille> <légende>
widget () { printf '<figure style="grid-column:span %s"><div class="fond"><img src="%s/%s.png" style="width:%spx"></div><figcaption><b>%s<i>%s</i></b>%s</figcaption></figure>' "$1" "$SRC" "$2" "$3" "$4" "$5" "$6"; }

{ entete 1280; cat <<HTML
<style>
.w{padding:26px 48px;display:grid;grid-template-columns:repeat(12,1fr);gap:26px 22px}
figure{display:flex;flex-direction:column;gap:12px}
/* Un coin d'écran d'accueil : le widget s'y pose comme sur le téléphone. */
.fond{height:270px;display:flex;align-items:center;justify-content:center;border-radius:22px;
  background:radial-gradient(90% 120% at 15% 0%,#1ED7601F 0%,transparent 60%),linear-gradient(160deg,#1A2330,#0F141B 60%,#141C26);
  box-shadow:0 0 0 1px #2F3A47,inset 0 0 0 1px #FFFFFF0A}
.fond img{display:block;height:auto;filter:drop-shadow(0 16px 26px #0009)}
.bas .fond{height:150px}
figcaption{font-family:'Space Grotesk',sans-serif;font-size:13px;line-height:1.45;color:var(--texte);padding:0 6px}
figcaption b{display:flex;align-items:center;gap:9px;font-size:14.5px;color:var(--titre);margin-bottom:3px}
figcaption i{font-style:normal;font-family:'JetBrains Mono',monospace;font-weight:500;font-size:11px;color:#1ED760;
  border:1px solid #1ED76038;background:#1ED76014;border-radius:5px;padding:2px 7px}
.note{grid-column:span 8;align-self:start;height:150px;display:flex;flex-direction:column;justify-content:center;
  border:1px dashed #2F3A47;border-radius:22px;padding:0 26px;font-family:'Space Grotesk',sans-serif;font-size:14px;line-height:1.55;color:var(--texte)}
.note b{display:block;color:#1ED760;font-size:15px;margin-bottom:6px}
</style></head><body>
<div class="w">
$(widget 4 analyse 222 'Analyse' '2 × 2' 'L’anneau des sorties du mois, une part et une icône par catégorie.')
$(widget 4 budget 222 'Budget' '2 × 2' 'Ce qu’il reste du budget du mois, et sa jauge.')
$(widget 4 epargne 222 'Épargne' '2 × 2' 'Le total des livrets, face à l’objectif.')
$(widget 4 comptes 330 'Mes comptes' '4 × 2' 'Le total, puis le compte courant, l’épargne et les espèces.')
$(widget 4 depenses 330 'Dépenses du mois' '4 × 2' 'Le total du mois et ses trois plus grosses catégories.')
$(widget 4 avenir 330 'À venir' '4 × 2' 'Les trois prochains prélèvements qui reviennent tout seuls.')
<figure class="bas" style="grid-column:span 4"><div class="fond"><img src="$SRC/especes.png" style="width:330px"></div><figcaption><b>Dépense en espèces<i>4 × 1</i></b>Un appui ouvre la saisie d’une dépense en espèces.</figcaption></figure>
<div class="note"><b>Dessinés par l’application elle-même</b>Chaque widget est une image que SmartBudget compose avec ses propres tuiles, ses couleurs et sa police, puis confie à Android. Un appui ouvre la bonne page, derrière l’empreinte.</div>
</div>
HTML
pied; } > "$D/html/widgets.html"
rendre widgets.html "$DOCS/schemas/widgets.png"

# Puis la même chose en anglais, dans docs/en/.
if [ -z "$LANGUE" ]; then LANGUE=en bash "${BASH_SOURCE[0]}"; fi

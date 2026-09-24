#!/bin/bash
# Les planches de captures : le téléphone, puis l'écran déplié du Fold.
#
# Les sources sont dans src-captures/<format>/, déjà rognées de leurs
# barres par rogner.js. Elles viennent de l'émulateur, remplies par le jeu
# d'essai : aucun vrai montant n'apparaît jamais ici.
#
#   bash docs/tools/captures.sh
source "$(dirname "${BASH_SOURCE[0]}")/rendu.sh"
mkdir -p "$DOCS/schemas"
SRC="file:///$B/src-captures"

# ecran <format> <fichier> <titre> <légende>
ecran () { printf '<figure class="%s"><div class="cadre"><img src="%s/%s/%s.jpg"></div><figcaption><b>%s</b>%s</figcaption></figure>' "$1" "$SRC" "$1" "$2" "$3" "$4"; }

style () { cat <<'HTML'
<style>
.w{padding:26px 48px;display:grid;gap:26px 22px}
figure{display:flex;flex-direction:column;gap:12px}
.cadre{border-radius:26px;padding:7px;background:linear-gradient(160deg,#2A3340,#10151C 45%,#1B232E);
  box-shadow:0 20px 40px #0009,0 0 0 1px #2F3A47,inset 0 0 0 1px #FFFFFF10}
.cadre img{display:block;width:100%;border-radius:20px}
.deplie .cadre{border-radius:22px}.deplie .cadre img{border-radius:16px}
figcaption{font-family:'Space Grotesk',sans-serif;font-size:13px;line-height:1.45;color:var(--texte);padding:0 6px}
.note{align-self:center;border:1px dashed #2F3A47;border-radius:18px;padding:22px;font-family:'Space Grotesk',sans-serif;font-size:14px;line-height:1.55;color:var(--texte)}
.note b{display:block;color:#1ED760;font-size:15px;margin-bottom:6px}
figcaption b{display:block;font-size:14.5px;color:var(--titre);margin-bottom:2px}
</style></head><body>
HTML
}

{ entete 1280; style; cat <<HTML
<div class="w" style="grid-template-columns:repeat(4,1fr)">
$(ecran telephone 00-ouverture 'L’ouverture' 'Le logo, l’accroche, et l’empreinte qui charge la clé.')
$(ecran telephone 01-accueil 'Le mois' 'Le solde de tous les comptes, ce qui reste à vérifier, tes comptes.')
$(ecran telephone 02-accueil-bas 'Où part l’argent' 'Budget, épargne, les cinq premières catégories, la répartition.')
$(ecran telephone 03-analyse 'L’anneau' 'Un mois, trois ou un an. Le centre ouvre les opérations.')
$(ecran telephone 04-categorie 'Une catégorie' 'Ses sous-catégories, et celles qui n’ont rien eu ce mois-ci.')
$(ecran telephone 05-recurrences 'Les récurrences' 'Payées, à venir, en retard : ce qui revient tout seul.')
$(ecran telephone 06-epargne 'L’épargne' 'Mis de côté, pioché, les livrets tenus par les virements.')
$(ecran telephone 07-verifier 'À vérifier' 'Ce que rien n’a reconnu : classer, ou marquer interne.')
$(ecran telephone 08-operations 'Les opérations' 'Toutes, jour par jour, avec la recherche et les espèces.')
$(ecran telephone 09-operation 'Une opération' 'Nom, mouvement, catégorie, type, répétition, remboursement.')
$(ecran telephone 10-reglages 'Les réglages' 'La banque, le budget, la sécurité, la sauvegarde.')
<div class="note"><b>Jeu d’essai</b>Toutes ces captures viennent d’un émulateur rempli par le jeu d’essai de l’application : aucun vrai compte, aucun vrai montant.</div>
</div>
HTML
pied; } > "$D/html/captures-telephone.html"
rendre captures-telephone.html "$DOCS/schemas/captures-telephone.png"

{ entete 1280; style; cat <<HTML
<div class="w" style="grid-template-columns:repeat(2,1fr)">
$(ecran deplie 01-accueil 'Le mois, en deux colonnes' 'Tout tient sur l’écran, sans défiler.')
$(ecran deplie 02-analyse 'L’analyse' 'L’anneau à gauche, les catégories à droite.')
$(ecran deplie 03-categorie 'Toucher Logement…' '…pousse tout vers la gauche : la ligne ouverte reste surlignée.')
$(ecran deplie 04-sous 'Puis Loyer' 'Un volet de plus, le geste retour en referme un.')
$(ecran deplie 05-operation 'Jusqu’à l’opération' 'Le titre porte le montant, la page tient en un bloc.')
$(ecran deplie 06-epargne 'L’épargne' 'Les livrets à gauche, les mouvements du mois à droite.')
</div>
HTML
pied; } > "$D/html/captures-deplie.html"
rendre captures-deplie.html "$DOCS/schemas/captures-deplie.png"

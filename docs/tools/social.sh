#!/bin/bash
# L'image d'aperçu du dépôt, celle que GitHub montre quand le lien est
# partagé : 1280 x 640, la taille que GitHub recommande. Le logo et le nom
# à gauche, deux écrans de l'application à droite. Comme BodyCount.
#
# À déposer dans Settings > General > Social preview : GitHub ne la lit
# pas depuis le dépôt.
#
#   bash docs/tools/social.sh
source "$(dirname "${BASH_SOURCE[0]}")/rendu.sh"
SRC="file:///$B/src-captures/telephone"

cat > "$D/html/social.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@800&family=Space+Grotesk:wght@400;500&family=JetBrains+Mono:wght@600&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;height:640px;overflow:hidden;background:#07100B}
.w{position:relative;width:1280px;height:640px;overflow:hidden;
   background:radial-gradient(circle at 12% 30%,#0F3A22 0,transparent 42%),
              radial-gradient(circle at 88% 90%,#0E3320 0,transparent 45%),#07100B}
.w::after{content:"";position:absolute;left:0;right:0;bottom:0;height:6px;background:linear-gradient(90deg,#1ED760,#50F48D)}
.g{position:absolute;left:84px;top:0;bottom:0;width:600px;display:flex;flex-direction:column;justify-content:center}
.logo{width:132px;height:132px;filter:drop-shadow(0 0 40px rgba(80,244,141,.45))}
h1{margin-top:36px;white-space:nowrap;font-family:Syne,sans-serif;font-weight:800;font-size:58px;line-height:1;letter-spacing:-1px;color:#F0F4F8}
h1 em{font-style:normal;color:#50F48D}
p{margin-top:22px;font-family:'Space Grotesk',sans-serif;font-size:25px;line-height:1.45;color:#A7B0BD}
.c{margin-top:30px;display:flex;gap:12px}
.c span{font-family:'JetBrains Mono',monospace;font-weight:600;font-size:15px;letter-spacing:1.5px;
  color:#50F48D;padding:10px 16px;border-radius:9px;border:1.5px solid #1E4A30;background:#0C1C13}
.e{position:absolute;width:220px;border-radius:26px;overflow:hidden;border:1.5px solid #24402F;
   box-shadow:0 40px 80px -20px rgba(0,0,0,.8),0 0 60px -10px rgba(30,215,96,.35)}
.e img{width:100%;display:block}
.e1{left:770px;transform:rotate(-6deg);top:92px}
.e2{left:1010px;transform:rotate(5deg);top:58px}
</style></head><body><div class="w">
  <div class="g">
    <img class="logo" src="file:///$DOCS/logo.png">
    <h1>Smart <em>Budget</em></h1>
    <p>Votre argent. Vos projets. Votre avenir.<br>Le compte, lu, classé et chiffré sur le téléphone.</p>
    <div class="c"><span>FLUTTER</span><span>DSP2</span><span>CHIFFRÉ</span></div>
  </div>
  <div class="e e1"><img src="$SRC/01-accueil.jpg"></div>
  <div class="e e2"><img src="$SRC/03-analyse.jpg"></div>
</div></body></html>
HTML

"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=15000 \
  --window-size=1280,640 --screenshot="$DOCS/social-preview.png" "file:///$B/html/social.html" >/dev/null 2>&1
echo "  social-preview.png"

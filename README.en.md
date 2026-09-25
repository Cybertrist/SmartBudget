<div align="center">

<p>
  <a href="README.md"><img src="docs/langues/fr-off.png" alt="Lire cette page en français" width="150" /></a>
  <img src="docs/langues/en-on.png" alt="English, page shown" width="150" />
</p>

<img src="docs/en/banniere.png" alt="Smart Budget: your money, your plans, your future. Stay in control, enjoy the essentials. Flutter, Enable Banking, SQLCipher, AES-GCM, Fold." width="100%">

</div>

<br>

An Android budgeting app, made for one person and one account: their own. It reads the current account over PSD2, files every transaction under its category, sets aside what is neither spending nor income, and shows where the money goes, month after month. Everything stays on the phone, encrypted.

It came from a simple wish: stop spending without looking, and stop dipping into savings. The model is Bankin; the style is Spotify's, plain and dark, with a single green.

The app itself is in French; this page is its English description.

<img src="docs/en/sections/s01.png" alt="01 Features" width="100%">

<img src="docs/en/schemas/fonctionnalites.png" alt="Twelve features. The account, on its own: the current account read over PSD2 through Enable Banking, twelve months of history, a sync at every launch, and an alert if the account goes overdrawn. Categorised for you: 23 categories, 180 subcategories, 250 known merchants, and learned corrections. The spending ring, over one month, three months or a year. Internal transfers kept apart, outside the budget. Refunds linked to their expenses. Recurring payments found on their own. Review and tick off. Cash and wallet. Savings accounts kept by transfers. Search across every transaction. Encrypted on the phone. Encrypted backup." width="100%">

<img src="docs/en/sections/s02.png" alt="02 The screens" width="100%">

On the phone, a floating capsule at the bottom to get around.

<img src="docs/en/schemas/captures-telephone.png" alt="Eleven phone screens. Unlock: the logo, the tagline and the fingerprint. The month: the balance of every account, transactions to review, the accounts. Where the money goes: budget, savings, the top five categories, the split between essential, treat, savings and unexpected. The spending ring, whose centre opens the transactions. A category and its subcategories. Recurring payments, paid, upcoming and late. Savings, put aside and dipped into, the savings accounts. To review. Transactions day by day, with search and the cash button. A transaction, with its name, movement, category, type and repetition. Settings, with the bank, the budget, security and backup. All of them come from the demo data." width="100%">

On the Fold's unfolded screen, a rail on the left, and pages become panes side by side.

<img src="docs/en/schemas/captures-deplie.png" alt="Six screens on the Fold's unfolded screen. The month in two columns, no scrolling. The analysis, the ring on the left and the categories on the right. Tapping Housing pushes everything left, the open row stays highlighted. Then Rent, one more pane. Down to the Foncia Rent transaction, whose title carries the amount. Savings, the savings accounts on the left and the month's movements on the right." width="100%">

<img src="docs/en/schemas/palette.png" alt="Palette: green #1ED760, logo neon #50F48D, background #121212, cards #181818, savings #3CE0FF, internal transfers #8FA3B8, warning #FFC857, alert #FF6B7A." width="100%">

<img src="docs/en/sections/s03.png" alt="03 Install" width="100%">

<p align="center">
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget.apk"><img src="docs/en/telecharger.png" alt="Download Smart Budget, the full version, Android 8 or later" width="400"></a>
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget-demo.apk"><img src="docs/en/telecharger-demo.png" alt="Try the Smart Budget demo, no bank, Android 8 or later" width="400"></a>
</p>

Two apps, which install side by side without getting in each other's way.

- **SmartBudget**, the full version: it links to your bank and holds only your real transactions.
- **SmartBudget démo**: four months of made-up transactions, already loaded when it opens, no bank, no fingerprint, and screenshots allowed. To see every screen before linking anything.

The APKs are not on the Play Store: Android asks, once, to allow installs from the browser. Every version is signed with the same key, so it installs over the previous one without losing anything. To check the downloaded file:

```
# SHA-256 of SmartBudget.apk, version 1.1.0
8ba46b6c6ddd59e2ca070cc10bb91a97952e8c8b4e038a531fa0c017fb501955

# SHA-256 of SmartBudget-demo.apk, version 1.1.0
fe4cf85184ed59b62302309c7b00a106e4fdee90e00a51cfa3b9c15d7d63874a

# SHA-256 of the signing certificate, CN=SmartBudget, O=Cybertrist
55572db26550312a39ee80315ad81ce6c31e492f0e3aebfc8e5e0f2cffabcbef
```

To build it yourself:

```
flutter build apk --release --split-per-abi
# the demo, with its own identifier and the demo data already loaded:
flutter build apk --release --split-per-abi --dart-define=DEMO=true
```

<img src="docs/en/sections/s04.png" alt="04 Linking the bank" width="100%">

Banks do not talk to individuals: you need a PSD2-licensed aggregator. [Enable Banking](https://enablebanking.com) offers one, free in restricted mode, meaning limited to the accounts you linked yourself on its portal. Bridge, Bankin's API, is for businesses only, and GoCardless has closed sign-ups.

**Before you start**, you need: SmartBudget installed, an email address you can open on the phone, and whatever you use to sign in to your online banking (login, and the usual confirmation, Safetrans at Crédit Mutuel). It takes about ten minutes, once: after that, access lasts 180 days.

<img src="docs/en/schemas/parcours-banque.svg" alt="Choosing and linking your bank, in five steps, on an animated phone. 1, in Settings, the Your bank card, tap Choose the bank. 2, find yours by name or country, then tap it. 3, the Get your key page: Open the portal opens the Enable Banking site in the browser, and every value to paste has its own Copy button. 4, Import the key: pick the .pem file in Downloads, without renaming it; it is encrypted at once and the copy deleted. 5, the bank's page opens, you confirm as usual, then the card shows Synced, access for 180 more days, and the transactions arrive." width="100%">

The app itself is in French: button names below are given as they appear on screen, with their meaning in brackets.

### 1. Choose the bank

**Réglages** (Settings) tab, **Ta banque** (Your bank) card, **Choisir la banque** (Choose the bank) button. The list holds every bank Enable Banking can read for individuals, in some thirty European countries: the major banks of the phone's country first, then all the others from A to Z.

### 2. Find yours

Type part of the name (`mutuel bretagne`) or a country (`belgique`) in the search field, then tap your bank. Each bank fits on one row, with its country: there is nothing to expand. Each one wears its mobile app's icon, bundled with SmartBudget: no image is loaded from the Internet, and banks without an app keep their initials.

Tapping the bank opens the **Obtenir ta clé** (Get your key) page straight away, which guides the next step.

### 3. Get your key on the Enable Banking portal

This is the only step outside the app. The **Obtenir ta clé** page lists the instructions in order, and every value to paste has its own **Copier** (Copy) button: you just go back and forth between SmartBudget and the browser.

<img src="docs/en/schemas/portail.svg" alt="On the Enable Banking portal. Sign in: type your email, Continue, then open the link you receive. Create the application, Add a new application: Environment Production, Private key Generate in the browser, Application name SmartBudget, then paste the values copied from SmartBudget: Allowed redirect URLs https://cybertrist.github.io/SmartBudget/, the description, Privacy URL and Terms URL; Email for data protection, your email. Register: a .pem file downloads, this is the key, never rename it. Then Activate by linking accounts: country, your bank, type personal, Link, and you confirm at your bank. The application is active, in free restricted mode." width="100%">

1. **Sign in.** Tap **Ouvrir le portail** (Open the portal): the sign-in page opens in the browser. Type your email, **Continue**, then open the link you receive by email. The Enable Banking account creates itself the first time.
2. **Create the application.** In **API applications**, fill in **Add a new application**:
   - **Environment**: `Production`
   - **Private key**: leave `Generate in the browser`
   - **Application name**: `SmartBudget`
   - **Allowed redirect URLs**: `https://cybertrist.github.io/SmartBudget/` (Copy button)
   - **Application description**: the suggested sentence (Copy button)
   - **Email for data protection**: your own email address
   - **Privacy URL** and **Terms URL**: `https://github.com/Cybertrist/SmartBudget` (Copy buttons)
3. **Register.** The portal downloads a `.pem` file: this is the application's private key. **Never rename it**: its name is the application ID, and SmartBudget reads it to use the key.
4. **Link your account on the portal.** On the application's page, tap **Activate by linking accounts**, choose the country, your bank and the `personal` type, then **Link**. The bank's page opens: sign in and confirm as usual. The application switches to restricted mode, free, limited to that account.

### 4. Import the key

Back in SmartBudget, at the bottom of the **Obtenir ta clé** page: **Importer la clé** (Import the key), and pick the `.pem` file in Downloads. It is encrypted on the phone at once (AES-GCM, with a key derived from the Keystore), and the working copy is deleted. The file left in Downloads can then be deleted, or stored somewhere safe to import the key again one day.

### 5. Link the account

The rest follows on its own: the bank's page opens one last time, you confirm as usual, and SmartBudget takes over again. The **Ta banque** card then shows **Synchronisé** (Synced), with the days of access left, and the last twelve months arrive.

After that, there is nothing left to do: SmartBudget syncs **every time it opens**, and every time you come back to it, as soon as the last sync is more than ten minutes old. The card's **Synchroniser** (Sync) button starts one by hand. Transactions still pending at the bank, like today's card payment, show up at once, marked **En attente** (Pending), then are replaced by their final version.

### If something goes wrong

- **"Le nom du fichier ne contient pas l'identifiant de l'application"** (the file name does not contain the application ID): the `.pem` file was renamed, for instance to `cle.pem`. Download it again from the application's page, without touching its name.
- **"Ce fichier n'est pas une clé privée"** (this file is not a private key): the chosen file is not the portal's `.pem`. Pick the one downloaded in step 3.
- **"Enable Banking refuse la clé"** (Enable Banking rejects the key): the imported key does not match the application, or the application is not in `Production`. Redo step 3, then import the new key (the card's **Nouvelle clé**, New key, button).
- **"Pas de connexion à Internet."** (no Internet connection): the sync resumes on its own the next time the app opens with a network.
- **"Trop de synchronisations aujourd'hui"** (too many syncs today): the bank limits the number of accesses per day. Just wait until tomorrow.
- **"L'accès a expiré : reconnecte le compte."** (access expired, reconnect the account): the 180 days are up. Tap **Relier le compte** (Link the account) and confirm at the bank: the key stays the same, nothing else to redo.
- **Your bank is not in the list**: Enable Banking cannot read it yet, or not for individuals.

Access expires after 180 days, by law, or sooner if the bank grants less: the bank card warns fifteen days ahead, and one tap renews it. PSD2 only shares the current account, which the bank calls "CARTE BANCAIRE": savings accounts are entered by hand, then follow the transfers the app spots. The app was written and tested with Crédit Mutuel de Bretagne: elsewhere, categorisation works the same way, but transfers to savings accounts may need to be marked by hand the first time.

### What happens behind the scenes

<img src="docs/en/schemas/banque.svg" alt="Linking the bank, an exchange between four parties: Smart Budget, Enable Banking, your bank and GitHub Pages. Smart Budget sends a JWT signed with RS256 and a random state; Enable Banking opens the bank's page; you approve with Safetrans; the bank comes back to GitHub Pages with a code and the state; the page hands back through smartbudget://banque; the app checks the state, trades the code for a 180-day session and the accounts, imports twelve months, then syncs at every launch." width="100%">

Every request to Enable Banking carries a token signed with RS256 by the imported key, decrypted only for the duration of the call. The bank's redirect goes through a GitHub Pages page (`docs/index.html`), which hands back to the app through the `smartbudget://banque` link; the state token, drawn at random at the start and checked on return, stops a link forged elsewhere from linking another account.

**The overdrawn alert** is the app's only notification. Every six hours, even with the app closed, it reads the current account's balance again, and nothing else: four reads a day at most, the limit PSD2 grants to access made without you. If it drops below zero, a notification gives the amount; the next one waits until the account has gone back up and down again.

<img src="docs/en/schemas/alerte.svg" alt="The balance watch. Every six hours, the current account balance is read again: 320, 180 and 60 euros, then -42.10 euros at midnight, and the locked phone gets the notification Current account overdrawn, with the amount. At the next two reads, -85 and -20 euros, no new alert: already told. At 150 euros, the alert re-arms. Four reads a day at most, the PSD2 limit." width="100%">

<img src="docs/en/sections/s05.png" alt="05 How a transaction is read" width="100%">

<img src="docs/en/schemas/classement.svg" alt="How a transaction is read. The label PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09 loses its noise, leaving the merchant key. Four questions follow one another: internal transfer, no; learned rule, no; dictionary, yes. Result: Groceries, Supermarket, essential." width="100%">

A bank label is written for the bank. The merchant is pulled out of it by removing prefixes, the masked card, dates, references and copied amounts; its key, its first three words without company suffixes, stays the same from one month to the next. That key carries corrections, chosen names and repetitions: renaming "Spotify P2f9 Stockholm" to "Spotify" renames all its transactions, the upcoming ones included.

What nothing recognises lands in "À classer" (uncategorised) and waits in **À vérifier** (to review), flagged on the home screen. A checked transaction gets ticked off, with a green tick.

<img src="docs/en/sections/s06.png" alt="06 Transfers, refunds, cash" width="100%">

<img src="docs/en/schemas/mouvements.svg" alt="Three traps in a statement. A transfer to savings, read in VIR VERS LIVRET A DE COMPTE COURANT, is outside the budget and counts 200 euros put aside. A 500 euro cheque refunds 300 euros of a 380 euro train ticket and 200 euros of a 260 euro restaurant: 80 and 60 euros are left, and the cheque is not income. A 50 euro withdrawal then 12 euros at the market in cash: withdrawals drop to 38, groceries rise to 12, the wallet goes from 50 to 38, and the month's spending stays at 50 euros." width="100%">

An honest budget never counts the same money twice.

- **A transfer between your own accounts** is neither spending nor income. At Crédit Mutuel de Bretagne it reads `VIR VERS <destination> DE <source>`: the direction is in the label. It leaves the budget, hatched, and feeds "put aside" or "dipped into". If detection gets it wrong, either way, the **Mouvement** (movement) row of a transaction fixes it.
- **A refund** is linked to the expenses it pays back, from either side. They then only count for what is left to pay, and the refund does not count as income.
- **A cash expense** is entered by hand. It comes off the month's withdrawals, and the **wallet**, if opened, tracks what is left in your pocket.

<img src="docs/en/sections/s07.png" alt="07 The unfolded screen" width="100%">

<img src="docs/en/schemas/volets.svg" alt="The unfolded screen. Two panes side by side, right of the rail. Tapping Housing pushes everything left and opens Housing on the right, then Rent, then the Foncia Rent transaction. The open row stays highlighted on the left. The back gesture, a green touch sliding from the right edge to the left, closes the panes one by one. On the right, the list of open pages grows then empties." width="100%">

A phone screen stretched over eight inches no longer looks like anything. On the open Fold, pages form one wide page showing its last two panes: you go down from the analysis to a single transaction without ever losing where you came from, and Samsung's back gesture closes the last pane. Each column tightens when needed to show everything at once, without scrolling. Inputs open in a card above the keyboard, never in a sheet sliding up from the bottom.

<img src="docs/en/sections/s08.png" alt="08 The stack" width="100%">

<img src="docs/en/schemas/stack.png" alt="Flutter 3 for the whole app. sqflite_sqlcipher for encrypted SQLite, schema version 6. flutter_secure_storage for the master key in the Keystore. cryptography for HKDF, AES-GCM and PBKDF2. local_auth for the fingerprint. flutter_riverpod for state. go_router for navigation and the lock guard. pointycastle for the RS256 signature of bank requests, in Dart. workmanager for the balance watch. flutter_local_notifications for the overdrawn alert. intl for dates and amounts. material_symbols_icons for the icons." width="100%">

<img src="docs/en/sections/s09.png" alt="09 Architecture" width="100%">

<img src="docs/en/schemas/couches.png" alt="Six layers. ecrans, the screens: read providers only, no SQL. providers: a write reloads everything. domaine, the domain: pure Dart, reading a label, spotting a transfer, categorising, detecting recurrences, tallying up. donnees, the data: the only place SQL is written. banque, the bank: Enable Banking, the key decrypted for one call. security: the keychain and the lock." width="100%">

<img src="docs/en/schemas/modele.png" alt="Six tables. operations: label, amount in cents, category, source, internal direction, unique bank ID, name and note, ticked off and cash, month it counts in. categories: name, icon, colour, parent, kind, nature. comptes, the accounts: current, savings or wallet, balance, pattern. liens, the links: the refunding income, the refunded expense, the share. regles, the rules: the learned merchant and its category. reglages, the settings: budget, month start, encrypted bank key, choices per merchant." width="100%">

Amounts are integers, in cents: a float never touches money. The domain knows neither Flutter nor the database, which makes it testable without a device.

<img src="docs/en/sections/s10.png" alt="10 Encryption" width="100%">

<img src="docs/en/schemas/chiffrement.svg" alt="The fingerprint loads the 32-byte master key from the Keystore. HKDF-SHA256 derives from it the SQLCipher database key and the one that encrypts the Enable Banking private key with AES-GCM. The backup is encrypted with AES-GCM under a key drawn from a passphrase by 210,000 rounds of PBKDF2, readable on another phone. Apart from the balance watch, every six hours, the key only enters memory after the fingerprint." width="100%">

The master key is drawn at random on first launch and never leaves the Android Keystore. Everything else derives from it: the database, and the Enable Banking private key, the most sensitive data in the app, since it opens read access to the account. That key lives encrypted twice, under its own key and inside a database that is itself encrypted, and is only decrypted for the length of a request. The RS256 signature happens in Dart, through pointycastle, and matches OpenSSL's byte for byte.

**One exception, owned up to: the balance watch.** Reading the balance with the app closed takes the bank key, and so the master key. Every six hours, it is loaded without the fingerprint, for a single read, then forgotten. Android itself never tied the key to the fingerprint, only the app did; the watch makes that limit visible instead of hiding it.

**Tout effacer** (Erase everything) destroys the key first, then the database and its side files: even if interrupted, nothing readable is left.

<img src="docs/en/sections/s11.png" alt="11 Privacy model" width="100%">

<img src="docs/en/schemas/confidentialite.png" alt="What holds: no server, the app only talks to Enable Banking; the database is encrypted and its key loaded after the fingerprint; the bank key is encrypted twice; PSD2 only grants reading and expires after 180 days; the screen is protected. What does not: Enable Banking sees the transactions go by; an open app shows everything; a backup is only as strong as its passphrase; losing the phone without a backup means losing the data; the balance watch runs without the fingerprint and shows the amount on the lock screen; the fingerprint can be turned off." width="100%">

<img src="docs/en/sections/s12.png" alt="12 Tests" width="100%">

<img src="docs/en/schemas/tests.png" alt="The tests: labels, internal transfers, recurrences, categorising and de-duplication, balance with refunds and cash, wallet, encrypted backup, RS256 signature identical to OpenSSL, overdrawn alert. The 24 tests run on an Android emulator." width="100%">

SQLCipher and the Keystore only exist on a device: the tests run on an emulator, never on the phone holding the real accounts, since they erase the database.

```
flutter test integration_test -d emulator-5554
```

<img src="docs/en/sections/s13.png" alt="13 Licence and author" width="100%">

The code is released under the [MIT](LICENSE) licence: free to read, reuse and modify, as long as the copyright notice stays. The Figtree font is under the SIL Open Font licence, the Material Symbols icons under Apache 2.0.

Designed and written by **Tristan Joncour**, a cyber-defence engineering student at ENSIBS, for personal use. The security core, fingerprint, keychain and encryption, comes from another app by the same author, [BodyCount](https://github.com/Cybertrist/BodyCount).

**What will never be in this repository:** the Enable Banking private key, the APK signing key, and any real bank data at all. `.gitignore` refuses `.pem`, `.p12`, `.jks` and `key.properties` files.

<br>

<sub>The images on this page come out of no drawing software: they are HTML pages captured by Chrome, and eight animated SVGs written by hand by <code>anime.js</code>, in French and then in English through <code>anglais.json</code>. The screenshots come from an emulator filled with demo data, cropped by <code>rogner.js</code>. It is all in <a href="docs/tools/">docs/tools</a>.</sub>

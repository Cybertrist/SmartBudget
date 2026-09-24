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

<img src="docs/en/schemas/fonctionnalites.png" alt="Twelve features. The account, on its own: the current account read over PSD2 through Enable Banking, twelve months of history then a sync at every launch. Categorised for you: 23 categories, 180 subcategories, 250 known merchants, and learned corrections. The spending ring, over one month, three months or a year. Internal transfers kept apart, outside the budget. Refunds linked to their expenses. Recurring payments found on their own. Review and tick off. Cash and wallet. Savings accounts kept by transfers. Search across every transaction. Encrypted on the phone. Encrypted backup." width="100%">

<img src="docs/en/sections/s02.png" alt="02 The screens" width="100%">

On the phone, a floating capsule at the bottom to get around.

<img src="docs/en/schemas/captures-telephone.png" alt="Eleven phone screens. Unlock: the logo, the tagline and the fingerprint. The month: the balance of every account, transactions to review, the accounts. Where the money goes: budget, savings, the top five categories, the split between essential, treat, savings and unexpected. The spending ring, whose centre opens the transactions. A category and its subcategories. Recurring payments, paid, upcoming and late. Savings, put aside and dipped into, the savings accounts. To review. Transactions day by day, with search and the cash button. A transaction, with its name, movement, category, type and repetition. Settings, with the bank, the budget, security and backup. All of them come from the demo data." width="100%">

On the Fold's unfolded screen, a rail on the left, and pages become panes side by side.

<img src="docs/en/schemas/captures-deplie.png" alt="Six screens on the Fold's unfolded screen. The month in two columns, no scrolling. The analysis, the ring on the left and the categories on the right. Tapping Housing pushes everything left, the open row stays highlighted. Then Rent, one more pane. Down to the Foncia Rent transaction, whose title carries the amount. Savings, the savings accounts on the left and the month's movements on the right." width="100%">

<img src="docs/en/schemas/palette.png" alt="Palette: green #1ED760, logo neon #50F48D, background #121212, cards #181818, savings #3CE0FF, internal transfers #8FA3B8, warning #FFC857, alert #FF6B7A." width="100%">

<img src="docs/en/sections/s03.png" alt="03 Install" width="100%">

<p align="center">
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget.apk"><img src="docs/en/telecharger.png" alt="Download Smart Budget, version 1.0.0, Android 8 or later, arm64" width="480"></a>
</p>

The APK is not on the Play Store: Android asks, once, to allow installs from the browser. Every version is signed with the same key, so it installs over the previous one without losing anything. To check the downloaded file:

```
# SHA-256 of SmartBudget.apk, version 1.0.0
d73996a9305b03bb00a4ee9235b5087cc661a458f51f4d7c411464b9c5fedfea

# SHA-256 of the signing certificate, CN=SmartBudget, O=Cybertrist
55572db26550312a39ee80315ad81ce6c31e492f0e3aebfc8e5e0f2cffabcbef
```

To build it yourself:

```
flutter build apk --release --split-per-abi
# with four months of demo data, to try it without a bank:
flutter build apk --release --split-per-abi --dart-define=ESSAIS=true
```

<img src="docs/en/sections/s04.png" alt="04 Linking the bank" width="100%">

<img src="docs/en/schemas/banque.svg" alt="Linking the bank, an exchange between four parties: Smart Budget, Enable Banking, your bank and GitHub Pages. Smart Budget sends a JWT signed with RS256 and a random state; Enable Banking opens the bank's page; you approve with Safetrans; the bank comes back to GitHub Pages with a code and the state; the page hands back through smartbudget://banque; the app checks the state, trades the code for a 180-day session and the accounts, imports twelve months, then syncs at every launch." width="100%">

Banks do not talk to individuals: you need a PSD2-licensed aggregator. [Enable Banking](https://enablebanking.com) offers one, free in restricted mode, meaning limited to the accounts you linked yourself on its portal. Bridge, Bankin's API, is for businesses only, and GoCardless has closed sign-ups.

1. On the Enable Banking portal, create a production application in restricted mode, with `https://cybertrist.github.io/SmartBudget/` as the redirect URL, then link your bank account to it. The app is built around Crédit Mutuel de Bretagne, whose labels it knows how to read.
2. Download the private key: a `.pem` file named after the application ID. Never rename it.
3. In the app, Réglages (Settings), **Importer la clé** (Import the key), pick the file. It is encrypted at once and the copy is erased.
4. **Relier le compte** (Link the account): the bank's page opens, you approve with Safetrans, and the app takes over again.

Access expires after 180 days, by law: the bank card warns fifteen days ahead, and one tap renews it. PSD2 only shares the current account, which the bank calls "CARTE BANCAIRE": savings accounts are entered by hand, then follow the transfers the app spots.

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

<img src="docs/en/schemas/stack.png" alt="Flutter 3 for the whole app. sqflite_sqlcipher for encrypted SQLite, schema version 5. flutter_secure_storage for the master key in the Keystore. cryptography for HKDF, AES-GCM and PBKDF2. local_auth for the fingerprint. flutter_riverpod for state. go_router for navigation and the lock guard. java.security for the RS256 signature of bank requests. intl for dates and amounts." width="100%">

<img src="docs/en/sections/s09.png" alt="09 Architecture" width="100%">

<img src="docs/en/schemas/couches.png" alt="Six layers. ecrans, the screens: read providers only, no SQL. providers: a write reloads everything. domaine, the domain: pure Dart, reading a label, spotting a transfer, categorising, detecting recurrences, tallying up. donnees, the data: the only place SQL is written. banque, the bank: Enable Banking, the key decrypted for one call. security: the keychain and the lock." width="100%">

<img src="docs/en/schemas/modele.png" alt="Six tables. operations: label, amount in cents, category, source, internal direction, unique bank ID, name and note, ticked off and cash, month it counts in. categories: name, icon, colour, parent, kind, nature. comptes, the accounts: current, savings or wallet, balance, pattern. liens, the links: the refunding income, the refunded expense, the share. regles, the rules: the learned merchant and its category. reglages, the settings: budget, month start, encrypted bank key, choices per merchant." width="100%">

Amounts are integers, in cents: a float never touches money. The domain knows neither Flutter nor the database, which makes it testable without a device.

<img src="docs/en/sections/s10.png" alt="10 Encryption" width="100%">

<img src="docs/en/schemas/chiffrement.svg" alt="The fingerprint loads the 32-byte master key from the Keystore. HKDF-SHA256 derives from it the SQLCipher database key and the one that encrypts the Enable Banking private key with AES-GCM. The backup is encrypted with AES-GCM under a key drawn from a passphrase by 210,000 rounds of PBKDF2, readable on another phone." width="100%">

The master key is drawn at random on first launch and never leaves the Android Keystore. Everything else derives from it: the database, and the Enable Banking private key, the most sensitive data in the app, since it opens read access to the account. That key lives encrypted twice, under its own key and inside a database that is itself encrypted, and is only decrypted for the length of a request. The RS256 signature happens on the native side, through `java.security`.

**Tout effacer** (Erase everything) destroys the key first, then the database and its side files: even if interrupted, nothing readable is left.

<img src="docs/en/sections/s11.png" alt="11 Privacy model" width="100%">

<img src="docs/en/schemas/confidentialite.png" alt="What holds: no server, the app only talks to Enable Banking; the database is encrypted and its key loaded after the fingerprint; the bank key is encrypted twice; PSD2 only grants reading and expires after 180 days; the screen is protected. What does not: Enable Banking sees the transactions go by; an open app shows everything; a backup is only as strong as its passphrase; losing the phone without a backup means losing the data; the fingerprint can be turned off." width="100%">

<img src="docs/en/sections/s12.png" alt="12 Tests" width="100%">

<img src="docs/en/schemas/tests.png" alt="The tests: labels, internal transfers, recurrences, categorising and de-duplication, balance with refunds and cash, wallet, encrypted backup, RS256 signature identical to OpenSSL. The 22 tests run on an Android emulator." width="100%">

SQLCipher and the Keystore only exist on a device: the tests run on an emulator, never on the phone holding the real accounts, since they erase the database.

```
flutter test integration_test -d emulator-5554
```

<img src="docs/en/sections/s13.png" alt="13 Licence and author" width="100%">

The code is released under the [MIT](LICENSE) licence: free to read, reuse and modify, as long as the copyright notice stays. The Figtree font is under the SIL Open Font licence, the Material Symbols icons under Apache 2.0.

Designed and written by **Tristan Joncour**, a cyber-defence engineering student at ENSIBS, for personal use. The security core, fingerprint, keychain and encryption, comes from another app by the same author, [BodyCount](https://github.com/Cybertrist/BodyCount).

**What will never be in this repository:** the Enable Banking private key, the APK signing key, and any real bank data at all. `.gitignore` refuses `.pem`, `.p12`, `.jks` and `key.properties` files.

<br>

<sub>The images on this page come out of no drawing software: they are HTML pages captured by Chrome, and five animated SVGs written by hand by <code>anime.js</code>, in French and then in English through <code>anglais.json</code>. The screenshots come from an emulator filled with demo data, cropped by <code>rogner.js</code>. It is all in <a href="docs/tools/">docs/tools</a>.</sub>

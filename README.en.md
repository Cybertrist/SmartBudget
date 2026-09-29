<div align="center">

<p>
  <a href="README.md"><img src="docs/langues/fr-off.png" alt="Français" width="150" /></a>
  <img src="docs/langues/en-on.png" alt="English" width="150" />
</p>

<img src="docs/en/banniere.png" alt="Smart Budget: your money, your plans, your future. Stay in control, enjoy the essentials. Flutter, Enable Banking, SQLCipher, AES-GCM, Fold." width="100%">

<br>

**An Android budgeting app, made for one person and one account: their own.**

</div>

It reads the current account over PSD2, files every transaction under its category, sets aside what is neither spending nor income, and shows where the money goes, month after month. Everything stays on the phone, encrypted: no server, no account to create, no advertising.

It came from a simple wish: stop spending without looking, and stop dipping into savings. The model is Bankin; the style is Spotify's, plain and dark, with a single green. The app itself is in French; this page is its English description, and button names are given as they appear on screen, with their meaning in brackets.

<img src="docs/en/sections/s00.png" alt="00 Contents" width="100%">

<p align="center">
<a href="#fonctionnalites"><img src="docs/en/sommaire/01.png" alt="01 Features" width="31%"></a>
<a href="#ecrans"><img src="docs/en/sommaire/02.png" alt="02 The screens" width="31%"></a>
<a href="#installer"><img src="docs/en/sommaire/03.png" alt="03 Install" width="31%"></a>
<br>
<a href="#relier"><img src="docs/en/sommaire/04.png" alt="04 Linking the bank" width="31%"></a>
<a href="#quotidien"><img src="docs/en/sommaire/05.png" alt="05 Day to day" width="31%"></a>
<a href="#lecture"><img src="docs/en/sommaire/06.png" alt="06 Reading a transaction" width="31%"></a>
<br>
<a href="#mouvements"><img src="docs/en/sommaire/07.png" alt="07 Transfers and savings" width="31%"></a>
<a href="#alerte"><img src="docs/en/sommaire/08.png" alt="08 The alert" width="31%"></a>
<a href="#deplie"><img src="docs/en/sommaire/09.png" alt="09 The unfolded screen" width="31%"></a>
<br>
<a href="#chiffrement"><img src="docs/en/sommaire/10.png" alt="10 Encryption" width="31%"></a>
<a href="#confidentialite"><img src="docs/en/sommaire/11.png" alt="11 Privacy" width="31%"></a>
<a href="#architecture"><img src="docs/en/sommaire/12.png" alt="12 Architecture" width="31%"></a>
<br>
<a href="#tests"><img src="docs/en/sommaire/13.png" alt="13 Tests" width="31%"></a>
<a href="#versions"><img src="docs/en/sommaire/14.png" alt="14 Versions" width="31%"></a>
<a href="#licence"><img src="docs/en/sommaire/15.png" alt="15 Licence" width="31%"></a>
</p>

<a id="fonctionnalites"></a>
<img src="docs/en/sections/s01.png" alt="01 Features" width="100%">

<img src="docs/en/schemas/fonctionnalites.png" alt="Twelve features. The account, on its own: the current account read over PSD2 through Enable Banking, twelve months of history, a sync at every launch, and an alert if the account goes overdrawn. Categorised for you: 23 categories, 180 subcategories, over 200 known merchants, and learned corrections. The spending ring, over the month opened by the salary, three months or a year. Internal transfers kept apart, outside the budget. Refunds linked to their expenses. Recurring payments found on their own. Review and tick off. Cash and wallet. Savings accounts kept by transfers. Search across every transaction. Encrypted on the phone. Encrypted backup." width="100%">

<a id="ecrans"></a>
<img src="docs/en/sections/s02.png" alt="02 The screens" width="100%">

On the phone, a floating capsule at the bottom to get around. Every screenshot comes from the demo data.

<img src="docs/en/schemas/captures-telephone.png" alt="Eleven phone screens. Unlock: the logo, the tagline and the fingerprint. The month: the balance of every account, transactions to review, the accounts. Where the money goes: budget, savings, the top five categories, the split between essential, treat, savings and unexpected. The spending ring, whose centre opens the transactions. A category and its subcategories. Recurring payments, paid, upcoming and late. Savings, put aside and dipped into, the savings accounts. To review. Transactions day by day, with search and the cash button. A transaction, with its name, movement, category, type and repetition. Settings, with the bank, the budget, security and backup. All of them come from the demo data." width="100%">

On the Fold's unfolded screen, a rail on the left, and pages become panes side by side.

<img src="docs/en/schemas/captures-deplie.png" alt="Six screens on the Fold's unfolded screen. The month in two columns, no scrolling. The analysis, the ring on the left and the categories on the right. Tapping Housing pushes everything left, the open row stays highlighted. Then Rent, one more pane. Down to the Foncia Rent transaction, whose title carries the amount. Savings, the savings accounts on the left and the month's movements on the right." width="100%">

<img src="docs/en/schemas/palette.png" alt="Palette: green #1ED760, logo neon #50F48D, background #121212, cards #181818, savings #3CE0FF, internal transfers #8FA3B8, warning #FFC857, alert #FF6B7A." width="100%">

<a id="installer"></a>
<img src="docs/en/sections/s03.png" alt="03 Install" width="100%">

<p align="center">
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget.apk"><img src="docs/en/telecharger.png" alt="Download Smart Budget, the full version, Android 8 or later" width="400"></a>
<a href="https://github.com/Cybertrist/SmartBudget/releases/latest/download/SmartBudget-demo.apk"><img src="docs/en/telecharger-demo.png" alt="Try the Smart Budget demo, no bank, Android 8 or later" width="400"></a>
</p>

Two apps, which install side by side without getting in each other's way.

- **SmartBudget**, the full version: it links to your bank and holds only your real transactions.
- **SmartBudget démo**: four months of made-up transactions, already loaded when it opens, no bank, no fingerprint, and screenshots allowed. To see every screen before linking anything.

The APKs are not on the Play Store: Android asks, once, to allow installs from the browser. Every version is signed with the same key: it installs over the previous one without losing anything.

<details>
<summary><b>Check the downloaded file, or build it yourself</b></summary>

```
# SHA-256 of SmartBudget.apk, version 1.2.6
0b8ba947f2d5a8d697713ee7b3f50cd0497112cc34e05d5f87a1f0b0a4cbb850

# SHA-256 of SmartBudget-demo.apk, version 1.2.6
67a1c7100131d4d9ec81fad7ba9594c92c1c26a093e4c7230cf6cdd23562ad5a

# SHA-256 of the signing certificate, CN=SmartBudget, O=Cybertrist
55572db26550312a39ee80315ad81ce6c31e492f0e3aebfc8e5e0f2cffabcbef
```

```
flutter build apk --release --split-per-abi
# the demo, with its own identifier and the demo data already loaded:
flutter build apk --release --split-per-abi --dart-define=DEMO=true
```

</details>

<a id="relier"></a>
<img src="docs/en/sections/s04.png" alt="04 Linking the bank" width="100%">

Banks do not talk to individuals: you need a PSD2-licensed aggregator. [Enable Banking](https://enablebanking.com) offers one, free in restricted mode, meaning limited to the accounts you linked yourself on its portal.

**You need** SmartBudget installed, an email address you can open on the phone, and whatever you use to sign in to your online banking. It takes about ten minutes, once: after that, access lasts 180 days.

<img src="docs/en/schemas/parcours-banque.svg" alt="Choosing and linking your bank, in five steps, on an animated phone. 1, in Settings, the Your bank card, tap Choose the bank. 2, find yours by name or country, here mutuel bretagne, then tap Crédit Mutuel de Bretagne. 3, the Get your key page: Open the portal opens the Enable Banking site in the browser, and every value to paste has its own Copy button. 4, Import the key: pick the .pem file in Downloads, without renaming it; it is encrypted at once and the copy deleted. 5, the bank’s page opens, you confirm as usual, then the card shows Synced, access for 180 more days, and the transactions arrive." width="100%">

### 1. Choose the bank

**Réglages** (Settings) tab, **Ta banque** (Your bank) card, **Choisir la banque** (Choose the bank) button. The list holds every bank Enable Banking can read for individuals, in some thirty European countries: the major banks of the phone's country first, then all the others from A to Z.

### 2. Find yours

Type part of the name (`mutuel bretagne`) or a country (`belgique`), then tap your bank. Each bank fits on one row, with its country and its mobile app's icon, bundled with SmartBudget: no image is loaded from the Internet. The **Obtenir ta clé** (Get your key) page opens straight away.

### 3. Get your key on the Enable Banking portal

This is the only step outside the app. The **Obtenir ta clé** page lists the instructions in order, and every value to paste has its own **Copier** (Copy) button: you just go back and forth between SmartBudget and the browser.

<img src="docs/en/schemas/portail.svg" alt="On the Enable Banking portal. Sign in: type your email, Continue, then open the link you receive. Create the application, Add a new application: Environment Production, Private key Generate in the browser, Application name SmartBudget, then paste the values copied from SmartBudget: Allowed redirect URLs https://cybertrist.github.io/SmartBudget/, the description, Privacy URL and Terms URL; Email for data protection, your email. Register: a .pem file downloads, this is the key, never rename it. Then Activate by linking accounts: country, your bank, type personal, Link, and you confirm at your bank. The application is active, in free restricted mode." width="100%">

1. **Sign in.** Tap **Ouvrir le portail** (Open the portal), type your email, **Continue**, then open the link you receive. The Enable Banking account creates itself the first time.
2. **Create the application.** In **API applications**, fill in **Add a new application**:
   - **Environment**: `Production`
   - **Private key**: leave `Generate in the browser`
   - **Application name**: `SmartBudget`
   - **Allowed redirect URLs**: `https://cybertrist.github.io/SmartBudget/` (Copy button)
   - **Application description**: the suggested sentence (Copy button)
   - **Email for data protection**: your own email address
   - **Privacy URL** and **Terms URL**: `https://github.com/Cybertrist/SmartBudget` (Copy buttons)
3. **Register.** The portal downloads a `.pem` file: the application's private key. **Never rename it**: its name is the application ID.
4. **Link your account on the portal.** On the application's page, **Activate by linking accounts**, choose the country, your bank and the `personal` type, then **Link**, and confirm on the bank's page as usual.

### 4. Import the key

Back in SmartBudget, at the bottom of the **Obtenir ta clé** page: **Importer la clé** (Import the key), and pick the `.pem` file in Downloads. It is encrypted on the phone at once (AES-GCM, with a key derived from the Keystore), and its working copy deleted.

### 5. Link the account

The bank's page opens one last time, you confirm, and SmartBudget takes over. The **Ta banque** card shows **Synchronisé** (Synced), with the days of access left, and the last twelve months arrive. After that, there is nothing left to do.

Access expires after 180 days, by law: with less than fifteen days left, the bank card turns yellow, and once access has expired, **Relier le compte** (link the account) renews it, with the same key. PSD2 only shares the current account, which the bank calls "CARTE BANCAIRE": savings accounts are entered by hand, then follow the transfers the app spots. The app was written and tested with Crédit Mutuel de Bretagne; elsewhere, categorisation works the same way, but transfers to savings accounts may need marking by hand the first time.

<details>
<summary><b>If something goes wrong</b></summary>

- **"Le nom du fichier ne contient pas l'identifiant de l'application"** (the file name does not contain the application ID): the `.pem` file was renamed, for instance to `cle.pem`. Download it again from the application's page, without touching its name.
- **"Ce fichier n'est pas une clé privée"** (this file is not a private key): the chosen file is not the portal's `.pem`. Pick the one downloaded in step 3.
- **"Enable Banking refuse la clé"** (Enable Banking rejects the key): the imported key does not match the application, or the application is not in `Production`. Redo step 3, then import the new key (the card's **Nouvelle clé**, New key, button).
- **"Pas de connexion à Internet."** (no Internet connection): the sync resumes on its own the next time the app opens with a network.
- **"Trop de synchronisations aujourd'hui"** (too many syncs today): the bank limits the number of accesses per day. Just wait until tomorrow.
- **"L'accès a expiré : reconnecte le compte."** (access expired, reconnect the account): the 180 days are up. Tap **Relier le compte** (Link the account) and confirm at the bank: the key stays the same.
- **Your bank is not in the list**: Enable Banking cannot read it yet, or not for individuals.

</details>

<details>
<summary><b>What happens behind the scenes</b></summary>

<img src="docs/en/schemas/banque.svg" alt="Linking the bank, an exchange between four parties: Smart Budget, Enable Banking, your bank and GitHub Pages. Smart Budget sends Enable Banking a JWT signed with RS256 and a random state; Enable Banking opens the bank’s page; you approve with Safetrans; the bank comes back to GitHub Pages with a code and the state; the page hands back to the app through smartbudget://banque; the app checks the state matches the one it sent, trades the code for a 180-day session and the accounts, then imports twelve months and syncs at every launch." width="100%">

Every request to Enable Banking carries a token signed with RS256 by the imported key, decrypted only for the length of the call. The bank's redirect goes through a GitHub Pages page (`docs/index.html`), which hands back to the app through the `smartbudget://banque` link; the state token, drawn at random at the start and checked on return, stops a link forged elsewhere from linking another account.

</details>

<a id="quotidien"></a>
<img src="docs/en/sections/s05.png" alt="05 Day to day" width="100%">

SmartBudget syncs **every time it opens**, and every time you come back to it as soon as the last sync is more than ten minutes old. There is nothing else to do but look.

<img src="docs/en/schemas/synchro.svg" alt="The sync when the app opens. The phone opens with the fingerprint, the home screen shows Syncing…, and the app asks the bank for the transactions since 18 September, the last sync minus seven days. Five transactions come back. CB LE FOURNIL, 3.80 euros, has an identifier already known: it is skipped, nothing counts twice. CB CARREFOUR MARKET, 54.20 euros, now booked, replaces the pending transaction from the same merchant for the same amount, within a week, and keeps what had been done by hand: the name Weekly groceries, the Groceries category and the note shared with Léa. PRLV SEPA FREE MOBILE, 19.99 euros, is new and filed under Subscriptions, Mobile plan. VIR VERS LIVRET A DE CARTE BANCAIRE, 100 euros, is an internal transfer, outside the budget, and the Livret A goes from 2,960 to 3,060 euros. CB SNCF CONNECT, 45 euros, arrives pending, filed under Transport. Then the balance is read again and compared with zero. The counter only counts the truly new ones: three, and the home screen shows 3 new transactions and Updated 26 Sept. It runs when the app opens and each time you come back if the last sync is over ten minutes old; the first time it imports twelve months; access lasts 180 days and the bank card in settings warns fifteen days ahead." width="100%">

Each sync asks again for the transactions since the last one, minus seven days, to catch those the bank books late. A transaction already known by its bank identifier is skipped: running it again doubles nothing. A **En attente** (pending) transaction, like today's card payment, shows up at once; once booked, it is updated in place and keeps what you did to it by hand (name, category, note, month) and its refund links.

<img src="docs/en/schemas/accueil.svg" alt="The home screen, the current month at a glance, on an animated phone. Eleven September transactions go in one by one, with a budget of 1,500 euros. Foncia Rent, 620 euros, and Carrefour Market, 182.40 euros, count. A 200 euro transfer to the Livret A is outside the budget: it only counts in savings, and the account goes up to 3,060 euros. Le Comptoir, 86.50 euros, and SNCF Connect, 145 euros, count. Norauto, 380 euros, marked unexpected by hand, turns the gauge yellow, past 90 %. Pharmacie du Port, 30 euros, then a 23.50 euro refund from the CPAM linked to it: it is not income, it lightens the pharmacy, which now weighs only 6.50 euros. Leboncoin, 250 euros, is hidden: nothing moves. Zalando, 89.99 euros, takes the budget over: the card turns red and shows 10.39 euros over budget. Spotify, 11.12 euros, counts but stays out of the top five categories. At the end: 1,521.51 euros spent, 21.51 euros over budget; the top five categories are Housing, Transport, Groceries, Shopping, Restaurants and outings; the breakdown gives Essential 953.90 euros, Treat 187.61 euros, Savings 200 euros and Unexpected 380 euros." width="100%">

The home screen always shows the current month. The budget is what is left once spending is taken out: green, yellow from 90%, red beyond, where it shows the overrun. Then come the five heaviest categories, and the split between essential, treat, savings and unexpected. A transfer to a savings account only counts as savings, a linked refund lightens the expense it pays back, and a hidden transaction appears nowhere.

<img src="docs/en/schemas/analyse.svg" alt="The Analysis screen, on an animated phone, in six gestures. 1, choose the month: the left arrow goes from September back to August 2026, where spending rises to €1,412.36, then the right arrow returns to September and stops at the current month; the 1 month, 3 months and 1 year chips choose the period, which ends at the month shown: €4,118.63 over three months. 2, the tabs: Spending, €1,349.91; Income, €1,309.40, mostly the salary; Recurrences, €630.86 paid of €633.16 expected, with what is upcoming and what is paid. 3, the ring carries one icon per category, and its centre opens the month’s spending, day by day, with search and the Cash button. 4, further down, the list of categories: tapping Housing opens its total, -€556.77, 41% of the month’s spending, and its subcategories, Rent and Electricity, then as chips the ones with nothing this month. 5, tapping Rent opens its transactions day by day. 6, tapping Foncia Rent opens the transaction: name, movement, category Housing › Rent, type Essential, and Counts in September. At the bottom, the path Analysis, Housing, Rent, Foncia Rent is written as the pages open. Coming back, the analysis keeps the month, the period and the tab." width="100%">

The analysis starts from a month and goes down to the transaction. The arrows change the month, the chips pick one month, three or a year, and the tabs switch between spending, income and recurrences. The centre of the ring opens the transactions it counts; a category opens its subcategories, a subcategory its transactions, day by day. Coming back, the month, the period and the tab stay as chosen.

<a id="lecture"></a>
<img src="docs/en/sections/s06.png" alt="06 How a transaction is read" width="100%">

<img src="docs/en/schemas/classement.svg" alt="How a transaction is read. The label PAIEMENT PAR CARTE X4057 CARREFOUR MARKET VANNES 12/09 loses its noise: the prefix, the masked card and the date are struck out, leaving the merchant key CARREFOUR MARKET VANNES. Four questions follow one another: internal transfer, no; learned rule, no; dictionary, yes; uncategorised is not reached. Result: Groceries, Supermarket, essential. Correcting a category writes a rule, followed by the next transactions from the same merchant." width="100%">

A bank label is written for the bank. The merchant is pulled out of it by removing prefixes, the masked card, dates, references and copied amounts; its key, its first three words without company suffixes, stays the same from one month to the next. That key carries corrections, chosen names and repetitions: renaming "Spotify P2f9 Stockholm" to "Spotify" renames all its transactions, the upcoming ones included.

<img src="docs/en/schemas/apprentissage.svg" alt="To review, and the learnt correction, on an animated phone. The home screen shows 4 transactions to review. The To review list holds those nothing recognised, each with Categorise and Internal, and Keep for money received. Sumup Atelier Kernevel of 8 September is put in Leisure, Hobbies: the correction becomes a rule tied to the merchant key, SUMUP ATELIER KERNEVEL, taken from the label PAIEMENT PAR CARTE X0000 SUMUP *ATELIER KERNEVEL 07/09. The transaction is sorted by hand and ticked off; the one of 12 August, from the same merchant and not sorted by hand, follows the rule, and both leave the list. Then the 25 euro refund received is kept, and leaves the list too. On the transaction page, renaming it Atelier Kernevel renames every transaction of the merchant, past and future. At the next sync, the transaction of 7 October arrives already in Hobbies through the learnt rule, already named Atelier Kernevel, without going through To review. A transaction sorted by hand is never touched by a rule again." width="100%">

What nothing recognises waits in **À vérifier** (to review), flagged on the home screen. Categorising a transaction writes a rule on the merchant key: its other transactions not sorted by hand follow at once, and the next ones arrive already sorted. A cheque, a cheque deposit or a withdrawal has no merchant: categorising one only applies to it. Categorising or keeping ticks the transaction off, with a green tick.

<img src="docs/en/schemas/recurrences.svg" alt="Recurring payments, worked out from the transactions with nothing to enter. Over four months, merchant by merchant, the reading sweeps up to 20 September and measures the gap between two payments. Foncia Loyer, 520 euros on the 5th of every month, and EDF, 36.40 to 41.20 euros on the 8th, come back every 30 or 31 days: Every month, already paid this month. Basic Fit, 29.99 euros, due on 10 September, has not gone through: late. Netflix, 14.99 euros, and Vinted, two purchases a month apart, are upcoming. Carrefour Market has no rhythm. The climbing club, debited 50 days apart, is not seen. Every gap must fall inside a window: 6 to 8 days for every week, 25 to 35 for every month, 85 to 95 for every quarter, 350 to 380 for every year; it takes at least two payments and an amount within 15% of its median, which becomes the expected amount. On the phone, the Recurrences tab of the analysis shows late, upcoming and paid, and 558.90 euros paid of 622.38 expected. On the Vinted purchase page, the Repetition line goes from Every month to None: this merchant does not come back, it leaves the list. On the climbing club one, it goes from None to Every month: it shows up as upcoming, in 1 day. The choice counts for every transaction of the merchant and comes before detection." width="100%">

Recurring payments are worked out on their own: at least two payments from one merchant, an amount within 15%, and every gap inside a window (a week, a month, a quarter, a year). The next date follows, and the analysis files them as late (four days of grace), upcoming or paid. A transaction's **Répétition** (repetition) line overrides detection for the whole merchant: "Aucune" (none) if it does not come back, a frequency if it comes back with no rhythm.

<a id="mouvements"></a>
<img src="docs/en/sections/s07.png" alt="07 Transfers, refunds, savings" width="100%">

<img src="docs/en/schemas/mouvements.svg" alt="Three traps in a statement, and how the app gets out of them. A transfer to the Livret A savings account, read in VIR VERS LIVRET A DE CARTE BANCAIRE: the money moves from the current account to savings, it is outside the budget, counted as 200 euros put aside, and the budget is unchanged. A 500 euro cheque that refunds: 300 euros go to the 380 euro train ticket, leaving 80, and 200 to the 260 euro restaurant, leaving 60; the cheque does not count as income. Cash: a 50 euro withdrawal, then 12 euros at the market; withdrawals drop to 38, groceries rise to 12, the wallet goes from 50 to 38 euros, and the month’s spending stays at 50 euros, not 62." width="100%">

An honest budget never counts the same money twice.

- **A transfer between your own accounts** is neither spending nor income. At Crédit Mutuel de Bretagne it reads `VIR VERS <destination> DE <source>`: the direction is in the label. It leaves the budget, hatched, and feeds "put aside" or "dipped into". If detection gets it wrong, the **Mouvement** (movement) row of a transaction fixes it.
- **A refund** is linked to the expenses it pays back. They then only count for what is left to pay, and the refund does not count as income.
- **A cash expense** is entered by hand. It draws on the oldest withdrawal before it, up to two months back: taking out €50 in September then paying €20 at the market in October counts €30 of withdrawal in September and €20 of groceries in October, never 70. The **wallet**, if opened, tracks what is left in your pocket.

<img src="docs/en/schemas/remboursement.svg" alt="Linking a refund, both ways, on an animated phone. A, from the expense: on the concert’s page, 90 euros on 20 September, the Refund line says None; tapping it opens Link to a refund, which offers money received up to two months before or after the purchase. You tick Camille Roux’s transfer, 30 euros received on 14 September, then Hugo Lefèvre’s, 30 euros received on 23 September; the cheque deposit, already fully assigned elsewhere, stays greyed out. At the bottom, the summary goes from 90 euros left to 2 selected, 60 euros, 30 euros left. Confirm 2 refunds: the page shows 60 euros received (2), the expense now only counts for 30 euros, and Camille and Hugo’s 60 euros no longer count as income. B, from the income: on the page of Lucas Martin’s 500 euro transfer of 18 September, the Pays back card offers Link expenses. The screen lists expenses from two months before to one month after the income; ticking the 380 euro train ticket offers 380 euros, corrected to 300, then ticking the 260 euro restaurant offers the 200 left, and the Split gauge reaches 500 out of 500. Link 2 expenses: the ticket now only counts for 80 euros, the restaurant for 60, both in August, and Lucas’s 500 euros are not September income. One income can pay back several expenses and one expense can be paid back by several incomes, never beyond either." width="100%">

The refund can arrive before the purchase or after it. From the expense, its **Remboursement** (refund) line opens **Associer à un remboursement** (link to a refund), which offers money received up to two months before or after, with what is left of it. From the income, **Lier des dépenses** (link expenses) splits it over several expenses, and the **Réparti** (split) gauge never goes past the amount received. An expense can be paid back by several incomes, never beyond its amount. Each transaction stays in its month: an August purchase paid back in September corrects August.

<img src="docs/en/schemas/epargne.svg" alt="Savings and savings accounts, on an animated phone. Over PSD2 the bank only shares the current account: savings accounts do not go through it and are entered by hand. On the Savings screen, where only the 1,800 euro LDDS exists, tapping Add opens New savings account: the current balance, 3,200 euros, the Livret A type, the name, and the word that names it on the statement, then Add the account. From then on, each transfer read on the current account keeps its balance alive. VIR VERS LIVRET A DE CARTE BANCAIRE, 200 euros, goes to the Livret A from the current account: put aside, the account rises to 3,400 euros. VIR VERS CARTE BANCAIRE DE LIVRET A, 100 euros, comes back to the current account: dipped into, the account drops to 3,300 euros. A 64.30 euro payment at Carrefour Market, on the other hand, is an expense. The month’s budget only counts those 64.30 euros of spending and no income: internal transfers stay outside the budget. The Savings screen shows 5,100 euros in total, plus 100 euros this month, 200 euros put aside, 100 euros dipped into, the Livret A at 65 percent of savings and the two movements spotted. Only transfers after the balance was entered move it, and tapping an account corrects its balance." width="100%">

Each savings account is added once, in **Épargne** (savings), **Mes livrets** (my savings), **Ajouter** (add): its current balance, its type, and the word that names it on the statement. From then on, each transfer to or from it, spotted on the current account, moves its balance, as long as it comes after the balance was entered and is no longer pending. Tapping an account corrects its balance, as the bank shows it.

<img src="docs/en/schemas/mois.svg" alt="The budget month, on a timeline from 20 November 2025 to 31 January 2026 and an animated phone. Eleven transactions: a €1,850 salary on 25 November, groceries, the €520 rent on 5 December, groceries, a salary paid early for Christmas on 19 December, gifts on 23 December, groceries, the rent on 5 January, a €250 bonus filed under Salary on 9 January, groceries, and the salary of 27 January. 1, in settings, Month start reads Salary, around the 25th: the usual payday, found on its own, is only a guide. On a fixed day, December would run from 25 November to 24 December, with two salaries, €3,700 of income, and January would only have the bonus, for a balance of -€393.70. 2, each salary opens its month on the day it arrives: the one of 19 December opens January that day, and its page reads Counts in January. December runs from 25 November to 18 December, €1,850 of income for €678.70 of spending; January from 19 December to 26 January, €2,100 of income for €808.60 of spending; the salary of 27 January opens February. 3, only a real salary opens a month: filed under Salary, at least half the usual salary, within ten days of the usual payday. The €250 bonus of 9 January opens nothing." width="100%">

**The budget month** opens with the salary: each salary opens its month on the day it arrives, even when paid early. The salary of 19 December, paid early for Christmas, opens January that day, and December never counts two salaries. In the settings, *Début du mois* (month start) shows the usual payday, for instance “Salaire, vers le 25” (salary, around the 25th): SmartBudget finds it on its own, the middle day of your salaries over the last six months, and it only serves months whose salary has not arrived yet. You can also pick it by hand, from the 1st to the 28th.

Only a real salary opens a month: filed under Salary, at least half the usual salary, and within ten days of the usual payday. A bonus or a refund opens nothing, and two salaries for the same month open it only once. If a transaction still lands on the wrong side, rent paid for the next month for instance, the transaction's **Compte en** (counts in) row attaches it to the month before or after.

<a id="alerte"></a>
<img src="docs/en/sections/s08.png" alt="08 The overdraft alert" width="100%">

SmartBudget sends only one notification: **"Compte courant en négatif"** (current account overdrawn), with the amount, when the account has just gone below zero. No budget reminder, no weekly summary, no advertising: nothing else ever rings.

<img src="docs/en/schemas/alerte.svg" alt="The balance watch. Every six hours, even with the app closed, the current account balance is read again. Over two days, eight reads: 320, 180 and 60 euros, then -42.10 euros at midnight, and the locked phone gets the notification Current account overdrawn, Your current account is at -42.10 euros. At the next two reads, -85 and -20 euros, no new alert: already told. At 150 euros, the alert re-arms. Four reads a day at most, the PSD2 limit for access made without the user." width="100%">

- **One alert per drop below zero.** As long as the account stays overdrawn, the following reads stay quiet; as soon as it recovers, the alert re-arms.
- **Every six hours, even with the app closed**, Android wakes a small background task, only when there is a network. It reads **the balance, and nothing else**, four times a day at most, the limit PSD2 grants to access made without you. Every sync inside the app runs the same comparison.
- **The amount shows on the lock screen**: on purpose, the alert must be seen without unlocking. Tapping it opens SmartBudget, behind the fingerprint.

**The price of the alert.** To read the balance, the background task needs the bank key, and so the master key: it is loaded without fingerprint, for that read only, then forgotten. This is the only exception to the "nothing opens without the fingerprint" rule, and the privacy model lists it among what is not protected.

<details>
<summary><b>Turning it on, silencing it, stopping it</b></summary>

- **Turning it on**: nothing to do. As soon as the account is linked, the watch starts, and Android 13 or later asks once for permission to send notifications. Answer **Allow**.
- **Silencing it**: Android Settings, Apps, Smart Budget, Notifications, then turn off the **"Compte en négatif"** (account overdrawn) category. The watch keeps reading the balance, but no longer rings.
- **Stopping it entirely**: **Délier** (Unlink) the bank in SmartBudget's settings. No more reads happen in the background.
- **The demo** has no bank, so no watch and no notification.

</details>

<a id="deplie"></a>
<img src="docs/en/sections/s09.png" alt="09 The unfolded screen" width="100%">

<img src="docs/en/schemas/volets.svg" alt="The unfolded screen. A tablet with its rail on the left shows two panes side by side. On the analysis, the ring on the left and spending on the right, tapping Housing pushes everything left and opens Housing on the right; then Rent; then the Foncia Rent transaction. The open row stays highlighted in the left pane. The back gesture, a green touch sliding from the right edge to the left, closes the panes one by one, back to the analysis. On the right, the list of open pages, Analysis, Housing, Rent, Foncia Rent, grows then empties." width="100%">

A phone screen stretched over eight inches no longer looks like anything. On the open Fold, pages form one wide page showing its last two panes: you go down from the analysis to a single transaction without ever losing where you came from, and Samsung's back gesture closes the last pane. Every page fits at once, without scrolling; a transaction opened on its own switches to two columns. Inputs open in a card above the keyboard, never in a sheet sliding up from the bottom.

<a id="chiffrement"></a>
<img src="docs/en/sections/s10.png" alt="10 Encryption and backup" width="100%">

<img src="docs/en/schemas/chiffrement.svg" alt="Encryption. The fingerprint loads the 32-byte master key from the Android Keystore. HKDF-SHA256 derives two keys from it: one opens the SQLCipher database, the other encrypts the Enable Banking private key with AES-GCM. Separately, the backup: a passphrase chosen at export goes through 210,000 rounds of PBKDF2 and encrypts, with AES-GCM, a .sbx file readable on another phone. Outside the balance watch, which loads it every six hours just long enough to read the balance, the key only enters memory after the fingerprint." width="100%">

The master key is drawn at random on first launch and never leaves the Android Keystore. Everything else derives from it: the database, and the Enable Banking private key, the most sensitive data in the app, since it opens read access to the account. That key lives encrypted twice, under its own key and inside a database that is itself encrypted, and is only decrypted for the length of a request. The RS256 signature is made in Dart, by pointycastle, byte for byte the same as OpenSSL's. **Tout effacer** (erase everything) destroys the key first, then the database: even if interrupted, nothing readable is left.

<img src="docs/en/schemas/sauvegarde.svg" alt="The backup, between two animated phones. On this phone, Settings, Backup, Export, encrypted: the Backup passphrase card asks for a passphrase of at least eight characters, twice, and warns that without it nobody can read the file again, not even you. The six tables, categories, accounts, transactions, rules, links and settings, go into the file with the database version, compressed then encrypted with the passphrase. The system picker saves smartbudget-2026-09-26.sbx to Downloads: Backup saved. The file travels, through Downloads, a computer or a cloud, and stays unreadable without the passphrase. On another phone where the app was just installed, Restore a backup: pick the file, confirm Replace, since everything in the app will be replaced. A wrong passphrase gives Wrong passphrase, or damaged file, and nothing is touched. The right passphrase passes the checks: the SBEX1 header and the AES-GCM MAC, a Smart Budget backup from a known version, then everything is replaced at once, in a single transaction. Backup restored: the home screen shows the same 4,125.33 euros as the old phone. The passphrase cannot be recovered: lose it and the backup is lost too." width="100%">

Settings, Backup, **Exporter, chiffré** (export, encrypted): the passphrase is typed twice, so a typo never locks the file. The file can travel anywhere: without the passphrase it is unreadable. On another phone, **Restaurer une sauvegarde** (restore a backup) replaces everything in a single transaction; a wrong passphrase touches nothing. The bank key, encrypted by the old phone's master key, cannot be read there: it is dropped, and importing it again relinks the account.

<a id="confidentialite"></a>
<img src="docs/en/sections/s11.png" alt="11 Privacy model" width="100%">

<img src="docs/en/schemas/confidentialite.svg" alt="The privacy model. In the centre, the phone; the only link leaving it goes to Enable Banking, then to the bank, read only, for 180 days of access; nothing goes to a server, a sign-up, analytics or ads. A curious eye tries every door, and they hold. No server of mine: the app only talks to Enable Banking, to read the account. The database is encrypted by SQLCipher; its key lives in the Keystore and is only loaded after the fingerprint, apart from the balance watch. The bank key is encrypted twice, with AES-GCM under a derived key, inside a database that is itself encrypted. PSD2 only grants reading: no transfer can leave the app, and access expires after 180 days. The screen is protected: screenshots blocked, recent-apps preview hidden, Android backup refused. Then, honestly, what stays open. Enable Banking sees the transactions while passing them on: it is the licensed aggregator that reads the bank. An open app shows everything: the fingerprint guards access, not your shoulder. A backup travels and is only as strong as its passphrase; without the passphrase, it is lost, for everyone. Losing the phone means losing the data that was not backed up: the key is copied nowhere. The balance watch runs without the fingerprint: every six hours, the key is loaded just long enough to read the balance, and the alert shows the amount on the lock screen. The fingerprint can be turned off in the settings; the data stays encrypted, but opens without proof." width="100%">

<a id="architecture"></a>
<img src="docs/en/sections/s12.png" alt="12 Architecture" width="100%">

<img src="docs/en/schemas/stack.svg" alt="The SmartBudget stack. Underneath, Flutter 3: the whole app, in Dart, one codebase for the phone and the unfolded screen. On top, five sockets, what the app serves, and each package stacks onto its own. The screen: flutter_riverpod for state, a write reloads everything that depends on it, in a single call; go_router for navigation and the lock guard on every page; intl for dates and amounts, French style; material_symbols_icons, five hundred icons rounded like the interface. The database: sqflite_sqlcipher, SQLite encrypted by SQLCipher, schema version 6, lossless migrations. The key: flutter_secure_storage, the master key in the Android Keystore, never on disk in the clear; cryptography, HKDF to derive keys, AES-GCM for the bank key and the backup, PBKDF2 for the passphrase; local_auth, the fingerprint, which loads the key, without it the database stays unreadable. The bank: pointycastle, the RS256 signature of requests, in Dart, byte for byte the one OpenSSL makes. The watch: workmanager, the balance watch every six hours, even with the app closed; flutter_local_notifications, the one notification, the current account gone overdrawn. Two paths run through them. On opening, the fingerprint loads the key, the key opens the database, the screen fills up. Every six hours, the watch loads the key, signs its request, reads the balance at the bank, and warns if it goes overdrawn." width="100%">

<img src="docs/en/schemas/couches.svg" alt="The six layers of SmartBudget, crossed by one write, step by step. ecrans: read providers, write through repositories, never SQL; on the unfolded screen, pages become panes. providers: Riverpod, a write bumps a version number and everything that reads the database reloads, in a single call. domaine: pure Dart, tested without a device, which reads a label, spots an internal transfer, categorises, detects recurrences and tallies up. donnees: the only place SQL is written, with the repositories, the schema and its migrations, backup and demo data. security: the keychain, master key in the Keystore, HKDF derivations, the lock; nothing reads a file by going around it. smartbudget.db: SQLite encrypted by SQLCipher, schema version 6. banque: Enable Banking, signed JWT, session, transactions, balance; the private key is decrypted only for the length of one call; it is off this path. On the phone, the Associer à un remboursement (link a refund) screen of the 90 euro concert: Camille Roux’s transfer is ticked for 45 euros, the cheque deposit, already fully assigned elsewhere, stays greyed out; the summary says 1 selected, 45 euros, 45 euros left. In green, the write going down: 1, tap Confirm 1 refund; 2, ecrans calls DepotLiens().rembourserPar() in donnees, without going through providers or domaine, greyed out; 3, donnees gets the database key from security; 4, inside a transaction, the concert’s links are replaced in smartbudget.db: DELETE, then INSERT INTO liens. In blue, the reload coming back up: 5, ecrans calls rafraichir(ref), and the providers version goes up one notch; 6, providers reloads through DepotBilan.du, which runs a SELECT on smartbudget.db; 7, donnees hands the month to calculerBilan() in domaine; 8, providers returns the new value to ecrans, and the concert’s page redraws: 45 euros received (1). A screen never writes SQL, and nothing opens the database without going through the keychain." width="100%">

<img src="docs/en/schemas/modele.svg" alt="The SmartBudget data model: six tables in a database encrypted by SQLCipher, schema version 6. operations, 18 columns: id; compte_id, to comptes; uid_banque, unique, so nothing doubles; le, the day of the transaction; libelle, as the bank writes it; montant_centimes, an integer, never a float; categorie_id, to categories; origine, by hand, rule, dictionary, internal or default; nature, empty to follow its category’s; mois_compte, to count it in another month; nom and note, chosen by hand; masquee, left out of analysis; recurrente, empty when detection decides; interne, to savings, from savings or between accounts; pointee and especes, checked and paid in cash; en_attente, not booked yet. categories, 10 columns: id; parent_id, for a subcategory; nom, icone and couleur, what shows; genre, expense, income, savings or internal; nature, essential, treat or unexpected; budget_centimes, its budget if it has one; ordre, its place in the list. comptes, 9 columns: id; nature, current, savings or wallet; nom and iban_fin; uid_banque, the account at the bank; solde_centimes, at the last statement, and solde_le, its date; motif, its name in transfers; cree_le. liens: entree_id, the refund; depense_id, the refunded expense; montant_centimes, its share. regles: id; motif, the learned merchant, unique; categorie_id, where it goes from now on. reglages: cle and valeur, for the budget, the savings goal, debut_mois, the usual payday, only a reference point, and debut_mois_auto, whether it was found automatically, the banque_ keys for the encrypted key, the bank and the end of access, the per-merchant choices under repetition: and nom:, and alerte_negatif. The foreign keys are drawn: operations.compte_id to comptes, operations.categorie_id to categories, categories.parent_id to categories, liens.entree_id and liens.depense_id to operations, regles.categorie_id to categories. Then a sample transaction fills column by column: id 1287, account 1, the current account, 20 September 2026, CB FNAC SPECTACLES 19/09, -9000 cents, category 164, Cinema and concerts under Leisure, categorised by the dictionary, named Concert; its refund adds to liens the row 1262, Camille Roux, to 1287, for 4500 cents, and the page shows 45 euros paid back, the expense now only weighing 45 euros. The schema guarantees cents rather than floats, an income and expense pair linked only once, cascading deletion of an account’s transactions and of a transaction’s links, and lossless migrations up to version 6." width="100%">

Amounts are integers, in cents: a float never touches money. The domain knows neither Flutter nor the database, which makes it testable without a device.

<a id="tests"></a>
<img src="docs/en/sections/s13.png" alt="13 Tests" width="100%">

<img src="docs/en/schemas/tests.svg" alt="The tests, run one by one. A counter climbs from 0 to 95 and a strip of 95 cells turns green: first the 33 pure-logic tests, with no device, through flutter test, then the 62 that run on an Android emulator, where SQLCipher and the Keystore exist, through flutter test integration_test. All 95 end up green. Each family lights up when a test that checks it passes. Labels: the merchant comes out of the bank’s noise, and its key does not change from one month to the next. Internal transfers: to savings, from savings, a savings account with an unusual name, and a transfer to someone that is not one. Recurrences: a monthly subscription found with its next date, irregular groceries that are not one. Categorising: the dictionary, corrections learned and followed, and a repeated sync that doubles nothing. Balance: split refunds, merchant refund, cash expense taken off the withdrawals. Wallet: 50 euros counted, a 20 euro withdrawal, 12 euros at the market, 58 left. Budget month: each salary opens its month, even when paid early for Christmas, a bonus opens none, and cash from a withdrawal counts only once. Backup: everything comes back with the right passphrase, a wrong one touches nothing. Signature: the JWT signed in Dart is, byte for byte, the one OpenSSL makes. Refunds: six transfers for one expense, linked either way, never over, even with two writes at the same moment. Syncs: pending transactions that get booked, change amount or are lifted, a year of history, nothing doubles, nothing is lost. Never frozen: every test puts a time limit on its database access, a deadlock would fail the suite instead of freezing it. On device: 95 tests, 33 on pure logic, 62 on an Android emulator." width="100%">

SQLCipher and the Keystore only exist on a device: the integration tests run on an emulator, never on the phone holding the real accounts, since they erase the database.

```
flutter test                                   # the pure logic
flutter test integration_test -d emulator-5554 # the encrypted database, on an emulator
```

<a id="versions"></a>
<img src="docs/en/sections/s14.png" alt="14 Versions" width="100%">

<img src="docs/en/schemas/versions.svg" alt="The releases, eleven in seven days, from Thursday 24 to Wednesday 30 September 2026, stacked one on top of the other: each one drops onto the previous one, just as it installs over it on the phone, without losing anything. At the bottom, the base never moves: your data, accounts, transactions, categories, learnt rules and links, and the same signing key, SHA-256 certificate 55572db2…fabcbef; a thread rises from the key and seals each release. On 24 September, 1.0.0, the first release: linked to Crédit Mutuel de Bretagne through Enable Banking, categorisation, internal transfers, refunds, recurring payments, an encrypted database and the unfolded screen in panes. 1.0.1, a small fix: the right version number in the settings, which still showed 0.1.0. 1.0.2: a Going out and leisure icon group, Ferris wheel, funfair, tickets, cinema, apart from Sport. 1.0.3: the overdrawn account alert, the balance read again every six hours, even with the app closed, one notification each time it drops below zero. 1.1.0: the demo, a second app installed alongside the real one, with four months of made-up transactions, no bank and no fingerprint. On 25 September, 1.2.0: every bank on Enable Banking, by name or by country, a guide page to get the key, pending transactions and a sync every time the app opens. On 26 September, 1.2.2, the full audit: linking a refund no longer freezes the app, it locks again after a trip to the background, the sync keeps the links of pending transactions, no more rule learnt from the “N” of a cheque, net amounts everywhere and correct recurring payments for past months, a transaction’s page fits whole on the unfolded screen. On 27 September, 1.2.3, the month follows the salary: the month starts by itself on the day the salary arrives, and cash withdrawn one month and spent the next no longer counts twice. On 29 September, 1.2.4, several refunds: one expense refunded by several transfers, six friends at 23 euros each, with checkboxes and what is left to cover right in view. The same day, 1.2.5: the Fold’s cover screen stays upright, like a phone, and the inner screen still rotates freely. On 30 September, 1.2.6, the current release, each salary, its month: each salary opens its month, even when paid early for Christmas; a month that opens in the first half of the month takes that month’s name; the home screen is no longer cut in half after locking during typing; paid recurring payments read “3 times, on the 10th” instead of repeating the day; transactions already linked leave To review, whose button now reads “Internal”; the fingerprint prompt has all its texts, under the title SmartBudget. 95 tests, all green." width="100%">

Every Release, with its notes and SHA-256 fingerprints: [github.com/Cybertrist/SmartBudget/releases](https://github.com/Cybertrist/SmartBudget/releases).

<a id="licence"></a>
<img src="docs/en/sections/s15.png" alt="15 Licence and author" width="100%">

The code is released under the [MIT](LICENSE) licence: free to read, reuse and modify, as long as the copyright notice stays. The Figtree font is under the SIL Open Font licence, the Material Symbols icons under Apache 2.0.

Designed and written by **Tristan Joncour**, a cyber-defence engineering student at ENSIBS, for personal use. The security core, fingerprint, keychain and encryption, comes from another app by the same author, [BodyCount](https://github.com/Cybertrist/BodyCount).

**What will never be in this repository:** the Enable Banking private key, the APK signing key, and any real bank data at all. `.gitignore` refuses `.pem`, `.p12`, `.jks` and `key.properties` files.

<br>

<sub>The images on this page come out of no drawing software: they are HTML pages captured by Chrome, and twenty-three animated SVGs written by <code>anime.js</code> and the modules in <code>schemas/</code>, in French and then in English through <code>anglais.json</code>. The screenshots come from an emulator filled with demo data, cropped by <code>rogner.js</code>. It is all in <a href="docs/tools/">docs/tools</a>.</sub>

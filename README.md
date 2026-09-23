# SmartBudget

Arrêter de dépenser sans regarder, et de piocher dans l'épargne. Le mois entier sur un écran, et la part que prend chaque catégorie.

Une application Android, en Flutter, branchée en lecture seule sur le compte courant par l'API d'Enable Banking. Les opérations sont copiées dans une base chiffrée par SQLCipher, dont la clé vit dans le Keystore et ne se charge qu'après l'empreinte.

Le projet est en cours de construction : ce README sera réécrit, avec ses schémas, quand l'application sera complète.

## Ce qui ne sera jamais dans ce dépôt

La clé privée d'Enable Banking, la clé de signature de l'APK, et la moindre donnée bancaire. `.gitignore` refuse les fichiers `.pem`, `.p12`, `.jks` et `key.properties`.

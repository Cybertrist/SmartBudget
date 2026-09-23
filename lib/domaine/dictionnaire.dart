/// Ce que l'application sait classer d'elle-même, avant toute correction.
///
/// Chaque entrée : un motif cherché dans le libellé normalisé, puis la
/// catégorie et la sous-catégorie. L'ordre compte : la première qui
/// correspond gagne, donc « UBER EATS » passe avant « UBER ». Un motif
/// court est entouré de limites de mot, pour que « BP » ne se trouve pas
/// dans « CBPAY ».
///
/// Les corrections de l'utilisateur passent avant ce dictionnaire : il
/// n'est qu'un point de départ.
library;

class Motif {
  const Motif(this.texte, this.categorie, this.sous, {this.seulementEntree = false, this.mot = false});

  final String texte;
  final String categorie;
  final String sous;

  /// Ne vaut que pour une entrée d'argent : « VINTED » positif est une
  /// vente, négatif un achat.
  final bool seulementEntree;

  /// Le motif doit être un mot entier : « PAIE » ne doit pas se trouver
  /// dans « PAIEMENT ». Sans ce drapeau, il suffit qu'un mot commence
  /// par lui (« PIZZ » trouve « PIZZERIA »). Trois lettres ou moins, c'est
  /// toujours un mot entier.
  final bool mot;
}

const dictionnaire = <Motif>[
  // Revenus d'abord : ils ne s'appliquent qu'aux entrées.
  Motif('SALAIRE', 'Salaire', 'Salaire', seulementEntree: true),
  Motif('PAIE', 'Salaire', 'Salaire', seulementEntree: true, mot: true),
  Motif('APPRENTI', 'Salaire', 'Alternance', seulementEntree: true),
  Motif('ALTERNANCE', 'Salaire', 'Alternance', seulementEntree: true),
  Motif('PRIME', 'Salaire', 'Primes', seulementEntree: true, mot: true),
  Motif('CAF', 'Autres revenus', 'Aides et CAF', seulementEntree: true, mot: true),
  Motif('CPAM', 'Autres revenus', 'Remboursements', seulementEntree: true),
  Motif('AMELI', 'Autres revenus', 'Remboursements', seulementEntree: true),
  Motif('MUTUELLE', 'Autres revenus', 'Remboursements', seulementEntree: true),
  Motif('REMBOURSEMENT', 'Autres revenus', 'Remboursements', seulementEntree: true),
  Motif('VINTED', 'Autres revenus', 'Ventes (Vinted, Leboncoin)', seulementEntree: true),
  Motif('LEBONCOIN', 'Autres revenus', 'Ventes (Vinted, Leboncoin)', seulementEntree: true),
  Motif('INTERETS', 'Autres revenus', 'Intérêts', seulementEntree: true),
  Motif('REMISE CHEQUE', 'Autres revenus', 'Remboursements', seulementEntree: true),
  Motif('REMISE CHQ', 'Autres revenus', 'Remboursements', seulementEntree: true),

  // Livraison de repas avant les VTC.
  Motif('UBER EATS', 'Restaurants et sorties', 'Livraison de repas'),
  Motif('DELIVEROO', 'Restaurants et sorties', 'Livraison de repas'),
  Motif('JUST EAT', 'Restaurants et sorties', 'Livraison de repas'),

  // Courses.
  Motif('CARREFOUR', 'Courses', 'Supermarché'),
  Motif('LECLERC', 'Courses', 'Supermarché'),
  Motif('INTERMARCHE', 'Courses', 'Supermarché'),
  Motif('AUCHAN', 'Courses', 'Supermarché'),
  Motif('LIDL', 'Courses', 'Supermarché'),
  Motif('ALDI', 'Courses', 'Supermarché'),
  Motif('SUPER U', 'Courses', 'Supermarché'),
  Motif('HYPER U', 'Courses', 'Supermarché'),
  Motif('MONOPRIX', 'Courses', 'Supermarché'),
  Motif('FRANPRIX', 'Courses', 'Supermarché'),
  Motif('CASINO', 'Courses', 'Supermarché'),
  Motif('SPAR', 'Courses', 'Supermarché', mot: true),
  Motif('NETTO', 'Courses', 'Supermarché'),
  Motif('GRAND FRAIS', 'Courses', 'Marché et primeur'),
  Motif('PICARD', 'Courses', 'Supermarché'),
  Motif('BIOCOOP', 'Courses', 'Produits bio'),
  Motif('NATURALIA', 'Courses', 'Produits bio'),
  Motif('BOULANG', 'Courses', 'Boulangerie'),
  Motif('PATISSERIE', 'Courses', 'Boulangerie'),
  Motif('NICOLAS', 'Courses', 'Cave et alcool'),
  Motif('BOUCHERIE', 'Courses', 'Boucherie et poissonnerie'),

  // Restaurants et sorties.
  Motif('MCDO', 'Restaurants et sorties', 'Fast-food'),
  Motif('MC DONALD', 'Restaurants et sorties', 'Fast-food'),
  Motif('MCDONALD', 'Restaurants et sorties', 'Fast-food'),
  Motif('BURGER KING', 'Restaurants et sorties', 'Fast-food'),
  Motif('KFC', 'Restaurants et sorties', 'Fast-food', mot: true),
  Motif('QUICK', 'Restaurants et sorties', 'Fast-food'),
  Motif('O TACOS', 'Restaurants et sorties', 'Fast-food'),
  Motif('SUBWAY', 'Restaurants et sorties', 'Fast-food'),
  Motif('FIVE GUYS', 'Restaurants et sorties', 'Fast-food'),
  Motif('KEBAB', 'Restaurants et sorties', 'Fast-food'),
  Motif('STARBUCKS', 'Restaurants et sorties', 'Bar et café'),
  Motif('CROUS', 'Restaurants et sorties', 'Cantine et resto U'),
  Motif('RESTAURANT', 'Restaurants et sorties', 'Restaurant'),
  Motif('BRASSERIE', 'Restaurants et sorties', 'Restaurant'),
  Motif('CREPERIE', 'Restaurants et sorties', 'Restaurant'),
  Motif('PIZZ', 'Restaurants et sorties', 'Restaurant'),
  Motif('SUSHI', 'Restaurants et sorties', 'Restaurant'),
  Motif('PUB', 'Restaurants et sorties', 'Bars et clubs', mot: true),

  // Transports.
  Motif('UBER', 'Transports', 'Taxi et VTC'),
  Motif('BOLT', 'Transports', 'Taxi et VTC'),
  Motif('HEETCH', 'Transports', 'Taxi et VTC'),
  Motif('TAXI', 'Transports', 'Taxi et VTC'),
  Motif('TOTALENERGIES', 'Transports', 'Carburant'),
  Motif('TOTAL', 'Transports', 'Carburant', mot: true),
  Motif('ESSO', 'Transports', 'Carburant', mot: true),
  Motif('SHELL', 'Transports', 'Carburant'),
  Motif('AVIA', 'Transports', 'Carburant'),
  Motif('STATION', 'Transports', 'Carburant'),
  Motif('CARBU', 'Transports', 'Carburant'),
  Motif('PEAGE', 'Transports', 'Péage'),
  Motif('VINCI AUTOROUTE', 'Transports', 'Péage'),
  Motif('SANEF', 'Transports', 'Péage'),
  Motif('APRR', 'Transports', 'Péage'),
  Motif('PARKING', 'Transports', 'Parking'),
  Motif('INDIGO', 'Transports', 'Parking'),
  Motif('EFFIA', 'Transports', 'Parking'),
  Motif('SNCF', 'Transports', 'Train'),
  Motif('OUIGO', 'Transports', 'Train'),
  Motif('TRAINLINE', 'Transports', 'Train'),
  Motif('KICEO', 'Transports', 'Transports en commun'),
  Motif('RATP', 'Transports', 'Transports en commun'),
  Motif('NAVIGO', 'Transports', 'Transports en commun'),
  Motif('AIR FRANCE', 'Transports', 'Avion'),
  Motif('EASYJET', 'Transports', 'Avion'),
  Motif('RYANAIR', 'Transports', 'Avion'),
  Motif('TRANSAVIA', 'Transports', 'Avion'),
  Motif('VOLOTEA', 'Transports', 'Avion'),
  Motif('NORAUTO', 'Transports', 'Entretien et réparation'),
  Motif('MIDAS', 'Transports', 'Entretien et réparation'),
  Motif('SPEEDY', 'Transports', 'Entretien et réparation'),

  // Permis.
  Motif('AUTO ECOLE', 'Permis', 'Permis voiture'),
  Motif('AUTO-ECOLE', 'Permis', 'Permis voiture'),
  Motif('ECF', 'Permis', 'Permis voiture', mot: true),
  Motif('CODE ROUSSEAU', 'Permis', 'Code de la route'),
  Motif('ANTS', 'Permis', 'Frais de dossier', mot: true),
  Motif('BATEAU ECOLE', 'Permis', 'Permis bateau'),

  // Abonnements.
  Motif('NETFLIX', 'Abonnements', 'Streaming vidéo'),
  Motif('DISNEY', 'Abonnements', 'Streaming vidéo'),
  Motif('PRIME VIDEO', 'Abonnements', 'Streaming vidéo'),
  Motif('CANAL', 'Abonnements', 'Streaming vidéo', mot: true),
  Motif('CRUNCHYROLL', 'Abonnements', 'Streaming vidéo'),
  Motif('SPOTIFY', 'Abonnements', 'Musique'),
  Motif('DEEZER', 'Abonnements', 'Musique'),
  Motif('FREE MOBILE', 'Abonnements', 'Forfait mobile'),
  Motif('SOSH', 'Abonnements', 'Forfait mobile'),
  Motif('RED BY SFR', 'Abonnements', 'Forfait mobile'),
  Motif('BOUYGUES', 'Abonnements', 'Forfait mobile'),
  Motif('ORANGE', 'Abonnements', 'Forfait mobile', mot: true),
  Motif('SFR', 'Abonnements', 'Forfait mobile', mot: true),
  Motif('FREEBOX', 'Abonnements', 'Internet'),
  Motif('LIVEBOX', 'Abonnements', 'Internet'),
  Motif('AUDIBLE', 'Abonnements', 'Presse et livres audio'),
  Motif('BASIC FIT', 'Abonnements', 'Salle de sport'),
  Motif('BASIC-FIT', 'Abonnements', 'Salle de sport'),
  Motif('FITNESS PARK', 'Abonnements', 'Salle de sport'),
  Motif('KEEP COOL', 'Abonnements', 'Salle de sport'),
  Motif('PLAYSTATION', 'Abonnements', 'Jeux vidéo en ligne'),
  Motif('XBOX', 'Abonnements', 'Jeux vidéo en ligne'),
  Motif('NINTENDO', 'Abonnements', 'Jeux vidéo en ligne'),
  Motif('APPLE.COM', 'Abonnements', 'Cloud et logiciels'),
  Motif('ICLOUD', 'Abonnements', 'Cloud et logiciels'),
  Motif('GOOGLE', 'Abonnements', 'Cloud et logiciels'),
  Motif('MICROSOFT', 'Abonnements', 'Cloud et logiciels'),
  Motif('ADOBE', 'Abonnements', 'Cloud et logiciels'),
  Motif('OPENAI', 'Abonnements', 'Cloud et logiciels'),
  Motif('ANTHROPIC', 'Abonnements', 'Cloud et logiciels'),
  Motif('CLAUDE.AI', 'Abonnements', 'Cloud et logiciels'),

  // Shopping.
  Motif('AMAZON', 'Shopping', 'Marketplace'),
  Motif('AMZN', 'Shopping', 'Marketplace'),
  Motif('CDISCOUNT', 'Shopping', 'Marketplace'),
  Motif('ALIEXPRESS', 'Shopping', 'Marketplace'),
  Motif('TEMU', 'Shopping', 'Marketplace'),
  Motif('SHEIN', 'Shopping', 'Marketplace'),
  Motif('TIKTOK', 'Shopping', 'Marketplace'),
  Motif('VINTED', 'Shopping', 'Seconde main'),
  Motif('LEBONCOIN', 'Shopping', 'Seconde main'),
  Motif('GYMSHARK', 'Shopping', 'Vêtements de sport'),
  Motif('NIKE', 'Shopping', 'Vêtements de sport'),
  Motif('ADIDAS', 'Shopping', 'Vêtements de sport'),
  Motif('DECATHLON', 'Shopping', 'Articles de sport'),
  Motif('INTERSPORT', 'Shopping', 'Articles de sport'),
  Motif('GO SPORT', 'Shopping', 'Articles de sport'),
  Motif('ZARA', 'Shopping', 'Vêtements'),
  Motif('H&M', 'Shopping', 'Vêtements'),
  Motif('H & M', 'Shopping', 'Vêtements'),
  Motif('UNIQLO', 'Shopping', 'Vêtements'),
  Motif('PRIMARK', 'Shopping', 'Vêtements'),
  Motif('KIABI', 'Shopping', 'Vêtements'),
  Motif('CELIO', 'Shopping', 'Vêtements'),
  Motif('JULES', 'Shopping', 'Vêtements'),
  Motif('BERSHKA', 'Shopping', 'Vêtements'),
  Motif('COURIR', 'Shopping', 'Chaussures'),
  Motif('FOOT LOCKER', 'Shopping', 'Chaussures'),
  Motif('FNAC', 'Shopping', 'High-tech'),
  Motif('DARTY', 'Shopping', 'High-tech'),
  Motif('BOULANGER', 'Shopping', 'High-tech'),
  Motif('LDLC', 'Shopping', 'High-tech'),
  Motif('BACK MARKET', 'Shopping', 'High-tech'),
  Motif('APPLE STORE', 'Shopping', 'High-tech'),
  Motif('CULTURA', 'Shopping', 'Livres'),
  Motif('MICROMANIA', 'Shopping', 'Jeux vidéo et jouets'),
  Motif('IKEA', 'Shopping', 'Maison et déco'),
  Motif('ACTION', 'Shopping', 'Maison et déco', mot: true),
  Motif('MAISONS DU MONDE', 'Shopping', 'Maison et déco'),
  Motif('SEPHORA', 'Shopping', 'Beauté et parfum'),
  Motif('NOCIBE', 'Shopping', 'Beauté et parfum'),
  Motif('PAYPAL', 'Shopping', 'Autres'),

  // Logement.
  Motif('LOYER', 'Logement', 'Loyer'),
  Motif('FONCIA', 'Logement', 'Loyer'),
  Motif('NEXITY', 'Logement', 'Loyer'),
  Motif('EDF', 'Logement', 'Électricité', mot: true),
  Motif('ENGIE', 'Logement', 'Gaz'),
  Motif('VEOLIA', 'Logement', 'Eau'),
  Motif('SAUR', 'Logement', 'Eau', mot: true),
  Motif('LEROY MERLIN', 'Logement', 'Entretien et bricolage'),
  Motif('CASTORAMA', 'Logement', 'Entretien et bricolage'),
  Motif('BRICO', 'Logement', 'Entretien et bricolage'),

  // Santé et soins.
  Motif('PHARMACIE', 'Santé', 'Pharmacie'),
  Motif('DOCTOLIB', 'Santé', 'Médecin'),
  Motif('MEDECIN', 'Santé', 'Médecin'),
  Motif('DENTAIRE', 'Santé', 'Dentiste'),
  Motif('DENTISTE', 'Santé', 'Dentiste'),
  Motif('KRYS', 'Santé', 'Opticien et ophtalmo'),
  Motif('AFFLELOU', 'Santé', 'Opticien et ophtalmo'),
  Motif('OPTIC', 'Santé', 'Opticien et ophtalmo'),
  Motif('MUTUELLE', 'Santé', 'Mutuelle'),
  Motif('KINE', 'Santé', 'Kiné et soins', mot: true),
  Motif('COIFF', 'Soins et beauté', 'Coiffeur et barbier'),
  Motif('BARBER', 'Soins et beauté', 'Coiffeur et barbier'),

  // Loisirs.
  Motif('CINEMA', 'Loisirs', 'Cinéma et concerts'),
  Motif('PATHE', 'Loisirs', 'Cinéma et concerts'),
  Motif('CGR', 'Loisirs', 'Cinéma et concerts', mot: true),
  Motif('UGC', 'Loisirs', 'Cinéma et concerts', mot: true),
  Motif('KINEPOLIS', 'Loisirs', 'Cinéma et concerts'),
  Motif('TICKETMASTER', 'Loisirs', 'Cinéma et concerts'),
  Motif('FNAC SPECTACLES', 'Loisirs', 'Cinéma et concerts'),
  Motif('BOOKING', 'Loisirs', 'Hôtels et hébergement'),
  Motif('AIRBNB', 'Loisirs', 'Hôtels et hébergement'),
  Motif('HOTEL', 'Loisirs', 'Hôtels et hébergement'),
  Motif('STEAM', 'Loisirs', 'Divertissements'),
  Motif('FDJ', 'Loisirs', 'Jeux et paris', mot: true),
  Motif('BETCLIC', 'Loisirs', 'Jeux et paris'),
  Motif('WINAMAX', 'Loisirs', 'Jeux et paris'),

  // Banque et impôts.
  Motif('COMMISSION D INTERVENTION', 'Banque et frais', 'Incidents de paiement'),
  Motif('COTIS', 'Banque et frais', 'Cotisation carte'),
  Motif('AGIOS', 'Banque et frais', 'Agios'),
  Motif('INTERETS DEBITEURS', 'Banque et frais', 'Agios'),
  Motif('FRAIS', 'Banque et frais', 'Frais bancaires'),
  Motif('COMMISSION', 'Banque et frais', 'Frais bancaires'),
  Motif('ECHEANCE PRET', 'Banque et frais', 'Remboursement de prêt'),
  Motif('DGFIP', 'Impôts et taxes', 'Impôt sur le revenu'),
  Motif('IMPOT', 'Impôts et taxes', 'Impôt sur le revenu'),
  Motif('TRESOR PUBLIC', 'Impôts et taxes', 'Taxes diverses'),
  Motif('ANTAI', 'Impôts et taxes', 'Amendes'),
  Motif('AMENDE', 'Impôts et taxes', 'Amendes'),

  // Retraits et chèques.
  Motif('RETRAIT', 'Retraits et virements', "Retraits d'espèces"),
  Motif('DAB', 'Retraits et virements', "Retraits d'espèces", mot: true),
  Motif('CHEQUE', 'Retraits et virements', 'Chèques émis'),
];

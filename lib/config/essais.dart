/// Le jeu d'essai n'existe que dans une version de travail.
///
/// `flutter build apk --dart-define=ESSAIS=true` le fait apparaître dans
/// les réglages. Sans ce drapeau, la constante vaut faux à la compilation :
/// le compilateur retire la ligne des réglages et tout le générateur avec.
const bool avecEssais = bool.fromEnvironment('ESSAIS') || modeDemo;

/// La démo publiée : `--dart-define=DEMO=true`. Une application à part
/// (« SmartBudget démo », identifiant `.demo`), qui s'installe à côté de
/// la vraie. Elle se remplit toute seule du jeu d'essai au premier
/// lancement, et ne se relie à aucune banque.
const bool modeDemo = bool.fromEnvironment('DEMO');

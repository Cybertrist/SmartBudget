/// Le jeu d'essai n'existe que dans une version de travail.
///
/// `flutter build apk --dart-define=ESSAIS=true` le fait apparaître dans
/// les réglages. Sans ce drapeau, la constante vaut faux à la compilation :
/// le compilateur retire la ligne des réglages et tout le générateur avec.
const bool avecEssais = bool.fromEnvironment('ESSAIS');

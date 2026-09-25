// lib/modele/sports/exercices.dart
//
// Un EXERCICE de la banque (hors ligne, sans IA) : son style, ses muscles
// principaux et secondaires, son matériel, s'il fait travailler plusieurs
// articulations (polyarticulaire) ou une seule (isolation), son niveau ; la
// fiche — étapes, erreurs fréquentes, respiration — et son MOUVEMENT (le
// corps animé de `widgets/corps/animations_corps.dart`). Les variantes plus
// faciles et plus dures sont des CHAÎNES (`catalogue.dart`).
//
// Le contenu (noms, étapes, conseils) est de la donnée, en français.

import 'muscles.dart';

enum StyleSport {
  musculation,
  poidsDuCorps,
  gainage,
  hiit,
  mobilite,
  cardio;

  /// Dépense d'un effort de ce style (MET, compendium d'Ainsworth).
  double get met => switch (this) {
    musculation => 5.0,
    poidsDuCorps => 5.0,
    gainage => 3.8,
    hiit => 8.0,
    mobilite => 2.5,
    cardio => 7.0,
  };
}

/// Le matériel. Un exercice sans matériel n'en demande aucun.
enum Materiel {
  halteres,
  barre,
  kettlebell,
  elastique,
  barreTraction,
  banc,
  chaise,
  corde,
  velo;

  /// Une charge qui se note en kilos.
  bool get charge => this == halteres || this == barre || this == kettlebell;
}

enum Niveau { debutant, intermediaire, avance }

/// Ce qu'on compte : des répétitions ou une durée.
enum Mesure { repetitions, duree }

/// Comment respirer, par famille de mouvement.
enum Respiration {
  pousser(
    'Inspire en descendant, souffle en poussant. Ne bloque jamais ta '
    'respiration.',
  ),
  tirer('Inspire bras tendus, souffle en tirant, inspire en revenant.'),
  jambes(
    'Inspire en descendant, souffle en remontant — le souffle accompagne '
    "l'effort.",
  ),
  charniere(
    "Inspire en basculant vers l'avant, souffle en ramenant les hanches.",
  ),
  gainage(
    'Respire calmement par le ventre sans relâcher le gainage : ne retiens '
    'pas ton souffle.',
  ),
  abdos('Souffle en enroulant, inspire en revenant sans relâcher.'),
  hiit("Souffle à chaque effort ; garde un rythme, même quand ça brûle."),
  cardio(
    'Trouve un rythme régulier : inspire sur deux ou trois pas, souffle sur '
    'autant.',
  ),
  etirement(
    'Respire lentement. À chaque expiration, relâche un peu plus, sans '
    'forcer.',
  ),
  mobilite('Respire librement, le souffle accompagne le mouvement.');

  const Respiration(this.texte);
  final String texte;
}

class ExerciceSport {
  const ExerciceSport(
    this.id,
    this.nom,
    this.style,
    this.mouvement, {
    required this.principaux,
    this.secondaires = const [],
    this.materiel = const {},
    this.poly = false,
    this.niveau = Niveau.debutant,
    this.mesure = Mesure.repetitions,
    this.parCote = false,
    required this.etapes,
    required this.erreurs,
    required this.respiration,
    this.met,
    this.intensite = 1,
  });

  final String id;
  final String nom;
  final StyleSport style;

  /// L'identifiant du corps animé (`Mouvements`).
  final String mouvement;
  final List<Muscle> principaux;
  final List<Muscle> secondaires;
  final Set<Materiel> materiel;

  /// Plusieurs articulations à la fois (squat, pompe, rowing) — sinon une
  /// seule (isolation : curl, élévation latérale).
  final bool poly;
  final Niveau niveau;
  final Mesure mesure;

  /// Se fait d'un côté puis de l'autre (fente, rowing un bras).
  final bool parCote;
  final List<String> etapes;
  final List<String> erreurs;
  final Respiration respiration;
  final double? met;

  /// Ce que demande l'exercice, de 1 (léger) à 3 (très exigeant) : le
  /// constructeur place les plus lourds d'abord.
  final int intensite;

  bool get enDuree => mesure == Mesure.duree;

  /// Se charge en kilos (haltères, barre, kettlebell).
  bool get charge => materiel.any((m) => m.charge);

  bool get sansMateriel => materiel.isEmpty;

  /// Faisable avec ce matériel.
  bool faisableAvec(Set<Materiel> dispo) => dispo.containsAll(materiel);

  double get depense => met ?? style.met;

  /// Tous les muscles, principaux d'abord.
  List<Muscle> get muscles => [...principaux, ...secondaires];

  /// Un exercice de tronc (gainage, abdos) : à la fin de la séance.
  bool get deTronc =>
      style == StyleSport.gainage || principaux.every((m) => m.tronc);

  /// Un échauffement ou un étirement (pas une série de travail).
  bool get douce => style == StyleSport.mobilite;
}

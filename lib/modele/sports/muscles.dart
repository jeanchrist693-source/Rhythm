// lib/modele/sports/muscles.dart
//
// Les MUSCLES, tels que Rhythm les nomme, les colore sur le corps
// (`widgets/corps/corps_humain.dart`), les place sur la silhouette
// (`widgets/corps/silhouette.dart`) et les compte (séries par muscle,
// récupération, muscles négligés).
//
// - GROS ou petit : le constructeur fait passer les gros avant les petits ;
// - ARTICULATIONS : ce que l'échauffement doit mobiliser avant de les
//   charger ;
// - OPPOSÉ : le partenaire d'un enchaînement sans repos (pectoraux ↔ dos,
//   biceps ↔ triceps, quadriceps ↔ ischios…).

enum Muscle {
  pectoraux,
  dos,
  trapezes,
  epaules,
  biceps,
  triceps,
  avantBras,
  abdos,
  obliques,
  lombaires,
  fessiers,
  quadriceps,
  ischios,
  adducteurs,
  mollets;

  /// Les gros muscles (les exercices qui les travaillent passent d'abord).
  bool get gros => switch (this) {
    pectoraux || dos || quadriceps || ischios || fessiers => true,
    _ => false,
  };

  /// Le haut ou le bas du corps (échauffement, répartition).
  bool get haut => switch (this) {
    pectoraux ||
    dos ||
    trapezes ||
    epaules ||
    biceps ||
    triceps ||
    avantBras => true,
    _ => false,
  };

  /// Le tronc (gainage : à la fin de la séance).
  bool get tronc => this == abdos || this == obliques || this == lombaires;

  /// Les articulations qu'il faut préparer avant de charger ce muscle.
  Set<Articulation> get articulations => switch (this) {
    pectoraux ||
    epaules ||
    trapezes => {Articulation.epaules, Articulation.colonne},
    dos => {Articulation.epaules, Articulation.colonne},
    biceps || triceps => {Articulation.coudes, Articulation.epaules},
    avantBras => {Articulation.poignets, Articulation.coudes},
    abdos ||
    obliques ||
    lombaires => {Articulation.colonne, Articulation.hanches},
    fessiers || adducteurs => {Articulation.hanches, Articulation.genoux},
    quadriceps || ischios => {Articulation.genoux, Articulation.hanches},
    mollets => {Articulation.chevilles, Articulation.genoux},
  };

  /// Le muscle opposé (enchaînement sans repos) ; `null` : aucun.
  Muscle? get oppose => switch (this) {
    pectoraux => dos,
    dos => pectoraux,
    biceps => triceps,
    triceps => biceps,
    quadriceps => ischios,
    ischios => quadriceps,
    abdos => lombaires,
    lombaires => abdos,
    epaules => dos,
    fessiers => quadriceps,
    _ => null,
  };
}

enum Articulation {
  epaules,
  coudes,
  poignets,
  colonne,
  hanches,
  genoux,
  chevilles,
}

// lib/modele/graine.dart
//
// Les données de démonstration : EXACTEMENT celles de la maquette, posées
// sur les VRAIES dates (la maquette est datée du jeudi 24 septembre 2026,
// semaine 39 — le jour de sa création). Un autre jour, les mêmes valeurs
// suivent le calendrier : la semaine se remplit jusqu'à aujourd'hui.
//
// Les habitudes, les sports et l'alimentation n'y sont plus : ils vivent
// (`etat_habitudes.dart`, `sports/etat_sport.dart`,
// `alimentation/etat_alimentation.dart`).
//
// Espaces insécables (U+00A0) entre un nombre et son unité, et avant « : »
// (typographie française : jamais « kg » ni « : » seuls en début de ligne).

import 'modeles.dart';

abstract final class Graine {
  static const Verset verset = Verset(
    texte: "L'Éternel est mon berger : je ne manquerai de rien.",
    reference: 'Psaume 23.1',
    traduction: 'Louis Segond',
  );

  // ── Biblique ──────────────────────────────────────────────────────────────
  static const PlanLecture plan = PlanLecture(
    livre: 'Évangile selon Jean',
    abrege: 'Jean',
    chapitre: 3,
    total: 21,
  );

  static const int serieLecture = 12;
  static const int sujetsPriere = 3;
}

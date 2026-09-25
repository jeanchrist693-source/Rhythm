// lib/modele/modeles.dart
//
// Les types communs de Rhythm, au plus simple : ce que les écrans de la
// maquette affichent. Les habitudes, les sports et l'alimentation ont leur
// modèle complet (`habitudes.dart`, `sports/`, `alimentation/`) ; le
// biblique suivra.

import 'dart:ui' show Color;

import '../theme/rhythm_couleurs.dart';

/// Les pastels de la maquette, un par domaine.
enum Teinte {
  corail(RhythmCouleurs.corail),
  peche(RhythmCouleurs.peche),
  menthe(RhythmCouleurs.menthe),
  lavande(RhythmCouleurs.lavande),
  ciel(RhythmCouleurs.ciel);

  const Teinte(this.couleur);
  final Color couleur;
}

class Verset {
  const Verset({
    required this.texte,
    required this.reference,
    required this.traduction,
  });

  /// Sans guillemets : l'écran les pose (« … », avec insécables).
  final String texte;
  final String reference;
  final String traduction;
}

/// Les repas de la journée, au sens québécois : déjeuner le matin, dîner le
/// midi, souper le soir.
enum MomentRepas { dejeuner, diner, collation, souper }

enum Macro { proteines, glucides, lipides }

class ApportMacro {
  const ApportMacro(this.macro, this.grammes, this.objectif);

  final Macro macro;
  final int grammes;
  final int objectif;

  double get progression => grammes / objectif;
}

class PlanLecture {
  const PlanLecture({
    required this.livre,
    required this.abrege,
    required this.chapitre,
    required this.total,
  });

  /// « Évangile selon Jean ».
  final String livre;

  /// « Jean » (« Jean 3 »).
  final String abrege;

  /// Chapitre en cours.
  final int chapitre;
  final int total;

  String get chapitreEnCours => '$abrege $chapitre';
  String get chapitrePrecedent => '$abrege ${chapitre - 1}';
}

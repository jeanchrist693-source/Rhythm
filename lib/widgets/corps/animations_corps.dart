// lib/widgets/corps/animations_corps.dart
//
// Les MOUVEMENTS : chaque animation d'exercice, en poses clés 3D
// (`squelette3.dart`) — la hanche placée, les mains et les pieds PLANTÉS
// par des cibles (cinématique inverse), un tempo de vraie répétition. Une
// famille par fichier (`mouvements/`). Plusieurs exercices partagent un
// mouvement et changent de matériel (squat au poids du corps, goblet, à la
// barre) : le catalogue (`modele/sports/catalogue/`) désigne le mouvement
// de chaque exercice par son identifiant.
//
// Repères, vus de profil, le corps tourné vers la droite : 0 = vers
// l'avant, 90 = vers le bas, −90 = vers le haut, 180 = vers l'arrière ;
// l'écart sort du plan (positif : vers l'extérieur de son côté). Un angle
// qui doit tourner « par l'arrière » s'écrit au-delà de 180 (210 : en
// arrière et vers le haut) — l'interpolation passe par le bon côté.

import 'dart:math' as math;
import 'dart:ui';

import 'corps_humain.dart';
import 'figure_exercice.dart';
import 'geometrie3.dart';
import 'squelette3.dart'
    show
        Squelette3,
        hDebout,
        lCou,
        lCuisse,
        lJambe,
        lTronc,
        rTeteY,
        yCheville,
        yPaume;

part 'mouvements/outils.dart';
part 'mouvements/jambes.dart';
part 'mouvements/poussee.dart';
part 'mouvements/tirage.dart';
part 'mouvements/tronc.dart';
part 'mouvements/cardio.dart';
part 'mouvements/mobilite.dart';
part 'mouvements/variantes.dart';

abstract final class Mouvements {
  /// Tous les mouvements, famille par famille.
  static final Map<String, AnimCorps> tous = {
    ..._jambes3,
    ..._poussee3,
    ..._tirage3,
    ..._tronc3,
    ..._cardio3,
    ..._mobilite3,
    ..._variantes3,
  };

  static AnimCorps? de(String id) => tous[id];
}

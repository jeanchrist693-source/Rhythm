// lib/ecrans/coquille/entree_accueil.dart
//
// Partition de l'ENTRÉE DE L'ACCUEIL, une fois par lancement, jouée dès que
// le logo de la scène d'ouverture commence à s'effacer
// (`SceneOuverture.ouvert`). Une seule horloge de 1,4 s ; chaque acteur y
// lit son intervalle — tout se règle ici, jamais en fractions dispersées
// (méthode de Net Worth).
//
//   0,00 + n·0,05  chaque bloc monte de 20 px en fondu (0,45 chacun) :
//                  en-tête, LIBÉRATION (s'il y en a une), verset, les
//                  quatre cases une à une, séance
//   0,10 – 0,65    la barre de navigation monte depuis le bas (sans fondu :
//                  son flou ferait sauter la teinte — leçon MyTV)
//   0,12 – 0,62    la croix de la grille se trace depuis son centre
//   0,22 – 0,86    les anneaux se tracent, les chiffres comptent
//   0,34 + n·0,06  les pastilles des habitudes faites s'allument une à une
//
// Les fondus se CHEVAUCHENT largement (chacun dure neuf pas) : c'est le
// recouvrement qui fait la coulée, pas l'écart entre les départs (MyTV).

import 'package:flutter/animation.dart';

abstract final class EntreeAccueil {
  static const Duration duree = Duration(milliseconds: 1400);

  // ── Les blocs ─────────────────────────────────────────────────────────────
  static const double pasBlocs = 0.05;
  static const double dureeBloc = 0.45;
  static const double montee = 20;

  /// Le bloc de rang [rang], dans l'ordre de l'écran (0 = en-tête).
  static Interval bloc(int rang) => Interval(
    rang * pasBlocs,
    rang * pasBlocs + dureeBloc,
    curve: Curves.easeOutCubic,
  );

  // ── La barre ──────────────────────────────────────────────────────────────
  static const Interval barre = Interval(
    0.10,
    0.65,
    curve: Curves.easeOutCubic,
  );

  // ── La croix de la grille ─────────────────────────────────────────────────
  static const Interval filets = Interval(
    0.12,
    0.62,
    curve: Curves.easeInOutCubic,
  );

  // ── Les mesures ───────────────────────────────────────────────────────────
  static const Interval compteurs = Interval(
    0.22,
    0.86,
    curve: Curves.easeOutCubic,
  );

  /// La pastille [i] des habitudes faites éclot (léger rebond).
  static Interval pastille(int i) =>
      Interval(0.34 + i * 0.06, 0.48 + i * 0.06, curve: Curves.easeOutBack);
}

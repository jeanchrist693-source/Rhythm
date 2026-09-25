// lib/theme/rhythm_mesures.dart
//
// Grille, rayons et durées de Rhythm. Maquette dessinée à 390 × 844 : 60 px
// du haut (barre d'état comprise), marges 20, 16 entre les blocs, barre
// flottante de 68 à 20 des bords et 28 du bas. Sur le téléphone, le haut et
// le bas se calent sur les marges du système (jamais moins que la maquette).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

abstract final class RhythmEspaces {
  /// Marge latérale d'écran.
  static const double marge = 20;

  /// Écart entre deux sections d'un écran. Sans cartes, c'est l'AIR qui fait
  /// les groupes : 28 (la maquette, avec ses boîtes : 16).
  static const double ecart = 28;

  /// Sous l'en-tête d'un écran.
  static const double ecartEnTete = 22;

  /// Air de chaque côté d'un filet entre deux cases.
  static const double ecartFilet = 18;

  /// Largeur maximale du contenu (tablette).
  static const double largeurMaxContenu = 560;

  /// Haut du contenu : 60 comme la maquette, ou 22 sous la barre d'état si
  /// elle est plus haute.
  static double haut(BuildContext context) =>
      math.max(60, MediaQuery.viewPaddingOf(context).top + 22);

  // ── Barre de navigation flottante ─────────────────────────────────────────
  static const double hauteurBarre = 68;
  static const double retraitBarre = 20;

  /// Au-dessus du bas de l'écran : 28 comme la maquette, ou 12 au-dessus de
  /// la barre de gestes d'Android.
  static double basBarre(BuildContext context) =>
      math.max(28, MediaQuery.viewPaddingOf(context).bottom + 12);

  /// Sous le dernier bloc d'un écran, pour qu'il défile au-dessus de la barre.
  static double degagementBarre(BuildContext context) =>
      basBarre(context) + hauteurBarre + 24;

  /// Flou de la barre (`blur(28px)`), le SEUL verre flouté : sous les
  /// cartes le fond est noir, un flou n'y changerait rien — et dans une
  /// animation d'opacité il fait sauter la teinte (leçon MyTV).
  static const double flouBarre = 28;
}

/// Plus de cartes, donc plus de rayons de carte : seule la barre flottante
/// (une capsule) en garde un. Boutons et pastilles sont des capsules et des
/// disques (rayon = moitié de la hauteur).
abstract final class RhythmRayons {
  static const double barre = 34;
}

abstract final class RhythmDurees {
  /// Entrée d'un onglet (fondu + montée de 12 px), reprise de MyTV /
  /// Net Worth / Studio.
  static const Duration entreeOnglet = Duration(milliseconds: 240);

  /// La capsule de l'onglet actif qui glisse d'une destination à l'autre.
  static const Duration basculeBarre = Duration(milliseconds: 300);
}

// lib/theme/rhythm_typo.dart
//
// Deux familles, chacune un rôle (maquette Rhythm) :
// - **Bricolage Grotesque** : titres d'écran, grands chiffres, versets.
// - **DM Sans** : tout le reste — libellés, listes, boutons.
//
// Les deux sont VARIABLES (axes `wght` et `opsz`). Le navigateur de la
// maquette applique la taille optique d'office (`font-optical-sizing:
// auto` : opsz = taille du texte) : on fait pareil, sinon les titres
// perdent leur dessin. ⚠️ Les valeurs par défaut du fichier de Bricolage
// sont wght 800 et opsz 96 — d'où les deux axes TOUJOURS passés (piège de
// Fraunces dans Studio). Toujours ces fabriques, jamais un `TextStyle` nu.
//
// Hauteur de ligne : `null` = celle de la police (1,2 pour Bricolage, 1,302
// pour DM Sans), exactement le `line-height: normal` de la maquette. On ne
// la fixe que là où la maquette la fixe (versets).

import 'package:flutter/painting.dart';

import 'rhythm_couleurs.dart';

abstract final class RhythmTypo {
  static const String familleTitre = 'BricolageGrotesque';
  static const String familleTexte = 'DMSans';

  static FontWeight _graisse(int poids) => switch (poids) {
    <= 400 => FontWeight.w400,
    <= 500 => FontWeight.w500,
    _ => FontWeight.w600,
  };

  /// Bricolage Grotesque. [espacement] en em (la maquette : −0,02 em sur
  /// les titres et les chiffres).
  static TextStyle titre(
    double taille, {
    int poids = 600,
    Color couleur = RhythmCouleurs.texte,
    double espacement = -0.02,
    double? hauteur,
  }) => TextStyle(
    fontFamily: familleTitre,
    fontSize: taille,
    fontWeight: _graisse(poids),
    fontVariations: [
      FontVariation('opsz', taille.clamp(12, 96).toDouble()),
      FontVariation('wght', poids.toDouble()),
    ],
    letterSpacing: espacement * taille,
    height: hauteur,
    color: couleur,
  );

  /// DM Sans. [espacement] en em (surtitres en capitales : 0,06 à 0,08).
  static TextStyle texte(
    double taille, {
    int poids = 400,
    Color couleur = RhythmCouleurs.texte,
    double espacement = 0,
    double? hauteur,
  }) => TextStyle(
    fontFamily: familleTexte,
    fontSize: taille,
    fontWeight: _graisse(poids),
    fontVariations: [
      FontVariation('opsz', taille.clamp(9, 40).toDouble()),
      FontVariation('wght', poids.toDouble()),
    ],
    letterSpacing: espacement * taille,
    height: hauteur,
    color: couleur,
  );

  // ── Échelle nommée (valeurs de la maquette) ───────────────────────────────

  /// Titre d'écran (« Bonjour », « Sports ») : 34, graisse 600.
  static TextStyle get titreEcran => titre(34);

  /// Surtitre d'écran (« Jeudi 24 septembre ») : 13, secondaire.
  static TextStyle get surtitre => texte(13, couleur: RhythmCouleurs.texte64);

  /// Chiffre d'une tuile (« 42 min ») : 24.
  static TextStyle get chiffreTuile => titre(24);

  /// Chiffre d'une statistique (« 1 180 ») : 22.
  static TextStyle get chiffreStat => titre(22);

  /// Titre d'une carte (« Repas », « Haut du corps ») : 17, graisse 600.
  static TextStyle get titreCarte => texte(17, poids: 600);

  /// Ligne d'une liste (exercice, repas, habitude) : 15.
  static TextStyle get ligne => texte(15);

  /// Détail secondaire (« 4 × 8 · 60 kg ») : 13.
  static TextStyle get detail => texte(13, couleur: RhythmCouleurs.texte64);

  /// Petit détail (« objectif 60 min ») : 12.
  static TextStyle get petit => texte(12, couleur: RhythmCouleurs.texte64);
}

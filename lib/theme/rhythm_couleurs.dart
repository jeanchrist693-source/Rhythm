// lib/theme/rhythm_couleurs.dart
//
// Palette de Rhythm, relevée sur la maquette (design/Rhythm.html, cinq
// planches : Accueil, Sports, Alimentation, Habitudes, Biblique). Noir OLED
// pur, et CINQ pastels, un par domaine. Ils portent un sens, jamais une
// décoration : corail = sports, pêche = alimentation, menthe = habitudes (et
// tout ce qui est « fait »), lavande = biblique, ciel = l'eau. Depuis le
// 24 septembre 2026 : ni cartes ni lueurs (`lib/widgets/filets.dart`).

import 'package:flutter/painting.dart';

abstract final class RhythmCouleurs {
  static const Color fond = Color(0xFF000000);
  static const Color noir = Color(0xFF000000);
  static const Color blanc = Color(0xFFFFFFFF);

  /// Le texte (#F5F5F7) : un blanc à peine cassé.
  static const Color texte = Color(0xFFF5F5F7);

  /// Texte secondaire : rgba(235, 235, 245, 0,64).
  static const Color texte64 = Color(0xA3EBEBF5);

  /// Libellé d'une tuile : rgba(235, 235, 245, 0,72).
  static const Color texte72 = Color(0xB8EBEBF5);

  // ── Les domaines ──────────────────────────────────────────────────────────
  static const Color corail = Color(0xFFFF8A7A);
  static const Color peche = Color(0xFFFFD3A8);
  static const Color menthe = Color(0xFFA6EFCB);
  static const Color lavande = Color(0xFFD9C8FF);
  static const Color ciel = Color(0xFFBFDDFF);

  /// Le contenu du bol (mascotte d'Alimentation).
  static const Color abricot = Color(0xFFFFB27A);

  /// La page de droite du livre (mascotte de Biblique).
  static const Color lavandePale = Color(0xFFEFE8FF);

  // ── Le verre (la barre de navigation, seul objet flottant) ──────────────
  /// Bord blanc 18 %…
  static const Color bordVerre = Color(0x2EFFFFFF);

  /// …et reflet de 1 px sous le bord haut, blanc 28 %.
  static const Color refletVerre = Color(0x47FFFFFF);

  /// Dégradé de la barre (180°) : 16 % → 7 %.
  static const List<Color> degradeBarre = [
    Color(0x29FFFFFF),
    Color(0x12FFFFFF),
  ];

  // ── Blancs translucides d'usage ───────────────────────────────────────────
  /// Pistes des anneaux et des jauges, barres vides : 12 %.
  static const Color piste = Color(0x1FFFFFFF);

  /// Filet entre deux lignes d'une liste, entre deux cases : 8 %.
  static const Color filet = Color(0x14FFFFFF);

  /// La croix d'une grille de cases, un peu plus présente : 11 %.
  static const Color filetGrille = Color(0x1CFFFFFF);

  /// Pastille d'habitude pas encore faite (tuile de l'accueil) : 16 %.
  static const Color pastilleVide = Color(0x29FFFFFF);

  /// Point d'un repas à planifier : 20 %.
  static const Color pointVide = Color(0x33FFFFFF);

  /// Onglet actif de la barre : 14 %.
  static const Color ongletActif = Color(0x24FFFFFF);

  /// Bord d'un bouton secondaire (« Partager ») : 20 %.
  static const Color bordBouton = Color(0x33FFFFFF);

  /// Cercle d'une habitude à faire : 28 %.
  static const Color cocheVide = Color(0x47FFFFFF);

  /// Le filet d'un champ en cours de saisie : 45 %.
  static const Color filetActif = Color(0x73FFFFFF);

  /// Fond d'une capsule de choix non choisie, d'un bouton − / + : 8 %.
  static const Color capsule = Color(0x14FFFFFF);

  /// Texte d'aide, indice d'un champ vide : 40 %.
  static const Color texte40 = Color(0x66EBEBF5);

  /// Ombre de la barre flottante : noir 60 %.
  static const Color ombreBarre = Color(0x99000000);
}

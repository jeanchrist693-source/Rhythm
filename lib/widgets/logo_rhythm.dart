// lib/widgets/logo_rhythm.dart
//
// Le logo de Rhythm : QUATRE CAPSULES, une par domaine (corail, pêche,
// menthe, lavande — l'ordre de la barre de navigation), dressées comme les
// barres d'un égaliseur : le rythme de la journée. Les capsules sont celles
// de la maquette (barres de la semaine, pastilles, onglet actif).
//
// Géométrie en FRACTIONS d'un carré, partagée avec l'icône de l'app
// (`tool/gen_icone.py` en recopie les valeurs : les garder alignées).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/rhythm_couleurs.dart';

abstract final class LogoRhythm {
  static const double largeurBarre = 0.13;
  static const double ecartBarres = 0.085;

  /// Hauteur de chaque capsule au repos.
  static const List<double> hauteurs = [0.46, 0.78, 0.60, 0.34];

  static const List<Color> couleurs = [
    RhythmCouleurs.corail,
    RhythmCouleurs.peche,
    RhythmCouleurs.menthe,
    RhythmCouleurs.lavande,
  ];

  /// Centre horizontal de la capsule [i].
  static double centre(int i) {
    const total = 4 * largeurBarre + 3 * ecartBarres;
    return (1 - total) / 2 +
        i * (largeurBarre + ecartBarres) +
        largeurBarre / 2;
  }

  /// Le logo au repos : (largeur, hauteur) de chaque capsule.
  static List<(double, double)> get repos => [
    for (final h in hauteurs) (largeurBarre, h),
  ];
}

/// Dessine les quatre capsules centrées sur la ligne médiane du carré.
/// [barres] : (largeur, hauteur) de chacune, en fractions du carré ; une
/// largeur nulle = capsule pas encore née. Jamais plus basse que large :
/// à hauteur minimale, c'est un point.
class PeintreLogo extends CustomPainter {
  PeintreLogo(this.barres);

  final List<(double, double)> barres;

  @override
  void paint(Canvas canvas, Size size) {
    final cote = size.shortestSide;
    final origine = Offset((size.width - cote) / 2, (size.height - cote) / 2);
    for (var i = 0; i < barres.length; i++) {
      final (l, h) = barres[i];
      if (l <= 0) continue;
      final largeur = l * cote;
      final hauteur = math.max(h * cote, largeur);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: origine + Offset(LogoRhythm.centre(i) * cote, cote / 2),
            width: largeur,
            height: hauteur,
          ),
          Radius.circular(largeur / 2),
        ),
        Paint()..color = LogoRhythm.couleurs[i],
      );
    }
  }

  @override
  bool shouldRepaint(PeintreLogo ancien) => !listEquals(ancien.barres, barres);
}

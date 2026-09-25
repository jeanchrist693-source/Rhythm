// lib/widgets/jauges.dart
//
// Ce qui mesure un avancement, tel que la maquette le dessine :
// - **Anneau** : piste blanche 12 %, arc de couleur qui part du haut, bouts
//   ronds (`stroke-dasharray` des SVG de la maquette) ;
// - **Jauge** : barre fine arrondie (macronutriments) ;
// - **Segments** : cases égales, pleines puis vides (verres d'eau,
//   chapitres du plan de lecture) ;
// - **AnneauSegmente** : l'anneau coupé en arcs égaux, un par élément
//   (les habitudes du jour sur l'accueil : menthe = faite).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/rhythm_couleurs.dart';

class Anneau extends StatelessWidget {
  const Anneau({
    super.key,
    required this.taille,
    required this.rayon,
    required this.epaisseur,
    required this.progression,
    required this.couleur,
  });

  final double taille;

  /// Rayon du trait (au milieu de son épaisseur), comme `r` en SVG.
  final double rayon;
  final double epaisseur;

  /// 0 → 1.
  final double progression;
  final Color couleur;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(taille),
    painter: _PeintreAnneau(rayon, epaisseur, progression, couleur),
  );
}

class _PeintreAnneau extends CustomPainter {
  _PeintreAnneau(this.rayon, this.epaisseur, this.progression, this.couleur);

  final double rayon;
  final double epaisseur;
  final double progression;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final trait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = epaisseur;
    canvas.drawCircle(centre, rayon, trait..color = RhythmCouleurs.piste);
    // Rien à 0 : un arc nul à bouts ronds dessinerait un point.
    if (progression <= 0.001) return;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon),
      -math.pi / 2,
      2 * math.pi * progression.clamp(0.0, 1.0),
      false,
      trait
        ..color = couleur
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PeintreAnneau ancien) =>
      ancien.progression != progression ||
      ancien.couleur != couleur ||
      ancien.rayon != rayon ||
      ancien.epaisseur != epaisseur;
}

class Jauge extends StatelessWidget {
  const Jauge({
    super.key,
    required this.progression,
    required this.couleur,
    this.hauteur = 6,
  });

  final double progression;
  final Color couleur;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    final rayon = BorderRadius.circular(hauteur / 2);
    return Container(
      height: hauteur,
      decoration: BoxDecoration(
        color: RhythmCouleurs.piste,
        borderRadius: rayon,
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progression.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: couleur, borderRadius: rayon),
        ),
      ),
    );
  }
}

class Segments extends StatelessWidget {
  const Segments({
    super.key,
    required this.total,
    required this.pleins,
    required this.couleur,
    required this.hauteur,
    required this.rayon,
    required this.ecart,
  });

  final int total;
  final int pleins;
  final Color couleur;
  final double hauteur;
  final double rayon;
  final double ecart;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) SizedBox(width: ecart),
        Expanded(
          child: Container(
            height: hauteur,
            decoration: BoxDecoration(
              color: i < pleins ? couleur : RhythmCouleurs.piste,
              borderRadius: BorderRadius.circular(rayon),
            ),
          ),
        ),
      ],
    ],
  );
}

/// L'anneau coupé en [total] arcs égaux (un écart de [ecart] degrés entre
/// deux), du haut, dans le sens horaire ; les [pleins] premiers en
/// [couleur]. [eclat] (0 → 1) déroule chaque arc plein à l'entrée.
class AnneauSegmente extends StatelessWidget {
  const AnneauSegmente({
    super.key,
    required this.taille,
    required this.rayon,
    required this.epaisseur,
    required this.total,
    required this.pleins,
    required this.couleur,
    this.ecart = 14,
    this.eclat,
    this.child,
  });

  final double taille;
  final double rayon;
  final double epaisseur;
  final int total;
  final int pleins;
  final Color couleur;
  final double ecart;
  final double Function(int i)? eclat;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(taille),
    painter: _PeintreSegments(rayon, epaisseur, total, pleins, couleur, ecart, [
      for (var i = 0; i < pleins; i++) eclat?.call(i) ?? 1,
    ]),
    child: SizedBox.square(dimension: taille, child: child),
  );
}

class _PeintreSegments extends CustomPainter {
  _PeintreSegments(
    this.rayon,
    this.epaisseur,
    this.total,
    this.pleins,
    this.couleur,
    this.ecart,
    this.eclats,
  );

  final double rayon, epaisseur;
  final int total, pleins;
  final Color couleur;
  final double ecart;
  final List<double> eclats;

  @override
  void paint(Canvas canvas, Size size) {
    final cadre = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: rayon,
    );
    final trait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = epaisseur
      ..strokeCap = StrokeCap.round;
    if (total <= 0) {
      canvas.drawCircle(
        cadre.center,
        rayon,
        trait..color = RhythmCouleurs.piste,
      );
      return;
    }
    // L'écart compte les bouts ronds : chacun déborde d'une demi-épaisseur.
    final rond = epaisseur / rayon;
    final pas = 2 * math.pi / total;
    final vide = total == 1 ? 0.0 : ecart * math.pi / 180 + rond;
    final arc = math.max(0.001, pas - vide);
    for (var i = 0; i < total; i++) {
      final debut = -math.pi / 2 + i * pas + vide / 2;
      canvas.drawArc(
        cadre,
        debut,
        arc,
        false,
        trait..color = RhythmCouleurs.piste,
      );
      if (i < pleins && eclats[i] > 0.001) {
        canvas.drawArc(
          cadre,
          debut,
          arc * eclats[i].clamp(0.0, 1.0),
          false,
          trait..color = couleur,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreSegments ancien) =>
      ancien.total != total ||
      ancien.pleins != pleins ||
      ancien.couleur != couleur ||
      !_memes(ancien.eclats, eclats);

  static bool _memes(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

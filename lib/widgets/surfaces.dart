// lib/widgets/surfaces.dart
//
// Ce qui reste des surfaces de la maquette, depuis que Rhythm n'a plus de
// cartes (voir `filets.dart`) :
//
// - **PeintreVerre** : le verre de la maquette — dégradé
//   `linear-gradient([angle]deg, …)` calculé comme en CSS (la ligne passe
//   par le centre et atteint exactement les coins), reflet `inset 0 1px 0`
//   (28 %), bord de 1 px (18 %). Il ne sert plus qu'à la barre de
//   navigation, seul objet flottant de l'app.
// - **Pastille** : le disque de couleur d'un domaine, pictogramme noir au
//   centre.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/rhythm_couleurs.dart';
import 'pictos.dart';

class PeintreVerre extends CustomPainter {
  const PeintreVerre({
    required this.rayon,
    required this.angle,
    required this.couleurs,
    required this.arrets,
  });

  final double rayon;

  /// En degrés, comme CSS : 0 = vers le haut, sens horaire.
  final double angle;
  final List<Color> couleurs;
  final List<double> arrets;

  @override
  void paint(Canvas canvas, Size size) {
    final boite = Offset.zero & size;
    final contour = RRect.fromRectAndRadius(boite, Radius.circular(rayon));

    // La ligne du dégradé à la CSS : direction de l'angle (0° = vers le
    // haut, sens horaire), longueur telle que les coins reçoivent 0 et 100 %.
    final a = angle * math.pi / 180;
    final direction = Offset(math.sin(a), -math.cos(a));
    final longueur =
        (size.width * math.sin(a)).abs() + (size.height * math.cos(a)).abs();
    final centre = boite.center;
    canvas.drawRRect(
      contour,
      Paint()
        ..shader = ui.Gradient.linear(
          centre - direction * (longueur / 2),
          centre + direction * (longueur / 2),
          couleurs,
          arrets,
        ),
    );

    // Le reflet (`inset 0 1px 0`) : sous le bord, la bande de 1 px que la
    // boîte intérieure décalée d'un pixel vers le bas ne couvre plus.
    final interieur = contour.deflate(1);
    canvas.save();
    canvas.clipRRect(interieur);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRRect(interieur),
        Path()..addRRect(interieur.shift(const Offset(0, 1))),
      ),
      Paint()..color = RhythmCouleurs.refletVerre,
    );
    canvas.restore();

    canvas.drawRRect(
      contour.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = RhythmCouleurs.bordVerre,
    );
  }

  @override
  bool shouldRepaint(PeintreVerre ancien) =>
      ancien.rayon != rayon ||
      ancien.angle != angle ||
      ancien.couleurs != couleurs ||
      ancien.arrets != arrets;
}

/// Pastille ronde d'un domaine, pictogramme noir au centre (tuiles, verset,
/// série).
class Pastille extends StatelessWidget {
  const Pastille({
    super.key,
    required this.picto,
    required this.couleur,
    this.taille = 32,
    this.taillePicto = 17,
  });

  final Picto picto;
  final Color couleur;
  final double taille;
  final double taillePicto;

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
    child: PictoRhythm(
      picto,
      taille: taillePicto,
      couleur: RhythmCouleurs.noir,
      epaisseur: 2,
    ),
  );
}

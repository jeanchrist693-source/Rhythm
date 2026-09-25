// lib/ecrans/sports/pieces_sports.dart
//
// Les pièces communes des écrans Sports, dans la langue sans cartes de
// Rhythm (`filets.dart`) : la miniature d'un exercice (son corps, figé à
// mi-mouvement), la ligne d'un exercice, deux segments en capsule, une
// statistique, les points du niveau, un minuteur en anneau.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/sports/exercices.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/corps/figure_exercice.dart';
import '../../widgets/filets.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';

/// Le corps d'un exercice, figé à mi-mouvement (listes) ou animé (fiche,
/// séance). CADRÉ, il prend la largeur [taille] et la hauteur que le
/// mouvement occupe vraiment (au plus [hauteurMax]) : un exercice couché
/// devient large et bas, donc plus grand.
class FigureDe extends StatelessWidget {
  const FigureDe(
    this.exercice, {
    super.key,
    this.taille = 56,
    this.animer = false,
    this.cadree = false,
    this.hauteurMax = double.infinity,
  });

  final ExerciceSport exercice;
  final double taille;
  final bool animer;
  final bool cadree;
  final double hauteurMax;

  @override
  Widget build(BuildContext context) {
    final animation = animationDe(exercice);
    final cadre = cadree ? cadreDe(animation) : null;
    final figure = ExcludeSemantics(
      child: FigureExercice(
        animation: animation,
        animer: animer,
        instant: 0.5,
        cadre: cadre,
        principaux: exercice.principaux.toSet(),
        secondaires: exercice.secondaires.toSet(),
      ),
    );
    if (cadre == null) return SizedBox.square(dimension: taille, child: figure);
    return SizedBox(
      width: taille,
      height: math.min(hauteurMax, taille * cadre.height / cadre.width),
      child: figure,
    );
  }
}

/// Les trois points du niveau (1, 2 ou 3 pleins).
class PointsNiveau extends StatelessWidget {
  const PointsNiveau(this.niveau, {super.key});

  final Niveau niveau;

  @override
  Widget build(BuildContext context) => Semantics(
    label: niveau.libelle(context.tr),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= niveau.index
                  ? RhythmCouleurs.corail
                  : RhythmCouleurs.pastilleVide,
            ),
          ),
        ],
      ],
    ),
  );
}

/// La ligne d'un exercice : son corps en miniature, son nom, un détail
/// (muscles, dosage) ; à droite, ce qu'on veut. Filet au-dessus.
class LigneExercice extends StatelessWidget {
  const LigneExercice({
    super.key,
    required this.exercice,
    required this.detail,
    this.onTap,
    this.droite,
    this.filet = true,
    this.titre,
    this.surtitre,
  });

  final ExerciceSport exercice;
  final String detail;
  final VoidCallback? onTap;
  final Widget? droite;
  final bool filet;

  /// Un nom à la place de celui de l'exercice.
  final String? titre;

  /// Une petite mention au-dessus du nom (« A1 · Enchaîné »).
  final String? surtitre;

  @override
  Widget build(BuildContext context) {
    final ligne = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          FigureDe(exercice),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (surtitre != null) ...[
                  Text(
                    surtitre!,
                    style: RhythmTypo.texte(
                      11,
                      poids: 600,
                      couleur: RhythmCouleurs.corail,
                      espacement: 0.04,
                    ),
                  ),
                  const SizedBox(height: 1),
                ],
                Text(
                  titre ?? exercice.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RhythmTypo.texte(15, poids: 500),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RhythmTypo.petit,
                ),
              ],
            ),
          ),
          if (droite != null) ...[const SizedBox(width: 10), droite!],
        ],
      ),
    );
    return Column(
      children: [
        if (filet) const Filet(),
        if (onTap == null)
          ligne
        else
          Semantics(
            button: true,
            child: PressionEchelle(onTap: onTap, echelle: 0.98, child: ligne),
          ),
      ],
    );
  }
}

/// « Pectoraux, triceps · Haltères » : le détail d'un exercice dans une
/// liste.
String detailExercice(ExerciceSport e, AppLocalizations tr) {
  final muscles = e.principaux.map((m) => m.libelle(tr)).join(', ');
  final materiel = e.materiel.isEmpty
      ? tr.sansMateriel
      : e.materiel.map((m) => m.libelle(tr)).join(', ');
  return '$muscles · $materiel';
}

/// Deux (ou trois) segments dans une capsule : le choisi est blanc.
class Segments2<T> extends StatelessWidget {
  const Segments2({
    super.key,
    required this.options,
    required this.valeur,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T valeur;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: RhythmCouleurs.capsule,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (v, libelle) in options)
          Semantics(
            button: true,
            selected: v == valeur,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (v == valeur) return;
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == valeur ? RhythmCouleurs.blanc : null,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  libelle,
                  style: RhythmTypo.texte(
                    13,
                    poids: 600,
                    couleur: v == valeur
                        ? RhythmCouleurs.noir
                        : RhythmCouleurs.texte72,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Une statistique : le libellé au-dessus, le chiffre en dessous.
class StatSport extends StatelessWidget {
  const StatSport({
    super.key,
    required this.libelle,
    required this.valeur,
    this.couleur = RhythmCouleurs.texte,
    this.detail,
  });

  final String libelle;
  final String valeur;
  final Color couleur;
  final String? detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(libelle, style: RhythmTypo.petit, maxLines: 1),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          valeur,
          maxLines: 1,
          style: RhythmTypo.titre(22, couleur: couleur),
        ),
      ),
      if (detail != null) ...[
        const SizedBox(height: 2),
        Text(detail!, style: RhythmTypo.petit, maxLines: 2),
      ],
    ],
  );
}

/// Un minuteur en anneau : l'arc qui se vide, le temps au centre.
class AnneauMinuteur extends StatelessWidget {
  const AnneauMinuteur({
    super.key,
    required this.progression,
    required this.couleur,
    required this.centre,
    this.taille = 220,
    this.epaisseur = 8,
  });

  /// 1 → 0 (ce qui reste).
  final double progression;
  final Color couleur;
  final Widget centre;
  final double taille;
  final double epaisseur;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: taille,
    child: CustomPaint(
      painter: _PeintreMinuteur(progression, couleur, epaisseur),
      child: Center(child: centre),
    ),
  );
}

class _PeintreMinuteur extends CustomPainter {
  _PeintreMinuteur(this.progression, this.couleur, this.epaisseur);

  final double progression;
  final Color couleur;
  final double epaisseur;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - epaisseur / 2;
    final c = size.center(Offset.zero);
    final trait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = epaisseur
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, trait..color = RhythmCouleurs.piste);
    final p = progression.clamp(0.0, 1.0);
    if (p <= 0.001) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * p,
      false,
      trait..color = couleur,
    );
  }

  @override
  bool shouldRepaint(_PeintreMinuteur a) =>
      a.progression != progression || a.couleur != couleur;
}

/// Un petit pictogramme cerclé (tuile d'activité, ligne de réglage).
class PictoCercle extends StatelessWidget {
  const PictoCercle(
    this.picto, {
    super.key,
    this.couleur = RhythmCouleurs.corail,
    this.taille = 40,
  });

  final Picto picto;
  final Color couleur;
  final double taille;

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: RhythmCouleurs.cocheVide, width: 1.5),
    ),
    child: PictoRhythm(
      picto,
      taille: taille * 0.45,
      epaisseur: 2,
      couleur: couleur,
    ),
  );
}

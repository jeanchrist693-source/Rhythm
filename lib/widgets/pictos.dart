// lib/widgets/pictos.dart
//
// Les pictogrammes de la maquette, dessinés depuis leurs tracés SVG recopiés
// tels quels (grille de 24, bouts et jonctions arrondis). L'épaisseur se
// donne dans la grille, comme en SVG : 1,8 dans la barre et l'en-tête, 2 dans
// les pastilles, 2,6 pour la coche d'une habitude.

import 'package:flutter/widgets.dart';

import '../theme/rhythm_couleurs.dart';
import 'chemin_svg.dart';

enum Picto {
  maison,
  haltere,
  couverts,
  cocheCercle,
  livre,
  cloche,
  fleche,
  flamme,
  goutte,
  coche,
  // Ajoutés avec les habitudes (tracés Lucide, même grille de 24).
  plus,
  moins,
  retour,
  chevron,
  crayon,
  telephone,
  vague,
  epingle,
  // Ajoutés avec les sports (tracés Lucide, même grille de 24).
  recherche,
  chrono,
  graphique,
  trophee,
  lecture,
  pause,
  stop,
  reglages,
  croix,
  balance,
  eclair,
  velo,
  traces,
  calendrier,
  suivant,
  corps,
  repete,
  liste,
  // Ajoutés avec les achats (tracés Lucide, même grille de 24).
  panier,
  frigo,
  poubelle,
}

const Map<Picto, List<String>> _traces = {
  Picto.maison: [
    'M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1Z',
  ],
  Picto.haltere: ['M6 7v10', 'M18 7v10', 'M3 10v4', 'M21 10v4', 'M6 12h12'],
  Picto.couverts: [
    'M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2',
    'M7 2v20',
    'M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7',
  ],
  // <circle cx="12" cy="12" r="9"> écrit en deux demi-arcs.
  Picto.cocheCercle: [
    'M21 12a9 9 0 1 1-18 0a9 9 0 1 1 18 0',
    'm8.5 12 2.5 2.5 4.5-5',
  ],
  Picto.livre: [
    'M2 4h6a4 4 0 0 1 4 4v13a3 3 0 0 0-3-3H2z',
    'M22 4h-6a4 4 0 0 0-4 4v13a3 3 0 0 1 3-3h7z',
  ],
  Picto.cloche: [
    'M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9',
    'M10.3 21a1.94 1.94 0 0 0 3.4 0',
  ],
  Picto.fleche: ['M5 12h14', 'm13 6 6 6-6 6'],
  Picto.flamme: [
    'M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.07-2.14-.22-4.05 2-6 '
        '.5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.15.43-2.29 '
        '1-3a2.5 2.5 0 0 0 2.5 2.5z',
  ],
  Picto.goutte: [
    'M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 '
        '6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z',
  ],
  Picto.coche: ['m6 12 4 4 8-8'],
  Picto.plus: ['M12 5v14', 'M5 12h14'],
  Picto.moins: ['M5 12h14'],
  Picto.retour: ['m15 18-6-6 6-6'],
  Picto.chevron: ['m9 18 6-6-6-6'],
  Picto.crayon: [
    'M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83'
        'l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z',
    'm15 5 4 4',
  ],
  Picto.telephone: [
    'M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 '
        '1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 '
        '1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 '
        '0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 '
        '0 1 22 16.92z',
  ],
  Picto.epingle: [
    'M12 17v5',
    'M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 '
        '1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 '
        '10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1z',
  ],
  Picto.recherche: ['M19 11a8 8 0 1 1-16 0a8 8 0 1 1 16 0', 'm21 21-4.34-4.34'],
  Picto.chrono: [
    'M10 2h4',
    'm12 14 3-3',
    'M20 14a8 8 0 1 1-16 0a8 8 0 1 1 16 0',
  ],
  Picto.graphique: [
    'M3 3v16a2 2 0 0 0 2 2h16',
    'M18 17V9',
    'M13 17V5',
    'M8 17v-3',
  ],
  Picto.trophee: [
    'M6 9H4.5a2.5 2.5 0 0 1 0-5H6',
    'M18 9h1.5a2.5 2.5 0 0 0 0-5H18',
    'M4 22h16',
    'M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22',
    'M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22',
    'M18 2H6v7a6 6 0 0 0 12 0V2Z',
  ],
  Picto.lecture: [
    'M7 4.5v15a.5.5 0 0 0 .77.42l11.5-7.5a.5.5 0 0 0 0-.84L7.77 4.08A.5.5 0 0 0 7 4.5z',
  ],
  Picto.pause: ['M8 5v14', 'M16 5v14'],
  Picto.stop: [
    'M7 5h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z',
  ],
  Picto.reglages: [
    'M21 4h-7',
    'M10 4H3',
    'M21 12h-9',
    'M8 12H3',
    'M21 20h-5',
    'M12 20H3',
    'M14 2v4',
    'M8 10v4',
    'M16 18v4',
  ],
  Picto.croix: ['M18 6 6 18', 'm6 6 12 12'],
  Picto.balance: [
    'm16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z',
    'm2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z',
    'M7 21h10',
    'M12 3v18',
    'M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2',
  ],
  Picto.eclair: [
    'M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 '
        '0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92'
        '-6.02A1 1 0 0 0 11 14z',
  ],
  Picto.velo: [
    'M22 17.5a3.5 3.5 0 1 1-7 0a3.5 3.5 0 1 1 7 0',
    'M9 17.5a3.5 3.5 0 1 1-7 0a3.5 3.5 0 1 1 7 0',
    'M16 5a1 1 0 1 1-2 0a1 1 0 1 1 2 0',
    'M12 17.5V14l-3-3 4-3 2 3h2',
  ],
  Picto.traces: [
    'M4 16v-2.38C4 11.5 2.97 10.5 3 8c.03-2.72 1.49-6 4.5-6C9.37 2 10 3.8 '
        '10 5.5c0 3.11-2 5.66-2 8.68V16a2 2 0 1 1-4 0Z',
    'M20 20v-2.38c0-2.12 1.03-3.12 1-5.62-.03-2.72-1.49-6-4.5-6C14.63 6 14 '
        '7.8 14 9.5c0 3.11 2 5.66 2 8.68V20a2 2 0 1 0 4 0Z',
    'M16 17h4',
    'M4 13h4',
  ],
  Picto.calendrier: [
    'M8 2v4',
    'M16 2v4',
    'M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z',
    'M3 10h18',
  ],
  Picto.suivant: ['M5 4.5v15l10-7.5z', 'M19 5v14'],
  Picto.corps: [
    'M13 5a1 1 0 1 1-2 0a1 1 0 1 1 2 0',
    'm9 20 3-6 3 6',
    'm6 8 6 2 6-2',
    'M12 10v4',
  ],
  Picto.repete: [
    'M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8',
    'M3 3v5h5',
  ],
  Picto.liste: [
    'M3 6h.01',
    'M3 12h.01',
    'M3 18h.01',
    'M8 6h13',
    'M8 12h13',
    'M8 18h13',
  ],
  Picto.panier: [
    'M9 21a1 1 0 1 1-2 0a1 1 0 1 1 2 0',
    'M20 21a1 1 0 1 1-2 0a1 1 0 1 1 2 0',
    'M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57'
        'l1.65-7.43H5.12',
  ],
  Picto.frigo: [
    'M5 6a4 4 0 0 1 4-4h6a4 4 0 0 1 4 4v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6Z',
    'M5 10h14',
    'M15 7v6',
  ],
  Picto.poubelle: [
    'M3 6h18',
    'M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6',
    'M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2',
  ],
  Picto.vague: [
    'M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 '
        '1.3 0 1.9.5 2.5 1',
    'M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 '
        '1.3 0 1.9.5 2.5 1',
    'M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 '
        '1.3 0 1.9.5 2.5 1',
  ],
};

class PictoRhythm extends StatelessWidget {
  const PictoRhythm(
    this.picto, {
    super.key,
    this.taille = 22,
    this.couleur = RhythmCouleurs.texte,
    this.epaisseur = 1.8,
  });

  final Picto picto;
  final double taille;
  final Color couleur;

  /// Épaisseur du trait dans la grille de 24.
  final double epaisseur;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: taille,
    child: CustomPaint(painter: _Peintre(picto, couleur, epaisseur)),
  );
}

class _Peintre extends CustomPainter {
  _Peintre(this.picto, this.couleur, this.epaisseur);

  final Picto picto;
  final Color couleur;
  final double epaisseur;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final trait = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = epaisseur
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final d in _traces[picto]!) {
      canvas.drawPath(cheminSvg(d), trait);
    }
  }

  @override
  bool shouldRepaint(_Peintre ancien) =>
      ancien.picto != picto ||
      ancien.couleur != couleur ||
      ancien.epaisseur != epaisseur;
}

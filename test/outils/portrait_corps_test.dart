// test/outils/portrait_corps_test.dart
//
// Banc d'essai du DÉTAIL du corps — PAS un vrai test. Rend un mouvement en
// GRAND, à un instant, sous plusieurs angles de caméra, et en gros plan sur
// une région (la tête, une main, un genou) : pour juger le visage, les
// cheveux, les mains, les plis des articulations, le modelé des muscles.
//
//   flutter test --dart-define=CAPTURES=<dossier> test/outils/portrait_corps_test.dart
//
// [MOUVEMENTS] (ids, « squat » par défaut), [INSTANT] (0..1, 0 par défaut —
// en pour mille : 500 = 0,5), [TAILLE] (900 px), [LACETS] (angles de caméra
// séparés par des virgules ; sinon celui du mouvement), [ZOOM] (tete, haut,
// mains, pieds ou corps).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/widgets/corps/animations_corps.dart';
import 'package:rhythm/widgets/corps/corps_humain.dart';
import 'package:rhythm/widgets/corps/figure_exercice.dart';
import 'package:rhythm/widgets/corps/peau3.dart';
import 'package:rhythm/widgets/corps/peintre3.dart';
import 'package:rhythm/widgets/corps/squelette3.dart';

const String _dossier = String.fromEnvironment('CAPTURES');
const String _filtre = String.fromEnvironment('MOUVEMENTS');
const String _lacets = String.fromEnvironment('LACETS');
const String _zoom = String.fromEnvironment('ZOOM', defaultValue: 'corps');
const String _principaux = String.fromEnvironment('PRINCIPAUX');

class _Portrait extends CustomPainter {
  _Portrait(this.anim, this.instant, this.camera, this.zoom);

  final AnimCorps anim;
  final double instant;
  final Camera3 camera;
  final String zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final s = Squelette3.de(anim.pose(instant));
    // La région à montrer, en coordonnées d'écran du carré 0..1.
    final pts = switch (zoom) {
      'tete' => [s.tete, s.cou],
      'visage' => [s.tete],
      'haut' => [s.tete, s.bassin, s.brasP.milieu, s.brasL.milieu],
      'mains' => [
        s.brasP.bout,
        s.brasP.bout + (s.brasP.extremite - s.brasP.bout) * 2.8,
      ],
      'epaule' => [s.brasP.racine, s.cou],
      'bassin' => [s.jambeP.racine, s.jambeL.racine, s.bassin],
      'pieds' => [s.talonP, s.jambeP.extremite, s.jambeP.bout],
      _ => s.points,
    };
    var r = Rect.fromCenter(
      center: camera.projeter(pts.first),
      width: 0,
      height: 0,
    );
    for (final p in pts) {
      r = r.expandToInclude(
        Rect.fromCenter(center: camera.projeter(p), width: 0, height: 0),
      );
    }
    final marge = switch (zoom) {
      'tete' => 0.07,
      'visage' => 0.06,
      'mains' => const int.fromEnvironment('MARGE', defaultValue: 30) / 1000,
      'epaule' => 0.05,
      'bassin' => 0.08,
      'pieds' => 0.06,
      _ => 0.09,
    };
    r = r.inflate(marge);
    final cote = size.shortestSide / r.longestSide;
    canvas.translate(
      (size.width - r.width * cote) / 2 - r.left * cote,
      (size.height - r.height * cote) / 2 - r.top * cote,
    );
    PeintreCorps3(
      cote: cote,
      camera: camera,
      principaux: _principaux.isEmpty
          ? const {}
          : {for (final n in _principaux.split(',')) Muscle.values.byName(n)},
    ).peindre(canvas, s, anim.accessoires);
  }

  @override
  bool shouldRepaint(_Portrait ancien) => true;
}

void main() {
  testWidgets('portraits', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    Peau3.debogage = const bool.fromEnvironment('DEBOGAGE');
    Peau3.contour = const int.fromEnvironment('CONTOUR', defaultValue: 0) / 100;
    final ids = _filtre.isEmpty ? ['squat'] : _filtre.split(',');
    const taille = 0.0 + int.fromEnvironment('TAILLE', defaultValue: 900);
    const instant = int.fromEnvironment('INSTANT', defaultValue: 0) / 1000;
    for (final id in ids) {
      final anim = Mouvements.de(id)!;
      final cameras = _lacets.isEmpty
          ? [anim.camera]
          : [
              for (final l in _lacets.split(','))
                Camera3(lacet: double.parse(l), tangage: anim.camera.tangage),
            ];
      tester.view.physicalSize = Size(taille * cameras.length, taille);
      tester.view.devicePixelRatio = 1;
      final cle = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: cle,
            child: ColoredBox(
              color: Colors.black,
              child: Row(
                children: [
                  for (final c in cameras)
                    SizedBox.square(
                      dimension: taille,
                      child: CustomPaint(
                        painter: _Portrait(anim, instant, c, _zoom),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final rendu =
          cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await rendu.toImage();
        final octets = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_dossier/portrait_${id}_$_zoom.png',
        ).writeAsBytesSync(octets!.buffer.asUint8List());
      });
    }
    tester.view.reset();
  });
}

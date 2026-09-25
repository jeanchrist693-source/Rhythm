// test/outils/mascottes_test.dart
//
// Banc d'essai des mascottes — PAS un vrai test. Rend les quatre personnages
// côte à côte, image par image (30 i/s pendant [_duree]), et écrit les PNG
// dans le dossier passé par `CAPTURES` ; ffmpeg en fait ensuite une vidéo
// pour juger du MOUVEMENT (une capture fixe ne dit rien d'une animation) :
//
//   flutter test --dart-define=CAPTURES=<dossier> test/outils/mascottes_test.dart
//   ffmpeg -framerate 30 -i <dossier>/m_%03d.png -pix_fmt yuv420p mascottes.mp4

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/widgets/mascottes.dart';

const String _dossier = String.fromEnvironment('CAPTURES');
const Duration _duree = Duration(milliseconds: 8000);
const int _images = 30 * 8;

void main() {
  testWidgets('les mascottes, image par image', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    tester.view.physicalSize = const Size(4 * 120 * 3, 100 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final cle = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: cle,
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final m in Mascotte.values)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: MascotteAnimee(m),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final pas = _duree ~/ _images;
    for (var i = 0; i < _images; i++) {
      await tester.pump(pas);
      final rendu =
          cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await rendu.toImage(pixelRatio: 3);
        final octets = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_dossier/m_${i.toString().padLeft(3, '0')}.png',
        ).writeAsBytesSync(octets!.buffer.asUint8List());
      });
    }
  });
}

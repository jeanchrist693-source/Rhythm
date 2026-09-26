// test/outils/grille_corps_test.dart
//
// Banc d'essai — PAS un vrai test. Une GRILLE d'exercices (ou de
// mouvements), chacun à SON instant : pour juger d'un coup d'œil les poses
// que `collisions_corps_test.dart` signale (« chenille@875,pigeon@125 »).
//
//   flutter test --dart-define=CAPTURES=<dossier> --dart-define=PAIRES=id@‰,id@‰ test/outils/grille_corps_test.dart
//
// Un id d'exercice du catalogue est rendu avec son matériel ; [TAILLE]
// (300) : le côté d'une case.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/modele/sports/catalogue.dart';
import 'package:rhythm/widgets/corps/animations_corps.dart';
import 'package:rhythm/widgets/corps/figure_exercice.dart';

import 'polices.dart';

const String _dossier = String.fromEnvironment('CAPTURES');
const String _paires = String.fromEnvironment('PAIRES');
const int _taille = int.fromEnvironment('TAILLE', defaultValue: 300);

void main() {
  testWidgets('une grille de poses', (tester) async {
    if (_dossier.isEmpty || _paires.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=… et PAIRES=…');
      return;
    }
    await chargerPolices();
    final paires = [
      for (final p in _paires.split(','))
        (p.split('@')[0], int.parse(p.split('@')[1]) / 1000),
    ];
    const parRangee = 4;
    final rangees = (paires.length / parRangee).ceil();
    tester.view.physicalSize = Size(
      _taille * parRangee * 1.0,
      (_taille + 18.0) * rangees,
    );
    tester.view.devicePixelRatio = 1;
    final cle = GlobalKey();
    AnimCorps anim(String id) =>
        Mouvements.de(id) ?? animationDe(Catalogue.de(id)!);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: cle,
          child: ColoredBox(
            color: Colors.black,
            child: Wrap(
              children: [
                for (final (id, t) in paires)
                  SizedBox(
                    width: _taille * 1.0,
                    height: _taille + 18.0,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 18,
                          child: Text(
                            '$id ${(t * 1000).round()}',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: _taille * 1.0,
                          child: FigureExercice(
                            animation: anim(id),
                            animer: false,
                            instant: t,
                            cadre: cadreDe(anim(id)),
                          ),
                        ),
                      ],
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
        '$_dossier/grille.png',
      ).writeAsBytesSync(octets!.buffer.asUint8List());
    });
    tester.view.reset();
  });
}

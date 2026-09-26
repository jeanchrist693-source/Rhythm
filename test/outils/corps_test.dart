// test/outils/corps_test.dart
//
// Banc d'essai des CORPS en mouvement — PAS un vrai test. Rend chaque
// mouvement de `animations_corps.dart` à cinq instants de son cycle, deux
// mouvements par rangée, seize par planche PNG, pour juger les poses, les
// trajectoires et le volume du corps :
//
//   flutter test --dart-define=CAPTURES=<dossier> test/outils/corps_test.dart
//
// [MOUVEMENTS] (liste d'ids séparés par des virgules) restreint la planche ;
// [EXERCICES] rend plutôt des exercices du CATALOGUE, avec LEUR matériel
// (`animationDe` : kettlebell, barre, sans charge…) — des ids, « tous », ou
// « charges » (ceux qui tiennent quelque chose) ;
// [INSTANTS] (5 par défaut) et [TAILLE] (100) règlent le détail ;
// [PRINCIPAUX] et [SECONDAIRES] (noms de muscles, ou « tous ») choisissent
// les muscles teintés.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/modele/sports/catalogue.dart';
import 'package:rhythm/widgets/corps/animations_corps.dart';
import 'package:rhythm/widgets/corps/corps_humain.dart';
import 'package:rhythm/widgets/corps/figure_exercice.dart';
import 'package:rhythm/widgets/corps/silhouette.dart';

import 'polices.dart';

const String _dossier = String.fromEnvironment('CAPTURES');
const String _filtre = String.fromEnvironment('MOUVEMENTS');
const String _exercices = String.fromEnvironment('EXERCICES');

/// Les animations à rendre, par libellé : des exercices du catalogue
/// ([EXERCICES]) ou des mouvements ([MOUVEMENTS], tous par défaut).
Map<String, AnimCorps> _animations() {
  if (_exercices.isNotEmpty) {
    final liste = switch (_exercices) {
      'tous' => Catalogue.tous,
      'charges' => [
        for (final e in Catalogue.tous)
          if (animationDe(e).accessoires.tientUneCharge ||
              animationDe(e).accessoires.elastique != null ||
              animationDe(e).accessoires.bandeMains)
            e,
      ],
      _ => [for (final id in _exercices.split(',')) Catalogue.de(id)!],
    };
    return {for (final e in liste) '${e.id} (${e.mouvement})': animationDe(e)};
  }
  final ids = _filtre.isEmpty
      ? Mouvements.tous.keys.toList()
      : _filtre.split(',');
  return {for (final id in ids) id: Mouvements.de(id)!};
}

const String _principaux = String.fromEnvironment('PRINCIPAUX');
const String _secondaires = String.fromEnvironment('SECONDAIRES');

Set<Muscle> _muscles(String noms, Set<Muscle> sinon) => noms.isEmpty
    ? sinon
    : noms == 'tous'
    ? Muscle.values.toSet()
    : {for (final n in noms.split(',')) Muscle.values.byName(n)};

void main() {
  testWidgets('les corps, pose par pose', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await chargerPolices();
    final animations = _animations();
    final ids = animations.keys.toList();
    const cote = 0.0 + int.fromEnvironment('TAILLE', defaultValue: 100);
    const n = int.fromEnvironment('INSTANTS', defaultValue: 5);
    final instants = [for (var i = 0; i < n; i++) i / n];
    const parRangee = n > 5 ? 1 : 2;
    const parPlanche = 16;
    final largeur = cote * instants.length * parRangee + 12;

    Widget cellule(String id) => SizedBox(
      width: cote * instants.length,
      child: Column(
        children: [
          SizedBox(
            height: 16,
            child: Text(
              id,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              for (final t in instants)
                SizedBox.square(
                  dimension: cote,
                  child: FigureExercice(
                    animation: animations[id]!,
                    animer: false,
                    instant: t,
                    cadre: cadreDe(animations[id]!),
                    principaux: _muscles(_principaux, const {
                      Muscle.quadriceps,
                      Muscle.pectoraux,
                      Muscle.dos,
                    }),
                    secondaires: _muscles(_secondaires, const {
                      Muscle.fessiers,
                      Muscle.epaules,
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    for (var lot = 0; lot * parPlanche < ids.length; lot++) {
      final partie = ids.skip(lot * parPlanche).take(parPlanche).toList();
      final rangees = (partie.length / parRangee).ceil();
      tester.view.physicalSize = Size(largeur * 2, (cote + 16) * rangees * 2);
      tester.view.devicePixelRatio = 2;
      final cle = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: cle,
            child: ColoredBox(
              color: Colors.black,
              child: Column(
                children: [
                  for (var r = 0; r < rangees; r++)
                    Row(
                      children: [
                        for (
                          var c = 0;
                          c < parRangee && r * parRangee + c < partie.length;
                          c++
                        ) ...[
                          if (c > 0) const SizedBox(width: 12),
                          cellule(partie[r * parRangee + c]),
                        ],
                      ],
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
        final image = await rendu.toImage(pixelRatio: 2);
        final octets = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_dossier/corps_$lot.png',
        ).writeAsBytesSync(octets!.buffer.asUint8List());
      });
    }
    tester.view.reset();
  });

  testWidgets('les silhouettes des muscles', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    tester.view.physicalSize = const Size(1440, 740);
    tester.view.devicePixelRatio = 2;
    final cle = GlobalKey();
    const corail = Color(0xFFFF8A7A);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: cle,
          child: ColoredBox(
            color: Colors.black,
            child: Row(
              children: [
                for (final cote in CoteSilhouette.values) ...[
                  const SizedBox(width: 20),
                  SizedBox(width: 150, child: SilhouetteMuscles(cote: cote)),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 150,
                    child: SilhouetteMuscles(
                      cote: cote,
                      couleurs: {
                        for (final m in Muscle.values)
                          if (m.index.isEven) m: corail,
                      },
                      hachures: const {Muscle.quadriceps, Muscle.dos},
                    ),
                  ),
                ],
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
      final image = await rendu.toImage(pixelRatio: 2);
      final octets = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '$_dossier/silhouettes.png',
      ).writeAsBytesSync(octets!.buffer.asUint8List());
    });
    tester.view.reset();
  });
}

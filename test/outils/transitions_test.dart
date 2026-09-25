// test/outils/transitions_test.dart
//
// Les TRANSITIONS vers les écrans secondaires, image par image — PAS un vrai
// test (même méthode que `captures_test.dart`) : depuis chaque section
// principale, l'aller (fondu-glissement de 550 ms) et le retour, filmés à
// 0, 60, 140, 240, 340, 440, 550 et 700 ms, animations réelles (mascottes
// comprises). Juger une transition = la regarder.
//
//   flutter test --dart-define=CAPTURES=C:/chemin/sortie test/outils/transitions_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/widgets/pictos.dart';
import 'package:rhythm/widgets/scene_ouverture.dart';

import 'polices.dart';

const String _dossier = String.fromEnvironment('CAPTURES');

const _instants = [0, 60, 140, 240, 340, 440, 550, 700];

Future<void> _capturer(WidgetTester tester, String nom) async {
  final element = find.byType(MaterialApp).evaluate().first;
  await tester.runAsync(() async {
    final image = await captureImage(element);
    final octets = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_dossier/$nom.png').writeAsBytesSync(octets!.buffer.asUint8List());
  });
}

/// Filme ce qui suit un toucher, aux [_instants].
Future<void> _filmer(WidgetTester tester, String nom) async {
  var t = 0;
  for (final (i, ms) in _instants.indexed) {
    await tester.pump(Duration(milliseconds: ms - t));
    t = ms;
    await _capturer(tester, '${nom}_$i');
  }
  // Le verrou contre les doubles appuis (550 ms) relâché.
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _picto(Picto p) =>
    find.byWidgetPredicate((w) => w is PictoRhythm && w.picto == p).last;

Future<void> _demarrer(WidgetTester tester) async {
  await initializeDateFormatting();
  await chargerPolices();
  tester.view.physicalSize = const Size(384, 832) * 1.5;
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final base = BaseAliments.analyser(
    File('assets/donnees/fcen.txt').readAsStringSync(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24, 17, 30)),
        horlogeProvider.overrideWithValue(() => DateTime(2026, 9, 24, 17, 30)),
        baseAlimentsProvider.overrideWith((ref) async => base),
      ],
      child: const RhythmApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1600));
}

void main() {
  // Le mode cuisine : une étape à minuteur → une étape sans (le chili, 2 →
  // 3), puis → une étape à minuteur (3 → 4). Le texte, le minuteur et la
  // liste des étapes doivent bouger ENSEMBLE. Imprime aussi la hauteur de
  // « TOUTES LES ÉTAPES » image par image.
  testWidgets("changement d'étape du mode cuisine", (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await _demarrer(tester);
    Future<void> toucher(Finder f) async {
      await tester.ensureVisible(f.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(f.first);
      // Une image d'abord : l'écran poussé naît « hors scène » (sa première
      // image), puis sa transition.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
    }

    for (final onglet in [Picto.maison, Picto.couverts]) {
      await tester.tap(_picto(onglet));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
    await toucher(find.text('Mes recettes'));
    await toucher(find.text('Chili sin carne'));
    await toucher(find.text('Cuisiner'));
    await tester.drag(
      find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
      const Offset(0, -560),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('Suivante'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (final nom in ['etape_2_3', 'etape_3_4']) {
      await tester.tap(find.text('Suivante'));
      var t = 0;
      for (final (i, ms) in [0, 40, 80, 130, 180, 230, 280, 400].indexed) {
        await tester.pump(Duration(milliseconds: ms - t));
        t = ms;
        final y = tester.getTopLeft(find.text('TOUTES LES ÉTAPES')).dy;
        debugPrint('$nom $ms ms : liste à ${y.toStringAsFixed(1)}');
        await _capturer(tester, '${nom}_$i');
      }
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('transitions vers les écrans secondaires', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await initializeDateFormatting();
    await chargerPolices();
    tester.view.physicalSize = const Size(384, 832) * 1.5;
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final base = BaseAliments.analyser(
      File('assets/donnees/fcen.txt').readAsStringSync(),
    );
    SceneOuverture.reinitialiser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24, 17, 30)),
          horlogeProvider.overrideWithValue(
            () => DateTime(2026, 9, 24, 17, 30),
          ),
          baseAlimentsProvider.overrideWith((ref) async => base),
        ],
        child: const RhythmApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));

    final cas = <(Picto, Finder, String)>[
      (Picto.maison, find.bySemanticsLabel('Rappels'), 'accueil_rappels'),
      (Picto.haltere, find.text('Exercices'), 'sports_banque'),
      (Picto.couverts, find.text('Mes recettes'), 'alim_recettes'),
      (Picto.couverts, find.text('Ma semaine'), 'alim_semaine'),
      (Picto.couverts, find.text('Liste de courses'), 'alim_courses'),
      (Picto.cocheCercle, find.text('Nouvelle habitude'), 'hab_nouvelle'),
    ];
    for (final (onglet, cible, nom) in cas) {
      await tester.tap(_picto(onglet));
      await tester.pump(const Duration(milliseconds: 600));
      if (cible.evaluate().isEmpty) {
        debugPrint('introuvable : $nom');
        continue;
      }
      await tester.ensureVisible(cible.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(cible.first);
      await _filmer(tester, '${nom}_aller');
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is PictoRhythm && w.picto == Picto.retour,
            )
            .first,
      );
      await _filmer(tester, '${nom}_retour');
      expect(tester.takeException(), isNull, reason: nom);
    }
  });
}

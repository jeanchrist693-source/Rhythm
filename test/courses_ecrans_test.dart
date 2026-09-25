// test/courses_ecrans_test.dart
//
// Les ACHATS parcourus au doigt (démonstration) : l'onglet Alimentation
// montre ce qui est à consommer bientôt ; la liste de courses (ajout
// fusionné, habituels) ; au magasin, un article au panier (prix, taxe), la
// caisse en direct, « Terminer » en deux temps ; le rangement guidé ; le
// garde-manger et la fiche d'un aliment (fini → réassort) — sans
// débordement, au format du téléphone et sur un petit écran.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/courses.dart';
import 'package:rhythm/modele/alimentation/etat_courses.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/widgets/pictos.dart';

import 'outils/polices.dart';

final DateTime _auj = DateTime(2026, 9, 24, 8);
final BaseAliments _base = BaseAliments.analyser(
  File('assets/donnees/fcen.txt').readAsStringSync(),
);

Future<ProviderContainer> _demarrer(
  WidgetTester tester, {
  Size taille = const Size(384, 832),
}) async {
  await initializeDateFormatting();
  await chargerPolices();
  tester.view.physicalSize = taille * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final conteneur = ProviderContainer(
    overrides: [
      aujourdhuiProvider.overrideWithValue(_auj),
      horlogeProvider.overrideWithValue(() => _auj),
      baseAlimentsProvider.overrideWith((ref) async => _base),
    ],
  );
  addTearDown(conteneur.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: conteneur, child: const RhythmApp()),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.couverts)
        .last,
  );
  await tester.pumpAndSettle();
  return conteneur;
}

Future<void> _naviguer(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await _naviguer(tester);
}

void main() {
  testWidgets('la liste, le magasin, la caisse, le rangement', (tester) async {
    final c = await _demarrer(tester);
    // L'onglet : à consommer bientôt, et la porte de la liste.
    expect(find.text('À CONSOMMER BIENTÔT'), findsOneWidget);
    await _toucher(tester, find.text('Liste de courses'));
    expect(find.text('Liste de courses'), findsWidgets);

    // Un ajout fusionné : les bananes étaient déjà là (6).
    await tester.enterText(find.byType(TextField).first, '3 bananes');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final bananes = c
        .read(coursesProvider)
        .liste
        .where((a) => a.nom == 'Bananes')
        .toList();
    expect(bananes, hasLength(1));
    expect(bananes.single.quantites, const [Quantite(9)]);

    // Un nouvel article, le rayon deviné.
    await tester.enterText(find.byType(TextField).first, '2 kg carottes');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final carottes = c
        .read(coursesProvider)
        .liste
        .firstWhere((a) => a.nom == 'Carottes');
    expect(carottes.rayon, Rayon.legumes);
    expect(carottes.quantites, const [Quantite(2, Unite.kg)]);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Au magasin.
    await _toucher(tester, find.text('Au magasin'));
    expect(find.text('Total à la caisse'), findsOneWidget);
    await _toucher(tester, find.text('Croustilles').first);
    // La taxe proposée : TPS + TVQ.
    expect(
      find.text(
        'Grignotines, bonbons, chocolat, boissons gazeuses : '
        'TPS et TVQ.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, '4,49');
    await tester.pumpAndSettle();
    await _toucher(tester, find.textContaining('Au panier ·'));
    final panier = c
        .read(coursesProvider)
        .liste
        .firstWhere((a) => a.nom == 'Croustilles')
        .panier!;
    expect(panier.prix, 4.49);
    expect(panier.statut.name, 'tpsTvq');
    // La caisse : 4,49 + TPS 0,22 + TVQ 0,45 = 5,16 $.
    expect(find.text('5,16 \$'), findsOneWidget);

    // Terminer, en deux temps, puis ranger.
    await tester.tap(find.text('Terminer'));
    await tester.pump();
    await tester.tap(find.text('Toucher encore'));
    await _naviguer(tester);
    expect(find.text('Ranger'), findsWidgets);
    expect(c.read(coursesProvider).achats, hasLength(9));
    final avant = c.read(coursesProvider).gardeManger.length;
    await _toucher(tester, find.text('Ranger 1 aliment'));
    expect(c.read(coursesProvider).gardeManger.length, avant + 1);
    final rangees = c
        .read(coursesProvider)
        .gardeManger
        .firstWhere((a) => a.nom == 'Croustilles');
    expect(rangees.emplacement, Emplacement.armoire);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le garde-manger : fini → revient sur la liste', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Garde-manger').last);
    expect(find.text('Épinards'), findsOneWidget);
    await _toucher(tester, find.text('Yogourt grec'));
    expect(find.text('Comment le garder'.toUpperCase()), findsOneWidget);
    await _toucher(tester, find.text("C'est fini"));
    final etat = c.read(coursesProvider);
    expect(etat.gardeManger.any((a) => a.nom == 'Yogourt grec'), isFalse);
    // Essentiel : revenu sur la liste.
    final yogourt = etat.liste.firstWhere((a) => a.nom == 'Yogourt grec');
    expect(yogourt.origines, [kOrigineReassort]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('petit écran : liste, magasin, panier, garde-manger, taxes', (
    tester,
  ) async {
    await _demarrer(tester, taille: const Size(360, 740));
    await _toucher(tester, find.text('Liste de courses'));
    await _toucher(tester, find.text('Au magasin'));
    await _toucher(tester, find.text('Poitrines de poulet').first);
    expect(find.text('Au poids'), findsOneWidget);
    await _toucher(
      tester,
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );
    await _toucher(
      tester,
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );
    await _toucher(tester, find.text('Les taxes du Québec'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

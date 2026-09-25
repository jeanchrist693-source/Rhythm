// test/sports_ecrans_test.dart
//
// Les écrans des Sports, parcourus au doigt : la silhouette qui choisit les
// zones, « Compléter », l'aperçu, la séance guidée jusqu'à l'enregistrement
// (le journal grandit, l'habitude « Entraînement » est cochée), la banque et
// sa recherche, une fiche — sans débordement, au format du téléphone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/modele/calculs_habitudes.dart';
import 'package:rhythm/modele/etat_habitudes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/sports/etat_sport.dart';
import 'package:rhythm/modele/sports/muscles.dart';
import 'package:rhythm/utils/dates.dart';
import 'package:rhythm/widgets/corps/silhouette.dart';
import 'package:rhythm/widgets/pictos.dart';

import 'outils/polices.dart';

final DateTime _auj = DateTime(2026, 9, 24, 8);

Future<ProviderContainer> _demarrer(WidgetTester tester) async {
  await initializeDateFormatting();
  await chargerPolices();
  tester.view.physicalSize = const Size(384, 832) * 3;
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
    ],
  );
  addTearDown(conteneur.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: conteneur, child: const RhythmApp()),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.haltere)
        .last,
  );
  await tester.pumpAndSettle();
  return conteneur;
}

/// Après une navigation : la transition finie ET son verrou relâché.
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
  testWidgets('constructeur → aperçu → séance guidée → journal', (
    tester,
  ) async {
    final c = await _demarrer(tester);
    final avant = c.read(sportProvider).journal.length;
    // L'habitude « Entraînement » pas encore cochée aujourd'hui.
    final h = c.read(habitudesProvider).parId('hab-entrainement')!;
    if (estFaite(h, jourDe(_auj))) {
      c.read(habitudesProvider.notifier).basculer(h.id, jourDe(_auj));
    }

    await _toucher(tester, find.text('Créer une séance'));
    expect(find.text('Nouvelle séance'), findsWidgets);

    // Les pectoraux, touchés sur la silhouette.
    final silhouette = find.byType(SilhouetteMuscles);
    final zone = tester.getRect(silhouette);
    final muscle = SilhouetteMuscles.muscleEn(
      CoteSilhouette.face,
      const Offset(40, 42),
    );
    expect(muscle, Muscle.pectoraux);
    await tester.tapAt(
      zone.topLeft + Offset(40 * zone.width / 100, 42 * zone.width / 100),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pectoraux'), findsWidgets);

    await _toucher(tester, find.text('Compléter'));
    await _toucher(tester, find.text("Voir l'aperçu"));
    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Séries par muscle'.toUpperCase()), findsOneWidget);

    await _toucher(tester, find.text('Commencer').first);
    // L'échauffement se passe ; la première série se fait.
    for (var i = 0; i < 8; i++) {
      if (find.text('Série faite').evaluate().isNotEmpty) break;
      await tester.tap(find.text("Passer l'exercice"));
      await tester.pumpAndSettle();
    }
    expect(find.text('Série faite'), findsOneWidget);
    await tester.tap(find.text('Série faite'));
    await tester.pumpAndSettle();
    expect(find.text('Repos'), findsOneWidget);
    await tester.tap(find.text('Difficile'));
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    // Arrêter : garder ce qui est fait, puis enregistrer.
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.croix)
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer ce qui est fait'));
    await tester.pumpAndSettle();
    expect(find.text('Séance terminée'), findsOneWidget);
    await tester.tap(find.text('Soutenu'));
    await tester.pumpAndSettle();
    await _toucher(tester, find.text('Enregistrer'));

    final journal = c.read(sportProvider).journal;
    expect(journal.length, avant + 1);
    final s = journal.last;
    expect(s.exercices.where((e) => e.series.isNotEmpty), isNotEmpty);
    expect(s.ressenti, 3);
    expect(
      s.exercices.expand((e) => e.series).any((x) => x.ressenti != null),
      isTrue,
    );
    expect(
      estFaite(
        c.read(habitudesProvider).parId('hab-entrainement')!,
        jourDe(_auj),
      ),
      isTrue,
    );
    expect(
      find.text('Semaine 39'),
      findsOneWidget,
      reason: 'retour aux Sports',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la banque : recherche, filtre, fiche', (tester) async {
    await _demarrer(tester);
    await _toucher(tester, find.text('Exercices'));
    await tester.enterText(find.byType(TextField).first, 'pompes');
    await tester.pumpAndSettle();
    expect(find.text('Pompes diamant'), findsOneWidget);
    await tester.tap(find.text('Sans matériel'));
    await tester.pumpAndSettle();
    expect(find.text('Pompes inclinées'), findsNothing, reason: 'une chaise');
    await _toucher(tester, find.text('Pompes').first);
    expect(find.text('ÉTAPES'), findsOneWidget);
    await _toucher(tester, find.text('Pompes déclinées'));
    expect(find.text('Tu es ici'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une routine express s’enchaîne seule', (tester) async {
    final c = await _demarrer(tester);
    final avant = c.read(sportProvider).journal.length;
    await _toucher(tester, find.text('Avant de dormir'));
    expect(find.text('Démarrer'), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      if (find.text('Séance terminée').evaluate().isNotEmpty) break;
      await tester.tap(find.text("Passer l'exercice"));
      await tester.pumpAndSettle();
    }
    expect(find.text('Séance terminée'), findsOneWidget);
    await _toucher(tester, find.text('Enregistrer'));
    expect(c.read(sportProvider).journal.length, avant + 1);
  });
}

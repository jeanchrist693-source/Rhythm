// test/recettes_ecrans_test.dart
//
// Les RECETTES parcourues au doigt (démonstration) : le livre, une recette,
// le mode cuisine (mise en place, minuteur, étapes) jusqu'à « C'est prêt »
// (journal, restes) ; écrire une recette (un ingrédient de la base, des
// étapes aux minuteurs repérés) ; ma semaine (prévoir un souper, la liste
// de la semaine, la cuisine en lot) ; noter des restes d'un toucher — sans
// débordement, au format du téléphone et sur un petit écran.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/ecrans/alimentation/pieces_alimentation.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/courses.dart';
import 'package:rhythm/modele/alimentation/etat_alimentation.dart';
import 'package:rhythm/modele/alimentation/etat_courses.dart';
import 'package:rhythm/modele/alimentation/etat_recettes.dart';
import 'package:rhythm/modele/alimentation/recettes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/modeles.dart';
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

Future<void> _retour(WidgetTester tester) => _toucher(
  tester,
  find
      .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
      .first,
);

void main() {
  testWidgets('une recette, le mode cuisine, « C\'est prêt »', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Mes recettes'));
    expect(find.text('8 recettes'), findsOneWidget);
    await _toucher(tester, find.text('Chili sin carne'));
    expect(find.text('Cuisiner'), findsOneWidget);
    expect(find.text('INGRÉDIENTS'), findsOneWidget);

    await _toucher(tester, find.text('Cuisiner'));
    expect(find.text('Mode cuisine'), findsOneWidget);
    // La mise en place se coche.
    await _toucher(tester, find.text('Oignon'));
    expect(find.text('MISE EN PLACE · 1 SUR 8'), findsOneWidget);
    // Le minuteur de l'étape 1 (5 minutes), puis on l'arrête.
    await tester.ensureVisible(find.text('Minuteur 5 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minuteur 5 min'));
    await tester.pump();
    expect(c.read(minuteursProvider).single.duree, const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel('Arrêter le minuteur'));
    await tester.pump();
    expect(c.read(minuteursProvider), isEmpty);
    await tester.pumpAndSettle();

    // Les étapes, une à une, jusqu'à « C'est prêt ».
    for (var i = 0; i < 3; i++) {
      await _toucher(tester, find.text('Suivante'));
    }
    expect(find.text('ÉTAPE 4 SUR 4'), findsOneWidget);
    await _toucher(tester, find.text("C'est prêt"));
    expect(find.text('Bon appétit !'), findsOneWidget);

    final avant = c.read(alimentationProvider).entreesDu(_auj).length;
    await _toucher(tester, find.text('Enregistrer'));
    // Une portion au journal, trois en restes (au congélateur : un lot de
    // 4 portions qui se congèle).
    final entrees = c.read(alimentationProvider).entreesDu(_auj);
    expect(entrees.length, avant + 1);
    expect(entrees.last.source, SourceEntree.recette);
    expect(entrees.last.recetteId, 'depart-chili');
    final restes = c
        .read(coursesProvider)
        .gardeManger
        .firstWhere((a) => a.recetteId == 'depart-chili');
    expect(restes.quantite, const Quantite(3));
    expect(restes.emplacement, Emplacement.congelateur);
    expect(restes.nom, 'Chili sin carne (restes)');
    // De retour sur la fiche : ses restes s'y lisent.
    expect(find.textContaining('Restes : 3 portions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('écrire une recette : un ingrédient de la base, des étapes', (
    tester,
  ) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Mes recettes'));
    await _toucher(tester, find.text('Nouvelle recette'));
    await tester.enterText(find.byType(TextField).first, 'riz aux lentilles');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await _toucher(tester, find.text('Ajouter un ingrédient'));
    await tester.enterText(find.byType(TextField).first, 'riz');
    await tester.pumpAndSettle();
    await _toucher(tester, find.textContaining('riz blanc').first);
    expect(find.text('Ajouter à la recette'), findsOneWidget);
    await _toucher(tester, find.text('Ajouter à la recette'));

    // De retour au formulaire : l'ingrédient, puis les étapes.
    await tester.enterText(
      find.byType(TextField).at(1),
      '1. Rincer le riz.\n2. Cuire 18 minutes à couvert.',
    );
    await tester.pumpAndSettle();
    expect(find.text('2 étapes · minuteurs : 18 min'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _toucher(tester, find.text('Enregistrer'));

    final r = c
        .read(recettesProvider)
        .recettes
        .firstWhere((x) => x.nom == 'Riz aux lentilles');
    expect(r.ingredients.single.source, SourceIngredient.base);
    expect(r.parPortion.kcal, greaterThan(0));
    expect(r.etapes, ['Rincer le riz.', 'Cuire 18 minutes à couvert.']);
    // La fiche a pris la place du formulaire.
    expect(find.text('Cuisiner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ma semaine : prévoir, la liste de la semaine, le lot', (
    tester,
  ) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Ma semaine'));
    expect(find.text('13 repas prévus'), findsOneWidget);
    // Le souper d'aujourd'hui : prévoir le saumon.
    await _toucher(tester, find.bySemanticsLabel('Prévoir le souper'));
    await _toucher(tester, find.text('Saumon et patates douces'));
    final prevus = c.read(recettesProvider).prevusLe(_auj, MomentRepas.souper);
    expect(prevus.single.recetteId, 'depart-saumon');
    expect(find.text('Saumon et patates douces'), findsOneWidget);

    // La cuisine en lot : le chili revient trois fois.
    await _toucher(tester, find.text('Cuisine en lot'));
    expect(find.textContaining('3 repas'), findsWidgets);
    await _retour(tester);

    // La liste de la semaine → la liste de courses.
    await _toucher(tester, find.text('Liste de la semaine'));
    await _toucher(tester, find.textContaining('à la liste').last);
    final saumon = c
        .read(coursesProvider)
        .liste
        .firstWhere((a) => a.nom == 'Saumon');
    expect(saumon.origines, contains('Saumon et patates douces'));
    expect(find.text('Liste de courses'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('noter : une portion des restes, d\'un toucher', (tester) async {
    final c = await _demarrer(tester);
    c.read(coursesProvider.notifier).ranger([
      ArticleGardeManger(
        id: 'restes',
        nom: 'Chili sin carne (restes)',
        emplacement: Emplacement.frigo,
        rayon: Rayon.autre,
        entre: _auj,
        quantite: const Quantite(2),
        peremption: DateTime(2026, 9, 26),
        recetteId: 'depart-chili',
      ),
    ]);
    await tester.pumpAndSettle();
    await _toucher(tester, find.bySemanticsLabel('Ajouter un repas'));
    expect(find.text('LES RESTES'), findsOneWidget);
    // Le « + » de la ligne des restes (la première : un chili « entrée
    // rapide » est aussi dans les récents).
    await tester.tap(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('Chili sin carne'),
              matching: find.byType(LigneAliment),
            ),
            matching: find.byWidgetPredicate(
              (w) => w is PictoRhythm && w.picto == Picto.plus,
            ),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      c.read(coursesProvider).gardeManger.firstWhere((a) => a.restes).quantite,
      const Quantite(1),
    );
    expect(
      c.read(alimentationProvider).entreesDu(_auj).last.recetteId,
      'depart-chili',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('petit écran : livre, fiche, cuisine, semaine, formulaire', (
    tester,
  ) async {
    await _demarrer(tester, taille: const Size(360, 740));
    await _toucher(tester, find.text('Mes recettes'));
    await _toucher(tester, find.text('Pâté chinois'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await _toucher(tester, find.text('Cuisiner'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await _retour(tester);
    await _toucher(tester, find.text('Planifier'));
    await _retour(tester);
    await _retour(tester);
    await _toucher(tester, find.text('Ma semaine'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await _retour(tester);
    await _toucher(tester, find.text('Nouvelle recette'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

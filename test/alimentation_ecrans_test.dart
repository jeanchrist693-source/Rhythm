// test/alimentation_ecrans_test.dart
//
// L'Alimentation parcourue au doigt (démonstration = la maquette) : noter
// une banane depuis la recherche (la base du FCÉN), boire un verre, retirer
// un aliment puis « Comme hier », les objectifs (fixés à la main ↔
// calculés), un produit créé — sans débordement, au format du téléphone et
// sur un petit écran.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/etat_alimentation.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/modeles.dart';
import 'package:rhythm/utils/dates.dart';
import 'package:rhythm/widgets/formulaire.dart';
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

Finder get _retour =>
    find.byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour);

void main() {
  testWidgets('noter une banane depuis la recherche', (tester) async {
    final c = await _demarrer(tester);
    expect(find.text('560'), findsOneWidget);
    expect(find.text('520 kcal'), findsOneWidget);

    await _toucher(tester, find.bySemanticsLabel('Ajouter un repas'));
    expect(find.text('Noter un repas'), findsOneWidget);
    // 8 h : le déjeuner, déjà trois aliments.
    expect(find.text('Déjà 3 aliments · 520 kcal'), findsOneWidget);
    // Les récents, sans rien chercher.
    expect(find.text('RÉCENTS'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'banane');
    await tester.pumpAndSettle();
    await _toucher(tester, find.text('Banane, crue').first);
    // La portion « 1 moyen » d'abord : 118 g, 105 kcal.
    expect(find.text('1 moyen · 118 g'), findsOneWidget);
    expect(find.text('105'), findsOneWidget);

    await _toucher(tester, find.text('Ajouter au déjeuner'));
    expect(find.text('Noter un repas'), findsOneWidget);
    expect(find.text('Déjà 4 aliments · 625 kcal'), findsOneWidget);
    final auj = jourDe(_auj);
    final dejeuner = c
        .read(alimentationProvider)
        .entreesDu(auj, MomentRepas.dejeuner);
    expect(dejeuner.last.nom, 'Banane');
    expect(dejeuner.last.code, 1704);
    expect(dejeuner.last.grammes, 118);

    await _toucher(tester, _retour.first);
    expect(find.text('625 kcal'), findsOneWidget);
    expect(find.text('455'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un verre de plus, puis de moins', (tester) async {
    final c = await _demarrer(tester);
    expect(find.text('1,25 L sur 2 L'), findsOneWidget);
    final verres = find.byKey(const ValueKey('verres'));
    await tester.ensureVisible(verres);
    await tester.pumpAndSettle();
    final zone = tester.getRect(verres);
    // Le sixième verre (sur huit).
    await tester.tapAt(
      Offset(zone.left + zone.width * 5.5 / 8, zone.center.dy),
    );
    await tester.pumpAndSettle();
    expect(find.text('1,5 L sur 2 L'), findsOneWidget);
    expect(c.read(alimentationProvider).eauDu(_auj), 6);
    // Toucher le dernier verre plein le vide.
    await tester.tapAt(
      Offset(zone.left + zone.width * 5.5 / 8, zone.center.dy),
    );
    await tester.pumpAndSettle();
    expect(c.read(alimentationProvider).eauDu(_auj), 5);
  });

  testWidgets('retirer un aliment, puis « Comme hier »', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Dîner'));
    expect(find.text('Bol poulet, riz, légumes'), findsWidgets);

    await _toucher(tester, find.text('Bol poulet, riz, légumes').last);
    expect(find.text('Entrée rapide'), findsOneWidget);
    await _toucher(tester, find.text('Retirer du repas'));
    await _toucher(tester, find.text('Toucher encore pour retirer'));
    expect(find.text('Rien de noté pour ce repas.'), findsOneWidget);
    expect(
      c.read(alimentationProvider).entreesDu(_auj, MomentRepas.diner),
      isEmpty,
    );

    // Hier, un dîner : il se recopie d'un toucher.
    final commeHier = find.textContaining('Comme hier');
    await _toucher(tester, commeHier);
    expect(
      c.read(alimentationProvider).entreesDu(_auj, MomentRepas.diner),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('les objectifs : fixés à la main, puis calculés', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('560'));
    expect(find.text('Mes objectifs'), findsWidgets);
    expect(find.text('2 200'), findsWidgets);
    expect(find.text('Métabolisme de base'), findsOneWidget);

    final fixer = find.descendant(
      of: find
          .ancestor(
            of: find.text('Fixer mes objectifs moi-même'),
            matching: find.byType(Row),
          )
          .first,
      matching: find.byType(Interrupteur),
    );
    await tester.ensureVisible(fixer);
    await tester.pumpAndSettle();
    await tester.tap(fixer);
    await tester.pumpAndSettle();
    final b = c.read(besoinsProvider(jourDe(_auj)));
    expect(b.manuel, isFalse);
    expect(b.kcal, isNot(2200));
    // Le résumé suit : les objectifs calculés (« 2 480 »).
    final kcal = c.read(besoinsProvider(jourDe(_auj))).kcal;
    expect(
      find.text('${kcal ~/ 1000} ${(kcal % 1000).toString().padLeft(3, '0')}'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('un nouveau produit', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Mes produits'));
    await _toucher(tester, find.text('Nouveau produit'));
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), 'Céréales croquantes');
    await tester.enterText(champs.at(2), '1 tasse');
    await tester.enterText(champs.at(3), '40');
    await tester.enterText(champs.at(4), '150');
    await tester.enterText(champs.at(10), '4');
    await tester.pumpAndSettle();
    await _toucher(tester, find.text('Enregistrer'));
    final p = c
        .read(alimentationProvider)
        .produits
        .firstWhere((p) => p.nom == 'Céréales croquantes');
    expect(p.grammesPortion, 40);
    expect(p.parPortion.kcal, 150);
    expect(p.parPortion.proteines, 4);
    expect(find.text('Céréales croquantes'), findsOneWidget);
  });

  testWidgets('petit écran : noter, portion, objectifs sans débordement', (
    tester,
  ) async {
    await _demarrer(tester, taille: const Size(360, 740));
    await _toucher(tester, find.bySemanticsLabel('Ajouter un repas'));
    await tester.enterText(find.byType(TextField).first, 'yogourt grec');
    await tester.pumpAndSettle();
    await _toucher(tester, find.text('Yogourt grec nature 2 %').first);
    expect(find.text('Portions (175 g)'), findsOneWidget);
    await _toucher(tester, _retour.first);
    await _toucher(tester, _retour.first);
    await _toucher(tester, find.text('Mes objectifs'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

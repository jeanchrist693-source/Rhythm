// test/formulaire_test.dart
//
// Régressions des formulaires (retours de l'utilisateur, 24 sept. 2026) :
// - « Me libérer », toucher « Pourquoi » sélectionnait AUSSI « Mon plan » —
//   deux champs partageaient un focus quand le formulaire changeait de
//   forme ; le clavier se refermait aussitôt ;
// - l'heure du rappel : les minutes « avançaient sans cesse » et
//   l'incrément était faux (55 + 5 donnait 4) — remplacé par une roulette.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/ecrans/habitudes/habitude_formulaire_ecran.dart';
import 'package:rhythm/l10n/app_localizations.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/theme/rhythm_theme.dart';
import 'package:rhythm/widgets/formulaire.dart';

import 'outils/polices.dart';

Widget _cadre(Widget enfant) => ProviderScope(
  overrides: [aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24, 8))],
  child: MaterialApp(
    theme: RhythmTheme.sombre(),
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: enfant,
  ),
);

Future<void> _taille(WidgetTester tester) async {
  await initializeDateFormatting();
  await chargerPolices();
  tester.view.physicalSize = const Size(384, 832) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Iterable<EditableText> _focalises(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .where((e) => e.focusNode.hasFocus);

void main() {
  testWidgets('« Me libérer » : un toucher, un seul champ sélectionné', (
    tester,
  ) async {
    await _taille(tester);
    await tester.pumpWidget(_cadre(const HabitudeFormulaireEcran()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me libérer'));
    await tester.pumpAndSettle();

    final champ = find.ancestor(
      of: find.text('Ce qui compte vraiment pour moi'),
      matching: find.byType(ChampRhythm),
    );
    await tester.ensureVisible(champ);
    await tester.pumpAndSettle();
    await tester.tap(champ);
    await tester.pump(const Duration(milliseconds: 500));
    final focalises = _focalises(tester).toList();
    expect(focalises.length, 1);
    expect(tester.widget<ChampRhythm>(champ).focus!.hasFocus, isTrue);

    // Toucher le champ suivant : le focus passe, le clavier reste.
    final plan = find.ancestor(
      of: find.text('Quand je me lève, je prie 10 minutes.'),
      matching: find.byType(ChampRhythm),
    );
    await tester.ensureVisible(plan);
    await tester.pumpAndSettle();
    await tester.tap(plan);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_focalises(tester).length, 1);
    expect(tester.widget<ChampRhythm>(plan).focus!.hasFocus, isTrue);
  });

  testWidgets('la roulette de l’heure : des minutes de 5 en 5', (tester) async {
    await _taille(tester);
    int? choisi;
    await tester.pumpWidget(
      _cadre(
        Scaffold(
          body: Center(
            child: RouletteHeure(
              minutes: 22 * 60 + 55,
              onChanged: (m) => choisi = m,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('22'), findsWidgets);
    expect(find.text('55'), findsWidgets);
    // Une ligne plus bas sur les minutes : 55 → 00 (en boucle), l'heure ne
    // bouge pas.
    await tester.drag(find.text('55').first, const Offset(0, -44));
    await tester.pumpAndSettle();
    expect(choisi, 22 * 60);
  });

  testWidgets('− / + en boucle : 55 + 5 = 0, 0 − 5 = 55', (tester) async {
    await _taille(tester);
    var valeur = 55;
    await tester.pumpWidget(
      _cadre(
        Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => CompteurRhythm(
                valeur: valeur,
                min: 0,
                max: 55,
                pas: 5,
                boucle: true,
                affichage: (v) => '$v',
                onChanged: (v) => setState(() => valeur = v),
              ),
            ),
          ),
        ),
      ),
    );
    final plus = find.byType(GestureDetector).last;
    await tester.tap(plus);
    await tester.pump();
    expect(valeur, 0);
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    expect(valeur, 55);
  });
}

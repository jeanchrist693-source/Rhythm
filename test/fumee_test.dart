// test/fumee_test.dart
//
// Parcours de fumée : l'accueil (jeudi 24 septembre 2026, la date de la
// maquette), les cinq onglets par la barre et par les tuiles, une habitude
// cochée qui se retrouve sur l'accueil — sans débordement, au format du
// téléphone comme sur un petit écran. Puis les habitudes vivantes : la
// fiche, le soutien d'une envie, une nouvelle habitude, les rappels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/modele/depot.dart';
import 'package:rhythm/modele/etat_habitudes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/utils/dates.dart';
import 'package:rhythm/widgets/pictos.dart';

import 'outils/polices.dart';

Future<void> _demarrer(WidgetTester tester, Size taille, {Depot? depot}) async {
  await initializeDateFormatting();
  await chargerPolices();
  tester.view.physicalSize = taille * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  // Mascottes figées : sinon leurs horloges empêchent `pumpAndSettle`.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24, 8)),
        horlogeProvider.overrideWithValue(() => DateTime(2026, 9, 24, 8)),
        if (depot != null) depotProvider.overrideWithValue(depot),
      ],
      child: const RhythmApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _onglet(Picto picto) =>
    find.byWidgetPredicate((w) => w is PictoRhythm && w.picto == picto).last;

/// Le cercle d'une habitude (la ligne, elle, ouvre sa fiche).
Finder _coche(String nom) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.checked != null &&
      w.properties.label == nom,
);

/// Après une navigation : la transition finie ET son verrou relâché (les
/// animations réduites des tests la raccourcissent, pas le verrou de 550 ms
/// contre les doubles appuis — `navigation/transitions.dart`).
Future<void> _naviguer(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Le chevron « retour » d'un écran secondaire.
Finder get _retour =>
    find.byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour);

void main() {
  test('dates : semaine ISO et lundi', () {
    expect(numeroSemaine(DateTime(2026, 9, 24)), 39);
    expect(numeroSemaine(DateTime(2026, 1, 1)), 1);
    expect(numeroSemaine(DateTime(2027, 1, 1)), 53);
    expect(lundiDe(DateTime(2026, 9, 24)), DateTime(2026, 9, 21));
    expect(joursEntre(DateTime(2026, 9, 21), DateTime(2026, 9, 24)), 3);
  });

  test('la semaine de sport de la maquette (un jeudi)', () {
    final conteneur = ProviderContainer(
      overrides: [aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24))],
    );
    addTearDown(conteneur.dispose);
    final semaine = conteneur.read(semaineSportProvider);
    expect(semaine.minutes, [45, 0, 60, 42, null, null, null]);
    expect(semaine.total, 147);
    expect(semaine.seances, 3);
    expect(semaine.calories, 1180);
  });

  for (final taille in const [Size(384, 832), Size(360, 740)]) {
    testWidgets('parcours des cinq onglets (${taille.width.toInt()} dp)', (
      tester,
    ) async {
      await _demarrer(tester, taille);

      // L'accueil, valeurs de la maquette.
      expect(find.text('Bonjour'), findsOneWidget);
      expect(find.text('Jeudi 24 septembre'), findsOneWidget);
      expect(find.text('42 min'), findsOneWidget);
      expect(find.text('1 640 kcal'), findsOneWidget);
      expect(find.text('4 sur 6'), findsOneWidget);
      expect(find.text('Jean 3'), findsOneWidget);

      // Une tuile mène à son onglet.
      await tester.tap(find.text('42 min'));
      await tester.pumpAndSettle();
      expect(find.text('Semaine 39'), findsOneWidget);
      expect(find.text('147'), findsOneWidget);
      expect(find.text('1 180'), findsOneWidget);

      // La barre.
      await tester.tap(_onglet(Picto.couverts));
      await tester.pumpAndSettle();
      expect(find.text('560'), findsOneWidget);
      expect(find.text('1,25 L sur 2 L'), findsOneWidget);

      await tester.tap(_onglet(Picto.livre));
      await tester.pumpAndSettle();
      expect(find.text('Évangile selon Jean'), findsOneWidget);
      expect(find.text('Notes sur Jean 2'), findsOneWidget);

      // Cocher une habitude (son cercle) : l'en-tête, puis l'accueil,
      // suivent.
      await tester.tap(_onglet(Picto.cocheCercle));
      await tester.pumpAndSettle();
      expect(find.text('4 sur 6'), findsOneWidget);
      // Sur un petit écran, la dernière ligne est sous la barre flottante :
      // on la fait d'abord remonter.
      await tester.ensureVisible(_coche('Étirements'));
      await tester.pumpAndSettle();
      await tester.tap(_coche('Étirements'));
      await tester.pumpAndSettle();
      expect(find.text('5 sur 6'), findsOneWidget);

      await tester.tap(_onglet(Picto.maison));
      await tester.pumpAndSettle();
      expect(find.text('5 sur 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('le retour ramène à l’accueil avant de quitter', (tester) async {
    await _demarrer(tester, const Size(384, 832));
    await tester.tap(_onglet(Picto.haltere));
    await tester.pumpAndSettle();
    expect(find.text('Semaine 39'), findsOneWidget);
    final navigateur = tester.state<NavigatorState>(find.byType(Navigator));
    await navigateur.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Bonjour'), findsOneWidget);
  });

  // Régression (24 sept. 2026) : l'animation de bascule changeait la FORME
  // de l'arbre (enfant nu au repos, enveloppé pendant le fondu) — Flutter
  // recréait alors tous les onglets à chaque changement de section : les
  // mascottes repartaient de zéro, le défilement était perdu.
  testWidgets('changer de section garde chaque onglet vivant', (tester) async {
    // Petit écran : l'Alimentation y défile.
    await _demarrer(tester, const Size(360, 640));
    await tester.tap(_onglet(Picto.couverts));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    final etat = tester.state<ScrollableState>(find.byType(Scrollable).last);
    final defilement = etat.position.pixels;
    expect(defilement, greaterThan(0));

    await tester.tap(_onglet(Picto.haltere));
    await tester.pumpAndSettle();
    await tester.tap(_onglet(Picto.couverts));
    await tester.pumpAndSettle();

    final apres = tester.state<ScrollableState>(find.byType(Scrollable).last);
    expect(identical(apres, etat), isTrue, reason: 'onglet recréé');
    expect(apres.position.pixels, defilement);
  });

  testWidgets('habitudes : la fiche, puis le soutien d’une envie', (
    tester,
  ) async {
    await _demarrer(tester, const Size(384, 832));
    await tester.tap(_onglet(Picto.cocheCercle));
    await tester.pumpAndSettle();
    // La série de la maquette, sur un vrai historique.
    expect(find.text("12 jours d'affilée"), findsOneWidget);
    expect(find.text('Record personnel : 21 jours'), findsOneWidget);

    // La fiche : sa série, son historique, son plan.
    await tester.tap(find.text('Prière du matin'));
    await _naviguer(tester);
    expect(find.text('HISTORIQUE'), findsOneWidget);
    expect(find.text('35 j'), findsNWidgets(2));
    expect(find.text('MON PLAN'), findsOneWidget);
    await tester.tap(_retour);
    await _naviguer(tester);

    // Libération : « Envie ? » ouvre le soutien ; « J'ai tenu » le fête.
    await tester.scrollUntilVisible(
      find.text('Envie ?'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envie ?'));
    await _naviguer(tester);
    expect(find.text('Tiens bon'), findsOneWidget);
    expect(find.text('Inspire'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("J'ai tenu"),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("J'ai tenu"));
    await _naviguer(tester);
    expect(find.text('Bravo.'), findsOneWidget);
    expect(find.text('6 envies surmontées'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('habitudes : une nouvelle habitude, puis les rappels', (
    tester,
  ) async {
    await _demarrer(tester, const Size(384, 832));
    await tester.tap(_onglet(Picto.cocheCercle));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Nouvelle habitude'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle habitude'));
    await _naviguer(tester);
    await tester.enterText(find.byType(TextField).first, 'Marcher');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Enregistrer'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await _naviguer(tester);
    expect(find.text('4 sur 7'), findsOneWidget);
    expect(find.text('Marcher'), findsOneWidget);

    // La cloche de l'accueil : les rappels.
    await tester.tap(_onglet(Picto.maison));
    await tester.pumpAndSettle();
    expect(find.text('4 sur 7'), findsOneWidget);
    await tester.tap(_onglet(Picto.cloche));
    await _naviguer(tester);
    expect(find.text('Rappels'), findsOneWidget);
    expect(find.text('Bilan du soir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accueil : la libération, bien visible, et son soutien', (
    tester,
  ) async {
    await _demarrer(tester, const Size(384, 832));
    // Sous le bonjour : la section, le compteur (16 jours depuis la rechute
    // du 7 septembre à 21 h 30), le prochain palier.
    expect(find.text('LIBÉRATION'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
    expect(
      find.text('Boissons énergisantes · 10\u00a0h 30\u00a0min'),
      findsOneWidget,
    );
    expect(
      find.text('Prochain palier\u00a0: 3 semaines · dans 4\u00a0j 13\u00a0h'),
      findsOneWidget,
    );
    // « Envie ? » ouvre le soutien depuis l'accueil.
    await tester.ensureVisible(find.text('Envie ?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envie\u00a0?'));
    await _naviguer(tester);
    expect(find.text('Tiens bon'), findsOneWidget);
    await tester.tap(_retour);
    await _naviguer(tester);
    // La ligne ouvre la fiche.
    await tester.ensureVisible(find.text('16'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('16'));
    await _naviguer(tester);
    expect(find.text('JOURNAL DES ENVIES'), findsOneWidget);
    await tester.tap(_retour);
    await _naviguer(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accueil, premier lancement : une invitation à se libérer', (
    tester,
  ) async {
    final depot = Depot.memoire();
    addTearDown(depot.fermer);
    await _demarrer(tester, const Size(384, 832), depot: depot);
    expect(find.text('LIBÉRATION'), findsNothing);
    expect(find.text('0 sur 6'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("Me libérer d'une dépendance"),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Me libérer d'une dépendance"));
    await _naviguer(tester);
    // Le formulaire s'ouvre sur « Me libérer ».
    expect(find.text('Ce dont je me libère'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('habitudes : déplacer au doigt, puis trier par heure', (
    tester,
  ) async {
    await _demarrer(tester, const Size(384, 832));
    await tester.tap(_onglet(Picto.cocheCercle));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Étirements'));
    await tester.pumpAndSettle();
    double y(String nom) => tester.getTopLeft(find.text(nom)).dy;
    expect(y('Étirements'), greaterThan(y('Prière du matin')));

    // Un doigt posé sur la liste fait défiler la PAGE (la liste
    // réordonnable ne garde pas le geste pour elle).
    final avant = y('Étirements');
    await tester.drag(find.text("Boire 2 L d'eau"), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(y('Étirements'), greaterThan(avant + 60));
    await tester.ensureVisible(find.text('Étirements'));
    await tester.pumpAndSettle();

    // Maintenir « Étirements », le monter tout en haut.
    final geste = await tester.startGesture(
      tester.getCenter(find.text('Étirements')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 8; i++) {
      await geste.moveBy(const Offset(0, -45));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await geste.up();
    await tester.pumpAndSettle();
    expect(y('Étirements'), lessThan(y('Prière du matin')));

    // « Par heure » : l'ordre suit les rappels, plus rien à déplacer.
    await tester.tap(find.text('Par heure'));
    await tester.pumpAndSettle();
    expect(find.text('Maintiens une habitude pour la déplacer.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

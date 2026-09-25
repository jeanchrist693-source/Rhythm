// test/ia_ecrans_test.dart
//
// L'ASSISTANT parcouru au doigt (démonstration), avec un FAUX service d'IA
// (aucun réseau) qui répond comme Groq : des idées de recettes (région
// choisie) jusqu'au livre ; importer une recette collée ; estimer un repas
// → journal ; combler l'écart → journal ; planifier la semaine → Ma
// semaine ; remplacer un ingrédient ; la conservation d'un aliment hors du
// guide, apprise et gardée ; le bilan ; les erreurs (pas de réseau, pas de
// clé) — et rien de personnel dans ce qui part. Sans débordement, au
// format du téléphone et sur un petit écran.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/ecrans/alimentation/recettes/pieces_recettes.dart';
import 'package:rhythm/ia/service_ia.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/conservation.dart';
import 'package:rhythm/modele/alimentation/etat_alimentation.dart';
import 'package:rhythm/modele/alimentation/etat_courses.dart';
import 'package:rhythm/modele/alimentation/etat_recettes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/modeles.dart';
import 'package:rhythm/utils/dates.dart';
import 'package:rhythm/widgets/formulaire.dart';
import 'package:rhythm/widgets/pictos.dart';

import 'outils/faux_ia.dart';
import 'outils/polices.dart';

final DateTime _auj = DateTime(2026, 9, 24, 8);
final BaseAliments _base = BaseAliments.analyser(
  File('assets/donnees/fcen.txt').readAsStringSync(),
);

// ═══ Le parcours ═════════════════════════════════════════════════════════════

Future<ProviderContainer> _demarrer(
  WidgetTester tester, {
  Size taille = const Size(384, 832),
  FauxServiceIa? service,
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
  final precedent = ServiceIa.instance;
  ServiceIa.instance = service ?? FauxServiceIa();
  addTearDown(() => ServiceIa.instance = precedent);
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

Future<void> _assistant(WidgetTester tester) =>
    _toucher(tester, find.text('Assistant'));

void main() {
  testWidgets('des idées (région choisie) jusqu\'au livre', (tester) async {
    final service = FauxServiceIa();
    final c = await _demarrer(tester, service: service);
    await _assistant(tester);
    expect(find.text('Idées de recettes'), findsOneWidget);
    await _toucher(tester, find.text('Idées de recettes'));

    // La région, le moment, le genre, avant de générer.
    await _toucher(tester, find.text("Afrique de l'Ouest"));
    expect(find.text('Sénégalaise'), findsOneWidget);
    await _toucher(
      tester,
      find.descendant(
        of: find.byType(RangeePuces<MomentRepas?>),
        matching: find.text('Souper'),
      ),
    );
    await _toucher(tester, find.text('Soupe'));
    await _toucher(tester, find.text('Proposer 3 idées'));

    final demande = service.appels.single.last.contenu;
    expect(demande, contains("Afrique de l'Ouest"));
    expect(demande, contains('Sénégalaise, Ivoirienne'));
    expect(demande, contains('souper'));
    expect(demande, contains('une soupe'));

    expect(find.text('PROPOSITIONS'), findsOneWidget);
    expect(find.text('Poulet yassa'), findsOneWidget);
    // Hors de la région demandée : ramenée à la région choisie.
    expect(find.textContaining("Afrique de l'Ouest ·"), findsOneWidget);
    // Les calories par portion, calculées par la base.
    expect(find.textContaining('kcal'), findsWidgets);

    await _toucher(tester, find.text('Poulet yassa'));
    expect(find.text('Ajouter à mon livre'), findsOneWidget);
    expect(find.text('INGRÉDIENTS'), findsOneWidget);
    expect(find.text('Oignons'), findsOneWidget);
    await _toucher(tester, find.text('Ajouter à mon livre'));

    final r = c
        .read(recettesProvider)
        .recettes
        .firstWhere((r) => r.nom == 'Poulet yassa');
    expect(r.region, 'Sénégalaise');
    expect(r.moments, contains(MomentRepas.souper));
    expect(r.seCongele, isTrue);
    expect(r.ingredients.where((i) => !i.libre), hasLength(5));
    expect(r.parPortion.kcal, greaterThan(300));
    expect(r.etapes.first, startsWith('Mariner le poulet'));
    // La fiche : cuisiner, à la liste, planifier.
    expect(find.text('Cuisiner'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // De retour aux idées, elle est « Au livre ».
    await _toucher(
      tester,
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );
    expect(find.textContaining('Au livre'), findsOneWidget);
    // « Autres idées » ne repropose pas ce qui l'a été.
    await _toucher(tester, find.text('Autres idées'));
    expect(service.appels.last.last.contenu, contains('Poulet yassa'));
  });

  testWidgets('importer une recette collée', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Mes recettes'));
    await _toucher(tester, find.text('Importer une recette'));
    // Le presse-papiers d'Android, simulé.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (appel) async => appel.method == 'Clipboard.getData'
          ? <String, dynamic>{
              'text':
                  'Poulet yassa pour 4. 600 g de poulet, 3 oignons, 60 ml de '
                  'jus de citron. Mariner, dorer, mijoter 30 minutes.',
            }
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _toucher(tester, find.text('Coller'));
    expect(find.textContaining('600 g de poulet'), findsOneWidget);
    await _toucher(tester, find.text('Mettre en forme'));
    expect(find.text('Ajouter à mon livre'), findsOneWidget);
    await _toucher(tester, find.text('Ajouter à mon livre'));
    expect(
      c.read(recettesProvider).recettes.any((r) => r.nom == 'Poulet yassa'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('estimer un repas → journal', (tester) async {
    final c = await _demarrer(tester);
    await _assistant(tester);
    await _toucher(tester, find.text('Estimer un repas'));
    await tester.enterText(
      find.byType(EditableText).first,
      "Deux rôties au beurre d'arachide et une banane",
    );
    await _toucher(tester, find.text('Estimer'));
    expect(find.text('CE QUE JE COMPTE'), findsOneWidget);
    // L'aliment inconnu de la base n'est pas compté.
    expect(find.textContaining('· hors de la base'), findsOneWidget);
    // Retirer la banane.
    await _toucher(tester, find.text('Banane'));
    final avant = c.read(alimentationProvider).entreesDu(_auj).length;
    await _toucher(tester, find.text('Noter 2 aliments'));
    final entrees = c.read(alimentationProvider).entreesDu(_auj);
    expect(entrees.length, avant + 2);
    expect(entrees.last.source, SourceEntree.base);
    expect(entrees.last.moment, MomentRepas.dejeuner);
    expect(entrees.last.nutriments.kcal, greaterThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets("combler l'écart → journal", (tester) async {
    final c = await _demarrer(tester);
    await _assistant(tester);
    await _toucher(tester, find.text("Combler l'écart"));
    expect(find.text('restent pour aujourd\'hui'), findsOneWidget);
    await _toucher(tester, find.text('Des idées'));
    expect(find.text('Omelette et rôties'), findsOneWidget);
    expect(find.text('Le chili'), findsOneWidget);
    final avant = c.read(alimentationProvider).entreesDu(_auj).length;
    await _toucher(tester, find.text('Noter au journal').first);
    expect(c.read(alimentationProvider).entreesDu(_auj).length, avant + 2);
    expect(find.text('Noté'), findsOneWidget);
    // La recette du livre, une portion.
    await _toucher(tester, find.text('Noter au journal').first);
    final e = c.read(alimentationProvider).entreesDu(_auj).last;
    expect(e.recetteId, 'depart-chili');
    expect(tester.takeException(), isNull);
  });

  testWidgets('planifier la semaine → Ma semaine', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Ma semaine'));
    await _toucher(tester, find.text("Planifier avec l'IA"));
    await _toucher(tester, find.text('Proposer ma semaine'));
    // Le souper déjà prévu (le chili) n'est pas repris.
    expect(find.textContaining('Souper · Saumon et patates douces'), findsOne);
    expect(find.textContaining('Dîner · Bol poulet'), findsOneWidget);
    expect(find.textContaining('Chili sin carne'), findsNothing);
    // Décocher le bol, ajouter le saumon.
    await _toucher(tester, find.textContaining('Dîner · Bol poulet'));
    final avant = c.read(recettesProvider).plan.length;
    await _toucher(tester, find.text('Ajouter 1 repas à ma semaine'));
    final plan = c.read(recettesProvider).plan;
    expect(plan.length, avant + 1);
    final p = plan.firstWhere(
      (p) => p.jour == jourDe(_auj) && p.moment == MomentRepas.souper,
    );
    expect(p.recetteId, 'depart-saumon');
    expect(p.portions, 2);
    // Ma semaine s'ouvre.
    expect(find.text('Liste de la semaine'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remplacer un ingrédient', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Mes recettes'));
    await _toucher(tester, find.text('Omelette aux épinards'));
    await _toucher(tester, find.text('Remplacer un ingrédient'));
    await _toucher(tester, find.text('Cheddar'));
    await _toucher(tester, find.text('Plus léger'));
    await _toucher(tester, find.text('Remplacer « Cheddar »'));
    expect(find.text('Feta'), findsOneWidget);
    expect(find.text('Levure alimentaire'), findsOneWidget);
    expect(find.textContaining('Par portion'), findsNWidgets(2));
    await _toucher(tester, find.text('Remplacer').first);
    final r = c.read(recettesProvider).recette('depart-omelette')!;
    expect(r.ingredients.any((i) => i.nom == 'Cheddar'), isFalse);
    final feta = r.ingredients.firstWhere((i) => i.nom == 'Feta');
    expect(feta.grammes, 20);
    expect(feta.nutriments.kcal, greaterThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('conservation hors du guide : apprise, gardée', (tester) async {
    final c = await _demarrer(tester);
    await _toucher(tester, find.text('Garde-manger'));
    await _toucher(tester, find.text('Ajouter au garde-manger'));
    await tester.enterText(find.byType(EditableText).first, 'Attiéké');
    await tester.pumpAndSettle();
    expect(find.text('Comment le garder ?'), findsOneWidget);
    await _toucher(tester, find.text('Comment le garder ?'));
    expect(
      c.read(coursesProvider).conservations[cleConservation('Attiéké')]?.frigo,
      (3, 5),
    );
    expect(
      find.text('Au frigo, dans un contenant bien fermé.'),
      findsOneWidget,
    );
    expect(find.text("Repère de l'IA : vérifie aussi l'emballage."), findsOne);
    expect(find.text('Comment le garder ?'), findsNothing);
    await _toucher(tester, find.text('Ranger'));
    final a = c
        .read(coursesProvider)
        .gardeManger
        .firstWhere((a) => a.nom == 'Attiéké');
    expect(a.peremption, plusJours(jourDe(_auj), 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('le bilan : les chiffres, puis l\'avis', (tester) async {
    final service = FauxServiceIa();
    await _demarrer(tester, service: service);
    await _assistant(tester);
    await _toucher(tester, find.text('Bilan de la semaine'));
    expect(find.text('LES CHIFFRES'), findsOneWidget);
    expect(find.text('Journées notées'), findsOneWidget);
    expect(
      find.textContaining('Tu as noté presque tous tes repas : bravo'),
      findsOneWidget,
    );
    expect(
      find.text('Ajoute des légumineuses deux fois cette semaine.'),
      findsOneWidget,
    );
    // Rouvrir ne redemande rien.
    await _toucher(
      tester,
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );
    await _toucher(tester, find.text('Bilan de la semaine'));
    expect(service.appels, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('les erreurs : pas de réseau, pas de clé', (tester) async {
    await _demarrer(tester, service: FauxServiceIa(erreur: ErreurIa.reseau));
    await _assistant(tester);
    await _toucher(tester, find.text('Idées de recettes'));
    await _toucher(tester, find.text('Proposer 3 idées'));
    expect(find.textContaining('Pas de connexion Internet'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    ServiceIa.instance = FauxServiceIa(erreur: ErreurIa.sansCle);
    await _toucher(tester, find.text('Réessayer'));
    expect(find.textContaining("clé d'IA absente"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rien de personnel ne part', (tester) async {
    final service = FauxServiceIa();
    await _demarrer(tester, service: service);
    await _assistant(tester);
    await _toucher(tester, find.text('Bilan de la semaine'));
    await _toucher(
      tester,
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );
    await _toucher(tester, find.text("Combler l'écart"));
    await _toucher(tester, find.text('Des idées'));
    await _toucher(
      tester,
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );
    await _toucher(tester, find.text('Planifier ma semaine'));
    await _toucher(tester, find.text('Proposer ma semaine'));
    final tout = service.envoye;
    expect(service.appels, hasLength(3));
    // La libération de la démonstration, les habitudes, le poids.
    expect(tout, isNot(contains('énergisantes')));
    expect(tout, isNot(contains('Boire 2')));
    expect(tout, isNot(contains(' kg')));
  });

  testWidgets('petit écran : rien ne déborde', (tester) async {
    await _demarrer(tester, taille: const Size(360, 740));
    await _assistant(tester);
    await _toucher(tester, find.text('Idées de recettes'));
    await _toucher(tester, find.text('Proposer 3 idées'));
    await _toucher(tester, find.text('Poulet yassa'));
    expect(tester.takeException(), isNull);
    expect(find.byType(ChampRhythm), findsNothing);
  });
}

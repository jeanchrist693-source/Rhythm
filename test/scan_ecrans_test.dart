// test/scan_ecrans_test.dart
//
// Le SCAN d'un produit parcouru au doigt, avec un FAUX Open Food Facts (ni
// caméra ni réseau : les chiffres se tapent) : « Mes produits » → scanner →
// le formulaire pré-rempli → enregistré avec son code ; scanné de nouveau,
// retrouvé sans réseau ; depuis « Noter un repas », un produit inconnu créé
// à la main enchaîne sur sa portion ; un code incomplet, pas de réseau puis
// « Réessayer ».

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/ecrans/alimentation/scanner_ecran.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/etat_alimentation.dart';
import 'package:rhythm/modele/alimentation/nutriments.dart';
import 'package:rhythm/modele/alimentation/open_food_facts.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/modeles.dart';
import 'package:rhythm/systeme/open_food_facts.dart';
import 'package:rhythm/utils/dates.dart';
import 'package:rhythm/widgets/pictos.dart';

import 'outils/polices.dart';

final DateTime _auj = DateTime(2026, 9, 24, 8);
final BaseAliments _base = BaseAliments.analyser(
  File('assets/donnees/fcen.txt').readAsStringSync(),
);

const _nbsp = ' ';

/// Un faux Open Food Facts : il connaît une barre tendre, ou rien, ou n'est
/// pas joignable ; il compte les appels.
class _FauxOff extends ServiceOff {
  _FauxOff({this.connu = true, this.erreur});

  bool connu;
  ErreurOff? erreur;
  final List<String> appels = [];

  @override
  Future<BrouillonOff?> chercher(String code) async {
    appels.add(code);
    if (erreur case final e?) throw ExceptionOff(e);
    if (!connu) return null;
    return BrouillonOff(
      produit: Produit(
        id: '',
        nom: 'Barre tendre aux pépites',
        marque: 'Quaker',
        portion: '1 barre (24 g)',
        grammesPortion: 24,
        codeBarres: code,
        parPortion: const Nutriments(kcal: 101, proteines: 1.6),
      ),
      valeursConnues: true,
    );
  }
}

Future<ProviderContainer> _demarrer(WidgetTester tester, _FauxOff off) async {
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
  ScannerEcran.camera = false;
  addTearDown(() => ScannerEcran.camera = true);
  final avant = ServiceOff.instance;
  ServiceOff.instance = off;
  addTearDown(() => ServiceOff.instance = avant);
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

/// Tape le code et « Chercher ».
Future<void> _chercher(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField).first, code);
  await tester.pumpAndSettle();
  await _toucher(tester, find.text('Chercher'));
}

void main() {
  testWidgets('mes produits : scanné, pré-rempli, enregistré, retrouvé', (
    tester,
  ) async {
    final off = _FauxOff();
    final c = await _demarrer(tester, off);
    await _toucher(tester, find.text('Mes produits'));
    await _toucher(tester, find.text('Scanner un produit'));
    expect(find.text('Scanner un code-barres'), findsOneWidget);
    expect(
      find.textContaining('Seul le code est envoyé à Open Food Facts'),
      findsOneWidget,
    );

    await _chercher(tester, '0 12345 67890 5');
    expect(off.appels, ['0012345678905']);
    // Le formulaire, pré-rempli, à vérifier avec l'étiquette.
    expect(find.text('Nouveau produit'), findsOneWidget);
    expect(find.text('Barre tendre aux pépites'), findsOneWidget);
    expect(find.text('Quaker'), findsOneWidget);
    expect(find.text('Code-barres$_nbsp: 0 012345 678905'), findsOneWidget);
    expect(find.textContaining('Rempli par Open Food Facts'), findsOneWidget);

    await _toucher(tester, find.text('Enregistrer'));
    expect(find.text('Mes produits'), findsWidgets);
    final p = c
        .read(alimentationProvider)
        .produits
        .firstWhere((p) => p.nom == 'Barre tendre aux pépites');
    expect(p.codeBarres, '0012345678905');
    expect(p.parPortion.kcal, 101);

    // Scanné de nouveau : retrouvé sans réseau, sa fiche s'ouvre.
    await _toucher(tester, find.text('Scanner un produit'));
    await _chercher(tester, '012345678905');
    expect(off.appels, hasLength(1));
    expect(find.text('Modifier le produit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('noter un repas : inconnu, créé à la main, puis sa portion', (
    tester,
  ) async {
    final off = _FauxOff(connu: false);
    final c = await _demarrer(tester, off);
    await _toucher(tester, find.bySemanticsLabel('Ajouter un repas'));
    await _toucher(tester, find.text('Scanner un code-barres'));

    await _chercher(tester, '96385074');
    expect(
      find.text('Open Food Facts ne connaît pas ce produit.'),
      findsOneWidget,
    );
    await _toucher(tester, find.text('Le créer à la main'));
    expect(find.text('Code-barres$_nbsp: 9638 5074'), findsOneWidget);
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), 'Galettes de riz');
    await tester.enterText(champs.at(4), '35');
    await tester.pumpAndSettle();
    await _toucher(tester, find.text('Enregistrer'));

    // Enregistré, il s'ouvre à sa portion (8 h : le déjeuner).
    await _toucher(tester, find.text('Ajouter au déjeuner'));
    expect(find.text('Noter un repas'), findsOneWidget);
    final dejeuner = c
        .read(alimentationProvider)
        .entreesDu(jourDe(_auj), MomentRepas.dejeuner);
    expect(dejeuner.last.nom, 'Galettes de riz');
    expect(dejeuner.last.nutriments.kcal, 35);
    expect(
      c.read(alimentationProvider).produitDuCode('96385074')?.nom,
      'Galettes de riz',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('un code incomplet ; pas de réseau, puis « Réessayer »', (
    tester,
  ) async {
    final off = _FauxOff(erreur: ErreurOff.reseau);
    await _demarrer(tester, off);
    await _toucher(tester, find.text('Mes produits'));
    await _toucher(tester, find.text('Scanner un produit'));

    // Le toast ne dure pas : vu tout de suite après le toucher.
    await tester.enterText(find.byType(TextField).first, '12345');
    await tester.ensureVisible(find.text('Chercher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chercher'));
    await tester.pump();
    expect(find.textContaining('Ce code n\'est pas complet'), findsOneWidget);
    expect(off.appels, isEmpty);
    await tester.pumpAndSettle();

    await _chercher(tester, '3017620422003');
    expect(
      find.text(
        'Pas de connexion Internet$_nbsp: la recherche a besoin du réseau.',
      ),
      findsOneWidget,
    );
    off.erreur = null;
    await _toucher(tester, find.text('Réessayer'));
    expect(find.text('Barre tendre aux pépites'), findsOneWidget);
    expect(off.appels, ['3017620422003', '3017620422003']);
    expect(tester.takeException(), isNull);
  });
}

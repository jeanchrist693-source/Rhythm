// test/outils/captures_alimentation_test.dart
//
// Captures d'écran de l'ALIMENTATION hors appareil — PAS un vrai test (même
// méthode que `captures_test.dart`) : l'onglet vivant (haut et bas),
// noter un repas (récents, recherche), la portion, un repas, les
// objectifs, mes produits et un produit ; les achats ; les recettes (livre,
// fiche, mode cuisine, « C'est prêt », formulaire, ingrédient, ma semaine,
// cuisine en lot) — au format du S26 Ultra, au jeudi 24 septembre 2026 (la
// démonstration = la maquette).
//
//   flutter test --dart-define=CAPTURES=C:/chemin/sortie test/outils/captures_alimentation_test.dart

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

Future<void> _capturer(WidgetTester tester, String nom) async {
  final element = find.byType(MaterialApp).evaluate().first;
  await tester.runAsync(() async {
    final image = await captureImage(element);
    final octets = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_dossier/$nom.png').writeAsBytesSync(octets!.buffer.asUint8List());
  });
}

/// Une navigation : la transition, puis un temps (les mascottes tournent
/// sans fin).
Future<void> _laisser(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

Finder get _liste => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> _defiler(WidgetTester tester, double dy) async {
  await tester.drag(_liste, Offset(0, -dy));
  await _laisser(tester);
}

void main() {
  _capturesAchats();
  _capturesRecettes();
  testWidgets("captures de l'alimentation", (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await initializeDateFormatting();
    await chargerPolices();
    tester.view.physicalSize = const Size(384, 832) * 2;
    tester.view.devicePixelRatio = 2;
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
          aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24, 8)),
          horlogeProvider.overrideWithValue(() => DateTime(2026, 9, 24, 8)),
          baseAlimentsProvider.overrideWith((ref) async => base),
        ],
        child: const RhythmApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));

    Future<void> ouvrir(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await _laisser(tester);
    }

    Future<void> fermer() => ouvrir(
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );

    await tester.tap(
      find
          .byWidgetPredicate(
            (w) => w is PictoRhythm && w.picto == Picto.couverts,
          )
          .last,
    );
    await _laisser(tester);
    await _capturer(tester, 'a01_alimentation');
    await _defiler(tester, 500);
    await _capturer(tester, 'a02_alimentation_bas');
    await _defiler(tester, -2000);

    // Noter : récents et produits, puis une recherche.
    await ouvrir(find.bySemanticsLabel('Ajouter un repas'));
    await _capturer(tester, 'a03_noter');
    await _defiler(tester, 600);
    await _capturer(tester, 'a04_noter_bas');
    await _defiler(tester, -2000);
    await tester.enterText(find.byType(TextField).first, 'poulet');
    await _laisser(tester);
    await _capturer(tester, 'a05_recherche_poulet');
    await tester.enterText(find.byType(TextField).first, 'banane');
    await _laisser(tester);
    await ouvrir(find.text('Banane, crue').first);
    await _capturer(tester, 'a06_portion');
    await _defiler(tester, 600);
    await _capturer(tester, 'a07_portion_bas');
    await fermer();
    await fermer();

    // Un repas.
    await ouvrir(find.text('Déjeuner'));
    await _capturer(tester, 'a08_repas');
    await fermer();

    // Les objectifs.
    await ouvrir(find.text('560'));
    await _capturer(tester, 'a09_objectifs');
    await _defiler(tester, 700);
    await _capturer(tester, 'a10_objectifs_2');
    await _defiler(tester, 700);
    await _capturer(tester, 'a11_objectifs_3');
    await _defiler(tester, 900);
    await _capturer(tester, 'a12_objectifs_4');
    await fermer();

    // Mes produits, un produit.
    await ouvrir(find.text('Mes produits'));
    await _capturer(tester, 'a13_produits');
    await ouvrir(find.text('Barre protéinée'));
    await _capturer(tester, 'a14_produit');
    await _defiler(tester, 700);
    await _capturer(tester, 'a15_produit_bas');
    await fermer();
    await fermer();

    // L'entrée rapide.
    await ouvrir(find.text('Souper'));
    await ouvrir(find.text('Ajouter un aliment'));
    await _defiler(tester, 600);
    await ouvrir(find.text('Entrée rapide'));
    await _capturer(tester, 'a16_entree_rapide');
  });
}

void _capturesAchats() {
  testWidgets('captures des achats', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await initializeDateFormatting();
    await chargerPolices();
    tester.view.physicalSize = const Size(384, 832) * 2;
    tester.view.devicePixelRatio = 2;
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
          aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24, 8)),
          horlogeProvider.overrideWithValue(() => DateTime(2026, 9, 24, 8)),
          baseAlimentsProvider.overrideWith((ref) async => base),
        ],
        child: const RhythmApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));

    Future<void> ouvrir(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await _laisser(tester);
    }

    Future<void> fermer() => ouvrir(
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );

    await tester.tap(
      find
          .byWidgetPredicate(
            (w) => w is PictoRhythm && w.picto == Picto.couverts,
          )
          .last,
    );
    await _laisser(tester);
    await _capturer(tester, 'b01_alimentation');
    await _defiler(tester, 900);
    await _capturer(tester, 'b02_alimentation_bas');

    await ouvrir(find.text('Liste de courses'));
    await _capturer(tester, 'b03_liste');
    await _defiler(tester, 700);
    await _capturer(tester, 'b04_liste_bas');
    await _defiler(tester, 900);
    await _capturer(tester, 'b05_liste_fin');
    await _defiler(tester, -3000);
    await ouvrir(find.text('Oignons'));
    await _capturer(tester, 'b06_article');
    await fermer();

    await ouvrir(find.text('Au magasin'));
    await _capturer(tester, 'b07_magasin');
    await ouvrir(find.text('Croustilles').first);
    await tester.enterText(find.byType(TextField).first, '4,49');
    await _laisser(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _laisser(tester);
    await _capturer(tester, 'b08_panier');
    await _defiler(tester, 600);
    await _capturer(tester, 'b09_panier_bas');
    await ouvrir(find.textContaining('Au panier ·'));
    await ouvrir(find.text('Poitrines de poulet').first);
    await _capturer(tester, 'b10_panier_poids');
    await tester.enterText(find.byType(TextField).at(1), '0,95');
    await _laisser(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _laisser(tester);
    await ouvrir(find.textContaining('Au panier ·'));
    await _defiler(tester, 900);
    await _capturer(tester, 'b11_magasin_panier');
    await tester.tap(find.text('Terminer'));
    await tester.pump();
    await tester.tap(find.text('Toucher encore'));
    await _laisser(tester);
    await _capturer(tester, 'b12_ranger');
    await _defiler(tester, 600);
    await _capturer(tester, 'b13_ranger_bas');
    await fermer();

    await ouvrir(find.text('Garde-manger').last);
    await _capturer(tester, 'b14_garde_manger');
    await _defiler(tester, 700);
    await _capturer(tester, 'b15_garde_manger_bas');
    await _defiler(tester, -3000);
    await ouvrir(find.text('Bananes'));
    await _capturer(tester, 'b16_fiche');
    await _defiler(tester, 700);
    await _capturer(tester, 'b17_fiche_bas');
    await fermer();
    await ouvrir(find.text('Ajouter au garde-manger'));
    await tester.enterText(find.byType(TextField).first, 'Avocats');
    await _laisser(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _laisser(tester);
    await _capturer(tester, 'b18_ajout');
    await fermer();
    await fermer();

    await ouvrir(find.text('Historique des épiceries'));
    await _capturer(tester, 'b19_historique');
    await ouvrir(find.textContaining('Maxi').first);
    await _capturer(tester, 'b20_epicerie');
    await fermer();
    await fermer();
    await ouvrir(find.text('Rayons, magasins et budget'));
    await _capturer(tester, 'b21_reglages');
    await _defiler(tester, 800);
    await _capturer(tester, 'b22_reglages_bas');
    await fermer();
    await ouvrir(find.text('Les taxes du Québec'));
    await _capturer(tester, 'b23_taxes');
    await _defiler(tester, 700);
    await _capturer(tester, 'b24_taxes_bas');
  });
}

void _capturesRecettes() {
  testWidgets('captures des recettes', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await initializeDateFormatting();
    await chargerPolices();
    tester.view.physicalSize = const Size(384, 832) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final base = BaseAliments.analyser(
      File('assets/donnees/fcen.txt').readAsStringSync(),
    );
    // 17 h 30 : le conseil du soir (décongeler pour demain).
    final soir = DateTime(2026, 9, 24, 17, 30);
    SceneOuverture.reinitialiser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aujourdhuiProvider.overrideWithValue(soir),
          horlogeProvider.overrideWithValue(() => soir),
          baseAlimentsProvider.overrideWith((ref) async => base),
        ],
        child: const RhythmApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));

    Future<void> ouvrir(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await _laisser(tester);
    }

    Future<void> fermer() => ouvrir(
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );

    await tester.tap(
      find
          .byWidgetPredicate(
            (w) => w is PictoRhythm && w.picto == Picto.couverts,
          )
          .last,
    );
    await _laisser(tester);
    await _capturer(tester, 'c01_alimentation_soir');
    await _defiler(tester, 1000);
    await _capturer(tester, 'c02_alimentation_liens');

    // Le livre, une recette.
    await ouvrir(find.text('Mes recettes'));
    await _capturer(tester, 'c03_livre');
    await _defiler(tester, 700);
    await _capturer(tester, 'c04_livre_bas');
    await _defiler(tester, -3000);
    await ouvrir(find.text('Chili sin carne'));
    await _capturer(tester, 'c05_fiche');
    await _defiler(tester, 600);
    await _capturer(tester, 'c06_fiche_ingredients');
    await _defiler(tester, 700);
    await _capturer(tester, 'c07_fiche_etapes');
    await _defiler(tester, -3000);

    // À la liste, planifier.
    await ouvrir(find.text('À la liste'));
    await _capturer(tester, 'c08_a_la_liste');
    await fermer();
    await ouvrir(find.text('Planifier'));
    await _capturer(tester, 'c09_planifier');
    await fermer();

    // Le mode cuisine, un minuteur, « C'est prêt ».
    await ouvrir(find.text('Cuisiner'));
    await ouvrir(find.text('Oignon'));
    await ouvrir(find.text('Poivron rouge'));
    await _capturer(tester, 'c10_cuisine');
    await ouvrir(find.text('Minuteur 5 min'));
    await tester.pump(const Duration(seconds: 3));
    await _capturer(tester, 'c11_cuisine_minuteur');
    await ouvrir(find.text('Suivante'));
    await ouvrir(find.text('Suivante'));
    await ouvrir(find.text('Suivante'));
    await _capturer(tester, 'c12_cuisine_derniere');
    await ouvrir(find.bySemanticsLabel('Arrêter le minuteur'));
    await ouvrir(find.text("C'est prêt"));
    await _capturer(tester, 'c13_pret');
    await _defiler(tester, 700);
    await _capturer(tester, 'c14_pret_bas');
    await fermer();
    await fermer();

    // Écrire une recette, un ingrédient.
    await ouvrir(find.text('Nouvelle recette'));
    await tester.enterText(find.byType(TextField).first, 'Soupe aux pois');
    await _laisser(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _laisser(tester);
    await _capturer(tester, 'c15_formulaire');
    await _defiler(tester, 700);
    await _capturer(tester, 'c16_formulaire_2');
    await _defiler(tester, 900);
    await _capturer(tester, 'c17_formulaire_3');
    // La région : une grande région, puis ses cuisines.
    for (final puce in ["Afrique de l'Ouest", 'Ivoirienne']) {
      await tester.ensureVisible(find.text(puce));
      await _laisser(tester);
      await tester.tap(find.text(puce));
      await _laisser(tester);
    }
    await _defiler(tester, -200);
    await _capturer(tester, 'c17b_formulaire_region');
    await tester.tap(find.text('Aucune'));
    await _laisser(tester);
    await _defiler(tester, -3000);
    await ouvrir(find.text('Ajouter un ingrédient'));
    await tester.enterText(find.byType(TextField).first, 'pois');
    await _laisser(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _laisser(tester);
    await _capturer(tester, 'c18_ingredient_recherche');
    await ouvrir(find.textContaining('Pois').first);
    await _capturer(tester, 'c19_ingredient_quantite');
    await fermer();
    await fermer();
    await fermer();

    // Ma semaine.
    await ouvrir(find.text('Ma semaine'));
    await _capturer(tester, 'c20_semaine');
    await ouvrir(find.text('${DateTime(2026, 9, 25).day}'));
    await _capturer(tester, 'c21_semaine_demain');
    await _defiler(tester, 700);
    await _capturer(tester, 'c22_semaine_bas');
    await _defiler(tester, -3000);
    await ouvrir(find.text('Pâté chinois'));
    await _capturer(tester, 'c23_repas_prevu');
    await _defiler(tester, 700);
    await _capturer(tester, 'c24_repas_prevu_bas');
    await fermer();
    await ouvrir(find.bySemanticsLabel('Prévoir le déjeuner'));
    await _capturer(tester, 'c25_choisir');
    await fermer();
    await _defiler(tester, 700);
    await ouvrir(find.text('Cuisine en lot'));
    await _capturer(tester, 'c26_cuisine_en_lot');
    await fermer();
    await ouvrir(find.text('Liste de la semaine'));
    await _capturer(tester, 'c27_liste_semaine');
    await _defiler(tester, 900);
    await _capturer(tester, 'c28_liste_semaine_bas');
  });
}

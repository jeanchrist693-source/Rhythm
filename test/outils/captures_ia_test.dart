// test/outils/captures_ia_test.dart
//
// Captures d'écran de l'ASSISTANT de l'Alimentation (palier 4) hors
// appareil — PAS un vrai test (même méthode que
// `captures_alimentation_test.dart`), avec le faux service d'IA : l'onglet
// (la ligne « Assistant »), l'assistant, les idées (avant, pendant — les
// capsules qui battent —, après), une recette proposée, importer, estimer,
// l'écart, la semaine, remplacer un ingrédient, la conservation apprise,
// le bilan, une erreur — au format du S26 Ultra, au jeudi 24 septembre
// 2026 à 17 h 30.
//
//   flutter test --dart-define=CAPTURES=C:/chemin/sortie test/outils/captures_ia_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/ia/service_ia.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/widgets/pictos.dart';
import 'package:rhythm/widgets/scene_ouverture.dart';

import 'faux_ia.dart';
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

/// Un service qui ne répond jamais : l'attente, capturée.
class _Lent extends FauxServiceIa {
  @override
  Future<Map<String, dynamic>> json(
    List<MessageIa> messages, {
    Effort effort = Effort.bas,
    double temperature = 0.4,
    int maxTokens = 4096,
  }) => Completer<Map<String, dynamic>>().future;
}

void main() {
  testWidgets("captures de l'assistant", (tester) async {
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
    final precedent = ServiceIa.instance;
    addTearDown(() => ServiceIa.instance = precedent);
    ServiceIa.instance = FauxServiceIa();
    SceneOuverture.reinitialiser();
    final maintenant = DateTime(2026, 9, 24, 17, 30);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aujourdhuiProvider.overrideWithValue(maintenant),
          horlogeProvider.overrideWithValue(() => maintenant),
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
    await tester.ensureVisible(find.text('Assistant'));
    await _laisser(tester);
    await _capturer(tester, 'i01_onglet');

    await ouvrir(find.text('Assistant'));
    await _capturer(tester, 'i02_assistant');
    await _defiler(tester, 600);
    await _capturer(tester, 'i03_assistant_bas');
    await _defiler(tester, -2000);

    // Les idées : le choix, l'attente, les propositions, une recette.
    await ouvrir(find.text('Idées de recettes'));
    await ouvrir(find.text("Afrique de l'Ouest"));
    await _capturer(tester, 'i04_idees');
    await _defiler(tester, 500);
    await _capturer(tester, 'i05_idees_bas');
    ServiceIa.instance = _Lent();
    await ouvrir(find.text('Proposer 3 idées'));
    await tester.pump(const Duration(milliseconds: 350));
    await _capturer(tester, 'i06_idees_attente');
    await fermer();
    ServiceIa.instance = FauxServiceIa();
    await ouvrir(find.text('Idées de recettes'));
    await ouvrir(find.text("Afrique de l'Ouest"));
    await ouvrir(find.text('Proposer 3 idées'));
    await _capturer(tester, 'i07_idees_propositions');
    await ouvrir(find.text('Poulet yassa'));
    await _capturer(tester, 'i08_recette_proposee');
    await _defiler(tester, 600);
    await _capturer(tester, 'i09_recette_proposee_bas');
    await _defiler(tester, 700);
    await _capturer(tester, 'i10_recette_proposee_fin');
    await fermer();
    await fermer();

    // L'écart du soir.
    await ouvrir(find.text("Combler l'écart"));
    await ouvrir(find.text('Des idées'));
    await _capturer(tester, 'i11_ecart');
    await _defiler(tester, 600);
    await _capturer(tester, 'i12_ecart_bas');
    await fermer();

    // La semaine.
    await ouvrir(find.text('Planifier ma semaine'));
    await ouvrir(find.text('Proposer ma semaine'));
    await _capturer(tester, 'i13_semaine');
    await _defiler(tester, 500);
    await _capturer(tester, 'i14_semaine_bas');
    await fermer();

    // Estimer.
    await ouvrir(find.text('Estimer un repas'));
    await tester.enterText(
      find.byType(EditableText).first,
      "Deux rôties au beurre d'arachide et une banane",
    );
    await ouvrir(find.text('Estimer'));
    await _capturer(tester, 'i15_estimer');
    await _defiler(tester, 500);
    await _capturer(tester, 'i16_estimer_bas');
    await fermer();

    // Importer.
    await ouvrir(find.text('Importer une recette'));
    await _capturer(tester, 'i17_importer');
    await fermer();

    // Le bilan.
    await ouvrir(find.text('Bilan de la semaine'));
    await _capturer(tester, 'i18_bilan');
    await _defiler(tester, 700);
    await _capturer(tester, 'i19_bilan_bas');
    await fermer();

    // Une erreur (pas de réseau).
    ServiceIa.instance = FauxServiceIa(erreur: ErreurIa.reseau);
    await ouvrir(find.text('Idées de recettes'));
    await ouvrir(find.text('Proposer 3 idées'));
    await _capturer(tester, 'i20_erreur');
    await fermer();
    await fermer();
    ServiceIa.instance = FauxServiceIa();

    // Remplacer un ingrédient.
    await ouvrir(find.text('Mes recettes'));
    await ouvrir(find.text('Omelette aux épinards'));
    await _defiler(tester, 700);
    await _capturer(tester, 'i21_recette_remplacer');
    await ouvrir(find.text('Remplacer un ingrédient'));
    await ouvrir(find.text('Cheddar'));
    await ouvrir(find.text('Remplacer «\u00A0Cheddar\u00A0»'));
    await _capturer(tester, 'i22_remplacer');
    await _defiler(tester, 600);
    await _capturer(tester, 'i23_remplacer_bas');
    await fermer();
    await fermer();
    await fermer();

    // La conservation d'un aliment hors du guide.
    await ouvrir(find.text('Garde-manger'));
    await ouvrir(find.text('Ajouter au garde-manger'));
    await tester.enterText(find.byType(EditableText).first, 'Attiéké');
    await _laisser(tester);
    await _capturer(tester, 'i24_conservation');
    await ouvrir(find.text('Comment le garder\u00A0?'));
    await _capturer(tester, 'i25_conservation_apprise');
  });
}

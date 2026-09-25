// test/outils/captures_test.dart
//
// Captures d'écran hors appareil — PAS un vrai test. Rend l'app avec les
// vraies polices, au jeudi 24 septembre 2026 (date de la maquette), et
// écrit des PNG dans le dossier passé par `CAPTURES` :
//   - les cinq écrans au format de la maquette (390 × 844) et du S26 Ultra
//     (384 × 832, ×3,75) ;
//   - la scène d'ouverture et l'entrée de l'accueil, image par image ;
//   - les habitudes vivantes : l'écran, la fiche (construire, libérer), le
//     soutien d'une envie, le formulaire, les rappels.
//
//   flutter test --dart-define=CAPTURES=C:/chemin/sortie test/outils/captures_test.dart
//
// Sans le `--dart-define`, le test est sauté. Sert à comparer à la maquette
// sans toucher au téléphone (méthode de Net Worth et Studio).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/app/rhythm_app.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/widgets/formulaire.dart';
import 'package:rhythm/widgets/corps/silhouette.dart';
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

Future<void> _preparer(WidgetTester tester, Size taille, double densite) async {
  await initializeDateFormatting();
  await chargerPolices();
  tester.view.physicalSize = taille * densite;
  tester.view.devicePixelRatio = densite;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

Widget _app() => ProviderScope(
  overrides: [
    aujourdhuiProvider.overrideWithValue(DateTime(2026, 9, 24, 8)),
    horlogeProvider.overrideWithValue(() => DateTime(2026, 9, 24, 8, 41, 27)),
  ],
  child: const RhythmApp(),
);

/// Une navigation : la transition, puis un temps (les mascottes tournent
/// sans fin, `pumpAndSettle` ne rendrait jamais la main).
Future<void> _laisser(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

/// La liste verticale de l'écran du dessus : la première (pas celle d'un
/// champ de texte, ni la liste réordonnable qu'elle contient).
Finder get _liste => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// Fait défiler l'écran du dessus de [dy].
Future<void> _defiler(WidgetTester tester, double dy) async {
  await tester.drag(_liste, Offset(0, -dy));
  await _laisser(tester);
}

Finder _onglet(Picto picto) =>
    find.byWidgetPredicate((w) => w is PictoRhythm && w.picto == picto).last;

void main() {
  for (final (format, taille, densite) in const [
    ('maquette', Size(390, 844), 2.0),
    ('s26', Size(384, 832), 3.75),
  ]) {
    testWidgets('captures des écrans ($format)', (tester) async {
      if (_dossier.isEmpty) {
        markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
        return;
      }
      await _preparer(tester, taille, densite);
      SceneOuverture.reinitialiser();
      await tester.pumpWidget(_app());
      // Les mascottes tournent sans fin : on avance l'horloge à la main.
      await tester.pump(const Duration(milliseconds: 1600));
      await _capturer(tester, '${format}_1_accueil');

      for (final (picto, nom) in const [
        (Picto.haltere, '2_sports'),
        (Picto.couverts, '3_alimentation'),
        (Picto.cocheCercle, '4_habitudes'),
        (Picto.livre, '5_biblique'),
      ]) {
        await tester.tap(_onglet(picto));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        await _capturer(tester, '${format}_$nom');
      }
      // Le bas de l'Alimentation (plus haute qu'un écran).
      await tester.tap(_onglet(Picto.couverts));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 900));
      await _capturer(tester, '${format}_3_alimentation_bas');
    });
  }

  testWidgets('captures des habitudes', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await _preparer(tester, const Size(384, 832), 2);
    SceneOuverture.reinitialiser();
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.tap(_onglet(Picto.cocheCercle));
    await _laisser(tester);
    await _capturer(tester, 'h1_habitudes');
    await _defiler(tester, 520);
    await _capturer(tester, 'h2_habitudes_bas');

    // La fiche d'une habitude à libérer, puis le soutien.
    await _defiler(tester, -2000);
    await tester.tap(find.textContaining('Boissons énergisantes').first);
    await _laisser(tester);
    await _capturer(tester, 'h5_fiche_liberer');
    await _defiler(tester, 700);
    await _capturer(tester, 'h6_fiche_liberer_bas');
    await tester.drag(_liste, const Offset(0, 2000));
    await _laisser(tester);
    await tester.tap(find.text("J'ai une envie"));
    await _laisser(tester);
    await tester.pump(const Duration(seconds: 2));
    await _capturer(tester, 'h7_envie');
    await _defiler(tester, 700);
    await _capturer(tester, 'h8_envie_milieu');
    await _defiler(tester, 900);
    await _capturer(tester, 'h9_envie_bas');
    await tester.tap(find.text("J'ai rechuté"));
    await _laisser(tester);
    await tester.drag(_liste, const Offset(0, 3000));
    await _laisser(tester);
    await _capturer(tester, 'h10_rechute');
    Navigator.of(tester.element(find.text("Tu n'as pas tout perdu."))).pop();
    await _laisser(tester);
    Navigator.of(tester.element(find.text('Boissons énergisantes').last)).pop();
    await _laisser(tester);

    // La fiche d'une habitude à construire.
    await tester.drag(_liste, const Offset(0, 2000));
    await _laisser(tester);
    await tester.tap(find.text('Prière du matin'));
    await _laisser(tester);
    await _capturer(tester, 'h3_fiche');
    await _defiler(tester, 600);
    await _capturer(tester, 'h4_fiche_bas');
    Navigator.of(tester.element(find.text('Prière du matin').last)).pop();
    await _laisser(tester);

    // Le formulaire, à libérer.
    await tester.ensureVisible(find.text('Nouvelle habitude'));
    await _laisser(tester);
    await tester.tap(find.text('Nouvelle habitude'));
    await _laisser(tester);
    await _capturer(tester, 'h11_formulaire');
    // Le rappel activé : la roulette de l'heure, réglée sur 22 h 30.
    await tester.tap(find.byType(Interrupteur).first);
    await _laisser(tester);
    await _defiler(tester, 360);
    await tester.drag(find.text('08').first, const Offset(0, -44.0 * 14));
    await _laisser(tester);
    await tester.drag(find.text('00').first, const Offset(0, -44.0 * 6));
    await _laisser(tester);
    await _capturer(tester, 'h11b_formulaire_heure');
    await _defiler(tester, -360);
    await tester.tap(find.text('Me libérer'));
    await _laisser(tester);
    await _defiler(tester, 700);
    await _capturer(tester, 'h12_formulaire_liberer');
    await _defiler(tester, 700);
    await _capturer(tester, 'h13_formulaire_liberer_bas');
    Navigator.of(tester.element(find.text('Enregistrer'))).pop();
    await _laisser(tester);

    // Les rappels, par la cloche.
    await tester.tap(_onglet(Picto.maison));
    await _laisser(tester);
    await tester.tap(_onglet(Picto.cloche));
    await _laisser(tester);
    await _capturer(tester, 'h14_rappels');
    await _defiler(tester, 800);
    await _capturer(tester, 'h15_rappels_bas');
  });

  testWidgets("scène d'ouverture et entrée de l'accueil", (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await _preparer(tester, const Size(384, 832), 1.5);
    SceneOuverture.reinitialiser(active: true);
    addTearDown(SceneOuverture.reinitialiser);
    await tester.pumpWidget(_app());
    var ecoule = 0;
    for (final t in const [
      350, 450, 520, 600, 700, 800, 950, 1100, 1300, 1450, 1550, 1650, //
      1800, 2000, 2200, 2350, 2450, 2550, 2650, 2800, 3000, 3300, 3800,
    ]) {
      await tester.pump(Duration(milliseconds: t - ecoule));
      ecoule = t;
      await _capturer(tester, 'scene_${t.toString().padLeft(4, '0')}');
    }
  });

  testWidgets('captures des sports', (tester) async {
    if (_dossier.isEmpty) {
      markTestSkipped('Exécuter avec --dart-define=CAPTURES=<dossier>');
      return;
    }
    await _preparer(tester, const Size(384, 832), 2);
    SceneOuverture.reinitialiser();
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.tap(_onglet(Picto.haltere));
    await _laisser(tester);
    await _capturer(tester, 's01_sports');
    await _defiler(tester, 640);
    await _capturer(tester, 's02_sports_2');
    await _defiler(tester, 640);
    await _capturer(tester, 's03_sports_3');
    await _defiler(tester, 640);
    await _capturer(tester, 's04_sports_4');
    await _defiler(tester, 640);
    await _capturer(tester, 's05_sports_5');
    await _defiler(tester, -4000);

    Future<void> ouvrir(String texte) async {
      final f = find.text(texte).first;
      await tester.ensureVisible(f);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(f);
      await _laisser(tester);
    }

    Future<void> fermer() async {
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await _laisser(tester);
    }

    // La banque, puis une fiche.
    await ouvrir('Exercices');
    await _capturer(tester, 's06_banque');
    await _defiler(tester, 900);
    await _capturer(tester, 's07_banque_bas');
    await _defiler(tester, -2000);
    await tester.enterText(find.byType(TextField).first, 'pompes');
    await _laisser(tester);
    await _capturer(tester, 's08_banque_recherche');
    await ouvrir('Pompes');
    await tester.pump(const Duration(milliseconds: 700));
    await _capturer(tester, 's09_fiche');
    await _defiler(tester, 700);
    await _capturer(tester, 's10_fiche_2');
    await _defiler(tester, 800);
    await _capturer(tester, 's11_fiche_3');
    await _defiler(tester, 800);
    await _capturer(tester, 's12_fiche_4');
    await fermer();
    await fermer();

    // Le constructeur : les pectoraux et le dos, « Compléter », l'aperçu.
    await ouvrir('Créer une séance');
    final silhouette = find.byType(SilhouetteMuscles).first;
    final zone = tester.getRect(silhouette);
    await tester.tapAt(
      zone.topLeft + Offset(zone.width * 0.40, zone.height * 0.2),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // Puis le dos (les dorsaux), de dos.
    await tester.tap(find.text('Dos').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tapAt(
      zone.topLeft + Offset(zone.width * 0.40, zone.width * 0.55),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await _capturer(tester, 's13_constructeur');
    await ouvrir('Compléter');
    await _defiler(tester, 760);
    await _capturer(tester, 's14_constructeur_2');
    await _defiler(tester, 800);
    await _capturer(tester, 's15_constructeur_3');
    await ouvrir("Voir l'aperçu");
    await _capturer(tester, 's16_apercu');
    await _defiler(tester, 700);
    await _capturer(tester, 's17_apercu_2');
    await tester.tap(find.byType(ReorderableDelayedDragStartListener).first);
    await _laisser(tester);
    await _capturer(tester, 's18_apercu_retouche');
    await _defiler(tester, 900);
    await _capturer(tester, 's19_apercu_3');
    await _defiler(tester, 900);
    await _capturer(tester, 's20_apercu_4');

    // La séance guidée.
    await _defiler(tester, -4000);
    await ouvrir('Commencer');
    await tester.pump(const Duration(milliseconds: 700));
    await _capturer(tester, 's21_seance_echauffement');
    for (var i = 0; i < 6; i++) {
      if (find.text('Série faite').evaluate().isNotEmpty) break;
      await tester.tap(find.text("Passer l'exercice"));
      await _laisser(tester);
    }
    await _capturer(tester, 's22_seance_serie');
    await tester.tap(find.text('Série faite'));
    await _laisser(tester);
    await _capturer(tester, 's23_seance_repos');
    await tester.tap(find.text('Correct'));
    await tester.tap(find.text('Passer'));
    await _laisser(tester);
    await tester.tap(find.text('Série faite'));
    await _laisser(tester);
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.croix)
          .first,
    );
    await _laisser(tester);
    await _capturer(tester, 's24_seance_arreter');
    await tester.tap(find.text('Enregistrer ce qui est fait'));
    await _laisser(tester);
    await _capturer(tester, 's25_resume');
    await _defiler(tester, 600);
    await _capturer(tester, 's26_resume_bas');
    await ouvrir('Enregistrer');
    await tester.pump(const Duration(milliseconds: 400));
    await _capturer(tester, 's27_sports_apres');

    // Course : le chrono, puis la fin.
    await _defiler(tester, 900);
    await ouvrir('Course');
    await _capturer(tester, 's28_course');
    await tester.tap(find.text("C'est parti"));
    await _laisser(tester);
    await _capturer(tester, 's29_course_en_cours');
    await tester.tap(find.text('Terminer'));
    await _laisser(tester);
    await _capturer(tester, 's30_course_fin');
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.retour)
          .first,
    );
    await _laisser(tester);
    await tester.tap(find.text('Abandonner sans enregistrer'));
    await _laisser(tester);

    // Le fractionné.
    await ouvrir('Fractionné');
    await _capturer(tester, 's31_fractionne');
    await _defiler(tester, 700);
    await _capturer(tester, 's32_fractionne_perso');
    await _defiler(tester, -2000);
    await ouvrir('Tabata : 8 × 20 s, 10 s');
    await tester.tap(find.text("C'est parti"));
    await _laisser(tester);
    await _capturer(tester, 's33_fractionne_en_cours');
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is PictoRhythm && w.picto == Picto.croix)
          .first,
    );
    await _laisser(tester);
    await tester.tap(find.text('Abandonner sans enregistrer'));
    await _laisser(tester);

    // Les statistiques.
    await _defiler(tester, -4000);
    await ouvrir('Statistiques');
    await _capturer(tester, 's34_stats');
    await _defiler(tester, 700);
    await _capturer(tester, 's35_stats_2');
    await _defiler(tester, 700);
    await _capturer(tester, 's36_stats_3');
    await _defiler(tester, 900);
    await _capturer(tester, 's37_stats_4');
    await fermer();

    // Les défis.
    await ouvrir('Voir les défis');
    await _capturer(tester, 's38_defis');
    await ouvrir('100 pompes');
    await _capturer(tester, 's39_defi');
    await _defiler(tester, 700);
    await _capturer(tester, 's40_defi_bas');
    await fermer();
    await fermer();

    // Programmes progressifs, journal, mesures, matériel.
    await ouvrir('Programmes progressifs');
    await _capturer(tester, 's41_programmes');
    await fermer();
    await ouvrir('Tout le journal');
    await _capturer(tester, 's42_journal');
    await tester.tap(find.text('Course').first);
    await _laisser(tester);
    await _capturer(tester, 's43_seance_faite');
    await fermer();
    await fermer();
    await ouvrir('Mesures');
    await _capturer(tester, 's44_mesures');
    await fermer();
    await ouvrir('Matériel et objectifs');
    await _capturer(tester, 's45_profil');
    await _defiler(tester, 700);
    await _capturer(tester, 's46_profil_bas');
    await fermer();
    await ouvrir('Haut du corps');
    await _capturer(tester, 's47_programme');
    await fermer();
  });
}

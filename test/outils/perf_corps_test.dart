// test/outils/perf_corps_test.dart
//
// Banc d'essai de VITESSE du corps (pas un vrai test) : le temps de peindre
// une image, pour une grande figure (séance, fiche) et une miniature
// (listes). Le test tourne en JIT : le téléphone (AOT) est plus rapide.
//
//   flutter test --dart-define=PERF=true test/outils/perf_corps_test.dart

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/widgets/corps/animations_corps.dart';
import 'package:rhythm/widgets/corps/corps_humain.dart';
import 'package:rhythm/widgets/corps/peintre3.dart';
import 'package:rhythm/widgets/corps/squelette3.dart';

const bool _actif = bool.fromEnvironment('PERF');

void main() {
  test('le temps de peindre une image', () {
    if (!_actif) {
      markTestSkipped('Exécuter avec --dart-define=PERF=true');
      return;
    }
    for (final id in ['squat_halteres', 'pompe', 'course', 'traction']) {
      final anim = Mouvements.de(id)!;
      for (final cote in [320.0, 56.0]) {
        // Chauffe.
        for (var i = 0; i < 30; i++) {
          _peindre(anim, cote, i / 30);
        }
        final chrono = Stopwatch()..start();
        const n = 120;
        for (var i = 0; i < n; i++) {
          _peindre(anim, cote, i / n);
        }
        chrono.stop();
        // ignore: avoid_print
        print(
          '$id à ${cote.round()} px : '
          '${(chrono.elapsedMicroseconds / n / 1000).toStringAsFixed(2)} ms',
        );
      }
    }
  });
}

void _peindre(dynamic anim, double cote, double t) {
  final enregistreur = ui.PictureRecorder();
  final c = ui.Canvas(enregistreur);
  PeintreCorps3(
    cote: cote,
    camera: anim.camera,
    principaux: const {Muscle.quadriceps, Muscle.fessiers},
    secondaires: const {Muscle.ischios},
  ).peindre(c, Squelette3.de(anim.pose(t)), anim.accessoires);
  enregistreur.endRecording().dispose();
}

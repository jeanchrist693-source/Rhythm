// test/outils/inspection_corps_test.dart
//
// Banc d'essai des DÉFORMATIONS en mouvement — PAS un vrai test. Rend chaque
// mouvement à [INSTANTS] instants de son cycle (sans image) et mesure, sur
// chaque surface émise (peau, short, chaussettes, chaussures, mains…), ce
// qui change d'une image à l'autre :
//
// - les POINTES : un sommet qui sort de la surface de ses voisins, bien plus
//   qu'à son habitude dans le mouvement ;
// - les PLIS RETOURNÉS : deux cases voisines qui se font face alors
//   qu'elles se suivent d'habitude (la peau qui se replie sur elle-même) ;
// - les ÉTIREMENTS : une arête bien plus longue (ou écrasée) qu'à son
//   habitude.
//
// Seules les cases peintes comptent (pas celles enfouies dans une autre
// partie). Imprime les pires cas, avec l'articulation la plus proche : on
// les rend ensuite en grand avec `portrait_corps_test.dart`.
//
//   flutter test --dart-define=INSPECTER=1 test/outils/inspection_corps_test.dart
//
// [MOUVEMENTS] (ids), [INSTANTS] (16), [TAILLE] (300 : le détail de la
// fiche), [PIRES] (40).

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/widgets/corps/animations_corps.dart';
import 'package:rhythm/widgets/corps/geometrie3.dart';
import 'package:rhythm/widgets/corps/peau3.dart';
import 'package:rhythm/widgets/corps/peintre3.dart';
import 'package:rhythm/widgets/corps/squelette3.dart';

const bool _actif = String.fromEnvironment('INSPECTER') != '';
const String _filtre = String.fromEnvironment('MOUVEMENTS');

/// Une surface émise, recopiée.
class _Surface {
  _Surface(
    this.partie,
    this.rangs,
    this.cols,
    this.boucle,
    this.x,
    this.y,
    this.z,
    this.cachees,
  );
  final int partie, rangs, cols;
  final bool boucle;
  final Float64List x, y, z;
  final Uint8List? cachees;

  int get qc => boucle ? cols : cols - 1;
  V3 p(int i, int j) {
    final k = i * cols + j;
    return V3(x[k], y[k], z[k]);
  }

  bool casePeinte(int i, int j) {
    if (i < 0 || i >= rangs - 1 || j < 0 || j >= qc) return false;
    final c = cachees;
    return c == null || c[i * qc + j] != 1;
  }

  /// Un sommet se voit s'il borde une case peinte.
  bool sommetPeint(int i, int j) {
    final jm = boucle ? (j - 1 + cols) % cols : j - 1;
    return casePeinte(i, j) ||
        casePeinte(i - 1, j) ||
        casePeinte(i, jm) ||
        casePeinte(i - 1, jm);
  }

  V3? normaleCase(int i, int j) {
    final j1 = (j + 1) % cols;
    final a = p(i, j), b = p(i, j1), c = p(i + 1, j), d = p(i + 1, j1);
    final n = (d - a).cross(c - b);
    return n.norme < 1e-9 ? null : n.unite;
  }
}

/// Un défaut trouvé.
class _Defaut {
  _Defaut(
    this.genre,
    this.score,
    this.id,
    this.instant,
    this.surface,
    this.partie,
    this.i,
    this.j,
    this.ou,
  );
  final String genre, id, ou;
  final double score, instant;
  final int surface, partie, i, j;

  @override
  String toString() =>
      '${score.toStringAsFixed(2).padLeft(6)}  $genre  $id @${instant.toStringAsFixed(3)}'
      '  surface $surface (partie $partie, ${i}x$j)  près de $ou';
}

String _pres(Squelette3 s, V3 p) {
  final points = {
    'bassin': s.bassin,
    'cou': s.cou,
    'tête': s.tete,
    'épaule P': s.brasP.racine,
    'coude P': s.brasP.milieu,
    'poignet P': s.brasP.bout,
    'main P': s.brasP.extremite,
    'épaule L': s.brasL.racine,
    'coude L': s.brasL.milieu,
    'poignet L': s.brasL.bout,
    'main L': s.brasL.extremite,
    'hanche P': s.jambeP.racine,
    'genou P': s.jambeP.milieu,
    'cheville P': s.jambeP.bout,
    'orteils P': s.jambeP.extremite,
    'hanche L': s.jambeL.racine,
    'genou L': s.jambeL.milieu,
    'cheville L': s.jambeL.bout,
    'orteils L': s.jambeL.extremite,
  };
  var meilleur = '', d = double.infinity;
  for (final e in points.entries) {
    final dd = (e.value - p).norme;
    if (dd < d) {
      d = dd;
      meilleur = e.key;
    }
  }
  return '$meilleur (${(d * 100).toStringAsFixed(1)} cm)';
}

void main() {
  test('les déformations, image par image', () {
    if (!_actif) {
      markTestSkipped('Exécuter avec --dart-define=INSPECTER=1');
      return;
    }
    const n = int.fromEnvironment('INSTANTS', defaultValue: 16);
    const cote = 0.0 + int.fromEnvironment('TAILLE', defaultValue: 300);
    const pires = int.fromEnvironment('PIRES', defaultValue: 40);
    final ids = _filtre.isEmpty
        ? Mouvements.tous.keys.toList()
        : _filtre.split(',');
    final defauts = <_Defaut>[];
    final parMouvement = <String, double>{};

    for (final id in ids) {
      final anim = Mouvements.de(id)!;
      final images = <List<_Surface>>[];
      final squelettes = <Squelette3>[];
      // L'image 0 : la pose de REPOS (debout), la référence.
      for (var f = -1; f < n; f++) {
        final s = Squelette3.de(f < 0 ? const Pose3() : anim.pose(f / n));
        final surfaces = <_Surface>[];
        Peau3.inspecter = (partie, rangs, cols, boucle, x, y, z, cachees) =>
            surfaces.add(
              _Surface(
                partie,
                rangs,
                cols,
                boucle,
                Float64List.fromList(x),
                Float64List.fromList(y),
                Float64List.fromList(z),
                cachees == null ? null : Uint8List.fromList(cachees),
              ),
            );
        final rec = ui.PictureRecorder();
        PeintreCorps3(
          cote: cote,
          camera: anim.camera,
        ).peindre(ui.Canvas(rec), s, anim.accessoires);
        rec.endRecording().dispose();
        images.add(surfaces);
        squelettes.add(s);
      }
      Peau3.inspecter = null;
      final repos = images.removeAt(0);
      squelettes.removeAt(0);

      var pire = 0.0;
      void noter(String genre, double score, int f, int g, int i, int j) {
        final sf = images[f][g];
        defauts.add(
          _Defaut(
            genre,
            score,
            id,
            f / n,
            g,
            sf.partie,
            i,
            j,
            _pres(squelettes[f], sf.p(i, j)),
          ),
        );
        pire = math.max(pire, score);
      }

      final nSurfaces = images.map((e) => e.length).reduce(math.min);
      for (var g = 0; g < math.min(nSurfaces, repos.length); g++) {
        final s0 = repos[g];
        if (images.any(
          (im) => im[g].rangs != s0.rangs || im[g].cols != s0.cols,
        )) {
          continue;
        }
        final rangs = s0.rangs, cols = s0.cols;
        // Le pire défaut de chaque genre, par image, pour cette surface.
        final pointes = List.generate(n, (_) => (0.0, 0, 0));
        final plis = List.generate(n, (_) => (0.0, 0, 0));
        final etires = List.generate(n, (_) => (0.0, 0, 0));

        // Les pointes : l'écart au milieu des voisins, rapporté aux arêtes.
        double ecart(_Surface sf, int i, int j) {
          final jm = (j - 1 + cols) % cols, jp = (j + 1) % cols;
          final c = sf.p(i, j);
          final vs = [sf.p(i - 1, j), sf.p(i + 1, j), sf.p(i, jm), sf.p(i, jp)];
          var m = V3.zero, e = 0.0;
          for (final v in vs) {
            m = m + v * 0.25;
            e += (v - c).norme * 0.25;
          }
          return e < 2e-4 ? 0 : (c - m).norme / e;
        }

        for (var i = 1; i < rangs - 1; i++) {
          for (var j = 0; j < cols; j++) {
            if (!s0.boucle && (j == 0 || j == cols - 1)) continue;
            final r0 = ecart(s0, i, j);
            for (var f = 0; f < n; f++) {
              final sf = images[f][g];
              if (!sf.sommetPeint(i, j)) continue;
              final r = ecart(sf, i, j);
              final sc = r - r0;
              if (r > 0.7 && sc > 0.3 && sc > pointes[f].$1) {
                pointes[f] = (sc, i, j);
              }
            }
          }
        }

        // Les plis retournés et les étirements, case par case.
        final qc = s0.qc;
        for (var i = 0; i < rangs - 1; i++) {
          for (var j = 0; j < qc; j++) {
            for (final (i2, j2) in [(i, (j + 1) % cols), (i + 1, j)]) {
              if (i2 >= rangs - 1 || j2 >= qc) continue;
              final a0 = s0.normaleCase(i, j), b0 = s0.normaleCase(i2, j2);
              if (a0 == null || b0 == null || a0.dot(b0) < 0.4) continue;
              for (var f = 0; f < n; f++) {
                final sf = images[f][g];
                if (!sf.casePeinte(i, j) || !sf.casePeinte(i2, j2)) continue;
                final a = sf.normaleCase(i, j), b = sf.normaleCase(i2, j2);
                if (a == null || b == null) continue;
                final d = a.dot(b);
                if (d < -0.1 && 1 - d > plis[f].$1) plis[f] = (1 - d, i, j);
              }
            }
            // L'arête le long de la colonne (d'un anneau au suivant) : bien
            // plus longue qu'au repos (les plis, eux, se tassent).
            final l0 = (s0.p(i + 1, j) - s0.p(i, j)).norme;
            if (l0 < 1e-3) continue;
            for (var f = 0; f < n; f++) {
              final sf = images[f][g];
              if (!sf.casePeinte(i, j)) continue;
              final r = (sf.p(i + 1, j) - sf.p(i, j)).norme / l0;
              if (r > 3 && r > etires[f].$1) etires[f] = (r, i, j);
            }
          }
        }
        for (var f = 0; f < n; f++) {
          if (pointes[f].$1 > 0) {
            noter('POINTE ', pointes[f].$1, f, g, pointes[f].$2, pointes[f].$3);
          }
          if (plis[f].$1 > 0) {
            noter('PLI    ', plis[f].$1, f, g, plis[f].$2, plis[f].$3);
          }
          if (etires[f].$1 > 0) {
            noter('ÉTIRÉ  ', etires[f].$1, f, g, etires[f].$2, etires[f].$3);
          }
        }
      }
      parMouvement[id] = pire;
    }

    // Un défaut par mouvement, surface et genre : le pire.
    defauts.sort((a, b) => b.score.compareTo(a.score));
    final vus = <String>{};
    final retenus = <_Defaut>[];
    for (final d in defauts) {
      if (vus.add('${d.id}/${d.surface}/${d.genre}')) retenus.add(d);
    }
    for (final genre in ['PLI    ', 'POINTE ', 'ÉTIRÉ  ']) {
      final liste = retenus.where((d) => d.genre == genre).toList();
      // ignore: avoid_print
      print('── ${genre.trim()} : ${liste.length} (les $pires pires) ──');
      for (final d in liste.take(pires)) {
        // ignore: avoid_print
        print(d);
      }
    }
    final classement = parMouvement.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print('── Les mouvements les plus touchés ──');
    for (final e in classement.take(25)) {
      // ignore: avoid_print
      print('${e.value.toStringAsFixed(2).padLeft(6)}  ${e.key}');
    }
  });
}

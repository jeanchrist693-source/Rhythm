// test/outils/collisions_corps_test.dart
//
// Banc d'essai des COLLISIONS — PAS un vrai test. Pour chaque exercice du
// catalogue (avec SON matériel, `animationDe`), à [INSTANTS] instants du
// cycle, mesure de combien :
// - le MATÉRIEL tenu (plateaux et poignée d'haltère, barre et disques,
//   boule de kettlebell, ballon) entre dans le corps — les mains qui le
//   tiennent exceptées ;
// - le corps entre EN LUI-MÊME (le tronc dans les cuisses d'une chenille,
//   la tête dans les genoux, un bras dans le tronc…) — au-delà du contact
//   des chairs ([TOLERANCE], en millièmes).
// Le corps est approché par des volumes simples : le tronc, un cylindre
// elliptique qui suit ses stations (demi-largeur, profondeur devant et
// derrière) ; la tête, une sphère ; les membres, des capsules qui
// s'amincissent.
//
//   flutter test --dart-define=COLLISIONS=1 test/outils/collisions_corps_test.dart
//
// [EXERCICES] (ids) restreint la liste ; [PIRES] (20) : combien en montrer.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/modele/sports/catalogue.dart';
import 'package:rhythm/widgets/corps/figure_exercice.dart';
import 'package:rhythm/widgets/corps/geometrie3.dart';
import 'package:rhythm/widgets/corps/peintre3.dart';
import 'package:rhythm/widgets/corps/squelette3.dart';

const bool _actif = String.fromEnvironment('COLLISIONS') != '';
const String _filtre = String.fromEnvironment('EXERCICES');
const int _instants = int.fromEnvironment('INSTANTS', defaultValue: 32);
const int _pires = int.fromEnvironment('PIRES', defaultValue: 20);
const double _tolerance =
    int.fromEnvironment('TOLERANCE', defaultValue: 20) / 1000;

/// Une sphère d'échantillon.
typedef _Boule = (V3 c, double r);

/// Une capsule qui s'amincit de [ra] (en [a]) à [rb] (en [b]).
class _Capsule {
  _Capsule(this.nom, this.a, this.b, this.ra, this.rb);
  final String nom;
  final V3 a, b;
  final double ra, rb;

  /// La pénétration d'une boule dans la capsule (> 0 : dedans), et le
  /// paramètre le long du segment.
  (double, double) penetration(_Boule s) {
    final ab = b - a;
    final l2 = ab.dot(ab);
    final t = l2 < 1e-12 ? 0.0 : ((s.$1 - a).dot(ab) / l2).clamp(0.0, 1.0);
    final p = a + ab * t;
    final r = ra + (rb - ra) * t;
    return (r + s.$2 - (s.$1 - p).norme, t);
  }

  /// Des boules le long de la capsule (pour la tester contre une autre).
  List<_Boule> boules({double de = 0, double a0 = 1, int n = 8}) => [
    for (var i = 0; i <= n; i++)
      (
        V3.lerp(a, b, de + (a0 - de) * i / n),
        ra + (rb - ra) * (de + (a0 - de) * i / n),
      ),
  ];
}

/// Le tronc : un cylindre elliptique le long de bassin → cou.
class _Tronc {
  _Tronc(this.s);
  final Squelette3 s;

  // t le long du tronc (0 bassin, 1 cou) : demi-largeur, devant, derrière
  // (les stations de `peau/tronc.dart`).
  static const _stations = [
    (-0.22, 0.05, 0.02, 0.04),
    (-0.16, 0.072, 0.03, 0.052),
    (-0.08, 0.08, 0.04, 0.056),
    (0.02, 0.078, 0.046, 0.054),
    (0.12, 0.069, 0.047, 0.048),
    (0.28, 0.062, 0.047, 0.043),
    (0.48, 0.066, 0.053, 0.047),
    (0.68, 0.075, 0.061, 0.051),
    (0.8, 0.083, 0.058, 0.052),
    (0.87, 0.083, 0.053, 0.051),
    (0.94, 0.073, 0.045, 0.047),
    (1.0, 0.049, 0.033, 0.039),
  ];

  (double, double, double) _section(double t) {
    if (t <= _stations.first.$1) {
      final s0 = _stations.first;
      return (s0.$2, s0.$3, s0.$4);
    }
    for (var i = 1; i < _stations.length; i++) {
      final a = _stations[i - 1], b = _stations[i];
      if (t <= b.$1) {
        final u = (t - a.$1) / (b.$1 - a.$1);
        return (
          a.$2 + (b.$2 - a.$2) * u,
          a.$3 + (b.$3 - a.$3) * u,
          a.$4 + (b.$4 - a.$4) * u,
        );
      }
    }
    final s1 = _stations.last;
    return (s1.$2, s1.$3, s1.$4);
  }

  /// La pénétration d'une boule dans le tronc (> 0 : dedans) ; t.
  (double, double) penetration(_Boule b) {
    final d = b.$1 - s.bassin;
    final t = d.dot(s.dirTronc) / lTronc;
    if (t < -0.22 || t > 1.0) return (-1, t);
    final u = t.clamp(0.0, 1.0);
    final lat = V3.lerp(s.lateralBassin, s.lateralEpaules, u).unite;
    final av = V3.lerp(s.avantBassin, s.avantEpaules, u).unite;
    final (hl, dev, der) = _section(t);
    final x = d.dot(lat), y = d.dot(av);
    final prof = y >= 0 ? dev : der;
    // La distance « elliptique », ramenée à une longueur.
    final e = math.sqrt(
      math.pow(x / (hl + b.$2), 2) + math.pow(y / (prof + b.$2), 2),
    );
    return ((1 - e) * math.min(hl, prof), t);
  }
}

class _Corps {
  _Corps(this.s) : tronc = _Tronc(s) {
    V3 lerp(V3 a, V3 b, double t) => V3.lerp(a, b, t);
    for (final (nom, m) in [('bras proche', s.brasP), ('bras loin', s.brasL)]) {
      membres.add(_Capsule('$nom (haut)', m.racine, m.milieu, 0.029, 0.022));
      membres.add(
        _Capsule('$nom (avant-bras)', m.milieu, m.bout, 0.022, 0.017),
      );
    }
    for (final (nom, m, talon) in [
      ('jambe proche', s.jambeP, s.talonP),
      ('jambe loin', s.jambeL, s.talonL),
    ]) {
      membres.add(_Capsule('$nom (cuisse)', m.racine, m.milieu, 0.043, 0.03));
      membres.add(_Capsule('$nom (tibia)', m.milieu, m.bout, 0.029, 0.017));
      membres.add(
        _Capsule(
          '$nom (pied)',
          talon,
          lerp(talon, m.extremite, 1),
          0.02,
          0.014,
        ),
      );
    }
    mains = [
      _Capsule('main proche', s.brasP.bout, s.brasP.extremite, 0.017, 0.013),
      _Capsule('main loin', s.brasL.bout, s.brasL.extremite, 0.017, 0.013),
    ];
  }

  final Squelette3 s;
  final _Tronc tronc;
  final List<_Capsule> membres = [];
  late final List<_Capsule> mains;

  _Boule get tete => (s.tete, rTeteY * 1.08);

  /// La pire pénétration d'une boule dans le corps (hors [sauf]).
  (double, String) dans(_Boule b, {Set<String> sauf = const {}}) {
    var pire = -1.0, ou = '';
    final (pt, _) = tronc.penetration(b);
    if (pt > pire && !sauf.contains('tronc')) (pire, ou) = (pt, 'tronc');
    final dt = rTeteY * 1.08 + b.$2 - (b.$1 - s.tete).norme;
    if (dt > pire && !sauf.contains('tête')) (pire, ou) = (dt, 'tête');
    for (final c in [...membres, ...mains]) {
      if (sauf.contains(c.nom)) continue;
      final (p, _) = c.penetration(b);
      if (p > pire) (pire, ou) = (p, c.nom);
    }
    return (pire, ou);
  }
}

/// Des boules sur un disque de centre [c], d'axe [axe], de rayon [r].
List<_Boule> _disque(V3 c, V3 axe, double r, double ep) {
  var u = axe.cross(V3.bas);
  if (u.norme < 1e-3) u = axe.cross(V3.avant);
  u = u.unite;
  final w = axe.cross(u).unite;
  final rb = math.max(ep / 2, r * 0.22);
  return [
    (c, rb),
    for (var i = 0; i < 12; i++)
      (
        c +
            u * (math.cos(i * math.pi / 6) * (r - rb)) +
            w * (math.sin(i * math.pi / 6) * (r - rb)),
        rb,
      ),
  ];
}

List<_Boule> _echantillons(Charge c) => switch (c) {
  HaltereTenu(:final centre, :final axe) => [
    for (final s in [1.0, -1.0])
      ..._disque(centre + axe * (demiHaltere * s), axe, rayonPlateau, 0.02),
    for (final t in [-0.5, 0.0, 0.5]) (centre + axe * (demiHaltere * t), 0.006),
  ],
  BarreTenue(:final centre, :final axe) => [
    for (var i = -6; i <= 6; i++) (centre + axe * (demiBarre * i / 6), 0.005),
    for (final s in [1.0, -1.0])
      ..._disque(centre + axe * (placeDisque * s), axe, rayonDisque, 0.03),
  ],
  KettlebellTenue() => [(c.boule, rayonBoule)],
  BallonTenu(:final centre) => [(centre, rayonBallon)],
};

/// Les paires du corps qui ne doivent pas s'interpénétrer (au-delà du
/// contact) : le tronc et la tête contre les membres, les membres entre
/// eux quand ils ne se suivent pas.
List<(double, String)> _autoCollisions(_Corps c) {
  final r = <(double, String)>[];
  void contre(String nom, List<_Boule> boules, {Set<String> sauf = const {}}) {
    for (final b in boules) {
      final (p, ou) = c.dans(b, sauf: sauf);
      if (p > 0) r.add((p, '$nom ↔ $ou'));
    }
  }

  final m = c.membres;
  // Les cuisses et les tibias contre le tronc et la tête (la racine de la
  // cuisse naît dans le bassin : on part du tiers).
  for (final cap in m.where((x) => x.nom.startsWith('jambe'))) {
    final de = cap.nom.contains('cuisse') ? 0.4 : 0.0;
    contre(
      cap.nom,
      cap.boules(de: de),
      sauf: {for (final x in m) x.nom, ...c.mains.map((x) => x.nom)},
    );
  }
  // Les bras contre le tronc (le haut du bras naît à l'épaule) et contre
  // les jambes ; la tête contre les membres.
  for (final cap in m.where((x) => x.nom.startsWith('bras'))) {
    final de = cap.nom.contains('haut') ? 0.45 : 0.0;
    contre(
      cap.nom,
      cap.boules(de: de),
      sauf: {
        'tête',
        for (final x in m)
          if (x.nom.startsWith(cap.nom.split(' (').first) ||
              // Les avant-bras se touchent, mains jointes : pas une faute.
              (cap.nom.contains('avant-bras') && x.nom.contains('avant-bras')))
            x.nom,
        ...c.mains.map((x) => x.nom),
      },
    );
  }
  final (pt, ou) = c.dans(
    c.tete,
    sauf: {'tronc', 'tête', ...c.mains.map((x) => x.nom)},
  );
  if (pt > 0) r.add((pt, 'tête ↔ $ou'));
  return r;
}

void main() {
  test('collisions du corps et du matériel', () {
    if (!_actif) {
      markTestSkipped('Exécuter avec --dart-define=COLLISIONS=1');
      return;
    }
    final exercices = _filtre.isEmpty
        ? Catalogue.tous
        : [for (final id in _filtre.split(',')) Catalogue.de(id)!];
    final materiel = <(double, String)>[];
    final corps = <(double, String)>[];
    for (final e in exercices) {
      final a = animationDe(e);
      var pireM = (0.0, ''), pireC = (0.0, '');
      for (var i = 0; i < _instants; i++) {
        final t = i / _instants;
        final s = Squelette3.de(a.pose(t));
        final c = _Corps(s);
        for (final ch in chargesTenues(s, a.accessoires)) {
          for (final b in _echantillons(ch)) {
            final (p, ou) = c.dans(b, sauf: {'main proche', 'main loin'});
            if (p > pireM.$1) {
              pireM = (p, '${(t * 1000).round()}‰ ${ch.runtimeType} ↔ $ou');
            }
          }
        }
        for (final (p, ou) in _autoCollisions(c)) {
          if (p > pireC.$1) pireC = (p, '${(t * 1000).round()}‰ $ou');
        }
      }
      if (pireM.$1 > 0.004) {
        materiel.add((pireM.$1, '${e.id} (${e.mouvement}) : ${pireM.$2}'));
      }
      if (pireC.$1 > _tolerance) {
        corps.add((pireC.$1, '${e.id} (${e.mouvement}) : ${pireC.$2}'));
      }
    }
    materiel.sort((a, b) => b.$1.compareTo(a.$1));
    corps.sort((a, b) => b.$1.compareTo(a.$1));
    String mm(double v) => '${(v * 1000).toStringAsFixed(0).padLeft(3)} ‰';
    // ignore: avoid_print
    print(
      '— MATÉRIEL DANS LE CORPS (${materiel.length}) —\n'
      '${materiel.take(_pires).map((x) => '${mm(x.$1)}  ${x.$2}').join('\n')}\n'
      '— CORPS EN LUI-MÊME, au-delà de ${mm(_tolerance)} (${corps.length}) —\n'
      '${corps.take(_pires).map((x) => '${mm(x.$1)}  ${x.$2}').join('\n')}',
    );
  });
}

// lib/widgets/corps/silhouette.dart
//
// La SILHOUETTE des muscles, de face et de dos : une carte du corps où
// chaque muscle est une région qu'on touche (le constructeur de séance :
// « tu touches les zones à travailler ») ou qu'on colore (les statistiques :
// ce qui a été travaillé sur 30 jours, ce qui est négligé).
//
// Dessinée dans un repère de 100 × 210 : le contour du corps (gris sombre),
// puis les régions (blanc 9 % au repos, la couleur qu'on leur donne sinon),
// symétriques — une région décrite pour le côté gauche de l'écran est
// reflétée. Les muscles EN RÉCUPÉRATION sont hachurés.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../modele/sports/muscles.dart';

enum CoteSilhouette { face, dos }

class SilhouetteMuscles extends StatelessWidget {
  const SilhouetteMuscles({
    super.key,
    required this.cote,
    this.couleurs = const {},
    this.hachures = const {},
    this.onTap,
  });

  final CoteSilhouette cote;

  /// La couleur de chaque muscle (les autres : blanc 9 %).
  final Map<Muscle, Color> couleurs;

  /// Les muscles hachurés (en récupération).
  final Set<Muscle> hachures;

  /// Un muscle touché.
  final ValueChanged<Muscle>? onTap;

  static const Size repere = Size(100, 210);

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: repere.width / repere.height,
    child: LayoutBuilder(
      builder: (context, c) {
        final echelle = c.maxWidth / repere.width;
        final peinture = CustomPaint(
          size: Size(c.maxWidth, c.maxHeight),
          painter: _PeintreSilhouette(cote, couleurs, hachures),
        );
        if (onTap == null) return peinture;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final p = d.localPosition / echelle;
            final m = muscleEn(cote, p);
            if (m != null) onTap!(m);
          },
          child: peinture,
        );
      },
    ),
  );

  /// Le muscle sous le point [p] (repère 100 × 210), ou le plus proche à
  /// moins de 5 unités.
  static Muscle? muscleEn(CoteSilhouette cote, Offset p) {
    final regions = _regions(cote);
    for (final r in regions.reversed) {
      if (r.$2.contains(p)) return r.$1;
    }
    Muscle? proche;
    var d = 5.0;
    for (final r in regions) {
      final b = r.$2.getBounds();
      final dx = (p.dx < b.left
          ? b.left - p.dx
          : (p.dx > b.right ? p.dx - b.right : 0.0));
      final dy = (p.dy < b.top
          ? b.top - p.dy
          : (p.dy > b.bottom ? p.dy - b.bottom : 0.0));
      final dist = dx > dy ? dx : dy;
      if (dist < d) {
        d = dist;
        proche = r.$1;
      }
    }
    return proche;
  }
}

// ═══ Le dessin ══════════════════════════════════════════════════════════════

/// Une courbe fermée lisse (Catmull-Rom) par ces points.
Path _lisse(List<Offset> p) {
  final n = p.length;
  final chemin = Path()..moveTo(p[0].dx, p[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = p[(i - 1 + n) % n], p1 = p[i];
    final p2 = p[(i + 1) % n], p3 = p[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    chemin.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return chemin..close();
}

Offset _miroir(Offset o) => Offset(100 - o.dx, o.dy);

List<Offset> _pts(List<double> xy) => [
  for (var i = 0; i < xy.length; i += 2) Offset(xy[i], xy[i + 1]),
];

/// Une région des deux côtés (décrite à gauche de l'écran).
Path _paire(List<double> xy) {
  final g = _pts(xy);
  return Path()
    ..addPath(_lisse(g), Offset.zero)
    ..addPath(_lisse([for (final o in g.reversed) _miroir(o)]), Offset.zero);
}

/// Le contour du corps : le côté gauche de l'écran, du cou à l'entrejambe ;
/// l'autre est son reflet.
final List<Offset> _moitie = _pts([
  45, 23, 44.5, 28, 38, 30, 29, 32.5, 24.5, 37, 22.5, 45, 22, 55, //
  20.5, 66, 19, 77, 16.5, 90, 15, 104, 13, 111, 12.5, 119, 15, 124, //
  18, 122, 19.5, 114, 21, 106, 24.5, 92, 27.5, 79, 30, 66, 31.5, 57, //
  33, 64, 34.5, 78, 35.5, 90, 33.5, 100, 31.5, 112, 31, 128, 32.5, 142, //
  35, 152, 34, 162, 35, 176, 37.5, 190, 34.5, 197, 36, 200, 44.5, 200, //
  45.5, 193, 46, 180, 46.5, 164, 47.5, 152, 48.5, 138, 49.5, 124, 50, 118,
]);

final Path _contour = () {
  final droite = [for (final o in _moitie.reversed) _miroir(o)];
  final chemin = Path()..moveTo(_moitie.first.dx, _moitie.first.dy);
  for (final o in [..._moitie, ...droite]) {
    chemin.lineTo(o.dx, o.dy);
  }
  chemin.close();
  // La tête.
  chemin.addOval(
    Rect.fromCenter(center: const Offset(50, 13), width: 17, height: 21),
  );
  return chemin;
}();

final Map<CoteSilhouette, List<(Muscle, Path)>> _cache = {};

List<(Muscle, Path)> _regions(CoteSilhouette cote) => _cache.putIfAbsent(
  cote,
  () => cote == CoteSilhouette.face ? _face() : _dos(),
);

List<(Muscle, Path)> _face() => [
  (Muscle.trapezes, _paire([45, 26, 39.5, 30, 45.5, 31.5])),
  (
    Muscle.epaules,
    _paire([
      38.5,
      31,
      30,
      32.5,
      25.5,
      37.5,
      24,
      45,
      27.5,
      49.5,
      31.5,
      44,
      35.5,
      37,
    ]),
  ),
  (
    Muscle.pectoraux,
    _paire([
      48.5,
      34,
      39.5,
      33,
      34,
      38,
      33,
      46,
      36.5,
      52.5,
      44,
      54.5,
      48.8,
      51,
    ]),
  ),
  (
    Muscle.biceps,
    _paire([30.5, 49, 26, 52, 24, 60, 23.5, 70, 27, 75, 29.5, 66, 31, 56]),
  ),
  (
    Muscle.avantBras,
    _paire([
      24,
      80,
      20.5,
      86,
      18.5,
      96,
      18.3,
      105,
      21.5,
      106,
      24,
      96,
      26.3,
      85,
    ]),
  ),
  (
    Muscle.obliques,
    _paire([41.5, 59, 36.5, 58, 35, 68, 36.5, 82, 41, 94, 42.5, 80]),
  ),
  (
    Muscle.abdos,
    _lisse(
      _pts([
        43.5,
        57,
        50,
        56,
        56.5,
        57,
        57,
        76,
        56,
        96,
        50,
        99,
        44,
        96,
        43,
        76,
      ]),
    ),
  ),
  (
    Muscle.quadriceps,
    _paire([
      34.5,
      106,
      32,
      118,
      32,
      132,
      34.5,
      145,
      39.5,
      150,
      45.5,
      146,
      47.5,
      130,
      46,
      114,
      41,
      107,
    ]),
  ),
  (
    Muscle.adducteurs,
    _paire([47.2, 113, 49.3, 119, 49.3, 132, 47.5, 139, 46.2, 126]),
  ),
  (
    Muscle.mollets,
    _paire([36.5, 158, 35.2, 168, 36.5, 182, 39.5, 184, 40, 170, 39.5, 159]),
  ),
];

List<(Muscle, Path)> _dos() => [
  (
    Muscle.trapezes,
    _lisse(
      _pts([
        50,
        24,
        56,
        29,
        61.5,
        31.5,
        56,
        38,
        51.5,
        56,
        48.5,
        56,
        44,
        38,
        38.5,
        31.5,
        44,
        29,
      ]),
    ),
  ),
  (
    Muscle.epaules,
    _paire([
      38,
      31,
      30,
      32.5,
      25.5,
      37.5,
      24,
      45,
      27.5,
      49.5,
      31.5,
      44,
      35,
      36.5,
    ]),
  ),
  (
    Muscle.dos,
    _paire([
      47.5,
      42,
      43,
      36.5,
      36,
      39,
      33.5,
      48,
      34.5,
      60,
      38.5,
      72,
      45.5,
      79,
      48.5,
      64,
    ]),
  ),
  (
    Muscle.triceps,
    _paire([30.5, 48, 26, 51, 24, 60, 24, 70, 27.5, 75, 30, 66, 31.5, 56]),
  ),
  (
    Muscle.avantBras,
    _paire([
      24,
      80,
      20.5,
      86,
      18.5,
      96,
      18.3,
      105,
      21.5,
      106,
      24,
      96,
      26.3,
      85,
    ]),
  ),
  (
    Muscle.lombaires,
    _paire([48.5, 80, 42.5, 82, 39.5, 88, 40.5, 96, 46, 98, 49.2, 93]),
  ),
  (
    Muscle.fessiers,
    _paire([49, 101, 40, 100, 34, 106, 33.5, 116, 38, 123, 45, 124, 49.2, 118]),
  ),
  (
    Muscle.ischios,
    _paire([
      34,
      125,
      32.5,
      135,
      34,
      146,
      39,
      151,
      45,
      149,
      47.5,
      137,
      46,
      126,
      40,
      125,
    ]),
  ),
  (Muscle.adducteurs, _paire([47.5, 124, 49.3, 129, 49, 139, 47, 134])),
  (
    Muscle.mollets,
    _paire([
      37,
      156,
      34.5,
      165,
      35.5,
      177,
      39.5,
      182,
      44,
      177,
      45.5,
      165,
      43,
      156,
    ]),
  ),
];

class _PeintreSilhouette extends CustomPainter {
  _PeintreSilhouette(this.cote, this.couleurs, this.hachures);

  final CoteSilhouette cote;
  final Map<Muscle, Color> couleurs;
  final Set<Muscle> hachures;

  static const Color _corps = Color(0xFF1C1C1F);
  static const Color _neutre = Color(0x17FFFFFF);
  static const Color _bord = Color(0x0FFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / SilhouetteMuscles.repere.width);
    canvas.drawPath(_contour, Paint()..color = _corps);
    final bord = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = _bord;
    for (final (m, chemin) in _regions(cote)) {
      canvas.drawPath(chemin, Paint()..color = couleurs[m] ?? _neutre);
      canvas.drawPath(chemin, bord);
      if (hachures.contains(m)) _hachurer(canvas, chemin);
    }
    // Les séparations des abdominaux (de face).
    if (cote == CoteSilhouette.face) {
      final trait = Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 0.8;
      canvas.drawLine(const Offset(50, 58), const Offset(50, 97), trait);
      for (final y in const [67.0, 77.0, 87.0]) {
        canvas.drawLine(Offset(44.5, y), Offset(55.5, y), trait);
      }
    } else {
      final trait = Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 0.8;
      canvas.drawLine(const Offset(50, 60), const Offset(50, 98), trait);
    }
    canvas.restore();
  }

  void _hachurer(Canvas canvas, Path chemin) {
    final b = chemin.getBounds();
    canvas.save();
    canvas.clipPath(chemin);
    final trait = Paint()
      ..color = const Color(0x8C000000)
      ..strokeWidth = 1.1;
    for (var x = b.left - b.height; x < b.right; x += 3.2) {
      canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), trait);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreSilhouette ancien) =>
      ancien.cote != cote ||
      !_memes(ancien.couleurs, couleurs) ||
      !ancien.hachures.containsAll(hachures) ||
      !hachures.containsAll(ancien.hachures);

  static bool _memes(Map<Muscle, Color> a, Map<Muscle, Color> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

/// Pour les tests : l'image d'une silhouette.
Future<ui.Image> imageSilhouette(
  CoteSilhouette cote,
  Map<Muscle, Color> couleurs, {
  double largeur = 200,
}) async {
  final enregistreur = ui.PictureRecorder();
  final canvas = Canvas(enregistreur);
  final taille = Size(largeur, largeur * 2.1);
  _PeintreSilhouette(cote, couleurs, const {}).paint(canvas, taille);
  return enregistreur.endRecording().toImage(
    taille.width.round(),
    taille.height.round(),
  );
}

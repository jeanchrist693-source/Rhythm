// lib/widgets/corps/geometrie3.dart
//
// La géométrie du corps en 3D : vecteurs, directions des segments (angle
// dans le plan sagittal + écart hors de ce plan), cinématique inverse à deux
// segments (le coude, le genou), enveloppe convexe et courbes lisses pour
// les contours.
//
// Repère du MONDE (celui du carré 0..1 de la figure) : x vers l'AVANT du
// corps (la droite d'un profil), y vers le BAS, z vers le côté PROCHE (vers
// la caméra d'un profil pur).

import 'dart:math' as math;
import 'dart:ui';

class V3 {
  const V3(this.x, this.y, this.z);

  final double x, y, z;

  static const V3 zero = V3(0, 0, 0);
  static const V3 avant = V3(1, 0, 0);
  static const V3 bas = V3(0, 1, 0);
  static const V3 haut = V3(0, -1, 0);
  static const V3 proche = V3(0, 0, 1);

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);
  V3 operator /(double k) => V3(x / k, y / k, z / k);
  V3 operator -() => V3(-x, -y, -z);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;

  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get norme => math.sqrt(x * x + y * y + z * z);

  V3 get unite {
    final n = norme;
    return n < 1e-12 ? const V3(0, 1, 0) : this / n;
  }

  static V3 lerp(V3 a, V3 b, double t) => a + (b - a) * t;

  /// Tourne autour de l'axe [axe] (unitaire) de [angle] radians (Rodrigues).
  V3 tourne(V3 axe, double angle) {
    final c = math.cos(angle), s = math.sin(angle);
    return this * c + axe.cross(this) * s + axe * (axe.dot(this) * (1 - c));
  }

  /// La composante perpendiculaire à [axe] (unitaire).
  V3 sansComposante(V3 axe) => this - axe * dot(axe);

  @override
  String toString() =>
      'V3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, '
      '${z.toStringAsFixed(3)})';
}

double rad(double degres) => degres * math.pi / 180;

/// La direction d'un segment : [theta] dans le plan sagittal (0 = avant,
/// 90 = bas, −90 = haut, 180 = arrière), puis écartée de [ecart] degrés hors
/// de ce plan, vers son côté ([cote] : +1 proche, −1 loin). Un bras le long
/// du corps (90) écarté de 90 est à l'horizontale sur le côté ; de 180, il
/// est au-dessus de la tête.
V3 direction(double theta, double ecart, double cote) {
  final t = rad(theta), a = rad(ecart);
  return V3(
    math.cos(t) * math.cos(a),
    math.sin(t) * math.cos(a),
    math.sin(a) * cote,
  );
}

/// Cinématique inverse à deux segments : de [racine] vers [cible], avec des
/// longueurs [l1] puis [l2], l'articulation du milieu poussée vers [pole].
/// Rend (milieu, bout) — le bout s'arrête avant la cible si elle est hors de
/// portée.
(V3, V3) deuxSegments(V3 racine, V3 cible, double l1, double l2, V3 pole) {
  final d0 = cible - racine;
  final dist = d0.norme.clamp((l1 - l2).abs() + 1e-4, l1 + l2 - 1e-4);
  final dir = d0.unite;
  final a = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist);
  final h = math.sqrt(math.max(0, l1 * l1 - a * a));
  var p = pole.sansComposante(dir);
  if (p.norme < 1e-6) p = V3.avant.sansComposante(dir);
  final milieu = racine + dir * a + p.unite * h;
  return (milieu, racine + dir * dist);
}

// ═══ Contours 2D ════════════════════════════════════════════════════════════

/// L'enveloppe convexe de points (Andrew), dans le sens trigonométrique.
List<Offset> enveloppe(List<Offset> pts) {
  if (pts.length < 3) return [...pts];
  final p = [
    ...pts,
  ]..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  double croix(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  final bas = <Offset>[];
  for (final q in p) {
    while (bas.length >= 2 && croix(bas[bas.length - 2], bas.last, q) <= 0) {
      bas.removeLast();
    }
    bas.add(q);
  }
  final haut = <Offset>[];
  for (final q in p.reversed) {
    while (haut.length >= 2 &&
        croix(haut[haut.length - 2], haut.last, q) <= 0) {
      haut.removeLast();
    }
    haut.add(q);
  }
  bas.removeLast();
  haut.removeLast();
  return [...bas, ...haut];
}

/// Une courbe fermée lisse passant par [p] (Catmull-Rom).
Path fermeLisse(List<Offset> p, {double tension = 1}) {
  final n = p.length;
  final chemin = Path();
  if (n == 0) return chemin;
  chemin.moveTo(p[0].dx, p[0].dy);
  if (n < 3) {
    for (final q in p.skip(1)) {
      chemin.lineTo(q.dx, q.dy);
    }
    return chemin..close();
  }
  for (var i = 0; i < n; i++) {
    final p0 = p[(i - 1 + n) % n], p1 = p[i];
    final p2 = p[(i + 1) % n], p3 = p[(i + 2) % n];
    final c1 = p1 + (p2 - p0) * (tension / 6);
    final c2 = p2 - (p3 - p1) * (tension / 6);
    chemin.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return chemin..close();
}

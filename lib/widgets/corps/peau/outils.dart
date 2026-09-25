// lib/widgets/corps/peau/outils.dart
//
// Les outils de la peau : courbes douces, cloches, rotations, profils de
// rayon (Hermite), reliefs de muscles et formes des muscles travaillés.

part of '../peau3.dart';

double _lisse(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// L'écart entre deux angles (degrés), de 0 à 180.
double _ecart(double a, double b) {
  var d = a - b;
  if (d > 180 || d < -180) d -= 360 * (d / 360).roundToDouble();
  return d < 0 ? -d : d;
}

/// Une cloche de [a] à [b] (nulle aux bords, 1 au milieu).
double _cloche(double x, double a, double b) {
  if (x <= a || x >= b) return 0;
  final s = math.sin(math.pi * (x - a) / (b - a));
  return s * s;
}

/// Une bosse ronde de rayon 1 (1 au centre, 0 au-delà), sans racine.
double _rond(double d2) {
  if (d2 >= 1) return 0;
  final c = 1 - d2;
  return c * c;
}

/// Une rotation (matrice 3 × 3) autour d'un axe unitaire.
class _Rot {
  _Rot(V3 k, double a) {
    final c = math.cos(a), s = math.sin(a), t = 1 - c;
    final x = k.x, y = k.y, z = k.z;
    m00 = t * x * x + c;
    m01 = t * x * y - s * z;
    m02 = t * x * z + s * y;
    m10 = t * x * y + s * z;
    m11 = t * y * y + c;
    m12 = t * y * z - s * x;
    m20 = t * x * z - s * y;
    m21 = t * y * z + s * x;
    m22 = t * z * z + c;
  }

  late final double m00, m01, m02, m10, m11, m12, m20, m21, m22;

  V3 de(V3 v) => V3(
    m00 * v.x + m01 * v.y + m02 * v.z,
    m10 * v.x + m11 * v.y + m12 * v.z,
    m20 * v.x + m21 * v.y + m22 * v.z,
  );
}

/// Un profil de rayon le long d'une partie : (s, devant, derrière, côté).
typedef _Profil = List<(double, double, double, double)>;

/// Le profil en [s] : une courbe d'Hermite (sans les méplats d'une
/// interpolation « lissée » station par station, qui se voyaient en bandes).
(double, double, double) _profil(_Profil p, double s) {
  final (a, b, c) = _hermite(p, s);
  return (math.max(0.0015, a), math.max(0.0015, b), math.max(0.0015, c));
}

(double, double, double) _hermite(_Profil p, double s) {
  if (s <= p.first.$1) return (p.first.$2, p.first.$3, p.first.$4);
  if (s >= p.last.$1) return (p.last.$2, p.last.$3, p.last.$4);
  var i = 0;
  while (s > p[i + 1].$1) {
    i++;
  }
  final h = p[i + 1].$1 - p[i].$1;
  final u = (s - p[i].$1) / h;
  final u2 = u * u, u3 = u2 * u;
  final h00 = 2 * u3 - 3 * u2 + 1, h10 = u3 - 2 * u2 + u;
  final h01 = -2 * u3 + 3 * u2, h11 = u3 - u2;
  double v(int k, int c) => switch (c) {
    0 => p[k].$2,
    1 => p[k].$3,
    _ => p[k].$4,
  };
  double pente(int k, int c) {
    final a = math.max(0, k - 1), b = math.min(p.length - 1, k + 1);
    return (v(b, c) - v(a, c)) / (p[b].$1 - p[a].$1);
  }

  double f(int c) =>
      h00 * v(i, c) +
      h10 * h * pente(i, c) +
      h01 * v(i + 1, c) +
      h11 * h * pente(i + 1, c);
  return (f(0), f(1), f(2));
}

/// Le rayon d'un profil dans la direction de cosinus [cph] avec l'avant (le
/// côté cède la place au devant, ou au derrière, comme |cos|^1,4 — ici
/// en polynôme : c'est calculé pour chaque sommet, à chaque image).
double _rayonDe((double, double, double) r, double cph) {
  final (devant, derriere, cote) = r;
  final a = cph.abs();
  return cote + ((cph >= 0 ? devant : derriere) - cote) * a * (0.6 + 0.4 * a);
}

/// x^0,85 (0 ≤ x ≤ 1), en polynôme : la section un peu carrée du tronc.
double _carre(double x) => x * (1.3 - 0.3 * x);

/// x^n pour un entier n ≥ 1 (le reflet), par carrés successifs.
double _puissance(double x, int n) {
  var r = 1.0, b = x, e = n;
  while (e > 0) {
    if (e & 1 == 1) r *= b;
    b *= b;
    e >>= 1;
  }
  return r;
}

/// Un RELIEF de muscle (ou un creux, [h] < 0) : de [s0] à [s1], le plus
/// haut à la fraction [pic], centré sur l'angle [c], large de [l] degrés de
/// part et d'autre. [bord] : la netteté du bord (0 : une cloche, 1 : un
/// muscle dessiné, dont le bord tombe franchement — le bas du pectoral,
/// les carrés des abdominaux).
class _Bosse {
  const _Bosse(
    this.s0,
    this.s1,
    this.pic,
    this.c,
    this.l,
    this.h, [
    this.bord = 0,
  ]);

  final double s0, s1, pic, c, l, h, bord;

  double en(double s, double phi) {
    final u = (s - s0) / (s1 - s0);
    if (u <= 0 || u >= 1) return 0;
    final d = _ecart(phi, c);
    if (d >= l) return 0;
    final v = u < pic ? 0.5 * u / pic : 0.5 + 0.5 * (u - pic) / (1 - pic);
    // Une cloche en long, une en travers (polynômes, sans trigonométrie).
    var a = 4 * v * (1 - v);
    final x = d / l;
    var b = 1 - x * x;
    if (bord > 0) {
      // Un plateau : le muscle est plein, son bord tombe.
      a = a + (math.sqrt(a) - a) * bord;
      b = b + (math.sqrt(b) - b) * bord;
    }
    return h * a * a * b * b;
  }
}

/// La FORME d'un muscle travaillé : de s0 à s1, et pour chaque fraction u
/// de cette longueur, l'angle de ses deux bords (un profil (u, bord, autre
/// bord, 0)) — le pectoral en éventail, le deltoïde en coiffe, les dorsaux
/// en V, le mollet qui file vers le tendon d'Achille…
typedef _Zone = (Muscle, double, double, _Profil);

/// Une AMANDE : centrée sur [c], demi-ouverture [ouv] au milieu, effilée aux
/// deux bouts (le biceps, le triceps).
_Profil _amande(double c, double ouv) => [
  for (final u in const [0.0, 0.15, 0.32, 0.5, 0.68, 0.85, 1.0])
    (
      u,
      c - ouv * (0.12 + 0.88 * math.pow(math.sin(math.pi * u), 0.6)),
      c + ouv * (0.12 + 0.88 * math.pow(math.sin(math.pi * u), 0.6)),
      0,
    ),
];

/// La même forme, de l'autre côté du corps.
_Profil _miroir(_Profil p) => [for (final (u, a, b, _) in p) (u, -b, -a, 0)];

/// Un bruit de valeur lisse (déterministe) : les mèches, le grain.
double _bruit(double x, double y) {
  final xi = x.floorToDouble(), yi = y.floorToDouble();
  final fx = x - xi, fy = y - yi;
  double h(double a, double b) {
    final n = math.sin(a * 127.1 + b * 311.7) * 43758.5453;
    return n - n.floorToDouble();
  }

  final ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy);
  final a = h(xi, yi), b = h(xi + 1, yi);
  final c = h(xi, yi + 1), d = h(xi + 1, yi + 1);
  return a + (b - a) * ux + (c - a) * uy + (a - b - c + d) * ux * uy;
}

/// Le même bruit, PÉRIODIQUE autour de la tête (pas de couture à 180°) :
/// [phi] en degrés, [echelle] : le nombre de motifs sur un tour (environ).
double _bruitTour(double phi, double echelle, double x0, double y) {
  final a = rad(phi), r = echelle / (2 * math.pi) * 2.2;
  return _bruit(x0 + r * math.cos(a), y + r * math.sin(a));
}

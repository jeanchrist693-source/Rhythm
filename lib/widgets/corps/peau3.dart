// lib/widgets/corps/peau3.dart
//
// La PEAU du corps (25 sept. 2026). L'utilisateur, une fois les mouvements
// jugés naturels : « au niveau de ses muscles ou des membres qui bougent, on
// dirait un jouet en caoutchouc, monté de toutes pièces ». Le corps était un
// assemblage de tubes à bouts ronds, cernés chacun de noir et posés les uns
// sur les autres — un coude, un genou plié montraient deux capsules
// empilées ; les muscles étaient des aplats collés dessus ; rien ne changeait
// de forme en bougeant.
//
// Chaque partie est maintenant une SURFACE MAILLÉE, peinte triangle par
// triangle, du plus loin au plus proche (`Tampon3`) :
// - un membre est D'UN SEUL TENANT, de l'épaule (la hanche) au poignet (la
//   cheville) : la surface se PLIE à l'articulation — en arc autour du coude,
//   du genou — et se TASSE dans le pli ; sa racine, dans le tronc, suit le
//   tronc puis le membre : l'épaule et la hanche se déforment au lieu d'être
//   des rotules ;
// - les MUSCLES sont des reliefs (deltoïde, biceps, triceps, quadriceps et sa
//   « goutte d'eau », mollets à deux chefs, pectoraux, grand droit, dorsaux,
//   fessiers…) qui se CONTRACTENT : le biceps gonfle et remonte quand le
//   coude plie, le mollet quand on monte sur la pointe des pieds, le fessier
//   quand la hanche s'étend ; le pectoral s'étire quand le bras monte ;
// - un MODELÉ de peau : lumière enveloppante, ombres CHAUDES (une peau n'est
//   jamais grise), bords à peine plus sombres, reflet très doux, plis plus
//   sombres ;
// - un CONTOUR seulement sur la silhouette, là où une partie passe devant
//   une autre — jamais aux jointures (épaule, hanche, poignet, cou).
// Les muscles travaillés sont des FUSEAUX posés sur la peau (corail :
// principaux ; corail doux : secondaires), qui en suivent le relief et la
// lumière.
//
// Chaque partie est une FORME (`_Forme`) : une fonction (s, angle) → point
// de la surface ; le maillage et les fuseaux des muscles en sont tirés.
//
// Repère : celui de `geometrie3.dart` ; un angle autour d'un membre se
// compte en degrés depuis son AVANT (0 : devant — biceps, cuisse, paume —,
// 90 : dehors, 180 : derrière, −90 : dedans) ; autour du tronc, depuis la
// poitrine (90 : le côté proche, −90 : le côté loin).

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../modele/sports/muscles.dart';
import '../../theme/rhythm_couleurs.dart';
import 'geometrie3.dart';
import 'peintre3.dart' show Camera3;
import 'squelette3.dart';

// ═══ Le tampon : les triangles à peindre ════════════════════════════════════

/// Des triangles (sommets à l'écran, une couleur par sommet) et leur
/// PROXIMITÉ (plus grande = plus près), peints du plus loin au plus proche.
class Tampon3 {
  Float32List _pos = Float32List(6 * 6000);
  Int32List _col = Int32List(3 * 6000);
  Float64List _z = Float64List(6000);

  /// Le nombre de triangles.
  int n = 0;

  void _grandir() {
    final m = _z.length * 2;
    final pos = Float32List(6 * m)..setRange(0, 6 * n, _pos);
    final col = Int32List(3 * m)..setRange(0, 3 * n, _col);
    final z = Float64List(m)..setRange(0, n, _z);
    _pos = pos;
    _col = col;
    _z = z;
  }

  void triangle(
    double ax,
    double ay,
    int ca,
    double bx,
    double by,
    int cb,
    double cx,
    double cy,
    int cc,
    double z,
  ) {
    if (n == _z.length) _grandir();
    final p = 6 * n, q = 3 * n;
    _pos[p] = ax;
    _pos[p + 1] = ay;
    _pos[p + 2] = bx;
    _pos[p + 3] = by;
    _pos[p + 4] = cx;
    _pos[p + 5] = cy;
    _col[q] = ca;
    _col[q + 1] = cb;
    _col[q + 2] = cc;
    _z[n] = z;
    n++;
  }

  /// La proximité du triangle [i].
  double z(int i) => _z[i];

  /// L'ordre de peinture, du plus loin au plus proche (tri par paquets :
  /// linéaire, et stable à l'intérieur d'un paquet).
  Int32List ordre() {
    final o = Int32List(n);
    if (n == 0) return o;
    var mn = _z[0], mx = _z[0];
    for (var i = 1; i < n; i++) {
      final v = _z[i];
      if (v < mn) mn = v;
      if (v > mx) mx = v;
    }
    const paquets = 4096;
    final k = mx > mn ? (paquets - 1) / (mx - mn) : 0.0;
    final compte = Int32List(paquets + 1);
    final cle = Int32List(n);
    for (var i = 0; i < n; i++) {
      final b = ((_z[i] - mn) * k).floor();
      cle[i] = b;
      compte[b + 1]++;
    }
    for (var b = 0; b < paquets; b++) {
      compte[b + 1] += compte[b];
    }
    for (var i = 0; i < n; i++) {
      o[compte[cle[i]]++] = i;
    }
    return o;
  }

  /// Peint les triangles [de]..[a] de l'[ordre].
  void peindre(Canvas c, Int32List ordre, int de, int a) {
    final m = a - de;
    if (m <= 0) return;
    final pos = Float32List(m * 6);
    final col = Int32List(m * 3);
    final sp = _pos, sc = _col;
    for (var k = 0; k < m; k++) {
      final i = ordre[de + k];
      final p = 6 * k, q = 6 * i;
      pos[p] = sp[q];
      pos[p + 1] = sp[q + 1];
      pos[p + 2] = sp[q + 2];
      pos[p + 3] = sp[q + 3];
      pos[p + 4] = sp[q + 4];
      pos[p + 5] = sp[q + 5];
      final c3 = 3 * k, i3 = 3 * i;
      col[c3] = sc[i3];
      col[c3 + 1] = sc[i3 + 1];
      col[c3 + 2] = sc[i3 + 2];
    }
    c.drawVertices(
      Vertices.raw(VertexMode.triangles, pos, colors: col),
      BlendMode.dst,
      Paint(),
    );
  }
}

// ═══ Outils ═════════════════════════════════════════════════════════════════

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
/// part et d'autre.
class _Bosse {
  const _Bosse(this.s0, this.s1, this.pic, this.c, this.l, this.h);

  final double s0, s1, pic, c, l, h;

  double en(double s, double phi) {
    final u = (s - s0) / (s1 - s0);
    if (u <= 0 || u >= 1) return 0;
    final d = _ecart(phi, c);
    if (d >= l) return 0;
    final v = u < pic ? 0.5 * u / pic : 0.5 + 0.5 * (u - pic) / (1 - pic);
    // Une cloche en long, une en travers (polynômes, sans trigonométrie).
    final a = 4 * v * (1 - v), x = d / l, b = 1 - x * x;
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

// ═══ Les formes ═════════════════════════════════════════════════════════════

/// Une surface : le point en (s, [phi] degrés), écarté de [plus] vers le
/// dehors ; l'OCCLUSION en ce point (1 : à découvert, moins dans un pli).
abstract class _Forme {
  V3 point(double s, double phi, [double plus = 0]) =>
      pointCS(s, phi, math.cos(rad(phi)), math.sin(rad(phi)), plus);

  /// Le même, le cosinus et le sinus de [phi] déjà calculés (le maillage
  /// les prend dans une table).
  V3 pointCS(double s, double phi, double cph, double sph, double plus);

  double ombre(double s, double phi) => 1;
}

/// Un anneau d'un membre : son origine, son décalage le long de l'axe, son
/// repère (avant, dehors), sa rotation, son profil, son pli.
typedef _Anneau = (V3, V3, V3, V3, _Rot, (double, double, double), double);

/// Un membre d'un seul tenant : de sa racine ([j0], l'épaule ou la hanche)
/// à son bout ([j2]) en passant par [j1] (coude, genou). La RACINE (s <
/// 0,5) part de sa direction de REPOS dans le tronc et s'enroule jusqu'à
/// celle du membre ([racine] : où commence et finit l'enroulement) ; autour
/// de l'articulation (s ≈ 1), la surface tourne progressivement d'un segment
/// à l'autre et se TASSE dans le pli ([tasse] : la part du rayon qui
/// s'écrase, membre replié). Sous l'[ourlet], le short (un peu ample).
class _FormeMembre extends _Forme {
  _FormeMembre({
    required this.j0,
    required this.j1,
    required V3 j2,
    required V3 avant,
    required V3 dehors,
    required this.repos,
    required this.racine,
    required this.profil,
    required List<_Bosse> Function(double phiDedans) bosses,
    required this.tasse,
    this.ourlet = -9,
  }) {
    l1 = (j1 - j0).norme;
    l2 = (j2 - j1).norme;
    d1 = (j1 - j0).unite;
    final d2 = (j2 - j1).unite;
    var a = avant.sansComposante(d1);
    a1 = a.norme < 1e-3 ? d1.cross(dehors).unite : a.unite;
    var o = dehors.sansComposante(d1).sansComposante(a1);
    o1 = o.norme < 1e-3 ? d1.cross(a1).unite : o.unite;
    // La racine : du repos à la direction du membre.
    th0 = math.acos(repos.dot(d1).clamp(-1.0, 1.0));
    var ax = repos.cross(d1);
    ax0 = ax.norme < 1e-4 ? o1 : ax.unite;
    final retour = _Rot(ax0, -th0);
    a0 = retour.de(a1);
    o0 = retour.de(o1);
    // L'articulation.
    final ce = d1.dot(d2).clamp(-1.0, 1.0);
    th1 = math.acos(ce);
    ax = d1.cross(d2);
    ax1 = ax.norme < 1e-4 ? o1 : ax.unite;
    flexion = (1 - ce) / 2;
    phiDedans = th1 < 0.05
        ? 0.0
        : math.atan2(d2.dot(o1), d2.dot(a1)) * 180 / math.pi;
    reliefs = bosses(phiDedans);
  }

  final V3 j0, j1, repos;
  final (double, double) racine;
  final _Profil profil;
  final double tasse, ourlet;
  late final double l1, l2, th0, th1, flexion, phiDedans;
  late final V3 d1, a1, o1, a0, o0, ax0, ax1;
  late final List<_Bosse> reliefs;

  double _sAnneau = double.nan;
  late _Anneau _anneau;

  /// Les reliefs qui touchent l'anneau courant.
  List<_Bosse> _actifs = const [];

  _Anneau _anneauEn(double s) {
    if (s == _sAnneau) return _anneau;
    _sAnneau = s;
    _actifs = [
      for (final b in reliefs)
        if (s > b.s0 && s < b.s1) b,
    ];
    final pli = flexion > 0.01 ? _cloche(s, 0.76, 1.24) * flexion : 0.0;
    if (s < 0.5) {
      _anneau = (
        j0,
        repos * (s * l1),
        a0,
        o0,
        _Rot(ax0, th0 * _lisse(racine.$1, racine.$2, s)),
        _profil(profil, s),
        pli,
      );
    } else {
      _anneau = (
        j1,
        d1 * ((s - 1) * (s < 1 ? l1 : l2)),
        a1,
        o1,
        _Rot(ax1, th1 * _lisse(0.9, 1.1, s)),
        _profil(profil, s),
        pli,
      );
    }
    return _anneau;
  }

  /// La part du pli en ce point (0 : hors du pli).
  double _pli(double pli, double phi) {
    if (pli <= 0) return 0;
    final e = _ecart(phi, phiDedans) / 85;
    if (e >= 1) return 0;
    final c = 1 - e * e;
    return pli * c * c;
  }

  @override
  V3 pointCS(double s, double phi, double cph, double sph, double plus) {
    final (base, long, a, o, rot, pr, pli) = _anneauEn(s);
    var r = _rayonDe(pr, cph);
    for (final b in _actifs) {
      r += b.en(s, phi);
    }
    r *= 1 - tasse * _pli(pli, phi);
    if (s < ourlet - 1e-6) r += 0.0035;
    r += plus;
    // base + rot(long + (a cos + o sin) r), sans objets intermédiaires.
    final vx = long.x + (a.x * cph + o.x * sph) * r;
    final vy = long.y + (a.y * cph + o.y * sph) * r;
    final vz = long.z + (a.z * cph + o.z * sph) * r;
    return V3(
      base.x + rot.m00 * vx + rot.m01 * vy + rot.m02 * vz,
      base.y + rot.m10 * vx + rot.m11 * vy + rot.m12 * vz,
      base.z + rot.m20 * vx + rot.m21 * vy + rot.m22 * vz,
    );
  }

  @override
  double ombre(double s, double phi) => 1 - 0.45 * _pli(_anneauEn(s).$7, phi);
}

/// Le TRONC : un volume balayé le long du dos (bassin → cou), section un peu
/// carrée (une superellipse, pas un tuyau), plus profonde devant (la
/// poitrine) ou derrière (les fessiers) ; le short jusqu'à la taille.
class _FormeTronc extends _Forme {
  _FormeTronc(this.s, this.reliefs, this.souffle, this.soudures) {
    final t1 = s.cou - s.dosControle;
    _t1 = t1.norme < 1e-6 ? s.dirTronc : t1.unite;
    _versTete = (s.tete - s.cou).unite;
  }

  final Squelette3 s;
  final List<_Bosse> reliefs;
  final double souffle;

  /// Là où le tronc épouse un autre volume (le dôme de l'épaule).
  final List<_Capsule> soudures;
  late final V3 _t1, _versTete;

  /// Le tronc : stations le long du dos (0 au bassin, 1 à la base du cou,
  /// puis le COU, d'un seul tenant avec le tronc, jusque dans la tête) —
  /// demi-largeur, profondeur devant, profondeur derrière.
  static const _Profil _stations = [
    (-0.27, 0.004, 0.004, 0.004),
    (-0.24, 0.04, 0.03, 0.036),
    (-0.12, 0.07, 0.046, 0.066),
    (0.02, 0.068, 0.048, 0.056),
    (0.25, 0.056, 0.046, 0.042),
    (0.48, 0.066, 0.052, 0.046),
    (0.68, 0.084, 0.064, 0.052),
    (0.84, 0.09, 0.056, 0.053),
    (0.96, 0.078, 0.038, 0.046),
    (1.03, 0.046, 0.029, 0.033),
    (1.09, 0.028, 0.025, 0.027),
    (1.18, 0.024, 0.023, 0.025),
    (1.24, 0.02, 0.019, 0.021),
    (1.28, 0.004, 0.004, 0.004),
  ];

  static const double taille = 0.1;

  V3 _dos(double t) {
    if (t <= 1 && t >= 0) {
      final u = 1 - t;
      return s.bassin * (u * u) + s.dosControle * (2 * u * t) + s.cou * (t * t);
    }
    if (t < 0) return s.bassin + s.dirTronc * (t * lTronc);
    // Le cou : il part dans le prolongement du dos et s'incline vers la
    // tête.
    final u = (t - 1) * lTronc;
    const k = 0.012;
    return s.cou +
        _versTete * u +
        (_t1 - _versTete) * (k * (1 - math.exp(-u / k)));
  }

  double _tAnneau = double.nan;
  late (V3, V3, V3, double, double, double) _anneau;
  List<_Bosse> _actifs = const [];

  (V3, V3, V3, double, double, double) _anneauEn(double t) {
    if (t == _tAnneau) return _anneau;
    _tAnneau = t;
    _actifs = [
      for (final b in reliefs)
        if (t > b.s0 && t < b.s1) b,
    ];
    final c = _dos(t);
    final tan = (_dos(t + 0.02) - _dos(t - 0.02)).unite;
    final u = (t + 0.1).clamp(0.0, 1.0);
    var lat = V3.lerp(s.lateralBassin, s.lateralEpaules, u).sansComposante(tan);
    lat = lat.norme < 1e-3 ? s.lateralBassin : lat.unite;
    final av = lat.cross(tan).unite;
    final (w, f, k) = _profil(_stations, t);
    return _anneau = (
      c,
      lat,
      av,
      w,
      f * (1 + 0.025 * souffle * _cloche(t, 0.42, 0.98)),
      k,
    );
  }

  @override
  V3 pointCS(double t, double phi, double cp, double sp, double plus) {
    final (c, lat, av, w, f, k) = _anneauEn(t);
    final ex = cp.sign * _carre(cp.abs()) * (cp >= 0 ? f : k);
    final ey = sp.sign * _carre(sp.abs()) * w;
    var h = plus;
    for (final b in _actifs) {
      h += b.en(t, phi);
    }
    if (t < taille - 1e-6) h += 0.003;
    final ox = av.x * ex + lat.x * ey;
    final oy = av.y * ex + lat.y * ey;
    final oz = av.z * ex + lat.z * ey;
    final n = math.sqrt(ox * ox + oy * oy + oz * oz);
    final g = n < 1e-9 ? 1.0 : 1 + h / n;
    return _souder(V3(c.x + ox * g, c.y + oy * g, c.z + oz * g), soudures);
  }
}

/// Un volume que la peau d'une autre partie ÉPOUSE (au lieu de le
/// traverser : une intersection se dessinait en dents de scie) : de [a] à
/// b, de rayon [r] (a = b : une sphère).
class _Capsule {
  _Capsule(this.a, V3 b, this.r) : ab = b - a {
    l2 = ab.dot(ab);
    final lim = r + math.sqrt(l2);
    lim2 = lim * lim;
  }

  final V3 a, ab;
  final double r;
  late final double l2, lim2;

  /// Le point de l'axe le plus proche de (x, y, z).
  V3 _axe(double x, double y, double z) {
    if (l2 < 1e-12) return a;
    final u = ((x - a.x) * ab.x + (y - a.y) * ab.y + (z - a.z) * ab.z) / l2;
    return a + ab * (u < 0 ? 0.0 : (u > 1 ? 1.0 : u));
  }
}

/// À combien de rayons de la plus proche des capsules est le point [p].
double _presDe(V3 p, List<_Capsule> capsules) {
  var m = double.infinity;
  for (final c in capsules) {
    m = math.min(m, (p - c._axe(p.x, p.y, p.z)).norme / c.r);
  }
  return m;
}

/// Le point [p], repoussé à la surface des capsules qui le contiennent.
V3 _souder(V3 p, List<_Capsule> capsules) {
  var q = p;
  for (final c in capsules) {
    // Loin de la capsule : rien à faire (le cas de presque tous les points).
    final ex = q.x - c.a.x, ey = q.y - c.a.y, ez = q.z - c.a.z;
    if (ex * ex + ey * ey + ez * ez > c.lim2) continue;
    final axe = c._axe(q.x, q.y, q.z);
    final d = q - axe;
    final n = d.norme;
    if (n < c.r && n > 1e-9) q = axe + d * (c.r / n);
  }
  return q;
}

// ═══ Les matières ═══════════════════════════════════════════════════════════

/// Une matière : sa couleur, la teinte de son ombre (par canal), son
/// reflet.
class _Matiere {
  const _Matiere(
    this.couleur, {
    this.ombre = (0.5, 0.5, 0.56),
    this.brillance = 0.04,
    this.exposant = 14,
    this.peau = false,
  });

  final int couleur;
  final (double, double, double) ombre;
  final double brillance;
  final int exposant;

  /// Une peau : un rien de rouge dans la transition ombre / lumière.
  final bool peau;
}

const _Matiere _peau = _Matiere(
  0xFFE6DACD,
  ombre: (0.58, 0.45, 0.43),
  brillance: 0.06,
  exposant: 20,
  peau: true,
);
const _Matiere _short = _Matiere(0xFF394356, brillance: 0.03, exposant: 8);
const _Matiere _ceinture = _Matiere(0xFF46526B, brillance: 0.03, exposant: 8);
const _Matiere _chaussure = _Matiere(
  0xFFE0E0E6,
  ombre: (0.52, 0.52, 0.58),
  brillance: 0.09,
  exposant: 16,
);
const _Matiere _semelle = _Matiere(0xFF6A6B73);
const _Matiere _chaussette = _Matiere(
  0xFFEDEDF1,
  ombre: (0.52, 0.52, 0.58),
  brillance: 0.03,
  exposant: 8,
);
const _Matiere _cheveux = _Matiere(
  0xFF2E2622,
  ombre: (0.62, 0.6, 0.6),
  brillance: 0.015,
  exposant: 4,
);

/// Un muscle travaillé : sa teinte, modelée comme la peau.
_Matiere _muscle(int couleur) => _Matiere(
  couleur,
  ombre: (0.58, 0.42, 0.42),
  brillance: 0.06,
  exposant: 20,
  peau: true,
);

const int _trait = 0xFF0C0909;
const int _yeux = 0xFF2A2522;

/// La lumière : d'en haut, à gauche, un peu devant (celle du matériel).
final V3 _lumiere = const V3(-0.35, -0.8, 0.5).unite;

// ═══ Une nappe de sommets ═══════════════════════════════════════════════════

/// Une surface en GRILLE : [rangs] anneaux de [cols] sommets (les colonnes
/// bouclent si [boucle]). Une matière par case.
class _Grille {
  _Grille(this.rangs, this.cols, {this.boucle = true})
    : x = Float64List(rangs * cols),
      y = Float64List(rangs * cols),
      z = Float64List(rangs * cols),
      trait = Float64List(rangs * cols)..fillRange(0, rangs * cols, 1),
      ao = Float64List(rangs * cols)..fillRange(0, rangs * cols, 1),
      matiere = Uint8List((rangs - 1) * (boucle ? cols : cols - 1));

  final int rangs, cols;
  final bool boucle;
  final Float64List x, y, z;

  /// L'épaisseur du contour en ce sommet (0 : pas de contour — une
  /// jointure).
  final Float64List trait;

  /// L'occlusion (les plis).
  final Float64List ao;

  /// La matière de chaque case (indice dans la liste passée à `_emettre`).
  final Uint8List matiere;

  /// Les anneaux (le s de chacun), pour retrouver la case d'un point.
  List<double>? ss;

  /// La proximité de chaque case, une fois émise.
  Float64List? zCases;

  /// La case qui contient le point (s, [phi]) de la forme.
  int caseEn(double s, double phi) {
    final a = ss!;
    var i = 0;
    while (i < a.length - 2 && s >= a[i + 1]) {
      i++;
    }
    final j = ((phi % 360) / 360 * cols).floor() % cols;
    return i * casesParRang + j;
  }

  int get casesParRang => boucle ? cols : cols - 1;

  void poser(int k, V3 p) {
    x[k] = p.x;
    y[k] = p.y;
    z[k] = p.z;
  }
}

// ═══ La peau ═════════════════════════════════════════════════════════════════

class Peau3 {
  Peau3({
    required this.camera,
    required this.cote,
    this.principaux = const {},
    this.secondaires = const {},
    this.respiration = 0,
  }) : fin = cote >= 140;

  final Camera3 camera;

  /// La taille du carré 0..1, en pixels.
  final double cote;
  final Set<Muscle> principaux;
  final Set<Muscle> secondaires;
  final double respiration;

  /// Le maillage fin (grandes figures) ou léger (miniatures).
  final bool fin;

  late final double _cl = math.cos(rad(camera.lacet));
  late final double _sl = math.sin(rad(camera.lacet));
  late final double _ct = math.cos(rad(camera.tangage));
  late final double _st = math.sin(rad(camera.tangage));
  late final V3 _vers = camera.vers;
  late final V3 _mi = (_lumiere + _vers).unite;
  late final double _largeurTrait = cote * 0.0032;
  late Tampon3 _t;

  static final _Matiere _principal = _muscle(0xFFFF8A7A);
  static final _Matiere _secondaire = _muscle(
    Color.lerp(
      RhythmCouleurs.corail,
      const Color(0xFFE6DACD),
      0.55,
    )!.toARGB32(),
  );

  _Matiere? _teinteDe(Muscle m) => principaux.contains(m)
      ? _principal
      : (secondaires.contains(m) ? _secondaire : null);

  /// Tout le corps, dans le tampon.
  void habiller(Squelette3 s, Tampon3 t) {
    _t = t;
    _tronc(s);
    _tete(s);
    _bras(s, s.brasP, 1);
    _bras(s, s.brasL, -1);
    _jambe(s, s.jambeP, 1, s.talonP);
    _jambe(s, s.jambeL, -1, s.talonL);
  }

  // ── Une forme en maillage ────────────────────────────────────────────────

  /// La forme maillée : un anneau par [ss], [cols] sommets par anneau ;
  /// [trait] : l'épaisseur du contour selon s.
  _Grille _nappe(
    _Forme f,
    List<double> ss,
    int cols,
    double Function(double s) trait,
  ) {
    final g = _Grille(ss.length, cols)..ss = ss;
    final (cs, sn) = _table(cols);
    for (var i = 0; i < ss.length; i++) {
      final s = ss[i];
      final tr = trait(s);
      for (var j = 0; j < cols; j++) {
        final k = i * cols + j;
        final phi = 360.0 * j / cols;
        g.poser(k, f.pointCS(s, phi, cs[j], sn[j], 0));
        g.trait[k] = tr;
        g.ao[k] = f.ombre(s, phi);
      }
    }
    _creux(g);
    return g;
  }

  static final Map<int, (Float64List, Float64List)> _tables = {};

  /// Le cosinus et le sinus de chaque colonne d'un anneau de [n] sommets.
  static (Float64List, Float64List) _table(int n) => _tables.putIfAbsent(n, () {
    final c = Float64List(n), s = Float64List(n);
    for (var j = 0; j < n; j++) {
      c[j] = math.cos(2 * math.pi * j / n);
      s[j] = math.sin(2 * math.pi * j / n);
    }
    return (c, s);
  });

  /// Les CREUX entre deux reliefs (le sillon du deltoïde, celui du
  /// quadriceps…) un peu plus sombres, les bosses un rien plus claires : le
  /// relief se lit, comme sur une vraie musculature.
  static void _creux(_Grille g) {
    final n = g.rangs, c = g.cols;
    final r = Float64List(n * c);
    for (var i = 0; i < n; i++) {
      var cx = 0.0, cy = 0.0, cz = 0.0;
      for (var j = 0; j < c; j++) {
        cx += g.x[i * c + j];
        cy += g.y[i * c + j];
        cz += g.z[i * c + j];
      }
      cx /= c;
      cy /= c;
      cz /= c;
      for (var j = 0; j < c; j++) {
        final k = i * c + j;
        final dx = g.x[k] - cx, dy = g.y[k] - cy, dz = g.z[k] - cz;
        r[k] = math.sqrt(dx * dx + dy * dy + dz * dz);
      }
    }
    for (var i = 1; i < n - 1; i++) {
      for (var j = 0; j < c; j++) {
        final k = i * c + j;
        final autour =
            (r[k - c] +
                r[k + c] +
                r[i * c + (j + 1) % c] +
                r[i * c + (j - 1 + c) % c]) /
            4;
        if (autour < 1e-4) continue;
        final creux = (autour - r[k]) / autour;
        g.ao[k] *= (1 - 3 * creux).clamp(0.82, 1.05);
      }
    }
  }

  /// Les FUSEAUX des muscles travaillés, posés sur la forme : nets, en
  /// amande, un rien au-dessus de la peau, et peints JUSTE APRÈS les cases de
  /// peau qu'ils recouvrent (la plus proche des quatre coins) — un décalage
  /// fixe laissait la peau repasser par-dessus, en rayures.
  void _fuseaux(_Forme f, List<_Zone> zones, _Grille peau) {
    final rangs = fin ? 11 : 7, cols = fin ? 9 : 5;
    for (final z in zones) {
      final m = _teinteDe(z.$1);
      if (m == null) continue;
      final (_, s0, s1, bords) = z;
      final g = _Grille(rangs, cols, boucle: false);
      final cases = Int32List(rangs * cols);
      for (var i = 0; i < rangs; i++) {
        final u = i / (rangs - 1);
        final s = s0 + (s1 - s0) * u;
        final (b0, b1, _) = _hermite(bords, u);
        for (var j = 0; j < cols; j++) {
          final phi = b0 + (b1 - b0) * j / (cols - 1);
          final k = i * cols + j;
          g.poser(k, f.point(s, phi, 0.0006));
          g.trait[k] = 0;
          cases[k] = peau.caseEn(s, phi);
          // L'ombre de la peau dessous (plis et creux compris).
          g.ao[k] = peau.ao[cases[k]];
        }
      }
      _emettre(g, [m], zImpose: _ancrer(peau, g, cases));
    }
  }

  /// La proximité de chaque case de [g], posée sur [peau] ([cases] : la
  /// case de peau sous chaque sommet) : juste devant la plus proche des
  /// cases de peau sous ses quatre coins.
  static Float64List _ancrer(_Grille peau, _Grille g, Int32List cases) {
    final zp = peau.zCases!;
    final cols = g.cols, qc = g.casesParRang;
    final zq = Float64List((g.rangs - 1) * qc);
    for (var i = 0; i < g.rangs - 1; i++) {
      for (var j = 0; j < qc; j++) {
        final a = i * cols + j, b = a + cols;
        final j1 = (j + 1) % cols;
        final c = (i + 1) * cols + j1, d = i * cols + j1;
        // Les rangées de peau entre les coins (une case de fuseau peut en
        // enjamber une), pour chacune des colonnes des coins.
        final pq = peau.casesParRang;
        var i0 = 1 << 30, i1 = -1;
        for (final v in [cases[a], cases[b], cases[c], cases[d]]) {
          final r = v ~/ pq;
          if (r < i0) i0 = r;
          if (r > i1) i1 = r;
        }
        var z = -double.infinity;
        for (final v in [cases[a], cases[b], cases[c], cases[d]]) {
          final col = v % pq;
          for (var r = i0; r <= i1; r++) {
            final zz = zp[r * pq + col];
            if (zz > z) z = zz;
          }
        }
        zq[i * qc + j] = z + 1e-6;
      }
    }
    return zq;
  }

  // ── Les bras ─────────────────────────────────────────────────────────────

  /// L'avant d'un segment du bras (le côté du biceps, de la paume).
  static V3 _avantBras(Squelette3 s, V3 dir) {
    var f = s.avantEpaules.sansComposante(dir);
    final n = f.norme;
    if (n < 0.35) {
      final haut = (-s.dirTronc).sansComposante(dir);
      f = f + haut.unite * ((0.35 - n) * 3);
    }
    return f.unite;
  }

  static const _Profil _profilBras = [
    (-0.19, 0.003, 0.003, 0.003),
    (-0.15, 0.017, 0.018, 0.019),
    (-0.09, 0.028, 0.03, 0.032),
    (0.0, 0.034, 0.036, 0.038),
    (0.15, 0.033, 0.034, 0.036),
    (0.4, 0.028, 0.029, 0.027),
    (0.7, 0.024, 0.025, 0.023),
    (0.9, 0.022, 0.023, 0.022),
    (1.0, 0.021, 0.022, 0.023),
    (1.18, 0.023, 0.022, 0.024),
    (1.5, 0.019, 0.018, 0.02),
    (1.8, 0.016, 0.015, 0.018),
    (1.96, 0.0135, 0.013, 0.017),
    (2.03, 0.011, 0.01, 0.013),
    (2.07, 0.003, 0.003, 0.003),
  ];

  static const List<double> _ssBrasFin = [
    -0.19, -0.16, -0.12, -0.07, -0.02, 0.05, 0.12, 0.2, 0.29, 0.38, //
    0.47, 0.56, 0.65, 0.74, 0.82, 0.88, 0.93, 0.97, 1.0, 1.03, //
    1.07, 1.12, 1.19, 1.28, 1.38, 1.49, 1.6, 1.71, 1.81, 1.9, //
    1.96, 2.02, 2.07,
  ];
  static const List<double> _ssBrasLeger = [
    -0.19, -0.13, -0.05, 0.05, 0.18, 0.34, 0.5, 0.66, 0.8, 0.9, //
    0.97, 1.03, 1.1, 1.24, 1.42, 1.6, 1.78, 1.92, 2.02, 2.07,
  ];

  static final List<_Zone> _zonesBras = [
    // Le deltoïde : une coiffe, large sur l'épaule, en pointe sur le bras.
    (
      Muscle.epaules,
      -0.12,
      0.46,
      const [
        (0.0, -30, 210, 0),
        (0.3, 0, 180, 0),
        (0.6, 38, 142, 0),
        (0.85, 70, 110, 0),
        (1.0, 86, 94, 0),
      ],
    ),
    (Muscle.biceps, 0.26, 0.93, _amande(0, 50)),
    (Muscle.triceps, 0.16, 0.93, _amande(180, 60)),
    // L'avant-bras : large au coude, fin au poignet.
    (
      Muscle.avantBras,
      1.04,
      1.76,
      const [(0.0, -100, 100, 0), (0.45, -85, 90, 0), (1.0, -18, 18, 0)],
    ),
  ];

  void _bras(Squelette3 s, Membre3 b, double cote) {
    final d1 = (b.milieu - b.racine).unite;
    final d2 = (b.bout - b.milieu).unite;
    // Le bras monte (0 : le long du corps, 1 : au-dessus de la tête), le
    // coude plie (0 : tendu, 1 : replié).
    final monte = (1 - (-s.dirTronc).dot(d1)) / 2;
    final plie = (1 - d1.dot(d2)) / 2;
    final f = _FormeMembre(
      j0: b.racine,
      j1: b.milieu,
      j2: b.bout,
      avant: _avantBras(s, d1),
      dehors: s.lateralEpaules * cote,
      repos: (-s.dirTronc + s.lateralEpaules * (0.2 * cote)).unite,
      racine: (-0.18, 0.3),
      profil: _profilBras,
      bosses: (dedans) => [
        // Le deltoïde : trois faisceaux, qui se ramassent bras levé.
        _Bosse(-0.12, 0.5, 0.35 - 0.1 * monte, 90, 80, 0.004 + 0.002 * monte),
        const _Bosse(-0.1, 0.42, 0.35, 35, 45, 0.003),
        const _Bosse(-0.1, 0.42, 0.35, 145, 45, 0.003),
        // Le biceps GONFLE et remonte quand le coude plie.
        _Bosse(0.25, 0.93, 0.6 - 0.12 * plie, 0, 62, 0.0025 + 0.0065 * plie),
        // Le triceps, plus dessiné bras tendu.
        _Bosse(0.12, 0.85, 0.38, 170, 55, 0.0045 - 0.0015 * plie),
        const _Bosse(0.1, 0.62, 0.45, 120, 40, 0.003),
        // La pointe du coude, qui ressort bras plié.
        _Bosse(0.92, 1.07, 0.55, dedans + 180, 40, 0.0015 + 0.003 * plie),
        // L'avant-bras : le long supinateur et les fléchisseurs.
        _Bosse(0.96, 1.55, 0.3, 55, 55, 0.0035 + 0.001 * plie),
        const _Bosse(1.02, 1.55, 0.28, -45, 60, 0.003),
      ],
      tasse: 0.35,
    );
    final g = _nappe(
      f,
      fin ? _ssBrasFin : _ssBrasLeger,
      fin ? 16 : 10,
      (s) => _lisse(-0.02, 0.2, s) * (1 - _lisse(1.94, 2.01, s)),
    );
    _emettre(g, const [_peau]);
    _fuseaux(f, _zonesBras, g);
    _main(s, b, cote);
  }

  // ── Les jambes ───────────────────────────────────────────────────────────

  // La racine reste SOUS la ceinture (elle dépassait du short en dents de
  // scie).
  static const _Profil _profilJambe = [
    (-0.075, 0.004, 0.004, 0.004),
    (-0.055, 0.026, 0.03, 0.029),
    (-0.03, 0.042, 0.048, 0.046),
    (0.02, 0.052, 0.055, 0.052),
    (0.3, 0.05, 0.048, 0.047),
    (0.62, 0.043, 0.04, 0.041),
    (0.86, 0.035, 0.033, 0.035),
    (1.0, 0.031, 0.03, 0.033),
    (1.12, 0.029, 0.031, 0.032),
    (1.3, 0.027, 0.03, 0.03),
    (1.6, 0.021, 0.022, 0.022),
    (1.88, 0.016, 0.016, 0.018),
    (2.0, 0.016, 0.016, 0.018),
    (2.06, 0.013, 0.013, 0.014),
    (2.1, 0.004, 0.004, 0.004),
  ];

  /// L'ourlet du short, sur la cuisse ; le haut de la soquette (qui
  /// habille la jonction avec la chaussure).
  static const double _ourlet = 0.34;
  static const double _soquette = 1.84;

  static const List<double> _ssJambeFin = [
    -0.075, -0.062, -0.047, -0.03, -0.01, 0.03, 0.1, 0.17, 0.24, 0.3, 0.336, //
    0.34, 0.4, 0.48, 0.56, 0.64, 0.72, 0.79, 0.85, 0.9, 0.94, //
    0.97, 1.0, 1.03, 1.06, 1.1, 1.15, 1.21, 1.28, 1.36, 1.45, //
    1.55, 1.65, 1.75, 1.83, 1.84, 1.92, 1.98, 2.04, 2.1,
  ];
  static const List<double> _ssJambeLeger = [
    -0.075, -0.05, -0.02, 0.03, 0.12, 0.22, 0.3, 0.336, 0.34, 0.46, 0.6, //
    0.74, 0.86, 0.94, 1.0, 1.06, 1.14, 1.26, 1.42, 1.6, 1.78, //
    1.84, 1.92, 2.02, 2.1,
  ];

  static const List<_Zone> _zonesJambe = [
    // Le quadriceps : large sous la hanche, la « goutte » du vaste interne
    // au-dessus du genou, qui se resserre sur la rotule.
    (
      Muscle.quadriceps,
      0.06,
      0.93,
      [
        (0.0, -30, 70, 0),
        (0.3, -52, 78, 0),
        (0.6, -60, 70, 0),
        (0.82, -55, 45, 0),
        (1.0, -14, 14, 0),
      ],
    ),
    (
      Muscle.ischios,
      0.12,
      0.92,
      [
        (0.0, 160, 200, 0),
        (0.3, 132, 228, 0),
        (0.7, 138, 222, 0),
        (1.0, 162, 198, 0),
      ],
    ),
    // Les adducteurs : un triangle, large à l'aine.
    (
      Muscle.adducteurs,
      0.02,
      0.66,
      [(0.0, -135, -45, 0), (0.5, -118, -68, 0), (1.0, -96, -84, 0)],
    ),
    // Le mollet : ses deux chefs en haut, qui filent vers le tendon.
    (
      Muscle.mollets,
      1.04,
      1.68,
      [
        (0.0, 118, 242, 0),
        (0.3, 110, 250, 0),
        (0.62, 138, 222, 0),
        (1.0, 173, 187, 0),
      ],
    ),
  ];

  void _jambe(Squelette3 s, Membre3 j, double cote, V3 talon) {
    final d1 = (j.milieu - j.racine).unite;
    final d2 = (j.bout - j.milieu).unite;
    final plie = (1 - d1.dot(d2)) / 2;
    // Sur la pointe des pieds, le mollet se contracte.
    final pied = (j.extremite - talon).unite;
    final pointe = ((d2.dot(pied) - 0.15) / 0.5).clamp(0.0, 1.0);
    var avant = d1.cross(s.lateralBassin);
    avant = avant.norme < 0.2
        ? s.avantBassin.sansComposante(d1).unite
        : avant.unite;
    final f = _FormeMembre(
      j0: j.racine,
      j1: j.milieu,
      j2: j.bout,
      avant: avant,
      dehors: s.lateralBassin * cote,
      repos: (-s.dirTronc + s.lateralBassin * (0.08 * cote)).unite,
      racine: (-0.075, 0.26),
      profil: _profilJambe,
      bosses: (dedans) => [
        // Le quadriceps : droit, vaste externe, la « goutte » du vaste
        // interne (plus dessinée jambe tendue).
        const _Bosse(0.08, 0.86, 0.45, 0, 45, 0.0035),
        const _Bosse(0.12, 0.86, 0.5, 72, 50, 0.004),
        _Bosse(0.55, 0.97, 0.72, -42, 45, 0.006 - 0.002 * plie),
        const _Bosse(0.12, 0.9, 0.42, 180, 60, 0.003),
        const _Bosse(-0.05, 0.55, 0.3, -95, 45, 0.004),
        // La rotule.
        const _Bosse(0.92, 1.08, 0.5, 0, 42, 0.004),
        // Les deux chefs du mollet, qui gonflent sur la pointe des pieds.
        _Bosse(1.07, 1.52, 0.35, -150, 45, 0.006 + 0.005 * pointe),
        _Bosse(1.07, 1.46, 0.35, 148, 42, 0.005 + 0.004 * pointe),
        const _Bosse(1.05, 1.6, 0.3, 32, 32, 0.0022),
      ],
      tasse: 0.4,
      ourlet: _ourlet,
    );
    final ss = fin ? _ssJambeFin : _ssJambeLeger;
    final cols = fin ? 18 : 12;
    // Pas de contour à la racine (dans le short), ni à l'ourlet (une
    // couture, pas une silhouette).
    final g = _nappe(
      f,
      ss,
      cols,
      (s) =>
          _lisse(0.0, 0.22, s) *
          (1 - _cloche(s, _ourlet - 0.03, _ourlet + 0.02)),
    );
    for (var i = 0; i < ss.length - 1; i++) {
      if (ss[i + 1] <= _ourlet + 1e-6) {
        g.matiere.fillRange(i * cols, (i + 1) * cols, 1);
      } else if (ss[i] >= _soquette - 1e-6) {
        g.matiere.fillRange(i * cols, (i + 1) * cols, 2);
      }
    }
    _emettre(g, const [_peau, _short, _chaussette]);
    _fuseaux(f, _zonesJambe, g);
    _chaussure3(j, talon);
  }

  // ── Le tronc ─────────────────────────────────────────────────────────────

  static const List<double> _tsFin = [
    -0.27, -0.25, -0.21, -0.16, -0.1, -0.04, 0.02, 0.065, 0.097, 0.1, //
    0.15, 0.21, 0.27, 0.33, 0.39, 0.45, 0.51, 0.57, 0.62, 0.67, //
    0.72, 0.77, 0.82, 0.86, 0.9, 0.94, 0.98, 1.02, 1.06, 1.1, //
    1.14, 1.18, 1.22, 1.25, 1.28,
  ];
  static const List<double> _tsLeger = [
    -0.27, -0.23, -0.14, -0.04, 0.05, 0.065, 0.097, 0.1, 0.2, 0.32, //
    0.44, 0.56, 0.66, 0.76, 0.85, 0.93, 1.0, 1.06, 1.13, 1.2, //
    1.25, 1.28,
  ];

  // Le pectoral : un ÉVENTAIL, du sternum vers l'aisselle (deux disques
  // ronds faisaient, de face, un haut de maillot).
  static const _Profil _pectoral = [
    (0.0, 4, 14, 0),
    (0.25, 4, 40, 0),
    (0.5, 4, 57, 0),
    (0.75, 5, 66, 0),
    (1.0, 9, 54, 0),
  ];

  // Le grand dorsal : un V, serré au bas du dos, large sous l'aisselle.
  static const _Profil _dorsal = [
    (0.0, 152, 172, 0),
    (0.35, 132, 174, 0),
    (0.7, 108, 172, 0),
    (0.9, 104, 162, 0),
    (1.0, 118, 150, 0),
  ];
  static const _Profil _fessier = [
    (0.0, 128, 168, 0),
    (0.35, 108, 178, 0),
    (0.7, 110, 178, 0),
    (1.0, 125, 172, 0),
  ];

  static final List<_Zone> _zonesTronc = [
    (Muscle.pectoraux, 0.6, 0.92, _pectoral),
    (Muscle.pectoraux, 0.6, 0.92, _miroir(_pectoral)),
    (
      Muscle.abdos,
      0.15,
      0.63,
      const [
        (0.0, -9, 9, 0),
        (0.08, -12, 12, 0),
        (0.5, -17, 17, 0),
        (0.92, -22, 22, 0),
        (1.0, -18, 18, 0),
      ],
    ),
    (Muscle.dos, 0.38, 0.93, _dorsal),
    (Muscle.dos, 0.38, 0.93, _miroir(_dorsal)),
    // Le trapèze : un losange, de la nuque au milieu du dos.
    (
      Muscle.trapezes,
      0.55,
      1.12,
      const [
        (0.0, 175, 185, 0),
        (0.3, 152, 208, 0),
        (0.6, 128, 232, 0),
        (0.8, 132, 228, 0),
        (0.95, 150, 210, 0),
        (1.0, 160, 200, 0),
      ],
    ),
    (Muscle.lombaires, 0.08, 0.46, _amande(166, 15)),
    (Muscle.lombaires, 0.08, 0.46, _amande(-166, 15)),
    (Muscle.fessiers, -0.24, 0.09, _fessier),
    (Muscle.fessiers, -0.24, 0.09, _miroir(_fessier)),
    (Muscle.obliques, 0.14, 0.58, _amande(64, 20)),
    (Muscle.obliques, 0.14, 0.58, _amande(-64, 20)),
  ];

  void _tronc(Squelette3 s) {
    double monte(Membre3 b) =>
        (1 - (-s.dirTronc).dot((b.milieu - b.racine).unite)) / 2;
    // La hanche en extension (la cuisse derrière le tronc) ou en flexion.
    double etend(Membre3 j) =>
        (-(j.milieu - j.racine).unite.dot(s.avantBassin)).clamp(0.0, 1.0);
    double flechit(Membre3 j) =>
        ((j.milieu - j.racine).unite.dot(s.avantBassin)).clamp(0.0, 1.0);
    final reliefs = <_Bosse>[];
    for (final (c, b, j) in [
      (1.0, s.brasP, s.jambeP),
      (-1.0, s.brasL, s.jambeL),
    ]) {
      final m = monte(b);
      reliefs.addAll([
        // Le pectoral, qui s'étire et remonte quand le bras monte.
        _Bosse(
          0.6 + 0.05 * m,
          0.92 + 0.03 * m,
          0.45 + 0.1 * m,
          28 * c,
          36,
          0.0075 * (1 - 0.35 * m),
        ),
        _Bosse(0.14, 0.5, 0.5, 60 * c, 22, 0.002),
        _Bosse(0.42, 0.86, 0.6, 118 * c, 36, 0.0045),
        _Bosse(0.05, 0.5, 0.4, 168 * c, 12, 0.003),
        _Bosse(0.64, 0.9, 0.55, 146 * c, 26, 0.003),
        _Bosse(0.9, 0.98, 0.5, 42 * c, 32, 0.0018),
        // Le fessier, plus rond hanche tendue.
        _Bosse(
          -0.25,
          0.1,
          0.42,
          150 * c,
          42,
          0.0075 + 0.003 * etend(j) - 0.002 * flechit(j),
        ),
      ]);
    }
    reliefs.addAll(const [
      _Bosse(0.16, 0.62, 0.5, 0, 20, 0.0035),
      _Bosse(0.18, 0.66, 0.5, 0, 5, -0.002),
      _Bosse(0.1, 0.92, 0.5, 180, 9, -0.0028),
      _Bosse(0.84, 1.12, 0.5, 180, 95, 0.0035),
      // Les sterno-cléido-mastoïdiens, de chaque côté du cou.
      _Bosse(1.02, 1.22, 0.5, 40, 22, 0.0018),
      _Bosse(1.02, 1.22, 0.5, -40, 22, 0.0018),
    ]);
    // Le tronc épouse le dôme de chaque épaule (le deltoïde passe par-dessus,
    // sans couture).
    final epaules = [
      _Capsule(s.brasP.racine, s.brasP.racine, 0.032),
      _Capsule(s.brasL.racine, s.brasL.racine, 0.032),
    ];
    final f = _FormeTronc(
      s,
      reliefs,
      math.sin(2 * math.pi * respiration),
      epaules,
    );
    final ts = fin ? _tsFin : _tsLeger;
    final cols = fin ? 24 : 16;
    // Le contour s'efface dans la tête, et à la ceinture (une couture).
    final g = _nappe(
      f,
      ts,
      cols,
      (t) => (1 - _lisse(1.16, 1.24, t)) * (1 - _cloche(t, 0.07, 0.13)),
    );
    for (var k = 0; k < g.x.length; k++) {
      g.trait[k] *= _lisse(
        1.0,
        1.4,
        _presDe(V3(g.x[k], g.y[k], g.z[k]), epaules),
      );
    }
    for (var i = 0; i < ts.length - 1; i++) {
      final haut = ts[i + 1];
      if (haut <= _FormeTronc.taille + 1e-6) {
        g.matiere.fillRange(i * cols, (i + 1) * cols, haut > 0.066 ? 2 : 1);
      }
    }
    _emettre(g, const [_peau, _short, _ceinture]);
    _fuseaux(f, _zonesTronc, g);
  }

  // ── La tête ──────────────────────────────────────────────────────────────

  /// La distance du centre de la tête à sa surface dans la direction
  /// (df, dl, du) de son repère : le crâne et la mâchoire, soudés.
  static double _rayonTete(double df, double dl, double du) {
    final crane = _rayonEllipsoide(df, dl, du, 0, 0, 0, 0.047, 0.042, 0.051);
    final machoire = _rayonEllipsoide(
      df,
      dl,
      du,
      0.016,
      0,
      -0.03,
      0.034,
      0.031,
      0.025,
    );
    // Un maximum ADOUCI : pas d'arête là où la mâchoire rejoint le crâne.
    const k = 0.008;
    final h = math.max(k - (crane - machoire).abs(), 0.0) / k;
    return math.max(crane, machoire) + h * h * k / 4;
  }

  /// Là où un rayon parti du centre sort d'un ellipsoïde (centre c,
  /// demi-axes r) ; 0 s'il le manque.
  static double _rayonEllipsoide(
    double df,
    double dl,
    double du,
    double cf,
    double cl,
    double cu,
    double rf,
    double rl,
    double ru,
  ) {
    final a =
        (df / rf) * (df / rf) + (dl / rl) * (dl / rl) + (du / ru) * (du / ru);
    final b =
        -2 * (df * cf / (rf * rf) + dl * cl / (rl * rl) + du * cu / (ru * ru));
    final c =
        (cf / rf) * (cf / rf) +
        (cl / rl) * (cl / rl) +
        (cu / ru) * (cu / ru) -
        1;
    final disc = b * b - 4 * a * c;
    if (disc < 0) return 0;
    return math.max(0, (-b + math.sqrt(disc)) / (2 * a));
  }

  void _tete(Squelette3 s) {
    final h = s.tete, u = s.hautTete, f = s.avantTete;
    final l = u.cross(f).unite;
    final rangs = fin ? 14 : 9, cols = fin ? 22 : 14;
    // Le dessous de la tête épouse le cou (la nuque, sous la mâchoire), un
    // rien AU-DEHORS : le cou rentre dans la tête sans la percer.
    final cou = [
      _Capsule(s.cou + (h - s.cou) * 0.15, s.cou + (h - s.cou) * 0.8, 0.0285),
    ];
    V3 point(double lat, double lon, double plus) {
      final cl = math.cos(lat), sl = math.sin(lat);
      final df = cl * math.cos(lon), dl = cl * math.sin(lon), du = sl;
      final r = _rayonTete(df, dl, du) + plus;
      return _souder(h + (f * df + l * dl + u * du) * r, cou);
    }

    // La tête (anneaux : les latitudes, en degrés) ; pas de contour là où
    // elle épouse le cou.
    final lats = [
      for (var i = 0; i < rangs; i++) -90 + 180.0 * i / (rangs - 1),
    ];
    final g = _Grille(rangs, cols)..ss = lats;
    for (var i = 0; i < rangs; i++) {
      for (var j = 0; j < cols; j++) {
        final q = point(rad(lats[i]), 2 * math.pi * j / cols, 0);
        g.poser(i * cols + j, q);
        g.trait[i * cols + j] = _lisse(1.05, 1.6, _presDe(q, cou));
      }
    }
    _emettre(g, const [_peau]);

    // Les cheveux : une calotte, de la ligne du front (plus basse sur les
    // côtés, jusqu'à la nuque derrière) au sommet — peinte juste après la
    // peau du crâne qu'elle recouvre (le crâne la transperçait par
    // endroits).
    final rc = fin ? 12 : 6;
    final c = _Grille(rc, cols);
    final cases = Int32List(rc * cols);
    for (var j = 0; j < cols; j++) {
      final lon = 360.0 * j / cols;
      final bord =
          1.25 + 32.5 * math.cos(rad(lon)) - 6.75 * math.cos(rad(2 * lon));
      for (var i = 0; i < rc; i++) {
        final v = i / (rc - 1);
        final lat = bord + (90 - bord) * v;
        c.poser(i * cols + j, point(rad(lat), rad(lon), 0.0025 + 0.002 * v));
        cases[i * cols + j] = g.caseEn(math.min(lat, 89.9), lon + 0.5);
      }
    }
    _emettre(c, const [_cheveux], zImpose: _ancrer(g, c, cases));

    // Le nez, les oreilles.
    // (Le nez sans contour : de face, un cerne en faisait un clown.)
    _ellipsoide(
      h + f * 0.045 - u * 0.007,
      u * 0.012,
      f * 0.008,
      l * 0.006,
      _peau,
      trait: 0,
      petit: true,
    );
    for (final sens in [1.0, -1.0]) {
      _ellipsoide(
        h + l * (0.039 * sens) - u * 0.008 - f * 0.006,
        u * 0.012,
        f * 0.008,
        l * 0.004,
        _peau,
        trait: 0.45,
        petit: true,
      );
    }

    // Les yeux et les sourcils, posés sur la surface.
    for (final sens in [1.0, -1.0]) {
      final d = (f * 0.9 + l * (0.36 * sens) + u * 0.08).unite;
      final r = _rayonTete(d.dot(f), d.dot(l), d.dot(u));
      final p = h + d * r;
      if (d.dot(_vers) < 0.22) continue;
      final e1 = l.sansComposante(d).unite, e2 = u.sansComposante(d).unite;
      _ellipseSur(p, e1 * 0.0042, e2 * 0.0052, _yeux, 0.003);
      final sourcil = p + e2 * 0.0115;
      _traitSur(
        sourcil - e1 * (0.0065 * sens) - e2 * 0.001,
        sourcil + e1 * (0.0065 * sens) + e2 * 0.0006,
        0.0026,
        0xE62A2522,
        0.003,
      );
    }
  }

  // ── Les mains, les pieds ─────────────────────────────────────────────────

  /// Une main à taille humaine : la paume et les doigts repliés, le pouce
  /// (du côté du dehors quand la paume regarde devant).
  void _main(Squelette3 s, Membre3 b, double cote) {
    final dAvant = (b.bout - b.milieu).unite;
    final axe = (b.extremite - b.bout).unite;
    var paume = _avantBras(s, dAvant).sansComposante(axe);
    paume = paume.norme < 1e-3 ? s.avantEpaules.sansComposante(axe) : paume;
    paume = paume.unite;
    final largeur = axe.cross(paume).unite * -cote;
    _ellipsoide(
      b.bout + axe * 0.032,
      axe * 0.034,
      largeur * 0.021,
      paume * 0.014,
      _peau,
      fonduVers: -1,
    );
    _ellipsoide(
      b.bout + largeur * 0.017 + paume * 0.01 + axe * 0.022,
      (axe + largeur * 0.4).unite * 0.016,
      largeur * 0.009,
      paume * 0.009,
      _peau,
      trait: 0,
      petit: true,
    );
  }

  /// La chaussure : une forme balayée du talon aux orteils, la semelle
  /// dessous, la tige qui monte autour de la cheville.
  void _chaussure3(Membre3 j, V3 talon) {
    final f = (j.extremite - talon).unite;
    final haut = (j.bout - talon).sansComposante(f).unite;
    final lat = f.cross(haut).unite;
    final debut = talon - f * 0.026, bout = j.extremite + f * 0.01;
    // (u, demi-largeur, hauteur, échelle de la section)
    const profil = [
      (0.0, 0.016, 0.02, 0.0),
      (0.04, 0.018, 0.026, 0.75),
      (0.1, 0.021, 0.036, 0.95),
      (0.22, 0.023, 0.045, 1.0),
      (0.34, 0.024, 0.044, 1.0),
      (0.46, 0.026, 0.034, 1.0),
      (0.6, 0.027, 0.027, 1.0),
      (0.75, 0.028, 0.021, 1.0),
      (0.88, 0.025, 0.016, 0.95),
      (0.96, 0.02, 0.012, 0.75),
      (1.0, 0.012, 0.008, 0.0),
    ];
    // La section : l'empeigne (un arc), puis la semelle (à plat).
    const arc = 10;
    const semelle = [
      (-1.0, -0.004),
      (-0.82, -0.0085),
      (-0.3, -0.009),
      (0.3, -0.009),
      (0.82, -0.0085),
      (1.0, -0.004),
    ];
    const cols = arc + 1 + 6;
    final g = _Grille(profil.length, cols);
    for (var i = 0; i < profil.length; i++) {
      final (u, w, hh, e) = profil[i];
      final base = V3.lerp(debut, bout, u);
      for (var k = 0; k < cols; k++) {
        final (x, y) = k <= arc
            ? (
                math.cos(math.pi * k / arc),
                hh * math.pow(math.sin(math.pi * k / arc), 0.8).toDouble(),
              )
            : semelle[k - arc - 1];
        g.poser(i * cols + k, base + (lat * (x * w) + haut * y) * e);
      }
    }
    for (var i = 0; i < profil.length - 1; i++) {
      for (var k = arc; k < cols; k++) {
        g.matiere[i * cols + k] = 1;
      }
    }
    _emettre(g, const [_chaussure, _semelle]);
  }

  /// Un ellipsoïde maillé, ses pôles au bout de [a] ; [fonduVers] : son
  /// contour s'efface vers ce pôle (−1 : le pôle −a, une jointure).
  void _ellipsoide(
    V3 centre,
    V3 a,
    V3 b,
    V3 c,
    _Matiere m, {
    double trait = 1,
    double fonduVers = 0,
    bool petit = false,
  }) {
    final rangs = petit ? 5 : (fin ? 7 : 5);
    final cols = petit ? 6 : (fin ? 10 : 7);
    final g = _Grille(rangs, cols);
    for (var i = 0; i < rangs; i++) {
      final lat = -math.pi / 2 + math.pi * i / (rangs - 1);
      final sl = math.sin(lat), cl = math.cos(lat);
      final tr = fonduVers == 0
          ? trait
          : trait * _lisse(-0.95, -0.35, sl * -fonduVers);
      for (var j = 0; j < cols; j++) {
        final lon = 2 * math.pi * j / cols;
        g.poser(
          i * cols + j,
          centre + a * sl + (b * math.cos(lon) + c * math.sin(lon)) * cl,
        );
        g.trait[i * cols + j] = tr;
      }
    }
    _emettre(g, [m]);
  }

  // ── Ce qui est posé sur la peau ──────────────────────────────────────────

  (double, double, double) _ecran(V3 p) {
    final d = (p.x - camera.pivot) * _sl + p.z * _cl;
    return (
      (camera.pivot + (p.x - camera.pivot) * _cl - p.z * _sl) * cote,
      (kSol + (p.y - kSol) * _ct + d * _st) * cote,
      d * _ct - (p.y - kSol) * _st,
    );
  }

  /// Une ellipse posée sur la surface (un œil) : [e1], [e2] ses demi-axes.
  void _ellipseSur(V3 centre, V3 e1, V3 e2, int couleur, double biais) {
    final (cx, cy, cz) = _ecran(centre);
    const n = 10;
    final pts = [
      for (var i = 0; i < n; i++)
        _ecran(
          centre +
              e1 * math.cos(2 * math.pi * i / n) +
              e2 * math.sin(2 * math.pi * i / n),
        ),
    ];
    for (var i = 0; i < n; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      _t.triangle(
        cx,
        cy,
        couleur,
        a.$1,
        a.$2,
        couleur,
        b.$1,
        b.$2,
        couleur,
        cz + biais,
      );
    }
  }

  /// Un trait posé sur la surface (un sourcil), épais de [e].
  void _traitSur(V3 a, V3 b, double e, int couleur, double biais) {
    final (ax, ay, az) = _ecran(a);
    final (bx, by, bz) = _ecran(b);
    var nx = -(by - ay), ny = bx - ax;
    final l = math.sqrt(nx * nx + ny * ny);
    if (l < 1e-6) return;
    nx *= e * cote / 2 / l;
    ny *= e * cote / 2 / l;
    final z = (az + bz) / 2 + biais;
    _t.triangle(
      ax + nx,
      ay + ny,
      couleur,
      bx + nx,
      by + ny,
      couleur,
      bx - nx,
      by - ny,
      couleur,
      z,
    );
    _t.triangle(
      ax + nx,
      ay + ny,
      couleur,
      bx - nx,
      by - ny,
      couleur,
      ax - nx,
      ay - ny,
      couleur,
      z,
    );
  }

  // ═══ Le rendu d'une grille ═════════════════════════════════════════════

  /// Projette, éclaire, et verse dans le tampon les cases tournées vers
  /// nous (rapprochées de [biais]), puis les contours de la silhouette.
  void _emettre(
    _Grille g,
    List<_Matiere> matieres, {
    double biais = 0,
    Float64List? zImpose,
  }) {
    final n = g.rangs * g.cols;
    final cols = g.cols, qc = g.casesParRang, bandes = g.rangs - 1;
    final sx = Float64List(n), sy = Float64List(n), pr = Float64List(n);
    final piv = camera.pivot;
    for (var k = 0; k < n; k++) {
      final x = g.x[k], y = g.y[k], z = g.z[k];
      final d = (x - piv) * _sl + z * _cl;
      sx[k] = (piv + (x - piv) * _cl - z * _sl) * cote;
      sy[k] = (kSol + (y - kSol) * _ct + d * _st) * cote;
      pr[k] = d * _ct - (y - kSol) * _st + biais;
    }

    // Les normales : celles des cases, cumulées aux sommets.
    final nx = Float64List(n), ny = Float64List(n), nz = Float64List(n);
    final fx = Float64List(bandes * qc);
    final fy = Float64List(bandes * qc);
    final fz = Float64List(bandes * qc);
    for (var i = 0; i < bandes; i++) {
      for (var j = 0; j < qc; j++) {
        final a = i * cols + j, b = a + cols;
        final j1 = (j + 1) % cols;
        final c = (i + 1) * cols + j1, d = i * cols + j1;
        final e1x = g.x[c] - g.x[a], e1y = g.y[c] - g.y[a];
        final e1z = g.z[c] - g.z[a];
        final e2x = g.x[d] - g.x[b], e2y = g.y[d] - g.y[b];
        final e2z = g.z[d] - g.z[b];
        final qx = e1y * e2z - e1z * e2y;
        final qy = e1z * e2x - e1x * e2z;
        final qz = e1x * e2y - e1y * e2x;
        final q = i * qc + j;
        fx[q] = qx;
        fy[q] = qy;
        fz[q] = qz;
        nx[a] += qx;
        ny[a] += qy;
        nz[a] += qz;
        nx[b] += qx;
        ny[b] += qy;
        nz[b] += qz;
        nx[c] += qx;
        ny[c] += qy;
        nz[c] += qz;
        nx[d] += qx;
        ny[d] += qy;
        nz[d] += qz;
      }
    }
    // Le sens (vers l'extérieur) : mesuré sur l'anneau du milieu.
    final im = bandes ~/ 2;
    var cx = 0.0, cy = 0.0, cz = 0.0;
    for (var j = 0; j < cols; j++) {
      cx += g.x[im * cols + j];
      cy += g.y[im * cols + j];
      cz += g.z[im * cols + j];
    }
    cx /= cols;
    cy /= cols;
    cz /= cols;
    var somme = 0.0;
    for (var j = 0; j < qc; j++) {
      final a = im * cols + j, q = im * qc + j;
      somme +=
          fx[q] * (g.x[a] - cx) + fy[q] * (g.y[a] - cy) + fz[q] * (g.z[a] - cz);
    }
    final sens = somme >= 0 ? 1.0 : -1.0;

    // La lumière, sommet par sommet.
    final dif = Float64List(n), face = Float64List(n), mi = Float64List(n);
    final l = _lumiere, v = _vers, h = _mi;
    for (var k = 0; k < n; k++) {
      var ax = nx[k], ay = ny[k], az = nz[k];
      final m = math.sqrt(ax * ax + ay * ay + az * az);
      if (m < 1e-12) {
        ax = v.x;
        ay = v.y;
        az = v.z;
      } else {
        ax *= sens / m;
        ay *= sens / m;
        az *= sens / m;
      }
      // Une lumière qui ENVELOPPE (l'ombre commence au-delà du profil).
      var d = (ax * l.x + ay * l.y + az * l.z + 0.38) / 1.38;
      d = d < 0 ? 0.0 : (d > 1 ? 1.0 : d);
      dif[k] = d * d * (3 - 2 * d);
      final fa = ax * v.x + ay * v.y + az * v.z;
      face[k] =
          (0.8 + 0.2 * math.sqrt(fa < 0 ? 0.0 : (fa > 1 ? 1.0 : fa))) * g.ao[k];
      mi[k] = math.max(0, ax * h.x + ay * h.y + az * h.z);
    }

    // Les couleurs, pour chaque matière de la grille.
    // Les anneaux que chaque matière occupe (le short n'est que sur le haut
    // de la cuisse : inutile de le calculer jusqu'à la cheville).
    final nm = matieres.length;
    final premier = List<int>.filled(nm, 1 << 30),
        dernier = List<int>.filled(nm, -1);
    for (var i = 0; i < bandes; i++) {
      for (var j = 0; j < qc; j++) {
        final m = g.matiere[i * qc + j];
        if (i < premier[m]) premier[m] = i;
        if (i + 1 > dernier[m]) dernier[m] = i + 1;
      }
    }
    final couleurs = [
      for (var i = 0; i < nm; i++)
        dernier[i] < 0
            ? null
            : _couleurs(
                matieres[i],
                g,
                dif,
                face,
                mi,
                premier[i] * cols,
                (dernier[i] + 1) * cols,
              ),
    ];

    // La proximité des cases.
    final zc = zImpose ?? Float64List(bandes * qc);
    if (zImpose == null) {
      for (var i = 0; i < bandes; i++) {
        for (var j = 0; j < qc; j++) {
          final a = i * cols + j, b = a + cols;
          final j1 = (j + 1) % cols;
          final c = (i + 1) * cols + j1, d = i * cols + j1;
          zc[i * qc + j] = (pr[a] + pr[b] + pr[c] + pr[d]) / 4;
        }
      }
    }
    g.zCases = zc;

    // Les cases tournées vers nous.
    final visible = Uint8List(bandes * qc);
    for (var q = 0; q < bandes * qc; q++) {
      if ((fx[q] * v.x + fy[q] * v.y + fz[q] * v.z) * sens > 0) visible[q] = 1;
    }
    for (var i = 0; i < bandes; i++) {
      for (var j = 0; j < qc; j++) {
        final q = i * qc + j;
        if (visible[q] == 0) continue;
        final a = i * cols + j, b = a + cols;
        final j1 = (j + 1) % cols;
        final c = (i + 1) * cols + j1, d = i * cols + j1;
        final col = couleurs[g.matiere[q]]!;
        final z = zc[q];
        _t.triangle(
          sx[a],
          sy[a],
          col[a],
          sx[b],
          sy[b],
          col[b],
          sx[c],
          sy[c],
          col[c],
          z,
        );
        _t.triangle(
          sx[a],
          sy[a],
          col[a],
          sx[c],
          sy[c],
          col[c],
          sx[d],
          sy[d],
          col[d],
          z,
        );
      }
    }

    // Les contours : là où une case visible touche une case cachée.
    void bord(int u, int w, double ox, double oy) {
      final lu = g.trait[u] * _largeurTrait, lw = g.trait[w] * _largeurTrait;
      if (lu < 0.04 && lw < 0.04) return;
      final ax = sx[u], ay = sy[u], bx = sx[w], by = sy[w];
      var ex = bx - ax, ey = by - ay;
      final len = math.sqrt(ex * ex + ey * ey);
      if (len < 1e-6) return;
      ex /= len;
      ey /= len;
      var px = -ey, py = ex;
      if (((ax + bx) / 2 - ox) * px + ((ay + by) / 2 - oy) * py < 0) {
        px = -px;
        py = -py;
      }
      final a0x = ax - ex * lu * 0.5, a0y = ay - ey * lu * 0.5;
      final b0x = bx + ex * lw * 0.5, b0y = by + ey * lw * 0.5;
      final z = (pr[u] + pr[w]) / 2;
      _t.triangle(
        a0x,
        a0y,
        _trait,
        b0x,
        b0y,
        _trait,
        b0x + px * lw,
        b0y + py * lw,
        _trait,
        z,
      );
      _t.triangle(
        a0x,
        a0y,
        _trait,
        b0x + px * lw,
        b0y + py * lw,
        _trait,
        a0x + px * lu,
        a0y + py * lu,
        _trait,
        z,
      );
    }

    for (var i = 0; i < bandes; i++) {
      for (var j = 0; j < qc; j++) {
        final q = i * qc + j;
        if (visible[q] == 0) continue;
        final a = i * cols + j, b = a + cols;
        final j1 = (j + 1) % cols;
        final c = (i + 1) * cols + j1, d = i * cols + j1;
        final ox = (sx[a] + sx[b] + sx[c] + sx[d]) / 4;
        final oy = (sy[a] + sy[b] + sy[c] + sy[d]) / 4;
        final gauche = j > 0 ? q - 1 : (g.boucle ? q + qc - 1 : -1);
        final droite = j < qc - 1 ? q + 1 : (g.boucle ? q - qc + 1 : -1);
        if (gauche >= 0 && visible[gauche] == 0) bord(a, b, ox, oy);
        if (droite >= 0 && visible[droite] == 0) bord(d, c, ox, oy);
        if (i > 0 && visible[q - qc] == 0) bord(a, d, ox, oy);
        if (i < bandes - 1 && visible[q + qc] == 0) bord(b, c, ox, oy);
      }
    }
  }

  static int _octet(double v) => v <= 0 ? 0 : (v >= 255 ? 255 : v.round());

  /// Les couleurs d'une matière, sommet par sommet : l'ombre chaude vers la
  /// pleine lumière, les bords un peu plus sombres, les plis, un reflet doux.
  Int32List _couleurs(
    _Matiere m,
    _Grille g,
    Float64List dif,
    Float64List bords,
    Float64List mi,
    int k0,
    int k1,
  ) {
    final col = Int32List(g.rangs * g.cols);
    final r = ((m.couleur >> 16) & 0xFF).toDouble();
    final gg = ((m.couleur >> 8) & 0xFF).toDouble();
    final b = (m.couleur & 0xFF).toDouble();
    final (or, og, ob) = m.ombre;
    final fin = math.min(k1, col.length);
    for (var k = k0; k < fin; k++) {
      final d = dif[k];
      final bord = bords[k];
      final reflet =
          m.brillance * 255 * _puissance(mi[k], m.exposant) * g.ao[k];
      // La peau : un rien de rouge là où l'ombre commence.
      var sang = 0.0;
      if (m.peau && d > 0.1 && d < 0.62) {
        final q = (d - 0.1) / 0.52, c = 4 * q * (1 - q);
        sang = 18 * c * c;
      }
      final rr = _octet(r * (or + (1.05 - or) * d) * bord + reflet + sang);
      final rg = _octet(
        gg * (og + (1.05 - og) * d) * bord + reflet + sang * 0.3,
      );
      final rb = _octet(b * (ob + (1.05 - ob) * d) * bord + reflet);
      col[k] = 0xFF000000 | (rr << 16) | (rg << 8) | rb;
    }
    return col;
  }
}

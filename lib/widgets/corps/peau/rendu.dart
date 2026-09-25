// lib/widgets/corps/peau/rendu.dart
//
// Le RENDU d'une grille : projection, normales, lumière, couleurs, triangles
// et contours.
//
// La lumière est celle d'un studio, liée à la CAMÉRA (le corps est aussi bien
// éclairé de face, de profil que de dos) :
// - une lumière PRINCIPALE en haut à gauche, un peu devant, qui ENVELOPPE
//   (l'ombre commence au-delà du profil, comme sur une peau) ;
// - un DÉBOUCHAGE froid et doux de la droite ;
// - un CONTRE-JOUR qui dessine un lisere clair sur les bords — sur le noir de
//   l'écran, c'est lui qui détache la silhouette ;
// - une lumière du CIEL, plus claire sur ce qui regarde en haut ;
// - l'OCCLUSION : les creux des plis, et celle des autres parties du corps
//   (des capsules : l'aisselle, l'intérieur des cuisses, le cou sous le
//   menton, le bras contre le flanc) ;
// - la PEAU : une ombre chaude (la lumière qui passe sous la peau), un rien de
//   rouge à la limite de l'ombre, un reflet doux et plus vif en rasant.

part of '../peau3.dart';

/// Une matière : sa couleur, la teinte de son ombre (par canal), son
/// reflet.
class _Matiere {
  const _Matiere(
    this.couleur, {
    this.ombre = (0.42, 0.42, 0.48),
    this.brillance = 0.04,
    this.exposant = 14,
    this.peau = false,
    this.lisere = 1,
  });

  final int couleur;
  final (double, double, double) ombre;
  final double brillance;
  final int exposant;

  /// Une peau : un rien de rouge dans la transition ombre / lumière.
  final bool peau;

  /// La force du contre-jour sur cette matière.
  final double lisere;
}

/// La peau : un teint clair et chaud, des ombres chaudes.
const int _teintPeau = 0xFFE5BFA5;
const _Matiere _peau = _Matiere(
  _teintPeau,
  ombre: (0.5, 0.33, 0.3),
  brillance: 0.07,
  exposant: 22,
  peau: true,
);
const _Matiere _short = _Matiere(
  0xFF354057,
  ombre: (0.36, 0.38, 0.46),
  brillance: 0.035,
  exposant: 7,
  lisere: 0.7,
);
const _Matiere _ceinture = _Matiere(0xFF434F68, brillance: 0.03, exposant: 8);
const _Matiere _chaussure = _Matiere(
  0xFFE4E4EA,
  ombre: (0.46, 0.46, 0.52),
  brillance: 0.1,
  exposant: 16,
);
const _Matiere _semelle = _Matiere(0xFF5E5F67, brillance: 0.05);
const _Matiere _chaussette = _Matiere(
  0xFFEDEDF1,
  ombre: (0.48, 0.48, 0.54),
  brillance: 0.02,
  exposant: 6,
);
const _Matiere _cheveux = _Matiere(
  0xFF33251D,
  ombre: (0.5, 0.45, 0.45),
  brillance: 0.09,
  exposant: 9,
  lisere: 0.8,
);
const _Matiere _levres = _Matiere(
  0xFFC98A7E,
  ombre: (0.5, 0.33, 0.32),
  brillance: 0.12,
  exposant: 26,
  peau: true,
);
const _Matiere _oeil = _Matiere(
  0xFFF1ECE8,
  ombre: (0.55, 0.52, 0.52),
  brillance: 0.25,
  exposant: 40,
  lisere: 0,
);

/// Un muscle travaillé : sa teinte, modelée comme la peau.
_Matiere _muscle(int couleur) => _Matiere(
  couleur,
  ombre: (0.52, 0.34, 0.33),
  brillance: 0.07,
  exposant: 22,
  peau: true,
);

const int _trait = 0xFF140D0B;

/// Une couleur par partie, pour voir qui peint quoi (`Peau3.debogage`).
const List<int> _debogage = [
  0xFF4C8F4C,
  0xFF9A5AB0,
  0xFF4A70C0,
  0xFF2F4A80,
  0xFFC08040,
  0xFF805020,
];

/// Les lumières du studio, liées à la caméra.
class _Lumieres {
  _Lumieres(Camera3 c) {
    final droite = c.ex, vers = c.vers;
    // « En haut » à l'écran : le haut du monde, sans la composante vers nous.
    var haut = V3.haut.sansComposante(vers);
    haut = haut.norme < 1e-3 ? V3.haut : haut.unite;
    cle = (droite * -0.5 + haut * 0.72 + vers * 0.55).unite;
    debouchage = (droite * 0.75 + haut * -0.05 + vers * 0.55).unite;
    contre = (droite * 0.55 + haut * 0.45 + vers * -0.7).unite;
    ciel = V3.haut;
    this.vers = vers;
    mi = (cle + vers).unite;
  }

  late final V3 cle, debouchage, contre, ciel, vers, mi;
}

/// La lumière principale d'une caméra (le matériel est éclairé comme le
/// corps).
V3 lumiereCle(Camera3 c) => _Lumieres(c).cle;

/// Une CAPSULE qui fait de l'ombre aux autres parties (occlusion) : de [a]
/// à b, de rayon [r], appartenant à la partie [partie].
class _Occultant {
  _Occultant(this.a, V3 b, this.r, this.partie) : ab = b - a {
    l2 = ab.dot(ab);
  }

  final V3 a, ab;
  final double r;
  final int partie;
  late final double l2;
}

extension _Rendu on Peau3 {
  /// Projette, éclaire, et verse dans le tampon les cases tournées vers
  /// nous, puis les contours de la silhouette. [partie] : la partie du corps
  /// (ses propres capsules ne l'assombrissent pas).
  void _emettre(
    _Grille g,
    List<_Matiere> matieres, {
    double biais = 0,
    Float64List? zImpose,
    int partie = -1,
    double largeurTrait = 1,
  }) {
    final n = g.n;
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

    // Les normales (celles des cases, cumulées aux sommets), puis celles de
    // la soudure là où deux parties se rejoignent.
    g.calculerNormales();
    final nx = g.nx!, ny = g.ny!, nz = g.nz!;
    final fx = g.fx!, fy = g.fy!, fz = g.fz!;
    final sens = g.sens;
    final v = _l.vers;
    final ip = g.ip;
    if (ip != null) {
      for (var k = 0; k < n; k++) {
        final w = ip[k];
        if (w <= 0) continue;
        var ax = nx[k] + (g.ix![k] - nx[k]) * w;
        var ay = ny[k] + (g.iy![k] - ny[k]) * w;
        var az = nz[k] + (g.iz![k] - nz[k]) * w;
        final m2 = math.sqrt(ax * ax + ay * ay + az * az);
        if (m2 > 1e-12) {
          ax /= m2;
          ay /= m2;
          az /= m2;
        }
        nx[k] = ax;
        ny[k] = ay;
        nz[k] = az;
      }
    }

    // L'occlusion des autres parties (capsules).
    final ao = Float64List(n);
    for (var k = 0; k < n; k++) {
      ao[k] = g.ao[k] * (partie >= 0 ? _occlusion(g, k, partie) : 1);
    }

    // Les couleurs, pour chaque matière de la grille, sur les anneaux
    // qu'elle occupe.
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
        if (Peau3.debogage && partie >= 0 && dernier[i] >= 0)
          Int32List(n)..fillRange(0, n, _debogage[partie % _debogage.length])
        else if (dernier[i] < 0)
          null
        else
          _couleurs(
            matieres[i],
            g,
            ao,
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

    // Les cases tournées vers nous (1), cachées dans une autre partie (2).
    final visible = Uint8List(bandes * qc);
    final cachees = g.cachees;
    for (var q = 0; q < bandes * qc; q++) {
      if ((fx[q] * v.x + fy[q] * v.y + fz[q] * v.z) * sens > 0) visible[q] = 1;
      if (cachees != null && cachees[q] == 1) visible[q] = 2;
    }
    for (var i = 0; i < bandes; i++) {
      for (var j = 0; j < qc; j++) {
        final q = i * qc + j;
        if (visible[q] != 1) continue;
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

    // Les contours : là où une case tournée vers nous touche une case qui
    // se détourne (la silhouette de cette partie).
    final lt = _largeurTrait * largeurTrait;
    if (lt <= 0) return;
    void bord(int u, int w, double ox, double oy) {
      final lu = g.trait[u] * lt, lw = g.trait[w] * lt;
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
        if (visible[q] != 1) continue;
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

  /// L'occlusion au sommet [k] de [g] par les capsules des AUTRES parties
  /// (1 : à découvert).
  double _occlusion(_Grille g, int k, int partie) {
    final px = g.x[k], py = g.y[k], pz = g.z[k];
    final nx = g.nx![k], ny = g.ny![k], nz = g.nz![k];
    var occ = 0.0;
    for (final c in _occultants) {
      if (c.partie == partie) continue;
      final wx = px - c.a.x, wy = py - c.a.y, wz = pz - c.a.z;
      var u = c.l2 < 1e-12
          ? 0.0
          : (wx * c.ab.x + wy * c.ab.y + wz * c.ab.z) / c.l2;
      u = u < 0 ? 0.0 : (u > 1 ? 1.0 : u);
      final dx = c.a.x + c.ab.x * u - px;
      final dy = c.a.y + c.ab.y * u - py;
      final dz = c.a.z + c.ab.z * u - pz;
      final d2 = dx * dx + dy * dy + dz * dz;
      final lim = c.r * 3.2;
      if (d2 > lim * lim) continue;
      final d = math.sqrt(d2);
      if (d < 1e-6) continue;
      final cosn = (nx * dx + ny * dy + nz * dz) / d;
      if (cosn <= 0) continue;
      final r = c.r / math.max(d, c.r);
      // Nulle au bord de la zone : pas de lisière visible.
      occ += cosn * r * r * (1 - d / lim);
    }
    return 1 - (occ * 0.85).clamp(0.0, 0.62);
  }

  static int _octet(double v) => v <= 0 ? 0 : (v >= 255 ? 255 : v.round());

  /// Les couleurs d'une matière, sommet par sommet ([ao] : l'occlusion).
  Int32List _couleurs(_Matiere m, _Grille g, Float64List ao, int k0, int k1) {
    final col = Int32List(g.n);
    final r0 = ((m.couleur >> 16) & 0xFF).toDouble();
    final g0 = ((m.couleur >> 8) & 0xFF).toDouble();
    final b0 = (m.couleur & 0xFF).toDouble();
    final (or, og, ob) = m.ombre;
    final fin = math.min(k1, col.length);
    final l = _l;
    final cle = l.cle, deb = l.debouchage, con = l.contre, v = l.vers;
    final mi = l.mi;
    final teinte = g.teinte;
    final nx = g.nx!, ny = g.ny!, nz = g.nz!;
    for (var k = k0; k < fin; k++) {
      final ax = nx[k], ay = ny[k], az = nz[k];
      final o = ao[k];
      // La lumière principale, qui enveloppe.
      var d = (ax * cle.x + ay * cle.y + az * cle.z + 0.35) / 1.35;
      d = d < 0 ? 0.0 : (d > 1 ? 1.0 : d);
      d = d * d * (3 - 2 * d);
      // L'ombre portée des creux touche surtout la lumière d'ambiance ; un
      // peu la principale aussi.
      final dp = d * (0.55 + 0.45 * o);
      // Le débouchage et le ciel.
      var f = (ax * deb.x + ay * deb.y + az * deb.z + 0.2) / 1.2;
      f = f < 0 ? 0.0 : f;
      final ciel = 0.5 - 0.5 * ay;
      final amb = (0.16 * f + 0.14 * ciel) * o;
      // Le contre-jour : sur les bords qui se détournent de nous.
      final fa = ax * v.x + ay * v.y + az * v.z;
      final bordure = 1 - (fa < 0 ? 0.0 : (fa > 1 ? 1.0 : fa));
      var c = ax * con.x + ay * con.y + az * con.z + 0.35;
      c = c < 0 ? 0.0 : c;
      final lis = m.lisere * 0.55 * bordure * bordure * bordure * c * o;
      // Le bord qui s'assombrit (la forme tourne), le reflet.
      final tourne = 0.84 + 0.16 * (fa < 0 ? 0.0 : math.sqrt(fa));
      final vif = 1 + 2.5 * bordure * bordure * bordure * bordure;
      final reflet =
          m.brillance *
          255 *
          _puissance(
            math.max(0, ax * mi.x + ay * mi.y + az * mi.z),
            m.exposant,
          ) *
          o *
          vif;
      // La peau : un rien de rouge là où l'ombre commence.
      var sang = 0.0;
      if (m.peau && d > 0.08 && d < 0.6) {
        final q = (d - 0.08) / 0.52, cc = 4 * q * (1 - q);
        sang = 16 * cc * cc;
      }
      double r = r0, gg = g0, b = b0;
      if (teinte != null) {
        r = teinte[3 * k];
        gg = teinte[3 * k + 1];
        b = teinte[3 * k + 2];
      }
      final rr = _octet(
        (r * (or + (1 - or) * dp) + r * amb * 0.9) * tourne +
            reflet +
            sang +
            255 * lis,
      );
      final rg = _octet(
        (gg * (og + (1 - og) * dp) + gg * amb * 0.95) * tourne +
            reflet +
            sang * 0.25 +
            250 * lis,
      );
      final rb = _octet(
        (b * (ob + (1 - ob) * dp) + b * amb * 1.1) * tourne +
            reflet * 1.02 +
            240 * lis,
      );
      col[k] = 0xFF000000 | (rr << 16) | (rg << 8) | rb;
    }
    return col;
  }
}

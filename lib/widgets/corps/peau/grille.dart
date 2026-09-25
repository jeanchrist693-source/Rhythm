// lib/widgets/corps/peau/grille.dart
//
// La GRILLE d'une partie (des anneaux de sommets) et la SOUDURE des parties
// entre elles.
//
// Chaque partie du corps est une surface à part (le tronc, un bras, une
// jambe, la tête) : là où deux parties se rejoignent (l'épaule, la hanche,
// le cou, le poignet), leurs surfaces se croisaient — une couture visible,
// des dents de scie (l'ordre de peinture hésitait entre deux surfaces à la
// même profondeur) et deux lumières différentes (chaque surface avait ses
// normales) : « un jouet monté de toutes pièces ».
//
// La soudure pose les sommets de chacune, près de la jointure, sur l'UNION
// LISSE des deux volumes (un « smooth min » : un congé arrondi, comme la
// chair qui passe du tronc au bras) et leur impose la normale de cette union :
// les deux surfaces n'en font plus qu'une, de même lumière — l'ordre dans
// lequel elles se peignent ne se voit plus.
//
// Le volume d'une partie est lu sur SA GRILLE (`_Tube`) : pour un point,
// l'anneau le plus proche, puis le rayon de l'anneau dans sa direction —
// reliefs des muscles compris.

part of '../peau3.dart';

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

  /// L'occlusion (les plis, les creux).
  final Float64List ao;

  /// La matière de chaque case (indice dans la liste passée à `_emettre`).
  final Uint8List matiere;

  /// Le paramètre de chaque anneau (le s de la forme), pour retrouver la
  /// case d'un point.
  List<double>? ss;

  /// Le paramètre de chaque colonne (degrés, croissants dans [0, 360)) ;
  /// `null` : régulier (360 · j / cols).
  List<double>? phis;

  /// La proximité de chaque case, une fois émise.
  Float64List? zCases;

  /// Les normales de chaque sommet, une fois émises (pour poser dessus).
  Float64List? nx, ny, nz;

  /// Une normale IMPOSÉE (la soudure) : sa direction et son poids (0..1).
  Float64List? ix, iy, iz, ip;

  /// La couleur propre de chaque sommet (r, g, b de 0 à 255) ; sinon celle
  /// de sa matière. Les lèvres, les joues, les genoux rosés, le dégradé des
  /// cheveux…
  Float32List? teinte;

  /// Les cases à ne pas peindre (enfouies dans une autre partie).
  Uint8List? cachees;

  int get n => rangs * cols;
  int get casesParRang => boucle ? cols : cols - 1;

  void poser(int k, V3 p) {
    x[k] = p.x;
    y[k] = p.y;
    z[k] = p.z;
  }

  V3 sommet(int k) => V3(x[k], y[k], z[k]);

  /// Impose la normale ([ax], [ay], [az] unitaire) au sommet [k], avec le
  /// poids [p] (le plus fort l'emporte).
  void imposer(int k, double ax, double ay, double az, double p) {
    if (ip == null) {
      ix = Float64List(n);
      iy = Float64List(n);
      iz = Float64List(n);
      ip = Float64List(n);
    }
    if (p <= ip![k]) return;
    ix![k] = ax;
    iy![k] = ay;
    iz![k] = az;
    ip![k] = p;
  }

  /// Donne à tous les sommets la couleur [c] (0xAARRGGBB), pour la teinter
  /// ensuite par endroits.
  Float32List teindre(int c) {
    final t = teinte ?? Float32List(3 * n);
    final r = ((c >> 16) & 0xFF).toDouble();
    final g = ((c >> 8) & 0xFF).toDouble();
    final b = (c & 0xFF).toDouble();
    for (var k = 0; k < n; k++) {
      t[3 * k] = r;
      t[3 * k + 1] = g;
      t[3 * k + 2] = b;
    }
    return teinte = t;
  }

  /// Mêle au sommet [k] la couleur [c] à hauteur de [a] (0..1).
  void meler(int k, int c, double a) {
    final t = teinte;
    if (t == null || a <= 0) return;
    final q = a > 1 ? 1.0 : a;
    t[3 * k] += (((c >> 16) & 0xFF) - t[3 * k]) * q;
    t[3 * k + 1] += (((c >> 8) & 0xFF) - t[3 * k + 1]) * q;
    t[3 * k + 2] += ((c & 0xFF) - t[3 * k + 2]) * q;
  }

  /// Calcule les normales des sommets (vers le dehors), celles des cases
  /// ([fx], [fy], [fz], non normées) et le sens du maillage ([sens]).
  void calculerNormales() {
    final cols = this.cols, qc = casesParRang, bandes = rangs - 1;
    final mx = Float64List(n), my = Float64List(n), mz = Float64List(n);
    final ax = Float64List(bandes * qc);
    final ay = Float64List(bandes * qc);
    final az = Float64List(bandes * qc);
    for (var i = 0; i < bandes; i++) {
      for (var j = 0; j < qc; j++) {
        final a = i * cols + j, b = a + cols;
        final j1 = (j + 1) % cols;
        final c = (i + 1) * cols + j1, d = i * cols + j1;
        final e1x = x[c] - x[a], e1y = y[c] - y[a], e1z = z[c] - z[a];
        final e2x = x[d] - x[b], e2y = y[d] - y[b], e2z = z[d] - z[b];
        final qx = e1y * e2z - e1z * e2y;
        final qy = e1z * e2x - e1x * e2z;
        final qz = e1x * e2y - e1y * e2x;
        final q = i * qc + j;
        ax[q] = qx;
        ay[q] = qy;
        az[q] = qz;
        for (final k in [a, b, c, d]) {
          mx[k] += qx;
          my[k] += qy;
          mz[k] += qz;
        }
      }
    }
    // Le sens (vers l'extérieur) : mesuré depuis le point [dedans] s'il est
    // connu (une grille posée sur une autre), sinon sur l'anneau du milieu.
    var somme = 0.0;
    final dd = dedans;
    if (dd != null) {
      for (var i = 0; i < bandes; i++) {
        for (var j = 0; j < qc; j++) {
          final a = i * cols + j, q = i * qc + j;
          somme +=
              ax[q] * (x[a] - dd.x) +
              ay[q] * (y[a] - dd.y) +
              az[q] * (z[a] - dd.z);
        }
      }
    } else {
      final im = bandes ~/ 2;
      var cx = 0.0, cy = 0.0, cz = 0.0;
      for (var j = 0; j < cols; j++) {
        cx += x[im * cols + j];
        cy += y[im * cols + j];
        cz += z[im * cols + j];
      }
      cx /= cols;
      cy /= cols;
      cz /= cols;
      for (var j = 0; j < qc; j++) {
        final a = im * cols + j, q = im * qc + j;
        somme +=
            ax[q] * (x[a] - cx) + ay[q] * (y[a] - cy) + az[q] * (z[a] - cz);
      }
    }
    sens = somme >= 0 ? 1.0 : -1.0;
    for (var k = 0; k < n; k++) {
      final m = math.sqrt(mx[k] * mx[k] + my[k] * my[k] + mz[k] * mz[k]);
      if (m < 1e-12) continue;
      mx[k] *= sens / m;
      my[k] *= sens / m;
      mz[k] *= sens / m;
    }
    nx = mx;
    ny = my;
    nz = mz;
    fx = ax;
    fy = ay;
    fz = az;
  }

  /// Un point DEDANS (sous une grille posée : le centre de la tête, un
  /// point sous la peau) : il dit de quel côté est le dehors.
  V3? dedans;

  /// Les normales des cases (non normées) et le sens du maillage.
  Float64List? fx, fy, fz;
  double sens = 1;

  /// La colonne (fractionnaire) de l'angle [phi].
  double _colonne(double phi) {
    var p = phi % 360;
    if (p < 0) p += 360;
    final ph = phis;
    if (ph == null) return p / 360 * cols;
    // Colonnes irrégulières : l'intervalle qui contient p (dichotomie).
    if (p < ph[0]) p += 360;
    var lo = 0, hi = cols - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (ph[mid] <= p) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final j = lo;
    final a = ph[j];
    final b = j < cols - 1 ? ph[j + 1] : ph[0] + 360;
    return j + (p - a) / (b - a);
  }

  /// L'anneau (fractionnaire) du paramètre [s].
  double _rang(double s) {
    final a = ss!;
    if (s <= a.first) return 0;
    if (s >= a.last) return rangs - 1.0;
    var lo = 0, hi = a.length - 2;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (a[mid] <= s) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + (s - a[lo]) / (a[lo + 1] - a[lo]);
  }

  /// La case qui contient le point (s, [phi]) de la forme.
  int caseEn(double s, double phi) {
    final i = math.min(_rang(s).floor(), rangs - 2);
    final j = _colonne(phi).floor() % cols;
    return i * casesParRang + math.min(j, casesParRang - 1);
  }

  /// Le point de la surface MAILLÉE en (s, [phi]) et sa normale (une fois
  /// émise) : ce qui se pose sur la peau suit exactement ce qui est peint.
  (V3, V3) surface(double s, double phi) {
    final fi = _rang(s);
    final i = math.min(fi.floor(), rangs - 2);
    final u = fi - i;
    final fj = _colonne(phi);
    var j0 = fj.floor();
    final v = fj - j0;
    j0 %= cols;
    var j1 = j0 + 1;
    if (j1 >= cols) j1 = boucle ? 0 : cols - 1;
    final a = i * cols + j0, b = i * cols + j1;
    final c = a + cols, d = b + cols;
    final wa = (1 - u) * (1 - v), wb = (1 - u) * v;
    final wc = u * (1 - v), wd = u * v;
    final p = V3(
      x[a] * wa + x[b] * wb + x[c] * wc + x[d] * wd,
      y[a] * wa + y[b] * wb + y[c] * wc + y[d] * wd,
      z[a] * wa + z[b] * wb + z[c] * wc + z[d] * wd,
    );
    final mx = nx, my = ny, mz = nz;
    if (mx == null || my == null || mz == null) return (p, V3.zero);
    final nn = V3(
      mx[a] * wa + mx[b] * wb + mx[c] * wc + mx[d] * wd,
      my[a] * wa + my[b] * wb + my[c] * wc + my[d] * wd,
      mz[a] * wa + mz[b] * wb + mz[c] * wc + mz[d] * wd,
    );
    return (p, nn.unite);
  }
}

// ═══ Le volume d'une partie, lu sur sa grille ═══════════════════════════════

/// Le VOLUME d'une partie en tube (tronc, bras, jambe), lu sur sa grille,
/// entre les anneaux [i0] et [i1] : une distance signée approchée (négative
/// dedans) et la direction qui sort.
class _Tube {
  _Tube(this.g, this.i0, this.i1) {
    final m = i1 - i0 + 1, c = g.cols;
    cx = Float64List(m);
    cy = Float64List(m);
    cz = Float64List(m);
    _ax = Float64List(m * 3);
    _ox = Float64List(m * 3);
    _ang = Float64List(m * c);
    _ray = Float64List(m * c);
    for (var r = 0; r < m; r++) {
      final i = i0 + r;
      var sx = 0.0, sy = 0.0, sz = 0.0;
      for (var j = 0; j < c; j++) {
        sx += g.x[i * c + j];
        sy += g.y[i * c + j];
        sz += g.z[i * c + j];
      }
      cx[r] = sx / c;
      cy[r] = sy / c;
      cz[r] = sz / c;
    }
    for (var r = 0; r < m - 1; r++) {
      final dx = cx[r + 1] - cx[r], dy = cy[r + 1] - cy[r];
      final dz = cz[r + 1] - cz[r];
      _pasMax = math.max(_pasMax, math.sqrt(dx * dx + dy * dy + dz * dz));
    }
    for (var k = i0 * c; k < (i1 + 1) * c; k++) {
      final x = g.x[k], y = g.y[k], z = g.z[k];
      if (x < _x0) _x0 = x;
      if (x > _x1) _x1 = x;
      if (y < _y0) _y0 = y;
      if (y > _y1) _y1 = y;
      if (z < _z0) _z0 = z;
      if (z > _z1) _z1 = z;
    }
    for (var r = 0; r < m; r++) {
      final i = i0 + r;
      // La tangente de l'axe, puis le repère de l'anneau : vers la colonne
      // 0, et vers la colonne d'un quart de tour.
      final ra = math.max(0, r - 1), rb = math.min(m - 1, r + 1);
      var t = V3(cx[rb] - cx[ra], cy[rb] - cy[ra], cz[rb] - cz[ra]);
      t = t.norme < 1e-9 ? V3.bas : t.unite;
      final c0 = V3(cx[r], cy[r], cz[r]);
      var a = (g.sommet(i * c) - c0).sansComposante(t);
      a = a.norme < 1e-9 ? t.cross(V3.proche).unite : a.unite;
      var o = (g.sommet(i * c + c ~/ 4) - c0)
          .sansComposante(t)
          .sansComposante(a);
      o = o.norme < 1e-9 ? t.cross(a).unite : o.unite;
      _ax[3 * r] = a.x;
      _ax[3 * r + 1] = a.y;
      _ax[3 * r + 2] = a.z;
      _ox[3 * r] = o.x;
      _ox[3 * r + 1] = o.y;
      _ox[3 * r + 2] = o.z;
      var prec = -1.0;
      for (var j = 0; j < c; j++) {
        final k = i * c + j;
        final qx = g.x[k] - cx[r], qy = g.y[k] - cy[r], qz = g.z[k] - cz[r];
        final pa = qx * a.x + qy * a.y + qz * a.z;
        final po = qx * o.x + qy * o.y + qz * o.z;
        var an = math.atan2(po, pa);
        if (an < 0) an += 2 * math.pi;
        // Les angles croissent le long de l'anneau.
        if (j > 0 && an < prec) an += 2 * math.pi;
        _ang[r * c + j] = an;
        _ray[r * c + j] = math.sqrt(pa * pa + po * po);
        prec = an;
      }
    }
  }

  final _Grille g;
  final int i0, i1;
  late final Float64List cx, cy, cz, _ax, _ox, _ang, _ray;

  /// Le plus long segment d'axe ; le dernier segment trouvé.
  double _pasMax = 0;
  int _dernier = 0;

  /// La boîte qui contient la partie (loin d'elle, pas de calcul).
  double _x0 = 1e9, _x1 = -1e9, _y0 = 1e9, _y1 = -1e9, _z0 = 1e9, _z1 = -1e9;
  static const double _marge = 0.025;

  /// Le rayon de l'anneau [r] (relatif) dans la direction d'angle [a], la
  /// colonne où il tombe et sa fraction.
  (double, int, double) _rayon(int r, double a) {
    final c = g.cols, base = r * c;
    final a0 = _ang[base];
    var t = a;
    while (t < a0) {
      t += 2 * math.pi;
    }
    while (t >= a0 + 2 * math.pi) {
      t -= 2 * math.pi;
    }
    var j = ((t - a0) / (2 * math.pi) * c).floor().clamp(0, c - 1);
    while (j > 0 && _ang[base + j] > t) {
      j--;
    }
    while (j < c - 1 && _ang[base + j + 1] <= t) {
      j++;
    }
    final b0 = _ang[base + j];
    final b1 = j < c - 1 ? _ang[base + j + 1] : a0 + 2 * math.pi;
    final r1 = j < c - 1 ? _ray[base + j + 1] : _ray[base];
    final u = b1 - b0 < 1e-9 ? 0.0 : (t - b0) / (b1 - b0);
    return (_ray[base + j] + (r1 - _ray[base + j]) * u, j, u);
  }

  /// La distance signée du point ([px], [py], [pz]) à la surface (négative
  /// dedans) et la direction qui sort (unitaire) : la normale de la surface
  /// maillée la plus proche, si elle est connue.
  (double, V3) distance(double px, double py, double pz) {
    if (px < _x0 - _marge ||
        px > _x1 + _marge ||
        py < _y0 - _marge ||
        py > _y1 + _marge ||
        pz < _z0 - _marge ||
        pz > _z1 + _marge) {
      return (_marge, V3.haut);
    }
    final m = cx.length;
    // Le segment d'axe le plus proche : cherché autour du précédent (les
    // sommets arrivent dans l'ordre des anneaux), vers les deux bouts,
    // jusqu'à ce que les anneaux soient trop loin pour faire mieux.
    var best = double.infinity, br = 0;
    var bu = 0.0;
    void essai(int r) {
      final ex = cx[r + 1] - cx[r], ey = cy[r + 1] - cy[r];
      final ez = cz[r + 1] - cz[r];
      final l2 = ex * ex + ey * ey + ez * ez;
      final wx = px - cx[r], wy = py - cy[r], wz = pz - cz[r];
      var u = l2 < 1e-14 ? 0.0 : (wx * ex + wy * ey + wz * ez) / l2;
      u = u < 0 ? 0.0 : (u > 1 ? 1.0 : u);
      final dx = wx - ex * u, dy = wy - ey * u, dz = wz - ez * u;
      final d2 = dx * dx + dy * dy + dz * dz;
      if (d2 < best) {
        best = d2;
        br = r;
        bu = u;
      }
    }

    double loin(int r) {
      final dx = px - cx[r], dy = py - cy[r], dz = pz - cz[r];
      return math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    final depart = _dernier.clamp(0, m - 2);
    essai(depart);
    for (var r = depart + 1; r < m - 1; r++) {
      if (loin(r) - _pasMax > math.sqrt(best)) break;
      essai(r);
    }
    for (var r = depart - 1; r >= 0; r--) {
      if (loin(r + 1) - _pasMax > math.sqrt(best)) break;
      essai(r);
    }
    _dernier = br;
    final r = br, u = bu;
    final ccx = cx[r] + (cx[r + 1] - cx[r]) * u;
    final ccy = cy[r] + (cy[r + 1] - cy[r]) * u;
    final ccz = cz[r] + (cz[r + 1] - cz[r]) * u;
    final qx = px - ccx, qy = py - ccy, qz = pz - ccz;
    final rho = math.sqrt(qx * qx + qy * qy + qz * qz);
    if (rho < 1e-9) return (-0.01, V3.haut);
    (double, int, double) rayon(int rr) {
      final pa = qx * _ax[3 * rr] + qy * _ax[3 * rr + 1] + qz * _ax[3 * rr + 2];
      final po = qx * _ox[3 * rr] + qy * _ox[3 * rr + 1] + qz * _ox[3 * rr + 2];
      return _rayon(rr, math.atan2(po, pa));
    }

    final (ra, ja, va) = rayon(r);
    final (rb, jb, vb) = rayon(r + 1);
    final ray = ra + (rb - ra) * u;
    final nx = g.nx, ny = g.ny, nz = g.nz;
    if (nx == null || ny == null || nz == null) {
      return (rho - ray, V3(qx / rho, qy / rho, qz / rho));
    }
    // La normale maillée : entre les deux colonnes de chaque anneau, puis
    // entre les deux anneaux.
    final c = g.cols;
    V3 normale(int rr, int j, double v) {
      final k0 = (i0 + rr) * c + j, k1 = (i0 + rr) * c + (j + 1) % c;
      return V3(
        nx[k0] + (nx[k1] - nx[k0]) * v,
        ny[k0] + (ny[k1] - ny[k0]) * v,
        nz[k0] + (nz[k1] - nz[k0]) * v,
      );
    }

    final n = V3.lerp(normale(r, ja, va), normale(r + 1, jb, vb), u);
    return (
      rho - ray,
      n.norme < 1e-9 ? V3(qx / rho, qy / rho, qz / rho) : n.unite,
    );
  }
}

/// Un volume quelconque : une distance signée et la direction qui sort.
typedef _Volume = (double, V3) Function(double x, double y, double z);

// ═══ La soudure ═════════════════════════════════════════════════════════════

/// Un déplacement prévu : le sommet, sa nouvelle place, sa normale et son
/// poids, ce qui reste du contour.
typedef _Deplacement = (int, V3, V3, double, double);

/// Pose les sommets de [g] proches du volume [autre] — autour du point
/// [centre] : pleinement jusqu'à [r0], plus du tout au-delà de [r1] — sur
/// l'union lisse de [propre] (le volume de g) et d'[autre], avec un congé
/// de [k]. Rend les déplacements (appliqués ensuite, pour que les deux
/// parties se soudent à partir des mêmes formes).
List<_Deplacement> _souder(
  _Grille g,
  _Volume propre,
  _Volume autre,
  V3 centre,
  double r0,
  double r1,
  double k, {
  int i0 = 0,
  int? i1,
}) {
  final res = <_Deplacement>[];
  final fin = (i1 ?? g.rangs - 1) + 1;
  final r12 = r1 * r1;
  for (var k0 = i0 * g.cols; k0 < fin * g.cols; k0++) {
    final px = g.x[k0], py = g.y[k0], pz = g.z[k0];
    final ex = px - centre.x, ey = py - centre.y, ez = pz - centre.z;
    final e2 = ex * ex + ey * ey + ez * ez;
    if (e2 > r12) continue;
    final kk = k * (1 - _lisse(r0, r1, math.sqrt(e2)));
    if (kk < 1e-4) continue;
    final (db0, nb) = autre(px, py, pz);
    if (db0 > kk) continue;
    // Un pas vers l'union lisse : le sommet est sur sa propre surface (à
    // distance nulle, sa normale déjà connue), à db0 de l'autre.
    final na = g.nx == null
        ? propre(px, py, pz).$2
        : V3(g.nx![k0], g.ny![k0], g.nz![k0]);
    const da = 0.0;
    final h = math.max(kk - (da - db0).abs(), 0.0) / kk;
    final f = math.min(da, db0) - h * h * kk / 4;
    final w = (0.5 + 0.5 * (db0 - da) / kk).clamp(0.0, 1.0);
    final n = (na * w + nb * (1 - w)).unite;
    final p = V3(px, py, pz) - n * f;
    final poids = 1 - _lisse(0.0, kk, db0);
    res.add((k0, p, n, poids, _lisse(0.4 * kk, kk, db0)));
  }
  return res;
}

void _appliquer(_Grille g, List<_Deplacement> d) {
  for (final (k, p, n, poids, trait) in d) {
    g.poser(k, p);
    g.imposer(k, n.x, n.y, n.z, poids);
    g.trait[k] *= trait;
  }
}

/// Cache les cases de [g] dont les quatre coins sont ENFOUIS dans [autre]
/// (plus loin que [marge] sous sa surface) : elles ne se verraient pas, et
/// leur ordre de peinture hésitait avec la surface qui les recouvre.
void _enfouir(
  _Grille g,
  _Volume autre,
  double marge, {
  int i0 = 0,
  int? i1,
  V3? centre,
  double rayon = 1,
}) {
  final fin = math.min(i1 ?? g.rangs - 1, g.rangs - 1);
  final dedans = Uint8List(g.n);
  final r2 = rayon * rayon;
  for (var k = i0 * g.cols; k < (fin + 1) * g.cols; k++) {
    if (centre != null) {
      final ex = g.x[k] - centre.x, ey = g.y[k] - centre.y;
      final ez = g.z[k] - centre.z;
      if (ex * ex + ey * ey + ez * ez > r2) continue;
    }
    if (autre(g.x[k], g.y[k], g.z[k]).$1 < -marge) dedans[k] = 1;
  }
  final qc = g.casesParRang, c = g.cols;
  final cachees = g.cachees ??= Uint8List((g.rangs - 1) * qc);
  for (var i = i0; i < fin; i++) {
    for (var j = 0; j < qc; j++) {
      final a = i * c + j, b = a + c;
      final j1 = (j + 1) % c;
      final cc = (i + 1) * c + j1, d = i * c + j1;
      if (dedans[a] + dedans[b] + dedans[cc] + dedans[d] == 4) {
        cachees[i * qc + j] = 1;
      }
    }
  }
}

// lib/widgets/corps/peau/mains.dart
//
// Les MAINS : c'étaient deux ovales (une moufle et un pouce), qui
// s'enfonçaient dans le sol pendant une pompe et ne tenaient pas leur
// haltère.
//
// Une main est une PAUME (du poignet aux jointures, un peu plus épaisse
// côté paume, les jointures en relief sur le dos), quatre DOIGTS de trois
// phalanges (les longueurs d'une vraie main : le majeur le plus long,
// l'auriculaire le plus court, les jointures en arc) et un POUCE opposable.
// Sa PRISE dépend de ce qu'elle fait :
// - elle TIENT (un haltère, une barre, une kettlebell, la barre fixe, un
//   élastique) : les doigts s'enroulent autour de la poignée, le pouce
//   referme par-dessus — et la poignée est dans le poing (`RepereMain`, que
//   le peintre du matériel utilise aussi) ;
// - elle est POSÉE à plat au sol (pompes, planches) : la paume sur le sol,
//   les doigts étalés vers l'avant, le pouce écarté ;
// - elle est LIBRE : les doigts légèrement repliés, plus vers l'auriculaire.
// Bras pendants, la paume regarde la cuisse ; avant-bras relevé, elle se
// tourne vers l'épaule (la supination d'un curl).

part of '../peau3.dart';

/// Le repère d'une main : le poignet, l'axe vers les doigts, la normale qui
/// sort de la paume, le côté du pouce ; la prise (0 : à plat, 1 : serrée
/// sur une poignée) ; posée au sol ou non.
class RepereMain {
  const RepereMain(
    this.poignet,
    this.axe,
    this.paume,
    this.pouce,
    this.prise, {
    this.auSol = false,
    this.jointures,
  });

  final V3 poignet, axe, paume, pouce;
  final double prise;
  final bool auSol;

  /// Posée au sol : les jointures, sur le sol.
  final V3? jointures;

  /// La poignée tenue : dans le poing, devant la paume, au pli des doigts.
  V3 get poignee => poignet + axe * 0.043 + paume * 0.0105;

  /// L'axe de la poignée : le long des jointures.
  V3 get axePoignee => pouce;
}

/// Le repère de la main [proche] (ou loin) de [s], selon ce qu'elle tient.
RepereMain repereMain(Squelette3 s, bool proche, Accessoires acc) {
  final b = proche ? s.brasP : s.brasL;
  final cote = proche ? 1.0 : -1.0;
  final auSol = proche ? s.doigtsAuSolP : s.doigtsAuSolL;
  final w = b.bout;
  if (auSol != null) {
    final k = (proche ? s.jointuresP : s.jointuresL)!;
    final a = (k - w).unite;
    var p = V3.bas.sansComposante(a);
    p = p.norme < 1e-3 ? V3.bas : p.unite;
    return RepereMain(
      w,
      a,
      p,
      p.cross(a).unite * cote,
      0,
      auSol: true,
      jointures: k,
    );
  }
  final dAvant = (b.bout - b.milieu).unite;
  var a = (b.extremite - b.bout);
  a = a.norme < 1e-6 ? dAvant : a.unite;
  // Le côté du pli de l'avant-bras (celui du biceps, de la paume en
  // supination).
  final flexion = _Membres._avantBras(s, dAvant);
  // Bras pendant le long du corps : la paume regarde la cuisse.
  final pendant = _lisse(0.45, 0.85, -a.dot(s.dirTronc));
  final dedans = -s.lateralEpaules * cote;
  var p = flexion * (1 - pendant) + dedans * pendant;
  var prise = 0.3;
  final tient =
      acc.halteres ||
      acc.kettlebells ||
      acc.barre ||
      acc.barreDos ||
      acc.bandeMains ||
      acc.corde ||
      acc.elastique != null ||
      (proche && (acc.haltereUne || acc.kettlebell)) ||
      (acc.kettlebell && (s.brasP.extremite - s.brasL.extremite).norme < 0.1);
  if (tient) prise = 1;
  if (acc.goblet) prise = 0.65;
  if (acc.ballon) prise = 0.12;
  final fixe = acc.barreFixe;
  if (fixe != null &&
      (V3(fixe.dx, fixe.dy, b.extremite.z) - b.extremite).norme < 0.06) {
    // Suspendu : prise en pronation, la paume vers l'avant.
    prise = 1;
    p = s.avantEpaules * 1.0;
  } else if (acc.barre && pendant > 0.5) {
    // Une barre bras tendus (soulevé de terre) : les paumes vers soi.
    p = -s.avantEpaules;
  }
  p = p.sansComposante(a);
  p = p.norme < 1e-3 ? flexion.sansComposante(a).unite : p.unite;
  return RepereMain(w, a, p, p.cross(a).unite * cote, prise);
}

/// Un doigt du gant : sa place sur la largeur (vers le pouce), sa
/// demi-largeur, sa demi-épaisseur, sa longueur depuis la ligne des
/// jointures.
typedef _Doigt = (double, double, double, double);

extension _Mains on Peau3 {
  // L'index, le majeur, l'annulaire, l'auriculaire : accolés, le majeur le
  // plus long, l'auriculaire le plus court.
  static const List<_Doigt> _doigts = [
    (0.0124, 0.0044, 0.0041, 0.0365),
    (0.0040, 0.0046, 0.0043, 0.0415),
    (-0.0046, 0.0043, 0.0040, 0.0393),
    (-0.0122, 0.0038, 0.0035, 0.0314),
  ];

  /// Où se plient les doigts (depuis la ligne des jointures) : la base, le
  /// milieu, le bout.
  static const List<double> _articulations = [0.0, 0.02, 0.0325];

  /// La PAUME, du poignet à la ligne des jointures (distance, négative) :
  /// demi-largeur, épaisseur côté paume, côté dos.
  static const _Profil _paume = [
    (-0.054, 0.0105, 0.0062, 0.0056),
    (-0.046, 0.0128, 0.0068, 0.0059),
    (-0.036, 0.0162, 0.0072, 0.0056),
    (-0.022, 0.0181, 0.0068, 0.0052),
    (-0.01, 0.0186, 0.0058, 0.0048),
    (0.0, 0.0184, 0.005, 0.0046),
  ];

  /// Les distances des anneaux du gant (le long de la main, depuis les
  /// jointures) : la paume, les articulations serrées, les bouts arrondis.
  static const List<double> _fsDetail = [
    -0.054, -0.046, -0.038, -0.028, -0.018, -0.009, -0.004, 0.0, 0.004, //
    0.008, 0.012, 0.016, 0.02, 0.024, 0.028, 0.0325, 0.0355, 0.0375, //
    0.039, 0.0402, 0.041, 0.0415,
  ];
  static const List<double> _fsFin = [
    -0.054, -0.044, -0.03, -0.015, -0.004, 0.004, 0.012, 0.02, 0.028, //
    0.0345, 0.038, 0.0405, 0.0415,
  ];

  /// La section de la paume (demi-largeur [w], épaisseurs [dp] côté paume,
  /// [dd] côté dos), dans la direction [th] : (vers le pouce, vers la
  /// paume).
  static (double, double) _sectionPaume(
    double th,
    double w,
    double dp,
    double dd,
  ) {
    final sn = math.sin(th), c = math.cos(th);
    final x = sn.sign * math.pow(sn.abs(), 0.8).toDouble() * w;
    final y = c.sign * math.pow(c.abs(), 0.8).toDouble() * (c >= 0 ? dp : dd);
    return (x, y);
  }

  /// La section des doigts à la distance [f] des jointures, dans la
  /// direction [th] : l'union des quatre doigts accolés (des ellipses), vue
  /// de leur milieu ; les jointures en relief sur le dos.
  static (double, double) _sectionDoigts(double th, double f) {
    final dx = math.sin(th), dy = math.cos(th);
    var xmin = 1.0, xmax = -1.0;
    final tailles = <(double, double, double)>[];
    for (final (x, a, b, lg) in _doigts) {
      if (f >= lg) continue;
      var k = 1 - 0.16 * f / lg;
      // Le bout arrondi.
      final debut = lg - a;
      if (f > debut) {
        final u = (f - debut) / a;
        k *= math.sqrt(math.max(0.0, 1 - u * u));
      }
      final aa = math.max(1e-5, a * k), bb = math.max(1e-5, b * k);
      // La jointure, sur le dos.
      final bd = bb + 0.0008 * _cloche(f, -0.004, 0.007);
      tailles.add((x, aa, dy < 0 ? bd : bb));
      xmin = math.min(xmin, x - aa);
      xmax = math.max(xmax, x + aa);
    }
    if (tailles.isEmpty) return (0, 0);
    final xc = (xmin + xmax) / 2;
    var r = 0.0;
    for (final (x, a, b) in tailles) {
      // Le rayon parti de (xc, 0) dans la direction (dx, dy) sort de
      // l'ellipse centrée en (x, 0).
      final cx = x - xc;
      final qa = dx * dx / (a * a) + dy * dy / (b * b);
      final qb = -2 * dx * cx / (a * a);
      final qc = cx * cx / (a * a) - 1;
      final d = qb * qb - 4 * qa * qc;
      if (d < 0) continue;
      r = math.max(r, (-qb + math.sqrt(d)) / (2 * qa));
    }
    return (xc + r * dx, r * dy);
  }

  /// Une main entière : le GANT (la paume et les quatre doigts d'un seul
  /// tenant, sans jointure à raccorder) et le pouce.
  List<_Grille> _main(Squelette3 s, bool proche) {
    final r = repereMain(s, proche, accessoires);
    final w = r.poignet, p = r.paume, t = r.pouce, a = r.axe;
    final longueur = r.jointures != null ? (r.jointures! - w).norme : 0.046;
    final k0 = w + a * longueur;
    // Les plis des trois articulations (en degrés, vers la paume).
    final List<double> plis;
    if (r.auSol) {
      // À plat : les doigts reviennent à l'horizontale, sur le sol.
      final pente = math.asin(a.y.clamp(-1.0, 1.0)) * 180 / math.pi;
      plis = [-pente, 3, 2];
    } else {
      plis = [14 + 54 * r.prise, 22 + 72 * r.prise, 10 + 48 * r.prise];
    }
    double angle(double f) {
      var al = 0.0;
      for (var k = 0; k < 3; k++) {
        al +=
            plis[k] *
            _lisse(_articulations[k] - 0.003, _articulations[k] + 0.003, f);
      }
      return rad(al);
    }

    final fs = _detail ? _fsDetail : _fsFin;
    final cols = _detail ? 36 : 20;
    final g = _Grille(fs.length, cols)..ss = fs;
    g.teindre(_teintPeau);
    // L'axe du gant : droit dans la paume, puis plié aux articulations
    // (intégré pas à pas).
    var c = k0 + a * fs.first;
    var fPrec = fs.first;
    for (var i = 0; i < fs.length; i++) {
      final f = fs[i];
      if (i > 0) {
        const n = 4;
        for (var q = 0; q < n; q++) {
          final fm = fPrec + (f - fPrec) * (q + 0.5) / n;
          final al = fm <= 0 ? 0.0 : angle(fm);
          c = c + (a * math.cos(al) + p * math.sin(al)) * ((f - fPrec) / n);
        }
      }
      fPrec = f;
      final al = f <= 0 ? 0.0 : angle(f);
      final pp = p * math.cos(al) - a * math.sin(al);
      final (lg, dp, dd) = _profil(_paume, math.min(f, 0.0));
      final m = _lisse(-0.004, 0.004, f);
      for (var j = 0; j < cols; j++) {
        final th = 2 * math.pi * j / cols;
        var (x, y) = _sectionPaume(th, lg, dp, dd);
        if (m > 0) {
          final (x2, y2) = _sectionDoigts(th, math.max(f, 0.0004));
          x += (x2 - x) * m;
          y += (y2 - y) * m;
        }
        final k = i * cols + j;
        g.poser(k, c + t * x + pp * y);
        // Les ongles : plus clairs et rosés sur le dos du bout des doigts.
        if (y < 0 && f > 0.026) {
          for (final (xd, ad, _, ld) in _doigts) {
            if (f > ld - 0.0095 && (x - xd).abs() < 0.62 * ad) {
              g.meler(k, 0xFFEBC8BC, 0.5 * _lisse(0.3, 0.8, -math.cos(th)));
            }
          }
        }
        // Les plis des phalanges, côté paume ; les sillons entre les doigts.
        if (y > 0) {
          for (final ar in _articulations) {
            g.ao[k] *= 1 - 0.18 * _cloche(f, ar - 0.002, ar + 0.002);
          }
        }
      }
    }
    g.trait.fillRange(0, g.n, 0);

    // Le pouce : sa base dans la paume, près du poignet ; écarté à plat, le
    // long de l'index quand la main est libre, refermé par-dessus les doigts
    // quand elle serre.
    final baseP = w + a * (0.012 * longueur / 0.046) + t * 0.0118 + p * 0.004;
    final pr = r.prise;
    // Libre : le long de l'index, un peu devant la paume ; serré : devant
    // la poignée, puis en travers des doigts.
    var dirP =
        (a * (0.85 - 0.05 * pr) + p * (0.4 + 0.08 * pr) + t * (0.24 - 0.6 * pr))
            .unite;
    var vers =
        (p * (0.75 - 0.5 * pr) + a * (0.2 - 0.25 * pr) - t * (0.12 + 0.75 * pr))
            .unite;
    if (r.auSol) {
      // À plat : le pouce s'écarte sur le sol, son bout posé.
      final e = (a * math.cos(rad(42)) + t * math.sin(rad(42))).unite;
      final h = V3(e.x, 0, e.z);
      dirP = h.norme < 1e-3
          ? e
          : (V3(
                      (baseP + h.unite * 0.04).x,
                      kSol - 0.0045,
                      (baseP + h.unite * 0.04).z,
                    ) -
                    baseP)
                .unite;
      vers = V3.bas;
    }
    var cote = vers.sansComposante(dirP);
    cote = cote.norme < 1e-3 ? p.sansComposante(dirP).unite : cote.unite;
    final ptsP = <V3>[baseP];
    var qp = baseP;
    for (final (lg, pli) in [
      (0.02, 0.0),
      (0.014, r.auSol ? 5.0 : 12 + 30 * pr),
      (0.012, r.auSol ? 5.0 : 14 + 34 * pr),
    ]) {
      final pl = rad(pli);
      final nd = (dirP * math.cos(pl) + cote * math.sin(pl)).unite;
      cote = (cote * math.cos(pl) - dirP * math.sin(pl)).unite;
      dirP = nd;
      qp = qp + dirP * lg;
      ptsP.add(qp);
    }
    return [
      g,
      _tubeDoigt(
        ptsP,
        const [0.0066, 0.0052, 0.0047, 0.0042],
        -cote,
        _detail ? 8 : 6,
      ),
    ];
  }

  /// Un doigt : un tube le long des phalanges [pts] (de la base au bout),
  /// de [rayons] (un par point), arrondi au bout ; [dos] : le côté de
  /// l'ongle au bout.
  _Grille _tubeDoigt(List<V3> pts, List<double> rayons, V3 dos, int cols) {
    // Les anneaux : un peu dans la paume, chaque phalange en deux, puis le
    // bout arrondi.
    final centres = <V3>[], ray = <double>[], dirs = <V3>[];
    V3 dirEn(int k) =>
        (pts[math.min(k + 1, pts.length - 1)] - pts[math.max(k - 1, 0)]).unite;
    final d0 = (pts[1] - pts[0]).unite;
    centres.add(pts[0] - d0 * 0.004);
    ray.add(rayons[0] * 0.9);
    dirs.add(d0);
    for (var k = 0; k < pts.length - 1; k++) {
      final dk = (pts[k + 1] - pts[k]).unite;
      centres.add(pts[k]);
      ray.add(rayons[k] * (k == 0 ? 1.0 : 1.06));
      dirs.add(k == 0 ? dk : dirEn(k));
      centres.add(V3.lerp(pts[k], pts[k + 1], 0.5));
      ray.add((rayons[k] + rayons[k + 1]) / 2 * 0.96);
      dirs.add(dk);
    }
    final fin = pts.last, df = (pts.last - pts[pts.length - 2]).unite;
    final rb = rayons.last;
    for (final (avance, r) in [
      (0.0, rb),
      (0.55, rb * 0.85),
      (0.88, rb * 0.5),
      (1.0, rb * 0.08),
    ]) {
      centres.add(fin + df * (avance * rb));
      ray.add(r);
      dirs.add(df);
    }
    final g = _Grille(centres.length, cols);
    g.teindre(_teintPeau);
    for (var i = 0; i < centres.length; i++) {
      final dd = dirs[i];
      var e1 = dos.sansComposante(dd);
      e1 = e1.norme < 1e-6 ? dd.cross(V3.proche).unite : e1.unite;
      final e2 = dd.cross(e1).unite;
      for (var j = 0; j < cols; j++) {
        final a = 2 * math.pi * j / cols;
        // Un peu plat sur le dessus (l'ongle), rond dessous.
        final c = math.cos(a);
        final r = ray[i] * (c > 0 ? 1 - 0.1 * c : 1.0);
        final k = i * cols + j;
        g.poser(k, centres[i] + e1 * (c * r) + e2 * (math.sin(a) * r));
        // L'ongle : plus clair et rosé sur le dos de la dernière phalange.
        if (i >= centres.length - 5 && c > 0.55) {
          g.meler(k, 0xFFEBC8BC, 0.55 * _lisse(0.55, 0.9, c));
        }
        // Les plis des phalanges, plus sombres côté paume.
        if (c < -0.5) g.ao[k] = 0.88;
      }
    }
    g.trait.fillRange(0, g.n, 0);
    return g;
  }
}

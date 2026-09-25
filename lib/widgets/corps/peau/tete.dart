// lib/widgets/corps/peau/tete.dart
//
// La TÊTE, sculptée : la tête était un œuf (crâne et mâchoire), les yeux deux
// points, les sourcils deux tirets, le nez une cheville collée, pas de
// bouche, une calotte de bain pour cheveux.
//
// La tête est LISSÉE PAR ÉTAGES, comme le tronc : de la pointe du menton au
// sommet du crâne, chaque étage a son avant, son arrière et sa largeur — les
// proportions d'un adulte (23 cm du menton au sommet, 16 de large, les tiers
// du visage égaux : front, nez, bas du visage), la mâchoire qui se resserre
// vers le menton, le crâne rond derrière, la nuque où entre le cou. Puis le
// RELIEF du visage : les arcades, le creux sous elles et le globe des yeux,
// le nez (un profil de la racine à la pointe, ses ailes), les pommettes, le
// creux des joues, les lèvres, le sillon sous la lèvre, le menton, l'angle
// et le bord de la mâchoire, les tempes. Le maillage est DENSE sur le
// visage, lâche derrière la tête.
//
// Posés sur la peau (collés à la surface, peints juste après elle) : les
// YEUX (le blanc, l'iris, la pupille ; la paupière qui cligne), le trait des
// cils, les SOURCILS, les LÈVRES, les narines ; les joues et le bout du nez
// rosés. Les OREILLES (l'hélix au bord, la conque creuse) et les CHEVEUX
// (une coupe courte : du volume dessus, ras sur les côtés, des mèches).
//
// Coordonnées : la hauteur u depuis le centre de la tête (1 cm ≈ 0,0046),
// l'angle φ autour (0 : devant, 90 : le côté proche, 180 : derrière).

part of '../peau3.dart';

/// Un relief (ou un creux) du visage, rond en (hauteur, angle), symétrique
/// si [sym].
class _Relief {
  const _Relief(
    this.u,
    this.phi,
    this.ru,
    this.rphi,
    this.h, {
    this.sym = true,
  });

  final double u, phi, ru, rphi, h;
  final bool sym;
}

/// La tête : son centre et son repère (avant, côté, haut).
class _FormeTete {
  _FormeTete(Squelette3 s)
    : h = s.tete,
      u = s.hautTete,
      f = s.avantTete,
      l = s.hautTete.cross(s.avantTete).unite,
      cou = s.cou,
      _base = (s.tete - s.cou).norme {
    // Le cou part de sa base dans la direction du dos (du milieu du dos au
    // cou), puis rejoint l'axe de la tête.
    final t = s.cou - s.dosControle;
    _dos = t.norme < 1e-6 ? s.dirTronc : t.unite;
  }

  final V3 h, u, f, l, cou;

  /// La base du cou, sous le centre de la tête ; la direction du dos.
  final double _base;
  late final V3 _dos;

  /// Jusqu'où le cou suit le dos avant de rejoindre l'axe de la tête.
  static const double _plie = 0.034;

  /// Les étages : (hauteur, avant, arrière, demi-largeur) — du bas du cou
  /// (dans le haut du tronc) au sommet du crâne. Sous le menton, la gorge ;
  /// derrière, la nuque qui file dans le cou.
  static const _Profil _etages = [
    (-0.08, 0.02, 0.024, 0.024),
    (-0.074, 0.021, 0.025, 0.0235),
    (-0.064, 0.0215, 0.0255, 0.023),
    (-0.057, 0.022, 0.026, 0.0232),
    (-0.05, 0.024, 0.027, 0.0238),
    (-0.041, 0.029, 0.0275, 0.025),
    (-0.032, 0.036, 0.029, 0.0272),
    (-0.022, 0.041, 0.035, 0.0305),
    (-0.011, 0.040, 0.042, 0.0335),
    (0.0, 0.0395, 0.046, 0.0352),
    (0.0095, 0.0425, 0.047, 0.0362),
    (0.021, 0.040, 0.046, 0.0356),
    (0.033, 0.034, 0.041, 0.032),
    (0.042, 0.025, 0.033, 0.026),
    (0.049, 0.014, 0.021, 0.016),
    (0.052, 0.005, 0.009, 0.007),
    (0.053, 0.001, 0.001, 0.001),
  ];

  static const double bas = -0.08, sommet = 0.053;

  /// La MANDIBULE, sous les joues : un « U » dont le fond est le menton
  /// et les branches remontent vers les oreilles — (hauteur, centre avant,
  /// avant, demi-largeur). Unie au cou (les étages), elle dessine de face
  /// la ligne de la mâchoire, de l'oreille au menton.
  static const _Profil _machoire = [
    (-0.0575, 0.012, 0.012, 0.0015),
    (-0.0555, 0.011, 0.022, 0.006),
    (-0.053, 0.009, 0.031, 0.0092),
    (-0.05, 0.006, 0.0368, 0.0127),
    (-0.046, 0.002, 0.0402, 0.0165),
    (-0.041, -0.002, 0.0415, 0.0212),
    (-0.036, -0.004, 0.042, 0.025),
    (-0.03, -0.004, 0.0424, 0.0275),
    (-0.02, -0.004, 0.041, 0.0302),
  ];

  /// Le NEZ, de la base à la racine : (hauteur, avancée, demi-largeur en
  /// degrés, 0).
  static const _Profil _nez = [
    (-0.0255, 0.0, 7.0, 0),
    (-0.0238, 0.0022, 9.0, 0),
    (-0.0222, 0.0062, 10.0, 0),
    (-0.0205, 0.0092, 9.0, 0),
    (-0.0185, 0.0096, 7.5, 0),
    (-0.0155, 0.0089, 6.2, 0),
    (-0.011, 0.0068, 5.2, 0),
    (-0.006, 0.0046, 4.6, 0),
    (-0.001, 0.0024, 4.8, 0),
    (0.0035, 0.0, 5.5, 0),
  ];

  static const List<_Relief> _reliefs = [
    // Les arcades, la glabelle entre elles.
    _Relief(0.0078, 19, 0.0038, 16, 0.0018),
    _Relief(0.0045, 0, 0.003, 7, 0.001, sym: false),
    // Le creux sous l'arcade, et le globe de l'œil sous les paupières.
    _Relief(0.0022, 19, 0.0038, 12, -0.0021),
    _Relief(-0.0022, 20.5, 0.0033, 9.5, 0.0012),
    // Les pommettes, douces ; les tempes.
    _Relief(-0.008, 38, 0.011, 20, 0.001),
    _Relief(0.012, 60, 0.009, 12, -0.0014),
    // Les ailes du nez, sa pointe.
    _Relief(-0.0205, 9.5, 0.0024, 4, 0.0028),
    _Relief(-0.0185, 0, 0.0023, 6, 0.001, sym: false),
    // La bouche : le massif de la lèvre supérieure, son ourlet, la lèvre
    // inférieure, la fente, les commissures, le philtrum.
    _Relief(-0.027, 0, 0.004, 18, 0.0018, sym: false),
    _Relief(-0.0305, 0, 0.0017, 13, 0.0008, sym: false),
    _Relief(-0.035, 0, 0.0021, 12, 0.0018, sym: false),
    _Relief(-0.0325, 0, 0.001, 15, -0.0008, sym: false),
    _Relief(-0.0328, 15, 0.002, 3, -0.0006),
    _Relief(-0.0275, 3, 0.0024, 1.3, 0.0003),
    // Le sillon sous la lèvre, le menton.
    _Relief(-0.039, 0, 0.0022, 12, -0.0008, sym: false),
    _Relief(-0.0465, 0, 0.007, 20, 0.0016, sym: false),
    // L'angle de la mâchoire (le masséter), son bord, le creux dessous,
    // l'occiput.
    _Relief(-0.034, 72, 0.01, 18, 0.0006),
    // Le cou : la pomme d'Adam, les sterno-cléido-mastoïdiens (de derrière
    // l'oreille au creux du sternum), la nuque.
    _Relief(-0.064, 0, 0.005, 12, 0.0016, sym: false),
    _Relief(-0.046, 88, 0.009, 16, 0.0012),
    _Relief(-0.06, 55, 0.009, 16, 0.0016),
    _Relief(-0.073, 24, 0.007, 14, 0.0013),
    _Relief(-0.07, 180, 0.012, 28, 0.0012, sym: false),
    _Relief(0.006, 180, 0.015, 30, 0.0015, sym: false),
  ];

  /// Le relief du visage à la hauteur [uu], à l'angle [phi] (degrés).
  static double relief(double uu, double phi) {
    var r = 0.0;
    final a = phi.abs();
    // Le nez.
    if (uu < 0.0035 && uu > -0.0255 && a < 12) {
      final (avance, largeur, _) = _hermite(_nez, uu);
      final x = phi / largeur;
      if (x.abs() < 1) {
        final c = 1 - x * x;
        r += avance * c * c;
      }
    }
    for (final t in _reliefs) {
      final du = (uu - t.u) / t.ru;
      if (du.abs() >= 1) continue;
      final dp = _ecart(t.sym ? a : phi, t.phi) / t.rphi;
      if (dp >= 1) continue;
      r += t.h * _rond(du * du + dp * dp);
    }
    return r;
  }

  double _uEtage = double.nan;
  late (double, double, double, double) _etage;

  /// L'étage [uu] : avant, arrière, demi-largeur, carré (0 : rond — le bas
  /// du visage ; 1 : un peu carré — le crâne).
  (double, double, double, double) _etageEn(double uu) {
    if (uu == _uEtage) return _etage;
    _uEtage = uu;
    final (av, ar, la) = _profil(_etages, uu);
    return _etage = (av, ar, la, _lisse(-0.02, 0.012, uu));
  }

  /// La mandibule dans la direction (c, s) : où le rayon sort du « U »
  /// (0 derrière, ou sous elle).
  static double _uMachoire = double.nan;
  static (double, double, double) _machoireCache = (0, 0, 0);

  static double _mandibule(double uu, double c, double s) {
    if (uu > -0.016 || uu < -0.0575 || c <= 0) return 0;
    if (uu != _uMachoire) {
      _uMachoire = uu;
      _machoireCache = _hermite(_machoire, uu);
    }
    final (cf, av, la) = _machoireCache;
    final a = math.max(1e-4, av - cf), b = math.max(1e-4, la);
    final qa = c * c / (a * a) + s * s / (b * b);
    final qb = -2 * c * cf / (a * a);
    final qc = cf * cf / (a * a) - 1;
    final d = qb * qb - 4 * qa * qc;
    if (d < 0) return 0;
    return (-qb + math.sqrt(d)) / (2 * qa);
  }

  /// Le centre et le repère (avant, côté) de l'étage [uu] : l'axe de la
  /// tête, sauf en bas du cou, qui part de sa base dans la direction du dos
  /// et rejoint l'axe en se courbant.
  double _uRepere = double.nan;
  late (V3, V3, V3) _repereCache;

  (V3, V3, V3) _repere(double uu) {
    if (uu == _uRepere) return _repereCache;
    _uRepere = uu;
    return _repereCache = _repereCalcule(uu);
  }

  (V3, V3, V3) _repereCalcule(double uu) {
    final d = uu + _base;
    final axe = h + u * uu;
    if (d >= _plie) return (axe, f, l);
    final x = d < 0 ? 0.0 : d / _plie;
    final ecart = _dos - u;
    final g = (d < 0 ? d : d * (1 - x) * (1 - x));
    final pente = d < 0 ? 1.0 : (1 - x) * (1 - 3 * x);
    final tan = (u + ecart * pente).unite;
    // La rotation qui porte l'axe de la tête sur la tangente.
    final ax = u.cross(tan);
    final sn = ax.norme;
    if (sn < 1e-6) return (axe + ecart * g, f, l);
    final a = math.asin(sn.clamp(-1.0, 1.0));
    final k = ax / sn;
    return (axe + ecart * g, f.tourne(k, a), l.tourne(k, a));
  }

  /// Le point de la surface à la hauteur [uu] et à l'angle [phi]
  /// (degrés), écarté de [plus].
  V3 point(double uu, double phi, [double plus = 0]) {
    final (av, ar, la, carre) = _etageEn(uu);
    final c = math.cos(rad(phi)), s = math.sin(rad(phi));
    final cx = c + (c.sign * _carre(c.abs()) - c) * carre;
    final sy = s + (s.sign * _carre(s.abs()) - s) * carre;
    final ex = cx * (c >= 0 ? av : ar), ey = sy * la;
    var n = math.sqrt(ex * ex + ey * ey);
    // La mandibule, unie au reste (un maximum adouci).
    if (n > 1e-9) {
      final m = _mandibule(uu, ex / n, ey / n);
      if (m > 0) {
        const k = 0.004;
        final h = math.max(k - (m - n).abs(), 0.0) / k;
        // Elle s'efface en montant dans les joues.
        final w = _lisse(-0.016, -0.028, uu);
        n += (math.max(m, n) + h * h * k / 4 - n) * w;
      }
    }
    final base = math.sqrt(ex * ex + ey * ey);
    final g = base < 1e-9 ? 1.0 : (n + relief(uu, phi) + plus) / base;
    final (o, ff, ll) = _repere(uu);
    return o + ff * (ex * g) + ll * (ey * g);
  }

  /// La normale de la surface en ([uu], [phi]) (par différences).
  V3 normale(double uu, double phi) {
    final a = point(uu + 0.0006, phi) - point(uu - 0.0006, phi);
    final b = point(uu, phi + 0.8) - point(uu, phi - 0.8);
    final n = b.cross(a);
    final q = point(uu, phi) - _repere(uu).$1;
    if (n.norme < 1e-12) return q.unite;
    return n.dot(q) < 0 ? -n.unite : n.unite;
  }
}

extension _Tete on Peau3 {
  /// Des pas réguliers par tronçons : (début, pas) … (fin, _).
  static List<double> _pas(List<(double, double)> troncons) {
    final r = <double>[];
    for (var k = 0; k < troncons.length - 1; k++) {
      final (a, pa) = troncons[k];
      final (b, _) = troncons[k + 1];
      final n = math.max(1, ((b - a) / pa).round());
      for (var i = 0; i < n; i++) {
        r.add(a + (b - a) * i / n);
      }
    }
    r.add(troncons.last.$1);
    return r;
  }

  // Les étages et les angles du maillage : dense sur le visage, lâche
  // derrière.
  static final List<double> _usDetail = _pas(const [
    (-0.08, 0.005),
    (-0.06, 0.0021),
    (0.012, 0.006),
    (0.047, 0.003),
    (0.053, 0),
  ]);
  static final List<double> _phisDetail = _pas(const [
    (0, 3.8),
    (50, 8),
    (110, 17),
    (250, 8),
    (310, 3.8),
    (360, 0),
  ])..removeLast();
  static final List<double> _usFin = _pas(const [
    (-0.08, 0.005),
    (-0.055, 0.0035),
    (0.012, 0.008),
    (0.053, 0),
  ]);
  static final List<double> _phisFin = _pas(const [
    (0, 6),
    (50, 12),
    (110, 20),
    (250, 12),
    (310, 6),
    (360, 0),
  ])..removeLast();
  static final List<double> _usLeger = _pas(const [(-0.08, 0.012), (0.053, 0)]);
  static final List<double> _phisLeger = _pas(const [(0, 30), (360, 0)])
    ..removeLast();

  /// Le visage se détaille (yeux, lèvres, oreilles, mèches) à partir de
  /// cette taille.
  bool get _detail => cote >= 200;

  /// La grille de la tête (pas encore peinte).
  (_FormeTete, _Grille) _tete(Squelette3 s) {
    final t = _FormeTete(s);
    final us = _detail ? _usDetail : (fin ? _usFin : _usLeger);
    final phis = _detail ? _phisDetail : (fin ? _phisFin : _phisLeger);
    final rangs = us.length, cols = phis.length;
    final g = _Grille(rangs, cols)
      ..ss = us
      ..phis = phis;
    g.teindre(_teintPeau);
    final lignes = [
      for (final p in phis) _hermite(_ligne, (p > 180 ? p - 360 : p).abs()).$1,
    ];
    for (var i = 0; i < rangs; i++) {
      for (var j = 0; j < cols; j++) {
        final k = i * cols + j;
        final phi = phis[j] > 180 ? phis[j] - 360 : phis[j];
        g.poser(k, t.point(us[i], phi));
        _teinteVisage(g, k, us[i], phi);
        // Le cuir chevelu, sous les cheveux, prend leur couleur.
        if (fin) {
          final ligne = lignes[j];
          g.meler(
            k,
            0xFF3A2B22,
            0.9 * _lisse(ligne + 0.003, ligne + 0.008, us[i]),
          );
        }
      }
    }
    return (t, g);
  }

  /// La couleur et l'ombre du visage en ([uu], [phi]) : les joues et le
  /// bout du nez rosés, une ombre de barbe rasée, le pli de la paupière,
  /// les narines, les commissures, le sillon du nez à la bouche.
  void _teinteVisage(_Grille g, int k, double uu, double phi) {
    final a = phi.abs();
    double tache(double u0, double p0, double ru, double rp) {
      final du = (uu - u0) / ru, dp = (a - p0) / rp;
      final d = du * du + dp * dp;
      return d < 1 ? _rond(d) : 0;
    }

    g.meler(k, 0xFFDE9B86, 0.12 * tache(-0.011, 34, 0.01, 14));
    g.meler(k, 0xFFDC9A88, 0.15 * tache(-0.018, 0, 0.004, 6));
    // La barbe rasée : la mâchoire, le menton, la lèvre supérieure (pas
    // sur les lèvres).
    if (uu < -0.022 && uu > -0.06 && a < 90) {
      final surLevres = (uu > -0.0385 && uu < -0.0295 && a < 14) ? 1.0 : 0.0;
      final barbe =
          _lisse(-0.022, -0.026, uu) *
          (1 - _lisse(72, 90, a)) *
          (1 - surLevres);
      g.meler(k, 0xFFB8998A, 0.0 * barbe);
    }
    var o = 1.0;
    o *= 1 - 0.2 * tache(0.0015, 20, 0.0013, 9);
    o *= 1 - 0.55 * tache(-0.0228, 4.6, 0.0014, 2.6);
    o *= 1 - 0.25 * tache(-0.0328, 15, 0.0017, 2.8);
    if (uu < -0.017 && uu > -0.034) {
      final v = (uu + 0.017) / -0.017;
      final ligne = 12.5 + 5.5 * v;
      final dl = (a - ligne) / 1.8;
      if (dl.abs() < 1) o *= 1 - 0.1 * (1 - dl * dl) * _cloche(v, -0.1, 1.1);
    }
    g.ao[k] *= o;
  }

  void _peindreTete(_FormeTete t, _Grille g) {
    _emettre(g, const [_peau], partie: _pTete);
    if (fin) _chevelure(t, g);
    if (!_detail) {
      _yeuxSimples(t, g);
      return;
    }
    if (t.normale(-0.033, 0).dot(_l.vers) > -0.2) _bouche(t, g);
    for (final sens in [1.0, -1.0]) {
      // Seulement ce qui se tourne vers nous.
      if (t.normale(-0.002, 20 * sens).dot(_l.vers) > -0.1) {
        _unOeil(t, g, sens);
      }
      if (t.normale(0.008, 18 * sens).dot(_l.vers) > -0.1) {
        _sourcil(t, g, sens);
      }
      if (t.normale(-0.006, 95 * sens).dot(_l.vers) > -0.35) {
        _oreille(t, sens);
      }
      if (t.normale(-0.023, 5 * sens).dot(_l.vers) > -0.2) {
        _tache(t, g, -0.0232, 4.8 * sens, 0.0008, 2.0, 0xFF3A2320);
      }
    }
  }

  /// Des yeux d'un trait (les figures moyennes).
  void _yeuxSimples(_FormeTete t, _Grille g) {
    if (!fin) return;
    for (final sens in [1.0, -1.0]) {
      if (t.normale(-0.002, 20 * sens).dot(_l.vers) < 0.1) continue;
      _tache(t, g, -0.002, 20.5 * sens, 0.0016, 6, 0xFF2A1E19);
      _tache(t, g, 0.008, 19 * sens, 0.001, 10, 0xFF3A2A21);
    }
  }

  /// Une grille POSÉE sur la tête : ses sommets en (hauteur, angle)
  /// ([lieu]), un rien au-dessus de la peau (plus l'[epaisseur] propre à
  /// chaque sommet), peinte juste après les cases de la tête qu'elle
  /// recouvre.
  _Grille _posee(
    _FormeTete t,
    _Grille tete,
    int rangs,
    int cols,
    (double, double) Function(int i, int j) lieu, {
    double plus = 0.0003,
    double Function(int i, int j)? epaisseur,
  }) {
    final g = _Grille(rangs, cols, boucle: false)..dedans = t.h;
    final cases = Int32List(rangs * cols);
    for (var i = 0; i < rangs; i++) {
      for (var j = 0; j < cols; j++) {
        final (uu, phi) = lieu(i, j);
        final k = i * cols + j;
        g.poser(k, t.point(uu, phi, plus + (epaisseur?.call(i, j) ?? 0)));
        g.trait[k] = 0;
        cases[k] = tete.caseEn(uu, phi);
      }
    }
    g.zCases = Peau3._ancrer(tete, g, cases);
    return g;
  }

  /// Une tache ovale posée sur la tête (une narine, un œil d'un trait).
  void _tache(
    _FormeTete t,
    _Grille tete,
    double uu,
    double phi,
    double ru,
    double rphi,
    int couleur,
  ) {
    const n = 10;
    final g = _posee(t, tete, 2, n + 1, (i, j) {
      final a = 2 * math.pi * j / n;
      return (uu + ru * i * math.sin(a), phi + rphi * i * math.cos(a));
    });
    g.teindre(couleur);
    _emettre(g, const [_oeil], zImpose: g.zCases);
  }

  /// Un ŒIL : le blanc, l'iris brun, la pupille, entre deux paupières en
  /// amande (le coin externe un peu plus haut) ; le trait des cils, épais
  /// dessus ; la paupière qui descend quand l'œil cligne.
  void _unOeil(_FormeTete t, _Grille tete, double sens) {
    const centre = -0.0024, phi0 = 20.5, demi = 8.6;
    final ouvert = 1 - clignement.clamp(0.0, 1.0);
    double haut(double x) {
      final c = (x + 0.15) / 1.15;
      return centre + 0.0019 * math.max(0, 1 - c * c) + 0.00028 * x;
    }

    double bas(double x) =>
        centre - 0.0012 * math.pow(math.max(0, 1 - x * x), 0.9) + 0.00028 * x;
    double paupiere(double x) => bas(x) + (haut(x) - bas(x)) * ouvert;
    double phiDe(double x) => sens * (phi0 + demi * x);

    if (ouvert > 0.08) {
      const rangs = 6, cols = 15;
      final g = _posee(t, tete, rangs, cols, (i, j) {
        final x = -1 + 2 * j / (cols - 1);
        final v = i / (rangs - 1);
        return (bas(x) + (paupiere(x) - bas(x)) * v, phiDe(x));
      }, plus: 0.0002);
      g.teindre(0xFFEDE5DF);
      // L'iris : un peu sous la paupière du haut, le regard droit devant.
      const iU = -0.0021, iPhi = 20.8, rIris = 0.0024, rPupille = 0.0009;
      const parDegre = 0.0007;
      for (var i = 0; i < rangs; i++) {
        for (var j = 0; j < cols; j++) {
          final k = i * cols + j;
          final x = -1 + 2 * j / (cols - 1);
          final v = i / (rangs - 1);
          final uu = bas(x) + (paupiere(x) - bas(x)) * v;
          final du = uu - iU, dp = (sens * phiDe(x) - iPhi) * parDegre;
          final d = math.sqrt(du * du + dp * dp);
          if (d < rPupille) {
            g.meler(k, 0xFF100B0A, 1);
          } else if (d < rIris) {
            // L'iris : plus sombre au bord, plus chaud vers la pupille.
            final q = (d - rPupille) / (rIris - rPupille);
            g.meler(k, q > 0.75 ? 0xFF2E1D14 : 0xFF6A4630, 1);
          } else if (x < -0.72) {
            // Le coin interne, rose.
            g.meler(k, 0xFFD9A596, _lisse(-0.72, -0.95, x));
          }
          // Le blanc s'ombre sous la paupière du haut.
          g.ao[k] = 1 - 0.35 * _lisse(0.45, 1, v);
        }
      }
      _emettre(g, const [_oeil], zImpose: g.zCases);
    }
    // Le trait des cils : le bord de la paupière du haut, épais vers
    // l'extérieur ; celui du bas, fin et clair.
    _ruban(
      t,
      tete,
      (x) => paupiere(x) + 0.0002,
      phiDe,
      (x) => 0.00042 + 0.0004 * _lisse(-0.6, 0.9, x),
      0xFF1A1210,
    );
    if (ouvert > 0.08) {
      _ruban(
        t,
        tete,
        (x) => bas(x) - 0.0001,
        phiDe,
        (x) => 0.00026 * (1 - x.abs() * 0.5),
        0xFF8C6454,
      );
    }
  }

  /// Les LÈVRES : la supérieure (l'arc de Cupidon), l'inférieure, plus
  /// pleine, et la fente entre elles, sombre au milieu.
  void _bouche(_FormeTete t, _Grille tete) {
    const cols = 15;
    double fente(double x) => -0.0325 - 0.0004 * x * x;
    double phiDe(double x) => 15.0 * x;
    double haut(double x) {
      final a = x.abs();
      return -0.0303 +
          0.0004 * _cloche(a, 0, 0.42) -
          0.0019 * _lisse(0.4, 1, a);
    }

    double bas(double x) => -0.0362 + 0.0028 * _lisse(0.15, 1, x.abs());
    for (final bord in [haut, bas]) {
      const rangs = 3;
      final g = _posee(t, tete, rangs, cols, (i, j) {
        final x = -1 + 2 * j / (cols - 1);
        final v = i / (rangs - 1);
        return (fente(x) + (bord(x) - fente(x)) * v, phiDe(x));
      }, plus: 0.0002);
      g.teindre(0xFFC99486);
      for (var i = 0; i < rangs; i++) {
        for (var j = 0; j < cols; j++) {
          final k = i * cols + j;
          final x = -1 + 2 * j / (cols - 1);
          // Plus sombres vers la fente ; les coins fondent dans la peau.
          g.meler(k, 0xFF9C6259, i == 0 ? 0.45 : 0.0);
          g.meler(k, _teintPeau, _lisse(0.7, 1, x.abs()));
        }
      }
      _emettre(g, const [_levres], zImpose: g.zCases);
    }
    _ruban(
      t,
      tete,
      fente,
      phiDe,
      (x) => 0.00038 * (1 - 0.6 * x.abs()),
      0xFF5E332D,
    );
  }

  /// Un ruban posé sur la tête : de x = −1 à 1, centré sur la hauteur
  /// [haut] (x), à l'angle [phi] (x), épais de [ep] (x).
  void _ruban(
    _FormeTete t,
    _Grille tete,
    double Function(double x) haut,
    double Function(double x) phi,
    double Function(double x) ep,
    int couleur, {
    _Matiere matiere = _oeil,
    int cols = 11,
  }) {
    final g = _posee(t, tete, 2, cols, (i, j) {
      final x = -1 + 2 * j / (cols - 1);
      return (haut(x) + ep(x) * (i - 0.5), phi(x));
    }, plus: 0.00035);
    g.teindre(couleur);
    _emettre(g, [matiere], zImpose: g.zCases);
  }

  /// Un SOURCIL : épais vers le nez, effilé dehors, sur l'arcade.
  void _sourcil(_FormeTete t, _Grille tete, double sens) {
    const rangs = 3, cols = 11;
    final g = _posee(t, tete, rangs, cols, (i, j) {
      final x = -1 + 2 * j / (cols - 1);
      final c = 0.0068 + 0.0012 * (1 - (x - 0.15) * (x - 0.15)) - 0.0003 * x;
      final ep = 0.0011 - 0.0006 * _lisse(-1, 1, x);
      return (c + ep * (i / (rangs - 1) * 2 - 1), sens * (19 + 12.5 * x));
    }, plus: 0.0005);
    g.teindre(0xFF2E221B);
    // Plus clair aux bords (des poils, pas un aplat).
    for (var j = 0; j < cols; j++) {
      g.meler(j, 0xFF6E5445, 0.35);
      g.meler((rangs - 1) * cols + j, 0xFF6E5445, 0.5);
    }
    _emettre(g, const [_cheveux], zImpose: g.zCases);
  }

  /// Une OREILLE : une coquille debout sur le côté de la tête, penchée en
  /// arrière, un peu tournée vers l'avant ; l'hélix roulé au bord, la conque
  /// creuse au milieu, le dos qui rejoint la tête.
  void _oreille(_FormeTete t, double sens) {
    final centre = t.point(-0.006, 96 * sens);
    final dehors = (t.l * (0.93 * sens) + t.f * 0.36).unite;
    final hautO = (t.u * math.cos(rad(14)) - t.f * math.sin(rad(14)))
        .sansComposante(dehors)
        .unite;
    final avant = hautO.cross(dehors).unite * sens;
    // Les anneaux : du creux de la conque au bord, puis le dos.
    const rhos = [0.0, 0.3, 0.52, 0.68, 0.82, 0.93, 1.0, 1.02, 0.9, 0.7];
    const hauteurs = [
      0.0004,
      0.001,
      0.0028,
      0.0042,
      0.0036,
      0.0052,
      0.0046,
      0.0026,
      -0.0005,
      -0.0025,
    ];
    const cols = 16;
    final g = _Grille(rhos.length, cols);
    g.teindre(_teintPeau);
    for (var i = 0; i < rhos.length; i++) {
      for (var j = 0; j < cols; j++) {
        final a = 2 * math.pi * j / cols;
        final ca = math.cos(a), sa = math.sin(a);
        // Le contour : plus haut que large, le lobe en bas, l'avant droit
        // (collé à la joue).
        final larg = ca > 0 ? 0.0066 : 0.0092;
        final haut = sa > 0 ? 0.0166 : 0.0136;
        final r = rhos[i];
        // L'avant de l'oreille (le tragus) reste près de la tête.
        final pres = ca > 0.3 ? 1 - 0.8 * _lisse(0.3, 0.9, ca) : 1.0;
        final k = i * cols + j;
        g.poser(
          k,
          centre +
              avant * (ca * larg * r) +
              hautO * (sa * haut * r - 0.001) +
              dehors * (hauteurs[i] * pres),
        );
        // La conque, dans l'ombre, le sillon sous l'hélix ; l'oreille un
        // peu plus rose que la joue.
        g.ao[k] = r < 0.55
            ? 0.45 + 0.45 * r / 0.55
            : (i == 4 ? 0.78 : (i >= 8 ? 0.7 : 1));
        g.meler(k, 0xFFDA9784, 0.12);
      }
    }
    g.trait.fillRange(0, g.n, 0);
    _emettre(g, const [_peau], partie: _pTete);
  }

  /// La ligne des cheveux (hauteur) selon l'angle (degrés, 0..180) : le
  /// front, les tempes, les pattes devant l'oreille, le tour de l'oreille,
  /// la nuque.
  static const _Profil _ligne = [
    (0, 0.034, 0, 0),
    (22, 0.033, 0, 0),
    (40, 0.029, 0, 0),
    (58, 0.019, 0, 0),
    (70, 0.004, 0, 0),
    (79, -0.012, 0, 0),
    (85, -0.011, 0, 0),
    (90, 0.003, 0, 0),
    (97, 0.012, 0, 0),
    (106, 0.009, 0, 0),
    (116, -0.006, 0, 0),
    (132, -0.022, 0, 0),
    (152, -0.03, 0, 0),
    (180, -0.033, 0, 0),
  ];

  /// Les CHEVEUX : une coupe courte — du volume sur le dessus, un peu
  /// relevé devant, ras sur les côtés et la nuque (la peau transparaît), des
  /// mèches (relief et couleur), une ligne frontale clairsemée ; posés sur
  /// le crâne.
  void _chevelure(_FormeTete t, _Grille tete) {
    final rangs = _detail ? 11 : 7, cols = _detail ? 55 : 31;
    final hs = Float64List(rangs * cols);
    final phis = Float64List(rangs * cols);
    final bruits = Float64List(rangs * cols);
    final bords = [
      for (var j = 0; j < cols; j++)
        _hermite(_ligne, (-180 + 360.0 * j / (cols - 1)).abs()).$1,
    ];
    final g = _posee(
      t,
      tete,
      rangs,
      cols,
      (i, j) {
        final phi = -180 + 360.0 * j / (cols - 1);
        final bord = bords[j];
        final v = i / (rangs - 1);
        final uu =
            bord + (_FormeTete.sommet - 0.0004 - bord) * math.pow(v, 0.85);
        hs[i * cols + j] = uu;
        phis[i * cols + j] = phi;
        return (uu, phi);
      },
      plus: 0,
      epaisseur: (i, j) {
        final uu = hs[i * cols + j], phi = phis[i * cols + j];
        final a = phi.abs();
        final v = i / (rangs - 1);
        // Ras sur les côtés et la nuque, fourni dessus, relevé devant.
        final cotes = 0.0009 + 0.0017 * _lisse(-0.025, 0.025, uu);
        final devant = _lisse(70, 0, a) * _lisse(0.025, 0.045, uu);
        final dessus = 0.0062 + 0.0018 * devant;
        var e = cotes + (dessus - cotes) * _lisse(0.024, 0.048, uu);
        // Les mèches : un relief étiré depuis le sommet.
        final m = bruits[i * cols + j] = _bruitTour(phi, 7.6, 11, uu * 90);
        e *= 1 + 0.32 * (m - 0.5) * _lisse(0.015, 0.04, uu);
        // Le bord fond dans la peau.
        e *= _lisse(0, a < 45 ? 0.1 : 0.16, v) * 0.9 + 0.1;
        return e;
      },
    );
    g.teindre(_cheveux.couleur);
    for (var k = 0; k < g.n; k++) {
      final uu = hs[k], phi = phis[k];
      final v = (k ~/ cols) / (rangs - 1);
      final a = phi.abs();
      // Le dégradé : près de la ligne, sur les côtés et la nuque, la peau
      // transparaît ; devant, la ligne est clairsemée (irrégulière).
      final ras =
          (1 - _lisse(0, 0.4, v)) *
          _lisse(40, 75, a) *
          (1 - _lisse(0.015, 0.032, uu));
      g.meler(k, 0xFF9C7C6A, 0.55 * ras);
      final lisiere = 1 - _lisse(0, 0.14 + 0.08 * bruits[k % cols], v);
      g.meler(k, 0xFFA88672, 0.7 * lisiere * (1 - _lisse(40, 75, a)));
      // Les mèches : des reflets plus clairs, des creux plus sombres.
      final m = bruits[k];
      if (m > 0.55) {
        g.meler(k, 0xFF5A4334, (m - 0.55) * 1.1 * _lisse(0.012, 0.035, uu));
      } else {
        g.meler(k, 0xFF1E1511, (0.55 - m) * 0.9);
      }
      g.ao[k] = 0.8 + 0.2 * _lisse(0.15, 0.6, v);
    }
    _emettre(g, const [_cheveux], zImpose: g.zCases, partie: _pTete);
  }
}

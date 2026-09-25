// lib/widgets/corps/peau/membres.dart
//
// Les MEMBRES, d'un seul tenant de l'épaule (la hanche) au poignet (la
// cheville) : la surface se PLIE à l'articulation — en arc autour du coude,
// du genou — et se TASSE dans le pli ; sa racine, dans le tronc, suit le
// tronc puis le membre. Les MUSCLES sont des reliefs qui se CONTRACTENT : le
// biceps gonfle et remonte quand le coude plie, le mollet quand on monte sur
// la pointe des pieds.
//
// Un angle autour d'un membre se compte en degrés depuis son AVANT (0 :
// devant — biceps, cuisse, paume —, 90 : dehors, 180 : derrière, −90 :
// dedans).

part of '../peau3.dart';

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
class _FormeMembre {
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
    final a = avant.sansComposante(d1);
    a1 = a.norme < 1e-3 ? d1.cross(dehors).unite : a.unite;
    final o = dehors.sansComposante(d1).sansComposante(a1);
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

  double ombre(double s, double phi) => 1 - 0.45 * _pli(_anneauEn(s).$7, phi);
}

extension _Membres on Peau3 {
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
    (-0.15, 0.014, 0.015, 0.016),
    (-0.09, 0.022, 0.024, 0.025),
    (0.0, 0.028, 0.03, 0.03),
    (0.15, 0.0285, 0.0305, 0.0305),
    (0.4, 0.027, 0.028, 0.026),
    (0.7, 0.024, 0.025, 0.023),
    (0.9, 0.022, 0.023, 0.022),
    (1.0, 0.021, 0.022, 0.023),
    (1.18, 0.023, 0.022, 0.024),
    (1.5, 0.019, 0.018, 0.02),
    (1.8, 0.0145, 0.014, 0.0165),
    (1.96, 0.0098, 0.0094, 0.0126),
    (2.01, 0.0078, 0.0074, 0.0102),
    (2.05, 0.003, 0.003, 0.003),
  ];

  static const List<double> _ssBrasFin = [
    -0.19, -0.16, -0.12, -0.07, -0.02, 0.05, 0.12, 0.2, 0.29, 0.38, //
    0.47, 0.56, 0.65, 0.74, 0.82, 0.88, 0.93, 0.97, 1.0, 1.03, //
    1.07, 1.12, 1.19, 1.28, 1.38, 1.49, 1.6, 1.71, 1.81, 1.9, //
    1.96, 2.01, 2.05,
  ];
  static const List<double> _ssBrasLeger = [
    -0.19, -0.13, -0.05, 0.05, 0.18, 0.34, 0.5, 0.66, 0.8, 0.9, //
    0.97, 1.03, 1.1, 1.24, 1.42, 1.6, 1.78, 1.92, 2.01, 2.05,
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

  (_FormeMembre, _Grille) _bras(Squelette3 s, Membre3 b, double cote) {
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
        _Bosse(-0.1, 0.5, 0.35 - 0.1 * monte, 90, 80, 0.003 + 0.0015 * monte),
        const _Bosse(-0.08, 0.42, 0.35, 35, 45, 0.0022),
        const _Bosse(-0.08, 0.42, 0.35, 145, 45, 0.0022),
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
      f.pointCS,
      fin ? _ssBrasFin : _ssBrasLeger,
      fin ? 16 : 10,
      (s) => _lisse(-0.02, 0.2, s) * (1 - _lisse(1.94, 2.0, s)),
      ombre: f.ombre,
    );
    return (f, g);
  }

  void _peindreBras(_Grille g, int partie) {
    _emettre(g, const [_peau], partie: partie);
    _fuseaux(g, _zonesBras);
  }

  // ── Les jambes ───────────────────────────────────────────────────────────

  // La racine reste SOUS la ceinture (elle dépassait du short en dents de
  // scie).
  static const _Profil _profilJambe = [
    (-0.075, 0.004, 0.004, 0.004),
    (-0.04, 0.012, 0.014, 0.012),
    (0.0, 0.022, 0.026, 0.024),
    (0.08, 0.036, 0.04, 0.035),
    (0.18, 0.043, 0.044, 0.039),
    (0.3, 0.043, 0.042, 0.038),
    (0.45, 0.041, 0.038, 0.036),
    (0.62, 0.038, 0.035, 0.034),
    (0.8, 0.033, 0.031, 0.031),
    (0.92, 0.03, 0.029, 0.03),
    (1.0, 0.029, 0.028, 0.03),
    (1.12, 0.027, 0.03, 0.029),
    (1.3, 0.026, 0.031, 0.029),
    (1.45, 0.024, 0.028, 0.026),
    (1.6, 0.02, 0.022, 0.022),
    (1.8, 0.016, 0.017, 0.018),
    (1.88, 0.015, 0.016, 0.017),
    (2.0, 0.016, 0.016, 0.018),
    (2.06, 0.013, 0.013, 0.014),
    (2.1, 0.004, 0.004, 0.004),
  ];

  /// L'ourlet du short, sur la cuisse ; le haut de la soquette (qui
  /// habille la jonction avec la chaussure).
  static const double _ourlet = 0.38;
  static const double _soquette = 1.84;

  static const List<double> _ssJambeFin = [
    -0.075, -0.055, -0.03, 0.0, 0.04, 0.09, 0.14, 0.2, 0.26, 0.32, 0.376, //
    0.38, 0.44, 0.5, 0.56, 0.64, 0.72, 0.79, 0.85, 0.9, 0.94, //
    0.97, 1.0, 1.03, 1.06, 1.1, 1.15, 1.21, 1.28, 1.36, 1.45, //
    1.55, 1.65, 1.75, 1.83, 1.84, 1.92, 1.98, 2.04, 2.1,
  ];
  static const List<double> _ssJambeLeger = [
    -0.075, -0.04, 0.0, 0.06, 0.14, 0.24, 0.32, 0.376, 0.38, 0.48, 0.6, //
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

  (_FormeMembre, _Grille) _jambe(
    Squelette3 s,
    Membre3 j,
    double cote,
    V3 talon,
  ) {
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
      f.pointCS,
      ss,
      cols,
      (s) =>
          _lisse(0.0, 0.22, s) *
          (1 - _cloche(s, _ourlet - 0.03, _ourlet + 0.02)),
      ombre: f.ombre,
    );
    for (var i = 0; i < ss.length - 1; i++) {
      if (ss[i + 1] <= _ourlet + 1e-6) {
        g.matiere.fillRange(i * cols, (i + 1) * cols, 1);
      } else if (ss[i] >= _soquette - 1e-6) {
        g.matiere.fillRange(i * cols, (i + 1) * cols, 2);
      }
    }
    return (f, g);
  }

  void _peindreJambe(_Grille g, int partie) {
    _emettre(g, const [_peau, _short, _chaussette], partie: partie);
    _fuseaux(g, _zonesJambe);
  }
}

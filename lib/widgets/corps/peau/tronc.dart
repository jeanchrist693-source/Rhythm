// lib/widgets/corps/peau/tronc.dart
//
// Le TRONC : un volume balayé le long du dos (bassin → cou, puis le cou d'un
// seul tenant jusque dans la tête), section un peu carrée (une superellipse,
// pas un tuyau), plus profonde devant (la poitrine) ou derrière (les
// fessiers) ; le short jusqu'à la taille. Ses reliefs : l'anatomie du tronc.

part of '../peau3.dart';

class _FormeTronc {
  _FormeTronc(this.s, this.reliefs, this.souffle) {
    final t1 = s.cou - s.dosControle;
    _t1 = t1.norme < 1e-6 ? s.dirTronc : t1.unite;
    _versTete = (s.tete - s.cou).unite;
  }

  final Squelette3 s;
  final List<_Bosse> reliefs;
  final double souffle;
  late final V3 _t1, _versTete;

  /// Le tronc : stations le long du dos (0 au bassin, 1 à la base du cou,
  /// puis le COU, d'un seul tenant avec le tronc, jusque dans la tête) —
  /// demi-largeur, profondeur devant, profondeur derrière.
  static const _Profil _stations = [
    // Le bassin porte les hanches (jusqu'aux trochanters), les fessiers et
    // le pli fessier : les cuisses naissent dedans, fines, et en sortent.
    (-0.28, 0.004, 0.004, 0.004),
    (-0.26, 0.024, 0.012, 0.022),
    (-0.22, 0.05, 0.02, 0.04),
    (-0.16, 0.072, 0.03, 0.052),
    (-0.08, 0.08, 0.04, 0.056),
    (0.02, 0.078, 0.046, 0.054),
    (0.12, 0.069, 0.047, 0.048),
    (0.28, 0.062, 0.047, 0.043),
    (0.48, 0.066, 0.053, 0.047),
    (0.68, 0.075, 0.061, 0.051),
    // La ceinture scapulaire : l'acromion, puis la pente CONCAVE du trapèze
    // (douce vers l'épaule, redressée contre le cou) — pas une pyramide.
    (0.8, 0.083, 0.058, 0.052),
    (0.87, 0.083, 0.053, 0.051),
    (0.91, 0.079, 0.049, 0.049),
    (0.94, 0.073, 0.045, 0.047),
    (0.96, 0.066, 0.041, 0.045),
    (0.98, 0.058, 0.037, 0.042),
    (1.0, 0.049, 0.033, 0.039),
    (1.02, 0.04, 0.029, 0.035),
    (1.04, 0.03, 0.024, 0.029),
    // Le haut du tronc s'arrête DANS la base du cou (un peu plus fin que
    // lui) : le cou appartient à la tête (`tete.dart`), qui s'y soude.
    (1.07, 0.02, 0.017, 0.02),
    (1.1, 0.01, 0.009, 0.01),
    (1.12, 0.003, 0.003, 0.003),
  ];

  static const double taille = 0.1;

  /// La ligne du dos : bassin → cou, puis tout droit (t > 1).
  V3 _ligne(double t) {
    if (t <= 1 && t >= 0) {
      final u = 1 - t;
      return s.bassin * (u * u) + s.dosControle * (2 * u * t) + s.cou * (t * t);
    }
    if (t < 0) return s.bassin + s.dirTronc * (t * lTronc);
    return s.cou + _t1 * ((t - 1) * lTronc);
  }

  /// Le centre de l'anneau [t] : la ligne du dos, écartée vers la tête
  /// autour de la base du cou par le PLI DU COU — le même que celui du cou
  /// de la tête (`_pliCou`) : les deux surfaces se suivent. Les anneaux,
  /// eux, restent tournés comme la ligne (`_anneauEn`) : le haut du tronc se
  /// CISAILLE sans tourner — ses anneaux, bien plus larges que le virage,
  /// se croiseraient.
  V3 _dos(double t) {
    final (psi, _) = _pliCou((t - 1) * lTronc);
    final c = _ligne(t);
    return psi == 0 ? c : c + (_versTete - _t1) * psi;
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
    final tan = (_ligne(t + 0.02) - _ligne(t - 0.02)).unite;
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

  V3 pointCS(double t, double phi, double cp, double sp, double plus) {
    final (c, lat, av, w, f, k) = _anneauEn(t);
    final ex = cp.sign * _carre(cp.abs()) * (cp >= 0 ? f : k);
    final ey = sp.sign * _carre(sp.abs()) * w;
    var h = plus;
    for (final b in _actifs) {
      h += b.en(t, phi);
    }
    if (t < taille - 1e-6) h += t > 0.066 ? 0.0045 : 0.003;
    final ox = av.x * ex + lat.x * ey;
    final oy = av.y * ex + lat.y * ey;
    final oz = av.z * ex + lat.z * ey;
    final n = math.sqrt(ox * ox + oy * oy + oz * oz);
    final g = n < 1e-9 ? 1.0 : 1 + h / n;
    return V3(c.x + ox * g, c.y + oy * g, c.z + oz * g);
  }
}

extension _Tronc on Peau3 {
  // Le tronc s'arrête sous la CEINTURE : plus bas, le bassin appartient aux
  // jambes (`membres.dart`, la demi-section de chaque côté), qui partent de
  // la taille ; il se referme dedans.
  static const List<double> _tsFin = [
    0.0,
    0.03,
    0.05,
    0.066,
    0.08,
    0.097,
    0.1,
    0.14,
    0.18,
    0.22,
    0.26,
    0.3,
    0.34,
    0.38,
    0.42, //
    0.46, 0.5, 0.54, 0.58, 0.62, 0.66, 0.7, 0.74, 0.78, 0.82, 0.86, //
    0.89, 0.92, 0.945, 0.965, 0.985, 1.005, 1.025, 1.045, 1.07, 1.1, 1.12,
  ];

  static const List<double> _tsLeger = [
    0.0, 0.04, 0.066, 0.097, 0.1, 0.2, 0.32, //
    0.44, 0.56, 0.66, 0.76, 0.85, 0.93, 1.0, 1.05, 1.09, 1.12,
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
    (Muscle.obliques, 0.14, 0.58, _amande(64, 20)),
    (Muscle.obliques, 0.14, 0.58, _amande(-64, 20)),
  ];

  /// La forme du tronc et sa grille (pas encore peinte).
  (_FormeTronc, _Grille) _tronc(Squelette3 s) {
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
        // Le PECTORAL : plein, son bord inférieur dessiné ; il s'étire et
        // remonte quand le bras monte.
        _Bosse(
          0.6 + 0.05 * m,
          0.93 + 0.03 * m,
          0.4 + 0.1 * m,
          27 * c,
          34,
          0.0085 * (1 - 0.35 * m),
          0.65,
        ),
        // Les obliques, les dentelés sous l'aisselle (trois digitations).
        _Bosse(0.14, 0.5, 0.5, 60 * c, 22, 0.0022),
        _Bosse(0.52, 0.6, 0.5, 66 * c, 10, 0.0012),
        _Bosse(0.58, 0.66, 0.5, 70 * c, 10, 0.0012),
        _Bosse(0.64, 0.72, 0.5, 74 * c, 10, 0.0011),
        // Le grand dorsal, les érecteurs du rachis.
        _Bosse(0.42, 0.86, 0.6, 118 * c, 36, 0.0045),
        _Bosse(0.05, 0.55, 0.4, 170 * c, 11, 0.0032, 0.4),
        // L'omoplate : son bord interne, l'épine.
        _Bosse(0.66, 0.9, 0.55, 146 * c, 24, 0.0032, 0.5),
        // La clavicule, et le creux au-dessus.
        _Bosse(0.93, 1.0, 0.5, 32 * c, 26, 0.0016),
        _Bosse(0.89, 0.96, 0.5, 62 * c, 20, 0.0014),
        _Bosse(0.97, 1.03, 0.5, 44 * c, 18, -0.0016),
        // Les grands droits : une colonne de chaque côté de la ligne
        // blanche, en trois étages.
        _Bosse(0.16, 0.3, 0.5, 8 * c, 9, 0.0024, 0.5),
        _Bosse(0.31, 0.42, 0.5, 8 * c, 9, 0.0024, 0.5),
        _Bosse(0.43, 0.54, 0.5, 8.5 * c, 9, 0.0022, 0.5),
        _Bosse(0.55, 0.62, 0.5, 9 * c, 9, 0.0016, 0.5),
        // Le FESSIER, plus rond hanche tendue.
        _Bosse(
          -0.25,
          0.1,
          0.42,
          150 * c,
          42,
          0.0042 + 0.002 * etend(j) - 0.0015 * flechit(j),
        ),
      ]);
    }
    reliefs.addAll(const [
      // La ligne blanche, le sternum, le nombril.
      _Bosse(0.15, 0.6, 0.5, 0, 4, -0.0016),
      _Bosse(0.62, 0.93, 0.5, 0, 7, -0.002),
      _Bosse(0.17, 0.23, 0.5, 0, 4, -0.0028),
      // La gouttière du dos, les trapèzes.
      _Bosse(0.1, 0.92, 0.5, 180, 9, -0.0028),
      _Bosse(0.8, 1.06, 0.5, 180, 95, 0.0025),
    ]);
    final f = _FormeTronc(s, reliefs, math.sin(2 * math.pi * respiration));
    final ts = fin ? _tsFin : _tsLeger;
    final cols = fin ? 36 : 16;
    // Le contour s'efface dans la tête, et à la ceinture (une couture).
    V3 point(double t, double phi, double cp, double sp, double plus) {
      final p = f.pointCS(t, phi, cp, sp, plus);
      if (t >= 0.066) return p;
      final c = f._dos(t);
      return c + (p - c) * (0.02 + 0.93 * _lisse(0.0, 0.066, t));
    }

    final g = _nappe(
      point,
      ts,
      cols,
      (t) => (1 - _lisse(1.0, 1.08, t)) * (1 - _cloche(t, 0.07, 0.13)),
    );
    for (var i = 0; i < ts.length - 1; i++) {
      final haut = ts[i + 1];
      if (haut <= _FormeTronc.taille + 1e-6) {
        g.matiere.fillRange(i * cols, (i + 1) * cols, haut > 0.066 ? 2 : 1);
      }
    }
    return (f, g);
  }

  void _peindreTronc(_Grille g) {
    _emettre(g, const [_peau, _short, _ceinture], partie: 0);
    _fuseaux(g, _zonesTronc);
  }
}

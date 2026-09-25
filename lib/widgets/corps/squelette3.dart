// lib/widgets/corps/squelette3.dart
//
// Le SQUELETTE du corps en 3D (l'utilisateur : « plus représentatif du
// corps humain, une représentation très fidèle de l'exercice ; parfois on ne
// voit pas les membres »). Les deux bras et les deux jambes existent
// vraiment : vus de trois quarts, aucun ne disparaît derrière l'autre.
//
// Une POSE (`Pose3`) se décrit comme avant, par la DIRECTION de chaque
// segment dans le plan sagittal (0 = avant, 90 = bas, −90 = haut, 180 =
// arrière), à laquelle s'ajoutent : l'ÉCART de chaque membre hors de ce plan
// (un bras écarté de 90 est à l'horizontale sur le côté), la TORSION des
// épaules, l'INCLINAISON latérale du tronc, le ROULIS de tout le corps
// (planche latérale), la tête qui tourne. Des CIBLES tiennent les mains et
// les pieds là où ils doivent être (mains au sol pendant une pompe, à la
// barre pendant une traction, pieds plantés pendant un squat) : le coude et
// le genou se plient d'eux-mêmes (cinématique inverse) — plus rien ne glisse.
//
// P = le côté proche (+z), L = le côté loin (−z).

import 'dart:math' as math;

import 'corps_humain.dart' show Ancre, kSol;
import 'geometrie3.dart';

export 'corps_humain.dart' show Ancre, kSol;

// ── Proportions (fraction du carré ; un adulte debout ≈ 0,83) ─────────────
const double lTronc = 0.245;
const double lCou = 0.03;
const double rTeteY = 0.052;
const double lBras = 0.145;
const double lAvantBras = 0.122;
const double lMain = 0.05;
const double lCuisse = 0.205;
const double lJambe = 0.2;
const double lPied = 0.085;
const double hCheville = 0.028;
const double demiEpaules = 0.083;

/// De combien l'articulation de l'épaule est sous la base du cou (le long
/// du tronc) : la clavicule descend un peu vers l'épaule.
const double baisseEpaule = 0.036;
const double demiHanches = 0.048;

/// Debout jambes tendues, pieds à plat : la hauteur de la hanche.
const double hDebout = 0.488;

/// La cheville d'un pied posé à plat sur le sol.
const double yCheville = kSol - 0.034;

/// Le centre d'une paume posée au sol.
const double yPaume = kSol - 0.013;

/// Là où une main ou un pied doit être (coordonnées du monde) ; sans [z],
/// à la profondeur naturelle du membre.
class Cible {
  const Cible(this.x, this.y, [this.z]);

  final double x, y;
  final double? z;

  static Cible lerp(Cible a, Cible b, double t) => Cible(
    a.x + (b.x - a.x) * t,
    a.y + (b.y - a.y) * t,
    (a.z == null || b.z == null)
        ? (t < 0.5 ? a.z : b.z)
        : a.z! + (b.z! - a.z!) * t,
  );
}

class Pose3 {
  const Pose3({
    this.x = 0.5,
    this.y = 0.47,
    this.ancre = Ancre.hanche,
    this.auSol = true,
    this.appui = kSol,
    this.saut = 0,
    this.dx = 0,
    this.dy = 0,
    this.dz = 0,
    this.tronc = -90,
    this.dos = 0,
    this.inclinaison = 0,
    this.torsion = 0,
    this.roulis = 0,
    this.tete,
    this.teteTourne = 0,
    this.haussement = 0,
    this.poignetP = 0,
    this.poignetL = 0,
    this.brasP = 90,
    this.ecartBrasP = 7,
    this.avantBrasP = 84,
    this.ecartAvantBrasP = 5,
    this.brasL = 90,
    this.ecartBrasL = 7,
    this.avantBrasL = 84,
    this.ecartAvantBrasL = 5,
    this.cuisseP = 90,
    this.ecartCuisseP = 3,
    this.jambeP = 90,
    this.ecartJambeP = 2,
    this.piedP = 0,
    this.cuisseL = 90,
    this.ecartCuisseL = 3,
    this.jambeL = 90,
    this.ecartJambeL = 2,
    this.piedL = 0,
    this.mainP,
    this.mainL,
    this.piedCibleP,
    this.piedCibleL,
    this.coudeP,
    this.coudeL,
    this.genouP,
    this.genouL,
  });

  // ── Placement ─────────────────────────────────────────────────────────────
  /// L'ancre ([ancre]) en ([x], [y]) ; si [auSol], [y] est calculé pour
  /// que le point le plus bas touche [appui], moins [saut].
  final double x, y;
  final Ancre ancre;
  final bool auSol;
  final double appui, saut;

  /// Décalage final ; [dz] : le corps glisse sur le côté (vers le proche).
  final double dx, dy, dz;

  // ── Tronc et tête ─────────────────────────────────────────────────────────
  final double tronc;

  /// Dos rond (> 0) ou creusé (< 0).
  final double dos;

  /// Le tronc penché sur le côté (> 0 : vers le côté proche).
  final double inclinaison;

  /// Les épaules tournées par rapport au bassin (> 0 : l'épaule proche
  /// avance).
  final double torsion;

  /// Tout le corps roule autour de son axe avant (planche latérale).
  final double roulis;

  /// La direction du cou à la tête ; `null` : naturelle (le regard reste
  /// devant quand on se penche).
  final double? tete;

  /// La tête tournée (> 0 : vers le côté proche).
  final double teteTourne;

  /// Les épaules haussées (0..1).
  final double haussement;

  /// La main pliée au poignet (> 0 : vers la paume).
  final double poignetP, poignetL;

  // ── Bras ──────────────────────────────────────────────────────────────────
  final double brasP, ecartBrasP, avantBrasP, ecartAvantBrasP;
  final double brasL, ecartBrasL, avantBrasL, ecartAvantBrasL;

  // ── Jambes ────────────────────────────────────────────────────────────────
  final double cuisseP, ecartCuisseP, jambeP, ecartJambeP, piedP;
  final double cuisseL, ecartCuisseL, jambeL, ecartJambeL, piedL;

  // ── Cibles (cinématique inverse) ──────────────────────────────────────────
  /// La paume de la main ; la cheville du pied.
  final Cible? mainP, mainL, piedCibleP, piedCibleL;

  /// Vers où plient le coude et le genou (sinon : coude en bas et dehors,
  /// genou devant).
  final V3? coudeP, coudeL, genouP, genouL;

  Pose3 copier({
    double? x,
    double? y,
    Ancre? ancre,
    bool? auSol,
    double? appui,
    double? saut,
    double? dx,
    double? dy,
    double? dz,
    double? tronc,
    double? dos,
    double? inclinaison,
    double? torsion,
    double? roulis,
    double? tete,
    double? teteTourne,
    double? haussement,
    double? poignetP,
    double? poignetL,
    double? brasP,
    double? ecartBrasP,
    double? avantBrasP,
    double? ecartAvantBrasP,
    double? brasL,
    double? ecartBrasL,
    double? avantBrasL,
    double? ecartAvantBrasL,
    double? cuisseP,
    double? ecartCuisseP,
    double? jambeP,
    double? ecartJambeP,
    double? piedP,
    double? cuisseL,
    double? ecartCuisseL,
    double? jambeL,
    double? ecartJambeL,
    double? piedL,
    Cible? mainP,
    Cible? mainL,
    Cible? piedCibleP,
    Cible? piedCibleL,
    V3? coudeP,
    V3? coudeL,
    V3? genouP,
    V3? genouL,
    bool sansCibles = false,
  }) => Pose3(
    x: x ?? this.x,
    y: y ?? this.y,
    ancre: ancre ?? this.ancre,
    auSol: auSol ?? this.auSol,
    appui: appui ?? this.appui,
    saut: saut ?? this.saut,
    dx: dx ?? this.dx,
    dy: dy ?? this.dy,
    dz: dz ?? this.dz,
    tronc: tronc ?? this.tronc,
    dos: dos ?? this.dos,
    inclinaison: inclinaison ?? this.inclinaison,
    torsion: torsion ?? this.torsion,
    roulis: roulis ?? this.roulis,
    tete: tete ?? this.tete,
    teteTourne: teteTourne ?? this.teteTourne,
    haussement: haussement ?? this.haussement,
    poignetP: poignetP ?? this.poignetP,
    poignetL: poignetL ?? this.poignetL,
    brasP: brasP ?? this.brasP,
    ecartBrasP: ecartBrasP ?? this.ecartBrasP,
    avantBrasP: avantBrasP ?? this.avantBrasP,
    ecartAvantBrasP: ecartAvantBrasP ?? this.ecartAvantBrasP,
    brasL: brasL ?? this.brasL,
    ecartBrasL: ecartBrasL ?? this.ecartBrasL,
    avantBrasL: avantBrasL ?? this.avantBrasL,
    ecartAvantBrasL: ecartAvantBrasL ?? this.ecartAvantBrasL,
    cuisseP: cuisseP ?? this.cuisseP,
    ecartCuisseP: ecartCuisseP ?? this.ecartCuisseP,
    jambeP: jambeP ?? this.jambeP,
    ecartJambeP: ecartJambeP ?? this.ecartJambeP,
    piedP: piedP ?? this.piedP,
    cuisseL: cuisseL ?? this.cuisseL,
    ecartCuisseL: ecartCuisseL ?? this.ecartCuisseL,
    jambeL: jambeL ?? this.jambeL,
    ecartJambeL: ecartJambeL ?? this.ecartJambeL,
    piedL: piedL ?? this.piedL,
    mainP: sansCibles ? null : (mainP ?? this.mainP),
    mainL: sansCibles ? null : (mainL ?? this.mainL),
    piedCibleP: sansCibles ? null : (piedCibleP ?? this.piedCibleP),
    piedCibleL: sansCibles ? null : (piedCibleL ?? this.piedCibleL),
    coudeP: coudeP ?? this.coudeP,
    coudeL: coudeL ?? this.coudeL,
    genouP: genouP ?? this.genouP,
    genouL: genouL ?? this.genouL,
  );

  /// Les deux bras pareils.
  Pose3 bras(double bras, double avantBras, {double? ecart}) => copier(
    brasP: bras,
    avantBrasP: avantBras,
    brasL: bras,
    avantBrasL: avantBras,
    ecartBrasP: ecart,
    ecartBrasL: ecart,
  );

  /// Les deux jambes pareilles.
  Pose3 jambes(double cuisse, double jambe, [double pied = 0]) => copier(
    cuisseP: cuisse,
    jambeP: jambe,
    piedP: pied,
    cuisseL: cuisse,
    jambeL: jambe,
    piedL: pied,
  );

  static Pose3 lerp(Pose3 a, Pose3 b, double t) {
    double l(double u, double v) => u + (v - u) * t;
    Cible? lc(Cible? u, Cible? v) =>
        (u == null || v == null) ? (t < 0.5 ? u : v) : Cible.lerp(u, v, t);
    V3? lv(V3? u, V3? v) =>
        (u == null || v == null) ? (t < 0.5 ? u : v) : V3.lerp(u, v, t);
    final ta = a.tete ?? Squelette3.teteNaturelle(a.tronc);
    final tb = b.tete ?? Squelette3.teteNaturelle(b.tronc);
    return Pose3(
      x: l(a.x, b.x),
      y: l(a.y, b.y),
      ancre: t < 0.5 ? a.ancre : b.ancre,
      auSol: t < 0.5 ? a.auSol : b.auSol,
      appui: l(a.appui, b.appui),
      saut: l(a.saut, b.saut),
      dx: l(a.dx, b.dx),
      dy: l(a.dy, b.dy),
      dz: l(a.dz, b.dz),
      tronc: l(a.tronc, b.tronc),
      dos: l(a.dos, b.dos),
      inclinaison: l(a.inclinaison, b.inclinaison),
      torsion: l(a.torsion, b.torsion),
      roulis: l(a.roulis, b.roulis),
      tete: (a.tete == null && b.tete == null) ? null : l(ta, tb),
      teteTourne: l(a.teteTourne, b.teteTourne),
      haussement: l(a.haussement, b.haussement),
      poignetP: l(a.poignetP, b.poignetP),
      poignetL: l(a.poignetL, b.poignetL),
      brasP: l(a.brasP, b.brasP),
      ecartBrasP: l(a.ecartBrasP, b.ecartBrasP),
      avantBrasP: l(a.avantBrasP, b.avantBrasP),
      ecartAvantBrasP: l(a.ecartAvantBrasP, b.ecartAvantBrasP),
      brasL: l(a.brasL, b.brasL),
      ecartBrasL: l(a.ecartBrasL, b.ecartBrasL),
      avantBrasL: l(a.avantBrasL, b.avantBrasL),
      ecartAvantBrasL: l(a.ecartAvantBrasL, b.ecartAvantBrasL),
      cuisseP: l(a.cuisseP, b.cuisseP),
      ecartCuisseP: l(a.ecartCuisseP, b.ecartCuisseP),
      jambeP: l(a.jambeP, b.jambeP),
      ecartJambeP: l(a.ecartJambeP, b.ecartJambeP),
      piedP: l(a.piedP, b.piedP),
      cuisseL: l(a.cuisseL, b.cuisseL),
      ecartCuisseL: l(a.ecartCuisseL, b.ecartCuisseL),
      jambeL: l(a.jambeL, b.jambeL),
      ecartJambeL: l(a.ecartJambeL, b.ecartJambeL),
      piedL: l(a.piedL, b.piedL),
      mainP: lc(a.mainP, b.mainP),
      mainL: lc(a.mainL, b.mainL),
      piedCibleP: lc(a.piedCibleP, b.piedCibleP),
      piedCibleL: lc(a.piedCibleL, b.piedCibleL),
      coudeP: lv(a.coudeP, b.coudeP),
      coudeL: lv(a.coudeL, b.coudeL),
      genouP: lv(a.genouP, b.genouP),
      genouL: lv(a.genouL, b.genouL),
    );
  }
}

/// Un membre calculé : ses articulations et son repère.
class Membre3 {
  Membre3(this.racine, this.milieu, this.bout, this.extremite);

  /// Épaule / hanche, coude / genou, poignet / cheville, main / orteils.
  V3 racine, milieu, bout, extremite;

  void deplacer(V3 d) {
    racine = racine + d;
    milieu = milieu + d;
    bout = bout + d;
    extremite = extremite + d;
  }

  void tourner(V3 pivot, V3 axe, double a) {
    racine = (racine - pivot).tourne(axe, a) + pivot;
    milieu = (milieu - pivot).tourne(axe, a) + pivot;
    bout = (bout - pivot).tourne(axe, a) + pivot;
    extremite = (extremite - pivot).tourne(axe, a) + pivot;
  }
}

/// Le squelette calculé d'une pose.
class Squelette3 {
  Squelette3._();

  late V3 bassin, cou, dosControle, tete;

  /// Le repère du tronc : direction du bassin vers le cou, côté (+z du
  /// corps), avant — au bassin et aux épaules (la torsion les sépare).
  late V3 dirTronc, lateralBassin, avantBassin, lateralEpaules, avantEpaules;

  /// Le repère de la tête : haut (du cou vers le crâne), avant (le visage).
  late V3 hautTete, avantTete;

  late Membre3 brasP, brasL, jambeP, jambeL;

  /// Le talon et les orteils de chaque pied ; l'avant du pied.
  late V3 talonP, talonL, avantPiedP, avantPiedL;

  /// Une main posée À PLAT au sol : la direction de ses doigts (sinon
  /// `null`) et ses jointures, sur le sol.
  V3? doigtsAuSolP, doigtsAuSolL, jointuresP, jointuresL;

  static double teteNaturelle(double tronc) {
    if (tronc > -165 && tronc < -15) return tronc - (tronc + 90) * 0.35;
    return tronc;
  }

  List<V3> get points => [
    bassin,
    cou,
    tete,
    dosControle,
    brasP.racine,
    brasP.milieu,
    brasP.bout,
    brasP.extremite,
    brasL.racine,
    brasL.milieu,
    brasL.bout,
    brasL.extremite,
    jambeP.racine,
    jambeP.milieu,
    jambeP.bout,
    jambeP.extremite,
    jambeL.racine,
    jambeL.milieu,
    jambeL.bout,
    jambeL.extremite,
    talonP,
    talonL,
  ];

  void _deplacer(V3 d) {
    bassin = bassin + d;
    cou = cou + d;
    dosControle = dosControle + d;
    tete = tete + d;
    for (final m in [brasP, brasL, jambeP, jambeL]) {
      m.deplacer(d);
    }
    talonP = talonP + d;
    talonL = talonL + d;
  }

  void _tourner(V3 pivot, V3 axe, double a) {
    V3 r(V3 p) => (p - pivot).tourne(axe, a) + pivot;
    bassin = r(bassin);
    cou = r(cou);
    dosControle = r(dosControle);
    tete = r(tete);
    talonP = r(talonP);
    talonL = r(talonL);
    for (final m in [brasP, brasL, jambeP, jambeL]) {
      m.tourner(pivot, axe, a);
    }
    dirTronc = dirTronc.tourne(axe, a);
    lateralBassin = lateralBassin.tourne(axe, a);
    avantBassin = avantBassin.tourne(axe, a);
    lateralEpaules = lateralEpaules.tourne(axe, a);
    avantEpaules = avantEpaules.tourne(axe, a);
    hautTete = hautTete.tourne(axe, a);
    avantTete = avantTete.tourne(axe, a);
    avantPiedP = avantPiedP.tourne(axe, a);
    avantPiedL = avantPiedL.tourne(axe, a);
  }

  /// La direction de la main, pliée de [flexion] degrés au poignet.
  V3 plierMain(V3 dAvant, double flexion, double cote) {
    if (flexion == 0) return dAvant;
    var axe = lateralEpaules.sansComposante(dAvant);
    if (axe.norme < 1e-3) axe = avantEpaules.sansComposante(dAvant);
    return dAvant.tourne(axe.unite, rad(flexion) * cote).unite;
  }

  /// Le point le plus bas du corps (sa surface), pour le poser au sol.
  double _plusBas() {
    var bas = -1e9;
    void v(V3 p, double r) => bas = math.max(bas, p.y + r);
    v(bassin + dirTronc * -0.02, 0.07);
    v(dosControle, 0.055);
    v(cou, 0.05);
    v(tete, rTeteY);
    for (final b in [brasP, brasL]) {
      v(b.racine, 0.035);
      v(b.milieu, 0.026);
      v(b.bout, 0.018);
      v(b.extremite, 0.016);
    }
    for (final j in [jambeP, jambeL]) {
      v(j.milieu, 0.03);
      v(j.bout, 0.022);
      v(j.extremite, 0.008);
    }
    v(talonP, 0.008);
    v(talonL, 0.008);
    return bas;
  }

  factory Squelette3.de(Pose3 p) {
    final s = Squelette3._();
    s._construire(p);
    // Tout le corps roule autour de son axe avant.
    if (p.roulis != 0) {
      s._tourner(s.bassin, V3.avant, rad(p.roulis));
    }
    // Le placement.
    final repere = switch (p.ancre) {
      Ancre.hanche => s.bassin,
      Ancre.pieds => s.jambeP.bout,
      Ancre.mains => s.brasP.extremite,
    };
    final bas = switch (p.ancre) {
      Ancre.hanche => s._plusBas(),
      Ancre.pieds => math.max(s.talonP.y + 0.006, s.jambeP.extremite.y + 0.006),
      Ancre.mains => s.brasP.extremite.y + 0.016,
    };
    final dx = p.x - repere.x;
    final dy = p.auSol ? p.appui - bas - p.saut : p.y - repere.y;
    s._deplacer(V3(dx + p.dx, dy + p.dy, p.dz));
    // Les membres tenus par une cible, maintenant que le corps est placé.
    s._cibles(p);
    return s;
  }

  void _construire(Pose3 p) {
    bassin = V3.zero;
    final sag = direction(p.tronc, 0, 1);
    final i = rad(p.inclinaison);
    dirTronc = (sag * math.cos(i) + V3.proche * math.sin(i)).unite;
    var lat = V3.proche.sansComposante(dirTronc);
    if (lat.norme < 1e-3) lat = V3.avant.sansComposante(dirTronc);
    lateralBassin = lat.unite;
    avantBassin = lateralBassin.cross(dirTronc).unite;
    lateralEpaules = lateralBassin.tourne(dirTronc, -rad(p.torsion)).unite;
    avantEpaules = lateralEpaules.cross(dirTronc).unite;

    cou = bassin + dirTronc * lTronc;
    dosControle = V3.lerp(bassin, cou, 0.5) - avantBassin * (p.dos / 90 * 0.06);

    // La tête.
    final th = p.tete ?? teteNaturelle(p.tronc);
    var dirTete = direction(th, 0, 1);
    dirTete =
        (dirTete * math.cos(i * 0.6) + V3.proche * math.sin(i * 0.6)).unite;
    hautTete = dirTete;
    avantTete = avantEpaules
        .tourne(dirTete, -rad(p.teteTourne))
        .sansComposante(dirTete)
        .unite;
    if (avantTete.norme < 0.5) avantTete = avantBassin;
    tete = cou + dirTete * (lCou + rTeteY * 0.9);

    // Les épaules et les bras.
    _haussement = p.haussement;
    V3 dirBras(double th, double ec, double cote) => direction(th, ec, cote);
    Membre3 bras(
      double cote,
      double b,
      double eb,
      double ab,
      double eab,
      double flexion,
    ) {
      final racine = _epaule(cote, dirBras(b, eb, cote));
      final coude = racine + dirBras(b, eb, cote) * lBras;
      final dAvant = dirBras(ab, eab, cote);
      final poignet = coude + dAvant * lAvantBras;
      return Membre3(
        racine,
        coude,
        poignet,
        poignet + plierMain(dAvant, flexion, cote) * (lMain * 0.55),
      );
    }

    brasP = bras(
      1,
      p.brasP,
      p.ecartBrasP,
      p.avantBrasP,
      p.ecartAvantBrasP,
      p.poignetP,
    );
    brasL = bras(
      -1,
      p.brasL,
      p.ecartBrasL,
      p.avantBrasL,
      p.ecartAvantBrasL,
      p.poignetL,
    );

    // Les hanches et les jambes.
    Membre3 jambe(
      double cote,
      double c,
      double ec,
      double j,
      double ej,
      double pied,
      void Function(V3 talon, V3 avant) pose,
    ) {
      final racine = bassin + lateralBassin * (demiHanches * cote);
      final genou = racine + direction(c, ec, cote) * lCuisse;
      final dJambe = direction(j, ej, cote);
      final cheville = genou + dJambe * lJambe;
      final dPied = direction(pied, 7 + ec * 0.3, cote);
      final orteils = cheville + dPied * lPied + dJambe * (hCheville * 0.6);
      final talon = cheville - dPied * 0.022 + dJambe * hCheville;
      pose(talon, dPied);
      return Membre3(racine, genou, cheville, orteils);
    }

    jambeP = jambe(
      1,
      p.cuisseP,
      p.ecartCuisseP,
      p.jambeP,
      p.ecartJambeP,
      p.piedP,
      (t, a) {
        talonP = t;
        avantPiedP = a;
      },
    );
    jambeL = jambe(
      -1,
      p.cuisseL,
      p.ecartCuisseL,
      p.jambeL,
      p.ecartJambeL,
      p.piedL,
      (t, a) {
        talonL = t;
        avantPiedL = a;
      },
    );
  }

  /// Le haussement d'épaules demandé par la pose.
  double _haussement = 0;

  /// L'ÉPAULE et son RYTHME : l'omoplate suit le bras — haussée quand il
  /// monte au-dessus de l'horizontale, avancée quand il pousse devant,
  /// reculée quand il tire derrière. L'épaule d'un bras dans la direction
  /// [dir] (calculée depuis le cou : elle suit le placement du corps).
  V3 _epaule(double cote, V3 dir) {
    final elev = math.acos(dir.dot(-dirTronc).clamp(-1.0, 1.0)) * 180 / math.pi;
    final t = ((elev - 75) / 95).clamp(0.0, 1.0);
    final h = math.max(
      _haussement,
      math.min(1.0, _haussement + 0.6 * t * t * (3 - 2 * t)),
    );
    final avant = dir.dot(avantEpaules);
    return cou -
        dirTronc * (baisseEpaule - 0.024 * h) +
        lateralEpaules * (demiEpaules * cote) +
        avantEpaules * (avant > 0 ? 0.007 * avant : 0.005 * avant);
  }

  /// La cinématique inverse : les membres qui ont une cible.
  void _cibles(Pose3 p) {
    void bras(Membre3 m, Cible? c, double cote, V3? pole, bool proche) {
      if (c == null) return;
      final cible = V3(c.x, c.y, c.z ?? m.racine.z);
      // L'épaule suit le bras qui va vers sa cible.
      m.racine = _epaule(cote, (cible - _epaule(cote, V3.zero)).unite);
      if (c.y >= yPaume - 0.006) {
        _mainAPlat(m, cible, cote, pole, proche);
        return;
      }
      final (coude, main) = deuxSegments(
        m.racine,
        cible,
        lBras,
        lAvantBras + lMain * 0.55,
        pole ?? V3(-0.25, 1, 0.7 * cote),
      );
      m.milieu = coude;
      m.extremite = main;
      m.bout = coude + (main - coude).unite * lAvantBras;
    }

    void jambe(Membre3 m, Cible? c, double cote, V3? pole, bool proche) {
      if (c == null) return;
      final cible = V3(c.x, c.y, c.z ?? m.racine.z);
      final (genou, cheville) = deuxSegments(
        m.racine,
        cible,
        lCuisse,
        lJambe,
        pole ?? V3(1, 0, 0.18 * cote),
      );
      final dJambe = (cheville - genou).unite;
      final dPied = proche ? avantPiedP : avantPiedL;
      m.milieu = genou;
      m.bout = cheville;
      m.extremite = cheville + dPied * lPied + dJambe * (hCheville * 0.6);
      final talon = cheville - dPied * 0.022 + dJambe * hCheville;
      if (proche) {
        talonP = talon;
      } else {
        talonL = talon;
      }
    }

    bras(brasP, p.mainP, 1, p.coudeP, true);
    bras(brasL, p.mainL, -1, p.coudeL, false);
    jambe(jambeP, p.piedCibleP, 1, p.genouP, true);
    jambe(jambeL, p.piedCibleL, -1, p.genouL, false);
  }

  /// La main posée À PLAT au sol (pompes, planches, appuis) : la paume sur
  /// le sol, les doigts vers l'avant du corps (vers la tête quand on est
  /// face au sol, vers les pieds quand on lui tourne le dos), un peu ouverts
  /// vers le dehors ; la cinématique vise le POIGNET, au-dessus du talon de
  /// la main (hors de portée, le talon se soulève : la main bascule sur ses
  /// doigts).
  void _mainAPlat(Membre3 m, V3 paume, double cote, V3? pole, bool proche) {
    V3 horizontal(V3 v) => V3(v.x, 0, v.z);
    var f = horizontal(dirTronc) * (avantEpaules.y >= 0 ? 1.0 : -1.0);
    if (f.norme < 0.35) f = f + horizontal(avantEpaules) * 0.8;
    if (f.norme < 1e-3) f = V3.avant;
    f = f.unite;
    // Un peu ouverte vers le dehors.
    final dehors = horizontal(lateralEpaules * cote);
    if (dehors.norme > 1e-3) f = (f + dehors.unite * 0.18).unite;
    final centre = V3(paume.x, kSol - 0.0068, paume.z);
    final poignet = centre - f * 0.02 + V3.haut * 0.005;
    final (coude, bout) = deuxSegments(
      m.racine,
      poignet,
      lBras,
      lAvantBras + 0.008,
      pole ?? V3(-0.25, 1, 0.7 * cote),
    );
    m.milieu = coude;
    m.bout = coude + (bout - coude).unite * lAvantBras;
    m.extremite = centre;
    final jointures = centre + f * 0.022 + V3.bas * 0.0015;
    if (proche) {
      doigtsAuSolP = f;
      jointuresP = jointures;
    } else {
      doigtsAuSolL = f;
      jointuresL = jointures;
    }
  }
}

// lib/widgets/corps/mouvements/outils.dart
//
// Les outils pour écrire les mouvements avec fidélité :
// - [_pose] : debout, la HANCHE placée à la main, les pieds PLANTÉS par des
//   cibles (ils ne glissent plus, les genoux se plient d'eux-mêmes) ;
// - [_pieds], [_mains] : planter les pieds et les mains ;
// - [_serie] : un aller-retour avec le TEMPO d'une vraie répétition (une
//   phase lente et contrôlée, l'autre plus vive, des temps marqués) ;
// - [_suite] : une suite de clés qui boucle.

part of '../animations_corps.dart';

/// Debout, jambes tendues, pieds plantés sous les hanches en x = 0,47 ;
/// bras le long du corps. La hanche est placée ([x], [y]), pas posée.
const Pose3 _pose = Pose3(
  ancre: Ancre.hanche,
  auSol: false,
  x: 0.47,
  y: hDebout,
  piedCibleP: Cible(0.47, yCheville),
  piedCibleL: Cible(0.47, yCheville),
);

/// Les pieds plantés : en x ([xL] pour le pied loin), à [z] du milieu
/// (écartement ; sinon sous les hanches), levés de [hP] / [hL].
Pose3 _pieds(
  Pose3 p,
  double x, {
  double? xL,
  double? z,
  double? zL,
  double hP = 0,
  double hL = 0,
}) => p.copier(
  piedCibleP: Cible(x, yCheville - hP, z),
  piedCibleL: Cible(xL ?? x, yCheville - hL, zL ?? (z == null ? null : -z)),
);

/// Les mains posées (au sol par défaut), écartées de [z].
// ignore: unused_element
Pose3 _mains(Pose3 p, double x, {double y = yPaume, double? z, double? xL}) =>
    p.copier(
      mainP: Cible(x, y, z),
      mainL: Cible(xL ?? x, y, z == null ? null : -z),
    );

/// Une répétition : de [a] à [b] en [ab] secondes, de [b] à [a] en [ba],
/// avec un temps marqué à chaque bout.
AnimCorps _serie(
  Pose3 a,
  Pose3 b, {
  double ab = 1.2,
  double ba = 1.2,
  double tenueA = 0.35,
  double tenueB = 0.2,
  Courbe courbeAB = Courbe.controlee,
  Courbe courbeBA = Courbe.controlee,
  Camera3 camera = Camera3.profil,
  Accessoires accessoires = const Accessoires(),
}) => AnimCorps(
  [
    Cle(a, duree: ba, courbe: courbeBA, tenue: tenueA),
    Cle(b, duree: ab, courbe: courbeAB, tenue: tenueB),
  ],
  camera: camera,
  accessoires: accessoires,
);

/// Une suite de clés qui boucle (la dernière revient à la première avec la
/// durée de la première).
AnimCorps _suite(
  List<Cle> cles, {
  Camera3 camera = Camera3.profil,
  Accessoires accessoires = const Accessoires(),
}) => AnimCorps(cles, camera: camera, accessoires: accessoires);

/// Le centre de la tête de [p] (hanche placée, sans roulis ni inclinaison).
(double, double) _centreTete(Pose3 p) {
  final t = rad(p.tronc);
  final th = rad(p.tete ?? Squelette3.teteNaturelle(p.tronc));
  const cou = lCou + rTeteY * 0.9;
  return (
    p.x + math.cos(t) * lTronc + math.cos(th) * cou,
    p.y + math.sin(t) * lTronc + math.sin(th) * cou,
  );
}

/// Les mains croisées derrière la tête (sur la nuque), coudes ouverts.
Pose3 _mainsNuque(Pose3 p, {double ouverture = 1}) {
  final (x, y) = _centreTete(p);
  final arriere = rad(p.tronc - 90);
  final m = Cible(x + math.cos(arriere) * 0.056, y + math.sin(arriere) * 0.056);
  return p.copier(
    mainP: Cible(m.x, m.y, 0.028),
    mainL: Cible(m.x, m.y, -0.028),
    coudeP: V3(0.35 - ouverture * 0.3, -0.2, 1),
    coudeL: V3(0.35 - ouverture * 0.3, -0.2, -1),
  );
}

/// La direction (en degrés) de [a] vers [b], dans le plan sagittal.
double _angle(double ax, double ay, double bx, double by) =>
    math.atan2(by - ay, bx - ax) * 180 / math.pi;

/// Une ALLURE sur place (marche, course, montées de genoux…) : le sol défile
/// sous le corps. Chaque pied, pendant l'[appui] (part du cycle), recule à
/// vitesse constante de [pas] devant la hanche à [pas] derrière, talon qui
/// attaque et pointe qui pousse ; puis il repasse en l'air, levé de
/// [lever] (et le genou monté de [genou], ou le talon ramené de [talon]).
/// Le bassin descend en double appui (marche) ou à mi-appui (course,
/// [course]) ; les bras balancent à l'opposé des jambes, coudes pliés de
/// [coude]. [n] clés calculées par cycle de [duree] secondes (deux pas).
AnimCorps _allure({
  required double duree,
  double pas = 0.12,
  double appui = 0.6,
  double lever = 0.045,
  double genou = 0,
  double talon = 0,
  bool course = false,
  double x = 0.47,
  double yHanche = hDebout,
  double rebond = 0.005,
  double tronc = -87,
  double bras = 22,
  double coude = 16,
  double zPieds = 0.055,
  Pose3 Function(Pose3 p, double u)? retouche,
  Camera3 camera = Camera3.profil,
  Accessoires accessoires = const Accessoires(),
  int n = 16,
}) {
  (double, double, double) pied(double u) {
    u %= 1;
    if (u < appui) {
      final v = u / appui;
      // L'attaque du talon, le pied à plat, puis la pointe qui pousse.
      final angle = v < 0.15
          ? -12 + 12 * v / 0.15
          : v > 0.7
          ? 38 * (v - 0.7) / 0.3
          : 0.0;
      final h = angle > 0 ? 0.085 * math.sin(rad(angle)) * 0.9 : 0.0;
      return (x + pas - 2 * pas * v, h, angle);
    }
    final v = (u - appui) / (1 - appui);
    final avance = 0.5 - 0.5 * math.cos(math.pi * v);
    // Le pied monte surtout au début (le talon se lève derrière), frôle le
    // sol en passant sous la hanche, puis la jambe se tend pour attaquer.
    final h =
        lever * math.sin(math.pi * math.pow(v, 0.6)) +
        genou * math.pow(math.sin(math.pi * math.min(1, v * 1.25)), 2) +
        talon * math.pow(math.sin(math.pi * math.min(1, v * 1.6)), 2);
    final angle = 38 * (1 - v) - 14 * v + talon * 300 * math.sin(math.pi * v);
    return (
      x -
          pas +
          2 * pas * avance +
          genou * 0.6 * math.sin(math.pi * v) -
          talon * 0.55 * math.sin(math.pi * v),
      h,
      angle,
    );
  }

  Pose3 a(double u) {
    final (xp, hp, ap) = pied(u);
    final (xl, hl, al) = pied(u + 0.5);
    // Le bassin au plus bas : au double appui (marche), à mi-appui
    // (course, où il amortit).
    final y = course
        ? yHanche + rebond * math.cos(4 * math.pi * (u - appui / 2))
        : yHanche + rebond * math.cos(4 * math.pi * (u - (appui - 0.5) / 2));
    final b = math.cos(2 * math.pi * u);
    var p = _pose.copier(
      x: x,
      y: y,
      tronc: tronc,
      torsion: -5 * b,
      piedCibleP: Cible(xp, yCheville - hp, zPieds),
      piedCibleL: Cible(xl, yCheville - hl, -zPieds),
      piedP: ap,
      piedL: al,
      brasP: 90 + bras * b,
      brasL: 90 - bras * b,
      avantBrasP: 90 + bras * 1.3 * b - coude - (course ? 0 : 6 * (1 - b)),
      avantBrasL: 90 - bras * 1.3 * b - coude - (course ? 0 : 6 * (1 + b)),
      ecartBrasP: 8,
      ecartBrasL: 8,
      ecartAvantBrasP: course ? -6 : 4,
      ecartAvantBrasL: course ? -6 : 4,
    );
    if (retouche != null) p = retouche(p, u);
    return p;
  }

  return AnimCorps(
    [
      for (var i = 0; i < n; i++)
        Cle(a(i / n), duree: duree / n, courbe: Courbe.reguliere),
    ],
    camera: camera,
    accessoires: accessoires,
  );
}

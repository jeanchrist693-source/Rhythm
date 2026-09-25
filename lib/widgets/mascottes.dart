// lib/widgets/mascottes.dart
//
// Les quatre mascottes, en haut à droite de chaque écran de domaine : le
// COUREUR (Sports), le GOURMAND (Alimentation), l'ENTHOUSIASTE (Habitudes)
// et le LECTEUR (Biblique). Leurs FORMES sont celles de la maquette (vue SVG
// de 150 × 120, affichée en 112 × 90). Leur MOUVEMENT a été refait le
// 24 septembre 2026 — l'utilisateur jugeait celui de la maquette « niveau
// débutant, aucune naturalité » (des bâtons qui pivotent comme des aiguilles,
// des rebonds en sinus pur, des boucles qui sautent) — selon les principes
// de l'animation :
//
// - ÉCRASEMENT et ÉTIREMENT : le corps s'écrase au choc et s'étire en l'air,
//   volume conservé (largeur × hauteur constante) ;
// - ANTICIPATION : on s'accroupit avant de sauter, la bouche s'ouvre avant la
//   cuillère, la main pince la page avant de la tourner ;
// - TRAÎNE et CHEVAUCHEMENT : bras, rubans, feuilles suivent le corps avec
//   un temps de retard, puis s'amortissent ;
// - ARCS et ralentis : les poses clés sont reliées par des splines (vitesse
//   continue), jamais en ligne droite à vitesse constante ;
// - membres « tuyau souple » : comprimée, une jambe PLIE au genou ; les pieds
//   du coureur restent posés sur un sol qui défile à leur vitesse — ils ne
//   glissent pas ;
// - actions secondaires à des rythmes INCOMMENSURABLES (clignements
//   irréguliers et parfois doubles, respiration, balancements, vapeur) :
//   rien ne boucle de façon mécanique.
//
// Temps : une horloge par mascotte. Onglet caché, `TickerMode` la met en
// sourdine SANS la remettre à zéro : au retour, le personnage est là où il
// en serait — le mouvement est continu. (Il repartait de zéro à cause d'une
// coquille qui recréait ses onglets à chaque bascule : corrigé et testé.)

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/rhythm_couleurs.dart';
import 'chemin_svg.dart';

enum Mascotte { sports, alimentation, habitudes, biblique }

class MascotteAnimee extends StatefulWidget {
  const MascotteAnimee(this.mascotte, {super.key});

  final Mascotte mascotte;

  /// Taille d'affichage de la maquette.
  static const Size taille = Size(112, 90);

  @override
  State<MascotteAnimee> createState() => _MascotteAnimeeState();
}

class _MascotteAnimeeState extends State<MascotteAnimee>
    with SingleTickerProviderStateMixin {
  /// Secondes écoulées depuis la naissance de la mascotte.
  final ValueNotifier<double> _horloge = ValueNotifier(0);
  late final Ticker _ticker = createTicker(
    (ecoule) => _horloge.value = ecoule.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final figee = MediaQuery.disableAnimationsOf(context);
    if (figee && _ticker.isActive) _ticker.stop();
    if (!figee && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _horloge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: MascotteAnimee.taille,
      painter: _PeintreMascotte(widget.mascotte, _horloge),
    ),
  );
}

class _PeintreMascotte extends CustomPainter {
  _PeintreMascotte(this.mascotte, this.horloge) : super(repaint: horloge);

  final Mascotte mascotte;
  final ValueNotifier<double> horloge;

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0 0 150 120, `xMidYMid meet`, contenu rogné à la vue.
    final e = math.min(size.width / 150, size.height / 120);
    canvas.translate((size.width - 150 * e) / 2, (size.height - 120 * e) / 2);
    canvas.scale(e);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 150, 120));
    final t = horloge.value;
    switch (mascotte) {
      case Mascotte.sports:
        _coureur(canvas, t);
      case Mascotte.alimentation:
        _gourmand(canvas, t);
      case Mascotte.habitudes:
        _enthousiaste(canvas, t);
      case Mascotte.biblique:
        _lecteur(canvas, t);
    }
  }

  @override
  bool shouldRepaint(_PeintreMascotte ancien) =>
      ancien.mascotte != mascotte || ancien.horloge != horloge;
}

// ═══ La boîte à outils de l'animateur ═══════════════════════════════════════

double _frac(double x) => x - x.floorToDouble();

/// Pseudo-hasard déterministe dans [0, 1) (même graine, même valeur).
double _hasard(double x) => _frac(math.sin(x * 12.9898 + 4.1414) * 43758.5453);

double _lisse(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// 0 → 1 sur [a, b].
double _fenetre(double u, double a, double b) =>
    ((u - a) / (b - a)).clamp(0.0, 1.0);

/// 0 → 1 → 0 sur [a, b] (demi-sinus).
double _cloche(double u, double a, double b) =>
    math.sin(math.pi * _fenetre(u, a, b));

/// Bruit lisse dans [−1, 1] : trois sinus de fréquences incommensurables —
/// une dérive vivante qui ne se répète jamais à l'identique.
double _bruit(double t, double graine) =>
    (math.sin(t * 0.93 + graine) +
        0.6 * math.sin(t * 1.71 + 2.1 * graine) +
        0.3 * math.sin(t * 2.93 + 4.7 * graine)) /
    1.9;

/// Oscillation amortie, [tau] secondes après un choc (0 avant).
double _amorti(double tau, double frequence, double amortissement) => tau < 0
    ? 0
    : math.exp(-amortissement * tau) * math.sin(2 * math.pi * frequence * tau);

/// Poses clés sur un cycle [0, 1) — (instant, valeur) triés — reliées par
/// une spline cubique (Hermite, tangentes de Catmull-Rom) : la vitesse est
/// continue, les mouvements ralentissent d'eux-mêmes aux extrémités. [saut] :
/// ce que gagne la valeur à chaque tour (360 pour un angle qui tourne).
double _piste(List<(double, double)> cles, double u, {double saut = 0}) {
  final n = cles.length;
  (double, double) cle(int k) {
    final tour = (k / n).floor();
    final (uk, vk) = cles[k - tour * n];
    return (uk + tour, vk + saut * tour);
  }

  var i = -1;
  for (var k = 0; k < n; k++) {
    if (cles[k].$1 > u) break;
    i = k;
  }
  final (u0, v0) = cle(i - 1);
  final (u1, v1) = cle(i);
  final (u2, v2) = cle(i + 1);
  final (u3, v3) = cle(i + 2);
  final h = u2 - u1;
  final s = h <= 0 ? 0.0 : (u - u1) / h;
  final m1 = (v2 - v0) / (u2 - u0) * h;
  final m2 = (v3 - v1) / (u3 - u1) * h;
  final s2 = s * s, s3 = s2 * s;
  return (2 * s3 - 3 * s2 + 1) * v1 +
      (s3 - 2 * s2 + s) * m1 +
      (-2 * s3 + 3 * s2) * v2 +
      (s3 - s2) * m2;
}

/// [_piste] pour des positions.
Offset _pisteO(List<(double, Offset)> cles, double u) => Offset(
  _piste([for (final (k, o) in cles) (k, o.dx)], u),
  _piste([for (final (k, o) in cles) (k, o.dy)], u),
);

/// Fermeture des paupières (0 ouvertes → 1 fermées). Clignements à
/// intervalles irréguliers (2,2 à 5,6 s), un sur quatre doublé ; un
/// clignement se ferme vite (70 ms) et se rouvre plus lentement (150 ms).
double _paupieres(double t, double graine) {
  const n = 9;
  var periode = 0.0;
  final debuts = <double>[];
  for (var k = 0; k < n; k++) {
    debuts.add(periode);
    periode += 2.2 + 3.4 * _hasard(k + graine * 17);
  }
  final u = t % periode;
  double un(double d) {
    if (d < 0 || d > 0.26) return 0;
    if (d < 0.07) return Curves.easeIn.transform(d / 0.07);
    if (d < 0.11) return 1;
    return 1 - Curves.easeOut.transform((d - 0.11) / 0.15);
  }

  var fermeture = 0.0;
  for (var k = 0; k < n; k++) {
    final d = u - debuts[k];
    fermeture = math.max(fermeture, un(d));
    if (_hasard(k * 3.7 + graine) < 0.25) {
      fermeture = math.max(fermeture, un(d - 0.24));
    }
  }
  return fermeture;
}

/// Une pose du corps : écrasement (autour de [base]), rotation (autour de
/// [pivot]), puis rebond vertical [dy] — monde = T · R · S · local.
class _Pose {
  const _Pose({
    this.dy = 0,
    this.angle = 0,
    this.pivot = Offset.zero,
    this.sx = 1,
    this.sy = 1,
    this.base = Offset.zero,
  });

  final double dy;

  /// Radians, sens horaire.
  final double angle;
  final Offset pivot;
  final double sx;
  final double sy;
  final Offset base;

  Offset appliquer(Offset p) {
    final q = Offset(
      base.dx + (p.dx - base.dx) * sx,
      base.dy + (p.dy - base.dy) * sy,
    );
    final c = math.cos(angle), s = math.sin(angle);
    final r = q - pivot;
    return pivot +
        Offset(r.dx * c - r.dy * s, r.dx * s + r.dy * c) +
        Offset(0, dy);
  }

  void surCanvas(Canvas c) {
    c.translate(0, dy);
    c.translate(pivot.dx, pivot.dy);
    c.rotate(angle);
    c.translate(-pivot.dx, -pivot.dy);
    c.translate(base.dx, base.dy);
    c.scale(sx, sy);
    c.translate(-base.dx, -base.dy);
  }
}

/// Un membre « tuyau souple » de [a] à [b] : droit s'il est tendu, plié
/// (genou, coude) s'il est comprimé — la courbe garde à peu près sa
/// [longueur]. [cote] (+1 / −1) : de quel côté il plie ; [pliMin] : flèche
/// minimale (un coude toujours un peu plié).
void _membre(
  Canvas c,
  Offset a,
  Offset b,
  double longueur,
  double cote,
  Paint p, {
  double pliMin = 0,
}) {
  final corde = b - a;
  final d = corde.distance;
  if (d < 0.001) return;
  final fleche = d < longueur ? math.sqrt(3 * d * (longueur - d) / 8) : 0.0;
  final normale = Offset(-corde.dy, corde.dx) / d;
  final controle =
      (a + b) / 2 + normale * (2 * math.max(fleche, pliMin) * cote);
  c.drawPath(
    Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(controle.dx, controle.dy, b.dx, b.dy),
    p,
  );
}

/// L'articulation (genou, coude) d'un membre à deux segments de [a] vers
/// [b] — cinématique inverse à deux os ([l1], [l2]) ; [cote] (+1 / −1) : de
/// quel côté elle plie.
Offset _articulation(Offset a, Offset b, double l1, double l2, double cote) {
  final corde = b - a;
  final d0 = corde.distance;
  if (d0 < 0.001) return a;
  final dir = corde / d0;
  final d = d0.clamp((l1 - l2).abs() + 0.01, l1 + l2 - 0.01);
  final cosA = ((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(-1.0, 1.0);
  final sinA = math.sqrt(1 - cosA * cosA) * cote;
  return a +
      Offset(dir.dx * cosA - dir.dy * sinA, dir.dx * sinA + dir.dy * cosA) * l1;
}

/// Trace un membre de [a] à [b] en passant par son articulation [j] : une
/// courbe douce, pas un angle vif — un genou, un coude de dessin animé.
void _courbeArticulee(Canvas c, Offset a, Offset j, Offset b, Paint p) {
  final controle = j * 2 - (a + b) / 2;
  c.drawPath(
    Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(controle.dx, controle.dy, b.dx, b.dy),
    p,
  );
}

/// Un membre à deux segments de [a] vers [b] (le pied, la main) ; trop
/// court pour l'atteindre, il se tend vers lui.
void _membre2(
  Canvas c,
  Offset a,
  Offset b,
  double l1,
  double l2,
  double cote,
  Paint p,
) {
  final corde = b - a;
  final d = corde.distance;
  final bout = d > l1 + l2 ? a + corde / d * (l1 + l2) : b;
  _courbeArticulee(c, a, _articulation(a, bout, l1, l2, cote), bout, p);
}

Paint _trait(Color couleur, double epaisseur) => Paint()
  ..color = couleur
  ..style = PaintingStyle.stroke
  ..strokeWidth = epaisseur
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _plein(Color couleur) => Paint()..color = couleur;

Color _alpha(Color couleur, double opacite) =>
    couleur.withValues(alpha: couleur.a * opacite.clamp(0.0, 1.0));

void _ligne(Canvas c, double x1, double y1, double x2, double y2, Paint p) =>
    c.drawLine(Offset(x1, y1), Offset(x2, y2), p);

void _ellipse(Canvas c, double cx, double cy, double rx, double ry, Paint p) =>
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 2 * rx, height: 2 * ry),
      p,
    );

const Color _blanc = RhythmCouleurs.texte;
const Color _noir = RhythmCouleurs.noir;

/// Deux yeux-points : ils se ferment ([fermeture]) et, dans la joie, se
/// plissent en arcs « ^ ^ » ([joie]). [regard] : où ils regardent. Ouvert,
/// l'œil est un point qui s'écrase en se fermant ; fermé, un TRAIT PLEIN —
/// un peu tombant (paupière close), qui s'arque en « ^ » avec la joie.
/// Jamais de fondu entre les deux : il laissait des taches grises.
/// [largeurs] : la largeur de chaque œil (1 = rond) — en trois quarts,
/// l'œil du fond est plus étroit.
void _yeux(
  Canvas c,
  List<Offset> centres, {
  double fermeture = 0,
  double joie = 0,
  Offset regard = Offset.zero,
  List<double>? largeurs,
}) {
  final ouverture = (1 - fermeture) * (1 - joie);
  for (var i = 0; i < centres.length; i++) {
    final o = centres[i] + regard;
    final l = largeurs?[i] ?? 1.0;
    if (ouverture > 0.22) {
      c.save();
      c.translate(o.dx, o.dy);
      c.scale(l, ouverture);
      c.drawCircle(Offset.zero, 2.8, _plein(_noir));
      c.restore();
    } else {
      final bout = 0.2 + 1.0 * joie;
      final milieu = 1.0 - 3.8 * joie;
      c.drawPath(
        Path()
          ..moveTo(o.dx - 3 * l, o.dy + bout)
          ..quadraticBezierTo(o.dx, o.dy + milieu, o.dx + 3 * l, o.dy + bout),
        _trait(_noir, 2.1),
      );
    }
  }
}

// ═══ Le coureur (Sports) ════════════════════════════════════════════════════
//
// Un vrai cycle de course : deux pas par foulée (0,56 s), chacun fait d'un
// APPUI (72 % du pas) et d'une SUSPENSION. En appui, le corps descend puis
// remonte — l'amorti de la jambe — et s'ÉCRASE ; en suspension il monte un
// peu et s'ÉTIRE. Au contact il est déjà en descente, jamais « tout en
// haut » quand le pied touche. Penché en avant, un peu plus à la poussée.
//
// Jambes et bras à DEUX SEGMENTS (cuisse / tibia, bras / avant-bras) : un
// genou et un coude nets, dessinés en courbe douce. Chaque pied décrit une
// boucle fermée : posé, il recule exactement à la vitesse du sol qui défile
// (il ne glisse pas) ; puis le talon remonte derrière, le pied se replie
// haut sous le corps, passe devant genou levé, va chercher loin et se pose
// en « griffant ». Les bras pompent depuis l'épaule, à contretemps des
// jambes, l'avant-bras plié qui rebondit à chaque pas. Les rubans du bandeau
// flottent derrière avec retard ; une bouffée de poussière naît à chaque
// pose de pied ; l'ombre rétrécit en l'air.

void _coureur(Canvas c, double t) {
  const corail = RhythmCouleurs.corail;
  const periode = 0.56;
  const appui = 0.36;
  const pas = 7.0; // le pied posé va de +7 à −7 autour de la hanche
  const sol = 112.0;
  const yPied = 108.0; // bout rond de 3 : le pied touche le sol
  const vitesse = 2 * pas / (appui * periode);
  final u = _frac(t / periode);

  // ── Le corps, pas par pas ──
  final q = _frac(u * 2);
  const partAppui = appui * 2;
  final double dy, sy;
  if (q < partAppui) {
    final w = math.sin(math.pi * q / partAppui);
    dy = 0.8 + 2.2 * w;
    sy = 1 - 0.05 * w;
  } else {
    final w = math.sin(math.pi * (q - partAppui) / (1 - partAppui));
    dy = 0.8 - 3.2 * w;
    sy = 1 + 0.03 * w;
  }
  final enLAir = ((0.8 - dy) / 3.2).clamp(0.0, 1.0);
  final corps = _Pose(
    dy: dy,
    angle: (10 + 2.5 * math.sin(2 * math.pi * q - 0.8)) * math.pi / 180,
    pivot: const Offset(78, 80),
    sx: 1 / sy,
    sy: sy,
    base: const Offset(78, 81),
  );

  // Le sol défile à la vitesse du pied d'appui.
  final tiret = _trait(_alpha(_blanc, .35), 2.5);
  final defile = -_frac(vitesse * t / 28) * 28;
  for (var k = 0; k < 8; k++) {
    final x = -20.0 + 28 * k + defile;
    _ligne(c, x, sol, x + 14, sol, tiret);
  }

  // L'ombre, plus petite et plus pâle quand il est en l'air.
  _ellipse(
    c,
    79,
    sol + 0.5,
    17 - 3 * enLAir,
    2.4,
    _plein(_alpha(corail, 0.24 - 0.08 * enLAir)),
  );

  // Traînées de vitesse, chacune à son rythme.
  for (final (y, per, dec, lg) in const [
    (44.0, 0.9, 0.0, 16.0),
    (58.0, 1.13, 0.41, 20.0),
    (72.0, 0.77, 0.73, 13.0),
  ]) {
    final v = _frac(t / per + dec);
    final x = 46 - 36 * v;
    _ligne(
      c,
      x,
      y,
      x - lg,
      y,
      _trait(_alpha(_blanc, 0.5 * math.sin(math.pi * v)), 2.5),
    );
  }

  // Poussière : une bouffée à chaque pose de pied, emportée par le sol.
  for (final (hanche, dephasage) in const [(71.0, 0.0), (85.0, 0.5)]) {
    final age = _frac(u - dephasage) * periode;
    if (age > 0.42) continue;
    final a = age / 0.42;
    final x0 = hanche + pas - vitesse * age;
    final opacite = 0.34 * (1 - a) * (1 - a);
    c.drawCircle(
      Offset(x0 - 4 * a, yPied + 2 - 5 * a),
      2 + 3.5 * a,
      _plein(_alpha(_blanc, opacite)),
    );
    c.drawCircle(
      Offset(x0 - 7 - 6 * a, yPied + 3 - 3 * a),
      1.4 + 2.5 * a,
      _plein(_alpha(_blanc, opacite * 0.8)),
    );
  }

  final trait = _trait(corail, 6);

  // La boucle du pied, relative à la hanche (x) : posé, il recule
  // (linéaire, voir `jambe`) ; puis la spline le fait décoller, replier,
  // passer, chercher et se poser — sa vitesse ne casse jamais.
  const boucle = [
    (0.00, Offset(pas, yPied)),
    (0.18, Offset(0, yPied)),
    (appui, Offset(-pas, yPied)),
    (0.47, Offset(-14, yPied - 9)), // le talon remonte derrière
    (0.60, Offset(-9, yPied - 18)), // replié haut sous le corps
    (0.74, Offset(5, yPied - 18)), // passe devant, genou levé
    (0.88, Offset(14, yPied - 10)), // va chercher loin
  ];

  void jambe(double hancheX, double dephasage) {
    final hanche = corps.appliquer(Offset(hancheX, 77));
    final phi = _frac(u + dephasage);
    final rel = phi < appui
        ? Offset(pas - 2 * pas * phi / appui, yPied)
        : _pisteO(boucle, phi);
    final pied = Offset(hancheX + rel.dx, math.min(yPied, rel.dy));
    _membre2(c, hanche, pied, 16, 16, -1, trait); // genou vers l'avant
  }

  void bras(Offset epauleLocale, double sens) {
    final epaule = corps.appliquer(epauleLocale);
    // Le bras pompe depuis l'épaule, en avant quand la jambe opposée l'est ;
    // l'avant-bras reste plié (~90°) et rebondit à chaque pas (traîne).
    final haut = 0.15 + sens * 0.8 * math.cos(2 * math.pi * u);
    final coude = epaule + Offset(math.sin(haut), math.cos(haut)) * 11;
    final avant = haut + 1.55 + 0.22 * math.sin(2 * math.pi * q - 2.0);
    final main = coude + Offset(math.sin(avant), math.cos(avant)) * 11;
    _courbeArticulee(c, epaule, coude, main, trait);
  }

  // Ordre de la maquette : bras du fond, jambes, corps, bras de devant.
  bras(const Offset(56, 56), -1);
  jambe(71, 0);
  jambe(85, 0.5);

  // Les rubans du bandeau, derrière la tête : le vent de la course les tend
  // vers l'arrière, ils ondulent en retard sur le rebond.
  final noeud = corps.appliquer(const Offset(57, 43));
  for (final (lg, base, dec) in const [(16.0, 0.30, 0.0), (12.0, 0.66, 1.1)]) {
    final a =
        math.pi -
        base +
        0.26 * math.sin(2 * math.pi * q - 1.3 - dec) +
        0.07 * math.sin(t * 13 + dec * 4);
    final bout = noeud + Offset(math.cos(a), math.sin(a)) * lg;
    final milieu =
        (noeud + bout) / 2 +
        Offset(0, 3 * math.sin(2 * math.pi * q - 2.2 - dec));
    c.drawPath(
      Path()
        ..moveTo(noeud.dx, noeud.dy)
        ..quadraticBezierTo(milieu.dx, milieu.dy, bout.dx, bout.dy),
      _trait(_blanc, 3),
    );
  }

  c.save();
  corps.surCanvas(c);
  _ellipse(c, 78, 54, 23, 27, _plein(corail));
  c.drawPath(cheminSvg('M56 42 Q78 33 100 42'), _trait(_blanc, 4));
  _yeux(c, const [Offset(80, 52), Offset(92, 52)], fermeture: _paupieres(t, 1));
  // Il halète au rythme de ses pas.
  final souffle = 0.5 + 0.5 * math.sin(2 * math.pi * q - 1);
  c.drawPath(
    Path()
      ..moveTo(84, 62)
      ..quadraticBezierTo(89, 65 + 1.6 * souffle, 94, 61),
    _trait(_noir, 2),
  );
  c.restore();

  bras(const Offset(100, 56), 1);
}

// ═══ Le gourmand (Alimentation) ═════════════════════════════════════════════
//
// Une vraie bouchée (4,4 s) : la main part au bol en arc, la cuillère plonge
// et ramasse, le poignet tourne pendant la montée, le regard suit ; la
// bouche s'entrouvre quand la cuillère monte, s'ouvre grand AVANT qu'elle
// arrive (anticipation) et se referme dessus — les lèvres avancent autour
// d'elle, le creux disparaît dans la bouche —, la cuillère ressort vide.
// Puis il mâche BOUCHE FERMÉE : la mâchoire descend et remonte en petit
// ovale, les lèvres roulent et se pincent ; les yeux se ferment puis se
// plissent de plaisir, il avale (petit rebond) et sourit, « mmh ».
//
// Le visage est de TROIS QUARTS (il regarde le bol) : les yeux sont décalés
// vers la droite, l'œil du fond plus étroit, et la bouche est SOUS eux, à
// peine vers l'avant — avec les yeux de la maquette (52 et 64) et la bouche
// au bord du visage, elle paraissait décalée (retour de l'utilisateur).
//
// Retouché le 24 septembre 2026 (l'utilisateur : « sa bouche fait bizarre,
// constamment ouverte, et il a l'air penché ») : au repos la bouche est un
// SOURIRE FERMÉ (un trait) — elle n'est un creux noir que pour recevoir la
// cuillère ; le corps reste DROIT (plus de bascule vers la cuillère : c'est
// la main qui fait le chemin), et le bras gauche, invisible sur le corps de
// même couleur, disparaît — son bout bosselait le bas du corps et le
// faisait paraître de travers. Les pieds se balancent sous le tabouret ; la
// vapeur monte en volutes irrégulières.

void _gourmand(Canvas c, double t) {
  const peche = RhythmCouleurs.peche;
  const periode = 4.4;
  final u = _frac(t / periode);

  // La vapeur du bol : trois volutes, chacune à son rythme.
  for (final (x, per, dec) in const [
    (106.0, 2.3, 0.0),
    (114.0, 2.9, 0.37),
    (122.0, 2.6, 0.71),
  ]) {
    final q = _frac(t / per + dec);
    final opacite = 0.7 * math.pow(math.sin(math.pi * q), 1.5).toDouble();
    final y0 = 66 - 16 * q;
    final d = 1.6 * math.sin(2 * math.pi * (q * 1.3 + dec));
    c.drawPath(
      Path()
        ..moveTo(x, y0)
        ..quadraticBezierTo(x - 4 + d, y0 - 6, x + d * 0.6, y0 - 12)
        ..quadraticBezierTo(x + 4 + d * 1.4, y0 - 18, x + d * 1.8, y0 - 24),
      _trait(_alpha(_blanc, opacite), 2.5),
    );
  }

  // Le tabouret et la table.
  c.drawPath(cheminSvg('M28 88 H70'), _trait(_alpha(_blanc, .55), 5));
  final pied = _trait(_alpha(_blanc, .55), 4);
  _ligne(c, 34, 90, 34, 116, pied);
  _ligne(c, 64, 90, 64, 116, pied);
  c.drawPath(cheminSvg('M90 86 H146'), _trait(_alpha(_blanc, .85), 5));
  _ligne(c, 138, 88, 138, 116, _trait(_alpha(_blanc, .85), 4));

  // ── La bouchée, pose par pose ──
  const mains = [
    (0.00, Offset(91, 66)), // repos, la cuillère au-dessus du bol
    (0.09, Offset(98, 56)), // au-dessus du bol
    (0.17, Offset(100, 60)), // plonge
    (0.24, Offset(98, 57)), // ramasse
    (0.34, Offset(93, 50)), // monte en arc
    (0.40, Offset(94.5, 60.5)), // attend devant la bouche qui s'ouvre
    (0.46, Offset(81.5, 66.3)), // dans la bouche
    (0.50, Offset(81.9, 66.5)), // les lèvres se ferment dessus
    (0.56, Offset(88, 68)), // ressort, vide
    (0.64, Offset(92, 68)), // redescend
    (0.70, Offset(91, 66)), // repos : il mâche
    (0.95, Offset(91, 66)),
  ];
  // Le poignet tourne toujours dans le même sens : la cuillère décrit une
  // boucle (plonger, ramasser, porter, revenir).
  const angles = [
    (0.00, -18.0),
    (0.09, 25.0),
    (0.17, 62.0),
    (0.24, 88.0),
    (0.34, 140.0),
    (0.40, 178.0),
    (0.46, 190.0),
    (0.50, 191.0),
    (0.56, 202.0),
    (0.64, 262.0),
    (0.70, 330.0),
    (0.95, 342.0),
  ];
  // L'ouverture : fermée au repos, entrouverte quand la cuillère monte,
  // grande ouverte PENDANT qu'elle attend devant (anticipation), refermée
  // sur elle.
  const ouvertures = [
    (0.00, 0.0),
    (0.30, 0.0),
    (0.34, 0.25),
    (0.39, 1.0),
    (0.45, 0.95),
    (0.50, 0.0),
    (0.90, 0.0),
  ];
  // La courbure des lèvres fermées : un sourire tranquille, neutre en
  // mâchant et en avalant, franc après (« mmh »).
  const sourires = [
    (0.00, 0.85),
    (0.12, 0.45),
    (0.30, 0.45),
    (0.58, 0.2),
    (0.88, 0.2),
    (0.91, 0.0),
    (0.95, 1.0),
  ];
  const regards = [
    (0.00, Offset(0, 0)),
    (0.07, Offset(1.2, 0.6)), // regarde le bol
    (0.26, Offset(1.2, 0.6)),
    (0.37, Offset(0.8, -0.4)), // suit la cuillère qui monte
    (0.50, Offset(0, 0)),
    (0.95, Offset(0, 0)),
  ];

  // Trois mastications, bouche fermée : la mâchoire descend puis remonte.
  final mache = u >= 0.58 && u < 0.88
      ? 0.5 - 0.5 * math.cos(2 * math.pi * 3 * _fenetre(u, 0.58, 0.88))
      : 0.0;
  // La mâchoire tourne un peu en mâchant (un petit ovale, pas un va-et-vient).
  final phaseMache = 2 * math.pi * 3 * _fenetre(u, 0.58, 0.88);
  // Les yeux se plissent de plaisir : ils se ferment d'abord (un instant),
  // puis s'arrondissent en « ^ ^ » — et l'inverse à la fin, comme un
  // clignement (un fondu de l'un à l'autre faisait des taches grises).
  final plaisir =
      _lisse(_fenetre(u, 0.595, 0.615)) *
      (1 - _lisse(_fenetre(u, 0.865, 0.885)));
  final plisse = math.max(_cloche(u, 0.575, 0.635), _cloche(u, 0.845, 0.905));
  // Les lèvres avancent autour de la cuillère, jusqu'au bord du visage.
  final moue = _cloche(u, 0.44, 0.57);
  final avale = _amorti(_frac(u - 0.89) * periode, 2.6, 7);
  // Il se grandit un peu vers la cuillère qui arrive (pas de bascule).
  final elan = _cloche(u, 0.33, 0.52);
  final sy =
      1 -
      0.018 * mache +
      0.012 * elan +
      0.02 * avale +
      0.008 * math.sin(2 * math.pi * t / 2.9);
  final corps = _Pose(
    dy: -0.8 * avale,
    sx: 1 / sy,
    sy: sy,
    base: const Offset(50, 85),
  );
  final trait = _trait(peche, 6);

  // La jambe : la cuisse sur le tabouret, le mollet qui se balance.
  final hanche = corps.appliquer(const Offset(56, 82));
  const genou = Offset(78, 84);
  final balance =
      0.13 * math.sin(2 * math.pi * t / 1.35) +
      0.05 * math.sin(2 * math.pi * t / 0.83 + 1);
  final pointe = genou + Offset(math.sin(balance), math.cos(balance)) * 22;
  c.drawPath(
    Path()
      ..moveTo(hanche.dx, hanche.dy)
      ..lineTo(genou.dx, genou.dy)
      ..lineTo(pointe.dx, pointe.dy),
    trait,
  );

  c.save();
  corps.surCanvas(c);
  _ellipse(c, 50, 58, 23, 27, _plein(peche));
  _yeux(
    c,
    const [Offset(58, 49.5), Offset(67.5, 49.5)],
    largeurs: const [1, 0.8],
    fermeture: math.max(_paupieres(t, 2) * (1 - plaisir), plisse),
    joie: plaisir,
    regard: _pisteO(regards, u),
  );
  c.restore();

  // La bouche, sous les yeux (un peu vers l'avant : trois quarts).
  final centreBouche = Offset(
    64.2 + 2 * moue + 0.6 * math.sin(phaseMache) * (mache > 0 ? 1 : 0),
    64.2 + 1.5 * mache,
  );
  final ouverture = _piste(ouvertures, u).clamp(0.0, 1.0);
  final serrement = 0.18 * mache + 0.15 * moue;

  // Le bras, la cuillère, la main. Pendant la bouchée, ce qui passe dans
  // le visage à gauche de la commissure est DANS la bouche : caché.
  final main = _pisteO(mains, u);
  final a = _piste(angles, u, saut: 360) * math.pi / 180;
  final dir = Offset(math.cos(a), math.sin(a));
  _membre(c, corps.appliquer(const Offset(65, 73.5)), main, 24, 1, trait);
  final dansLaBouche = u >= 0.41 && u < 0.58;
  if (dansLaBouche) {
    c.save();
    final commissure = centreBouche.dx + _demiBouche(ouverture, serrement);
    final dedans = Path.combine(
      PathOperation.intersect,
      Path()..addOval(
        Rect.fromCenter(center: const Offset(50, 58), width: 46, height: 54),
      ),
      Path()..addRect(Rect.fromLTRB(0, 0, commissure, 120)),
    );
    c.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(const Rect.fromLTWH(0, 0, 150, 120)),
        dedans,
      ),
    );
  }
  c.drawLine(main + dir * 2, main + dir * 12.5, _trait(_blanc, 3));
  final creux = main + dir * 16.8;
  c.save();
  c.translate(creux.dx, creux.dy);
  c.rotate(a);
  _ellipse(c, 0, 0, 4, 2.5, _plein(_blanc));
  if (u >= 0.24 && u < 0.48) {
    _ellipse(c, 0, 0, 2.6, 1.5, _plein(RhythmCouleurs.abricot));
  }
  c.restore();
  if (dansLaBouche) c.restore();

  c.save();
  corps.surCanvas(c);
  _bouche(
    c,
    centreBouche,
    ouverture: ouverture,
    sourire: _piste(sourires, u) - 0.45 * mache,
    serrement: serrement,
  );
  c.restore();
  c.drawCircle(main, 5.5, _plein(peche));

  // Le bol par-dessus : la cuillère qui plonge disparaît dans la soupe.
  c.drawPath(cheminSvg('M98 70 H130 A16 15 0 0 1 98 70 Z'), _plein(_blanc));
  _ellipse(c, 114, 70, 16, 3, _plein(RhythmCouleurs.abricot));
  c.drawCircle(const Offset(108, 68), 3, _plein(RhythmCouleurs.menthe));
  c.drawCircle(const Offset(118, 67.5), 3, _plein(RhythmCouleurs.corail));
}

/// La demi-largeur de la bouche (de son centre à une commissure).
double _demiBouche(double ouverture, double serrement) =>
    3.6 * (1 - 0.22 * ouverture) * (1 - serrement);

/// Une bouche de profil (trois quarts), centrée sur [centre] : deux lèvres
/// entre deux commissures. Fermée ([ouverture] 0), c'est un trait — un
/// sourire si [sourire] > 0 (une moue en dessous de 0) ; ouverte, la lèvre
/// du bas descend et le creux se remplit de noir. [serrement] rapproche les
/// commissures (lèvres qui avancent, mastication).
void _bouche(
  Canvas c,
  Offset centre, {
  double ouverture = 0,
  double sourire = 0.4,
  double serrement = 0,
}) {
  final demi = _demiBouche(ouverture, serrement);
  // Trois quarts : la commissure du fond est un peu plus haute.
  final gauche = centre + Offset(-demi, -0.2);
  final droite = centre + Offset(demi, -0.6);
  final creux = 1.5 * sourire;
  final haut = Offset(centre.dx, centre.dy + creux - 2.4 * ouverture);
  final bas = Offset(centre.dx, centre.dy + creux + 7.2 * ouverture);
  final levres = Path()
    ..moveTo(gauche.dx, gauche.dy)
    ..quadraticBezierTo(haut.dx, haut.dy, droite.dx, droite.dy)
    ..quadraticBezierTo(bas.dx, bas.dy, gauche.dx, gauche.dy)
    ..close();
  if (ouverture > 0.01) c.drawPath(levres, _plein(_noir));
  c.drawPath(levres, _trait(_noir, 1.7));
}

// ═══ L'enthousiaste (Habitudes) ═════════════════════════════════════════════
//
// Un saut de joie (2,8 s) : il s'accroupit en ramenant les bras
// (anticipation), s'étire et jaillit en lançant les bras au ciel, agite les
// mains au sommet, les jambes repliées, les yeux plissés de bonheur, la
// bouche grande ouverte ; il retombe, s'ÉCRASE, rebondit un peu et se pose
// (amorti) — les bras retombent avec retard puis remontent. La coche éclot
// au sommet du saut et se trace, flotte, sautille avec lui à l'atterrissage
// puis s'en va. La plante se balance doucement et frémit au choc.

void _enthousiaste(Canvas c, double t) {
  const menthe = RhythmCouleurs.menthe;
  const periode = 2.8;
  final u = _frac(t / periode);

  const hauteurs = [
    (0.00, 0.0),
    (0.11, 5.0),
    (0.16, 2.0),
    (0.24, -11.0),
    (0.33, -16.0),
    (0.42, -11.0),
    (0.50, 2.0),
    (0.535, 5.5),
    (0.59, -1.2),
    (0.65, 0.6),
    (0.71, 0.0),
    (0.80, 0.0),
    (0.90, -1.2),
  ];
  const ecrasements = [
    (0.00, 1.0),
    (0.11, 0.85),
    (0.145, 0.95),
    (0.18, 1.15),
    (0.30, 1.0),
    (0.44, 1.05),
    (0.50, 1.0),
    (0.535, 0.81),
    (0.59, 1.06),
    (0.65, 0.97),
    (0.71, 1.01),
    (0.80, 1.0),
    (0.90, 1.01),
  ];
  // Angle des bras depuis la verticale (0 = tout droit en l'air) : pendant
  // l'élan ils descendent le long du corps (150°), puis sont lancés au ciel.
  const brasLeves = [
    (0.00, 32.0),
    (0.11, 150.0),
    (0.155, 95.0),
    (0.21, -8.0),
    (0.27, 18.0),
    (0.33, 6.0),
    (0.39, 22.0),
    (0.45, 12.0),
    (0.53, 80.0),
    (0.60, 18.0),
    (0.67, 38.0),
    (0.75, 30.0),
    (0.88, 34.0),
  ];

  final dy = _piste(hauteurs, u);
  final sy = _piste(ecrasements, u) + 0.01 * math.sin(2 * math.pi * t / 2.3);
  final corps = _Pose(
    dy: dy,
    angle: 1.5 * math.pi / 180 * _bruit(t * 0.9, 5),
    pivot: const Offset(52, 86),
    sx: 1 / sy,
    sy: sy,
    base: const Offset(52, 86),
  );
  final enLAir = (-dy / 16).clamp(0.0, 1.0);
  final choc = _frac(u - 0.535) * periode; // secondes depuis l'atterrissage
  final trait = _trait(menthe, 6);

  // L'ombre : petite et pâle en l'air, large à l'écrasement.
  _ellipse(
    c,
    52,
    113,
    20 * (1 - 0.4 * enLAir) * (1 + 0.5 * (1 - sy).clamp(0.0, 0.3)),
    4 * (1 - 0.3 * enLAir),
    _plein(_alpha(menthe, 0.3 * (1 - 0.5 * enLAir))),
  );

  // La coche.
  if (u >= 0.25 && u < 0.95) {
    const echelles = [
      (0.25, 0.0),
      (0.30, 1.25),
      (0.34, 0.9),
      (0.38, 1.04),
      (0.42, 1.0),
      (0.535, 1.0),
      (0.565, 1.12),
      (0.60, 1.0),
      (0.86, 1.0),
      (0.89, 1.15),
      (0.95, 0.0),
    ];
    final s = math.max(0.0, _piste(echelles, u));
    if (s > 0.01) {
      final flotte = 1.4 * math.sin(2 * math.pi * t / 1.3);
      final tangue = 12 * _amorti((u - 0.25) * periode, 2.6, 5);
      c.save();
      c.translate(86, 22 + flotte);
      c.rotate(tangue * math.pi / 180);
      c.scale(s);
      c.drawCircle(Offset.zero, 13, _plein(_blanc));
      // La coche se trace, du coin à la pointe.
      final coche = cheminSvg('m-6 0 4 4 8-8');
      final mesure = coche.computeMetrics().first;
      c.drawPath(
        mesure.extractPath(0, mesure.length * _lisse(_fenetre(u, 0.29, 0.38))),
        _trait(_noir, 2.6),
      );
      c.restore();
    }
  }

  // Les jambes : repliées en l'air, pliées quand il s'écrase.
  final repli = _cloche(u, 0.21, 0.47);
  for (final (x, cote) in const [(45.0, -1.0), (59.0, 1.0)]) {
    final hanche = corps.appliquer(Offset(x, 82));
    final pied = Offset(
      x + cote * (1.5 + 2 * repli),
      math.min(106.0, hanche.dy + 24 - 7 * repli),
    );
    _membre(c, hanche, pied, 25, -cote, trait);
  }

  // Les bras : le droit suit le gauche avec un souffle de retard ; au
  // sommet, les mains s'agitent.
  final agite = _cloche(u, 0.21, 0.47) * 0.25 * math.sin(2 * math.pi * t * 3.2);
  final aG = _piste(brasLeves, u) * math.pi / 180 + agite;
  final aD = _piste(brasLeves, _frac(u - 0.02)) * math.pi / 180 - agite;
  final epG = corps.appliquer(const Offset(30, 54));
  final epD = corps.appliquer(const Offset(74, 54));
  _membre(
    c,
    epG,
    epG + Offset(-math.sin(aG), -math.cos(aG)) * 18,
    19.5,
    -1,
    trait,
    pliMin: 1,
  );
  _membre(
    c,
    epD,
    epD + Offset(math.sin(aD), -math.cos(aD)) * 18,
    19.5,
    1,
    trait,
    pliMin: 1,
  );

  // Le corps et le visage.
  c.save();
  corps.surCanvas(c);
  _ellipse(c, 52, 58, 24, 28, _plein(menthe));
  _yeux(
    c,
    const [Offset(45, 52), Offset(59, 52)],
    fermeture: _paupieres(t, 3),
    joie: _cloche(u, 0.21, 0.49),
  );
  final o = _cloche(u, 0.19, 0.51);
  c.drawPath(
    Path()
      ..moveTo(46, 62)
      ..quadraticBezierTo(52, 68 + 4 * o, 58, 62),
    _trait(_noir, 2),
  );
  if (o > 0.01) {
    c.drawPath(
      Path()
        ..moveTo(46, 62)
        ..quadraticBezierTo(52, 68 + 4 * o, 58, 62)
        ..quadraticBezierTo(52, 63 + o, 46, 62)
        ..close(),
      _plein(_alpha(_noir, _lisse(o * 2))),
    );
  }
  c.restore();

  // La plante : un balancement lent, et le frisson du choc (traîne) ; les
  // feuilles suivent la tige avec retard.
  double balance(double decalage) =>
      (2.2 * _bruit((t - decalage) * 0.8, 3) +
          7 * _amorti(choc - decalage, 2.2, 3.2)) *
      math.pi /
      180;
  c.save();
  c.translate(120, 96);
  c.rotate(balance(0));
  c.translate(-120, -96);
  _ligne(c, 120, 96, 120, 62, _trait(menthe, 4));
  final feuilles = balance(0.09) * 0.9;
  for (final (d, ancre, sens) in const [
    ('M120 76 q-15 -3 -18 -17 q15 2 18 17Z', Offset(120, 76), 1.0),
    ('M120 68 q13 -4 16 -17 q-13 2 -16 17Z', Offset(120, 68), -1.0),
  ]) {
    c.save();
    c.translate(ancre.dx, ancre.dy);
    c.rotate(feuilles * sens);
    c.translate(-ancre.dx, -ancre.dy);
    c.drawPath(cheminSvg(d), _plein(menthe));
    c.restore();
  }
  c.restore();

  // Le pot sautille au choc.
  c.save();
  c.translate(0, -1.3 * math.max(0.0, _amorti(choc, 3.5, 9)));
  c.drawPath(
    cheminSvg('M105 94 H135 L130 114 H110 Z'),
    _plein(RhythmCouleurs.peche),
  );
  c.restore();
}

// ═══ Le lecteur (Biblique) ══════════════════════════════════════════════════
//
// Il lit, les yeux clos, et RESPIRE : l'inspiration (plus courte) le soulève
// et l'étire un peu, l'expiration (plus longue) le repose ; le livre suit la
// respiration avec retard. Sa tête dérive lentement, jamais au même rythme.
// Toutes les 7,6 s, il tourne une page : la main la pince (anticipation), la
// page se soulève en s'incurvant, passe par-dessus la reliure — on en voit
// le revers —, se pose à gauche et rebondit à peine ; la tête l'accompagne,
// puis hoche doucement.
// Les étoiles scintillent chacune à son rythme, d'un bref éclat.

void _lecteur(Canvas c, double t) {
  const lavande = RhythmCouleurs.lavande;

  // La respiration : inspirer (42 %), expirer (58 %).
  double souffle(double t) {
    final q = _frac(t / 3.4);
    return q < 0.42
        ? Curves.easeInOutSine.transform(q / 0.42)
        : 1 - Curves.easeInOutSine.transform((q - 0.42) / 0.58);
  }

  final inspire = souffle(t);
  final livre = -1.1 * souffle(t - 0.25); // le livre suit, en retard

  // La page qui tourne : anticipation, passage, atterrissage.
  final tp = t % 7.6;
  final pince =
      2.4 *
      _lisse(_fenetre(tp, 4.9, 5.3)) *
      (1 - _lisse(_fenetre(tp, 5.3, 5.6)));
  final passage = Curves.easeInOutCubic.transform(_fenetre(tp, 5.3, 6.7));
  final theta = math.pi * passage;
  final rebond = 2.2 * math.max(0.0, _amorti(tp - 6.7, 3, 7));
  // Après avoir posé la page, il hoche doucement la tête.
  final hoche = _cloche(tp, 6.75, 7.35);

  // Les étoiles : un bref éclat, chacune à son rythme.
  for (final (d, centre, per, dec) in const [
    (
      'M22 20 L23.62 24.38 L28 26 L23.62 27.62 L22 32 L20.38 27.62 L16 26 L20.38 24.38 Z',
      Offset(22, 26),
      2.3,
      0.0,
    ),
    (
      'M130 13 L131.35 16.65 L135 18 L131.35 19.35 L130 23 L128.65 19.35 L125 18 L128.65 16.65 Z',
      Offset(130, 18),
      3.1,
      0.3,
    ),
    (
      'M138 56 L139.08 58.92 L142 60 L139.08 61.08 L138 64 L136.92 61.08 L134 60 L136.92 58.92 Z',
      Offset(138, 60),
      2.7,
      0.6,
    ),
    (
      'M16 70 L17.08 72.92 L20 74 L17.08 75.08 L16 78 L14.92 75.08 L12 74 L14.92 72.92 Z',
      Offset(16, 74),
      3.7,
      0.85,
    ),
  ]) {
    final eclat = math
        .pow(math.max(0.0, math.sin(2 * math.pi * (t / per + dec))), 3)
        .toDouble();
    c.save();
    c.translate(centre.dx, centre.dy);
    c.rotate(0.35 * eclat);
    c.scale(0.75 + 0.4 * eclat);
    c.translate(-centre.dx, -centre.dy);
    c.drawPath(cheminSvg(d), _plein(_alpha(_blanc, 0.12 + 0.8 * eclat)));
    c.restore();
  }

  _ellipse(
    c,
    75,
    113,
    34 * (1 + 0.015 * inspire),
    4,
    _plein(_alpha(lavande, .3)),
  );

  // Le corps : il respire, la tête dérive et suit la page qui passe.
  final sy = 1 + 0.03 * inspire;
  final corps = _Pose(
    dy: -0.8 * inspire + 1.2 * hoche,
    angle: (1.4 * _bruit(t * 0.45, 1.7) - 3 * math.sin(theta)) * math.pi / 180,
    pivot: const Offset(75, 84),
    sx: 1 - 0.012 * inspire,
    sy: sy - 0.012 * hoche,
    base: const Offset(75, 80),
  );
  final jambe = _trait(lavande, 6);
  _membre(
    c,
    corps.appliquer(const Offset(62, 84)),
    const Offset(58, 108),
    25,
    1,
    jambe,
  );
  _membre(
    c,
    corps.appliquer(const Offset(88, 84)),
    const Offset(92, 108),
    25,
    -1,
    jambe,
  );
  c.save();
  corps.surCanvas(c);
  _ellipse(c, 75, 52, 24, 28, _plein(lavande));
  final paupiere = _trait(_noir, 2.2);
  c.drawPath(cheminSvg('M65 48 q3 3 6 0'), paupiere);
  c.drawPath(cheminSvg('M79 48 q3 3 6 0'), paupiere);
  c.drawPath(
    Path()
      ..moveTo(72, 60)
      ..quadraticBezierTo(75, 62 + 0.6 * inspire, 78, 60),
    _trait(_noir, 2),
  );
  c.restore();

  // Le livre, porté par la respiration.
  c.save();
  c.translate(0, livre);
  c.drawPath(cheminSvg('M75 76 L46 71 L46 95 L75 100 Z'), _plein(_blanc));
  c.drawPath(
    cheminSvg('M75 76 L104 71 L104 95 L75 100 Z'),
    _plein(RhythmCouleurs.lavandePale),
  );
  // La page : du recto (couleur de la page de droite, invisible au repos) au
  // verso (couleur de la page de gauche, invisible une fois posée) — la
  // boucle est sans couture.
  if (passage > 0 || pince > 0) {
    final lever = 14 * math.sin(theta) + pince + rebond;
    final bord = 75 + 27 * math.cos(theta);
    final couleur = theta < math.pi / 2
        ? Color.lerp(
            RhythmCouleurs.lavandePale,
            RhythmCouleurs.blanc,
            math.sin(theta),
          )!
        : Color.lerp(_blanc, RhythmCouleurs.blanc, math.sin(theta))!;
    c.drawPath(
      Path()
        ..moveTo(75, 76)
        // La page s'incurve : son bord libre traîne derrière son milieu.
        ..quadraticBezierTo(
          (75 + bord) / 2,
          74 - lever * 1.25,
          bord,
          72 - lever * 0.85,
        )
        ..lineTo(bord, 94 - lever * 0.55)
        ..quadraticBezierTo((75 + bord) / 2, 97 - lever * 0.7, 75, 99)
        ..close(),
      _plein(couleur),
    );
  }
  // Les mains : la droite pince la page et la lâche, la gauche la reçoit.
  c.drawCircle(
    Offset(48, 90 + 0.8 * math.max(0.0, _amorti(tp - 6.7, 3, 7))),
    5,
    _plein(lavande),
  );
  c.drawCircle(
    Offset(102 - 2 * _cloche(tp, 5.1, 5.9), 90 - pince * 0.7),
    5,
    _plein(lavande),
  );
  c.restore();
}

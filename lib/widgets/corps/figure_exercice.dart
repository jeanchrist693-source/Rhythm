// lib/widgets/corps/figure_exercice.dart
//
// Un exercice en MOUVEMENT : le corps 3D (`squelette3.dart`, peint par
// `peintre3.dart`) qui enchaîne des IMAGES CLÉS. Chaque clé dit en combien
// de temps on l'atteint, avec quelle COURBE (la montée d'un squat n'a pas le
// rythme de sa descente : on descend en contrôlant, on remonte plus vite,
// on marque un temps), et combien de temps on la tient. Le cycle revient à
// la première clé. La poitrine respire.
//
// Une horloge par figure, muette quand l'écran est caché (`TickerMode`),
// arrêtée si le système réduit les animations ; [animer] = false : la pose
// de l'[instant] demandé, figée (listes).

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../modele/sports/exercices.dart';
import 'animations_corps.dart';
import 'corps_humain.dart';
import 'geometrie3.dart' show V3;
import 'peintre3.dart';
import 'squelette3.dart';

export 'peintre3.dart' show Camera3;
export 'squelette3.dart' show Cible, Pose3;

/// Le rythme d'un passage d'une clé à la suivante.
enum Courbe {
  /// Aller et retour réguliers (sinus).
  douce(Curves.easeInOutSine),

  /// Un départ et une arrivée amortis (un mouvement contrôlé).
  controlee(Curves.easeInOutCubic),

  /// Un départ vif qui ralentit (une poussée, un saut).
  explosive(Curves.easeOutCubic),

  /// Un départ lent qui accélère (une chute contrôlée, puis l'appui).
  lancee(Curves.easeInCubic),

  /// Constante (une course, un pédalage).
  reguliere(Curves.linear);

  const Courbe(this.courbe);
  final Curve courbe;
}

/// Une image clé.
class Cle {
  const Cle(
    this.pose, {
    this.duree = 1,
    this.courbe = Courbe.controlee,
    this.tenue = 0,
  });

  final Pose3 pose;

  /// Le temps pour ARRIVER à cette pose depuis la précédente (secondes).
  final double duree;
  final Courbe courbe;

  /// Le temps passé dans cette pose, une fois arrivé.
  final double tenue;
}

/// Une animation d'exercice.
class AnimCorps {
  const AnimCorps(
    this.cles, {
    this.camera = Camera3.profil,
    this.accessoires = const Accessoires(),
  });

  final List<Cle> cles;
  final Camera3 camera;
  final Accessoires accessoires;

  /// Un cycle complet, en secondes.
  double get duree =>
      cles.fold(0.0, (s, c) => s + c.duree + c.tenue).clamp(0.2, 60);

  /// La même animation avec d'autres accessoires.
  AnimCorps avec(Accessoires a) =>
      AnimCorps(cles, camera: camera, accessoires: a);

  /// La pose au temps [t] du cycle (0..1).
  Pose3 pose(double t) {
    if (cles.length == 1) return cles.first.pose;
    var x = (t % 1) * duree;
    // La clé 0 : on la tient d'abord, puis on va aux suivantes ; le retour à
    // la clé 0 prend sa [duree].
    final n = cles.length;
    x -= cles[0].tenue;
    if (x < 0) return cles[0].pose;
    for (var k = 1; k <= n; k++) {
      final cible = cles[k % n];
      final depart = cles[k - 1].pose;
      if (x < cible.duree) {
        final u = cible.courbe.courbe.transform((x / cible.duree).clamp(0, 1));
        final (de, vers) = _relier(depart, cible.pose);
        return Pose3.lerp(de, vers, u);
      }
      x -= cible.duree;
      if (k < n) {
        if (x < cible.tenue) return cible.pose;
        x -= cible.tenue;
      }
    }
    return cles[0].pose;
  }

  /// Deux clés dont l'une tient un membre par une cible et l'autre non : la
  /// cible manquante est prise là où le membre se trouve (et son coude ou son
  /// genou donne le sens du pli), pour que le membre GLISSE d'une clé à
  /// l'autre au lieu de sauter à mi-chemin. Les cibles sans profondeur
  /// reçoivent celle de leur épaule ou de leur hanche.
  static (Pose3, Pose3) _relier(Pose3 a, Pose3 b) {
    bool ecart(Cible? u, Cible? v) =>
        (u == null) != (v == null) ||
        (u != null && v != null && (u.z == null) != (v.z == null));
    if (!ecart(a.mainP, b.mainP) &&
        !ecart(a.mainL, b.mainL) &&
        !ecart(a.piedCibleP, b.piedCibleP) &&
        !ecart(a.piedCibleL, b.piedCibleL)) {
      return (a, b);
    }
    Pose3 completer(Pose3 p, Pose3 autre) {
      final s = Squelette3.de(p);
      V3? pli(Membre3 m) {
        final d = m.milieu - V3.lerp(m.racine, m.bout, 0.5);
        return d.norme < 1e-3 ? null : d;
      }

      Cible? cible(Cible? c, Cible? c2, Membre3 m, V3 bout) {
        if (c != null) return c.z != null ? c : Cible(c.x, c.y, m.racine.z);
        return c2 == null ? null : Cible(bout.x, bout.y, bout.z);
      }

      final mainP = p.mainP == null && autre.mainP != null;
      final mainL = p.mainL == null && autre.mainL != null;
      final piedP = p.piedCibleP == null && autre.piedCibleP != null;
      final piedL = p.piedCibleL == null && autre.piedCibleL != null;
      return p.copier(
        mainP: cible(p.mainP, autre.mainP, s.brasP, s.brasP.extremite),
        mainL: cible(p.mainL, autre.mainL, s.brasL, s.brasL.extremite),
        piedCibleP: cible(
          p.piedCibleP,
          autre.piedCibleP,
          s.jambeP,
          s.jambeP.bout,
        ),
        piedCibleL: cible(
          p.piedCibleL,
          autre.piedCibleL,
          s.jambeL,
          s.jambeL.bout,
        ),
        coudeP: mainP ? pli(s.brasP) : null,
        coudeL: mainL ? pli(s.brasL) : null,
        genouP: piedP ? pli(s.jambeP) : null,
        genouL: piedL ? pli(s.jambeL) : null,
      );
    }

    return (completer(a, b), completer(b, a));
  }
}

class FigureExercice extends StatefulWidget {
  const FigureExercice({
    super.key,
    required this.animation,
    this.principaux = const {},
    this.secondaires = const {},
    this.animer = true,
    this.instant = 0,
    this.cadre,
  });

  final AnimCorps animation;
  final Set<Muscle> principaux;
  final Set<Muscle> secondaires;
  final bool animer;

  /// La pose montrée quand la figure est figée (0..1 du cycle).
  final double instant;

  /// La partie du carré 0..1 à montrer (`cadreDe`) ; `null` : tout le carré.
  final Rect? cadre;

  @override
  State<FigureExercice> createState() => _FigureExerciceState();
}

class _FigureExerciceState extends State<FigureExercice>
    with SingleTickerProviderStateMixin {
  /// Le temps écoulé, en secondes.
  final ValueNotifier<double> _t = ValueNotifier(0);
  late final Ticker _ticker = createTicker((e) {
    _t.value = widget.instant * widget.animation.duree + e.inMicroseconds / 1e6;
  });

  @override
  void initState() {
    super.initState();
    _t.value = widget.instant * widget.animation.duree;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final figee = !widget.animer || MediaQuery.disableAnimationsOf(context);
    if (figee && _ticker.isActive) _ticker.stop();
    if (!figee && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PeintreFigure(
        widget.animation,
        _t,
        widget.principaux,
        widget.secondaires,
        widget.cadre,
        widget.animer,
      ),
      size: Size.infinite,
    ),
  );
}

class _PeintreFigure extends CustomPainter {
  _PeintreFigure(
    this.anim,
    this.t,
    this.principaux,
    this.secondaires,
    this.cadre,
    this.anime,
  ) : super(repaint: t);

  final AnimCorps anim;
  final ValueNotifier<double> t;
  final Set<Muscle> principaux;
  final Set<Muscle> secondaires;
  final Rect? cadre;
  final bool anime;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final double cote;
    final c = cadre;
    if (c == null) {
      cote = size.shortestSide;
      canvas.translate((size.width - cote) / 2, (size.height - cote) / 2);
    } else {
      // Le cadre, le plus grand possible, centré ; le reste est coupé.
      cote = math.min(size.width / c.width, size.height / c.height);
      canvas.clipRect(Offset.zero & size);
      canvas.translate(
        (size.width - c.width * cote) / 2 - c.left * cote,
        (size.height - c.height * cote) / 2 - c.top * cote,
      );
    }
    final secondes = t.value;
    final cycle = secondes / anim.duree;
    final peintre = PeintreCorps3(
      cote: cote,
      camera: anim.camera,
      principaux: principaux,
      secondaires: secondaires,
      respiration: anime ? (secondes / 3.6) % 1 : 0,
      phase: cycle % 1,
    );
    peintre.peindre(
      canvas,
      Squelette3.de(anim.pose(cycle % 1)),
      anim.accessoires,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreFigure ancien) =>
      ancien.anim != anim ||
      ancien.cadre != cadre ||
      ancien.principaux != principaux ||
      ancien.secondaires != secondaires;
}

final Map<String, AnimCorps> _parExercice = {};

/// L'animation d'un exercice de la banque : son mouvement, avec la charge
/// de CET exercice (une kettlebell au lieu d'haltères, une barre, ou rien
/// au poids du corps).
AnimCorps animationDe(ExerciceSport e) => _parExercice.putIfAbsent(e.id, () {
  final base = Mouvements.de(e.mouvement) ?? Mouvements.de('squat')!;
  final a = base.accessoires;
  if (!a.tientUneCharge) return base;
  final kb = e.materiel.contains(Materiel.kettlebell);
  final barre = e.materiel.contains(Materiel.barre);
  final hal = e.materiel.contains(Materiel.halteres);
  if (kb && !a.kettlebell && !a.kettlebells) {
    // Deux haltères deviennent deux kettlebells ; sinon, une seule.
    return base.avec(
      a.halteres
          ? a.avecCharge(kettlebells: true)
          : a.avecCharge(kettlebell: true),
    );
  }
  if (barre && !a.barre && !a.barreDos) {
    return base.avec(a.avecCharge(barre: true));
  }
  if (hal && !a.halteres && !a.haltereUne && !a.goblet) {
    return base.avec(a.avecCharge(halteres: true));
  }
  if (!kb && !barre && !hal) return base.avec(a.avecCharge());
  return base;
});

final Map<AnimCorps, Rect> _cadres = {};

/// Le CADRE d'une animation : toute la largeur, et en hauteur seulement ce
/// que le corps occupe au cours du mouvement (du plus haut qu'il monte au
/// sol) — un exercice couché (pompes, planche) n'a plus un grand vide
/// au-dessus de lui.
Rect cadreDe(AnimCorps a) => _cadres.putIfAbsent(a, () {
  var haut = kSol;
  var plusBas = kSol;
  var gauche = 0.0, droite = 1.0;
  for (var i = 0; i < 16; i++) {
    final s = Squelette3.de(a.pose(i / 16));
    for (final p in s.points) {
      final e = a.camera.projeter(p);
      haut = math.min(haut, e.dy);
      plusBas = math.max(plusBas, e.dy);
      // Un corps allongé, bras tendus, peut déborder du carré.
      gauche = math.min(gauche, e.dx - 0.05);
      droite = math.max(droite, e.dx + 0.05);
    }
  }
  // La tête et une charge au bout des bras dépassent les articulations.
  haut -= 0.1;
  final fixe = a.accessoires.barreFixe;
  if (fixe != null) haut = math.min(haut, fixe.dy - 0.04);
  // Vu d'en haut, ce qui est près de nous descend sous la ligne du sol.
  final bas = math.min(
    1.1,
    math.max(kSol + 0.05, a.camera.tangage > 0 ? plusBas + 0.06 : 0.0),
  );
  // Pas plus large que 2 : au-delà, la figure serait minuscule en hauteur.
  haut = math.max(-0.2, math.min(haut, bas - 0.5 * (droite - gauche)));
  return Rect.fromLTRB(gauche, haut, droite, bas);
});

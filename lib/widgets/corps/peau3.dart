// lib/widgets/corps/peau3.dart
//
// La PEAU du corps : chaque partie est une SURFACE MAILLÉE, peinte triangle
// par triangle, du plus loin au plus proche (`Tampon3`).
//
// Historique : l'utilisateur, une fois les mouvements jugés naturels, « au
// niveau de ses muscles ou des membres qui bougent, on dirait un jouet en
// caoutchouc, monté de toutes pièces » (d'où les membres d'un seul tenant,
// qui se plient), puis (25 sept. 2026) : « comme un vrai humain, que ce soit
// en muscle, articulation, mouvement, corps, visage, cheveux ». Le moteur :
//
// 1. les FORMES (`peau/tronc.dart`, `peau/membres.dart`, `peau/tete.dart`,
//    `peau/extremites.dart`) : le tronc balayé le long du dos, les membres
//    d'un seul tenant qui se plient et se tassent dans le pli, les muscles en
//    reliefs qui se contractent, la tête et son visage, les mains, les pieds ;
// 2. les GRILLES de sommets tirées de ces formes (`peau/grille.dart`) ;
// 3. la SOUDURE des parties (épaules, hanches, cou) sur leur union lisse, de
//    même lumière : plus de couture ni de dents de scie ; ce qui est enfoui
//    dans une autre partie n'est pas peint ;
// 4. le RENDU (`peau/rendu.dart`) : une lumière de studio liée à la caméra,
//    la peau (ombres chaudes, contre-jour), l'occlusion des plis et des
//    autres parties ;
// 5. ce qui se POSE sur la peau : les muscles travaillés (fuseaux corail :
//    principaux ; corail doux : secondaires), les yeux, les sourcils, la
//    bouche, les cheveux — collés à la surface maillée, peints juste après
//    la peau qu'ils recouvrent.
//
// Repère : celui de `geometrie3.dart` ; un angle autour d'un membre se
// compte en degrés depuis son AVANT (0 : devant — biceps, cuisse, paume —,
// 90 : dehors, 180 : derrière, −90 : dedans) ; autour du tronc, depuis la
// poitrine (90 : le côté proche, −90 : le côté loin).

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../modele/sports/muscles.dart';
import '../../theme/rhythm_couleurs.dart';
import 'corps_humain.dart' show Accessoires;
import 'geometrie3.dart';
import 'peintre3.dart' show Camera3;
import 'squelette3.dart';

part 'peau/outils.dart';
part 'peau/grille.dart';
part 'peau/rendu.dart';
part 'peau/tronc.dart';
part 'peau/membres.dart';
part 'peau/tete.dart';
part 'peau/extremites.dart';
part 'peau/mains.dart';

// ═══ Le tampon : les triangles à peindre ════════════════════════════════════

/// Des triangles (sommets à l'écran, une couleur par sommet) et leur
/// PROXIMITÉ (plus grande = plus près), peints du plus loin au plus proche.
class Tampon3 {
  Float32List _pos = Float32List(6 * 6000);
  Int32List _col = Int32List(3 * 6000);
  Float64List _z = Float64List(6000);

  /// Le nombre de triangles.
  int n = 0;

  void _grandir() {
    final m = _z.length * 2;
    final pos = Float32List(6 * m)..setRange(0, 6 * n, _pos);
    final col = Int32List(3 * m)..setRange(0, 3 * n, _col);
    final z = Float64List(m)..setRange(0, n, _z);
    _pos = pos;
    _col = col;
    _z = z;
  }

  void triangle(
    double ax,
    double ay,
    int ca,
    double bx,
    double by,
    int cb,
    double cx,
    double cy,
    int cc,
    double z,
  ) {
    if (n == _z.length) _grandir();
    final p = 6 * n, q = 3 * n;
    _pos[p] = ax;
    _pos[p + 1] = ay;
    _pos[p + 2] = bx;
    _pos[p + 3] = by;
    _pos[p + 4] = cx;
    _pos[p + 5] = cy;
    _col[q] = ca;
    _col[q + 1] = cb;
    _col[q + 2] = cc;
    _z[n] = z;
    n++;
  }

  /// La proximité du triangle [i].
  double z(int i) => _z[i];

  /// L'ordre de peinture, du plus loin au plus proche (tri par paquets :
  /// linéaire, et stable à l'intérieur d'un paquet).
  Int32List ordre() {
    final o = Int32List(n);
    if (n == 0) return o;
    var mn = _z[0], mx = _z[0];
    for (var i = 1; i < n; i++) {
      final v = _z[i];
      if (v < mn) mn = v;
      if (v > mx) mx = v;
    }
    const paquets = 8192;
    final k = mx > mn ? (paquets - 1) / (mx - mn) : 0.0;
    final compte = Int32List(paquets + 1);
    final cle = Int32List(n);
    for (var i = 0; i < n; i++) {
      final b = ((_z[i] - mn) * k).floor();
      cle[i] = b;
      compte[b + 1]++;
    }
    for (var b = 0; b < paquets; b++) {
      compte[b + 1] += compte[b];
    }
    for (var i = 0; i < n; i++) {
      o[compte[cle[i]]++] = i;
    }
    return o;
  }

  /// Peint les triangles [de]..[a] de l'[ordre].
  void peindre(Canvas c, Int32List ordre, int de, int a) {
    final m = a - de;
    if (m <= 0) return;
    final pos = Float32List(m * 6);
    final col = Int32List(m * 3);
    final sp = _pos, sc = _col;
    for (var k = 0; k < m; k++) {
      final i = ordre[de + k];
      final p = 6 * k, q = 6 * i;
      pos[p] = sp[q];
      pos[p + 1] = sp[q + 1];
      pos[p + 2] = sp[q + 2];
      pos[p + 3] = sp[q + 3];
      pos[p + 4] = sp[q + 4];
      pos[p + 5] = sp[q + 5];
      final c3 = 3 * k, i3 = 3 * i;
      col[c3] = sc[i3];
      col[c3 + 1] = sc[i3 + 1];
      col[c3 + 2] = sc[i3 + 2];
    }
    c.drawVertices(
      Vertices.raw(VertexMode.triangles, pos, colors: col),
      BlendMode.dst,
      Paint(),
    );
  }
}

// ═══ La peau ═════════════════════════════════════════════════════════════════

/// Les parties du corps (l'occlusion : une partie n'assombrit pas elle-même).
const int _pTronc = 0, _pTete = 1, _pBrasP = 2, _pBrasL = 3;
const int _pJambeP = 4, _pJambeL = 5;

class Peau3 {
  Peau3({
    required this.camera,
    required this.cote,
    this.principaux = const {},
    this.secondaires = const {},
    this.respiration = 0,
    this.clignement = 0,
    this.accessoires = const Accessoires(),
  }) : fin = cote >= 140;

  final Camera3 camera;

  /// La taille du carré 0..1, en pixels.
  final double cote;
  final Set<Muscle> principaux;
  final Set<Muscle> secondaires;
  final double respiration;

  /// Les paupières (0 : ouvertes, 1 : fermées).
  final double clignement;

  /// Ce que tiennent les mains (la prise des doigts).
  final Accessoires accessoires;

  /// Le maillage fin (grandes figures) ou léger (miniatures).
  final bool fin;

  /// Une couleur unie par partie (bancs d'essai).
  static bool debogage = false;

  /// L'épaisseur du contour (bancs d'essai).
  static double contour = 0;

  late final double _cl = math.cos(rad(camera.lacet));
  late final double _sl = math.sin(rad(camera.lacet));
  late final double _ct = math.cos(rad(camera.tangage));
  late final double _st = math.sin(rad(camera.tangage));
  late final _Lumieres _l = _Lumieres(camera);
  late final double _largeurTrait = cote * 0.0028 * Peau3.contour;
  late Tampon3 _t;
  final List<_Occultant> _occultants = [];

  static final _Matiere _principal = _muscle(0xFFFF8A7A);
  static final _Matiere _secondaire = _muscle(
    Color.lerp(RhythmCouleurs.corail, const Color(_teintPeau), 0.5)!.toARGB32(),
  );

  _Matiere? _teinteDe(Muscle m) => principaux.contains(m)
      ? _principal
      : (secondaires.contains(m) ? _secondaire : null);

  /// Le temps passé par étape (bancs d'essai de vitesse), en µs.
  static final Map<String, int> chronos = {};
  static bool chronometrer = false;
  final Stopwatch _chrono = Stopwatch();

  void _top(String etape) {
    if (!chronometrer) return;
    chronos[etape] = (chronos[etape] ?? 0) + _chrono.elapsedMicroseconds;
    _chrono.reset();
  }

  /// Tout le corps, dans le tampon.
  void habiller(Squelette3 s, Tampon3 t) {
    _t = t;
    if (chronometrer) _chrono.start();
    _occultants.addAll(_capsules(s));
    // 1. Les formes et leurs grilles.
    final (_, tronc) = _tronc(s);
    final (_, brasP) = _bras(s, s.brasP, 1);
    final (_, brasL) = _bras(s, s.brasL, -1);
    final (_, jambeP) = _jambe(s, s.jambeP, 1, s.talonP);
    final (_, jambeL) = _jambe(s, s.jambeL, -1, s.talonL);
    _top('formes');
    final (tete, gTete) = _tete(s);
    _top('tête (forme)');
    final mains = fin ? [_main(s, true), _main(s, false)] : null;
    _top('mains (forme)');
    // 2. Les soudures.
    _souderTout(s, tronc, brasP, brasL, jambeP, jambeL, tete, gTete, mains);
    _top('soudures');
    // 3. La peinture.
    _peindreTronc(tronc);
    _top('tronc (peint)');
    _peindreTete(tete, gTete);
    _top('tête (peinte)');
    _peindreBras(brasP, _pBrasP);
    _peindreBras(brasL, _pBrasL);
    _top('bras (peints)');
    if (mains != null) {
      for (final (grilles, partie) in [
        (mains[0], _pBrasP),
        (mains[1], _pBrasL),
      ]) {
        _emettre(grilles[0], const [_peau], partie: partie, biais: 0.003);
        _emettre(grilles[1], const [_peau], partie: partie, biais: 0.004);
      }
    } else {
      _mainSimple(s, s.brasP, 1, _pBrasP);
      _mainSimple(s, s.brasL, -1, _pBrasL);
    }
    _top('mains (peintes)');
    _peindreJambe(jambeP, _pJambeP);
    _chaussure3(s.jambeP, s.talonP, _pJambeP);
    _peindreJambe(jambeL, _pJambeL);
    _chaussure3(s.jambeL, s.talonL, _pJambeL);
    _top('jambes (peintes)');
  }

  /// Les capsules qui font de l'ombre aux autres parties.
  static List<_Occultant> _capsules(Squelette3 s) => [
    _Occultant(s.bassin - s.dirTronc * 0.02, s.dosControle, 0.058, _pTronc),
    _Occultant(s.dosControle, s.cou - s.dirTronc * 0.035, 0.062, _pTronc),
    _Occultant(s.tete, s.tete, 0.046, _pTete),
    for (final (b, p) in [(s.brasP, _pBrasP), (s.brasL, _pBrasL)]) ...[
      _Occultant(V3.lerp(b.racine, b.milieu, 0.35), b.milieu, 0.026, p),
      _Occultant(b.milieu, b.bout, 0.02, p),
      _Occultant(b.bout, b.extremite, 0.014, p),
    ],
    for (final (j, talon, p) in [
      (s.jambeP, s.talonP, _pJambeP),
      (s.jambeL, s.talonL, _pJambeL),
    ]) ...[
      _Occultant(V3.lerp(j.racine, j.milieu, 0.3), j.milieu, 0.042, p),
      _Occultant(j.milieu, j.bout, 0.028, p),
      _Occultant(talon, j.extremite, 0.018, p),
    ],
  ];

  /// Les indices des anneaux dont le paramètre est dans [a, b].
  static (int, int) _plage(List<double> ss, double a, double b) {
    var i0 = 0;
    while (i0 < ss.length - 1 && ss[i0] < a) {
      i0++;
    }
    var i1 = ss.length - 1;
    while (i1 > 0 && ss[i1] > b) {
      i1--;
    }
    return (i0, math.max(i0 + 1, i1));
  }

  /// Soude les parties entre elles : les épaules, les hanches, l'entrejambe,
  /// le cou.
  void _souderTout(
    Squelette3 s,
    _Grille tronc,
    _Grille brasP,
    _Grille brasL,
    _Grille jambeP,
    _Grille jambeL,
    _FormeTete tete,
    _Grille gTete,
    List<List<_Grille>>? mains,
  ) {
    for (final g in [tronc, brasP, brasL, jambeP, jambeL, gTete]) {
      g.calculerNormales();
    }
    final moves = <(_Grille, List<_Deplacement>)>[];

    /// Une partie d'une grille, entre les anneaux de paramètre [a] et [b],
    /// et son volume.
    (_Grille, int, int, _Volume) partie(_Grille g, double a, double b) {
      final (i0, i1) = _plage(g.ss!, a, b);
      return (g, i0, i1, _Tube(g, i0, i1).distance);
    }

    /// Joint deux parties autour de [centre] : ce qui est enfoui dans
    /// l'autre (à moins de [rayon] du centre) n'est pas peint, le reste est
    /// posé sur leur union lisse (congé [k], de [r0] à [r1] du centre).
    void joindre(
      (_Grille, int, int, _Volume) a,
      (_Grille, int, int, _Volume) b,
      V3 centre,
      double r0,
      double r1,
      double k, {
      double rayon = 0.08,
      double marge = 0.003,
    }) {
      for (final (p, q) in [(a, b), (b, a)]) {
        final (g, i0, i1, propre) = p;
        final autre = q.$4;
        _enfouir(g, autre, marge, i0: i0, i1: i1, centre: centre, rayon: rayon);
        moves.add((
          g,
          _souder(g, propre, autre, centre, r0, r1, k, i0: i0, i1: i1),
        ));
      }
    }

    final epaules = partie(tronc, 0.35, 1.14);
    final bassin = partie(tronc, -0.28, 0.45);
    for (final (g, b) in [(brasP, s.brasP), (brasL, s.brasL)]) {
      joindre(partie(g, -0.19, 0.75), epaules, b.racine, 0.045, 0.09, 0.017);
    }
    final cuisses = [
      for (final g in [jambeP, jambeL]) partie(g, -0.075, 0.6),
    ];
    for (final (c, j) in [(cuisses[0], s.jambeP), (cuisses[1], s.jambeL)]) {
      joindre(c, bassin, j.racine, 0.05, 0.1, 0.012, rayon: 0.1);
    }
    // L'entrejambe : les deux cuisses l'une contre l'autre.
    joindre(
      cuisses[0],
      cuisses[1],
      V3.lerp(s.jambeP.racine, s.jambeL.racine, 0.5),
      0.03,
      0.08,
      0.006,
    );
    // Le cou (qui appartient à la tête) dans le haut du tronc : à la base
    // du cou, les trapèzes.
    final (h0, h1) = _plage(gTete.ss!, _FormeTete.bas, -0.045);
    joindre(
      partie(tronc, 0.85, 1.12),
      (gTete, h0, h1, _Tube(gTete, h0, h1).distance),
      s.cou - s.dirTronc * 0.006,
      0.04,
      0.075,
      0.011,
      rayon: 0.07,
    );
    // Les mains : le gant s'enfonce dans l'avant-bras (et l'avant-bras
    // dans le gant), la base du pouce dans la paume — rien n'est soudé (des
    // pièces si petites et si plates) : ce qui est enfoui n'est pas peint,
    // et la main est peinte un rien devant l'avant-bras.
    if (mains != null) {
      for (final (grilles, bras) in [(mains[0], brasP), (mains[1], brasL)]) {
        final gant = grilles.first..calculerNormales();
        final tGant = _Tube(gant, 0, gant.rangs - 1).distance;
        final (i0, i1) = _plage(bras.ss!, 1.75, 2.07);
        _enfouir(bras, tGant, 0.0008, i0: i0, i1: i1);
        _enfouir(gant, _Tube(bras, i0, i1).distance, 0.0008, i1: 3);
        _enfouir(grilles[1], tGant, 0.0005);
      }
    }
    for (final (g, d) in moves) {
      _appliquer(g, d);
    }
  }

  // ── Une forme en maillage ────────────────────────────────────────────────

  /// La forme maillée : un anneau par [ss], [cols] sommets par anneau ;
  /// [trait] : l'épaisseur du contour selon s ; [ombre] : l'occlusion des
  /// plis.
  _Grille _nappe(
    V3 Function(double s, double phi, double cph, double sph, double plus)
    point,
    List<double> ss,
    int cols,
    double Function(double s) trait, {
    double Function(double s, double phi)? ombre,
  }) {
    final g = _Grille(ss.length, cols)..ss = ss;
    final (cs, sn) = _table(cols);
    for (var i = 0; i < ss.length; i++) {
      final s = ss[i];
      final tr = trait(s);
      for (var j = 0; j < cols; j++) {
        final k = i * cols + j;
        final phi = 360.0 * j / cols;
        g.poser(k, point(s, phi, cs[j], sn[j], 0));
        g.trait[k] = tr;
        if (ombre != null) g.ao[k] = ombre(s, phi);
      }
    }
    _creux(g);
    return g;
  }

  static final Map<int, (Float64List, Float64List)> _tables = {};

  /// Le cosinus et le sinus de chaque colonne d'un anneau de [n] sommets.
  static (Float64List, Float64List) _table(int n) => _tables.putIfAbsent(n, () {
    final c = Float64List(n), s = Float64List(n);
    for (var j = 0; j < n; j++) {
      c[j] = math.cos(2 * math.pi * j / n);
      s[j] = math.sin(2 * math.pi * j / n);
    }
    return (c, s);
  });

  /// Les CREUX entre deux reliefs (le sillon du deltoïde, celui du
  /// quadriceps…) un peu plus sombres, les bosses un rien plus claires : le
  /// relief se lit, comme sur une vraie musculature.
  static void _creux(_Grille g) {
    final n = g.rangs, c = g.cols;
    final r = Float64List(n * c);
    for (var i = 0; i < n; i++) {
      var cx = 0.0, cy = 0.0, cz = 0.0;
      for (var j = 0; j < c; j++) {
        cx += g.x[i * c + j];
        cy += g.y[i * c + j];
        cz += g.z[i * c + j];
      }
      cx /= c;
      cy /= c;
      cz /= c;
      for (var j = 0; j < c; j++) {
        final k = i * c + j;
        final dx = g.x[k] - cx, dy = g.y[k] - cy, dz = g.z[k] - cz;
        r[k] = math.sqrt(dx * dx + dy * dy + dz * dz);
      }
    }
    for (var i = 1; i < n - 1; i++) {
      for (var j = 0; j < c; j++) {
        final k = i * c + j;
        final autour =
            (r[k - c] +
                r[k + c] +
                r[i * c + (j + 1) % c] +
                r[i * c + (j - 1 + c) % c]) /
            4;
        if (autour < 1e-4) continue;
        final creux = (autour - r[k]) / autour;
        g.ao[k] *= (1 - 3 * creux).clamp(0.82, 1.05);
      }
    }
  }

  /// Les FUSEAUX des muscles travaillés, posés sur la peau MAILLÉE (telle
  /// qu'elle est peinte, soudures comprises) : nets, en amande, un rien
  /// au-dessus de la peau, et peints JUSTE APRÈS les cases de peau qu'ils
  /// recouvrent.
  void _fuseaux(_Grille peau, List<_Zone> zones) {
    final rangs = fin ? 11 : 7, cols = fin ? 9 : 5;
    for (final z in zones) {
      final m = _teinteDe(z.$1);
      if (m == null) continue;
      final (_, s0, s1, bords) = z;
      final g = _Grille(rangs, cols, boucle: false);
      final cases = Int32List(rangs * cols);
      // Le dedans : sous le milieu du fuseau.
      final (pm, nm) = peau.surface(
        (s0 + s1) / 2,
        (_hermite(bords, 0.5).$1 + _hermite(bords, 0.5).$2) / 2,
      );
      g.dedans = pm - nm * 0.02;
      for (var i = 0; i < rangs; i++) {
        final u = i / (rangs - 1);
        final s = s0 + (s1 - s0) * u;
        final (b0, b1, _) = _hermite(bords, u);
        for (var j = 0; j < cols; j++) {
          final phi = b0 + (b1 - b0) * j / (cols - 1);
          final k = i * cols + j;
          final (p, n) = peau.surface(s, phi);
          g.poser(k, p + n * 0.0006);
          g.trait[k] = 0;
          cases[k] = peau.caseEn(s, phi);
          // L'ombre de la peau dessous (plis et creux compris).
          g.ao[k] = peau.ao[math.min(cases[k], peau.ao.length - 1)];
        }
      }
      _emettre(g, [m], zImpose: _ancrer(peau, g, cases));
    }
  }

  /// La proximité de chaque case de [g], posée sur [peau] ([cases] : la
  /// case de peau sous chaque sommet) : juste devant la plus proche des
  /// cases de peau sous ses quatre coins.
  static Float64List _ancrer(_Grille peau, _Grille g, Int32List cases) {
    final zp = peau.zCases!;
    final cols = g.cols, qc = g.casesParRang;
    final zq = Float64List((g.rangs - 1) * qc);
    final pq = peau.casesParRang;
    for (var i = 0; i < g.rangs - 1; i++) {
      for (var j = 0; j < qc; j++) {
        final a = i * cols + j, b = a + cols;
        final j1 = (j + 1) % cols;
        final c = (i + 1) * cols + j1, d = i * cols + j1;
        // Toutes les cases de peau entre les coins (une case posée peut en
        // enjamber plusieurs, en rangées comme en colonnes).
        var i0 = 1 << 30, i1 = -1;
        final c0 = cases[a] % pq;
        var o0 = 1 << 30, o1 = -(1 << 30);
        for (final v in [cases[a], cases[b], cases[c], cases[d]]) {
          final r = v ~/ pq;
          if (r < i0) i0 = r;
          if (r > i1) i1 = r;
          var o = peau.boucle ? (v % pq - c0) % pq : v % pq - c0;
          if (peau.boucle && o > pq ~/ 2) o -= pq;
          if (o < o0) o0 = o;
          if (o > o1) o1 = o;
        }
        var z = -double.infinity;
        for (var o = o0; o <= o1; o++) {
          final col = (c0 + o) % pq;
          for (var r = i0; r <= i1; r++) {
            final zz = zp[math.min(r * pq + col, zp.length - 1)];
            if (zz > z) z = zz;
          }
        }
        zq[i * qc + j] = z + 1e-6;
      }
    }
    return zq;
  }

  /// Un ellipsoïde maillé, ses pôles au bout de [a] ; [fonduVers] : son
  /// contour s'efface vers ce pôle (−1 : le pôle −a, une jointure).
  void _ellipsoide(
    V3 centre,
    V3 a,
    V3 b,
    V3 c,
    _Matiere m, {
    double trait = 1,
    double fonduVers = 0,
    bool petit = false,
    int partie = -1,
  }) {
    final rangs = petit ? 5 : (fin ? 7 : 5);
    final cols = petit ? 6 : (fin ? 10 : 7);
    final g = _Grille(rangs, cols);
    for (var i = 0; i < rangs; i++) {
      final lat = -math.pi / 2 + math.pi * i / (rangs - 1);
      final sl = math.sin(lat), cl = math.cos(lat);
      final tr = fonduVers == 0
          ? trait
          : trait * _lisse(-0.95, -0.35, sl * -fonduVers);
      for (var j = 0; j < cols; j++) {
        final lon = 2 * math.pi * j / cols;
        g.poser(
          i * cols + j,
          centre + a * sl + (b * math.cos(lon) + c * math.sin(lon)) * cl,
        );
        g.trait[i * cols + j] = tr;
      }
    }
    _emettre(g, [m], partie: partie);
  }
}

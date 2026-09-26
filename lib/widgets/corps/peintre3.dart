// lib/widgets/corps/peintre3.dart
//
// Le PEINTRE de la scène en 3D : une caméra de TROIS QUARTS (les deux bras
// et les deux jambes se voient), le sol et le mobilier derrière, le CORPS —
// une peau maillée, peinte triangle par triangle du plus loin au plus proche
// (`peau3.dart`) — et le matériel tenu, glissé à sa profondeur parmi les
// triangles du corps (l'haltère de la main loin passe derrière le tronc,
// celui de la main proche devant) : la barre traverse les deux mains avec
// ses disques, les haltères ont leurs plateaux, le banc a son épaisseur, la
// barre fixe ses montants.
//
// Tout est calculé en coordonnées du monde (le carré 0..1) puis mis à
// l'échelle ([cote] pixels).

import 'dart:math' as math;
import 'dart:ui';

import '../../modele/sports/muscles.dart';
import '../../theme/rhythm_couleurs.dart';
import 'corps_humain.dart' show Accessoires, kMarcheHaut, kMarcheProf;
import 'geometrie3.dart';
import 'peau3.dart';
import 'squelette3.dart';

/// La caméra : [lacet] degrés autour de la verticale (0 = profil pur, 90 =
/// de face), autour de l'abscisse [pivot].
class Camera3 {
  const Camera3({this.lacet = 25, this.tangage = 0, this.pivot = 0.5});

  /// La rotation autour de la verticale (0 : de profil pur).
  final double lacet;

  /// La PLONGÉE : de combien la caméra regarde d'en haut (0 : à hauteur
  /// d'homme). Le sol devient un plan — on voit s'écarter les bras et les
  /// jambes d'un corps couché.
  final double tangage;
  final double pivot;

  /// Trois quarts, de côté (le corps tourné vers la droite).
  static const Camera3 profil = Camera3(lacet: 25);

  /// Trois quarts, de face.
  static const Camera3 face = Camera3(lacet: 68);

  /// Trois quarts, de dos (le dos travaille : tractions, rowing).
  static const Camera3 dos = Camera3(lacet: -35);

  /// D'en haut, pour les corps couchés (à plat ventre, sur le dos, sur le
  /// côté).
  static const Camera3 dessus = Camera3(lacet: 16, tangage: 24);

  double get _c => math.cos(rad(lacet));
  double get _s => math.sin(rad(lacet));
  double get _cp => math.cos(rad(tangage));
  double get _sp => math.sin(rad(tangage));

  /// L'axe horizontal de l'écran et la direction vers le spectateur, dans
  /// le monde.
  V3 get ex => V3(_c, 0, -_s);
  V3 get vers => V3(_s * _cp, -_sp, _c * _cp);

  /// La profondeur avant la plongée.
  double _d(V3 p) => (p.x - pivot) * _s + p.z * _c;

  Offset projeter(V3 p) => Offset(
    pivot + (p.x - pivot) * _c - p.z * _s,
    kSol + (p.y - kSol) * _cp + _d(p) * _sp,
  );

  double profondeur(V3 p) => _d(p) * _cp - (p.y - kSol) * _sp;

  /// Une direction du monde, sur l'écran.
  Offset direction(V3 d) =>
      Offset(d.x * _c - d.z * _s, d.y * _cp + (d.x * _s + d.z * _c) * _sp);
}

// ── Couleurs du matériel ────────────────────────────────────────────────────
const Color _contour = Color(0xE6080809);
const Color _metal = Color(0xFFBDBEC6);
const Color _metalSombre = Color(0xFF5B5C63);
const Color _meuble = Color(0xFF44454C);
const Color _meubleClair = Color(0xFF585960);

/// La lumière : d'en haut, à gauche, un peu devant.
final V3 _lumiere = const V3(-0.35, -0.8, 0.5).unite;

class PeintreCorps3 {
  PeintreCorps3({
    required this.cote,
    this.camera = Camera3.profil,
    this.principaux = const {},
    this.secondaires = const {},
    this.respiration = 0,
    this.phase = 0,
  });

  final double cote;
  final Camera3 camera;
  final Set<Muscle> principaux;
  final Set<Muscle> secondaires;

  /// Le souffle (0..1, un cycle) : la poitrine se soulève à peine.
  final double respiration;

  /// L'avancée du cycle de l'animation (la corde qui tourne).
  final double phase;

  late Canvas _c;

  Offset _e(V3 p) => camera.projeter(p) * cote;
  double _z(V3 p) => camera.profondeur(p);

  V3 get _vers => camera.vers;

  // ═══ Le tout ══════════════════════════════════════════════════════════════

  void peindre(Canvas c, Squelette3 s, Accessoires acc) {
    _c = c;
    _sol(acc);
    _mobilier(acc);
    final escalier = acc.escalier;
    if (escalier != null) _escalier(escalier);
    // Le corps : ses triangles, triés.
    final tampon = Tampon3();
    Peau3(
      camera: camera,
      cote: cote,
      principaux: principaux,
      secondaires: secondaires,
      respiration: respiration,
      accessoires: acc,
    ).habiller(s, tampon);
    final ordre = tampon.ordre();
    // Le matériel tenu, chaque pièce à sa profondeur parmi eux.
    final pieces = <(double, void Function())>[];
    void piece(double z, void Function() f) => pieces.add((z, f));
    _materielTenu(s, acc, piece);
    pieces.sort((a, b) => a.$1.compareTo(b.$1));
    var k = 0;
    for (final (z, f) in pieces) {
      var k2 = k;
      while (k2 < ordre.length && tampon.z(ordre[k2]) < z) {
        k2++;
      }
      tampon.peindre(c, ordre, k, k2);
      k = k2;
      f();
    }
    tampon.peindre(c, ordre, k, ordre.length);
    _devant(s, acc);
  }

  // ═══ Les volumes du matériel ═════════════════════════════════════════════

  /// Le modelé d'un volume : clair au centre et du côté de la lumière,
  /// sombre vers les bords (un cylindre), un peu plus sombre au loin.
  void _ombre(Path chemin, Offset a2, Offset b2, Offset n2, V3 n3) {
    final centre = Offset.lerp(a2, b2, 0.5)!;
    final bornes = chemin.getBounds();
    // La demi-largeur du volume, mesurée le long de la normale d'écran.
    var larg = 0.0;
    for (final coin in [
      bornes.topLeft,
      bornes.topRight,
      bornes.bottomLeft,
      bornes.bottomRight,
    ]) {
      larg = math.max(
        larg,
        ((coin - centre).dx * n2.dx + (coin - centre).dy * n2.dy).abs(),
      );
    }
    larg = math.max(larg * 0.72, cote * 0.01);
    Color voile(double l) => l >= 0
        ? const Color(0xFFFFFFFF).withValues(alpha: (l * 0.28).clamp(0, 0.3))
        : const Color(0xFF000000).withValues(alpha: (-l * 0.55).clamp(0, 0.55));
    final lg = n3.dot(_lumiere), ld = (-n3).dot(_lumiere);
    final lc = _vers.dot(_lumiere);
    _c.drawRect(
      bornes.inflate(2),
      Paint()
        ..shader = Gradient.linear(
          centre + n2 * larg,
          centre - n2 * larg,
          [
            voile(lg * 0.5 - 0.42),
            voile(lg * 0.45 + lc * 0.35),
            voile(lc * 0.4),
            voile(ld * 0.4 + lc * 0.1 - 0.05),
            voile(ld * 0.5 - 0.5),
          ],
          const [0.0, 0.3, 0.52, 0.78, 1.0],
        ),
    );
  }

  void _cerner(Path chemin) => _c.drawPath(
    chemin,
    Paint()
      ..color = _contour
      ..style = PaintingStyle.stroke
      ..strokeWidth = cote * 0.0036
      ..strokeJoin = StrokeJoin.round,
  );

  /// Des points sur un ellipsoïde (centre, trois demi-axes).
  List<V3> _ellipsoide(V3 centre, V3 a, V3 b, V3 cc, {int n = 10, int m = 6}) {
    final r = <V3>[];
    for (var i = 0; i < n; i++) {
      final u = 2 * math.pi * i / n;
      for (var j = 1; j < m; j++) {
        final w = math.pi * j / m - math.pi / 2;
        r.add(
          centre +
              a * (math.cos(w) * math.cos(u)) +
              b * (math.cos(w) * math.sin(u)) +
              cc * math.sin(w),
        );
      }
    }
    r
      ..add(centre + cc)
      ..add(centre - cc);
    return r;
  }

  Path _enveloppe(List<V3> pts) =>
      fermeLisse(enveloppe([for (final p in pts) _e(p)]), tension: 0.8);

  /// Un solide convexe (main, disque) : rempli, modelé le long de [axe],
  /// cerné.
  void _solide(List<V3> pts, Color couleur, V3 a, V3 b) {
    final chemin = _enveloppe(pts);
    _c.drawPath(chemin, Paint()..color = couleur);
    _c.save();
    _c.clipPath(chemin);
    final axe = (b - a).unite;
    var n3 = axe.cross(_vers);
    n3 = n3.norme < 1e-3 ? camera.ex : n3.unite;
    var n2 = camera.direction(n3);
    n2 = n2.distance < 1e-6 ? const Offset(1, 0) : n2 / n2.distance;
    _ombre(chemin, _e(a), _e(b), n2, n3);
    _c.restore();
    _cerner(chemin);
  }

  // ═══ Le sol et le mobilier ════════════════════════════════════════════════

  void _sol(Accessoires acc) {
    final mur = acc.mur;
    if (mur != null) {
      final coins = [
        V3(mur, 0.06, -0.4),
        V3(mur, 0.06, 0.4),
        V3(mur, kSol, 0.4),
        V3(mur, kSol, -0.4),
      ];
      _c.drawPath(
        Path()..addPolygon([for (final p in coins) _e(p)], true),
        Paint()..color = const Color(0xFF232328),
      );
      _c.drawLine(
        _e(V3(mur, 0.06, 0.4)),
        _e(V3(mur, kSol, 0.4)),
        Paint()
          ..color = const Color(0xFF3A3A41)
          ..strokeWidth = cote * 0.006,
      );
    }
    final filet = Paint()
      ..color = RhythmCouleurs.filetGrille
      ..strokeWidth = cote * 0.006
      ..strokeCap = StrokeCap.round;
    if (camera.tangage > 0) {
      // Vu d'en haut, le sol est un plan : une nappe à peine plus claire,
      // bordée devant d'un filet.
      final coins = [
        V3(0.04, kSol, -0.34),
        V3(0.96, kSol, -0.34),
        V3(0.96, kSol, 0.34),
        V3(0.04, kSol, 0.34),
      ];
      _c.drawPath(
        Path()..addPolygon([for (final p in coins) _e(p)], true),
        Paint()..color = const Color(0x0DFFFFFF),
      );
      _c.drawLine(_e(coins[3]), _e(coins[2]), filet);
      return;
    }
    final pente = acc.pente ?? 0;
    _c.drawLine(
      Offset(0.05 * cote, (kSol - pente * (0.05 - 0.47)) * cote),
      Offset(0.95 * cote, (kSol - pente * (0.95 - 0.47)) * cote),
      filet,
    );
  }

  /// Une boîte (banc, marche, tapis) : ses faces visibles, ombrées.
  void _boite(
    double x0,
    double x1,
    double y0,
    double y1,
    double z0,
    double z1,
    Color couleur,
  ) {
    V3 p(double x, double y, double z) => V3(x, y, z);
    final faces = <(V3, List<V3>)>[
      (
        const V3(0, 0, 1),
        [p(x0, y0, z1), p(x1, y0, z1), p(x1, y1, z1), p(x0, y1, z1)],
      ),
      (
        const V3(0, 0, -1),
        [p(x0, y0, z0), p(x1, y0, z0), p(x1, y1, z0), p(x0, y1, z0)],
      ),
      (
        const V3(1, 0, 0),
        [p(x1, y0, z0), p(x1, y0, z1), p(x1, y1, z1), p(x1, y1, z0)],
      ),
      (
        const V3(-1, 0, 0),
        [p(x0, y0, z0), p(x0, y0, z1), p(x0, y1, z1), p(x0, y1, z0)],
      ),
    ];
    for (final (n, coins) in faces) {
      if (n.dot(_vers) <= 0.02) continue;
      final l = 0.78 + 0.3 * n.dot(_lumiere);
      final teinte = Color.lerp(
        const Color(0xFF000000),
        couleur,
        l.clamp(0.4, 1.15),
      )!;
      _c.drawPath(
        Path()..addPolygon([for (final q in coins) _e(q)], true),
        Paint()..color = teinte,
      );
    }
    // L'arête du dessus, claire.
    _c.drawLine(
      _e(p(x0, y0, z1)),
      _e(p(x1, y0, z1)),
      Paint()
        ..color = Color.lerp(couleur, const Color(0xFFFFFFFF), 0.18)!
        ..strokeWidth = cote * 0.004,
    );
  }

  /// Le mobilier, derrière le corps : tapis, marche, banc, barre fixe, vélo.
  void _mobilier(Accessoires acc) {
    if (acc.tapis) {
      _boite(
        0.1,
        0.9,
        kSol - 0.012,
        kSol,
        -0.13,
        0.13,
        const Color(0xFF34343A),
      );
    }
    final marche = acc.marche;
    if (marche != null) {
      _boite(marche.left, marche.right, marche.top, kSol, -0.16, 0.16, _meuble);
    }
    final banc = acc.banc;
    if (banc != null) {
      for (final x in [banc.left + 0.05, banc.right - 0.05]) {
        for (final z in [-0.06, 0.06]) {
          _boite(
            x - 0.009,
            x + 0.009,
            banc.top + 0.03,
            kSol,
            z - 0.009,
            z + 0.009,
            _meuble,
          );
        }
      }
      _boite(
        banc.left,
        banc.right,
        banc.top,
        banc.top + 0.035,
        -0.085,
        0.085,
        _meubleClair,
      );
      final dossier = acc.dossier;
      if (dossier != null) {
        final (a, b) = dossier;
        _c.drawLine(
          _e(V3(a.dx, a.dy, 0)),
          _e(V3(b.dx, b.dy, 0)),
          Paint()
            ..color = _meubleClair
            ..strokeWidth = cote * 0.035
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    final fixe = acc.barreFixe;
    if (fixe != null && acc.plateau) {
      // Une table : le plateau part du bord (où sont les mains) vers la
      // tête ; quatre pieds.
      for (final x in [fixe.dx - 0.28, fixe.dx - 0.01]) {
        for (final z in [-0.27, 0.27]) {
          _boite(
            x - 0.01,
            x + 0.01,
            fixe.dy,
            kSol,
            z - 0.01,
            z + 0.01,
            _meuble,
          );
        }
      }
      _boite(
        fixe.dx - 0.3,
        fixe.dx + 0.008,
        fixe.dy - 0.014,
        fixe.dy + 0.016,
        -0.3,
        0.3,
        _meubleClair,
      );
    } else if (fixe != null) {
      final montant = Paint()
        ..color = _meuble
        ..strokeWidth = cote * 0.016
        ..strokeCap = StrokeCap.round;
      for (final z in [-0.26, 0.26]) {
        _c.drawLine(
          _e(V3(fixe.dx, fixe.dy - 0.02, z)),
          _e(V3(fixe.dx, kSol, z)),
          montant,
        );
      }
      _c.drawLine(
        _e(V3(fixe.dx, fixe.dy, -0.28)),
        _e(V3(fixe.dx, fixe.dy, 0.28)),
        Paint()
          ..color = _metal
          ..strokeWidth = cote * 0.012
          ..strokeCap = StrokeCap.round,
      );
    }
    if (acc.velo) _velo(fixe: acc.veloFixe);
  }

  /// L'escalier qui défile : chaque marche, une boîte du dessus de sa
  /// marche jusqu'au sol, coupée aux bords de l'image.
  void _escalier(Offset nez) {
    final o = 2 * phase;
    for (var k = -6; k <= 7; k++) {
      final dessus = nez.dy - kMarcheHaut * (k - o);
      if (dessus >= kSol - 0.002) continue;
      var xa = nez.dx + kMarcheProf * (k - o);
      var xb = xa + kMarcheProf;
      if (xb < 0.1 || xa > 0.82) continue;
      xa = math.max(xa, 0.1);
      xb = math.min(xb, 0.82);
      _boite(xa, xb, dessus, kSol, -0.17, 0.17, _meuble);
    }
  }

  /// Le vélo, de profil ; [fixe] : un vélo d'intérieur — un socle posé au
  /// sol et un volant d'inertie plein à l'avant, pas de roues.
  void _velo({bool fixe = false}) {
    final trait = Paint()
      ..color = _metalSombre
      ..style = PaintingStyle.stroke
      ..strokeWidth = cote * 0.011
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const r = 0.13;
    const arriere = V3(0.26, kSol - r, 0), avant = V3(0.78, kSol - r, 0);
    const pedalier = V3(0.47, kSol - r, 0);
    const selle = V3(0.42, 0.55, 0), guidon = V3(0.7, 0.5, 0);
    if (fixe) {
      _veloFixe(pedalier, selle, guidon);
      return;
    }
    for (final roue in [arriere, avant]) {
      final pts = [
        for (var i = 0; i < 32; i++)
          _e(
            roue +
                V3(
                  math.cos(i * math.pi / 16) * r,
                  math.sin(i * math.pi / 16) * r,
                  0,
                ),
          ),
      ];
      _c.drawPath(Path()..addPolygon(pts, true), trait);
    }
    trait.color = _metal;
    Offset e(V3 p) => _e(p);
    final cadre = Path()
      ..moveTo(e(arriere).dx, e(arriere).dy)
      ..lineTo(e(pedalier).dx, e(pedalier).dy)
      ..lineTo(e(selle).dx, e(selle).dy)
      ..lineTo(e(arriere).dx, e(arriere).dy)
      ..moveTo(e(selle).dx, e(selle).dy)
      ..lineTo(e(guidon).dx, e(guidon).dy)
      ..lineTo(e(pedalier).dx, e(pedalier).dy)
      ..moveTo(e(guidon).dx, e(guidon).dy)
      ..lineTo(e(avant).dx, e(avant).dy);
    _c.drawPath(cadre, trait);
    _c.drawLine(
      e(guidon + const V3(0, 0, 0.08)),
      e(guidon - const V3(0, 0, 0.08)),
      trait,
    );
    _c.drawLine(
      e(selle - const V3(0.035, 0, 0)),
      e(selle + const V3(0.035, 0, 0)),
      Paint()
        ..color = _metal
        ..strokeWidth = cote * 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  void _veloFixe(V3 pedalier, V3 selle, V3 guidon) {
    // Le socle : deux pieds posés en travers, reliés par une poutre.
    for (final x in [0.3, 0.72]) {
      _boite(x - 0.03, x + 0.03, kSol - 0.02, kSol, -0.13, 0.13, _meuble);
    }
    _boite(0.3, 0.72, kSol - 0.045, kSol - 0.02, -0.018, 0.018, _meuble);
    final trait = Paint()
      ..color = _metal
      ..style = PaintingStyle.stroke
      ..strokeWidth = cote * 0.013
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset e(V3 p) => _e(p);
    const volant = V3(0.66, kSol - 0.11, 0);
    // Le volant d'inertie : un disque plein, à l'avant.
    _disque(volant, V3.proche, 0.085, 0.03, _metalSombre);
    final cadre = Path()
      ..moveTo(
        e(const V3(0.34, kSol - 0.045, 0)).dx,
        e(const V3(0.34, kSol - 0.045, 0)).dy,
      )
      ..lineTo(e(selle).dx, e(selle).dy)
      ..moveTo(e(pedalier).dx, e(pedalier).dy)
      ..lineTo(e(volant).dx, e(volant).dy)
      ..moveTo(
        e(const V3(0.66, kSol - 0.045, 0)).dx,
        e(const V3(0.66, kSol - 0.045, 0)).dy,
      )
      ..lineTo(e(guidon).dx, e(guidon).dy)
      ..moveTo(e(pedalier).dx, e(pedalier).dy)
      ..lineTo(
        e(V3.lerp(selle, const V3(0.34, kSol - 0.045, 0), 0.5)).dx,
        e(V3.lerp(selle, const V3(0.34, kSol - 0.045, 0), 0.5)).dy,
      );
    _c.drawPath(cadre, trait);
    _c.drawLine(
      e(guidon + const V3(0, 0, 0.08)),
      e(guidon - const V3(0, 0, 0.08)),
      trait,
    );
    _c.drawLine(
      e(selle - const V3(0.035, 0, 0)),
      e(selle + const V3(0.035, 0, 0)),
      Paint()
        ..color = _metal
        ..strokeWidth = cote * 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  // ═══ Le matériel tenu ═════════════════════════════════════════════════════

  void _materielTenu(
    Squelette3 s,
    Accessoires acc,
    void Function(double, void Function()) piece,
  ) {
    for (final c in chargesTenues(s, acc)) {
      switch (c) {
        case HaltereTenu(:final centre, :final axe):
          _haltere(centre, axe, piece);
        case BarreTenue(:final centre, :final axe):
          _barre(centre, axe, piece);
        case KettlebellTenue(:final prise, :final bas, :final axePoignee):
          final boule = c.boule;
          piece(_z(boule) - 0.004, () {
            final pts = _ellipsoide(
              boule,
              V3.avant * 0.038,
              V3.proche * 0.038,
              V3.bas * 0.036,
            );
            _solide(
              pts,
              _metalSombre,
              boule - V3.bas * 0.03,
              boule + V3.bas * 0.03,
            );
            final p0 = _e(boule - axePoignee * 0.024 - bas * 0.02);
            final p1 = _e(prise - bas * 0.01);
            final p2 = _e(boule + axePoignee * 0.024 - bas * 0.02);
            _c.drawPath(
              Path()
                ..moveTo(p0.dx, p0.dy)
                ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy),
              Paint()
                ..color = _metalSombre
                ..style = PaintingStyle.stroke
                ..strokeWidth = cote * 0.011,
            );
          });
        case BallonTenu(:final centre):
          piece(_z(centre), () {
            final pts = _ellipsoide(
              centre,
              V3.avant * 0.05,
              V3.proche * 0.05,
              V3.bas * 0.05,
            );
            _solide(
              pts,
              const Color(0xFF6E6E78),
              centre - V3.bas * 0.05,
              centre + V3.bas * 0.05,
            );
          });
      }
    }
    final fixe = acc.barreFixe;
    if (acc.bandeTraction && fixe != null) {
      // L'élastique d'assistance : noué à la barre, il descend en boucle
      // sous le genou proche — devant le corps, trié parmi ses triangles.
      final genou = s.jambeP.milieu + V3.bas * 0.02;
      final trait = Paint()
        ..color = RhythmCouleurs.menthe.withValues(alpha: 0.9)
        ..strokeWidth = cote * 0.008
        ..strokeCap = StrokeCap.round;
      for (final dz in [-0.022, 0.022]) {
        final a = V3(fixe.dx, fixe.dy + 0.006, dz), b = genou + V3.proche * dz;
        const n = 12;
        for (var i = 0; i < n; i++) {
          final u = V3.lerp(a, b, i / n), v = V3.lerp(a, b, (i + 1) / n);
          piece(_z(V3.lerp(u, v, 0.5)), () => _c.drawLine(_e(u), _e(v), trait));
        }
      }
    }
    if (acc.sac) _sac(s, piece);
    final e = acc.elastique;
    if (e != null) {
      _elastique(
        s,
        acc,
        e,
        repereMain(s, true, acc),
        repereMain(s, false, acc),
        piece,
      );
    }
  }

  /// L'ÉLASTIQUE, d'une attache à chaque poignée, en tronçons triés parmi
  /// les triangles du corps (il passe derrière la tête, sous le bras). Au
  /// sol, sous les pieds : une seule attache. Accroché plus haut (porte,
  /// poteau) : une attache par main, en face d'elle ; derrière le corps,
  /// hors des épaules — il longe le corps au lieu de le traverser.
  void _elastique(
    Squelette3 s,
    Accessoires acc,
    Offset e,
    RepereMain mainP,
    RepereMain mainL,
    void Function(double, void Function()) piece,
  ) {
    final auSol = e.dy > kSol - 0.12;
    final trait = Paint()
      ..color = RhythmCouleurs.menthe.withValues(alpha: 0.9)
      ..strokeWidth = cote * 0.007
      ..strokeCap = StrokeCap.round;
    for (final (b, m, sens) in [
      (s.brasP, mainP, 1.0),
      (s.brasL, mainL, -1.0),
    ]) {
      final main = m.poignee;
      var z = acc.elastiqueZ ?? (auSol ? 0.0 : main.z);
      final epaule = b.racine;
      final derriere = (V3(e.dx, e.dy, epaule.z) - epaule).dot(s.avantEpaules);
      if (acc.elastiqueZ == null && !auSol && derriere < 0) {
        final hors = epaule.z + sens * 0.045;
        z = sens > 0 ? math.max(z, hors) : math.min(z, hors);
      }
      final ancre = V3(e.dx, e.dy, z);
      const n = 10;
      for (var i = 0; i < n; i++) {
        final u = V3.lerp(ancre, main, i / n);
        final v = V3.lerp(ancre, main, (i + 1) / n);
        piece(_z(V3.lerp(u, v, 0.5)), () => _c.drawLine(_e(u), _e(v), trait));
      }
    }
  }

  /// Le SAC À DOS : un volume arrondi collé au haut du dos, entre les
  /// omoplates, et ses bretelles sur les épaules.
  void _sac(Squelette3 s, void Function(double, void Function()) piece) {
    final centre = V3.lerp(s.bassin, s.cou, 0.62) - s.avantEpaules * 0.078;
    final pts = _ellipsoide(
      centre,
      s.dirTronc * 0.085,
      s.lateralEpaules * 0.06,
      s.avantEpaules * 0.036,
    );
    piece(_z(centre), () {
      _solide(
        pts,
        const Color(0xFF4A5A6E),
        centre - s.dirTronc * 0.085,
        centre + s.dirTronc * 0.085,
      );
    });
    final bretelle = Paint()
      ..color = const Color(0xFF3A4757)
      ..strokeWidth = cote * 0.009
      ..strokeCap = StrokeCap.round;
    for (final b in [s.brasP, s.brasL]) {
      final a = b.racine - s.avantEpaules * 0.02 + s.dirTronc * 0.02;
      final c = b.racine + s.avantEpaules * 0.035 - s.dirTronc * 0.075;
      piece(
        _z(V3.lerp(a, c, 0.5)) + 0.01,
        () => _c.drawLine(_e(a), _e(c), bretelle),
      );
    }
  }

  void _haltere(
    V3 centre,
    V3 axe,
    void Function(double, void Function()) piece,
  ) {
    for (final sens in [1.0, -1.0]) {
      final plateau = centre + axe * (0.046 * sens);
      piece(_z(plateau), () => _disque(plateau, axe, 0.028, 0.02, _metal));
    }
    // La poignée, en trois tronçons triés chacun à sa profondeur (le poing
    // la recouvre, pas le bras qui passe derrière).
    for (var i = 0; i < 3; i++) {
      final u = centre + axe * (0.046 * (2 * i / 3 - 1));
      final v = centre + axe * (0.046 * (2 * (i + 1) / 3 - 1));
      piece(_z(V3.lerp(u, v, 0.5)) - 0.002, () {
        _c.drawLine(
          _e(u),
          _e(v),
          Paint()
            ..color = _metalSombre
            ..strokeWidth = cote * 0.012
            ..strokeCap = StrokeCap.round,
        );
      });
    }
  }

  void _barre(V3 centre, V3 axe, void Function(double, void Function()) piece) {
    // La barre, en tronçons triés chacun à sa profondeur (une barre qui
    // passe devant les cuisses ou la poitrine n'y entre pas), et ses
    // disques.
    const n = 8;
    for (final sens in [1.0, -1.0]) {
      for (var i = 0; i < n; i++) {
        final u = centre + axe * (0.3 * sens * i / n);
        final v = centre + axe * (0.3 * sens * (i + 1) / n);
        piece(_z(V3.lerp(u, v, 0.5)) - 0.001, () {
          _c.drawLine(
            _e(u),
            _e(v),
            Paint()
              ..color = _metal
              ..strokeWidth = cote * 0.01
              ..strokeCap = StrokeCap.round,
          );
        });
      }
      final disque = centre + axe * (0.235 * sens);
      piece(_z(disque), () => _disque(disque, axe, 0.072, 0.03, _metalSombre));
    }
  }

  /// Un disque (plateau d'haltère, disque de barre) : un cylindre court.
  void _disque(
    V3 centre,
    V3 axe,
    double rayon,
    double epaisseur,
    Color couleur,
  ) {
    var u = axe.cross(V3.bas);
    if (u.norme < 1e-3) u = axe.cross(V3.avant);
    u = u.unite;
    final w = axe.cross(u).unite;
    final pts = <V3>[];
    for (final e in [-epaisseur / 2, epaisseur / 2]) {
      for (var i = 0; i < 20; i++) {
        final a = 2 * math.pi * i / 20;
        pts.add(
          centre +
              axe * e +
              u * (math.cos(a) * rayon) +
              w * (math.sin(a) * rayon),
        );
      }
    }
    final chemin = _enveloppe(pts);
    _c.drawPath(chemin, Paint()..color = couleur);
    // La face tournée vers le spectateur, plus claire.
    final face = axe.dot(_vers) >= 0 ? epaisseur / 2 : -epaisseur / 2;
    final rond = [
      for (var i = 0; i < 20; i++)
        _e(
          centre +
              axe * face +
              u * (math.cos(2 * math.pi * i / 20) * rayon * 0.9) +
              w * (math.sin(2 * math.pi * i / 20) * rayon * 0.9),
        ),
    ];
    _c.drawPath(
      fermeLisse(rond, tension: 0.7),
      Paint()..color = Color.lerp(couleur, const Color(0xFFFFFFFF), 0.14)!,
    );
    _c.drawCircle(
      _e(centre + axe * face),
      cote * rayon * 0.2,
      Paint()..color = _metalSombre,
    );
    _cerner(chemin);
  }

  /// Ce qui passe devant tout : l'élastique, la corde.
  void _devant(Squelette3 s, Accessoires acc) {
    final elastique = Paint()
      ..color = RhythmCouleurs.menthe.withValues(alpha: 0.9)
      ..strokeWidth = cote * 0.007
      ..strokeCap = StrokeCap.round;
    if (acc.bandeMains) {
      _c.drawLine(
        _e(s.brasP.extremite),
        _e(s.brasL.extremite),
        elastique..strokeWidth = cote * 0.011,
      );
    }
    if (acc.bandeGenoux) {
      V3 sous(Membre3 j) => V3.lerp(j.milieu, j.bout, 0.18);
      _c.drawLine(
        _e(sous(s.jambeP)),
        _e(sous(s.jambeL)),
        Paint()
          ..color = RhythmCouleurs.menthe.withValues(alpha: 0.9)
          ..strokeWidth = cote * 0.012
          ..strokeCap = StrokeCap.round,
      );
    }
    if (acc.corde) {
      final a = s.brasP.extremite, b = s.brasL.extremite;
      final axe = (a - b).unite;
      final milieu = V3.lerp(a, b, 0.5);
      final rayon = (kSol + 0.01 - milieu.y).abs();
      final ang = 2 * math.pi * phase * (acc.cordeDouble ? 2 : 1);
      final bas = V3.bas.tourne(axe, ang).sansComposante(axe).unite;
      final pts = <Offset>[];
      for (var i = 0; i <= 24; i++) {
        final u = math.pi * i / 24;
        final p = V3.lerp(a, b, i / 24) + bas * (math.sin(u) * rayon);
        pts.add(_e(p));
      }
      _c.drawPath(
        Path()..addPolygon(pts, false),
        Paint()
          ..color = const Color(0xFFCFCFD6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cote * 0.005
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

// ═══ La géométrie du matériel tenu ═════════════════════════════════════════
//
// Partagée par le peintre et par le contrôle du matériel qui entre dans le
// corps (`test/outils/collisions_corps_test.dart`).

/// Une charge tenue.
sealed class Charge {
  const Charge();
}

/// Un haltère : son centre et l'axe de sa poignée (plateaux à ±
/// [demiHaltere], de rayon [rayonPlateau]).
class HaltereTenu extends Charge {
  const HaltereTenu(this.centre, this.axe);
  final V3 centre, axe;
}

/// Une barre : son centre et son axe (± [demiBarre], disques de rayon
/// [rayonDisque] à ± [placeDisque]).
class BarreTenue extends Charge {
  const BarreTenue(this.centre, this.axe);
  final V3 centre, axe;
}

/// Une kettlebell : la poignée, la direction de la boule, l'axe de la
/// poignée.
class KettlebellTenue extends Charge {
  const KettlebellTenue(this.prise, this.bas, this.axePoignee);
  final V3 prise, bas, axePoignee;

  /// Le centre de la boule (de rayon [rayonBoule]).
  V3 get boule => prise + bas * 0.05;
}

/// Un médecine-ball tenu à deux mains.
class BallonTenu extends Charge {
  const BallonTenu(this.centre);
  final V3 centre;
}

const double demiHaltere = 0.046, rayonPlateau = 0.028;
const double demiBarre = 0.3, placeDisque = 0.235, rayonDisque = 0.072;
const double rayonBoule = 0.037, rayonBallon = 0.05;

/// De combien la main est levée plus haut que le poignet (0 : doigts à
/// l'horizontale ou vers le bas, 1 : vers le haut) — une charge tenue pend
/// alors sous la main au lieu de prolonger le bras.
double _levee(V3 axe) {
  final u = ((-axe.dot(V3.bas) + 0.15) / 0.6).clamp(0.0, 1.0);
  return u * u * (3 - 2 * u);
}

/// Les charges que tient le corps [s] : chacune DANS LE POING (le repère
/// de chaque main).
List<Charge> chargesTenues(Squelette3 s, Accessoires acc) {
  final r = <Charge>[];
  final mainP = repereMain(s, true, acc), mainL = repereMain(s, false, acc);
  if (acc.halteres || acc.haltereUne) {
    for (final m in acc.halteres ? [mainP, mainL] : [mainP]) {
      r.add(HaltereTenu(m.poignee, m.axePoignee));
    }
  }
  if (acc.goblet) {
    // UN haltère tenu à deux mains jointes, par le plateau du haut : il
    // PEND sous les paumes (goblet, au-dessus de la tête, entre les
    // jambes) ; bras tendus devant (swing), il file dans leur
    // prolongement.
    var axe = mainP.axe + mainL.axe;
    axe = axe.norme < 1e-3 ? V3.bas : axe.unite;
    final d = V3.lerp(axe, V3.bas, _levee(axe)).unite;
    r.add(
      HaltereTenu(V3.lerp(mainP.poignee, mainL.poignee, 0.5) + d * 0.036, d),
    );
  }
  if (acc.haltereTravers) {
    // UN haltère en travers, une main sur chaque bout (sur les hanches).
    final a = mainP.poignee, b = mainL.poignee;
    final axe = (a - b).norme < 1e-3 ? s.lateralBassin : (a - b).unite;
    r.add(HaltereTenu(V3.lerp(a, b, 0.5), axe));
  }
  if (acc.barre) {
    final centre = V3.lerp(mainP.poignee, mainL.poignee, 0.5);
    var axe = mainP.poignee - mainL.poignee;
    axe = axe.norme < 0.08 ? s.lateralEpaules : axe.unite;
    r.add(BarreTenue(centre, axe));
  }
  if (acc.barreDos) {
    final centre =
        V3.lerp(s.brasP.racine, s.brasL.racine, 0.5) -
        s.avantEpaules * 0.055 +
        s.dirTronc * 0.014;
    r.add(BarreTenue(centre, s.lateralEpaules));
  }
  final ensemble =
      acc.kettlebell && (s.brasP.extremite - s.brasL.extremite).norme < 0.1;
  for (final (m, sens) in [
    if (acc.kettlebell || acc.kettlebells) (mainP, 1.0),
    if (acc.kettlebells) (mainL, -1.0),
  ]) {
    final prise = ensemble
        ? V3.lerp(mainP.poignee, mainL.poignee, 0.5)
        : m.poignee;
    // La boule pend dans le prolongement du bras (bras le long du corps,
    // swing). La main levée plus haut que le poignet : tenue à deux mains
    // par les cornes, elle pend sous les mains ; d'une main (rack,
    // développé), elle repose sur le DEHORS de l'avant-bras, sous la
    // poignée — jamais dans l'épaule.
    final leve = _levee(m.axe);
    final repos = ensemble
        ? (V3.bas * 0.8 + s.avantEpaules * 0.6).unite
        : (s.lateralEpaules * (0.85 * sens) -
                  s.avantEpaules * 0.25 -
                  m.axe * 0.6)
              .unite;
    r.add(
      KettlebellTenue(prise, V3.lerp(m.axe, repos, leve).unite, m.axePoignee),
    );
  }
  if (acc.ballon) {
    r.add(BallonTenu(V3.lerp(s.brasP.extremite, s.brasL.extremite, 0.5)));
  }
  return r;
}

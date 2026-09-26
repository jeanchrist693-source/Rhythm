// lib/widgets/corps/mouvements/distincts.dart
//
// Les exercices qui partageaient le mouvement d'un autre et ne s'en
// distinguaient pas (retour de l'utilisateur, 26 sept. 2026 : « fente aux
// haltères et fente marchée aux haltères, on ne voit aucune différence ») :
// chacun reçoit ici ce qui le fait reconnaître — le sens du pas (fente
// avant, arrière, croisée, marchée), le tempo (pause, tempo), la prise
// (marteau, Zottman, supination, poignets inversés, Arnold), la charge
// tenue à deux mains (une kettlebell, un haltère goblet ou en travers),
// une jambe (chaise, mollets), la corde qui passe deux fois.

part of '../animations_corps.dart';

/// La même animation, chaque pose retouchée par [f] (et, au besoin, un
/// autre matériel ou une autre caméra).
AnimCorps _retoucher(
  AnimCorps a,
  Pose3 Function(Pose3 p) f, {
  Accessoires? accessoires,
  Camera3? camera,
}) => AnimCorps(
  [
    for (final c in a.cles)
      Cle(f(c.pose), duree: c.duree, courbe: c.courbe, tenue: c.tenue),
  ],
  camera: camera ?? a.camera,
  accessoires: accessoires ?? a.accessoires,
);

/// La même animation, la clé [i] arrivant en [duree] secondes et tenue
/// [tenue] secondes.
AnimCorps _tempo(AnimCorps a, int i, {double? duree, double? tenue}) =>
    AnimCorps(
      [
        for (var k = 0; k < a.cles.length; k++)
          k == i
              ? Cle(
                  a.cles[k].pose,
                  duree: duree ?? a.cles[k].duree,
                  courbe: a.cles[k].courbe,
                  tenue: tenue ?? a.cles[k].tenue,
                )
              : a.cles[k],
      ],
      camera: a.camera,
      accessoires: a.accessoires,
    );

/// Les deux avant-bras tournés de [degres] (la pronation, `Pose3`).
Pose3 _prono(Pose3 p, double degres) =>
    p.copier(pronationP: degres, pronationL: degres);

// ── Les fentes ─────────────────────────────────────────────────────────────

/// La FENTE AVANT : pieds joints en arrière, la jambe proche fait un grand
/// pas EN AVANT, on descend, puis on repousse le sol pour revenir aux pieds
/// joints — le corps avance et recule (dans la fente arrière, c'est la
/// jambe de derrière qui part).
AnimCorps _fenteAvant({
  Pose3 Function(Pose3)? bras,
  Accessoires accessoires = const Accessoires(),
}) {
  Pose3 b(Pose3 p) => bras == null ? p : bras(p);
  const xArriere = 0.3, xAvant = 0.66;
  final debout = b(_pieds(_pose, xArriere).copier(x: xArriere));
  final pas = b(
    _pieds(
      _pose,
      0.48,
      xL: xArriere,
      hP: 0.07,
    ).copier(x: 0.35, y: 0.5, tronc: -86, piedP: -10),
  );
  final pose = b(
    _fente(avantP: true, bas: false, xAvant: xAvant, xArriere: xArriere),
  );
  final bas = b(
    _fente(avantP: true, bas: true, xAvant: xAvant, xArriere: xArriere),
  );
  return _suite([
    Cle(debout, duree: 0.45, tenue: 0.35),
    Cle(pas, duree: 0.3),
    Cle(pose, duree: 0.3, courbe: Courbe.lancee),
    Cle(bas, duree: 0.9, tenue: 0.2),
    Cle(pose, duree: 0.6, courbe: Courbe.explosive),
    Cle(pas, duree: 0.35),
  ], accessoires: accessoires);
}

/// La FENTE CROISÉE (révérence) : la jambe loin recule en diagonale et se
/// CROISE derrière la jambe proche ; vue de trois quarts face pour que le
/// croisement se voie.
AnimCorps _fenteCroisee() {
  const z = 0.17;
  final debout = _pieds(_pose, 0.52).copier(x: 0.52);
  final pas = _pieds(
    _pose,
    0.52,
    xL: 0.4,
    hL: 0.07,
    zL: z * 0.6,
  ).copier(x: 0.5, y: 0.5, tronc: -86, piedL: 20);
  final pose = _fente(
    avantP: true,
    bas: false,
    xAvant: 0.52,
    xArriere: 0.26,
    zArriere: z,
  ).copier(x: 0.45);
  final bas = _fente(
    avantP: true,
    bas: true,
    xAvant: 0.52,
    xArriere: 0.26,
    zArriere: z,
  ).copier(x: 0.43, y: 0.66);
  return _suite([
    Cle(debout, duree: 0.35, tenue: 0.4),
    Cle(pas, duree: 0.35),
    Cle(pose, duree: 0.3),
    Cle(bas, duree: 1.0, tenue: 0.25),
    Cle(pose, duree: 0.7, courbe: Courbe.explosive),
    Cle(pas, duree: 0.3),
  ], camera: Camera3.face);
}

/// Les FENTES MARCHÉES : on avance de fente en fente, une jambe puis
/// l'autre, sans revenir pieds joints. Le corps reste au milieu de l'image
/// et le SOL DÉFILE (comme la marche et la course) : le pied posé recule à
/// vitesse constante, celui de derrière repasse devant, genou qui monte.
AnimCorps _fentesMarchees({
  Pose3 Function(Pose3)? bras,
  Accessoires accessoires = const Accessoires(),
  double duree = 3.2,
  int n = 24,
}) {
  const h = 0.45;
  // Le sol recule de 0,72 par cycle (deux fentes) ; un pied est posé 72 %
  // du cycle, en l'air le reste.
  const vitesse = 0.72, pose = 0.725, devant = 0.265;
  double lisse(double a, double b, double t) {
    final u = t.clamp(0.0, 1.0);
    return a + (b - a) * (u * u * (3 - 2 * u));
  }

  (double, double, double) pied(double u) {
    u %= 1;
    if (u < pose) {
      final x = h + devant - vitesse * u;
      // Derrière la hanche, le talon se lève : sur la pointe.
      final angle = ((h - 0.02 - x) / 0.15).clamp(0.0, 1.0) * 62;
      return (x, 0.085 * math.sin(rad(angle)) * 0.9, angle);
    }
    final v = (u - pose) / (1 - pose);
    final x0 = h + devant - vitesse * pose;
    final x = lisse(x0, h + devant, v);
    return (
      x,
      0.075 * math.sin(math.pi * math.pow(v, 0.8)),
      lisse(62, -8, v * 1.3),
    );
  }

  double hanche(double v) {
    // Une fente : on descend, on remonte en passant la jambe, on se pose.
    if (v < 0.25) return lisse(0.55, 0.675, v / 0.25);
    if (v < 0.7) return lisse(0.675, 0.505, (v - 0.25) / 0.45);
    return lisse(0.505, 0.55, (v - 0.7) / 0.3);
  }

  Pose3 a(double u) {
    final (xp, hp, ap) = pied(u);
    final (xl, hl, al) = pied(u + 0.5);
    final v = (u * 2) % 1;
    // Le bras opposé à la jambe de devant balance vers l'avant.
    final devantP = u < 0.5;
    final p = _pose.copier(
      x: h,
      y: hanche(v),
      tronc: -86 + 2 * math.sin(math.pi * v),
      piedCibleP: Cible(xp, yCheville - hp, 0.06),
      piedCibleL: Cible(xl, yCheville - hl, -0.06),
      piedP: ap,
      piedL: al,
      genouP: const V3(1, 0.1, 0.1),
      genouL: const V3(1, 0.1, -0.1),
      brasP: devantP ? 104 : 72,
      avantBrasP: devantP ? 96 : 40,
      brasL: devantP ? 72 : 104,
      avantBrasL: devantP ? 40 : 96,
    );
    return bras == null ? p : bras(p);
  }

  return AnimCorps([
    for (var i = 0; i < n; i++)
      Cle(a(i / n), duree: duree / n, courbe: Courbe.reguliere),
  ], accessoires: accessoires);
}

// ── Les charges ────────────────────────────────────────────────────────────

/// Les mains AUX ÉPAULES, en rack (haltères posés sur les épaules, barre
/// sur l'avant des épaules) : elles suivent le tronc, écartées de [z],
/// avancées de [avance] ; les coudes devant, un peu relevés ([coude]).
Pose3 _rack(
  Pose3 p, {
  double z = 0.12,
  double avance = 0.06,
  double haut = 0.005,
  V3 coude = const V3(1, 0.4, 0.5),
}) {
  final t = rad(p.tronc);
  final av = rad(p.tronc + 90);
  final x = p.x + math.cos(t) * (_lEpaule + haut) + math.cos(av) * avance;
  final y = p.y + math.sin(t) * (_lEpaule + haut) + math.sin(av) * avance;
  return p.copier(
    mainP: Cible(x, y, z),
    mainL: Cible(x, y, -z),
    coudeP: coude,
    coudeL: V3(coude.x, coude.y, -coude.z),
  );
}

/// Une BARRE tenue bras pendants, contre l'avant des cuisses (ou des
/// tibias) au lieu de passer dedans : les mains, écartées de [z], à la
/// hauteur où elles pendent, juste devant la jambe la plus avancée.
Pose3 _barreDevantJambes(Pose3 p, {double z = 0.14, double? y}) {
  final s = Squelette3.de(p);
  final h = y ?? (s.brasP.extremite.y + s.brasL.extremite.y) / 2;
  var devant = -1.0;
  for (final j in [s.jambeP, s.jambeL]) {
    for (final (a, b, r) in [
      (j.racine, j.milieu, 0.046),
      (j.milieu, j.bout, 0.033),
    ]) {
      if ((h - a.y) * (h - b.y) > 0) continue;
      final u = (h - a.y) / (b.y - a.y);
      devant = math.max(devant, a.x + (b.x - a.x) * u + r);
    }
  }
  if (devant < 0) devant = s.bassin.x + 0.05;
  // La poignée est dans le poing : la paume, un peu en deçà.
  final x = devant + 0.012;
  return p.copier(
    mainP: Cible(x, h, z),
    mainL: Cible(x, h, -z),
    coudeP: const V3(-0.3, 1, 0.3),
    coudeL: const V3(-0.3, 1, -0.3),
  );
}

/// Le hip thrust : les mains posées sur les hanches, écartées de [z], la
/// charge dessus (un haltère en travers, une barre).
Pose3 _mainsSurHanches(
  Pose3 p, {
  double z = 0.046,
  double haut = 0.085,
  double versCuisses = 0.02,
}) {
  final s = Squelette3.de(p);
  final c = s.bassin + s.avantBassin * haut - s.dirTronc * versCuisses;
  return p.copier(
    mainP: Cible(c.x, c.y, c.z + z),
    mainL: Cible(c.x, c.y, c.z - z),
    coudeP: const V3(-0.2, -0.6, 1),
    coudeL: const V3(-0.2, -0.6, -1),
  );
}

/// La MONTÉE D'ESCALIERS, sur place : l'escalier descend de deux marches
/// par cycle (le peintre le fait défiler, `Accessoires.escalier`) ; chaque
/// pied se pose au milieu d'une marche, descend avec elle, puis monte se
/// poser deux marches plus haut. La hanche ne bouge presque pas.
const Offset _nezEscalier = Offset(0.3825, kSol - 0.12);

AnimCorps _escaliers({double duree = 1.5, int n = 16}) {
  const run = kMarcheProf, rise = kMarcheHaut;
  const x0 = 0.3825, y0 = kSol - 0.12;
  const pose = 0.62;
  const hanche = 0.47;
  const dessus = kSol - yCheville;
  double lisse(double a, double b, double t) {
    final u = t.clamp(0.0, 1.0);
    return a + (b - a) * (u * u * (3 - 2 * u));
  }

  // Un pied posé en u = 0 sur la marche 1 (le pied proche), l'autre en
  // u = 0,5 sur la marche 0 décalée d'une marche : même endroit du monde.
  (double, double, double) pied(double u) {
    u %= 1;
    if (u < pose) {
      final o = 2 * u;
      final x = x0 + run * (1.5 - o);
      final y = y0 - rise * (1 - o) - dessus;
      // Le talon se lève avant de décoller.
      final angle = u > pose - 0.15 ? 26 * (u - (pose - 0.15)) / 0.15 : 0.0;
      return (x, y - 0.03 * math.sin(rad(angle)), angle);
    }
    final v = (u - pose) / (1 - pose);
    final xa = x0 + run * (1.5 - 2 * pose);
    final ya = y0 - rise * (1 - 2 * pose) - dessus;
    final xb = x0 + run * 1.5;
    final yb = y0 - rise - dessus;
    return (
      lisse(xa, xb, v),
      lisse(ya, yb, v) - 0.05 * math.sin(math.pi * v),
      lisse(26, -6, v),
    );
  }

  Pose3 a(double u) {
    final (xp, yp, ap) = pied(u);
    final (xl, yl, al) = pied(u + 0.5);
    final b = math.cos(2 * math.pi * u);
    return _pose.copier(
      x: hanche,
      y: y0 - dessus - 0.4 + 0.006 * math.cos(4 * math.pi * u),
      tronc: -84,
      piedCibleP: Cible(xp, yp, 0.055),
      piedCibleL: Cible(xl, yl, -0.055),
      piedP: ap,
      piedL: al,
      genouP: const V3(1, -0.2, 0.1),
      genouL: const V3(1, -0.2, -0.1),
      brasP: 90 + 22 * b,
      brasL: 90 - 22 * b,
      avantBrasP: 76 + 28 * b,
      avantBrasL: 76 - 28 * b,
      ecartBrasP: 8,
      ecartBrasL: 8,
    );
  }

  return AnimCorps([
    for (var i = 0; i < n; i++)
      Cle(a(i / n), duree: duree / n, courbe: Courbe.reguliere),
  ], accessoires: const Accessoires(escalier: _nezEscalier));
}

// ── Les mouvements ─────────────────────────────────────────────────────────

final Map<String, AnimCorps> _distincts3 = {
  // ══ MATÉRIEL ═══════════════════════════════════════════════════════════
  // Le bord d'une table au lieu d'une barre.
  'tirage_table': _retoucher(
    _tirage3['traction_australienne']!,
    (p) => p,
    accessoires: const Accessoires(barreFixe: _barreBasse, plateau: true),
  ),
  // L'élastique d'assistance, noué à la barre, sous le genou.
  'traction_elastique': _retoucher(
    _tirage3['traction']!,
    (p) => p,
    accessoires: const Accessoires(barreFixe: _barreHaute, bandeTraction: true),
  ),
  'escaliers': _escaliers(),
  // Un vélo d'intérieur (socle, volant d'inertie) au lieu du vélo de route.
  'velo_interieur': _retoucher(
    _cardio3['velo']!,
    (p) => p,
    accessoires: const Accessoires(velo: true, veloFixe: true),
  ),
  // En randonnée : le sac au dos, la pente plus douce, le pas plus long et
  // plus lent que la marche en côte.
  'randonnee': _allure(
    duree: 1.35,
    pas: 0.13,
    tronc: -82,
    bras: 20,
    coude: 24,
    yHanche: hDebout + 0.006,
    retouche: (p, u) => _surLaPente(p, 0.06),
    accessoires: const Accessoires(pente: 0.06, sac: true),
  ),
  // ══ CHARGES ════════════════════════════════════════════════════════════
  // La barre sur l'avant des épaules, coudes hauts, buste droit.
  // La barre posée sur l'avant des épaules, les mains juste devant elles,
  // les coudes pointés vers l'avant (ils se croisaient devant le visage).
  'squat_avant': _serie(
    _rack(
      _largeur(_pose, z: 0.08),
      z: 0.09,
      avance: 0.04,
      haut: 0.04,
      coude: const V3(1, 0.7, 0.12),
    ),
    _rack(
      _largeur(_pose, z: 0.08).copier(x: 0.37, y: 0.72, tronc: -68, dos: 1),
      z: 0.09,
      avance: 0.04,
      haut: 0.04,
      coude: const V3(1, 0.7, 0.12),
    ),
    ab: 1.7,
    ba: 1.1,
    tenueA: 0.5,
    tenueB: 0.15,
    accessoires: const Accessoires(barre: true),
  ),
  // Les haltères posés sur les épaules, puis poussés au-dessus de la tête.
  'thruster': _suite([
    Cle(_rack(_largeur(_pose), z: 0.13), duree: 0.7, tenue: 0.2),
    Cle(
      _rack(
        _largeur(_pose).copier(x: 0.35, y: 0.7, tronc: -60, dos: 2),
        z: 0.13,
      ),
      duree: 1.1,
    ),
    Cle(
      _largeur(_pose).copier(
        brasP: -92,
        brasL: -92,
        avantBrasP: -92,
        avantBrasL: -92,
        ecartBrasP: 16,
        ecartBrasL: 16,
        ecartAvantBrasP: 12,
        ecartAvantBrasL: 12,
      ),
      duree: 0.75,
      courbe: Courbe.explosive,
      tenue: 0.25,
    ),
  ], accessoires: const Accessoires(halteres: true)),
  // UNE kettlebell contre la poitrine (par les cornes), poussée à deux
  // mains au-dessus de la tête.
  'thruster_kettlebell': _suite([
    Cle(_goblet(_largeur(_pose), -90), duree: 0.7, tenue: 0.2),
    Cle(
      _goblet(_largeur(_pose).copier(x: 0.35, y: 0.7, tronc: -60, dos: 2), -60),
      duree: 1.1,
    ),
    Cle(
      _joindreMains(
        _largeur(_pose).copier(
          brasP: -94,
          brasL: -94,
          avantBrasP: -92,
          avantBrasL: -92,
          ecartBrasP: 4,
          ecartBrasL: 4,
          ecartAvantBrasP: -4,
          ecartAvantBrasL: -4,
        ),
        ecart: 0.03,
      ),
      duree: 0.75,
      courbe: Courbe.explosive,
      tenue: 0.25,
    ),
  ], accessoires: const Accessoires(kettlebell: true)),
  // La kettlebell à deux mains devant les cuisses, qui descend le long des
  // jambes.
  'souleve_roumain_kb': _serie(
    _joindreMains(
      _brasPendus(_pieds(_pose, 0.47, z: 0.06), ecart: 6),
      avance: 0.075,
    ),
    _joindreMains(
      _brasPendus(
        _pieds(
          _pose,
          0.47,
          z: 0.06,
        ).copier(x: 0.35, y: 0.515, tronc: -14, dos: 2, tete: -24),
        ecart: 6,
      ),
      avance: 0.02,
    ),
    ab: 1.8,
    ba: 1.2,
    tenueA: 0.45,
    tenueB: 0.2,
    accessoires: const Accessoires(kettlebell: true),
  ),
  // La kettlebell entre les pieds, saisie à deux mains, genoux ouverts.
  'souleve_terre_kb': _serie(
    _deadlift(bas: true, yMains: kSol - 0.1, z: 0.028).copier(
      piedCibleP: const Cible(0.47, yCheville, 0.1),
      piedCibleL: const Cible(0.47, yCheville, -0.1),
      genouP: const V3(1, -0.2, 0.8),
      genouL: const V3(1, -0.2, -0.8),
      coudeP: const V3(-0.2, 1, 0.1),
      coudeL: const V3(-0.2, 1, -0.1),
    ),
    _joindreMains(
      _brasPendus(
        _pieds(
          _pose,
          0.47,
          z: 0.1,
        ).copier(genouP: const V3(1, 0, 0.5), genouL: const V3(1, 0, -0.5)),
        ecart: 4,
      ),
      avance: 0.06,
    ),
    ab: 1.2,
    ba: 1.5,
    tenueA: 0.35,
    tenueB: 0.45,
    accessoires: const Accessoires(kettlebell: true),
  ),
  // La kettlebell par les cornes, montée vers la poitrine.
  'curl_kettlebell': _serie(
    _joindreMains(_curl(_pieds(_pose, 0.47, z: 0.06), 84), avance: 0.07),
    _joindreMains(_curl(_pieds(_pose, 0.47, z: 0.06), -50), avance: 0.02),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(kettlebell: true),
  ),
  // Un haltère en travers des hanches, une main sur chaque bout.
  'hip_thrust_haltere': _serie(
    _mainsSurHanches(_hipThrust(haut: false), haut: 0.075, versCuisses: 0.04),
    _mainsSurHanches(_hipThrust(haut: true), haut: 0.07, versCuisses: 0.04),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.7,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(
      haltereTravers: true,
      banc: Rect.fromLTRB(0.02, 0.65, 0.3, 0.685),
    ),
  ),
  // La barre posée dans le pli des hanches, les mains larges dessus.
  'hip_thrust_barre': _serie(
    _mainsSurHanches(_hipThrust(haut: false), z: 0.19, haut: 0.095),
    _mainsSurHanches(_hipThrust(haut: true), z: 0.19, haut: 0.085),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.7,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(
      barre: true,
      banc: Rect.fromLTRB(0.02, 0.65, 0.3, 0.685),
    ),
  ),
  // La barre devant les cuisses, épaules qui montent.
  'shrug_barre': _serie(
    _barreDevantJambes(_pieds(_pose, 0.47, z: 0.06)),
    _barreDevantJambes(
      _pieds(_pose, 0.47, z: 0.06).copier(haussement: 1),
      y: _barreDevantJambes(_pieds(_pose, 0.47, z: 0.06)).mainP!.y - 0.022,
    ),
    ab: 0.7,
    ba: 1.1,
    tenueA: 0.3,
    tenueB: 0.6,
    camera: Camera3.face,
    accessoires: const Accessoires(barre: true),
  ),
  // ══ TEMPO ══════════════════════════════════════════════════════════════
  // Trois secondes tenues tout en bas.
  'squat_pause': _tempo(_jambes3['squat']!, 1, tenue: 3),
  // Trois secondes pour descendre.
  'squat_tempo': _tempo(_jambes3['squat']!, 1, duree: 3.2),
  'pompe_tempo': _tempo(_poussee3['pompe']!, 1, duree: 3.2, tenue: 0.3),
  'fente_pause': _tempo(_fenteArriere(), 3, tenue: 3),
  // ══ FENTES ═════════════════════════════════════════════════════════════
  'fente_avant': _fenteAvant(),
  'fente_croisee': _fenteCroisee(),
  'fente_marchee': _fentesMarchees(),
  'fente_marchee_halteres': _fentesMarchees(
    bras: _brasPendus,
    accessoires: const Accessoires(halteres: true),
  ),
  // Une kettlebell (ou un haltère) contre la poitrine.
  'fente_arriere_goblet': _fenteArriere(
    bras: (p) => _goblet(p, p.tronc),
    accessoires: const Accessoires(goblet: true),
  ),
  'fente_laterale_goblet': _retoucher(
    _jambes3['fente_laterale']!,
    (p) => _goblet(p, p.tronc),
    accessoires: const Accessoires(goblet: true),
  ),
  // L'étirement : la fente latérale TENUE, qui respire.
  'etirement_adducteurs': _suite([
    Cle(
      _mainsJointes(_lateral(0.13, 0.655).copier(tronc: -64, dos: 3)),
      duree: 3,
      courbe: Courbe.douce,
    ),
    Cle(
      _mainsJointes(_lateral(0.14, 0.665).copier(tronc: -62, dos: 3)),
      duree: 3,
      courbe: Courbe.douce,
    ),
  ], camera: Camera3.face),
  // ══ UNE JAMBE ══════════════════════════════════════════════════════════
  // On s'assoit sur la chaise, sur une jambe, l'autre tendue devant.
  'squat_une_jambe_chaise': _serie(
    _brasDevant(
      _pieds(_pose, 0.47).copier(
        x: 0.47,
        piedCibleL: const Cible(0.62, yCheville - 0.08),
        cuisseL: 60,
        jambeL: 70,
      ),
    ).copier(sansCibles: false),
    _brasDevant(
      _pieds(_pose, 0.47).copier(
        x: 0.27,
        y: 0.62,
        tronc: -54,
        dos: 3,
        piedCibleL: const Cible(0.72, 0.8),
        piedL: -40,
      ),
    ),
    ab: 1.8,
    ba: 1.3,
    tenueA: 0.4,
    tenueB: 0.35,
    accessoires: const Accessoires(marche: _chaise),
  ),
  // Sur la marche, un seul pied : l'autre, replié derrière la cheville.
  'mollets_une_jambe': _retoucher(
    _jambes3['mollets_marche']!,
    (p) => p.copier(
      piedCibleL: Cible(
        (p.piedCibleP?.x ?? 0.45) - 0.06,
        (p.piedCibleP?.y ?? 0.77) - 0.09,
        -0.02,
      ),
      genouL: const V3(1, 0.3, -0.2),
      piedL: 70,
    ),
  ),
  // ══ PRISES ═════════════════════════════════════════════════════════════
  // Paumes face à face tout du long.
  'curl_marteau': _serie(
    _curl(_pieds(_pose, 0.47, z: 0.06), 88),
    _prono(_curl(_pieds(_pose, 0.47, z: 0.06), -56), 90),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(halteres: true),
  ),
  // Monté paumes vers le haut, tourné en haut, descendu paumes vers le bas.
  'curl_zottman': _suite([
    Cle(_curl(_pieds(_pose, 0.47, z: 0.06), 88), duree: 0.45, tenue: 0.2),
    Cle(
      _curl(_pieds(_pose, 0.47, z: 0.06), -56),
      duree: 0.9,
      courbe: Courbe.explosive,
      tenue: 0.15,
    ),
    Cle(
      _prono(_curl(_pieds(_pose, 0.47, z: 0.06), -56), 180),
      duree: 0.45,
      tenue: 0.15,
    ),
    // Redescendus paumes vers soi, les haltères passent devant les cuisses.
    Cle(
      _prono(_brasDirects(_pieds(_pose, 0.47, z: 0.06), 84, 10, 80, 8), 90),
      duree: 1.8,
      tenue: 0.15,
    ),
  ], accessoires: const Accessoires(halteres: true)),
  // Deux demi-curls du bas, deux du haut, un complet.
  'curl_21': _suite([
    for (final (a, b) in [(88.0, 12.0), (88.0, 12.0)]) ...[
      Cle(_curl(_pieds(_pose, 0.47, z: 0.06), a), duree: 0.5, tenue: 0.05),
      Cle(
        _curl(_pieds(_pose, 0.47, z: 0.06), b),
        duree: 0.5,
        courbe: Courbe.explosive,
      ),
    ],
    for (final (a, b) in [(12.0, -56.0), (12.0, -56.0)]) ...[
      Cle(_curl(_pieds(_pose, 0.47, z: 0.06), a), duree: 0.5, tenue: 0.05),
      Cle(
        _curl(_pieds(_pose, 0.47, z: 0.06), b),
        duree: 0.5,
        courbe: Courbe.explosive,
      ),
    ],
    Cle(_curl(_pieds(_pose, 0.47, z: 0.06), 88), duree: 0.9, tenue: 0.1),
    Cle(
      _curl(_pieds(_pose, 0.47, z: 0.06), -56),
      duree: 0.8,
      courbe: Courbe.explosive,
      tenue: 0.1,
    ),
  ], accessoires: const Accessoires(halteres: true)),
  'rowing_penche_supination': _retoucher(
    _tirage3['rowing_penche']!,
    (p) => _prono(p, 180),
  ),
  // Paumes vers le bas : on relève le dos des mains.
  'curl_poignet_inverse': _serie(
    _poignets(-32),
    _poignets(26),
    ab: 1.0,
    ba: 0.6,
    tenueA: 0.3,
    tenueB: 0.15,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(halteres: true, banc: _bancBasAssise),
  ),
  // Haltères devant le visage paumes vers soi ; les coudes s'ouvrent en
  // poussant, les paumes tournent vers l'avant.
  'developpe_arnold': _suite(
    [
      Cle(
        _prono(
          _mainsEn(
            _largeur(_pose, z: 0.07),
            0.56,
            0.25,
            0.07,
            const V3(1, 1, 0.15),
          ),
          -150,
        ),
        duree: 0.8,
        tenue: 0.25,
      ),
      Cle(
        _prono(
          _mainsEn(
            _largeur(_pose, z: 0.07),
            0.5,
            0.21,
            0.17,
            const V3(0.3, 1, 1),
          ),
          -70,
        ),
        duree: 0.5,
      ),
      Cle(
        _mainsEn(
          _largeur(_pose, z: 0.07),
          0.475,
          -0.01,
          0.1,
          const V3(0.1, 1, 1),
        ),
        duree: 0.55,
        courbe: Courbe.explosive,
        tenue: 0.25,
      ),
      Cle(
        _prono(
          _mainsEn(
            _largeur(_pose, z: 0.07),
            0.5,
            0.21,
            0.17,
            const V3(0.3, 1, 1),
          ),
          -70,
        ),
        duree: 0.8,
      ),
    ],
    camera: Camera3.face,
    accessoires: const Accessoires(halteres: true),
  ),
  // Un seul bras monte ; l'autre main sur la hanche.
  'elevation_laterale_une': _serie(
    _mainHanche(_brasDirects(_pieds(_pose, 0.47, z: 0.06), 90, 7, 84, 4)),
    _mainHanche(_brasDirects(_pieds(_pose, 0.47, z: 0.06), 92, 86, 82, 82)),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.3,
    camera: Camera3.face,
    accessoires: const Accessoires(haltereUne: true),
  ),
  // ══ CARDIO ═════════════════════════════════════════════════════════════
  // Plus lent que la course : petites foulées, peu de rebond.
  'footing': _allure(
    duree: 0.84,
    pas: 0.13,
    appui: 0.42,
    lever: 0.05,
    talon: 0.05,
    genou: 0.015,
    course: true,
    yHanche: hDebout + 0.008,
    rebond: 0.01,
    tronc: -84,
    bras: 26,
    coude: 80,
  ),
  // Un saut plus haut, et la corde passe DEUX fois sous les pieds pendant
  // qu'on est en l'air (au début et à la moitié du cycle) ; on se reçoit
  // quand elle passe au-dessus de la tête.
  'corde_double': _suite([
    for (final (h, pied, pli) in [
      (0.07, 44.0, 0.0),
      (0.11, 52.0, 0.0),
      (0.07, 44.0, 0.0),
      (0.0, 0.0, 0.014),
    ])
      Cle(
        _mainsCorde(
          _pieds(_pose, 0.47, z: 0.05, hP: h, hL: h),
        ).copier(y: hDebout - h + pli, piedP: pied, piedL: pied),
        duree: 0.17,
        courbe: Courbe.douce,
      ),
  ], accessoires: const Accessoires(corde: true, cordeDouble: true)),
};

/// La main loin posée sur la hanche, coude ouvert.
Pose3 _mainHanche(Pose3 p) => p.copier(
  mainL: Cible(p.x + 0.01, p.y - 0.035, -0.12),
  coudeL: const V3(-0.3, 0, -1),
);

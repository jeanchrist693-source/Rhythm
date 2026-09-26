// lib/widgets/corps/mouvements/tronc.dart
//
// Le TRONC, réécrit pour la fidélité : crunchs (les omoplates décollent, le
// bas du dos reste au sol), relevés de jambes, dead bug et crunch vélo vus
// d'en haut (bras et jambes opposés bien lisibles), planches gainées sur
// les avant-bras, planches LATÉRALES (le corps roulé sur le côté, l'avant-
// bras sous l'épaule), twists, bûcheron et Pallof.

part of '../animations_corps.dart';

// ── Positions ──────────────────────────────────────────────────────────────

/// Sur le dos, jambes libres (sans cibles), bras le long du corps.
final Pose3 _dosLibre = _dosAuSol.copier(sansCibles: true);

/// Les bras croisés sur la poitrine, qui suivent le tronc.
Pose3 _brasCroises(Pose3 p) {
  final t = p.tronc;
  return p.copier(
    brasP: t + 145,
    brasL: t + 145,
    ecartBrasP: 12,
    ecartBrasL: 12,
    avantBrasP: t + 45,
    avantBrasL: t + 50,
    ecartAvantBrasP: -70,
    ecartAvantBrasL: -66,
  );
}

/// Le crunch : les omoplates décollées de [haut] (0 à 1), mains aux tempes.
Pose3 _crunch(double haut, {Pose3? base, double torsion = 0}) => _mainsTempes(
  (base ?? _dosAuSol).copier(
    tronc: 180 + 26 * haut,
    dos: 8 * haut,
    tete: 184 + 40 * haut,
    torsion: torsion,
  ),
);

/// Assis en V pour le russian twist : buste incliné en arrière, pieds
/// décollés, les mains jointes devant la poitrine, tournées avec les
/// épaules de [torsion] degrés.
Pose3 _twist(double torsion) {
  const tronc = -130.0;
  final base = _pose.copier(
    x: 0.46,
    y: kSol - 0.066,
    tronc: tronc,
    tete: -112,
    torsion: torsion,
    sansCibles: true,
    cuisseP: -36,
    cuisseL: -36,
    ecartCuisseP: 6,
    ecartCuisseL: 6,
    jambeP: 26,
    jambeL: 26,
    piedP: 40,
    piedL: 40,
  );
  final t = rad(tronc);
  final dir = V3(math.cos(t), math.sin(t), 0);
  final avant = const V3(0, 0, 1).cross(dir).unite.tourne(dir, -rad(torsion));
  final c = const V3(0.46, kSol - 0.066, 0) + dir * 0.15 + avant * 0.25;
  return base.copier(
    mainP: Cible(c.x, c.y, c.z + 0.02),
    mainL: Cible(c.x, c.y, c.z - 0.02),
    coudeP: const V3(0, 1, 1),
    coudeL: const V3(0, 1, -1),
  );
}

/// La planche sur les avant-bras : épaules en [epaule], coudes dessous,
/// avant-bras posés devant.
Pose3 _plancheCoudes({
  Offset epaule = const Offset(0.716, 0.745),
  Offset appui = const Offset(0.1, _pointe),
  bool genoux = false,
}) => _gaine(appui, epaule, genoux: genoux).copier(
  mainP: Cible(epaule.dx + 0.15, yPaume - 0.004, 0.065),
  mainL: Cible(epaule.dx + 0.15, yPaume - 0.004, -0.065),
  coudeP: const V3(-0.3, 1, 0.2),
  coudeL: const V3(-0.3, 1, -0.2),
);

/// La planche LATÉRALE : couché sur le côté loin (le corps roulé vers
/// nous), l'avant-bras loin sous l'épaule. [pente] : l'inclinaison du
/// tronc ; [penteJambes] : celle des jambes (moins que le tronc = hanches
/// qui descendent) ; [genoux] : genoux pliés derrière ; [brasHaut] : le
/// bras proche tendu vers le plafond (sinon posé sur la hanche).
Pose3 _lateralePlanche({
  double pente = 16.7,
  double? penteJambes,
  bool genoux = false,
  bool brasHaut = false,
  bool main = false,
}) {
  final j = penteJambes ?? pente;
  return _pose.copier(
    auSol: true,
    x: 0.42,
    tronc: 0,
    inclinaison: pente,
    roulis: 90,
    tete: -2,
    sansCibles: true,
    cuisseP: 180,
    cuisseL: 180,
    ecartCuisseP: -j,
    ecartCuisseL: j,
    jambeP: genoux ? -90 : 180,
    jambeL: genoux ? -90 : 180,
    ecartJambeP: -j,
    ecartJambeL: j,
    piedP: genoux ? 200 : 90,
    piedL: genoux ? 200 : 90,
    // Le bras d'appui : sous l'épaule, l'avant-bras posé en biais devant.
    brasL: 0,
    ecartBrasL: 90,
    avantBrasL: main ? 0 : 45,
    ecartAvantBrasL: main ? 90 : 0,
    // Le bras proche : tendu vers le plafond, ou posé le long du corps.
    brasP: brasHaut ? 0 : 178,
    ecartBrasP: brasHaut ? 90 : -6,
    avantBrasP: brasHaut ? 0 : 182,
    ecartAvantBrasP: brasHaut ? 90 : -13,
  );
}

/// Dead bug : bras vers le plafond, genoux à 90° au-dessus des hanches ;
/// [brasP] / [brasL] partent derrière la tête, [jambeP] / [jambeL] se
/// tendent.
Pose3 _deadBug({
  bool brasP = false,
  bool brasL = false,
  bool jambeP = false,
  bool jambeL = false,
  bool haltere = false,
}) => _dosLibre.copier(
  brasP: brasP ? 188 : -90,
  brasL: brasL ? 188 : -90,
  avantBrasP: brasP ? 190 : -90,
  avantBrasL: brasL ? 190 : -90,
  ecartBrasP: haltere ? -12 : 6,
  ecartBrasL: haltere ? -12 : 6,
  ecartAvantBrasP: haltere ? -12 : 4,
  ecartAvantBrasL: haltere ? -12 : 4,
  cuisseP: jambeP ? -8 : -90,
  cuisseL: jambeL ? -8 : -90,
  jambeP: jambeP ? -8 : 0,
  jambeL: jambeL ? -8 : 0,
  piedP: jambeP ? -40 : -70,
  piedL: jambeL ? -40 : -70,
  ecartCuisseP: 5,
  ecartCuisseL: 5,
);

/// Le hollow (banane) : omoplates et jambes décollées, bras tendus
/// derrière la tête ; [bascule] le fait rouler d'avant en arrière.
Pose3 _hollow({double bascule = 0, bool roule = false}) => _dosLibre.copier(
  auSol: roule,
  tronc: 196 + bascule,
  tete: 206 + bascule,
  dos: 6,
  brasP: 196 + bascule,
  brasL: 196 + bascule,
  avantBrasP: 196 + bascule,
  avantBrasL: 196 + bascule,
  ecartBrasP: 6,
  ecartBrasL: 6,
  ecartAvantBrasP: 4,
  ecartAvantBrasL: 4,
  cuisseP: -14 + bascule,
  cuisseL: -14 + bascule,
  jambeP: -14 + bascule,
  jambeL: -14 + bascule,
  piedP: -50 + bascule,
  piedL: -50 + bascule,
  ecartCuisseP: 2,
  ecartCuisseL: 2,
);

/// Les jambes tendues, décollées de [p] et [l] degrés, écartées de
/// [eP] / [eL] (négatif : elles se croisent) ; mains sous les fesses.
Pose3 _jambesLevees(double p, double l, {double eP = 3, double eL = 3}) =>
    _dosLibre.copier(
      tronc: 188,
      tete: 196,
      cuisseP: -p,
      cuisseL: -l,
      jambeP: -p,
      jambeL: -l,
      ecartCuisseP: eP,
      ecartCuisseL: eL,
      ecartJambeP: eP,
      ecartJambeL: eL,
      piedP: -p - 40,
      piedL: -l - 40,
      brasP: 10,
      brasL: 10,
      avantBrasP: 16,
      avantBrasL: 16,
      ecartBrasP: 6,
      ecartBrasL: 6,
      ecartAvantBrasP: -4,
      ecartAvantBrasL: -4,
    );

/// L'ours : à quatre pattes, genoux décollés de quelques centimètres,
/// orteils rentrés.
Pose3 _ours({double souffle = 0}) => _quatrePattes()
    .copier(y: kSol - 0.03 - lCuisse - 0.035 - souffle * 0.004)
    .copier(
      piedCibleP: const Cible(0.18, _pointe, 0.07),
      piedCibleL: const Cible(0.18, _pointe, -0.07),
      genouP: const V3(0.4, 1, 0.1),
      genouL: const V3(0.4, 1, -0.1),
      piedP: 70,
      piedL: 70,
    );

// ── Les mouvements ─────────────────────────────────────────────────────────

final Map<String, AnimCorps> _tronc3 = {
  // ══ CRUNCHS ════════════════════════════════════════════════════════════
  'crunch': _serie(
    _crunch(0),
    _crunch(1),
    ab: 0.8,
    ba: 1.1,
    tenueA: 0.3,
    tenueB: 0.45,
    courbeAB: Courbe.explosive,
  ),
  // Les épaules décollées, la main va toucher le talon de son côté (la
  // base du crunch tenait les mains aux tempes : elles y restaient).
  'toucher_talons': _suite([
    Cle(
      _crunch(0.75).copier(
        inclinaison: 13,
        mainP: const Cible(0.73, kSol - 0.02, 0.19),
        mainL: const Cible(0.6, kSol - 0.03, -0.17),
        coudeP: const V3(0, -0.3, 1),
        coudeL: const V3(0, -0.3, -1),
      ),
      duree: 0.5,
      tenue: 0.12,
    ),
    Cle(
      _crunch(0.75).copier(
        inclinaison: -13,
        mainP: const Cible(0.6, kSol - 0.03, 0.17),
        mainL: const Cible(0.73, kSol - 0.02, -0.19),
        coudeP: const V3(0, -0.3, 1),
        coudeL: const V3(0, -0.3, -1),
      ),
      duree: 0.5,
      tenue: 0.12,
    ),
  ], camera: Camera3.dessus),
  'situp': _suite([
    Cle(_brasCroises(_dosAuSol.copier(tete: 184)), duree: 1.2, tenue: 0.3),
    Cle(
      _brasCroises(_dosAuSol.copier(tronc: 230, tete: 250, dos: 12)),
      duree: 0.5,
      courbe: Courbe.lancee,
    ),
    Cle(
      _brasCroises(_dosAuSol.copier(tronc: 268, tete: 286, dos: 4)),
      duree: 0.45,
      courbe: Courbe.explosive,
      tenue: 0.3,
    ),
  ]),
  'crunch_oblique': _suite([
    Cle(_crunch(0), duree: 0.9, tenue: 0.25),
    Cle(_crunch(0.85, torsion: 30), duree: 0.8, tenue: 0.35),
    Cle(_crunch(0), duree: 0.9, tenue: 0.25),
    Cle(_crunch(0.85, torsion: -30), duree: 0.8, tenue: 0.35),
  ], camera: Camera3.dessus),
  'crunch_velo': _suite([
    Cle(
      _crunch(
        0.9,
        base: _dosLibre.copier(
          cuisseP: -122,
          jambeP: -22,
          piedP: -70,
          cuisseL: -14,
          jambeL: -14,
          piedL: -50,
        ),
        torsion: 30,
      ),
      duree: 0.7,
      tenue: 0.1,
    ),
    Cle(
      _crunch(
        0.9,
        base: _dosLibre.copier(
          cuisseP: -14,
          jambeP: -14,
          piedP: -50,
          cuisseL: -122,
          jambeL: -22,
          piedL: -70,
        ),
        torsion: -30,
      ),
      duree: 0.7,
      tenue: 0.1,
    ),
  ], camera: Camera3.dessus),
  'crunch_inverse': _serie(
    _dosLibre.copier(
      cuisseP: -92,
      cuisseL: -92,
      jambeP: -2,
      jambeL: -2,
      piedP: -60,
      piedL: -60,
    ),
    _dosLibre.copier(
      y: kSol - 0.1,
      tronc: 168,
      tete: 184,
      cuisseP: -132,
      cuisseL: -132,
      jambeP: -48,
      jambeL: -48,
      piedP: -90,
      piedL: -90,
    ),
    ab: 0.8,
    ba: 1.2,
    tenueA: 0.3,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
  ),
  'crunch_jambes_levees': _serie(
    _brasDirects(
      _jambesLevees(90, 90),
      -60,
      8,
      -60,
      6,
    ).copier(tronc: 186, tete: 190),
    _brasDirects(
      _jambesLevees(90, 90),
      -48,
      8,
      -44,
      6,
    ).copier(tronc: 208, tete: 226, dos: 8),
    ab: 0.8,
    ba: 1.1,
    tenueA: 0.3,
    tenueB: 0.4,
    courbeAB: Courbe.explosive,
  ),
  // ══ JAMBES LEVÉES ══════════════════════════════════════════════════════
  'releve_jambes': _serie(
    _jambesLevees(8, 8),
    _jambesLevees(88, 88),
    ab: 1.1,
    ba: 1.7,
    tenueA: 0.3,
    tenueB: 0.3,
  ),
  'ciseaux': _suite([
    Cle(_jambesLevees(24, 20, eP: 16, eL: 16), duree: 0.4),
    Cle(_jambesLevees(26, 18, eP: -8, eL: 6), duree: 0.4),
    Cle(_jambesLevees(20, 24, eP: 16, eL: 16), duree: 0.4),
    Cle(_jambesLevees(18, 26, eP: 6, eL: -8), duree: 0.4),
  ], camera: Camera3.dessus),
  'battements': _suite([
    Cle(_jambesLevees(32, 12), duree: 0.32, courbe: Courbe.douce),
    Cle(_jambesLevees(12, 32), duree: 0.32, courbe: Courbe.douce),
  ]),
  'v_up': _suite([
    Cle(
      _hollow().copier(
        auSol: true,
        tronc: 180,
        tete: 184,
        dos: 0,
        cuisseP: 0,
        cuisseL: 0,
        jambeP: 0,
        jambeL: 0,
        piedP: -30,
        piedL: -30,
        brasP: 188,
        brasL: 188,
        avantBrasP: 188,
        avantBrasL: 188,
      ),
      duree: 1.1,
      tenue: 0.3,
    ),
    Cle(
      _hollow().copier(
        auSol: true,
        tronc: 228,
        tete: 244,
        dos: 6,
        cuisseP: -46,
        cuisseL: -46,
        jambeP: -46,
        jambeL: -46,
        piedP: -76,
        piedL: -76,
        brasP: 314,
        brasL: 314,
        avantBrasP: 316,
        avantBrasL: 316,
      ),
      duree: 0.7,
      courbe: Courbe.explosive,
      tenue: 0.2,
    ),
  ]),
  'hollow': _suite([
    Cle(_hollow(), duree: 1.8),
    Cle(_hollow(bascule: 1.2), duree: 1.8),
  ]),
  'hollow_rock': _suite([
    Cle(_hollow(bascule: -12, roule: true), duree: 0.55, courbe: Courbe.douce),
    Cle(_hollow(bascule: 12, roule: true), duree: 0.55, courbe: Courbe.douce),
  ]),
  'dead_bug': _suite([
    Cle(_deadBug(), duree: 0.9, tenue: 0.2),
    Cle(_deadBug(brasP: true, jambeL: true), duree: 1.3, tenue: 0.4),
    Cle(_deadBug(), duree: 0.9, tenue: 0.2),
    Cle(_deadBug(brasL: true, jambeP: true), duree: 1.3, tenue: 0.4),
  ], camera: Camera3.dessus),
  'dead_bug_haltere': _suite(
    [
      Cle(_deadBug(haltere: true), duree: 0.9, tenue: 0.2),
      Cle(_deadBug(haltere: true, jambeL: true), duree: 1.3, tenue: 0.4),
      Cle(_deadBug(haltere: true), duree: 0.9, tenue: 0.2),
      Cle(_deadBug(haltere: true, jambeP: true), duree: 1.3, tenue: 0.4),
    ],
    camera: Camera3.dessus,
    accessoires: const Accessoires(goblet: true),
  ),
  // ══ ROTATIONS ══════════════════════════════════════════════════════════
  'russian_twist': _suite([
    Cle(_twist(40), duree: 0.7, courbe: Courbe.douce, tenue: 0.1),
    Cle(_twist(-40), duree: 0.7, courbe: Courbe.douce, tenue: 0.1),
  ], camera: Camera3.dessus),
  'russian_twist_haltere': _suite(
    [
      Cle(_twist(40), duree: 0.8, courbe: Courbe.douce, tenue: 0.1),
      Cle(_twist(-40), duree: 0.8, courbe: Courbe.douce, tenue: 0.1),
    ],
    camera: Camera3.dessus,
    accessoires: const Accessoires(goblet: true),
  ),
  'woodchop': _serie(
    _joindreMains(
      _largeur(_pose, z: 0.1).copier(
        torsion: -22,
        mainP: const Cible(0.66, 0.02, -0.17),
        mainL: const Cible(0.66, 0.02, -0.21),
        coudeP: const V3(0.3, 0.5, 1),
        coudeL: const V3(0.3, 0.5, -1),
      ),
    ),
    _joindreMains(
      _largeur(_pose, z: 0.1).copier(
        y: 0.53,
        x: 0.45,
        tronc: -76,
        torsion: 38,
        mainP: const Cible(0.63, 0.66, 0.21),
        mainL: const Cible(0.63, 0.66, 0.17),
        coudeP: const V3(0, 1, 1),
        coudeL: const V3(0, 1, -1),
      ),
    ),
    ab: 0.7,
    ba: 1.2,
    tenueA: 0.2,
    tenueB: 0.25,
    courbeAB: Courbe.explosive,
    camera: Camera3.face,
    accessoires: const Accessoires(goblet: true),
  ),
  'woodchop_elastique': _serie(
    _largeur(_pose, z: 0.1).copier(
      torsion: -22,
      mainP: const Cible(0.66, 0.02, -0.17),
      mainL: const Cible(0.66, 0.02, -0.21),
      coudeP: const V3(0.3, 0.5, 1),
      coudeL: const V3(0.3, 0.5, -1),
    ),
    _largeur(_pose, z: 0.1).copier(
      y: 0.53,
      x: 0.45,
      tronc: -76,
      torsion: 38,
      mainP: const Cible(0.63, 0.66, 0.21),
      mainL: const Cible(0.63, 0.66, 0.17),
      coudeP: const V3(0, 1, 1),
      coudeL: const V3(0, 1, -1),
    ),
    ab: 0.7,
    ba: 1.2,
    tenueA: 0.2,
    tenueB: 0.25,
    courbeAB: Courbe.explosive,
    camera: Camera3.face,
    accessoires: const Accessoires(
      elastique: Offset(0.5, -0.06),
      elastiqueZ: -0.5,
    ),
  ),
  'pallof': _serie(
    _mainsEn(_largeur(_pose, z: 0.1), 0.53, 0.3, 0.02, const V3(-0.3, 1, 1)),
    _mainsEn(_largeur(_pose, z: 0.1), 0.76, 0.3, 0.02, const V3(-0.3, 1, 1)),
    ab: 0.9,
    ba: 1.0,
    tenueA: 0.3,
    tenueB: 1.0,
    accessoires: const Accessoires(
      elastique: Offset(0.6, 0.3),
      elastiqueZ: -0.6,
    ),
  ),
  // ══ GAINAGE ════════════════════════════════════════════════════════════
  'planche': _suite([
    Cle(_plancheCoudes(), duree: 1.8),
    Cle(_plancheCoudes(epaule: const Offset(0.716, 0.742)), duree: 1.8),
  ]),
  'planche_genoux': _suite([
    Cle(
      _plancheCoudes(
        appui: const Offset(0.33, kSol - 0.03),
        epaule: const Offset(0.726, 0.745),
        genoux: true,
      ),
      duree: 1.8,
    ),
    Cle(
      _plancheCoudes(
        appui: const Offset(0.33, kSol - 0.03),
        epaule: const Offset(0.726, 0.742),
        genoux: true,
      ),
      duree: 1.8,
    ),
  ]),
  'planche_haute': _suite([
    Cle(_pompe(yPaume - 0.285), duree: 1.8),
    Cle(_pompe(yPaume - 0.281), duree: 1.8),
  ]),
  'planche_toucher': _suite([
    Cle(_pompe(yPaume - 0.285, zPieds: 0.12), duree: 0.5, tenue: 0.15),
    Cle(
      _pompe(yPaume - 0.285, zPieds: 0.12).copier(
        mainP: const Cible(0.66, 0.665, -0.07),
        coudeP: const V3(0, 1, 1),
        roulis: -6,
      ),
      duree: 0.5,
      tenue: 0.2,
    ),
    Cle(_pompe(yPaume - 0.285, zPieds: 0.12), duree: 0.5, tenue: 0.15),
    Cle(
      _pompe(yPaume - 0.285, zPieds: 0.12).copier(
        mainL: const Cible(0.66, 0.665, 0.07),
        coudeL: const V3(0, 1, -1),
        roulis: 6,
      ),
      duree: 0.5,
      tenue: 0.2,
    ),
  ]),
  'planche_dynamique': _suite([
    Cle(_plancheCoudes(), duree: 0.55, tenue: 0.25),
    // La main proche se pose, le corps monte d'un côté…
    Cle(
      _plancheCoudes(epaule: const Offset(0.704, 0.68)).copier(
        mainP: const Cible(0.7, yPaume, 0.12),
        coudeP: const V3(-0.6, -1, 0.7),
      ),
      duree: 0.55,
    ),
    // … puis l'autre : planche haute.
    Cle(
      _pompe(yPaume - 0.285, main: const Offset(0.7, yPaume)),
      duree: 0.55,
      tenue: 0.25,
    ),
    Cle(
      _plancheCoudes(epaule: const Offset(0.704, 0.68)).copier(
        mainL: const Cible(0.7, yPaume, -0.12),
        coudeL: const V3(-0.6, -1, -0.7),
      ),
      duree: 0.55,
    ),
  ]),
  'planche_laterale': _suite([
    Cle(_lateralePlanche(), duree: 1.8),
    Cle(_lateralePlanche(pente: 17.2), duree: 1.8),
  ]),
  'planche_laterale_genoux': _suite([
    Cle(_lateralePlanche(pente: 20, penteJambes: 12, genoux: true), duree: 1.8),
    Cle(
      _lateralePlanche(pente: 20.5, penteJambes: 12, genoux: true),
      duree: 1.8,
    ),
  ]),
  'planche_laterale_hanche': _serie(
    _lateralePlanche(),
    _lateralePlanche(pente: 36, penteJambes: 5),
    ab: 1.0,
    ba: 0.8,
    tenueA: 0.35,
    tenueB: 0.15,
    courbeBA: Courbe.explosive,
  ),
  'planche_rotation': _suite([
    Cle(_pompe(yPaume - 0.285, zPieds: 0.1), duree: 0.8, tenue: 0.3),
    Cle(
      _lateralePlanche(pente: 26, brasHaut: true, main: true),
      duree: 0.9,
      tenue: 0.5,
    ),
  ]),
  'ours_statique': _suite([
    Cle(_ours(), duree: 1.8),
    Cle(_ours(souffle: 1), duree: 1.8),
  ]),
};

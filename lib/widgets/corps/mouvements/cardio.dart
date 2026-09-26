// lib/widgets/corps/mouvements/cardio.dart
//
// Le CARDIO, réécrit pour la fidélité : sauts (le corps quitte vraiment le
// sol, les réceptions amorties), burpees en entier (accroupi, planche,
// retour, saut), grimpeurs, course et marche (de vraies foulées), vélo (les
// pieds sur les pédales qui tournent), corde, boxe, chenille.

part of '../animations_corps.dart';

// ── Positions ──────────────────────────────────────────────────────────────

/// Debout, pieds écartés de [z], bras en [bras] (ecart : 5 le long du
/// corps, 90 à l'horizontale, 165 au-dessus de la tête), en l'air de [air].
Pose3 _jack(double z, double bras, {double air = 0, double flexion = 0}) =>
    _pose.copier(
      y: hDebout - air + flexion,
      piedCibleP: Cible(0.47, yCheville - air * 0.8, z),
      piedCibleL: Cible(0.47, yCheville - air * 0.8, -z),
      piedP: air > 0 ? 40 : 0,
      piedL: air > 0 ? 40 : 0,
      genouP: const V3(1, 0, 0.5),
      genouL: const V3(1, 0, -0.5),
      ecartCuisseP: z * 60,
      ecartCuisseL: z * 60,
      brasP: 90,
      brasL: 90,
      ecartBrasP: bras,
      ecartBrasL: bras,
      avantBrasP: 86,
      avantBrasL: 86,
      ecartAvantBrasP: bras - 4,
      ecartAvantBrasL: bras - 4,
    );

/// Accroupi, les mains posées au sol devant les pieds (burpee).
final Pose3 _accroupiMains = _pieds(_pose, 0.47, z: 0.09).copier(
  x: 0.38,
  y: 0.69,
  tronc: -30,
  tete: -20,
  // Les mains entre les genoux, qui s'ouvrent : les bras ne traversent
  // plus les cuisses.
  mainP: const Cible(0.6, yPaume, 0.05),
  mainL: const Cible(0.6, yPaume, -0.05),
  coudeP: const V3(-0.5, 0, 0.4),
  coudeL: const V3(-0.5, 0, -0.4),
  genouP: const V3(1, -0.3, 0.75),
  genouL: const V3(1, -0.3, -0.75),
);

/// La planche du burpee (mains en 0,6, pieds sautés derrière).
Pose3 _plancheBurpee({double yEpaule = yPaume - 0.285}) => _pompe(
  yEpaule,
  appui: const Offset(0.01, _pointe),
  main: const Offset(0.6, yPaume),
);

/// L'envol d'un saut, bras au ciel.
final Pose3 _envolBras = _pieds(_pose, 0.47, z: 0.06, hP: 0.1, hL: 0.1).copier(
  y: hDebout - 0.1,
  piedP: 50,
  piedL: 50,
  brasP: -94,
  brasL: -94,
  avantBrasP: -92,
  avantBrasL: -92,
  ecartBrasP: 12,
  ecartBrasL: 12,
);

/// La garde de boxe : appui décalé, poings au menton.
Pose3 _gardeBoxe({double rebond = 0, double torsion = 0}) =>
    _pieds(
      _pose,
      0.52,
      xL: 0.4,
      z: 0.07,
      hP: rebond * 0.6,
      hL: rebond * 0.6,
    ).copier(
      x: 0.46,
      y: hDebout + 0.02 - rebond,
      tronc: -84,
      torsion: torsion,
      piedP: rebond > 0 ? 20 : 0,
      piedL: rebond > 0 ? 20 : 0,
      mainP: const Cible(0.53, 0.25, 0.08),
      mainL: const Cible(0.56, 0.24, -0.06),
      coudeP: const V3(0, 1, 0.4),
      coudeL: const V3(0, 1, -0.4),
    );

/// Le vélo : assis sur la selle, mains au guidon, les pieds sur les
/// pédales à l'angle [phi] (le pied loin à l'opposé).
Pose3 _pedaler(double phi) {
  const pedalier = Offset(0.47, kSol - 0.13);
  const manivelle = 0.085;
  Cible pedale(double a, double z) => Cible(
    pedalier.dx + manivelle * math.cos(a) - 0.045,
    pedalier.dy + manivelle * math.sin(a) - 0.035,
    z,
  );
  return _pose.copier(
    x: 0.42,
    y: 0.52,
    tronc: -58,
    tete: -70,
    piedCibleP: pedale(phi, 0.08),
    piedCibleL: pedale(phi + math.pi, -0.08),
    piedP: 12 + 14 * math.sin(phi),
    piedL: 12 + 14 * math.sin(phi + math.pi),
    genouP: const V3(1, -0.3, 0.1),
    genouL: const V3(1, -0.3, -0.1),
    mainP: const Cible(0.7, 0.5, 0.08),
    mainL: const Cible(0.7, 0.5, -0.08),
    coudeP: const V3(-0.2, 1, 0.5),
    coudeL: const V3(-0.2, 1, -0.5),
  );
}

/// Les grimpeurs : en planche, le genou proche ([proche]) ou loin ramené
/// sous la poitrine.
Pose3 _grimpeur({required bool proche}) {
  final p = _pompe(yPaume - 0.29, appui: const Offset(0.06, _pointe));
  const genou = Cible(0.44, kSol - 0.075);
  return proche
      ? p.copier(
          piedCibleP: Cible(genou.x, genou.y, 0.06),
          genouP: const V3(1, 0.8, 0.1),
          piedP: 60,
        )
      : p.copier(
          piedCibleL: Cible(genou.x, genou.y, -0.06),
          genouL: const V3(1, 0.8, -0.1),
          piedL: 60,
        );
}

/// L'ours qui avance : à quatre pattes, genoux décollés ; [pas] avance la
/// main proche et le pied loin (négatif : l'autre diagonale).
Pose3 _oursPas(double pas) => _ours().copier(
  mainP: Cible(0.59 + 0.05 * pas, yPaume - 0.03 * pas.abs(), 0.1),
  mainL: Cible(0.59 - 0.05 * pas, yPaume - 0.03 * pas.abs(), -0.1),
  piedCibleP: Cible(0.18 - 0.05 * pas, _pointe - 0.03 * pas.abs(), 0.07),
  piedCibleL: Cible(0.18 + 0.05 * pas, _pointe - 0.03 * pas.abs(), -0.07),
);

/// Le patineur : réception sur une jambe ([proche]), le corps décalé de
/// côté, l'autre jambe croisée derrière, les bras qui balancent en travers.
Pose3 _patineur({required bool proche, bool air = false}) {
  final s = proche ? 1.0 : -1.0;
  final z = 0.2 * s;
  return _pose.copier(
    x: 0.47,
    y: air ? 0.5 : 0.56,
    dz: air ? 0 : z * 0.85,
    tronc: -62,
    tete: -74,
    inclinaison: air ? 0 : -6 * s,
    piedCibleP: proche
        ? Cible(0.47, yCheville - (air ? 0.06 : 0), z)
        : Cible(0.36, yCheville - 0.07, z * 0.15),
    piedCibleL: proche
        ? Cible(0.36, yCheville - 0.07, -z * 0.15)
        : Cible(0.47, yCheville - (air ? 0.06 : 0), z),
    genouP: const V3(1, 0, 0.2),
    genouL: const V3(1, 0, -0.2),
    brasP: proche ? 150 : 40,
    brasL: proche ? 40 : 150,
    ecartBrasP: proche ? 24 : -20,
    ecartBrasL: proche ? -20 : 24,
    avantBrasP: proche ? 140 : 20,
    avantBrasL: proche ? 20 : 140,
  );
}

/// La pente de la marche en côte (≈ 10 %).
const double _penteCote = 0.1;

/// Les pieds de [p] posés sur un sol de pente [pente] (qui passe par
/// x = 0,47 au niveau du sol), la pointe relevée d'autant.
Pose3 _surLaPente(Pose3 p, double pente) {
  final angle = math.atan(pente) * 180 / math.pi;
  Cible? sur(Cible? c) =>
      c == null ? null : Cible(c.x, c.y - pente * (c.x - 0.47), c.z);
  return p.copier(
    piedCibleP: sur(p.piedCibleP),
    piedCibleL: sur(p.piedCibleL),
    piedP: p.piedP - angle,
    piedL: p.piedL - angle,
  );
}

// ── Les mouvements ─────────────────────────────────────────────────────────

final Map<String, AnimCorps> _cardio3 = {
  // ══ SAUTS ══════════════════════════════════════════════════════════════
  'jumping_jack': _suite([
    Cle(
      _jack(0.05, 5, flexion: 0.012),
      duree: 0.15,
      courbe: Courbe.lancee,
      tenue: 0.06,
    ),
    Cle(_jack(0.13, 90, air: 0.04), duree: 0.15, courbe: Courbe.explosive),
    Cle(
      _jack(0.21, 172, flexion: 0.02),
      duree: 0.15,
      courbe: Courbe.lancee,
      tenue: 0.06,
    ),
    Cle(_jack(0.13, 90, air: 0.04), duree: 0.15, courbe: Courbe.explosive),
  ], camera: Camera3.face),
  'jacks_sans_saut': _suite([
    Cle(_jack(0.05, 5), duree: 0.35),
    Cle(
      _jack(0.05, 160).copier(
        piedCibleP: const Cible(0.47, yCheville, 0.24),
        ecartCuisseP: 14,
      ),
      duree: 0.35,
      tenue: 0.05,
    ),
    Cle(_jack(0.05, 5), duree: 0.35),
    Cle(
      _jack(0.05, 160).copier(
        piedCibleL: const Cible(0.47, yCheville, -0.24),
        ecartCuisseL: 14,
      ),
      duree: 0.35,
      tenue: 0.05,
    ),
  ], camera: Camera3.face),
  'squat_jack': _suite([
    Cle(
      _mainsJointes(_jack(0.06, 5, flexion: 0.1).copier(tronc: -76, x: 0.44)),
      duree: 0.2,
      courbe: Courbe.lancee,
    ),
    Cle(
      _mainsJointes(_jack(0.13, 5, air: 0.03).copier(tronc: -80, x: 0.45)),
      duree: 0.18,
      courbe: Courbe.explosive,
    ),
    Cle(
      _mainsJointes(_jack(0.22, 5, flexion: 0.11).copier(tronc: -74, x: 0.44)),
      duree: 0.2,
      courbe: Courbe.lancee,
    ),
    Cle(
      _mainsJointes(_jack(0.13, 5, air: 0.03).copier(tronc: -80, x: 0.45)),
      duree: 0.18,
      courbe: Courbe.explosive,
    ),
  ], camera: Camera3.face),
  'star_jump': _suite([
    Cle(
      _jack(0.07, 12, flexion: 0.11).copier(tronc: -66, x: 0.43),
      duree: 0.45,
      tenue: 0.15,
    ),
    // L'étoile, en l'air.
    Cle(
      _jack(0.24, 138, air: 0.14).copier(piedP: 60, piedL: 60),
      duree: 0.3,
      courbe: Courbe.explosive,
    ),
    Cle(
      _jack(0.08, 20, flexion: 0.1).copier(tronc: -70, x: 0.44),
      duree: 0.3,
      courbe: Courbe.lancee,
    ),
  ], camera: Camera3.face),
  'saut_groupe': _suite([
    Cle(
      _brasDevant(_largeur(_pose).copier(x: 0.4, y: 0.6, tronc: -60)).copier(
        brasP: 130,
        brasL: 130,
        avantBrasP: 120,
        avantBrasL: 120,
        ecartBrasP: 20,
        ecartBrasL: 20,
        ecartAvantBrasP: 14,
        ecartAvantBrasL: 14,
      ),
      duree: 0.45,
      tenue: 0.15,
    ),
    // Les genoux ramenés contre la poitrine au sommet.
    Cle(
      _pose.copier(
        y: 0.33,
        tronc: -80,
        sansCibles: true,
        cuisseP: -40,
        cuisseL: -40,
        ecartCuisseP: 6,
        ecartCuisseL: 6,
        jambeP: 96,
        jambeL: 96,
        piedP: 60,
        piedL: 60,
        // Les bras devant, hors des genoux ramenés.
        brasP: 16,
        brasL: 16,
        avantBrasP: -14,
        avantBrasL: -14,
        ecartBrasP: 26,
        ecartBrasL: 26,
        ecartAvantBrasP: 12,
        ecartAvantBrasL: 12,
      ),
      duree: 0.32,
      courbe: Courbe.explosive,
    ),
    Cle(
      _brasDevant(_largeur(_pose).copier(x: 0.42, y: 0.58, tronc: -66)),
      duree: 0.3,
      courbe: Courbe.lancee,
    ),
  ]),
  // ══ BURPEES ════════════════════════════════════════════════════════════
  'burpee': _suite([
    Cle(_pieds(_pose, 0.47, z: 0.07), duree: 0.35, tenue: 0.1),
    Cle(_accroupiMains, duree: 0.4),
    Cle(_plancheBurpee(), duree: 0.3, courbe: Courbe.explosive),
    Cle(_accroupiMains, duree: 0.35, courbe: Courbe.explosive),
    Cle(_envolBras, duree: 0.35, courbe: Courbe.explosive),
  ]),
  'burpee_pompe': _suite([
    Cle(_pieds(_pose, 0.47, z: 0.07), duree: 0.35, tenue: 0.1),
    Cle(_accroupiMains, duree: 0.4),
    Cle(_plancheBurpee(), duree: 0.3, courbe: Courbe.explosive),
    Cle(_plancheBurpee(yEpaule: kSol - 0.08), duree: 0.55, tenue: 0.05),
    Cle(_plancheBurpee(), duree: 0.45, courbe: Courbe.explosive),
    Cle(_accroupiMains, duree: 0.35, courbe: Courbe.explosive),
    Cle(_envolBras, duree: 0.35, courbe: Courbe.explosive),
  ]),
  'burpee_sans_saut': _suite([
    Cle(_pieds(_pose, 0.47, z: 0.07), duree: 0.45, tenue: 0.1),
    Cle(_accroupiMains, duree: 0.5),
    // Un pied recule, puis l'autre.
    Cle(
      _accroupiMains.copier(piedCibleP: const Cible(0.05, _pointe, 0.05)),
      duree: 0.45,
    ),
    Cle(_plancheBurpee(), duree: 0.45, tenue: 0.2),
    Cle(
      _accroupiMains.copier(piedCibleL: const Cible(0.05, _pointe, -0.05)),
      duree: 0.45,
    ),
    Cle(_accroupiMains, duree: 0.45),
    Cle(
      _pieds(_pose, 0.47, z: 0.07).copier(
        brasP: -94,
        brasL: -94,
        avantBrasP: -92,
        avantBrasL: -92,
        ecartBrasP: 12,
        ecartBrasL: 12,
      ),
      duree: 0.5,
      tenue: 0.2,
    ),
  ]),
  'burpee_saut_groupe': _suite([
    Cle(_pieds(_pose, 0.47, z: 0.07), duree: 0.35, tenue: 0.1),
    Cle(_accroupiMains, duree: 0.4),
    Cle(_plancheBurpee(), duree: 0.3, courbe: Courbe.explosive),
    Cle(_accroupiMains, duree: 0.35, courbe: Courbe.explosive),
    Cle(
      _pose.copier(
        y: 0.33,
        tronc: -80,
        sansCibles: true,
        cuisseP: -40,
        cuisseL: -40,
        jambeP: 96,
        jambeL: 96,
        piedP: 60,
        piedL: 60,
        // Les bras devant, hors des genoux ramenés.
        brasP: 16,
        brasL: 16,
        avantBrasP: -14,
        avantBrasL: -14,
        ecartBrasP: 26,
        ecartBrasL: 26,
        ecartAvantBrasP: 12,
        ecartAvantBrasL: 12,
      ),
      duree: 0.38,
      courbe: Courbe.explosive,
    ),
  ]),
  // ══ AU SOL ═════════════════════════════════════════════════════════════
  'mountain_climber': _suite([
    Cle(_grimpeur(proche: true), duree: 0.24, courbe: Courbe.douce),
    Cle(_grimpeur(proche: false), duree: 0.24, courbe: Courbe.douce),
  ]),
  'plank_jack': _suite([
    Cle(
      _pompe(yPaume - 0.285, zPieds: 0.04),
      duree: 0.24,
      courbe: Courbe.lancee,
    ),
    Cle(
      _pompe(yPaume - 0.295, zPieds: 0.14).copier(
        piedCibleP: const Cible(0.09, _pointe - 0.03, 0.14),
        piedCibleL: const Cible(0.09, _pointe - 0.03, -0.14),
      ),
      duree: 0.12,
      courbe: Courbe.explosive,
    ),
    Cle(
      _pompe(yPaume - 0.285, zPieds: 0.22),
      duree: 0.12,
      courbe: Courbe.lancee,
    ),
    Cle(
      _pompe(yPaume - 0.295, zPieds: 0.14).copier(
        piedCibleP: const Cible(0.09, _pointe - 0.03, 0.14),
        piedCibleL: const Cible(0.09, _pointe - 0.03, -0.14),
      ),
      duree: 0.12,
      courbe: Courbe.explosive,
    ),
  ], camera: Camera3.dessus),
  'bear_crawl': _suite([
    Cle(_oursPas(1), duree: 0.45, courbe: Courbe.douce),
    Cle(_oursPas(-1), duree: 0.45, courbe: Courbe.douce),
  ]),
  'chenille': _suite([
    Cle(_pieds(_pose, 0.3).copier(x: 0.3), duree: 0.7, tenue: 0.3),
    // On se plie, les mains au sol devant les pieds.
    Cle(
      _pieds(_pose, 0.3).copier(
        x: 0.22,
        y: 0.5,
        tronc: 52,
        tete: 66,
        dos: 6,
        mainP: const Cible(0.46, yPaume, 0.09),
        mainL: const Cible(0.46, yPaume, -0.09),
      ),
      duree: 1.0,
    ),
    // Les mains avancent…
    Cle(
      _pieds(_pose, 0.3, hP: 0.03, hL: 0.03).copier(
        x: 0.4,
        y: 0.53,
        tronc: 40,
        tete: 40,
        piedP: 40,
        piedL: 40,
        mainP: const Cible(0.7, yPaume, 0.1),
        mainL: const Cible(0.7, yPaume, -0.1),
        coudeP: const V3(-0.3, -0.4, 1),
        coudeL: const V3(-0.3, -0.4, -1),
      ),
      duree: 0.9,
    ),
    // … jusqu'à la planche.
    Cle(
      _pompe(
        yPaume - 0.285,
        appui: const Offset(0.27, _pointe),
        main: const Offset(0.87, yPaume),
      ),
      duree: 0.8,
      tenue: 0.4,
    ),
    Cle(
      _pieds(_pose, 0.3, hP: 0.03, hL: 0.03).copier(
        x: 0.4,
        y: 0.53,
        tronc: 40,
        tete: 40,
        piedP: 40,
        piedL: 40,
        mainP: const Cible(0.7, yPaume, 0.1),
        mainL: const Cible(0.7, yPaume, -0.1),
        coudeP: const V3(-0.3, -0.4, 1),
        coudeL: const V3(-0.3, -0.4, -1),
      ),
      duree: 0.8,
    ),
    Cle(
      _pieds(_pose, 0.3).copier(
        x: 0.22,
        y: 0.5,
        tronc: 52,
        tete: 66,
        dos: 6,
        mainP: const Cible(0.46, yPaume, 0.09),
        mainL: const Cible(0.46, yPaume, -0.09),
      ),
      duree: 0.9,
    ),
  ]),
  // ══ SUR PLACE ══════════════════════════════════════════════════════════
  'montees_genoux': _allure(
    duree: 0.62,
    pas: 0.03,
    appui: 0.36,
    lever: 0.03,
    genou: 0.19,
    course: true,
    rebond: 0.012,
    tronc: -86,
    bras: 42,
    coude: 80,
    n: 12,
  ),
  'sprint_sur_place': _allure(
    duree: 0.42,
    pas: 0.03,
    appui: 0.36,
    lever: 0.03,
    genou: 0.12,
    course: true,
    rebond: 0.01,
    tronc: -80,
    bras: 50,
    coude: 85,
    n: 12,
  ),
  'talons_fesses': _allure(
    duree: 0.62,
    pas: 0.02,
    appui: 0.36,
    lever: 0.02,
    talon: 0.2,
    course: true,
    rebond: 0.012,
    tronc: -86,
    bras: 34,
    coude: 80,
    n: 12,
  ),
  'course_sur_place': _allure(
    duree: 0.66,
    pas: 0.03,
    appui: 0.4,
    lever: 0.03,
    genou: 0.06,
    talon: 0.06,
    course: true,
    rebond: 0.012,
    tronc: -84,
    bras: 34,
    coude: 80,
    n: 12,
  ),
  'course': _allure(
    duree: 0.72,
    pas: 0.2,
    appui: 0.36,
    lever: 0.07,
    talon: 0.1,
    genou: 0.04,
    course: true,
    yHanche: hDebout + 0.012,
    rebond: 0.016,
    tronc: -80,
    bras: 40,
    coude: 84,
  ),
  'sprints': _allure(
    duree: 0.58,
    pas: 0.25,
    appui: 0.32,
    lever: 0.08,
    talon: 0.14,
    genou: 0.08,
    course: true,
    yHanche: hDebout + 0.016,
    rebond: 0.018,
    tronc: -74,
    bras: 55,
    coude: 88,
  ),
  'marche': _allure(duree: 1.1),
  'marche_rapide': _allure(
    duree: 0.9,
    pas: 0.14,
    bras: 32,
    coude: 60,
    tronc: -85,
    yHanche: hDebout + 0.004,
  ),
  // Sur un sol qui MONTE (il était plat) : chaque pied se pose sur la
  // pente, pointe relevée ; le buste penché vers l'avant.
  'marche_cote': _allure(
    duree: 1.2,
    pas: 0.11,
    tronc: -80,
    bras: 24,
    coude: 30,
    yHanche: hDebout + 0.008,
    retouche: (p, u) => _surLaPente(p, _penteCote),
    accessoires: const Accessoires(pente: _penteCote),
  ),
  'velo': _suite([
    for (var i = 0; i < 12; i++)
      Cle(
        _pedaler(2 * math.pi * i / 12),
        duree: 0.9 / 12,
        courbe: Courbe.reguliere,
      ),
  ], accessoires: const Accessoires(velo: true)),
  'corde': _suite([
    // La corde passe sous les pieds au début du cycle : on est en l'air.
    Cle(
      _mainsCorde(
        _pieds(_pose, 0.47, z: 0.05, hP: 0.045, hL: 0.045),
      ).copier(y: hDebout - 0.045, piedP: 45, piedL: 45),
      duree: 0.24,
      courbe: Courbe.douce,
    ),
    Cle(
      _mainsCorde(
        _pieds(_pose, 0.47, z: 0.05, hP: 0.02, hL: 0.02),
      ).copier(y: hDebout + 0.004, piedP: 25, piedL: 25),
      duree: 0.24,
      courbe: Courbe.douce,
    ),
  ], accessoires: const Accessoires(corde: true)),
  'boxe': _suite([
    Cle(_gardeBoxe(), duree: 0.3, tenue: 0.1),
    // Direct du bras avant (loin).
    Cle(
      _gardeBoxe(torsion: 12).copier(
        mainL: const Cible(0.8, 0.22, -0.03),
        coudeL: const V3(0, 1, -0.6),
      ),
      duree: 0.14,
      courbe: Courbe.explosive,
    ),
    Cle(_gardeBoxe(rebond: 0.012), duree: 0.2),
    // Direct du bras arrière (proche), la hanche tourne.
    Cle(
      _gardeBoxe(torsion: -26).copier(
        x: 0.48,
        mainP: const Cible(0.82, 0.22, 0.0),
        coudeP: const V3(0, 1, 0.6),
      ),
      duree: 0.16,
      courbe: Courbe.explosive,
    ),
    Cle(_gardeBoxe(rebond: 0.012), duree: 0.22),
  ]),
  'boxe_crochets': _suite([
    Cle(_gardeBoxe(), duree: 0.3, tenue: 0.1),
    Cle(
      _gardeBoxe(torsion: -34).copier(
        mainP: const Cible(0.66, 0.24, -0.08),
        coudeP: const V3(0, -0.2, 1),
      ),
      duree: 0.18,
      courbe: Courbe.explosive,
    ),
    Cle(_gardeBoxe(rebond: 0.012), duree: 0.22),
    Cle(
      _gardeBoxe(torsion: 30).copier(
        mainL: const Cible(0.68, 0.24, 0.1),
        coudeL: const V3(0, -0.2, -1),
      ),
      duree: 0.18,
      courbe: Courbe.explosive,
    ),
    Cle(_gardeBoxe(rebond: 0.012), duree: 0.22),
  ]),
  'patineur': _suite([
    Cle(_patineur(proche: true), duree: 0.3, tenue: 0.12),
    Cle(
      _patineur(proche: true, air: true),
      duree: 0.2,
      courbe: Courbe.explosive,
    ),
    Cle(
      _patineur(proche: false),
      duree: 0.2,
      courbe: Courbe.lancee,
      tenue: 0.12,
    ),
    Cle(
      _patineur(proche: false, air: true),
      duree: 0.2,
      courbe: Courbe.explosive,
    ),
  ], camera: Camera3.face),
  'pas_chasses': _suite([
    Cle(_bandeLaterale(0, 0.1, -0.1), duree: 0.16),
    Cle(_bandeLaterale(0.05, 0.19, -0.02, levP: 0.03), duree: 0.13),
    Cle(_bandeLaterale(0.1, 0.2, 0.0), duree: 0.13),
    Cle(_bandeLaterale(0.05, 0.12, -0.08, levL: 0.03), duree: 0.13),
  ], camera: Camera3.face),
};

/// Les poignées de la corde : mains près des hanches, écartées, avant-bras
/// en avant.
Pose3 _mainsCorde(Pose3 p) => p.copier(
  mainP: const Cible(0.52, 0.46, 0.17),
  mainL: const Cible(0.52, 0.46, -0.17),
  coudeP: const V3(-0.6, 1, 0.3),
  coudeL: const V3(-0.6, 1, -0.3),
);

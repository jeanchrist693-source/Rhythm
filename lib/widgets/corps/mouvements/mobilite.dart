// lib/widgets/corps/mouvements/mobilite.dart
//
// La MOBILITÉ, réécrite pour la fidélité : des étirements TENUS (on
// s'installe, puis on respire dans la posture, qui s'approfondit un peu à
// chaque expiration), et des mobilisations lentes (cercles, balanciers,
// chat-vache, rotations).

part of '../animations_corps.dart';

// ── Positions ──────────────────────────────────────────────────────────────

/// Une posture qu'on prend en [entree] secondes, puis qu'on tient en
/// respirant : [b] est la même posture, un peu plus profonde.
AnimCorps _tenir(
  Pose3 depart,
  Pose3 a,
  Pose3 b, {
  double entree = 1.4,
  double souffle = 2.6,
  Camera3 camera = Camera3.profil,
  Accessoires accessoires = const Accessoires(),
}) => _suite(
  [
    Cle(depart, duree: entree, tenue: 0.6),
    Cle(a, duree: entree),
    Cle(b, duree: souffle, courbe: Courbe.douce),
    Cle(a, duree: souffle, courbe: Courbe.douce),
    Cle(b, duree: souffle, courbe: Courbe.douce),
  ],
  camera: camera,
  accessoires: accessoires,
);

/// Une posture tenue sans entrée : on respire dedans.
AnimCorps _respirer(
  Pose3 a,
  Pose3 b, {
  double souffle = 2.4,
  Camera3 camera = Camera3.profil,
  Accessoires accessoires = const Accessoires(),
}) => _suite(
  [
    Cle(a, duree: souffle, courbe: Courbe.douce),
    Cle(b, duree: souffle, courbe: Courbe.douce),
  ],
  camera: camera,
  accessoires: accessoires,
);

/// Debout, penché en avant, jambes presque tendues : le tronc descend à
/// [tronc] degrés, la hanche recule.
Pose3 _plie(double tronc) {
  final f = ((tronc + 90) / 185).clamp(0.0, 1.0);
  return _brasDirects(
    _pieds(_pose, 0.47, z: 0.06).copier(
      x: 0.47 - 0.075 * f,
      y: hDebout + 0.012 * f,
      tronc: tronc,
      tete: tronc + 8 * f,
      dos: 10 * f,
    ),
    90 + 6 * f,
    6,
    92 + 8 * f,
    4,
  );
}

/// La fente basse : le pied proche devant, le genou loin posé au sol,
/// la hanche avancée de [avance].
Pose3 _fenteBasse(double avance, {double torsion = 0}) {
  const genou = Offset(0.313, kSol - 0.03);
  final h = Offset(0.4 + avance, 0.704 + avance * 0.5);
  final cuisse = _angle(h.dx, h.dy, genou.dx, genou.dy);
  return _pose
      .copier(
        x: h.dx,
        y: h.dy,
        tronc: -86 + avance * 40,
        torsion: torsion,
        sansCibles: true,
        cuisseL: cuisse,
        jambeL: 180,
        piedL: 178,
        ecartCuisseL: 2,
      )
      .copier(
        piedCibleP: const Cible(0.62, yCheville, 0.07),
        genouP: const V3(1, -0.2, 0.1),
      );
}

/// Le pigeon : la jambe proche pliée devant, le tibia en travers ; la
/// jambe loin tendue loin derrière ; [penche] : le buste qui descend.
Pose3 _pigeon(double penche) => _pose.copier(
  x: 0.46,
  y: kSol - 0.085,
  tronc: -84 + penche * 90,
  tete: -78 + penche * 110,
  dos: penche * 8,
  sansCibles: true,
  cuisseP: 14,
  ecartCuisseP: 34,
  jambeP: 150,
  ecartJambeP: -62,
  piedP: 150,
  cuisseL: 176,
  ecartCuisseL: 2,
  jambeL: 180,
  piedL: 178,
  brasP: 90 - penche * 80,
  brasL: 90 - penche * 80,
  avantBrasP: 90 - penche * 84,
  avantBrasL: 90 - penche * 84,
  ecartBrasP: 14,
  ecartBrasL: 14,
);

/// Allongé sur le dos, bras en croix au sol, les genoux pliés qui tombent
/// de [cote] (−1 : vers le côté loin, 1 : vers nous, 0 : au centre).
Pose3 _torsionCouchee(double cote) => _dosLibre.copier(
  brasP: 180,
  brasL: 180,
  ecartBrasP: 84,
  ecartBrasL: 84,
  avantBrasP: 180,
  avantBrasL: 180,
  ecartAvantBrasP: 86,
  ecartAvantBrasL: 86,
  teteTourne: -30 * cote,
  cuisseP: -62 + 50 * cote.abs(),
  cuisseL: -62 + 50 * cote.abs(),
  ecartCuisseP: 66 * cote,
  ecartCuisseL: -66 * cote,
  jambeP: 60 - 56 * cote.abs(),
  jambeL: 60 - 56 * cote.abs(),
  ecartJambeP: 60 * cote,
  ecartJambeL: -60 * cote,
  piedP: 20,
  piedL: 20,
);

/// Les mains posées sur les hanches (qui bougent avec le bassin).
Pose3 _mainsHanches(Pose3 p) {
  final x = p.x + 0.015, y = p.y - 0.04;
  return p.copier(
    mainP: Cible(x, y, p.dz + 0.12),
    mainL: Cible(x, y, p.dz - 0.12),
    coudeP: const V3(-0.4, 0.3, 1),
    coudeL: const V3(-0.4, 0.3, -1),
  );
}

/// Debout sur la jambe loin, la jambe proche qui balance à [cuisse] degrés
/// (écartée de [ecart]), une main sur la hanche.
Pose3 _balancier(double cuisse, {double ecart = 3}) => _pieds(_pose, 0.47)
    .copier(
      piedCibleP: null,
      sansCibles: true,
      cuisseP: cuisse,
      ecartCuisseP: ecart,
      jambeP: cuisse + (cuisse < 90 ? 12 : 4),
      ecartJambeP: ecart,
      piedP: cuisse < 90 ? cuisse - 30 : 60,
      brasL: 40,
      avantBrasL: 20,
      ecartBrasL: 40,
      ecartAvantBrasL: 50,
    )
    .copier(piedCibleL: const Cible(0.47, yCheville, -0.05));

// ── Les mouvements ─────────────────────────────────────────────────────────

final Map<String, AnimCorps> _mobilite3 = {
  // ══ DEBOUT ═════════════════════════════════════════════════════════════
  'flexion_avant': _tenir(
    _plie(-90),
    _plie(50).copier(
      mainP: const Cible(0.53, yPaume - 0.006, 0.09),
      mainL: const Cible(0.53, yPaume - 0.006, -0.09),
      coudeP: const V3(-0.2, 0, 1),
      coudeL: const V3(-0.2, 0, -1),
    ),
    _plie(62).copier(
      mainP: const Cible(0.5, yPaume - 0.006, 0.1),
      mainL: const Cible(0.5, yPaume - 0.006, -0.1),
      coudeP: const V3(-0.2, 0, 1),
      coudeL: const V3(-0.2, 0, -1),
    ),
    entree: 1.8,
  ),
  'etirement_ischios_chaise': _tenir(
    _pieds(_pose, 0.4).copier(
      x: 0.4,
      piedCibleP: const Cible(0.74, 0.66 - 0.028, 0.06),
      genouP: const V3(0, -1, 0),
      piedP: -70,
    ),
    _pieds(_pose, 0.4).copier(
      x: 0.4,
      y: hDebout - 0.01,
      tronc: -46,
      dos: 3,
      tete: -40,
      piedCibleP: const Cible(0.74, 0.66 - 0.028, 0.06),
      genouP: const V3(0, -1, 0),
      piedP: -70,
      mainP: const Cible(0.66, 0.6, 0.08),
      mainL: const Cible(0.66, 0.6, 0.02),
    ),
    _pieds(_pose, 0.4).copier(
      x: 0.39,
      y: hDebout - 0.005,
      tronc: -34,
      dos: 4,
      tete: -30,
      piedCibleP: const Cible(0.74, 0.66 - 0.028, 0.06),
      genouP: const V3(0, -1, 0),
      piedP: -70,
      mainP: const Cible(0.7, 0.62, 0.08),
      mainL: const Cible(0.7, 0.62, 0.02),
    ),
    accessoires: const Accessoires(
      marche: Rect.fromLTRB(0.66, 0.66, 0.96, kSol),
    ),
  ),
  'etirement_quadriceps': _tenir(
    _pieds(_pose, 0.47, z: 0.05),
    _pieds(_pose, 0.47, z: 0.05).copier(
      piedCibleP: const Cible(0.37, 0.57, 0.07),
      genouP: const V3(0.1, 1, 0),
      piedP: 190,
      mainP: const Cible(0.36, 0.56, 0.1),
      coudeP: const V3(-0.2, 0.4, 1),
      brasL: 60,
      avantBrasL: 40,
      ecartBrasL: 38,
      ecartAvantBrasL: 30,
    ),
    _pieds(_pose, 0.47, z: 0.05).copier(
      piedCibleP: const Cible(0.36, 0.55, 0.07),
      genouP: const V3(0.05, 1, 0),
      piedP: 196,
      mainP: const Cible(0.35, 0.54, 0.1),
      coudeP: const V3(-0.2, 0.4, 1),
      brasL: 60,
      avantBrasL: 40,
      ecartBrasL: 38,
      ecartAvantBrasL: 30,
    ),
  ),
  'etirement_mollet': _tenir(
    _pieds(_pose, 0.47).copier(x: 0.47),
    _mainsEn(
      _pieds(
        _pose,
        0.6,
        xL: 0.28,
      ).copier(x: 0.45, y: 0.52, tronc: -70, piedL: 0),
      0.786,
      0.3,
      0.13,
      const V3(-0.5, 0.6, 1),
    ),
    _mainsEn(
      _pieds(
        _pose,
        0.6,
        xL: 0.28,
      ).copier(x: 0.47, y: 0.525, tronc: -66, piedL: 0),
      0.786,
      0.3,
      0.13,
      const V3(-0.5, 0.6, 1),
    ),
    accessoires: const Accessoires(mur: 0.8),
  ),
  'etirement_pectoraux': _tenir(
    _pieds(_pose, 0.5, xL: 0.4, z: 0.06).copier(x: 0.45),
    _brasDirects(
      _pieds(_pose, 0.52, xL: 0.4, z: 0.06).copier(x: 0.47, tronc: -86),
      176,
      84,
      -90,
      10,
    ).copier(brasL: 90, avantBrasL: 88, ecartBrasL: 8, ecartAvantBrasL: 6),
    _brasDirects(
      _pieds(_pose, 0.53, xL: 0.4, z: 0.06).copier(x: 0.49, tronc: -84),
      178,
      70,
      -92,
      10,
    ).copier(brasL: 90, avantBrasL: 88, ecartBrasL: 8, ecartAvantBrasL: 6),
    accessoires: const Accessoires(barreFixe: Offset(0.45, 0.02)),
  ),
  'etirement_biceps': _tenir(
    _pieds(_pose, 0.47, z: 0.06),
    _pieds(_pose, 0.47, z: 0.06).copier(
      torsion: -14,
      mainP: const Cible(0.214, 0.3, 0.12),
      coudeP: const V3(0, 1, 0.3),
    ),
    _pieds(_pose, 0.47, z: 0.06).copier(
      torsion: -24,
      mainP: const Cible(0.214, 0.3, 0.12),
      coudeP: const V3(0, 1, 0.3),
    ),
    accessoires: const Accessoires(mur: 0.2),
  ),
  'etirement_triceps': _tenir(
    _pieds(_pose, 0.47, z: 0.06),
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), -96, 10, 104, -18).copier(
      brasL: 90,
      avantBrasL: 88,
      ecartBrasL: 6,
      ecartAvantBrasL: 4,
      mainL: const Cible(0.47, 0.13, 0.06),
      coudeL: const V3(0.3, -1, -1),
    ),
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), -98, 6, 104, -22).copier(
      inclinaison: -4,
      mainL: const Cible(0.465, 0.13, 0.04),
      coudeL: const V3(0.3, -1, -1),
    ),
    camera: Camera3.face,
  ),
  'etirement_epaule': _tenir(
    _pieds(_pose, 0.47, z: 0.06),
    _brasDirects(
      _pieds(_pose, 0.47, z: 0.06),
      2,
      -62,
      2,
      -66,
    ).copier(mainL: const Cible(0.56, 0.29, -0.03), coudeL: const V3(0, 1, -1)),
    _brasDirects(
      _pieds(_pose, 0.47, z: 0.06),
      2,
      -70,
      2,
      -74,
    ).copier(mainL: const Cible(0.55, 0.29, -0.05), coudeL: const V3(0, 1, -1)),
    camera: Camera3.face,
  ),
  'flexion_laterale': _suite([
    Cle(_pieds(_pose, 0.47, z: 0.08), duree: 1.0, tenue: 0.3),
    Cle(
      _brasDirects(_pieds(_pose, 0.47, z: 0.08), -80, -34, -70, -60).copier(
        inclinaison: -22,
        tete: -76,
        brasL: 88,
        avantBrasL: 80,
        ecartBrasL: 14,
        ecartAvantBrasL: 20,
      ),
      duree: 1.6,
      tenue: 1.2,
    ),
    Cle(_pieds(_pose, 0.47, z: 0.08), duree: 1.4, tenue: 0.3),
    Cle(
      _pieds(_pose, 0.47, z: 0.08).copier(
        inclinaison: 22,
        tete: -76,
        brasL: -80,
        ecartBrasL: -34,
        avantBrasL: -70,
        ecartAvantBrasL: -60,
        brasP: 88,
        avantBrasP: 80,
        ecartBrasP: 14,
        ecartAvantBrasP: 20,
      ),
      duree: 1.6,
      tenue: 1.2,
    ),
  ], camera: Camera3.face),
  'cercles_bras': _suite([
    for (var i = 0; i < 8; i++)
      Cle(
        _brasDirects(
          _pieds(_pose, 0.47, z: 0.07),
          -45.0 * i,
          78,
          -45.0 * i,
          78,
        ),
        duree: 0.18,
        courbe: Courbe.reguliere,
      ),
  ], camera: Camera3.face),
  'rotation_hanches': _suite([
    for (var i = 0; i < 8; i++)
      Cle(
        _mainsHanches(
          _pieds(_pose, 0.47, z: 0.1).copier(
            dx: 0.04 * math.cos(i * math.pi / 4),
            dz: 0.04 * math.sin(i * math.pi / 4),
            tronc: -90 - 6 * math.cos(i * math.pi / 4),
            inclinaison: -6 * math.sin(i * math.pi / 4),
            y: hDebout + 0.01,
          ),
        ),
        duree: 0.4,
        courbe: Courbe.reguliere,
      ),
  ], camera: Camera3.face),
  'balancier_jambe': _suite([
    Cle(_balancier(128), duree: 0.7, courbe: Courbe.douce),
    Cle(_balancier(18), duree: 0.7, courbe: Courbe.douce),
  ]),
  'balancier_lateral': _suite(
    [
      Cle(
        _mainsEn(
          _balancier(90, ecart: -24),
          0.786,
          0.32,
          0.13,
          const V3(0, 1, 1),
        ),
        duree: 0.7,
        courbe: Courbe.douce,
      ),
      Cle(
        _mainsEn(
          _balancier(90, ecart: 44),
          0.786,
          0.32,
          0.13,
          const V3(0, 1, 1),
        ),
        duree: 0.7,
        courbe: Courbe.douce,
      ),
    ],
    camera: Camera3.dos,
    accessoires: const Accessoires(mur: 0.8),
  ),
  // ══ À GENOUX, À QUATRE PATTES ══════════════════════════════════════════
  'fente_basse': _tenir(
    _fenteBasse(0).copier(tronc: -88),
    _mainsEn(_fenteBasse(0.02), 0.6, 0.64, 0.08, const V3(-0.5, 1, 0.5)),
    _mainsEn(_fenteBasse(0.045), 0.61, 0.645, 0.08, const V3(-0.5, 1, 0.5)),
  ),
  'fente_basse_rotation': _suite([
    Cle(
      _fenteBasse(0.02).copier(
        tronc: -40,
        mainL: const Cible(0.56, yPaume, 0.0),
        mainP: const Cible(0.56, yPaume, 0.1),
      ),
      duree: 1.0,
      tenue: 0.3,
    ),
    Cle(
      _brasDirects(
        _fenteBasse(0.02, torsion: -60).copier(tronc: -46),
        -90,
        30,
        -90,
        30,
      ).copier(mainL: const Cible(0.56, yPaume, 0.0)),
      duree: 1.2,
      tenue: 1.0,
    ),
  ]),
  'enfant': _respirer(_enfant(0), _enfant(1), souffle: 2.8),
  'chat_vache': _suite([
    Cle(
      _quatrePattes().copier(dos: 30, tete: 64, tronc: -14),
      duree: 1.6,
      courbe: Courbe.douce,
      tenue: 0.5,
    ),
    Cle(
      _quatrePattes().copier(dos: -26, tete: -44, tronc: -5),
      duree: 1.6,
      courbe: Courbe.douce,
      tenue: 0.5,
    ),
  ]),
  'rotation_thoracique': _suite([
    Cle(_rotationThoracique(ouvert: false), duree: 1.3, tenue: 0.3),
    Cle(_rotationThoracique(ouvert: true), duree: 1.5, tenue: 0.6),
  ]),
  'chien_tete_bas': _suite([
    Cle(
      _pique(0.33, 0.49, 55, pieds: const Offset(0.12, kSol - 0.085)),
      duree: 1.2,
    ),
    // On pédale : un talon descend, puis l'autre.
    Cle(
      _pique(
        0.33,
        0.49,
        55,
        pieds: const Offset(0.12, kSol - 0.085),
      ).copier(piedCibleP: const Cible(0.13, kSol - 0.05, 0.06), piedP: 18),
      duree: 1.0,
      courbe: Courbe.douce,
    ),
    Cle(
      _pique(
        0.33,
        0.49,
        55,
        pieds: const Offset(0.12, kSol - 0.085),
      ).copier(piedCibleL: const Cible(0.13, kSol - 0.05, -0.06), piedL: 18),
      duree: 1.2,
      courbe: Courbe.douce,
    ),
  ]),
  // ══ AU SOL ═════════════════════════════════════════════════════════════
  'cobra': _tenir(_cobra(0), _cobra(0.8), _cobra(1)),
  'chien_tete_haut': _tenir(
    _cobra(0),
    _pique(
      0.511,
      0.78,
      -47,
      pieds: const Offset(0.12, kSol - 0.035),
    ).copier(tete: -60, dos: -8, piedP: 180, piedL: 180),
    _pique(
      0.52,
      0.79,
      -45,
      pieds: const Offset(0.12, kSol - 0.035),
    ).copier(tete: -66, dos: -10, piedP: 180, piedL: 180),
  ),
  'pigeon': _tenir(_pigeon(0), _pigeon(0.35), _pigeon(0.9), entree: 1.6),
  'assis_flexion': _tenir(
    _brasDirects(_assisJambesTendues, 90, 10, 88, 8),
    _brasDirects(
      _assisJambesTendues.copier(tronc: -30, tete: -18, dos: 10),
      14,
      8,
      12,
      6,
    ),
    _brasDirects(
      _assisJambesTendues.copier(tronc: -20, tete: -6, dos: 12),
      10,
      8,
      8,
      6,
    ),
  ),
  'papillon': _respirer(
    _papillon(0),
    _papillon(1),
    souffle: 1.2,
    camera: Camera3.face,
  ),
  'torsion_couchee': _suite([
    Cle(_torsionCouchee(0), duree: 1.4, tenue: 0.3),
    Cle(_torsionCouchee(-1), duree: 1.6, tenue: 1.6),
    Cle(_torsionCouchee(0), duree: 1.4, tenue: 0.3),
    Cle(_torsionCouchee(1), duree: 1.6, tenue: 1.6),
  ], camera: Camera3.dessus),
  'torsion_assise': _tenir(
    _torsionAssise(0),
    _torsionAssise(0.8),
    _torsionAssise(1),
  ),
  'etirement_fessier': _tenir(
    _fessier(tire: false),
    _fessier(tire: true),
    _fessier(tire: true, plus: true),
    camera: Camera3.dessus,
  ),
  'genoux_poitrine': _respirer(
    _genouxPoitrine(0),
    _genouxPoitrine(1),
    souffle: 1.8,
  ),
  'respiration': _respirer(_respiration(0), _respiration(1), souffle: 3.2),
  'jambes_mur': _respirer(
    _jambesMur(0),
    _jambesMur(1),
    souffle: 3.2,
    accessoires: const Accessoires(mur: 0.775),
  ),
};

// ── Les positions composées ────────────────────────────────────────────────

/// La posture de l'enfant : assis sur les talons, le buste posé sur les
/// cuisses, les bras allongés devant ; [souffle] l'allonge un peu.
Pose3 _enfant(double souffle) => _pose.copier(
  x: 0.38,
  y: 0.79 + souffle * 0.004,
  tronc: 16 - souffle * 3,
  tete: 4,
  dos: 10,
  sansCibles: true,
  cuisseP: 28,
  cuisseL: 28,
  ecartCuisseP: 10,
  ecartCuisseL: 10,
  jambeP: 180,
  jambeL: 180,
  piedP: 180,
  piedL: 180,
  brasP: 10 - souffle * 2,
  brasL: 10 - souffle * 2,
  avantBrasP: 10,
  avantBrasL: 10,
  ecartBrasP: 12,
  ecartBrasL: 12,
  ecartAvantBrasP: 8,
  ecartAvantBrasL: 8,
);

/// Le cobra : à plat ventre, les mains sous les épaules ; la poitrine
/// monte de [haut] (0 à 1), les hanches restent au sol.
Pose3 _cobra(double haut) {
  final t = -34.0 * haut;
  final p = _aPlatVentre.copier(
    x: 0.45,
    tronc: t,
    tete: t - 16 * haut,
    dos: -8 * haut,
  );
  final s = rad(t);
  final ex = 0.45 + math.cos(s) * _lEpaule;
  return p.copier(
    mainP: Cible(ex - 0.03, yPaume, 0.12),
    mainL: Cible(ex - 0.03, yPaume, -0.12),
    coudeP: const V3(-1, -0.3, 0.4),
    coudeL: const V3(-1, -0.3, -0.4),
  );
}

/// La rotation thoracique : à quatre pattes, la main proche derrière la
/// tête ; le coude monte vers le plafond ([ouvert]) ou passe sous le
/// buste.
Pose3 _rotationThoracique({required bool ouvert}) {
  final p = _quatrePattes().copier(torsion: ouvert ? 48 : -24, tete: -14);
  final (x, y) = _centreTete(p);
  return p.copier(
    mainP: Cible(x - 0.02, y - 0.03, 0.03),
    coudeP: ouvert ? const V3(0, -1, 0.6) : const V3(0.2, 1, -0.4),
  );
}

/// Le papillon : assis, plantes des pieds jointes, les mains dessus ; les
/// genoux battent vers le sol ([bas]).
Pose3 _papillon(double bas) => _pose.copier(
  x: 0.44,
  y: kSol - 0.06,
  tronc: -84,
  tete: -76,
  piedCibleP: const Cible(0.62, kSol - 0.04, 0.025),
  piedCibleL: const Cible(0.62, kSol - 0.04, -0.025),
  genouP: V3(0.2, -0.5 + 0.6 * bas, 1),
  genouL: V3(0.2, -0.5 + 0.6 * bas, -1),
  piedP: 20,
  piedL: 20,
  mainP: const Cible(0.64, kSol - 0.07, 0.035),
  mainL: const Cible(0.64, kSol - 0.07, -0.035),
  coudeP: const V3(0, 1, 1),
  coudeL: const V3(0, 1, -1),
);

/// La torsion assise : jambe loin tendue, pied proche croisé par-dessus ;
/// le buste tourne vers le genou levé de [tour] (0 à 1), la main proche
/// posée au sol derrière.
Pose3 _torsionAssise(double tour) => _assisJambesTendues
    .copier(
      torsion: -44 * tour,
      teteTourne: -30 * tour,
      brasL: 70,
      avantBrasL: 20,
      ecartBrasL: -30 * tour,
      ecartAvantBrasL: -40 * tour,
    )
    .copier(
      piedCibleP: const Cible(0.55, yCheville, -0.07),
      genouP: const V3(0.3, -1, 0.1),
      piedP: 10,
      mainP: const Cible(0.26, yPaume, 0.12),
      coudeP: const V3(-0.2, 0.4, 1),
    );

/// L'étirement des fessiers en « 4 » : sur le dos, la cheville proche
/// posée sur le genou loin ; [tire] : la jambe loin ramenée vers soi.
Pose3 _fessier({required bool tire, bool plus = false}) {
  final p = _dosAuSol.copier(tete: 184);
  if (!tire) {
    return p.copier(
      piedCibleP: const Cible(0.68, 0.7, -0.03),
      genouP: const V3(0.2, -0.3, 1),
      piedP: 0,
    );
  }
  final k = plus ? 0.02 : 0.0;
  return p.copier(
    piedCibleL: Cible(0.7 - k, 0.66 - k, -0.08),
    genouL: const V3(0.3, -1, -0.1),
    piedL: -40,
    piedCibleP: Cible(0.6 - k, 0.58 - k, -0.03),
    genouP: const V3(0.2, -0.3, 1),
    piedP: 0,
    mainP: Cible(0.62 - k, 0.66 - k, -0.06),
    mainL: Cible(0.62 - k, 0.66 - k, -0.11),
    coudeP: const V3(0, 1, 1),
    coudeL: const V3(0, 1, -1),
  );
}

/// Genoux à la poitrine : sur le dos, les mains sur les tibias, qui
/// ramènent un peu plus à chaque souffle.
Pose3 _genouxPoitrine(double serre) => _dosLibre.copier(
  tete: 188,
  cuisseP: -124 - serre * 8,
  cuisseL: -124 - serre * 8,
  ecartCuisseP: 6,
  ecartCuisseL: 6,
  jambeP: -26 - serre * 8,
  jambeL: -26 - serre * 8,
  piedP: -60,
  piedL: -60,
  mainP: Cible(0.56 - serre * 0.01, 0.7, 0.09),
  mainL: Cible(0.56 - serre * 0.01, 0.7, -0.09),
  coudeP: const V3(0, 1, 1),
  coudeL: const V3(0, 1, -1),
);

/// La respiration ventrale : sur le dos, genoux pliés, une main sur le
/// ventre (qui se soulève), l'autre sur la poitrine.
Pose3 _respiration(double inspire) => _dosAuSol.copier(
  tete: 184,
  mainP: Cible(0.5, kSol - 0.13 - inspire * 0.014, 0.03),
  mainL: Cible(0.42, kSol - 0.125 - inspire * 0.004, -0.02),
  coudeP: const V3(0, 1, 1),
  coudeL: const V3(0, 1, -1),
);

/// Jambes au mur : sur le dos, les fesses contre le mur, les jambes
/// tendues contre lui, les bras relâchés au sol.
Pose3 _jambesMur(double souffle) => _dosLibre.copier(
  x: 0.71,
  tete: 182,
  cuisseP: -90,
  cuisseL: -90,
  jambeP: -90,
  jambeL: -90,
  ecartCuisseP: 3,
  ecartCuisseL: 3,
  piedP: -170 + souffle * 6,
  piedL: -170 + souffle * 6,
  brasP: 30,
  brasL: 30,
  avantBrasP: 20,
  avantBrasL: 20,
  ecartBrasP: 40 + souffle * 3,
  ecartBrasL: 40 + souffle * 3,
  ecartAvantBrasP: 50,
  ecartAvantBrasL: 50,
);

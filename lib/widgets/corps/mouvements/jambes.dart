// lib/widgets/corps/mouvements/jambes.dart
//
// Les JAMBES, réécrites pour la fidélité : les pieds PLANTÉS (cibles), la
// hanche placée selon la vraie géométrie (debout, elle est à l'aplomb du
// pied ; au bas d'un squat, la cuisse est parallèle au sol et les épaules
// restent au-dessus du milieu du pied ; dans une fente, le tibia avant est
// vertical et le genou arrière frôle le sol), les genoux qui suivent la
// pointe des pieds, et le tempo d'une vraie répétition (on descend en
// contrôlant, on remonte plus vivement, on marque un temps).

part of '../animations_corps.dart';

// ── Positions ──────────────────────────────────────────────────────────────

/// Pieds à largeur d'épaules, pointes un peu ouvertes, genoux dans l'axe.
Pose3 _largeur(Pose3 p, {double x = 0.47, double z = 0.072}) =>
    _pieds(p, x, z: z).copier(
      ecartCuisseP: 12,
      ecartCuisseL: 12,
      genouP: const V3(1, 0, 0.32),
      genouL: const V3(1, 0, -0.32),
    );

/// Le bas d'un squat : cuisses parallèles, buste penché, épaules au-dessus
/// du milieu du pied.
Pose3 _basSquat(Pose3 p, {double tronc = -48}) =>
    p.copier(x: 0.335, y: 0.7, tronc: tronc, dos: 3);

/// Les bras tendus devant, à l'horizontale.
Pose3 _brasDevant(Pose3 p) => p.copier(
  brasP: 2,
  avantBrasP: 0,
  brasL: 2,
  avantBrasL: 0,
  ecartBrasP: 9,
  ecartBrasL: 9,
  ecartAvantBrasP: 4,
  ecartAvantBrasL: 4,
);

/// Les mains jointes devant la poitrine.
Pose3 _mainsJointes(Pose3 p, {double bras = 64, double avant = -72}) =>
    p.copier(
      brasP: bras,
      brasL: bras,
      ecartBrasP: -10,
      ecartBrasL: -10,
      avantBrasP: avant,
      avantBrasL: avant,
      ecartAvantBrasP: -34,
      ecartAvantBrasL: -34,
    );

/// Les bras le long du corps, qui pendent (une charge dans chaque main).
Pose3 _brasPendus(Pose3 p, {double ecart = 11}) => p.copier(
  brasP: 90,
  avantBrasP: 90,
  brasL: 90,
  avantBrasL: 90,
  ecartBrasP: ecart,
  ecartBrasL: ecart,
  ecartAvantBrasP: ecart - 3,
  ecartAvantBrasL: ecart - 3,
);

/// Une barre posée sur le haut du dos : les mains la tiennent, larges, les
/// coudes sous la barre.
Pose3 _mainsBarreDos(Pose3 p, double tronc) {
  final penche = tronc + 90;
  return p.copier(
    brasP: 118 + penche * 0.6,
    brasL: 118 + penche * 0.6,
    ecartBrasP: 52,
    ecartBrasL: 52,
    avantBrasP: -118 + penche,
    avantBrasL: -118 + penche,
    ecartAvantBrasP: 18,
    ecartAvantBrasL: 18,
  );
}

/// Le goblet : l'haltère debout contre la poitrine, coudes serrés.
Pose3 _goblet(Pose3 p, double tronc) {
  final penche = tronc + 90;
  return p.copier(
    brasP: 76 - penche * 0.7,
    brasL: 76 - penche * 0.7,
    ecartBrasP: -8,
    ecartBrasL: -8,
    avantBrasP: -80 + penche * 0.3,
    avantBrasL: -80 + penche * 0.3,
    ecartAvantBrasP: -36,
    ecartAvantBrasL: -36,
  );
}

/// Une caisse devant (marche, box jump) et une derrière (squat bulgare).
const Rect _caisseDevant = Rect.fromLTRB(0.56, 0.72, 0.86, kSol);
const Rect _caisseDerriere = Rect.fromLTRB(0.03, 0.69, 0.23, kSol);
const Rect _chaise = Rect.fromLTRB(0.07, 0.675, 0.3, kSol);

/// La cheville d'un pied posé sur la caisse de devant.
const double _surCaisse = 0.72 - 0.034;

/// Couché sur le dos, genoux pliés, pieds plantés en [xPieds] : la hanche
/// en ([hx], [hy]), les omoplates au sol (le tronc s'incline pour que le
/// cou reste posé).
Pose3 _pont(double hx, double hy, {double xPieds = 0.66}) {
  const cou = kSol - 0.052;
  final dy = (cou - hy).clamp(-lTronc, lTronc);
  final ang = 180 - math.asin(dy / lTronc) * 180 / math.pi;
  return _pieds(_pose, xPieds, z: 0.07).copier(
    x: hx,
    y: hy,
    tronc: ang,
    tete: 184,
    brasP: 4,
    avantBrasP: 3,
    brasL: 4,
    avantBrasL: 3,
    ecartBrasP: 18,
    ecartBrasL: 18,
    ecartAvantBrasP: 14,
    ecartAvantBrasL: 14,
    genouP: const V3(0.3, -1, 0.15),
    genouL: const V3(0.3, -1, -0.15),
  );
}

// ── Les mouvements ─────────────────────────────────────────────────────────

final Map<String, AnimCorps> _jambes3 = {
  // ══ SQUATS ═════════════════════════════════════════════════════════════
  'squat': _serie(
    _largeur(_pose),
    _brasDevant(_basSquat(_largeur(_pose))),
    ab: 1.6,
    ba: 1.0,
    tenueA: 0.5,
    tenueB: 0.25,
  ),
  'squat_halteres': _serie(
    _brasPendus(_largeur(_pose)),
    _brasPendus(_basSquat(_largeur(_pose), tronc: -54)),
    ab: 1.6,
    ba: 1.0,
    tenueA: 0.5,
    tenueB: 0.2,
    accessoires: const Accessoires(halteres: true),
  ),
  'squat_goblet': _serie(
    _goblet(_largeur(_pose), -90),
    _goblet(_largeur(_pose).copier(x: 0.35, y: 0.71, tronc: -62, dos: 2), -62),
    ab: 1.6,
    ba: 1.0,
    tenueA: 0.45,
    tenueB: 0.25,
    accessoires: const Accessoires(goblet: true),
  ),
  'squat_barre': _serie(
    _mainsBarreDos(_largeur(_pose, z: 0.08), -90),
    _mainsBarreDos(_basSquat(_largeur(_pose, z: 0.08), tronc: -50), -50),
    ab: 1.7,
    ba: 1.1,
    tenueA: 0.5,
    tenueB: 0.15,
    accessoires: const Accessoires(barreDos: true),
  ),
  'squat_sumo': _serie(
    _mainsJointes(_sumo(_pose)),
    _mainsJointes(_sumo(_pose).copier(y: 0.66, tronc: -82)),
    ab: 1.5,
    ba: 1.0,
    tenueA: 0.45,
    tenueB: 0.3,
    camera: Camera3.face,
  ),
  'squat_sumo_charge': _serie(
    _mainsCharge(_sumo(_pose)),
    _mainsCharge(_sumo(_pose).copier(y: 0.66, tronc: -80)),
    ab: 1.5,
    ba: 1.0,
    tenueA: 0.45,
    tenueB: 0.3,
    camera: Camera3.face,
    accessoires: const Accessoires(goblet: true),
  ),
  'squat_saute': _suite([
    Cle(_largeur(_pose), duree: 0.5, tenue: 0.35),
    Cle(
      _largeur(_pose).copier(
        x: 0.37,
        y: 0.655,
        tronc: -52,
        dos: 3,
        brasP: 150,
        brasL: 150,
        avantBrasP: 140,
        avantBrasL: 140,
      ),
      duree: 0.6,
    ),
    // L'envol : jambes tendues, pointes tendues, bras au ciel.
    Cle(
      _pieds(_pose, 0.47, z: 0.07, hP: 0.1, hL: 0.1).copier(
        y: hDebout - 0.11,
        piedP: 48,
        piedL: 48,
        brasP: -96,
        brasL: -96,
        avantBrasP: -94,
        avantBrasL: -94,
        ecartBrasP: 14,
        ecartBrasL: 14,
      ),
      duree: 0.32,
      courbe: Courbe.explosive,
    ),
    // La réception, amortie.
    Cle(
      _largeur(_pose).copier(
        x: 0.41,
        y: 0.6,
        tronc: -66,
        brasP: 20,
        brasL: 20,
        avantBrasP: 10,
        avantBrasL: 10,
      ),
      duree: 0.34,
      courbe: Courbe.lancee,
    ),
  ]),
  'squat_bulgare': _serie(
    _brasPendus(_bulgare(0.41, 0.5)),
    _brasPendus(_bulgare(0.39, 0.635).copier(tronc: -80)),
    ab: 1.5,
    ba: 1.0,
    tenueA: 0.4,
    tenueB: 0.2,
    accessoires: const Accessoires(halteres: true, marche: _caisseDerriere),
  ),
  'squat_une_jambe': _serie(
    _brasDevant(
      _pieds(_pose, 0.5).copier(
        x: 0.5,
        piedCibleL: const Cible(0.62, yCheville - 0.08),
        cuisseL: 60,
        jambeL: 70,
      ),
    ).copier(sansCibles: false),
    _brasDevant(_pistol()),
    ab: 2.0,
    ba: 1.4,
    tenueA: 0.4,
    tenueB: 0.3,
  ),
  'squat_tenu': _suite([
    Cle(
      _mainsJointes(
        _basSquat(_largeur(_pose), tronc: -58).copier(y: 0.72, x: 0.36),
      ),
      duree: 2,
    ),
    Cle(
      _mainsJointes(
        _basSquat(_largeur(_pose), tronc: -60).copier(y: 0.724, x: 0.358),
      ),
      duree: 2,
    ),
  ]),
  'squat_chaise': _serie(
    _largeur(_pose),
    _brasDevant(_largeur(_pose).copier(x: 0.27, y: 0.62, tronc: -52, dos: 3)),
    ab: 1.5,
    ba: 1.0,
    tenueA: 0.4,
    tenueB: 0.3,
    accessoires: const Accessoires(marche: _chaise),
  ),
  'thruster': _suite([
    Cle(_goblet(_largeur(_pose), -90).copier(), duree: 0.7, tenue: 0.2),
    Cle(
      _goblet(_largeur(_pose).copier(x: 0.35, y: 0.7, tronc: -60, dos: 2), -60),
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
  // ══ FENTES ═════════════════════════════════════════════════════════════
  'fente': _fenteArriere(),
  'fente_halteres': _fenteArriere(
    bras: _brasPendus,
    accessoires: const Accessoires(halteres: true),
  ),
  'fente_barre': _fenteArriere(
    bras: (p) => _mainsBarreDos(p, p.tronc),
    accessoires: const Accessoires(barreDos: true),
  ),
  'fente_sautee': _suite([
    Cle(_fente(avantP: true, bas: true), duree: 0.3, tenue: 0.12),
    Cle(_envolFente(avantP: true), duree: 0.3, courbe: Courbe.explosive),
    Cle(
      _fente(avantP: false, bas: true),
      duree: 0.3,
      courbe: Courbe.lancee,
      tenue: 0.12,
    ),
    Cle(_envolFente(avantP: false), duree: 0.3, courbe: Courbe.explosive),
  ]),
  'fente_laterale': _suite([
    Cle(_mainsJointes(_pieds(_pose, 0.47, z: 0.07)), duree: 0.9, tenue: 0.35),
    Cle(_mainsJointes(_lateral(0.0, 0.5)), duree: 0.45),
    Cle(
      _mainsJointes(_lateral(0.12, 0.64).copier(tronc: -66, dos: 3)),
      duree: 1.2,
      tenue: 0.3,
    ),
    Cle(_mainsJointes(_lateral(0.0, 0.5)), duree: 0.9),
  ], camera: Camera3.face),
  'step_up': _suite([
    Cle(_pieds(_pose, 0.42).copier(x: 0.42), duree: 0.45, tenue: 0.3),
    // Le genou proche monte…
    Cle(
      _pieds(
        _pose,
        0.42,
      ).copier(x: 0.42, tronc: -84, piedCibleP: const Cible(0.58, 0.64)),
      duree: 0.4,
    ),
    // … et le pied se pose sur la caisse.
    Cle(
      _pieds(
        _pose,
        0.66,
        xL: 0.42,
        hP: yCheville - _surCaisse,
      ).copier(x: 0.46, y: 0.505, tronc: -76, dos: 2),
      duree: 0.35,
    ),
    // On pousse dessus : la hanche passe au-dessus du pied, la jambe de
    // derrière se replie et suit.
    Cle(
      _pieds(_pose, 0.66, hP: yCheville - _surCaisse).copier(
        x: 0.64,
        y: hDebout - 0.19,
        tronc: -84,
        piedCibleL: const Cible(0.52, 0.64),
        genouL: const V3(1, 0.1, -0.1),
        brasP: 104,
        avantBrasP: 80,
        brasL: 74,
        avantBrasL: 40,
      ),
      duree: 0.8,
      courbe: Courbe.explosive,
    ),
    Cle(
      _pieds(
        _pose,
        0.66,
        hP: yCheville - _surCaisse,
        hL: yCheville - _surCaisse,
      ).copier(x: 0.66, y: hDebout - (yCheville - _surCaisse)),
      duree: 0.35,
      tenue: 0.3,
    ),
    // On redescend en arrière : la même jambe travaille, le pied de
    // derrière cherche le sol.
    Cle(
      _pieds(_pose, 0.66, hP: yCheville - _surCaisse).copier(
        x: 0.6,
        y: hDebout - 0.16,
        tronc: -84,
        piedCibleL: const Cible(0.5, 0.76),
        genouL: const V3(1, 0.4, -0.1),
      ),
      duree: 0.5,
    ),
    Cle(
      _pieds(
        _pose,
        0.66,
        xL: 0.42,
        hP: yCheville - _surCaisse,
      ).copier(x: 0.47, y: 0.5, tronc: -82),
      duree: 0.7,
    ),
    Cle(
      _pieds(
        _pose,
        0.42,
      ).copier(x: 0.43, tronc: -86, piedCibleP: const Cible(0.58, 0.64)),
      duree: 0.4,
    ),
  ], accessoires: const Accessoires(marche: _caisseDevant)),
  'box_jump': _suite([
    Cle(_largeur(_pose, x: 0.36).copier(x: 0.36), duree: 0.6, tenue: 0.3),
    Cle(
      _largeur(_pose, x: 0.36).copier(
        x: 0.27,
        y: 0.64,
        tronc: -50,
        brasP: 150,
        brasL: 150,
        avantBrasP: 140,
        avantBrasL: 140,
      ),
      duree: 0.55,
    ),
    // L'envol, genoux ramenés.
    Cle(
      _pieds(_pose, 0.6, z: 0.07, hP: 0.3, hL: 0.3).copier(
        x: 0.5,
        y: 0.32,
        tronc: -70,
        brasP: -60,
        brasL: -60,
        avantBrasP: -40,
        avantBrasL: -40,
      ),
      duree: 0.38,
      courbe: Courbe.explosive,
    ),
    // La réception sur la caisse, amortie.
    Cle(
      _largeur(_pose, x: 0.7)
          .copier(
            x: 0.6,
            y: 0.47,
            tronc: -56,
            brasP: 10,
            brasL: 10,
            avantBrasP: 0,
            avantBrasL: 0,
          )
          .copier(
            piedCibleP: const Cible(0.7, _surCaisse, 0.072),
            piedCibleL: const Cible(0.7, _surCaisse, -0.072),
          ),
      duree: 0.3,
      courbe: Courbe.lancee,
    ),
    Cle(
      _largeur(_pose)
          .copier(x: 0.7, y: _surCaisse - 0.398)
          .copier(
            piedCibleP: const Cible(0.7, _surCaisse, 0.072),
            piedCibleL: const Cible(0.7, _surCaisse, -0.072),
          ),
      duree: 0.6,
      tenue: 0.3,
    ),
    // On redescend en marchant, en arrière.
    Cle(
      _largeur(_pose, x: 0.5)
          .copier(x: 0.5, y: 0.47, tronc: -84)
          .copier(piedCibleP: const Cible(0.7, _surCaisse, 0.072)),
      duree: 0.6,
    ),
  ], accessoires: const Accessoires(marche: _caisseDevant)),
  'chaise_murale': _suite([
    Cle(_chaiseMurale(0), duree: 2.2),
    Cle(_chaiseMurale(1), duree: 2.2),
  ], accessoires: const Accessoires(mur: 0.2)),
  // ══ PONTS ══════════════════════════════════════════════════════════════
  'pont_fessier': _serie(
    _pont(0.47, kSol - 0.06),
    _pont(0.47, kSol - 0.205),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.8,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(tapis: true),
  ),
  'pont_une_jambe': _serie(
    _pont(0.47, kSol - 0.06)
        .copier(piedCibleL: null, cuisseL: -52, jambeL: -50, piedL: -40)
        .copier(piedCibleL: const Cible(0.66, yCheville - 0.3, -0.07)),
    _pont(0.47, kSol - 0.2).copier(piedCibleL: const Cible(0.73, 0.6, -0.07)),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.8,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(tapis: true),
  ),
  'hip_thrust': _serie(
    _hipThrust(haut: false),
    _hipThrust(haut: true),
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
  // ══ CHARNIÈRE DE HANCHE ════════════════════════════════════════════════
  'souleve_roumain': _serie(
    _brasPendus(_pieds(_pose, 0.47, z: 0.06), ecart: 6),
    _brasPendus(
      _pieds(
        _pose,
        0.47,
        z: 0.06,
      ).copier(x: 0.35, y: 0.515, tronc: -14, dos: 2, tete: -24),
      ecart: 6,
    ),
    ab: 1.8,
    ba: 1.2,
    tenueA: 0.45,
    tenueB: 0.2,
    accessoires: const Accessoires(halteres: true),
  ),
  'souleve_roumain_barre': _serie(
    _brasPendus(_pieds(_pose, 0.47, z: 0.06), ecart: 13),
    _brasPendus(
      _pieds(
        _pose,
        0.47,
        z: 0.06,
      ).copier(x: 0.35, y: 0.515, tronc: -14, dos: 2, tete: -24),
      ecart: 13,
    ),
    ab: 1.8,
    ba: 1.2,
    tenueA: 0.45,
    tenueB: 0.2,
    accessoires: const Accessoires(barre: true),
  ),
  'souleve_une_jambe': _serie(
    _brasPendus(
      _pieds(
        _pose,
        0.5,
      ).copier(x: 0.5, piedCibleL: const Cible(0.46, yCheville - 0.03)),
      ecart: 6,
    ),
    _brasPendus(
      _pieds(_pose, 0.5)
          .copier(x: 0.39, y: 0.505, tronc: -6, tete: -16, piedCibleL: null)
          .copier(piedCibleL: const Cible(0.02, 0.5)),
      ecart: 6,
    ).copier(piedL: 90),
    ab: 1.8,
    ba: 1.3,
    tenueA: 0.4,
    tenueB: 0.3,
    accessoires: const Accessoires(halteres: true),
  ),
  'souleve_terre': _serie(
    _deadlift(bas: true, yMains: kSol - 0.06, z: 0.12),
    _deadlift(bas: false, yMains: 0.575, z: 0.12),
    ab: 1.2,
    ba: 1.5,
    tenueA: 0.35,
    tenueB: 0.45,
    accessoires: const Accessoires(halteres: true),
  ),
  'souleve_terre_barre': _serie(
    _deadlift(bas: true, yMains: kSol - 0.076, z: 0.11),
    _deadlift(bas: false, yMains: 0.575, z: 0.11),
    ab: 1.2,
    ba: 1.5,
    tenueA: 0.35,
    tenueB: 0.45,
    accessoires: const Accessoires(barre: true),
  ),
  'good_morning': _serie(
    _mainsNuque(_pieds(_pose, 0.47, z: 0.06)),
    _mainsNuque(
      _pieds(
        _pose,
        0.47,
        z: 0.06,
      ).copier(x: 0.36, y: 0.505, tronc: -18, dos: 2, tete: -26),
    ),
    ab: 1.7,
    ba: 1.2,
    tenueA: 0.4,
    tenueB: 0.2,
  ),
  // ══ MOLLETS ════════════════════════════════════════════════════════════
  'mollets': _serie(
    _brasPendus(_pieds(_pose, 0.47, z: 0.06)),
    _brasPendus(
      _pieds(
        _pose,
        0.47,
        z: 0.06,
        hP: 0.052,
        hL: 0.052,
      ).copier(y: hDebout - 0.052, piedP: 46, piedL: 46),
    ),
    ab: 0.7,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.6,
    accessoires: const Accessoires(halteres: true),
  ),
  'mollets_marche': _serie(
    _pieds(_pose, 0.44, z: 0.06)
        .copier(
          x: 0.44,
          y: 0.782 - 0.034 + 0.024 - 0.398,
          piedP: -26,
          piedL: -26,
        )
        .copier(
          piedCibleP: const Cible(0.445, 0.782 - 0.034 + 0.024, 0.06),
          piedCibleL: const Cible(0.445, 0.782 - 0.034 + 0.024, -0.06),
        ),
    _pieds(_pose, 0.44, z: 0.06)
        .copier(x: 0.45, y: 0.782 - 0.034 - 0.046 - 0.398, piedP: 44, piedL: 44)
        .copier(
          piedCibleP: const Cible(0.455, 0.782 - 0.034 - 0.046, 0.06),
          piedCibleL: const Cible(0.455, 0.782 - 0.034 - 0.046, -0.06),
        ),
    ab: 0.8,
    ba: 1.5,
    tenueA: 0.4,
    tenueB: 0.6,
    accessoires: const Accessoires(
      marche: Rect.fromLTRB(0.44, 0.782, 0.8, kSol),
    ),
  ),
  // ══ ISCHIOS ET FESSIERS, AU SOL ════════════════════════════════════════
  'nordic': _suite([
    Cle(
      _nordic(-88, redresse: true),
      duree: 1.0,
      courbe: Courbe.controlee,
      tenue: 0.5,
    ),
    Cle(_nordic(-58), duree: 1.4, courbe: Courbe.controlee),
    Cle(_nordic(-24), duree: 1.3, courbe: Courbe.lancee),
    Cle(
      _nordic(-16, appui: true),
      duree: 0.3,
      courbe: Courbe.explosive,
      tenue: 0.3,
    ),
    Cle(_nordic(-40, appui: true), duree: 0.6, courbe: Courbe.explosive),
  ]),
  'donkey_kick': _serie(
    _quatrePattes(),
    _quatrePattes().copier(cuisseP: 196, jambeP: 274, piedP: 196),
    ab: 0.8,
    ba: 1.1,
    tenueA: 0.3,
    tenueB: 0.5,
    accessoires: const Accessoires(tapis: true),
  ),
  'abduction_cote': _serie(
    _coucheCote(0),
    _coucheCote(46),
    ab: 0.8,
    ba: 1.2,
    tenueA: 0.3,
    tenueB: 0.5,
    camera: Camera3.face,
    accessoires: const Accessoires(tapis: true),
  ),
  'marche_laterale': _suite(
    [
      Cle(_bandeLaterale(0, 0.1, -0.1), duree: 0.45, tenue: 0.1),
      Cle(_bandeLaterale(0.03, 0.2, -0.1, levP: 0.04), duree: 0.35),
      Cle(_bandeLaterale(0.06, 0.2, -0.1), duree: 0.3),
      Cle(_bandeLaterale(0.09, 0.2, 0.0, levL: 0.04), duree: 0.35),
      Cle(_bandeLaterale(0.1, 0.2, 0.0), duree: 0.3, tenue: 0.1),
      Cle(_bandeLaterale(0.07, 0.2, -0.1, levL: 0.04), duree: 0.35),
      Cle(_bandeLaterale(0.04, 0.2, -0.1), duree: 0.3),
      Cle(_bandeLaterale(0.02, 0.1, -0.1, levP: 0.04), duree: 0.35),
    ],
    camera: Camera3.face,
    accessoires: const Accessoires(bandeGenoux: true),
  ),
};

// ── Les positions composées ────────────────────────────────────────────────

/// Le sumo : pieds très écartés, pointes ouvertes, genoux vers l'extérieur.
Pose3 _sumo(Pose3 p) => _pieds(p, 0.5, z: 0.15).copier(
  x: 0.5,
  y: 0.5,
  tronc: -86,
  ecartCuisseP: 42,
  ecartCuisseL: 42,
  genouP: const V3(0.5, 0, 0.86),
  genouL: const V3(0.5, 0, -0.86),
);

/// Une charge tenue à deux mains, bras tendus entre les jambes.
Pose3 _mainsCharge(Pose3 p) => p.copier(
  brasP: 90,
  brasL: 90,
  ecartBrasP: -4,
  ecartBrasL: -4,
  avantBrasP: 90,
  avantBrasL: 90,
  ecartAvantBrasP: -12,
  ecartAvantBrasL: -12,
);

/// Le squat bulgare : le pied arrière (loin) posé sur la caisse, lacets en
/// bas ; le pied avant (proche) planté.
Pose3 _bulgare(double hx, double hy) => _pieds(_pose, 0.53).copier(
  x: hx,
  y: hy,
  tronc: -84,
  piedL: 160,
  piedCibleL: const Cible(0.2, 0.69 - 0.03),
  genouL: const V3(0.2, 1, 0),
);

/// Le bas d'un squat sur une jambe : la jambe libre tendue devant.
Pose3 _pistol() => _pieds(_pose, 0.5)
    .copier(x: 0.37, y: 0.78, tronc: -40, dos: 6, piedCibleL: null)
    .copier(piedCibleL: const Cible(0.76, 0.74), piedL: -50);

/// Une fente arrière : la jambe proche devant, la loin qui recule, en
/// quatre temps (le pied se lève, se pose, on descend, on remonte).
AnimCorps _fenteArriere({
  Pose3 Function(Pose3)? bras,
  Accessoires accessoires = const Accessoires(),
}) {
  Pose3 b(Pose3 p) => bras == null ? p : bras(p);
  final debout = b(_pieds(_pose, 0.56).copier(x: 0.56));
  final pas = b(
    _pieds(
      _pose,
      0.56,
      xL: 0.4,
      hL: 0.07,
    ).copier(x: 0.53, y: 0.5, tronc: -86, piedL: 20),
  );
  final pose = b(_fente(avantP: true, bas: false));
  final bas = b(_fente(avantP: true, bas: true));
  return _suite([
    Cle(debout, duree: 0.35, tenue: 0.4),
    Cle(pas, duree: 0.35),
    Cle(pose, duree: 0.3),
    Cle(bas, duree: 1.1, tenue: 0.25),
    Cle(pose, duree: 0.75, courbe: Courbe.explosive),
    Cle(pas, duree: 0.3),
  ], accessoires: accessoires);
}

/// La fente : un pied devant (tibia vertical), l'autre derrière sur la
/// pointe ; en bas, le genou arrière frôle le sol.
Pose3 _fente({required bool avantP, required bool bas}) {
  const xAvant = 0.56, xArriere = 0.2;
  final p = _pose.copier(
    x: bas ? 0.385 : 0.4,
    y: bas ? 0.675 : 0.53,
    tronc: bas ? -84 : -87,
    piedCibleP: Cible(
      avantP ? xAvant : xArriere,
      avantP ? yCheville : kSol - 0.075,
    ),
    piedCibleL: Cible(
      avantP ? xArriere : xAvant,
      avantP ? kSol - 0.075 : yCheville,
    ),
    piedP: avantP ? 0 : 62,
    piedL: avantP ? 62 : 0,
    genouP: avantP ? null : const V3(0.35, 1, 0),
    genouL: avantP ? const V3(0.35, 1, 0) : null,
    brasP: avantP ? 112 : 68,
    avantBrasP: avantP ? 92 : 20,
    brasL: avantP ? 68 : 112,
    avantBrasL: avantP ? 20 : 92,
  );
  return p;
}

/// En l'air, entre deux fentes : le corps monte, les jambes presque
/// tendues se croisent en ciseaux ([avantP] : la jambe proche, encore
/// devant, repart en arrière).
Pose3 _envolFente({required bool avantP}) {
  final xP = avantP ? 0.45 : 0.33, xL = avantP ? 0.33 : 0.45;
  return _pose.copier(
    x: 0.39,
    y: hDebout - 0.075,
    tronc: -87,
    piedCibleP: Cible(xP, yCheville - 0.1),
    piedCibleL: Cible(xL, yCheville - 0.1),
    genouP: const V3(1, 0, 0.1),
    genouL: const V3(1, 0, -0.1),
    piedP: 40,
    piedL: 40,
    brasP: 92,
    brasL: 92,
    avantBrasP: 50,
    avantBrasL: 50,
  );
}

/// La fente latérale : [dz] décale la hanche vers le côté proche, la
/// jambe proche se plie.
Pose3 _lateral(double dz, double hy) =>
    _pieds(_pose, 0.5, z: 0.26, zL: -0.07).copier(
      x: 0.5,
      y: hy,
      dz: dz,
      tronc: -80,
      ecartCuisseP: 30,
      ecartCuisseL: 12,
      genouP: const V3(0.8, 0, 0.6),
    );

/// La chaise murale : le dos contre le mur, cuisses parallèles, tenue ;
/// [souffle] fait respirer la pose.
Pose3 _chaiseMurale(double souffle) => _largeur(_pose, x: 0.47).copier(
  x: 0.26,
  y: 0.69 + souffle * 0.003,
  tronc: -91,
  brasP: 80,
  avantBrasP: 60,
  brasL: 80,
  avantBrasL: 60,
  ecartBrasP: 4 + souffle * 2,
  ecartBrasL: 4 + souffle * 2,
);

/// Le hip thrust : le haut du dos contre le banc, pieds plantés.
Pose3 _hipThrust({required bool haut}) {
  const cou = (0.27, 0.63);
  final hx = haut ? 0.505 : 0.43, hy = haut ? 0.63 : 0.8;
  var ang = _angle(hx, hy, cou.$1, cou.$2);
  if (ang > 0) ang -= 360;
  return _pieds(_pose, 0.68, z: 0.08).copier(
    x: hx,
    y: hy,
    tronc: ang,
    tete: haut ? 200 : 250,
    brasP: _angle(0.3, 0.64, hx, hy) + 4,
    brasL: _angle(0.3, 0.64, hx, hy) + 4,
    avantBrasP: _angle(0.3, 0.64, hx, hy) - 10,
    avantBrasL: _angle(0.3, 0.64, hx, hy) - 10,
    ecartBrasP: 18,
    ecartBrasL: 18,
    ecartAvantBrasP: 6,
    ecartAvantBrasL: 6,
    genouP: const V3(0.4, -1, 0.1),
    genouL: const V3(0.4, -1, -0.1),
  );
}

/// Le soulevé de terre : les mains tiennent la charge en ([x] = milieu du
/// pied, [yMains]) ; en bas, les hanches reculent, le dos reste plat.
Pose3 _deadlift({required bool bas, required double yMains, double z = 0.11}) =>
    _pieds(_pose, 0.47, z: 0.07).copier(
      x: bas ? 0.36 : 0.47,
      y: bas ? 0.63 : hDebout,
      tronc: bas ? -38 : -88,
      dos: bas ? 2 : 0,
      tete: bas ? -52 : null,
      mainP: Cible(0.49, yMains, z),
      mainL: Cible(0.49, yMains, -z),
      coudeP: const V3(-0.2, 1, 0.3),
      coudeL: const V3(-0.2, 1, -0.3),
    );

/// Le nordic : à genoux, talons calés ; le corps (genou → cou) incliné de
/// [angle] ; [appui] : les mains rattrapent le sol.
Pose3 _nordic(double angle, {bool redresse = false, bool appui = false}) {
  const genou = (0.36, kSol - 0.03);
  final a = rad(angle);
  final hx = genou.$1 + math.cos(a) * lCuisse;
  final hy = genou.$2 + math.sin(a) * lCuisse;
  return _pose
      .copier(
        x: hx,
        y: hy,
        tronc: angle,
        tete: angle - 6,
        cuisseP: angle + 180,
        cuisseL: angle + 180,
        jambeP: 180,
        jambeL: 180,
        piedP: 96,
        piedL: 96,
        sansCibles: true,
        brasP: appui ? 40 : 70,
        brasL: appui ? 40 : 70,
        avantBrasP: appui ? 70 : -30,
        avantBrasL: appui ? 70 : -30,
        ecartBrasP: 14,
        ecartBrasL: 14,
      )
      .copier(
        mainP: appui ? Cible(hx + 0.33, yPaume, 0.1) : null,
        mainL: appui ? Cible(hx + 0.33, yPaume, -0.1) : null,
      );
}

/// À quatre pattes : genoux sous les hanches, mains sous les épaules.
Pose3 _quatrePattes() => _pose
    .copier(
      x: 0.36,
      y: kSol - 0.03 - lCuisse,
      tronc: -9,
      tete: -14,
      cuisseP: 90,
      cuisseL: 90,
      jambeP: 180,
      jambeL: 180,
      piedP: 172,
      piedL: 172,
      sansCibles: true,
    )
    .copier(
      mainP: const Cible(0.59, yPaume, 0.1),
      mainL: const Cible(0.59, yPaume, -0.1),
      coudeP: const V3(-0.4, 0.3, 1),
      coudeL: const V3(-0.4, 0.3, -1),
    );

/// Couché sur le côté (le côté proche au sol), face à la caméra ; la jambe
/// du dessus levée de [ecart].
Pose3 _coucheCote(double ecart) => _pose.copier(
  auSol: true,
  x: 0.5,
  roulis: -90,
  sansCibles: true,
  cuisseL: 90,
  ecartCuisseL: 2 + ecart,
  jambeL: 90,
  ecartJambeL: 2 + ecart,
  piedL: 8,
  cuisseP: 90,
  ecartCuisseP: 0,
  jambeP: 90,
  brasP: -90,
  ecartBrasP: 4,
  avantBrasP: 150,
  ecartAvantBrasP: -40,
  brasL: 88,
  ecartBrasL: 14,
  avantBrasL: 92,
  ecartAvantBrasL: 10,
);

/// La marche latérale à l'élastique : demi-squat, le bassin décalé de [dz],
/// les pieds en [zP] et [zL].
Pose3 _bandeLaterale(
  double dz,
  double zP,
  double zL, {
  double levP = 0,
  double levL = 0,
}) => _pose.copier(
  x: 0.5,
  y: 0.58,
  dz: dz,
  tronc: -76,
  piedCibleP: Cible(0.5, yCheville - levP, zP),
  piedCibleL: Cible(0.5, yCheville - levL, zL),
  genouP: const V3(0.8, 0, 0.5),
  genouL: const V3(0.8, 0, -0.5),
  ecartCuisseP: 14,
  ecartCuisseL: 14,
  brasP: 60,
  brasL: 60,
  avantBrasP: -20,
  avantBrasL: -20,
  ecartBrasP: -10,
  ecartBrasL: -10,
  ecartAvantBrasP: -30,
  ecartAvantBrasL: -30,
);

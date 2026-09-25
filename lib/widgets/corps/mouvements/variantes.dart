// lib/widgets/corps/mouvements/variantes.dart
//
// Les VARIANTES qui méritent leur propre mouvement (l'exercice ne se
// reconnaîtrait pas dans celui de base) : chaise murale sur une jambe,
// squat cosaque, ponts sur chaise et à l'élastique, squat à l'élastique,
// kickback à l'élastique, montée avec genou levé, pompe en T.

part of '../animations_corps.dart';

/// Les mains aux épaules, en rack (squat à l'élastique) : elles suivent le
/// tronc.
Pose3 _mainsAuxEpaules(Pose3 p) {
  final t = rad(p.tronc);
  final av = rad(p.tronc + 90);
  final x = p.x + math.cos(t) * (_lEpaule + 0.01) + math.cos(av) * 0.07;
  final y = p.y + math.sin(t) * (_lEpaule + 0.01) + math.sin(av) * 0.07;
  return p.copier(
    mainP: Cible(x, y, 0.15),
    mainL: Cible(x, y, -0.15),
    coudeP: const V3(0.5, 1, 0.3),
    coudeL: const V3(0.5, 1, -0.3),
  );
}

/// Le squat cosaque : pieds très écartés, le bassin glisse du côté [c]
/// (1 : vers nous, −1 : loin, 0 : au centre) et descend sur cette jambe ;
/// l'autre reste tendue, pointe vers le ciel.
Pose3 _cosaque(double c) => _mainsJointes(
  _pieds(_pose, 0.5, z: 0.26).copier(
    x: 0.5,
    y: 0.5 + 0.2 * c.abs(),
    dz: 0.14 * c,
    tronc: -90 + 26 * c.abs(),
    genouP: const V3(0.8, 0, 0.6),
    genouL: const V3(0.8, 0, -0.6),
    ecartCuisseP: 30,
    ecartCuisseL: 30,
    piedP: c < 0 ? -44 : 0,
    piedL: c > 0 ? -44 : 0,
  ),
);

/// La montée avec genou levé : celle de base, mais en haut de la caisse le
/// genou arrière monte jusqu'à la hanche.
AnimCorps _stepUpGenou() {
  final base = _jambes3['step_up']!;
  final cles = [...base.cles];
  final haut = cles[4].pose;
  cles[4] = Cle(
    haut.copier(
      piedCibleL: const Cible(0.73, 0.5, -0.06),
      genouL: const V3(1, 0, -0.1),
      piedL: 30,
      brasP: 50,
      avantBrasP: -10,
      brasL: 120,
      avantBrasL: 100,
    ),
    duree: 0.5,
    courbe: Courbe.explosive,
    tenue: 0.45,
  );
  return AnimCorps(cles, camera: base.camera, accessoires: base.accessoires);
}

final Map<String, AnimCorps> _variantes3 = {
  'chaise_murale_une_jambe': _suite([
    for (final s in [0.0, 1.0])
      Cle(
        _chaiseMurale(s)
            .copier(sansCibles: true)
            .copier(
              piedCibleL: const Cible(0.47, yCheville, -0.072),
              genouL: const V3(1, 0, -0.32),
              cuisseP: -2,
              jambeP: -2,
              ecartCuisseP: 6,
              ecartJambeP: 6,
              piedP: -60,
            ),
        duree: 2.2,
      ),
  ], accessoires: const Accessoires(mur: 0.2)),
  'squat_cosaque': _suite([
    Cle(_cosaque(0), duree: 0.9, tenue: 0.2),
    Cle(_cosaque(1), duree: 1.4, tenue: 0.4),
    Cle(_cosaque(0), duree: 1.1, tenue: 0.2),
    Cle(_cosaque(-1), duree: 1.4, tenue: 0.4),
  ], camera: Camera3.face),
  'pont_fessier_chaise': _serie(
    _pont(0.47, kSol - 0.06).copier(
      piedCibleP: const Cible(0.8, 0.7 - 0.028, 0.07),
      piedCibleL: const Cible(0.8, 0.7 - 0.028, -0.07),
      piedP: -62,
      piedL: -62,
    ),
    _pont(0.5, 0.69).copier(
      piedCibleP: const Cible(0.8, 0.7 - 0.028, 0.07),
      piedCibleL: const Cible(0.8, 0.7 - 0.028, -0.07),
      piedP: -62,
      piedL: -62,
    ),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.8,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(
      tapis: true,
      marche: Rect.fromLTRB(0.74, 0.7, 0.98, kSol),
    ),
  ),
  'pont_fessier_elastique': _serie(
    _pont(
      0.47,
      kSol - 0.06,
    ).copier(genouP: const V3(0.3, -1, 0.35), genouL: const V3(0.3, -1, -0.35)),
    _pont(
      0.47,
      kSol - 0.205,
    ).copier(genouP: const V3(0.3, -1, 0.4), genouL: const V3(0.3, -1, -0.4)),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.8,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(tapis: true, bandeGenoux: true),
  ),
  'squat_elastique': _serie(
    _mainsAuxEpaules(_largeur(_pose)),
    _mainsAuxEpaules(_basSquat(_largeur(_pose), tronc: -54)),
    ab: 1.6,
    ba: 1.0,
    tenueA: 0.5,
    tenueB: 0.2,
    accessoires: const Accessoires(elastique: Offset(0.47, kSol - 0.004)),
  ),
  'kickback_fessier_elastique': _serie(
    _quatrePattes(),
    _quatrePattes().copier(cuisseP: 190, jambeP: 186, piedP: 150),
    ab: 0.7,
    ba: 1.1,
    tenueA: 0.3,
    tenueB: 0.5,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(tapis: true, bandeGenoux: true),
  ),
  'step_up_genou': _stepUpGenou(),
  'pompe_t': _suite([
    Cle(_pompe(yPaume - 0.285, zPieds: 0.08), duree: 0.8, tenue: 0.2),
    Cle(_pompe(kSol - 0.08, zPieds: 0.08), duree: 1.1),
    Cle(
      _pompe(yPaume - 0.285, zPieds: 0.08),
      duree: 0.7,
      courbe: Courbe.explosive,
    ),
    // On pivote en planche latérale, le bras vers le plafond.
    Cle(
      _lateralePlanche(pente: 26, brasHaut: true, main: true),
      duree: 0.9,
      tenue: 0.5,
    ),
    Cle(_pompe(yPaume - 0.285, zPieds: 0.08), duree: 0.8),
  ]),
};

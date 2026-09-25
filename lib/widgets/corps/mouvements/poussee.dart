// lib/widgets/corps/mouvements/poussee.dart
//
// La POUSSÉE, réécrite pour la fidélité : pompes (les mains PLANTÉES, le
// corps gainé qui pivote autour des pointes de pieds, les coudes à 45°),
// développés couchés, inclinés et au sol (les mains qui montent à la
// verticale des épaules), écartés en arc de cercle, épaules et triceps.

part of '../animations_corps.dart';

// ── Repères ────────────────────────────────────────────────────────────────

/// De la hanche à l'articulation de l'épaule, le long du tronc.
const double _lEpaule = lTronc - 0.028;

/// La cheville d'un pied posé sur la pointe (planche, pompe).
const double _pointe = kSol - 0.09;

/// Le banc plat (dessus à 0,64) et le banc à dossier incliné (30°).
const Rect _bancPlat = Rect.fromLTRB(0.2, 0.64, 0.8, 0.675);
const Rect _bancAssise = Rect.fromLTRB(0.5, 0.64, 0.78, 0.675);
const (Offset, Offset) _dossierIncline = (Offset(0.54, 0.64), Offset(0.3, 0.5));

/// Un banc à hauteur de chaise, pour les dips.
const Rect _bancDips = Rect.fromLTRB(0.06, 0.7, 0.33, 0.735);

// ── Positions ──────────────────────────────────────────────────────────────

/// Le corps GAINÉ, droit de [appui] (la cheville ; le genou si [genoux])
/// jusqu'à l'épaule [epaule] : la hanche sur la ligne, la tête dans l'axe,
/// les pieds sur la pointe.
Pose3 _gaine(
  Offset appui,
  Offset epaule, {
  bool genoux = false,
  double? pied,
  double zPieds = 0.05,
  V3 genou = const V3(0, 1, 0.1),
}) {
  final l = genoux ? lCuisse : lCuisse + lJambe;
  final d = epaule - appui;
  final hanche = appui + d * (l / (l + _lEpaule));
  final tronc = _angle(appui.dx, appui.dy, epaule.dx, epaule.dy);
  final base = _pose.copier(
    x: hanche.dx,
    y: hanche.dy,
    tronc: tronc,
    tete: tronc - 6,
    sansCibles: true,
  );
  if (genoux) {
    // Les genoux posés, les tibias qui se relèvent un peu derrière.
    return base.copier(
      cuisseP: tronc + 180,
      cuisseL: tronc + 180,
      ecartCuisseP: 4,
      ecartCuisseL: 4,
      jambeP: 198,
      jambeL: 204,
      piedP: 196,
      piedL: 202,
    );
  }
  return base.copier(
    piedCibleP: Cible(appui.dx, appui.dy, zPieds),
    piedCibleL: Cible(appui.dx, appui.dy, -zPieds),
    genouP: genou,
    genouL: V3(genou.x, genou.y, -genou.z),
    piedP: pied ?? tronc + 90,
    piedL: pied ?? tronc + 90,
  );
}

/// Une pompe : les épaules à la hauteur [yEpaule], le corps gainé qui
/// pivote autour de [appui], les mains plantées en [main] (écartées de
/// [zMain]), les coudes poussés vers [coude] (en arrière, vers le haut et
/// vers l'extérieur : 45°).
Pose3 _pompe(
  double yEpaule, {
  Offset appui = const Offset(0.08, _pointe),
  bool genoux = false,
  Offset main = const Offset(0.67, yPaume),
  double zMain = 0.12,
  double zPieds = 0.05,
  V3 coude = const V3(-0.6, -1, 0.7),
}) {
  final l = (genoux ? lCuisse : lCuisse + lJambe) + _lEpaule;
  final dy = yEpaule - appui.dy;
  final dx = math.sqrt(math.max(0, l * l - dy * dy));
  return _gaine(
    appui,
    Offset(appui.dx + dx, yEpaule),
    genoux: genoux,
    zPieds: zPieds,
  ).copier(
    mainP: Cible(main.dx, main.dy, zMain),
    mainL: Cible(main.dx, main.dy, -zMain),
    coudeP: coude,
    coudeL: V3(coude.x, coude.y, -coude.z),
  );
}

/// Couché sur le dos sur le banc plat, la tête à gauche, les pieds plantés
/// au sol de part et d'autre.
final Pose3 _dosBanc = _pose.copier(
  x: 0.62,
  y: 0.585,
  tronc: 180,
  tete: 180,
  piedCibleP: const Cible(0.84, yCheville, 0.14),
  piedCibleL: const Cible(0.84, yCheville, -0.14),
  genouP: const V3(1, -0.8, 0.3),
  genouL: const V3(1, -0.8, -0.3),
);

/// Couché sur le dos au sol, genoux pliés, pieds à plat.
final Pose3 _dosAuSol = _pose.copier(
  x: 0.58,
  y: kSol - 0.052,
  tronc: 180,
  tete: 180,
  piedCibleP: const Cible(0.82, yCheville, 0.09),
  piedCibleL: const Cible(0.82, yCheville, -0.09),
  genouP: const V3(0.3, -1, 0.15),
  genouL: const V3(0.3, -1, -0.15),
  brasP: 4,
  avantBrasP: 2,
  brasL: 4,
  avantBrasL: 2,
  ecartBrasP: 14,
  ecartBrasL: 14,
);

/// Assis sur le banc incliné, le dos contre le dossier.
final Pose3 _dosIncline = _pose.copier(
  x: 0.575,
  y: 0.6,
  tronc: 210,
  tete: 206,
  piedCibleP: const Cible(0.84, yCheville, 0.14),
  piedCibleL: const Cible(0.84, yCheville, -0.14),
  genouP: const V3(1, -0.6, 0.3),
  genouL: const V3(1, -0.6, -0.3),
);

/// Debout, en appui décalé (le pied proche devant) : pour pousser ou tirer
/// un élastique accroché.
Pose3 _decale(Pose3 p) =>
    _pieds(p, 0.55, xL: 0.37, z: 0.06).copier(y: hDebout + 0.012);

/// Les deux mains tenues en [x], [y], écartées de [z] ; les coudes vers
/// [coude] (proche) et son miroir.
Pose3 _mainsEn(Pose3 p, double x, double y, double z, V3 coude) => p.copier(
  mainP: Cible(x, y, z),
  mainL: Cible(x, y, -z),
  coudeP: coude,
  coudeL: V3(coude.x, coude.y, -coude.z),
);

/// Les deux bras en commande directe : bras ([theta], [ecart]), avant-bras
/// ([theta2], [ecart2]).
Pose3 _brasDirects(
  Pose3 p,
  double theta,
  double ecart, [
  double? theta2,
  double? ecart2,
]) => p.copier(
  sansCibles: false,
  brasP: theta,
  brasL: theta,
  ecartBrasP: ecart,
  ecartBrasL: ecart,
  avantBrasP: theta2 ?? theta,
  avantBrasL: theta2 ?? theta,
  ecartAvantBrasP: ecart2 ?? ecart,
  ecartAvantBrasL: ecart2 ?? ecart,
);

/// Penché en avant, dos plat, genoux souples (oiseau, kickback).
final Pose3 _penchePlat = _pieds(
  _pose,
  0.47,
  z: 0.07,
).copier(x: 0.37, y: 0.53, tronc: -22, dos: 2, tete: -36);

/// Assis au bord d'un banc bas, le dos droit, pieds à plat.
final Pose3 _assisBas = _pose.copier(
  x: 0.4,
  y: 0.64 - 0.056,
  tronc: -90,
  piedCibleP: const Cible(0.62, yCheville, 0.09),
  piedCibleL: const Cible(0.62, yCheville, -0.09),
  genouP: const V3(1, -0.2, 0.2),
  genouL: const V3(1, -0.2, -0.2),
);
const Rect _bancBasAssise = Rect.fromLTRB(0.18, 0.64, 0.5, 0.675);

/// À plat ventre, la tête à droite, jambes tendues.
final Pose3 _aPlatVentre = _pose.copier(
  x: 0.5,
  y: kSol - 0.056,
  tronc: 0,
  tete: -8,
  sansCibles: true,
  cuisseP: 180,
  cuisseL: 180,
  ecartCuisseP: 5,
  ecartCuisseL: 5,
  jambeP: 180,
  jambeL: 180,
  piedP: 178,
  piedL: 178,
);

// ── Les mouvements ─────────────────────────────────────────────────────────

final Map<String, AnimCorps> _poussee3 = {
  // ══ POMPES ═════════════════════════════════════════════════════════════
  'pompe': _serie(
    _pompe(yPaume - 0.285),
    _pompe(kSol - 0.08),
    ab: 1.3,
    ba: 0.85,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
  ),
  'pompe_large': _serie(
    _pompe(yPaume - 0.27, zMain: 0.21, coude: const V3(-0.2, -1, 1)),
    _pompe(kSol - 0.08, zMain: 0.21, coude: const V3(-0.2, -1, 1)),
    ab: 1.3,
    ba: 0.85,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
  ),
  'pompe_genoux': _serie(
    _pompe(
      yPaume - 0.285,
      appui: const Offset(0.33, kSol - 0.03),
      genoux: true,
      main: const Offset(0.68, yPaume),
    ),
    _pompe(
      kSol - 0.08,
      appui: const Offset(0.33, kSol - 0.03),
      genoux: true,
      main: const Offset(0.68, yPaume),
    ),
    ab: 1.2,
    ba: 0.85,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
  ),
  'pompe_inclinee': _serie(
    _pompe(
      0.72 - 0.013 - 0.285,
      appui: const Offset(0.12, _pointe),
      main: const Offset(0.64, 0.72 - 0.013),
    ),
    _pompe(
      0.72 - 0.08,
      appui: const Offset(0.12, _pointe),
      main: const Offset(0.64, 0.72 - 0.013),
    ),
    ab: 1.2,
    ba: 0.85,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(
      marche: Rect.fromLTRB(0.56, 0.72, 0.9, kSol),
    ),
  ),
  'pompe_declinee': _serie(
    _pompe(
      yPaume - 0.285,
      appui: const Offset(0.1, 0.72 - 0.085),
      main: const Offset(0.7, yPaume),
    ),
    _pompe(
      kSol - 0.085,
      appui: const Offset(0.1, 0.72 - 0.085),
      main: const Offset(0.7, yPaume),
    ),
    ab: 1.3,
    ba: 0.85,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(
      marche: Rect.fromLTRB(0.02, 0.72, 0.2, kSol),
    ),
  ),
  'pompe_diamant': _serie(
    _pompe(
      yPaume - 0.28,
      main: const Offset(0.62, yPaume),
      zMain: 0.025,
      coude: const V3(-1, -0.5, 0.25),
    ),
    _pompe(
      kSol - 0.095,
      main: const Offset(0.62, yPaume),
      zMain: 0.025,
      coude: const V3(-1, -0.5, 0.25),
    ),
    ab: 1.3,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
  ),
  'pompe_archer': _suite([
    Cle(_pompe(yPaume - 0.27, zMain: 0.3), duree: 0.8, tenue: 0.25),
    // Le corps descend vers la main proche, l'autre bras reste tendu.
    Cle(
      _pompe(
        kSol - 0.09,
        zMain: 0.3,
        coude: const V3(-0.5, -1, 0.3),
      ).copier(dz: 0.12, coudeL: const V3(0, -0.2, -1)),
      duree: 1.3,
      tenue: 0.15,
    ),
    Cle(_pompe(yPaume - 0.27, zMain: 0.3), duree: 0.8, tenue: 0.25),
    Cle(
      _pompe(
        kSol - 0.09,
        zMain: 0.3,
        coude: const V3(-0.5, -1, 0.3),
      ).copier(dz: -0.12, coudeP: const V3(0, -0.2, 1)),
      duree: 1.3,
      tenue: 0.15,
    ),
  ]),
  'pompe_claquee': _suite([
    Cle(_pompe(yPaume - 0.285), duree: 0.5, tenue: 0.2),
    Cle(_pompe(kSol - 0.08), duree: 1.0, courbe: Courbe.controlee),
    // L'envol : les mains quittent le sol et claquent sous la poitrine.
    Cle(
      _pompe(yPaume - 0.36).copier(
        mainP: const Cible(0.64, 0.74, 0.012),
        mainL: const Cible(0.64, 0.74, -0.012),
        coudeP: const V3(-0.4, 0.2, 1),
        coudeL: const V3(-0.4, 0.2, -1),
      ),
      duree: 0.26,
      courbe: Courbe.explosive,
    ),
    Cle(_pompe(yPaume - 0.29), duree: 0.24, courbe: Courbe.lancee),
  ]),
  'pompe_isometrique': _suite([
    Cle(_pompe(yPaume - 0.285), duree: 0.9, tenue: 0.2),
    Cle(_pompe(kSol - 0.14), duree: 1.0, tenue: 1.6),
    Cle(_pompe(kSol - 0.145), duree: 0.8, tenue: 1.2),
  ]),
  'pompe_mur': _serie(
    _auMur(const Offset(0.51, 0.278)).copier(tete: -84),
    _auMur(const Offset(0.7, 0.353)).copier(tete: -72),
    ab: 1.2,
    ba: 0.8,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(mur: 0.8),
  ),
  // ══ PIQUÉES ════════════════════════════════════════════════════════════
  'pike_pushup': _serie(
    _pique(0.42, 0.45, 62),
    _pique(0.47, 0.51, 72),
    ab: 1.3,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
  ),
  'pike_sureleve': _serie(
    _pique(0.55, 0.4, 85, pieds: const Offset(0.18, 0.66 - 0.085)),
    _pique(0.56, 0.5, 80, pieds: const Offset(0.18, 0.66 - 0.085)),
    ab: 1.3,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(
      marche: Rect.fromLTRB(0.0, 0.66, 0.24, kSol),
    ),
  ),
  'pompe_hindoue': _suite([
    Cle(
      _pique(0.33, 0.49, 55, pieds: const Offset(0.12, kSol - 0.085)),
      duree: 0.9,
      tenue: 0.3,
    ),
    // La poitrine plonge et frôle le sol en avançant vers les mains…
    Cle(
      _pique(
        0.47,
        0.68,
        30,
        pieds: const Offset(0.12, kSol - 0.085),
      ).copier(tete: -8),
      duree: 0.8,
    ),
    // … et remonte en chien tête en haut : bras tendus, hanches basses,
    // le dessus des pieds au sol.
    Cle(
      _pique(
        0.511,
        0.78,
        -47,
        pieds: const Offset(0.12, kSol - 0.035),
      ).copier(tete: -64, dos: -8, piedP: 180, piedL: 180),
      duree: 0.6,
      tenue: 0.4,
    ),
    Cle(
      _pique(
        0.47,
        0.68,
        30,
        pieds: const Offset(0.12, kSol - 0.085),
      ).copier(tete: -8),
      duree: 0.7,
    ),
  ]),
  // ══ DÉVELOPPÉS ═════════════════════════════════════════════════════════
  'developpe_couche': _serie(
    _mainsEn(_dosBanc, 0.405, 0.3, 0.1, const V3(0.2, 1, 1)),
    _mainsEn(_dosBanc, 0.43, 0.548, 0.19, const V3(0.2, 1, 1)),
    ab: 1.5,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(halteres: true, banc: _bancPlat),
  ),
  'developpe_couche_barre': _serie(
    _mainsEn(_dosBanc, 0.405, 0.3, 0.2, const V3(0.3, 1, 1)),
    _mainsEn(_dosBanc, 0.445, 0.528, 0.2, const V3(0.3, 1, 1)),
    ab: 1.5,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(barre: true, banc: _bancPlat),
  ),
  'developpe_serre_barre': _serie(
    _mainsEn(_dosBanc, 0.405, 0.3, 0.1, const V3(0.8, 1, 0.3)),
    _mainsEn(_dosBanc, 0.45, 0.53, 0.1, const V3(0.8, 1, 0.3)),
    ab: 1.5,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(barre: true, banc: _bancPlat),
  ),
  'developpe_sol': _serie(
    _mainsEn(_dosAuSol, 0.365, kSol - 0.335, 0.1, const V3(0.2, 1, 1)),
    _mainsEn(_dosAuSol, 0.38, kSol - 0.19, 0.2, const V3(0.2, 1, 1)),
    ab: 1.4,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.25,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(halteres: true, tapis: true),
  ),
  'developpe_serre_sol': _serie(
    _mainsEn(_dosAuSol, 0.365, kSol - 0.335, 0.07, const V3(0.8, 1, 0.3)),
    _mainsEn(_dosAuSol, 0.43, kSol - 0.19, 0.08, const V3(0.8, 1, 0.3)),
    ab: 1.4,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.25,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(halteres: true, tapis: true),
  ),
  'developpe_incline': _serie(
    _mainsEn(_dosIncline, 0.41, 0.215, 0.1, const V3(0.3, 1, 1)),
    _mainsEn(_dosIncline, 0.43, 0.44, 0.19, const V3(0.3, 1, 1)),
    ab: 1.5,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(
      halteres: true,
      banc: _bancAssise,
      dossier: _dossierIncline,
    ),
  ),
  'developpe_incline_barre': _serie(
    _mainsEn(_dosIncline, 0.41, 0.215, 0.2, const V3(0.3, 1, 1)),
    _mainsEn(_dosIncline, 0.44, 0.43, 0.2, const V3(0.3, 1, 1)),
    ab: 1.5,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(
      barre: true,
      banc: _bancAssise,
      dossier: _dossierIncline,
    ),
  ),
  'developpe_elastique': _serie(
    _mainsEn(_decale(_pose), 0.54, 0.31, 0.15, const V3(-1, 0.3, 0.8)),
    _mainsEn(_decale(_pose), 0.75, 0.3, 0.06, const V3(-0.2, 1, 0.5)),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.2,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(elastique: Offset(0.08, 0.3)),
  ),
  // ══ ÉCARTÉS ════════════════════════════════════════════════════════════
  // En commande directe : l'arc de cercle du bras est exact.
  'ecarte_couche': _serie(
    _brasDirects(_dosBanc, -88, 7, -88, -6),
    _brasDirects(_dosBanc, -82, 80, -86, 62),
    ab: 1.6,
    ba: 1.0,
    tenueA: 0.3,
    tenueB: 0.15,
    accessoires: const Accessoires(halteres: true, banc: _bancPlat),
  ),
  'ecarte_sol': _serie(
    _brasDirects(_dosAuSol, -88, 7, -88, -6),
    _brasDirects(_dosAuSol, -84, 76, -88, 60),
    ab: 1.4,
    ba: 1.0,
    tenueA: 0.3,
    tenueB: 0.25,
    accessoires: const Accessoires(halteres: true, tapis: true),
  ),
  'ecarte_elastique': _serie(
    _brasDirects(_decale(_pose), 4, 80, -2, 64),
    _brasDirects(_decale(_pose), 4, -4, 2, -16),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.2,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(elastique: Offset(0.08, 0.3)),
  ),
  'ecartement_elastique': _serie(
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), 2, 12, 2, 8),
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), 2, 86, 2, 84),
    ab: 0.9,
    ba: 1.2,
    tenueA: 0.2,
    tenueB: 0.4,
    courbeAB: Courbe.explosive,
    camera: Camera3.face,
    accessoires: const Accessoires(bandeMains: true),
  ),
  'pullover': _serie(
    _brasDirects(_dosBanc, -92, -12, -96, -12),
    _brasDirects(_dosBanc, -186, -12, -198, -12),
    ab: 1.6,
    ba: 1.1,
    tenueA: 0.3,
    tenueB: 0.2,
    accessoires: const Accessoires(haltereUne: true, banc: _bancPlat),
  ),
  // ══ DIPS ═══════════════════════════════════════════════════════════════
  'dips_banc': _serie(
    _dips(haut: true, tendues: false),
    _dips(haut: false, tendues: false),
    ab: 1.3,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(banc: _bancDips),
  ),
  'dips_tendues': _serie(
    _dips(haut: true, tendues: true),
    _dips(haut: false, tendues: true),
    ab: 1.3,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.12,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(banc: _bancDips),
  ),
  // ══ ÉPAULES ════════════════════════════════════════════════════════════
  'developpe_epaules': _serie(
    _mainsEn(_largeur(_pose, z: 0.07), 0.49, 0.25, 0.19, const V3(0.1, 1, 1)),
    _mainsEn(_largeur(_pose, z: 0.07), 0.475, -0.01, 0.1, const V3(0.1, 1, 1)),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.2,
    tenueB: 0.25,
    courbeAB: Courbe.explosive,
    camera: Camera3.face,
    accessoires: const Accessoires(halteres: true),
  ),
  'developpe_epaules_assis': _serie(
    _mainsEn(_assisBas, 0.42, 0.345, 0.19, const V3(0.1, 1, 1)),
    _mainsEn(_assisBas, 0.405, 0.085, 0.1, const V3(0.1, 1, 1)),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.2,
    tenueB: 0.25,
    courbeAB: Courbe.explosive,
    camera: Camera3.face,
    accessoires: const Accessoires(halteres: true, banc: _bancBasAssise),
  ),
  'developpe_kettlebell': _serie(
    _largeur(_pose, z: 0.07).copier(
      mainP: const Cible(0.53, 0.275, 0.1),
      coudeP: const V3(0.3, 1, 0.3),
      brasL: 90,
      avantBrasL: 90,
      ecartBrasL: 10,
      ecartAvantBrasL: 8,
    ),
    _largeur(_pose, z: 0.07).copier(
      mainP: const Cible(0.48, -0.005, 0.1),
      coudeP: const V3(0.3, 1, 0.3),
      brasL: 90,
      avantBrasL: 90,
      ecartBrasL: 10,
      ecartAvantBrasL: 8,
    ),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.25,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(kettlebell: true),
  ),
  'developpe_militaire': _suite([
    Cle(
      _mainsEn(
        _largeur(_pose, z: 0.07),
        0.55,
        0.285,
        0.14,
        const V3(0.6, 1, 0.5),
      ),
      duree: 0.7,
      tenue: 0.25,
    ),
    // La barre passe devant le visage, puis revient à l'aplomb.
    Cle(
      _mainsEn(_largeur(_pose, z: 0.07), 0.56, 0.13, 0.14, const V3(0.3, 1, 1)),
      duree: 0.45,
      courbe: Courbe.explosive,
    ),
    Cle(
      _mainsEn(
        _largeur(_pose, z: 0.07),
        0.475,
        -0.005,
        0.13,
        const V3(0, 1, 1),
      ),
      duree: 0.45,
      tenue: 0.25,
    ),
    Cle(
      _mainsEn(_largeur(_pose, z: 0.07), 0.56, 0.13, 0.14, const V3(0.3, 1, 1)),
      duree: 0.8,
    ),
  ], accessoires: const Accessoires(barre: true)),
  'developpe_epaules_elastique': _serie(
    _mainsEn(_largeur(_pose, z: 0.07), 0.49, 0.25, 0.19, const V3(0.1, 1, 1)),
    _mainsEn(_largeur(_pose, z: 0.07), 0.475, -0.01, 0.1, const V3(0.1, 1, 1)),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.2,
    tenueB: 0.25,
    courbeAB: Courbe.explosive,
    camera: Camera3.face,
    accessoires: const Accessoires(elastique: Offset(0.47, kSol - 0.004)),
  ),
  'elevation_laterale': _serie(
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), 90, 7, 84, 4),
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), 92, 86, 82, 82),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.3,
    camera: Camera3.face,
    accessoires: const Accessoires(halteres: true),
  ),
  'elevation_laterale_elastique': _serie(
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), 90, 7, 84, 4),
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), 92, 82, 82, 78),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.3,
    camera: Camera3.face,
    accessoires: const Accessoires(elastique: Offset(0.47, kSol - 0.004)),
  ),
  'elevation_frontale': _serie(
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), 84, 6, 80, 4),
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), -2, 8, -4, 6),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.3,
    accessoires: const Accessoires(halteres: true),
  ),
  'oiseau': _serie(
    _brasDirects(_penchePlat, 92, 5, 96, 2),
    _brasDirects(_penchePlat, 88, 84, 100, 78),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.35,
    accessoires: const Accessoires(halteres: true),
  ),
  'rowing_menton': _serie(
    _mainsEn(
      _pieds(_pose, 0.47, z: 0.06),
      0.52,
      0.5,
      0.06,
      const V3(0, -1, 1.2),
    ),
    _mainsEn(
      _pieds(_pose, 0.47, z: 0.06),
      0.52,
      0.29,
      0.06,
      const V3(0, -1, 1.2),
    ),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.25,
    courbeAB: Courbe.explosive,
    camera: Camera3.face,
    accessoires: const Accessoires(halteres: true),
  ),
  'y_t_w': _suite([
    // Y : bras tendus en avant et en V, décollés.
    Cle(
      _brasDirects(_aPlatVentre.copier(tronc: -5, tete: -12), -10, 40, -12, 38),
      duree: 0.8,
      tenue: 0.6,
    ),
    // T : bras en croix.
    Cle(
      _brasDirects(_aPlatVentre.copier(tronc: -5, tete: -12), -12, 86, -12, 86),
      duree: 0.9,
      tenue: 0.6,
    ),
    // W : coudes tirés vers les hanches, mains à hauteur d'épaules.
    Cle(
      _brasDirects(_aPlatVentre.copier(tronc: -6, tete: -12), 150, 62, -8, 70),
      duree: 0.9,
      tenue: 0.6,
    ),
    // On repose.
    Cle(_brasDirects(_aPlatVentre, 150, 50, 0, 60), duree: 0.6, tenue: 0.3),
  ], camera: Camera3.dessus),
  // ══ TRICEPS ════════════════════════════════════════════════════════════
  'extension_triceps': _serie(
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), -96, -7, -94, -10),
    _brasDirects(_pieds(_pose, 0.47, z: 0.06), -100, -7, -214, -16),
    ab: 1.4,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.15,
    accessoires: const Accessoires(haltereUne: true),
  ),
  'extension_triceps_elastique': _serie(
    _brasDirects(_decale(_pose), -96, -7, -94, -10),
    _brasDirects(_decale(_pose), -100, -7, -214, -16),
    ab: 1.3,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.15,
    accessoires: const Accessoires(elastique: Offset(0.37, kSol - 0.004)),
  ),
  'kickback': _serie(
    _brasDirects(_penchePlat, 166, 4, 88, 2),
    _brasDirects(_penchePlat, 170, 4, 168, 2),
    ab: 0.8,
    ba: 1.2,
    tenueA: 0.25,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(halteres: true),
  ),
  'skull_crusher': _serie(
    _brasDirects(_dosBanc, -100, 5, -100, 3),
    _brasDirects(_dosBanc, -102, 5, -206, 3),
    ab: 1.4,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.15,
    accessoires: const Accessoires(halteres: true, banc: _bancPlat),
  ),
  'skull_crusher_barre': _serie(
    _brasDirects(_dosBanc, -100, 1, -100, 0),
    _brasDirects(_dosBanc, -102, 1, -206, 0),
    ab: 1.4,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.15,
    accessoires: const Accessoires(barre: true, banc: _bancPlat),
  ),
  'extension_triceps_sol': _serie(
    _brasDirects(_dosAuSol, -100, 5, -100, 3),
    _brasDirects(_dosAuSol, -102, 5, -200, 3),
    ab: 1.4,
    ba: 0.9,
    tenueA: 0.3,
    tenueB: 0.15,
    accessoires: const Accessoires(halteres: true, tapis: true),
  ),
};

// ── Les positions composées ────────────────────────────────────────────────

/// La pompe piquée : la hanche en ([hx], [hy]), le tronc qui plonge de
/// [tronc] degrés vers les mains (en 0,6), les jambes tendues vers
/// [pieds] (sur la pointe).
Pose3 _pique(
  double hx,
  double hy,
  double tronc, {
  Offset pieds = const Offset(0.29, kSol - 0.085),
}) => _pose.copier(
  x: hx,
  y: hy,
  tronc: tronc,
  tete: tronc + 4,
  piedCibleP: Cible(pieds.dx, pieds.dy, 0.06),
  piedCibleL: Cible(pieds.dx, pieds.dy, -0.06),
  genouP: const V3(0, 1, 0.1),
  genouL: const V3(0, 1, -0.1),
  piedP: 58,
  piedL: 58,
  mainP: const Cible(0.6, yPaume, 0.11),
  mainL: const Cible(0.6, yPaume, -0.11),
  coudeP: const V3(-0.3, -0.4, 1),
  coudeL: const V3(-0.3, -0.4, -1),
);

/// Penché contre le mur (en 0,8), les pieds à plat, l'épaule en [epaule],
/// les mains à plat sur le mur à hauteur d'épaules.
Pose3 _auMur(Offset epaule) =>
    _gaine(const Offset(0.38, yCheville), epaule, pied: 0).copier(
      mainP: const Cible(0.786, 0.32, 0.13),
      mainL: const Cible(0.786, 0.32, -0.13),
      coudeP: const V3(-0.5, 0.6, 1),
      coudeL: const V3(-0.5, 0.6, -1),
    );

/// Les dips sur un banc derrière soi : les mains au bord, les épaules qui
/// descendent à l'aplomb, les coudes vers l'arrière ; [tendues] : les
/// jambes tendues, talons au sol (sinon genoux pliés, pieds à plat).
Pose3 _dips({required bool haut, required bool tendues}) {
  const main = Offset(0.315, 0.7 - 0.013);
  final epaule = haut
      ? Offset(0.37, main.dy - 0.283)
      : Offset(0.375, main.dy - 0.145);
  const tronc = -92.0;
  final t = rad(tronc);
  final hx = epaule.dx - math.cos(t) * _lEpaule;
  final hy = epaule.dy - math.sin(t) * _lEpaule;
  return _pose.copier(
    x: hx,
    y: hy,
    tronc: tronc,
    tete: -86,
    mainP: const Cible(0.315, 0.687, 0.1),
    mainL: const Cible(0.315, 0.687, -0.1),
    coudeP: const V3(-1, 0, 0.15),
    coudeL: const V3(-1, 0, -0.15),
    piedCibleP: Cible(
      tendues ? 0.7 : 0.64,
      tendues ? kSol - 0.03 : yCheville,
      0.07,
    ),
    piedCibleL: Cible(
      tendues ? 0.7 : 0.64,
      tendues ? kSol - 0.03 : yCheville,
      -0.07,
    ),
    genouP: const V3(1, -1, 0.1),
    genouL: const V3(1, -1, -0.1),
    piedP: tendues ? -50 : 0,
    piedL: tendues ? -50 : 0,
  );
}

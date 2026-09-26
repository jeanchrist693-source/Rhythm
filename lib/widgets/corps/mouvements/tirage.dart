// lib/widgets/corps/mouvements/tirage.dart
//
// Le TIRAGE, réécrit pour la fidélité : tractions (les mains accrochées à la
// barre, le menton qui la passe, vues de dos), suspensions, rowings (les
// coudes qui filent le long du corps), superman, bird dog, swings, curls et
// marche du fermier (une vraie marche).

part of '../animations_corps.dart';

// ── Repères ────────────────────────────────────────────────────────────────

/// La barre de traction, et une plus haute pour les relevés jambes tendues.
const Offset _barreHaute = Offset(0.5, 0.02);
const Offset _barreTresHaute = Offset(0.5, -0.04);

/// La barre basse de la traction australienne.
const Offset _barreBasse = Offset(0.3, 0.5);

/// Le banc du rowing un bras.
const Rect _bancRowing = Rect.fromLTRB(0.12, 0.71, 0.62, 0.745);

// ── Positions ──────────────────────────────────────────────────────────────

/// Suspendu à [barre], les mains en prise écartées de [z], les épaules en
/// ([xEpaule], [yEpaule]) ; genoux un peu pliés, chevilles derrière.
/// [haussement] : 1 = suspension passive (épaules aux oreilles).
Pose3 _suspendu3(
  double xEpaule,
  double yEpaule, {
  Offset barre = _barreHaute,
  double z = 0.15,
  double tronc = -93,
  double haussement = 0,
  V3 coude = const V3(0.1, 1, 0.8),
}) {
  final t = rad(tronc);
  final l = _lEpaule + 0.024 * haussement;
  return _pose
      .copier(
        x: xEpaule - math.cos(t) * l,
        y: yEpaule - math.sin(t) * l,
        tronc: tronc,
        haussement: haussement,
        sansCibles: true,
        cuisseP: 100,
        cuisseL: 97,
        ecartCuisseP: 4,
        ecartCuisseL: 3,
        jambeP: 146,
        jambeL: 140,
        ecartJambeP: -3,
        ecartJambeL: 7,
        piedP: 124,
        piedL: 118,
      )
      .copier(
        mainP: Cible(barre.dx, barre.dy + 0.008, z),
        mainL: Cible(barre.dx, barre.dy + 0.008, -z),
        coudeP: coude,
        coudeL: V3(coude.x, coude.y, -coude.z),
      );
}

/// La traction australienne : le corps gainé des talons aux épaules sous
/// la barre basse.
Pose3 _australienne(Offset epaule) =>
    _gaine(
      const Offset(0.88, kSol - 0.035),
      epaule,
      genou: const V3(0, -1, 0.1),
    ).copier(
      tete: 182,
      mainP: Cible(_barreBasse.dx, _barreBasse.dy + 0.008, 0.15),
      mainL: Cible(_barreBasse.dx, _barreBasse.dy + 0.008, -0.15),
      coudeP: const V3(0.3, 1, 0.7),
      coudeL: const V3(0.3, 1, -0.7),
    );

/// Le rowing un bras : genou et main loin sur le banc, pied proche au sol,
/// dos plat ; la main proche en ([x], [y]).
Pose3 _rowingUnBras(double x, double y) => _pose
    .copier(
      x: 0.34,
      y: 0.475,
      tronc: -6,
      tete: -24,
      sansCibles: true,
      cuisseL: 90,
      ecartCuisseL: 2,
      jambeL: 180,
      piedL: 176,
    )
    .copier(
      piedCibleP: const Cible(0.3, yCheville, 0.16),
      genouP: const V3(1, 0, 0.3),
      mainL: const Cible(0.6, 0.71 - 0.013, -0.1),
      coudeL: const V3(-0.3, 0.2, -1),
      mainP: Cible(x, y, 0.11),
      coudeP: const V3(-1, -0.5, 0.25),
    );

/// Assis au sol, jambes tendues devant, buste droit.
final Pose3 _assisJambesTendues = _pose.copier(
  x: 0.36,
  y: kSol - 0.06,
  tronc: -86,
  sansCibles: true,
  cuisseP: 2,
  cuisseL: 2,
  ecartCuisseP: 3,
  ecartCuisseL: 3,
  jambeP: 0,
  jambeL: 0,
  piedP: -72,
  piedL: -72,
);

/// Les mains aux tempes, coudes ouverts.
Pose3 _mainsTempes(Pose3 p) {
  final (x, y) = _centreTete(p);
  final avant = rad(p.tronc + 90);
  final m = Offset(x + math.cos(avant) * 0.012, y + math.sin(avant) * 0.012);
  return p.copier(
    mainP: Cible(m.dx, m.dy, 0.07),
    mainL: Cible(m.dx, m.dy, -0.07),
    coudeP: const V3(-0.3, 0, 1),
    coudeL: const V3(-0.3, 0, -1),
  );
}

/// Le superman : à plat ventre, bras tendus devant ; [haut] : bras,
/// poitrine et jambes décollés.
Pose3 _superman({
  bool brasP = false,
  bool brasL = false,
  bool jambeP = false,
  bool jambeL = false,
  double poitrine = 0,
}) {
  final p = _aPlatVentre.copier(x: 0.46, tronc: -poitrine, tete: -8 - poitrine);
  return p.copier(
    brasP: brasP ? -16 : -2,
    brasL: brasL ? -16 : -2,
    avantBrasP: brasP ? -16 : -2,
    avantBrasL: brasL ? -16 : -2,
    ecartBrasP: 14,
    ecartBrasL: 14,
    ecartAvantBrasP: 12,
    ecartAvantBrasL: 12,
    cuisseP: jambeP ? 193 : 180,
    cuisseL: jambeL ? 193 : 180,
    jambeP: jambeP ? 190 : 180,
    jambeL: jambeL ? 190 : 180,
  );
}

/// À quatre pattes pour le bird dog : [proche] tend le bras proche et la
/// jambe loin (sinon l'inverse) ; [tendu] de 0 (au sol) à 1.
Pose3 _birdDog({required bool proche, required bool tendu}) {
  final base = _quatrePattes();
  if (!tendu) return base;
  final p = base.copier(sansCibles: true);
  if (proche) {
    return p
        .copier(
          brasP: -4,
          avantBrasP: -4,
          ecartBrasP: 8,
          ecartAvantBrasP: 6,
          cuisseL: 182,
          jambeL: 180,
          piedL: 170,
        )
        .copier(mainL: base.mainL, coudeL: base.coudeL);
  }
  return p
      .copier(
        brasL: -4,
        avantBrasL: -4,
        ecartBrasL: 8,
        ecartAvantBrasL: 6,
        cuisseP: 182,
        jambeP: 180,
        piedP: 170,
      )
      .copier(mainP: base.mainP, coudeP: base.coudeP);
}

/// Le curl : bras le long du corps, l'avant-bras qui monte à [avantBras].
Pose3 _curl(Pose3 p, double avantBras, {double ecart = 8}) =>
    _brasDirects(p, 94, ecart, avantBras, ecart - 2);

// ── Les mouvements ─────────────────────────────────────────────────────────

final Map<String, AnimCorps> _tirage3 = {
  // ══ À LA BARRE ═════════════════════════════════════════════════════════
  'traction': _serie(
    _suspendu3(0.49, 0.311),
    _suspendu3(0.44, 0.105, tronc: -100),
    ab: 0.9,
    ba: 1.5,
    tenueA: 0.35,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    camera: Camera3.dos,
    accessoires: const Accessoires(barreFixe: _barreHaute),
  ),
  'traction_large': _serie(
    _suspendu3(0.49, 0.3, z: 0.25),
    _suspendu3(0.445, 0.12, z: 0.25, tronc: -100),
    ab: 0.9,
    ba: 1.5,
    tenueA: 0.35,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    camera: Camera3.dos,
    accessoires: const Accessoires(barreFixe: _barreHaute),
  ),
  'traction_supination': _serie(
    _suspendu3(0.49, 0.311, z: 0.1, coude: const V3(0.7, 1, 0.3)),
    _suspendu3(0.44, 0.1, z: 0.1, tronc: -100, coude: const V3(0.7, 1, 0.3)),
    ab: 0.9,
    ba: 1.5,
    tenueA: 0.35,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    camera: Camera3.dos,
    accessoires: const Accessoires(barreFixe: _barreHaute),
  ),
  'traction_negative': _suite(
    [
      Cle(_suspendu3(0.49, 0.311), duree: 0.3, tenue: 0.4),
      // On monte d'un bond…
      Cle(
        _suspendu3(0.44, 0.105, tronc: -100),
        duree: 0.6,
        courbe: Courbe.explosive,
        tenue: 0.5,
      ),
      // … et on redescend le plus lentement possible.
      Cle(_suspendu3(0.49, 0.311), duree: 3.2, courbe: Courbe.douce),
    ],
    camera: Camera3.dos,
    accessoires: const Accessoires(barreFixe: _barreHaute),
  ),
  'traction_isometrique': _suite(
    [
      Cle(_suspendu3(0.44, 0.105, tronc: -100), duree: 1.6),
      Cle(_suspendu3(0.443, 0.112, tronc: -99), duree: 1.6),
    ],
    camera: Camera3.dos,
    accessoires: const Accessoires(barreFixe: _barreHaute),
  ),
  'suspension': _suite(
    [
      Cle(_suspendu3(0.49, 0.31, haussement: 0.7), duree: 2.2),
      Cle(_suspendu3(0.494, 0.312, haussement: 0.75, tronc: -92), duree: 2.2),
    ],
    camera: Camera3.dos,
    accessoires: const Accessoires(barreFixe: _barreHaute),
  ),
  'suspension_active': _serie(
    _suspendu3(0.49, 0.31, haussement: 1),
    _suspendu3(0.49, 0.31),
    ab: 0.8,
    ba: 1.0,
    tenueA: 0.5,
    tenueB: 1.0,
    camera: Camera3.dos,
    accessoires: const Accessoires(barreFixe: _barreHaute),
  ),
  'releve_genoux_suspendu': _serie(
    // Suspendu, genoux à peine fléchis : les pointes ne touchent pas le sol.
    _suspendu3(0.49, 0.251, barre: _barreTresHaute).copier(
      cuisseP: 94,
      cuisseL: 94,
      jambeP: 118,
      jambeL: 118,
      piedP: 44,
      piedL: 44,
    ),
    _suspendu3(0.5, 0.251, barre: _barreTresHaute, tronc: -99).copier(
      cuisseP: -24,
      cuisseL: -24,
      jambeP: 64,
      jambeL: 64,
      piedP: 30,
      piedL: 30,
    ),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.35,
    tenueB: 0.3,
    accessoires: const Accessoires(barreFixe: _barreTresHaute),
  ),
  'releve_jambes_suspendu': _serie(
    _suspendu3(0.49, 0.251, barre: _barreTresHaute).copier(
      cuisseP: 93,
      cuisseL: 93,
      jambeP: 95,
      jambeL: 95,
      piedP: 22,
      piedL: 22,
    ),
    _suspendu3(0.5, 0.251, barre: _barreTresHaute, tronc: -101).copier(
      cuisseP: -4,
      cuisseL: -4,
      jambeP: -2,
      jambeL: -2,
      piedP: -40,
      piedL: -40,
    ),
    ab: 1.0,
    ba: 1.4,
    tenueA: 0.35,
    tenueB: 0.3,
    accessoires: const Accessoires(barreFixe: _barreTresHaute),
  ),
  'traction_australienne': _serie(
    _australienne(const Offset(0.268, 0.785)),
    _australienne(const Offset(0.33, 0.6)),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.3,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(barreFixe: _barreBasse),
  ),
  // ══ ROWINGS ════════════════════════════════════════════════════════════
  'rowing_penche': _serie(
    _mainsEn(_penchePlat, 0.575, 0.73, 0.155, const V3(-1, -0.5, 0.3)),
    _mainsEn(_penchePlat, 0.47, 0.585, 0.16, const V3(-1, -0.5, 0.3)),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(halteres: true),
  ),
  'rowing_penche_barre': _serie(
    _mainsEn(_penchePlat, 0.58, 0.72, 0.16, const V3(-1, -0.5, 0.4)),
    _mainsEn(_penchePlat, 0.49, 0.6, 0.16, const V3(-1, -0.5, 0.4)),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(barre: true),
  ),
  'rowing_un_bras': _serie(
    _rowingUnBras(0.57, 0.73),
    _rowingUnBras(0.44, 0.56),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(haltereUne: true, banc: _bancRowing),
  ),
  'renegade_row': _suite([
    Cle(_renegade(), duree: 0.6, tenue: 0.3),
    Cle(
      _renegade(tireP: true),
      duree: 0.7,
      courbe: Courbe.explosive,
      tenue: 0.25,
    ),
    Cle(_renegade(), duree: 0.8, tenue: 0.3),
    Cle(
      _renegade(tireL: true),
      duree: 0.7,
      courbe: Courbe.explosive,
      tenue: 0.25,
    ),
  ], accessoires: const Accessoires(halteres: true)),
  'rowing_elastique': _serie(
    _mainsEn(_assisJambesTendues, 0.66, 0.68, 0.09, const V3(-1, 0.3, 0.3)),
    _mainsEn(
      _assisJambesTendues.copier(tronc: -92),
      0.44,
      0.67,
      0.13,
      const V3(-1, 0.3, 0.3),
    ),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(elastique: Offset(0.8, 0.85)),
  ),
  'tirage_elastique': _serie(
    _mainsEn(_largeur(_pose, z: 0.07), 0.5, 0.0, 0.2, const V3(0, 1, 1)),
    _mainsEn(_largeur(_pose, z: 0.07), 0.49, 0.235, 0.24, const V3(0, 1, 1)),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    camera: Camera3.dos,
    accessoires: const Accessoires(elastique: Offset(0.52, -0.12)),
  ),
  'face_pull': _serie(
    _mainsEn(_decale(_pose), 0.76, 0.25, 0.07, const V3(-0.3, -0.7, 1)),
    _mainsEn(_decale(_pose), 0.53, 0.2, 0.2, const V3(-0.3, -0.7, 1)),
    ab: 0.8,
    ba: 1.3,
    tenueA: 0.2,
    tenueB: 0.4,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(elastique: Offset(0.97, 0.22)),
  ),
  // ══ AU SOL ═════════════════════════════════════════════════════════════
  'superman': _serie(
    _superman(),
    _superman(
      brasP: true,
      brasL: true,
      jambeP: true,
      jambeL: true,
      poitrine: 10,
    ),
    ab: 0.8,
    ba: 1.0,
    tenueA: 0.4,
    tenueB: 1.2,
    camera: Camera3.dessus,
  ),
  'nageur': _suite([
    Cle(_superman(brasP: true, jambeL: true, poitrine: 8), duree: 0.4),
    Cle(_superman(brasL: true, jambeP: true, poitrine: 8), duree: 0.4),
  ], camera: Camera3.dessus),
  'extension_lombaire': _serie(
    _mainsTempes(_aPlatVentre.copier(x: 0.45)),
    _mainsTempes(_aPlatVentre.copier(x: 0.45, tronc: -18, tete: -28)),
    ab: 0.9,
    ba: 1.2,
    tenueA: 0.4,
    tenueB: 0.6,
    camera: Camera3.dessus,
  ),
  'bird_dog': _suite([
    Cle(_birdDog(proche: true, tendu: false), duree: 0.8, tenue: 0.3),
    Cle(_birdDog(proche: true, tendu: true), duree: 1.0, tenue: 1.0),
    Cle(_birdDog(proche: true, tendu: false), duree: 0.8, tenue: 0.3),
    Cle(_birdDog(proche: false, tendu: true), duree: 1.0, tenue: 1.0),
  ]),
  // ══ HANCHES ════════════════════════════════════════════════════════════
  'swing_kettlebell': _suite([
    Cle(
      _joindreMains(_brasDirects(_largeur(_pose, z: 0.1), -2, -9, -2, -12)),
      duree: 0.5,
      courbe: Courbe.explosive,
      tenue: 0.1,
    ),
    Cle(
      _joindreMains(
        _brasDirects(
          _largeur(_pose, z: 0.1).copier(x: 0.36, y: 0.56, tronc: -34, dos: 2),
          114,
          -5,
          116,
          -7,
        ),
      ),
      duree: 0.55,
      courbe: Courbe.lancee,
      tenue: 0.05,
    ),
  ], accessoires: const Accessoires(kettlebell: true)),
  'swing_haltere': _suite([
    Cle(
      _joindreMains(_brasDirects(_largeur(_pose, z: 0.1), -2, -9, -2, -12)),
      duree: 0.5,
      courbe: Courbe.explosive,
      tenue: 0.1,
    ),
    Cle(
      _joindreMains(
        _brasDirects(
          _largeur(_pose, z: 0.1).copier(x: 0.36, y: 0.56, tronc: -34, dos: 2),
          114,
          -5,
          116,
          -7,
        ),
      ),
      duree: 0.55,
      courbe: Courbe.lancee,
      tenue: 0.05,
    ),
  ], accessoires: const Accessoires(goblet: true)),
  'swing_une_main': _suite([
    Cle(
      _brasDirects(
        _largeur(_pose, z: 0.1),
        -2,
        -4,
        -2,
        -6,
      ).copier(brasL: 60, avantBrasL: 20, ecartBrasL: 20),
      duree: 0.5,
      courbe: Courbe.explosive,
      tenue: 0.1,
    ),
    Cle(
      _brasDirects(
        _largeur(_pose, z: 0.12).copier(x: 0.36, y: 0.56, tronc: -34, dos: 2),
        114,
        -13,
        116,
        -16,
      ).copier(brasL: 150, avantBrasL: 120, ecartBrasL: 20),
      duree: 0.55,
      courbe: Courbe.lancee,
      tenue: 0.05,
    ),
  ], accessoires: const Accessoires(kettlebell: true)),
  // ══ ÉPAULES, BRAS ══════════════════════════════════════════════════════
  'shrug': _serie(
    _brasPendus(_pieds(_pose, 0.47, z: 0.06)),
    _brasPendus(_pieds(_pose, 0.47, z: 0.06)).copier(haussement: 1),
    ab: 0.7,
    ba: 1.1,
    tenueA: 0.3,
    tenueB: 0.6,
    camera: Camera3.face,
    accessoires: const Accessoires(halteres: true),
  ),
  'curl': _serie(
    _curl(_pieds(_pose, 0.47, z: 0.06), 88),
    _curl(_pieds(_pose, 0.47, z: 0.06), -56),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(halteres: true),
  ),
  'curl_barre': _serie(
    _barreDevantJambes(_curl(_pieds(_pose, 0.47, z: 0.06), 88, ecart: 13)),
    _curl(_pieds(_pose, 0.47, z: 0.06), -56, ecart: 13),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(barre: true),
  ),
  'curl_elastique': _serie(
    _curl(_pieds(_pose, 0.47, z: 0.06), 88),
    _curl(_pieds(_pose, 0.47, z: 0.06), -56),
    ab: 0.9,
    ba: 1.3,
    tenueA: 0.25,
    tenueB: 0.3,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(elastique: Offset(0.47, kSol - 0.004)),
  ),
  'curl_concentre': _serie(
    _concentre(88),
    _concentre(-38),
    ab: 0.9,
    ba: 1.4,
    tenueA: 0.25,
    tenueB: 0.35,
    courbeAB: Courbe.explosive,
    accessoires: const Accessoires(haltereUne: true, banc: _bancBasAssise),
  ),
  // Paumes vers le HAUT (elles regardaient le sol) : la main s'enroule vers
  // le haut, vivement, et redescend lentement.
  'curl_poignet': _serie(
    _poignets(-42).copier(pronationP: 180, pronationL: 180),
    _poignets(34).copier(pronationP: 180, pronationL: 180),
    ab: 1.0,
    ba: 0.6,
    tenueA: 0.3,
    tenueB: 0.15,
    courbeBA: Courbe.explosive,
    accessoires: const Accessoires(halteres: true, banc: _bancBasAssise),
  ),
  'marche_fermier': _allure(
    duree: 1.25,
    pas: 0.1,
    bras: 3,
    coude: 0,
    tronc: -89,
    retouche: (p, u) => p.copier(
      ecartBrasP: 13,
      ecartBrasL: 13,
      ecartAvantBrasP: 10,
      ecartAvantBrasL: 10,
      haussement: 0.15,
    ),
    accessoires: const Accessoires(halteres: true),
  ),
  'marche_valise': _allure(
    duree: 1.25,
    pas: 0.1,
    bras: 3,
    coude: 0,
    tronc: -89,
    retouche: (p, u) => p.copier(
      ecartBrasP: 12,
      ecartAvantBrasP: 10,
      brasL: 88,
      avantBrasL: 60,
      ecartBrasL: 30,
      ecartAvantBrasL: 50,
    ),
    accessoires: const Accessoires(haltereUne: true),
  ),
};

// ── Les positions composées ────────────────────────────────────────────────

/// Le renegade row : planche haute sur deux haltères, pieds écartés ; une
/// main tire l'haltère jusqu'à la hanche.
Pose3 _renegade({bool tireP = false, bool tireL = false}) {
  final p = _pompe(
    kSol - 0.05 - 0.28,
    main: const Offset(0.67, kSol - 0.05),
    zMain: 0.13,
    zPieds: 0.13,
  );
  if (tireP) {
    return p.copier(
      mainP: const Cible(0.53, 0.7, 0.13),
      coudeP: const V3(-1, -1, 0.2),
      roulis: -6,
    );
  }
  if (tireL) {
    return p.copier(
      mainL: const Cible(0.53, 0.7, -0.13),
      coudeL: const V3(-1, -1, -0.2),
      roulis: 6,
    );
  }
  return p;
}

/// Le curl concentré : assis, penché, le coude proche calé contre
/// l'intérieur de la cuisse ; l'avant-bras qui monte à [avantBras].
Pose3 _concentre(double avantBras) => _assisBas
    .copier(
      tronc: -50,
      tete: -40,
      piedCibleP: const Cible(0.64, yCheville, 0.2),
      piedCibleL: const Cible(0.64, yCheville, -0.2),
      genouP: const V3(1, -0.2, 0.5),
      genouL: const V3(1, -0.2, -0.5),
      brasP: 92,
      ecartBrasP: -18,
      avantBrasP: avantBras,
      ecartAvantBrasP: -20,
    )
    .copier(mainL: const Cible(0.6, 0.52, -0.13), coudeL: const V3(0, 1, -1));

/// La flexion des poignets : assis, les avant-bras posés sur les cuisses,
/// les mains qui dépassent des genoux ; [poignet] : l'angle du poignet.
Pose3 _poignets(double poignet) => _brasDirects(
  _assisBas.copier(tronc: -70, tete: -56),
  60,
  8,
  4,
  4,
).copier(poignetP: poignet, poignetL: poignet);

// lib/widgets/corps/corps_humain.dart
//
// Ce que partagent le squelette (`squelette3.dart`), le peintre
// (`peintre3.dart`) et les mouvements (`animations_corps.dart`) : le repère
// (un carré 0..1, y vers le bas, le sol à [kSol]), l'ancrage d'une pose et
// le MATÉRIEL d'une animation (haltères, barre, kettlebell, banc, barre
// fixe, élastique, marche, mur, corde, tapis, vélo).

import 'dart:ui';

export '../../modele/sports/muscles.dart' show Muscle;

/// Le sol.
const double kSol = 0.92;

/// Les marches d'un escalier : hauteur, profondeur.
const double kMarcheHaut = 0.055, kMarcheProf = 0.105;

/// Ce qui reste en place d'une pose à l'autre : la hanche (par défaut),
/// les PIEDS (mouvements debout : la hanche recule, les pieds restent
/// plantés) ou les MAINS (suspendu à une barre).
enum Ancre { hanche, pieds, mains }

// ═══ Le matériel d'une animation ════════════════════════════════════════════

/// Ce que tient ou utilise le corps. Les positions sont dans le carré 0..1.
class Accessoires {
  const Accessoires({
    this.halteres = false,
    this.goblet = false,
    this.bandeGenoux = false,
    this.haltereUne = false,
    this.haltereTravers = false,
    this.barre = false,
    this.barreDos = false,
    this.kettlebell = false,
    this.kettlebells = false,
    this.bandeMains = false,
    this.banc,
    this.dossier,
    this.barreFixe,
    this.elastique,
    this.elastiqueZ,
    this.marche,
    this.corde = false,
    this.cordeDouble = false,
    this.tapis = false,
    this.ballon = false,
    this.velo = false,
    this.mur,
    this.bandeTraction = false,
    this.plateau = false,
    this.escalier,
    this.pente,
    this.veloFixe = false,
    this.sac = false,
  });

  /// Le vélo est un vélo D'INTÉRIEUR : un socle et un volant d'inertie au
  /// lieu des deux roues.
  final bool veloFixe;

  /// Un sac à dos (randonnée).
  final bool sac;

  /// Un sol EN PENTE (la montée vers l'avant, par unité d'abscisse) : le
  /// sol passe par (0,47 ; [kSol]).
  final double? pente;

  /// Un élastique d'assistance noué à la barre fixe, le genou proche dedans.
  final bool bandeTraction;

  /// La barre fixe est le BORD D'UNE TABLE (tirage sous une table).
  final bool plateau;

  /// Un ESCALIER qui défile (on monte sur place) : le nez de la marche 0 au
  /// début du cycle ; il descend de deux marches par cycle.
  final Offset? escalier;

  /// Un mur vertical à cette abscisse.
  final double? mur;

  /// Un vélo (de profil), sous le cycliste.
  final bool velo;

  /// Un haltère dans chaque main ; [haltereUne] : dans la main proche.
  final bool halteres, haltereUne;

  /// UN haltère tenu à deux mains jointes, qui pend sous les paumes (squat
  /// goblet, extension au-dessus de la tête, pull-over, bûcheron).
  final bool goblet;

  /// UN haltère en travers, une main sur chaque bout (hip thrust).
  final bool haltereTravers;

  /// Une mini-bande élastique autour des jambes, sous les genoux.
  final bool bandeGenoux;

  /// Une barre tenue (de profil, on la voit de bout : un disque aux mains).
  final bool barre;

  /// Une barre posée sur le haut du dos (squat, fente arrière).
  final bool barreDos;

  /// Une kettlebell tenue à deux mains (ou dans la main proche de profil).
  final bool kettlebell;

  /// Une kettlebell dans CHAQUE main.
  final bool kettlebells;

  /// Un élastique tendu d'une main à l'autre (écartement d'élastique).
  final bool bandeMains;

  /// Un banc : du bord gauche au bord droit, à la hauteur de son dessus.
  final Rect? banc;

  /// Le dossier incliné d'un banc : de (x, y) bas vers (x, y) haut.
  final (Offset, Offset)? dossier;

  /// Une barre fixe (vue de bout de profil).
  final Offset? barreFixe;

  /// Un élastique attaché à ce point, une poignée dans chaque main (accroché
  /// en hauteur ou à mi-hauteur, il passe de chaque côté du corps).
  final Offset? elastique;

  /// La profondeur de l'attache de l'élastique, quand elle est sur le côté
  /// (Pallof, bûcheron) ; sinon, en face de chaque main.
  final double? elastiqueZ;

  /// Une marche / une chaise : le rectangle de son dessus jusqu'au sol.
  final Rect? marche;

  /// Une corde à sauter ; [cordeDouble] : elle passe deux fois par saut.
  final bool corde, cordeDouble;

  /// Un tapis au sol.
  final bool tapis;

  /// Un ballon (médecine-ball) à deux mains.
  final bool ballon;

  /// Le même matériel, la CHARGE tenue remplacée (haltères, barre,
  /// kettlebell — ou rien).
  Accessoires avecCharge({
    bool halteres = false,
    bool goblet = false,
    bool haltereUne = false,
    bool haltereTravers = false,
    bool barre = false,
    bool barreDos = false,
    bool kettlebell = false,
    bool kettlebells = false,
  }) => Accessoires(
    halteres: halteres,
    goblet: goblet,
    bandeGenoux: bandeGenoux,
    haltereUne: haltereUne,
    haltereTravers: haltereTravers,
    barre: barre,
    barreDos: barreDos,
    kettlebell: kettlebell,
    kettlebells: kettlebells,
    bandeMains: bandeMains,
    banc: banc,
    dossier: dossier,
    barreFixe: barreFixe,
    elastique: elastique,
    elastiqueZ: elastiqueZ,
    marche: marche,
    corde: corde,
    cordeDouble: cordeDouble,
    tapis: tapis,
    ballon: ballon,
    velo: velo,
    mur: mur,
    bandeTraction: bandeTraction,
    plateau: plateau,
    escalier: escalier,
    pente: pente,
    veloFixe: veloFixe,
    sac: sac,
  );

  bool get tientUneCharge =>
      halteres ||
      haltereUne ||
      haltereTravers ||
      goblet ||
      barre ||
      barreDos ||
      kettlebell ||
      kettlebells;
}

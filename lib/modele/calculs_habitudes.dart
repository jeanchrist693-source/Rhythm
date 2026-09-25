// lib/modele/calculs_habitudes.dart
//
// Tout ce qui se DÉDUIT des habitudes, en fonctions pures (testées dans
// `test/calculs_habitudes_test.dart`) : les écrans n'inventent rien.
//
// Règles des séries (celles de Flow) :
// - AUJOURD'HUI EST TOLÉRÉ : pas encore coché ne casse rien, la journée
//   n'est pas finie ; coché, il compte ;
// - un jour NON PRÉVU (« lun · mer · ven ») ne casse pas la série et ne
//   compte pas — sauf s'il a été fait quand même (un bonus compte) ;
// - rien ne compte avant la création de l'habitude.
// Une JOURNÉE COMPLÈTE : toutes les habitudes à construire prévues ce
// jour-là sont faites. La série globale (l'écran, l'accueil) compte les
// journées complètes d'affilée ; un jour sans rien de prévu est sauté.
// Les habitudes à LIBÉRER n'entrent pas dans les journées : elles ont leur
// compteur (et une rechute ne casse jamais la série des autres).

import 'dart:math' as math;

import '../utils/dates.dart';
import 'habitudes.dart';

/// Les paliers d'une série, en jours (66 : la durée moyenne pour qu'une
/// habitude devienne automatique — Lally et al., 2009).
const List<int> kPaliersSerie = [3, 7, 14, 21, 30, 50, 66, 100, 150, 200, 365];

/// Les paliers d'une libération, en jours.
const List<int> kPaliersLiberte = [1, 3, 7, 14, 21, 30, 60, 90, 180, 365];

// ── Construire ─────────────────────────────────────────────────────────────

/// [h] est-elle prévue le [jour] ? (Libérer : tous les jours.)
bool estPrevue(Habitude h, DateTime jour) {
  final j = jourDe(jour);
  if (j.isBefore(h.creeLe)) return false;
  return h.aLiberer || h.quotidienne || h.jours.contains(j.weekday);
}

bool estFaite(Habitude h, DateTime jour) => h.faits.contains(cleJour(jour));

/// Le premier jour qui compte : la création, ou un jour fait avant elle
/// (données anciennes).
DateTime _debut(Habitude h) {
  var debut = h.creeLe;
  for (final cle in h.faits) {
    final j = jourDeCle(cle);
    if (j.isBefore(debut)) debut = j;
  }
  return debut;
}

/// La série en cours de [h] au [aujourdhui] (voir les règles en tête).
int serie(Habitude h, DateTime aujourdhui) {
  final auj = jourDe(aujourdhui);
  final debut = _debut(h);
  var n = estFaite(h, auj) ? 1 : 0;
  for (var j = plusJours(auj, -1); !j.isBefore(debut); j = plusJours(j, -1)) {
    if (estFaite(h, j)) {
      n++;
    } else if (estPrevue(h, j)) {
      break;
    }
  }
  return n;
}

/// La plus longue série de [h] jusqu'au [aujourdhui].
int record(Habitude h, DateTime aujourdhui) {
  final auj = jourDe(aujourdhui);
  var meilleur = 0, courant = 0;
  for (var j = _debut(h); !j.isAfter(auj); j = plusJours(j, 1)) {
    if (estFaite(h, j)) {
      courant++;
      meilleur = math.max(meilleur, courant);
    } else if (estPrevue(h, j) && j != auj) {
      courant = 0;
    }
  }
  return meilleur;
}

/// Part des jours prévus faits sur les [jours] derniers jours (depuis la
/// création si elle est plus récente ; aujourd'hui seulement s'il est
/// fait). `null` : aucun jour prévu dans la fenêtre.
double? taux(Habitude h, DateTime aujourdhui, {int jours = 30}) {
  final auj = jourDe(aujourdhui);
  var prevus = 0, faits = 0;
  for (var i = 0; i < jours; i++) {
    final j = plusJours(auj, -i);
    if (!estPrevue(h, j)) continue;
    final fait = estFaite(h, j);
    if (i == 0 && !fait) continue;
    prevus++;
    if (fait) faits++;
  }
  return prevus == 0 ? null : faits / prevus;
}

/// Un jour, pour les habitudes à construire.
class Journee {
  const Journee(this.prevues, this.faites);

  final int prevues;

  /// Faites parmi les prévues.
  final int faites;

  bool get vide => prevues == 0;
  bool get complete => prevues > 0 && faites >= prevues;
  bool get entamee => faites > 0;
  int get reste => math.max(0, prevues - faites);
}

Journee journee(List<Habitude> habitudes, DateTime jour) {
  var prevues = 0, faites = 0;
  for (final h in habitudes) {
    if (h.aLiberer || !estPrevue(h, jour)) continue;
    prevues++;
    if (estFaite(h, jour)) faites++;
  }
  return Journee(prevues, faites);
}

DateTime? _premierJour(List<Habitude> habitudes) {
  DateTime? debut;
  for (final h in habitudes) {
    if (h.aLiberer) continue;
    final d = _debut(h);
    if (debut == null || d.isBefore(debut)) debut = d;
  }
  return debut;
}

/// Les journées complètes d'affilée au [aujourdhui] (aujourd'hui toléré,
/// jours sans rien de prévu sautés).
int serieGlobale(List<Habitude> habitudes, DateTime aujourdhui) {
  final debut = _premierJour(habitudes);
  if (debut == null) return 0;
  final auj = jourDe(aujourdhui);
  var n = journee(habitudes, auj).complete ? 1 : 0;
  for (var j = plusJours(auj, -1); !j.isBefore(debut); j = plusJours(j, -1)) {
    final jour = journee(habitudes, j);
    if (jour.vide) continue;
    if (!jour.complete) break;
    n++;
  }
  return n;
}

/// La plus longue suite de journées complètes.
int recordGlobal(List<Habitude> habitudes, DateTime aujourdhui) {
  final debut = _premierJour(habitudes);
  if (debut == null) return 0;
  final auj = jourDe(aujourdhui);
  var meilleur = 0, courant = 0;
  for (var j = debut; !j.isAfter(auj); j = plusJours(j, 1)) {
    final jour = journee(habitudes, j);
    if (jour.complete) {
      courant++;
      meilleur = math.max(meilleur, courant);
    } else if (!jour.vide && j != auj) {
      courant = 0;
    }
  }
  return meilleur;
}

/// L'habitude à construire, prévue [aujourdhui] et pas encore faite, qui a
/// SAUTÉ son dernier jour prévu (« jamais deux fois de suite »). La plus
/// ancienne d'abord.
Habitude? manqueeHier(List<Habitude> habitudes, DateTime aujourdhui) {
  final auj = jourDe(aujourdhui);
  for (final h in habitudes) {
    if (h.aLiberer || !estPrevue(h, auj) || estFaite(h, auj)) continue;
    // Le dernier jour prévu avant aujourd'hui (au plus une semaine avant).
    for (var i = 1; i <= 7; i++) {
      final j = plusJours(auj, -i);
      if (j.isBefore(h.creeLe)) break;
      if (!estPrevue(h, j)) continue;
      if (!estFaite(h, j)) return h;
      break;
    }
  }
  return null;
}

// ── Paliers ────────────────────────────────────────────────────────────────

/// Le palier que [valeur] vient d'atteindre EXACTEMENT, s'il y en a un
/// (au-delà de la table : chaque année).
int? palierAtteint(List<int> paliers, int valeur) {
  if (paliers.contains(valeur)) return valeur;
  if (valeur > paliers.last && valeur % 365 == 0) return valeur;
  return null;
}

/// Le prochain palier après [valeur] et celui d'avant (0 au départ) : la
/// jauge « prochain palier » va de l'un à l'autre.
({int precedent, int suivant}) prochainPalier(List<int> paliers, num valeur) {
  var precedent = 0;
  for (final p in paliers) {
    if (valeur < p) return (precedent: precedent, suivant: p);
    precedent = p;
  }
  final annees = (valeur / 365).floor();
  return (
    precedent: math.max(precedent, annees * 365),
    suivant: (annees + 1) * 365,
  );
}

// ── Libérer ────────────────────────────────────────────────────────────────

/// Le temps libre en cours (depuis la dernière rechute).
Duration dureeLiberte(Habitude h, DateTime maintenant) {
  final d = maintenant.difference(h.debutLiberte);
  return d.isNegative ? Duration.zero : d;
}

/// La plus longue période libre (celle en cours comprise).
Duration recordLiberte(Habitude h, DateTime maintenant) {
  var meilleur = Duration.zero;
  var debut = h.debutDeclare;
  for (final r in [...h.rechutes, maintenant]) {
    final d = r.difference(debut);
    if (d > meilleur) meilleur = d;
    debut = r;
  }
  return meilleur;
}

/// Jours libres depuis le début déclaré (chaque rechute en retire un).
double joursLibres(Habitude h, DateTime maintenant) {
  final total =
      maintenant.difference(h.debutDeclare).inMinutes / Duration.minutesPerDay;
  return math.max(0, total - h.rechutes.length);
}

/// Ce qui n'a pas été dépensé depuis le début ; `null` sans coût déclaré.
double? economies(Habitude h, DateTime maintenant) {
  final cout = h.coutParJour;
  if (cout == null || cout <= 0) return null;
  return cout * joursLibres(h, maintenant);
}

/// Les envies surmontées (notées, et tenues).
int enviesSurmontees(Habitude h) => h.envies.where((e) => e.tenue).length;

/// Le déclencheur le plus noté ; `null` sans envie qui en porte un.
String? declencheurFrequent(Habitude h) {
  final comptes = <String, int>{};
  for (final e in h.envies) {
    final d = e.declencheur;
    if (d == null || d.trim().isEmpty) continue;
    comptes[d] = (comptes[d] ?? 0) + 1;
  }
  if (comptes.isEmpty) return null;
  return comptes.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

/// Les moments de la journée.
enum Tranche { nuit, matin, apresMidi, soir }

/// Nuit 23 h – 5 h, matin 5 h – 12 h, après-midi 12 h – 18 h, soir 18 h – 23 h.
Tranche trancheDe(DateTime t) => switch (t.hour) {
  < 5 => Tranche.nuit,
  < 12 => Tranche.matin,
  < 18 => Tranche.apresMidi,
  < 23 => Tranche.soir,
  _ => Tranche.nuit,
};

/// Le moment où les envies arrivent le plus (au moins trois envies notées).
Tranche? trancheFrequente(Habitude h) {
  if (h.envies.length < 3) return null;
  final comptes = <Tranche, int>{};
  for (final e in h.envies) {
    final t = trancheDe(e.quand);
    comptes[t] = (comptes[t] ?? 0) + 1;
  }
  return comptes.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

// ── L'ordre ────────────────────────────────────────────────────────────────

/// [habitudes] dans l'ordre choisi : le sien (celui de la liste), ou par
/// heure de rappel (sans rappel à la fin, dans leur ordre) ; l'épinglée
/// toujours en tête.
List<Habitude> ordonner(List<Habitude> habitudes, ReglagesHabitudes r) {
  final liste = [...habitudes];
  if (r.tri == TriHabitudes.rappel) {
    final rang = {for (var i = 0; i < liste.length; i++) liste[i].id: i};
    liste.sort((a, b) {
      final ra = a.rappel, rb = b.rappel;
      if (ra != rb) {
        if (ra == null) return 1;
        if (rb == null) return -1;
        return ra.compareTo(rb);
      }
      return rang[a.id]!.compareTo(rang[b.id]!);
    });
  }
  final i = liste.indexWhere((h) => h.id == r.epinglee);
  if (i > 0) liste.insert(0, liste.removeAt(i));
  return liste;
}

/// Le nouvel ordre de [toutes] quand une partie d'entre elles ([partie],
/// dans le nouvel ordre voulu) a été réordonnée : les places qu'elles
/// occupaient sont reprises dans ce nouvel ordre, les autres ne bougent pas.
List<Habitude> reordonnerListe(List<Habitude> toutes, List<String> partie) {
  final dans = partie.toSet();
  final parId = {for (final h in toutes) h.id: h};
  final suite = partie.where(parId.containsKey).iterator;
  return [
    for (final h in toutes)
      if (dans.contains(h.id) && suite.moveNext()) parId[suite.current]! else h,
  ];
}

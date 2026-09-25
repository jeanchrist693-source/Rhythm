// lib/modele/alimentation/calculs_alimentation.dart
//
// Les RÈGLES de l'alimentation, pures et testées (aucun widget, aucun état) :
//
// - BESOINS : métabolisme de base de Mifflin-St Jeor (le plus juste des
//   calculs usuels) × l'activité HORS SPORT, + les calories des séances
//   (moyenne des 14 derniers jours — une cible stable, qui suit l'activité
//   réelle lue dans les Sports), ± l'objectif (7 700 kcal par kilo : 0,25
//   kg / semaine ≈ 275 kcal / jour), + l'AJUSTEMENT AUTOMATIQUE. Jamais sous
//   le métabolisme × 1,1 ni sous 1 500 (homme) / 1 200 kcal (femme).
// - MACRONUTRIMENTS : protéines au kilo (perdre 2,0 ; maintenir 1,6 ;
//   prendre 1,8 g/kg), lipides 30 % des calories (25 % un jour de séance :
//   un peu plus de glucides quand on s'entraîne), au moins 0,8 g/kg ;
//   glucides : le reste.
// - AJUSTEMENT AUTOMATIQUE : sur les 21 derniers jours, si au moins 10
//   journées sont notées et 3 pesées couvrent 10 jours, la dépense RÉELLE =
//   apport moyen − (tendance du poids × 7 700). La moitié de l'écart avec
//   la formule corrige les besoins (± 400 au plus) : prudent, car une
//   journée notée n'est jamais tout à fait complète.
// - EAU : 35 ml par kilo, dont 80 % à boire (le reste vient des aliments),
//   en verres de 250 ml (6 à 16), + 1 verre par demi-heure de sport du jour.
// - Le CONSEIL DU JOUR (le genre ; les mots sont dans
//   `l10n/libelles_alimentation.dart`).

import 'dart:math' as math;

import '../../utils/dates.dart';
import '../modeles.dart';
import '../sports/calculs_sport.dart';
import '../sports/sport.dart';
import 'alimentation.dart';
import 'nutriments.dart';

const double kKcalParKilo = 7700;

/// Le volume d'un verre, en litres.
const double kLitresParVerre = 0.25;

/// L'âge à utiliser (30 ans tant qu'on ne le connaît pas).
int ageDe(ProfilNutrition p, DateTime jour) =>
    p.anneeNaissance == null ? 30 : jour.year - p.anneeNaissance!;

/// Mifflin-St Jeor (kcal / jour). Sexe inconnu : la moyenne des deux.
double metabolismeBase({
  required Sexe? sexe,
  required double poids,
  required double taille,
  required int age,
}) {
  final base = 10 * poids + 6.25 * taille - 5 * age;
  return switch (sexe) {
    Sexe.homme => base + 5,
    Sexe.femme => base - 161,
    null => base - 78,
  };
}

/// La taille à utiliser (moyenne canadienne tant qu'on ne la connaît pas).
double tailleDe(ProfilNutrition p) =>
    p.taille ?? (p.sexe == Sexe.femme ? 163 : (p.sexe == null ? 170 : 176));

/// Les calories des séances, par jour, en moyenne sur les [jours] jours
/// AVANT [jour].
double sportMoyen(List<SeanceFaite> journal, DateTime jour, {int jours = 14}) {
  final debut = plusJours(jour, -jours);
  final fin = jourDe(jour);
  var total = 0;
  for (final s in journal) {
    final j = jourDe(s.debut);
    if (!j.isBefore(debut) && j.isBefore(fin)) total += s.kcal;
  }
  return total / jours;
}

/// Minutes de sport faites [jour].
int minutesSportDu(List<SeanceFaite> journal, DateTime jour) {
  final j = jourDe(jour);
  return journal
      .where((s) => jourDe(s.debut) == j)
      .fold(0, (m, s) => m + s.minutes);
}

/// Un jour de séance : une séance faite ce jour-là, ou (aujourd'hui) une
/// séance prévue.
bool estJourDeSeance(
  List<SeanceFaite> journal,
  List<Programme> programmes,
  DateTime jour,
  DateTime aujourdhui,
) {
  final j = jourDe(jour);
  if (journal.any((s) => jourDe(s.debut) == j)) return true;
  return j == jourDe(aujourdhui) &&
      seanceDuJour(programmes, journal, aujourdhui) != null;
}

// ═══ L'ajustement automatique ═══════════════════════════════════════════════

enum EtatAjustement { desactive, donneesInsuffisantes, actif }

class Ajustement {
  const Ajustement({
    required this.etat,
    this.kcal = 0,
    this.joursNotes = 0,
    this.pesees = 0,
    this.depenseReelle,
    this.rythmeReel,
  });

  final EtatAjustement etat;

  /// La correction appliquée aux besoins (kcal / jour).
  final int kcal;
  final int joursNotes;
  final int pesees;

  /// La dépense estimée d'après l'apport et le poids.
  final double? depenseReelle;

  /// La tendance du poids, en kg par semaine.
  final double? rythmeReel;
}

/// Une journée compte si elle a au moins 2 aliments et 1 000 kcal.
bool journeeNotee(List<EntreeJournal> entrees) =>
    entrees.length >= 2 &&
    Nutriments.somme(entrees.map((e) => e.nutriments)).kcal >= 1000;

Ajustement ajustementAdaptatif({
  required List<EntreeJournal> journal,
  required List<MesureCorps> mesures,
  required DateTime jour,
  required double depenseFormule,
  bool actif = true,
}) {
  if (!actif) return const Ajustement(etat: EtatAjustement.desactive);
  final auj = jourDe(jour);
  final debut = plusJours(auj, -21);
  final parJour = <DateTime, List<EntreeJournal>>{};
  for (final e in journal) {
    if (!e.jour.isBefore(debut) && e.jour.isBefore(auj)) {
      parJour.putIfAbsent(e.jour, () => []).add(e);
    }
  }
  final notes = [
    for (final l in parJour.values)
      if (journeeNotee(l)) Nutriments.somme(l.map((e) => e.nutriments)).kcal,
  ];
  final pesees = [
    for (final m in mesures)
      if (m.poids != null &&
          !m.date.isBefore(plusJours(debut, -3)) &&
          !jourDe(m.date).isAfter(auj))
        m,
  ];
  final etendue = pesees.length < 2
      ? 0
      : joursEntre(pesees.first.date, pesees.last.date);
  if (notes.length < 10 || pesees.length < 3 || etendue < 10) {
    return Ajustement(
      etat: EtatAjustement.donneesInsuffisantes,
      joursNotes: notes.length,
      pesees: pesees.length,
    );
  }
  // Tendance du poids : moindres carrés (kg par jour).
  final t0 = pesees.first.date;
  final xs = [for (final m in pesees) joursEntre(t0, m.date).toDouble()];
  final ys = [for (final m in pesees) m.poids!];
  final mx = xs.reduce((a, b) => a + b) / xs.length;
  final my = ys.reduce((a, b) => a + b) / ys.length;
  var num = 0.0, den = 0.0;
  for (var i = 0; i < xs.length; i++) {
    num += (xs[i] - mx) * (ys[i] - my);
    den += (xs[i] - mx) * (xs[i] - mx);
  }
  final pente = den == 0 ? 0.0 : num / den;
  final apport = notes.reduce((a, b) => a + b) / notes.length;
  final reelle = apport - pente * kKcalParKilo;
  final correction = ((reelle - depenseFormule) * 0.5).clamp(-400, 400);
  return Ajustement(
    etat: EtatAjustement.actif,
    kcal: (correction / 10).round() * 10,
    joursNotes: notes.length,
    pesees: pesees.length,
    depenseReelle: reelle,
    rythmeReel: pente * 7,
  );
}

// ═══ Les besoins ════════════════════════════════════════════════════════════

class Besoins {
  const Besoins({
    required this.metabolisme,
    required this.activite,
    required this.sport,
    required this.objectif,
    required this.ajustement,
    required this.kcal,
    required this.proteines,
    required this.glucides,
    required this.lipides,
    required this.verres,
    required this.poids,
    required this.estimation,
    required this.manuel,
    required this.jourDeSeance,
  });

  /// Métabolisme de base, part de l'activité quotidienne, séances (moyenne),
  /// objectif (±) — en kcal / jour.
  final double metabolisme, activite, sport, objectif;
  final Ajustement ajustement;

  /// Les objectifs du jour.
  final int kcal, proteines, glucides, lipides;
  final int verres;

  /// Le poids utilisé (kg) ; `null` : aucun poids connu (70 par défaut).
  final double? poids;

  /// Profil incomplet : une estimation.
  final bool estimation;

  /// Fixés à la main.
  final bool manuel;
  final bool jourDeSeance;

  /// La dépense de la formule, sans l'objectif ni l'ajustement.
  double get depenseFormule => metabolisme + activite + sport;

  int objectifDe(Macro m) => switch (m) {
    Macro.proteines => proteines,
    Macro.glucides => glucides,
    Macro.lipides => lipides,
  };
}

/// Protéines visées par kilo, selon l'objectif.
double proteinesParKilo(ObjectifPoids o) => switch (o) {
  ObjectifPoids.perdre => 2.0,
  ObjectifPoids.maintenir => 1.6,
  ObjectifPoids.prendre => 1.8,
};

/// Les verres d'eau visés.
int verresVises(ProfilNutrition p, double poids, int minutesSport) =>
    p.verresEau ??
    ((poids * 35 * 0.8 / 250).round().clamp(6, 16) + minutesSport ~/ 30);

Besoins besoinsDu({
  required ProfilNutrition profil,
  required double? poids,
  required List<SeanceFaite> seances,
  required List<Programme> programmes,
  required List<EntreeJournal> journal,
  required List<MesureCorps> mesures,
  required DateTime jour,
  required DateTime aujourdhui,
}) {
  final kg = poids ?? 70;
  final bmr = metabolismeBase(
    sexe: profil.sexe,
    poids: kg,
    taille: tailleDe(profil),
    age: ageDe(profil, jour),
  );
  final activite = bmr * (profil.activite.facteur - 1);
  final sport = profil.compterSeances ? sportMoyen(seances, jour) : 0.0;
  final objectif = switch (profil.objectif) {
    ObjectifPoids.perdre => -profil.rythme * kKcalParKilo / 7,
    ObjectifPoids.maintenir => 0.0,
    ObjectifPoids.prendre => profil.rythme * kKcalParKilo / 7,
  };
  final ajustement = ajustementAdaptatif(
    journal: journal,
    mesures: mesures,
    jour: jour,
    depenseFormule: bmr + activite + sport,
    actif: profil.ajustementAuto,
  );
  final seance = estJourDeSeance(seances, programmes, jour, aujourdhui);
  final verres = verresVises(profil, kg, minutesSportDu(seances, jour));
  final m = profil.manuels;
  if (m != null) {
    return Besoins(
      metabolisme: bmr,
      activite: activite,
      sport: sport,
      objectif: objectif,
      ajustement: ajustement,
      kcal: m.kcal,
      proteines: m.proteines,
      glucides: m.glucides,
      lipides: m.lipides,
      verres: verres,
      poids: poids,
      estimation: false,
      manuel: true,
      jourDeSeance: seance,
    );
  }
  final plancher = math.max(bmr * 1.1, profil.sexe == Sexe.femme ? 1200 : 1500);
  final brut = bmr + activite + sport + objectif + ajustement.kcal;
  final kcal = (math.max(brut, plancher) / 10).round() * 10;
  final proteines = (kg * proteinesParKilo(profil.objectif)).round();
  final lipides = math.max(kcal * (seance ? 0.25 : 0.30) / 9, kg * 0.8).round();
  final glucides = math
      .max((kcal - proteines * 4 - lipides * 9) / 4, 50)
      .round();
  return Besoins(
    metabolisme: bmr,
    activite: activite,
    sport: sport,
    objectif: objectif,
    ajustement: ajustement,
    kcal: kcal,
    proteines: proteines,
    glucides: glucides,
    lipides: lipides,
    verres: verres,
    poids: poids,
    estimation: !profil.complet || poids == null,
    manuel: false,
    jourDeSeance: seance,
  );
}

// ═══ Le journal ═════════════════════════════════════════════════════════════

Nutriments totalDe(Iterable<EntreeJournal> entrees) =>
    Nutriments.somme(entrees.map((e) => e.nutriments));

double valeurDe(Nutriments n, Macro m) => switch (m) {
  Macro.proteines => n.proteines,
  Macro.glucides => n.glucides,
  Macro.lipides => n.lipides,
};

/// Le moment qui convient à l'heure : déjeuner avant 10 h 30, dîner avant
/// 14 h 30, collation avant 17 h, souper avant 21 h, collation ensuite.
MomentRepas momentPourHeure(DateTime maintenant) {
  final m = maintenant.hour * 60 + maintenant.minute;
  if (m < 10 * 60 + 30) return MomentRepas.dejeuner;
  if (m < 14 * 60 + 30) return MomentRepas.diner;
  if (m < 17 * 60) return MomentRepas.collation;
  if (m < 21 * 60) return MomentRepas.souper;
  return MomentRepas.collation;
}

/// Des noms en une phrase : « Gruau, banane, beurre d'arachide » — la
/// majuscule reste au premier (sauf [premiere] faux), un sigle (« BBQ »)
/// garde la sienne, pas de doublon.
String enPhrase(Iterable<String> noms, {bool premiere = true}) {
  final uniques = <String>[];
  for (final n in noms) {
    if (!uniques.contains(n)) uniques.add(n);
  }
  bool sigle(String n) => n.length > 1 && n[1] != n[1].toLowerCase();
  return [
    for (final (i, n) in uniques.indexed)
      (i == 0 && premiere) || n.isEmpty || sigle(n)
          ? n
          : n[0].toLowerCase() + n.substring(1),
  ].join(', ');
}

/// « Gruau, banane, beurre d'arachide » : les noms d'un repas en une
/// phrase.
String contenuDe(List<EntreeJournal> entrees) =>
    enPhrase(entrees.map((e) => e.nom));

/// Les aliments déjà mangés, du plus récent au plus ancien, un par
/// aliment (leur DERNIÈRE quantité).
List<EntreeJournal> recents(List<EntreeJournal> journal, {int max = 12}) {
  final vus = <String>{};
  final liste = <EntreeJournal>[];
  for (final e in journal.reversed) {
    if (vus.add(e.cleSource)) liste.add(e);
    if (liste.length >= max) break;
  }
  return liste;
}

/// Combien de fois chaque aliment de la base a été mangé (la recherche les
/// fait passer devant).
Map<int, int> frequentsBase(List<EntreeJournal> journal) {
  final f = <int, int>{};
  for (final e in journal) {
    if (e.source == SourceEntree.base && e.code != null) {
      f[e.code!] = (f[e.code!] ?? 0) + 1;
    }
  }
  return f;
}

// ═══ Le conseil du jour ═════════════════════════════════════════════════════

enum GenreConseil {
  /// Le profil est incomplet : des objectifs estimés.
  profil,

  /// Le soir : sortir du congélateur ce que demandent les repas prévus
  /// demain.
  decongeler,

  /// Des aliments du garde-manger à consommer d'ici demain.
  peremption,

  /// Le matin, rien de noté.
  dejeuner,

  /// Une séance faite, peu de protéines.
  apresSeance,

  /// Le soir, beaucoup de protéines restantes.
  proteinesSoir,

  /// L'eau en retard sur l'heure.
  eau,

  /// Prendre du poids : trop peu mangé en soirée.
  prendreSoir,

  /// Nettement au-dessus : sans reproche.
  depasse,

  /// Objectifs atteints.
  atteint,

  /// Un repère général (guide alimentaire), selon le moment.
  general,
}

class Conseil {
  const Conseil(
    this.genre, {
    this.n = 0,
    this.m = 0,
    this.variante = 0,
    this.noms = '',
  });

  final GenreConseil genre;

  /// Un nombre à dire (grammes restants, verres bus…) et un second.
  final int n, m;

  /// Des noms à dire (« Yogourt grec, épinards »).
  final String noms;

  /// Une variante stable dans la journée.
  final int variante;
}

Conseil conseilDuJour({
  required Besoins besoins,
  required Nutriments total,
  required int entrees,
  required int verres,
  required bool seanceFaite,
  required bool profilComplet,
  required ObjectifPoids objectif,
  required DateTime maintenant,
  List<String> aConsommer = const [],
  List<String> aDecongeler = const [],
}) {
  final h = maintenant.hour + maintenant.minute / 60;
  final variante = cleJour(maintenant) % 7;
  final resteP = besoins.proteines - total.proteines;
  final resteKcal = besoins.kcal - total.kcal;
  if (!profilComplet && !besoins.manuel) {
    return const Conseil(GenreConseil.profil);
  }
  // Le soir, ce qui doit décongeler pour demain (le frigo y met la nuit).
  if (aDecongeler.isNotEmpty && h >= 16) {
    return Conseil(
      GenreConseil.decongeler,
      n: aDecongeler.length,
      noms: enPhrase(aDecongeler.take(2), premiere: false),
    );
  }
  // Le gaspillage d'abord : ce qui ne passera pas demain, à cuisiner.
  if (aConsommer.isNotEmpty && h < 20) {
    return Conseil(
      GenreConseil.peremption,
      n: aConsommer.length,
      // En minuscules après les deux-points (un sigle garde sa majuscule).
      noms: enPhrase(aConsommer.take(2), premiere: false),
    );
  }
  if (total.kcal > besoins.kcal * 1.15) {
    return Conseil(GenreConseil.depasse, variante: variante);
  }
  if (total.kcal >= besoins.kcal * 0.9 &&
      total.proteines >= besoins.proteines * 0.9) {
    return Conseil(GenreConseil.atteint, variante: variante);
  }
  if (h >= 5 && h < 10.5 && entrees == 0) {
    return Conseil(GenreConseil.dejeuner, variante: variante);
  }
  if (seanceFaite && total.proteines < besoins.proteines * 0.6) {
    return Conseil(GenreConseil.apresSeance, n: resteP.round());
  }
  // L'eau : de 8 h à 21 h, on devrait en être à la part écoulée du jour.
  final attendu = (besoins.verres * ((h - 8) / 13).clamp(0, 1)).floor();
  if (h >= 10 && verres + 2 <= attendu) {
    return Conseil(GenreConseil.eau, n: verres, m: besoins.verres);
  }
  if (objectif == ObjectifPoids.prendre &&
      h >= 19 &&
      resteKcal > besoins.kcal * 0.3) {
    return Conseil(GenreConseil.prendreSoir, n: resteKcal.round());
  }
  if (h >= 17 && resteP >= 30) {
    return Conseil(GenreConseil.proteinesSoir, n: resteP.round());
  }
  return Conseil(GenreConseil.general, variante: variante);
}

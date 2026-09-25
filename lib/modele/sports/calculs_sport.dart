// lib/modele/sports/calculs_sport.dart
//
// Les RÈGLES D'ENTRAÎNEMENT de Rhythm — classiques, sans IA, en fonctions
// pures (testées) :
//
// - DOSAGE selon l'objectif : force 4 à 6 répétitions, repos long ;
//   volume 8 à 12, 60 à 90 s ; endurance 15 à 20, repos court ;
// - ORDRE : les exercices polyarticulaires et les plus lourds d'abord, les
//   gros muscles avant les petits, le gainage à la fin ; en option, deux
//   exercices OPPOSÉS enchaînés sans repos (pectoraux / dos, biceps /
//   triceps…) ;
// - ÉCHAUFFEMENT adapté aux articulations sollicitées, RETOUR AU CALME qui
//   étire les muscles travaillés ;
// - « COMPLÉTER » : des exercices équilibrés pour les zones choisies, avec
//   le matériel qu'on a, en évitant les muscles en récupération ;
// - PROGRESSION automatique (une répétition de plus, puis un peu plus de
//   charge — la double progression) ; RECORDS (charge, répétitions, force
//   maximale estimée par Epley) ;
// - RÉCUPÉRATION : un muscle travaillé lourdement il y a moins de 48 h ;
// - la SEMAINE, la série de semaines, les STATISTIQUES sur 30 jours, les
//   CALORIES (MET × poids × durée).

import 'dart:math' as math;

import '../../utils/dates.dart';
import 'catalogue.dart';
import 'exercices.dart';
import 'muscles.dart';
import 'sport.dart';

// ═══ Dosage ═════════════════════════════════════════════════════════════════

/// La ligne d'un exercice dosé pour [objectif].
LigneSeance doser(
  ExerciceSport e,
  Objectif objectif, {
  RoleLigne role = RoleLigne.travail,
}) {
  if (role != RoleLigne.travail) {
    return LigneSeance(
      exercice: e.id,
      series: 1,
      secondes: e.parCote ? 60 : 40,
      repos: 10,
      role: role,
    );
  }
  final isolation = !e.poly;
  final series = switch (objectif) {
    Objectif.force => isolation ? 3 : 4,
    Objectif.volume => isolation ? 3 : 4,
    Objectif.endurance => isolation ? 2 : 3,
  };
  if (e.enDuree) {
    final secondes = switch (e.style) {
      StyleSport.gainage || StyleSport.musculation => switch (objectif) {
        Objectif.force => 30,
        Objectif.volume => 40,
        Objectif.endurance => 60,
      },
      StyleSport.cardio => switch (objectif) {
        Objectif.force => 60,
        Objectif.volume => 90,
        Objectif.endurance => 120,
      },
      _ => switch (objectif) {
        Objectif.force => 20,
        Objectif.volume => 30,
        Objectif.endurance => 45,
      },
    };
    return LigneSeance(
      exercice: e.id,
      series: 3,
      secondes: secondes,
      repos: (objectif.repos * 0.5).round().clamp(20, 90),
    );
  }
  final reps = e.style == StyleSport.hiit
      ? 12
      : ((objectif.repsMin + objectif.repsMax) / 2).floor();
  return LigneSeance(
    exercice: e.id,
    series: series,
    reps: reps,
    repos: isolation ? (objectif.repos * 0.8).round() : objectif.repos,
  );
}

// ═══ L'ordre ════════════════════════════════════════════════════════════════

/// Le rang d'un exercice dans la séance (plus petit = plus tôt).
int rangDans(ExerciceSport e) {
  if (e.deTronc) return 3000 - e.intensite * 10;
  var r = 0;
  if (e.style == StyleSport.hiit || e.style == StyleSport.cardio) r += 2000;
  if (!e.poly) r += 1000;
  if (!e.principaux.any((m) => m.gros)) r += 100;
  if (e.charge) r -= 5;
  r -= e.intensite * 10;
  return r;
}

/// Les lignes de travail rangées selon l'effort (tri stable) ; si
/// [enchainer], deux exercices opposés voisins forment une paire sans repos
/// entre eux (le repos vient après la paire).
List<LigneSeance> organiser(
  List<LigneSeance> travail, {
  bool enchainer = false,
}) {
  final indexees = [for (var i = 0; i < travail.length; i++) (i, travail[i])];
  int rang(LigneSeance l) {
    final e = Catalogue.de(l.exercice);
    return e == null ? 5000 : rangDans(e);
  }

  indexees.sort((a, b) {
    final c = rang(a.$2).compareTo(rang(b.$2));
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  final rangees = [
    for (final x in indexees) x.$2.copierAvec(groupe: () => null),
  ];
  if (!enchainer) return rangees;
  return enchainerOpposes(rangees);
}

/// Forme des paires d'exercices opposés (A1 / A2), la seconde placée juste
/// après la première.
List<LigneSeance> enchainerOpposes(List<LigneSeance> lignes) {
  final restantes = [...lignes];
  final resultat = <LigneSeance>[];
  var groupe = 1;
  while (restantes.isNotEmpty) {
    final a = restantes.removeAt(0);
    final ea = Catalogue.de(a.exercice);
    final oppose = ea == null || ea.deTronc ? null : ea.principaux.first.oppose;
    int? j;
    if (oppose != null) {
      for (var k = 0; k < restantes.length && k < 4; k++) {
        final eb = Catalogue.de(restantes[k].exercice);
        if (eb != null && !eb.deTronc && eb.principaux.first == oppose) {
          j = k;
          break;
        }
      }
    }
    if (j == null) {
      resultat.add(a);
      continue;
    }
    final b = restantes.removeAt(j);
    final repos = math.max(a.repos, b.repos);
    resultat
      ..add(a.copierAvec(groupe: () => groupe, repos: 15))
      ..add(b.copierAvec(groupe: () => groupe, repos: repos));
    groupe++;
  }
  return resultat;
}

// ═══ Échauffement et retour au calme ════════════════════════════════════════

/// L'exercice qui prépare chaque articulation.
const Map<Articulation, String> _mobilisation = {
  Articulation.epaules: 'cercles_bras',
  Articulation.coudes: 'cercles_bras',
  Articulation.poignets: 'cercles_bras',
  Articulation.colonne: 'chat_vache',
  Articulation.hanches: 'rotation_hanches',
  Articulation.genoux: 'squat',
  Articulation.chevilles: 'mollets_debout',
};

/// L'échauffement d'une séance : trois minutes pour lancer le cœur, puis
/// une mobilisation de chaque articulation sollicitée (≈ 5 minutes).
List<LigneSeance> echauffement(Iterable<String> travail) {
  final articulations = <Articulation>{};
  var basDuCorps = false;
  for (final id in travail) {
    final e = Catalogue.de(id);
    if (e == null) continue;
    for (final m in e.principaux) {
      articulations.addAll(m.articulations);
      if (!m.haut && !m.tronc) basDuCorps = true;
    }
  }
  final ids = <String>{
    basDuCorps ? 'montees_genoux' : 'jumping_jack',
    for (final a in Articulation.values)
      if (articulations.contains(a)) _mobilisation[a]!,
    if (basDuCorps) 'balancier_jambe',
  };
  return [
    for (final (i, id) in ids.take(5).indexed)
      LigneSeance(
        exercice: id,
        series: 1,
        secondes: i == 0 ? 90 : (Catalogue.de(id)!.parCote ? 60 : 40),
        repos: 10,
        role: RoleLigne.echauffement,
      ),
  ];
}

/// L'étirement de chaque muscle.
const Map<Muscle, String> _etirement = {
  Muscle.pectoraux: 'etirement_pectoraux',
  Muscle.dos: 'posture_enfant',
  Muscle.trapezes: 'etirement_epaule',
  Muscle.epaules: 'etirement_epaule',
  Muscle.biceps: 'etirement_biceps',
  Muscle.triceps: 'etirement_triceps',
  Muscle.avantBras: 'etirement_biceps',
  Muscle.abdos: 'cobra',
  Muscle.obliques: 'torsion_couchee',
  Muscle.lombaires: 'genoux_poitrine',
  Muscle.fessiers: 'etirement_fessier',
  Muscle.quadriceps: 'etirement_quadriceps',
  Muscle.ischios: 'assis_flexion',
  Muscle.adducteurs: 'papillon',
  Muscle.mollets: 'etirement_mollet',
};

/// Le retour au calme : les muscles les plus travaillés, étirés (cinq au
/// plus).
List<LigneSeance> retourAuCalme(List<LigneSeance> travail) {
  final series = seriesParMuscle(travail);
  final muscles = series.keys.toList()
    ..sort((a, b) => series[b]!.compareTo(series[a]!));
  final ids = <String>{for (final m in muscles) ?_etirement[m]};
  return [
    for (final id in ids.take(5))
      doser(Catalogue.de(id)!, Objectif.volume, role: RoleLigne.retourCalme),
  ];
}

// ═══ Construire une séance ══════════════════════════════════════════════════

/// Une séance complète autour des exercices [ids] : échauffement, travail
/// dosé et rangé (charges reprises de la dernière fois), retour au calme.
List<LigneSeance> construireSeance(
  List<String> ids, {
  required Objectif objectif,
  bool enchainer = false,
  List<SeanceFaite> journal = const [],
}) {
  final travail = <LigneSeance>[];
  for (final id in ids) {
    final e = Catalogue.de(id);
    if (e == null) continue;
    final l = doser(e, objectif);
    final avant = derniereFois(id, journal);
    final charge = avant == null ? null : chargeDeTravail(avant);
    travail.add(l.copierAvec(charge: () => charge));
  }
  final ranges = organiser(travail, enchainer: enchainer);
  return [
    ...echauffement(ranges.map((l) => l.exercice)),
    ...ranges,
    ...retourAuCalme(ranges),
  ];
}

/// Des exercices ÉQUILIBRÉS pour les [zones] (tout le corps si vide),
/// faisables avec [materiel], à la portée de [niveau], qui évitent les
/// muscles [enRecuperation] — en plus de ceux [deja] choisis, jusqu'à
/// [cible] en tout.
List<String> completer({
  required Set<Muscle> zones,
  required List<String> deja,
  required Set<Materiel> materiel,
  required Niveau niveau,
  Set<Muscle> enRecuperation = const {},
  int cible = 6,
}) {
  final visees = zones.isEmpty
      ? {
          Muscle.pectoraux,
          Muscle.dos,
          Muscle.quadriceps,
          Muscle.ischios,
          Muscle.epaules,
          Muscle.abdos,
        }
      : zones;
  final choisis = [...deja];
  final mouvements = {for (final id in deja) ?Catalogue.de(id)?.mouvement};
  bool couvre(Muscle m) =>
      choisis.any((id) => Catalogue.de(id)?.principaux.contains(m) ?? false);

  final candidats = [
    for (final e in Catalogue.tous)
      if (e.style != StyleSport.mobilite &&
          e.style != StyleSport.cardio &&
          e.faisableAvec(materiel) &&
          e.niveau.index <= niveau.index &&
          !e.principaux.any(enRecuperation.contains))
        e,
  ];

  int score(ExerciceSport e, Muscle zone) {
    var s = 0;
    if (e.principaux.first == zone) s += 20;
    if (e.principaux.contains(zone)) s += 10;
    if (e.poly) s += 6;
    // Le matériel déclaré sert : on le préfère au poids du corps.
    if (e.charge) s += 3;
    if (e.niveau == niveau) s += 2;
    if (e.style == StyleSport.hiit) s -= 4;
    if (zone.tronc && e.style == StyleSport.gainage) s += 8;
    s += e.principaux.where(visees.contains).length;
    return s;
  }

  ExerciceSport? meilleur(Muscle zone, {bool isolationPermise = true}) {
    ExerciceSport? top;
    var topScore = -1 << 20;
    for (final e in candidats) {
      if (choisis.contains(e.id) || mouvements.contains(e.mouvement)) continue;
      if (!e.principaux.contains(zone)) continue;
      if (!isolationPermise && !e.poly && zone.gros) continue;
      final s = score(e, zone);
      if (s > topScore) {
        topScore = s;
        top = e;
      }
    }
    return top;
  }

  void prendre(ExerciceSport e) {
    choisis.add(e.id);
    mouvements.add(e.mouvement);
  }

  // Un exercice par zone non couverte, les gros muscles d'abord.
  final ordre = visees.toList()
    ..sort((a, b) => (b.gros ? 1 : 0).compareTo(a.gros ? 1 : 0));
  for (final m in ordre) {
    if (choisis.length >= cible) break;
    if (couvre(m)) continue;
    final e = meilleur(m, isolationPermise: !m.gros);
    if (e != null) prendre(e);
  }
  // Puis un second pour les gros muscles visés, tant qu'il reste de la
  // place.
  for (final m in ordre) {
    if (choisis.length >= cible) break;
    final e = meilleur(m);
    if (e != null) prendre(e);
  }
  return choisis;
}

/// Les exercices proposés pour des [zones] (tout le corps si vide) : ceux
/// qui les travaillent en principal, faisables avec [materiel], à la portée
/// de [niveau], hors muscles [enRecuperation] et hors [exclus] — les
/// polyarticulaires et les chargés d'abord.
List<ExerciceSport> suggestions({
  required Set<Muscle> zones,
  required Set<Materiel> materiel,
  required Niveau niveau,
  Set<Muscle> enRecuperation = const {},
  Iterable<String> exclus = const [],
  int n = 10,
}) {
  final pris = exclus.toSet();
  final r = [
    for (final e in Catalogue.tous)
      if (!pris.contains(e.id) &&
          e.style != StyleSport.mobilite &&
          e.style != StyleSport.cardio &&
          e.faisableAvec(materiel) &&
          e.niveau.index <= niveau.index &&
          !e.principaux.any(enRecuperation.contains) &&
          (zones.isEmpty || e.principaux.any(zones.contains)))
        e,
  ];
  int score(ExerciceSport e) =>
      (e.poly ? 6 : 0) +
      (e.charge ? 3 : 0) +
      (e.niveau == niveau ? 2 : 0) +
      (zones.contains(e.principaux.first) ? 4 : 0) -
      (e.style == StyleSport.hiit ? 4 : 0);
  r.sort((a, b) => score(b).compareTo(score(a)));
  return r.take(n).toList();
}

// ═══ Aperçu ═════════════════════════════════════════════════════════════════

/// Le temps d'effort d'une série (secondes) : une série en durée compte
/// déjà ses deux côtés ; en répétitions, un exercice « de chaque côté » se
/// fait deux fois.
double _effortSerie(LigneSeance l, ExerciceSport? e) {
  final s = l.secondes;
  if (s != null) return s.toDouble();
  final base = (l.reps ?? 10) * 3.5;
  return (e?.parCote ?? false) ? base * 2 : base;
}

/// La durée estimée d'une séance : efforts, repos, installation.
Duration dureeEstimee(List<LigneSeance> lignes) {
  var s = 0.0;
  for (final l in lignes) {
    final e = Catalogue.de(l.exercice);
    s += l.series * (_effortSerie(l, e) + l.repos);
    s += l.role == RoleLigne.travail ? 30 : 5;
  }
  return Duration(seconds: s.round());
}

/// Les séries par muscle (principal : 1, secondaire : ½), travail seulement.
Map<Muscle, double> seriesParMuscle(List<LigneSeance> lignes) {
  final r = <Muscle, double>{};
  for (final l in lignes) {
    if (l.role != RoleLigne.travail) continue;
    final e = Catalogue.de(l.exercice);
    if (e == null) continue;
    for (final m in e.principaux) {
      r[m] = (r[m] ?? 0) + l.series;
    }
    for (final m in e.secondaires) {
      r[m] = (r[m] ?? 0) + l.series / 2;
    }
  }
  return r;
}

// ═══ La dernière fois, la progression ═══════════════════════════════════════

/// Ce qu'on a fait de [exercice] la dernière fois (séries de travail).
ExerciceFait? derniereFois(String exercice, List<SeanceFaite> journal) {
  for (final s in journal.reversed) {
    for (final e in s.exercices) {
      if (e.exercice == exercice &&
          e.role == RoleLigne.travail &&
          e.series.isNotEmpty) {
        return e;
      }
    }
  }
  return null;
}

/// La charge de travail d'une fois : la plus fréquente, sinon la plus
/// lourde.
double? chargeDeTravail(ExerciceFait f) {
  final charges = [
    for (final s in f.series)
      if (s.charge != null && s.charge! > 0) s.charge!,
  ];
  if (charges.isEmpty) return null;
  final compte = <double, int>{};
  for (final c in charges) {
    compte[c] = (compte[c] ?? 0) + 1;
  }
  return compte.entries
      .reduce(
        (a, b) =>
            b.value > a.value || (b.value == a.value && b.key > a.key) ? b : a,
      )
      .key;
}

/// Pourquoi la proposition change.
enum Progres { premiereFois, pareil, repDePlus, plusDeCharge, plusLong }

class Proposition {
  const Proposition({
    this.reps,
    this.secondes,
    this.charge,
    required this.progres,
  });

  final int? reps;
  final int? secondes;
  final double? charge;
  final Progres progres;
}

/// Le pas de charge d'un exercice (kilos).
double pasDeCharge(ExerciceSport e) {
  if (e.materiel.contains(Materiel.barre)) return 2.5;
  if (e.materiel.contains(Materiel.kettlebell)) return 4;
  return 2;
}

/// La PROGRESSION AUTOMATIQUE (double progression) : si tout a été réussi
/// la dernière fois, une répétition de plus ; en haut de la plage de
/// l'objectif, un peu plus de charge et retour en bas de la plage. Un
/// exercice en durée gagne 5 secondes. Un échec : on refait pareil.
Proposition proposer(
  LigneSeance ligne,
  ExerciceSport e,
  List<SeanceFaite> journal,
  Objectif objectif,
) {
  final avant = derniereFois(e.id, journal);
  if (avant == null) {
    return Proposition(
      reps: ligne.reps,
      secondes: ligne.secondes,
      charge: ligne.charge,
      progres: Progres.premiereFois,
    );
  }
  final echec = avant.series.any((s) => s.ressenti == Ressenti.echec);
  if (ligne.enDuree) {
    final vise = ligne.secondes ?? 30;
    final tenu = avant.series.every((s) => (s.secondes ?? 0) >= vise);
    final base = math.max(
      vise,
      avant.series.map((s) => s.secondes ?? 0).fold(0, math.max),
    );
    return tenu && !echec
        ? Proposition(secondes: base + 5, progres: Progres.plusLong)
        : Proposition(secondes: vise, progres: Progres.pareil);
  }
  final cible = avant.cibleReps ?? ligne.reps ?? objectif.repsMin;
  final charge = chargeDeTravail(avant) ?? ligne.charge;
  final reussi = !echec && avant.series.every((s) => (s.reps ?? 0) >= cible);
  if (!reussi) {
    return Proposition(reps: cible, charge: charge, progres: Progres.pareil);
  }
  if (e.charge && charge != null && cible >= objectif.repsMax) {
    return Proposition(
      reps: objectif.repsMin,
      charge: charge + pasDeCharge(e),
      progres: Progres.plusDeCharge,
    );
  }
  return Proposition(
    reps: cible + 1,
    charge: charge,
    progres: Progres.repDePlus,
  );
}

// ═══ Records ════════════════════════════════════════════════════════════════

enum TypeRecord { charge, reps, force, duree }

class Records {
  const Records({this.charge, this.reps, this.force, this.duree});

  /// Charge maximale (kg).
  final double? charge;

  /// Répétitions maximales en une série.
  final int? reps;

  /// Force maximale estimée (1 répétition, Epley), kg.
  final double? force;

  /// Durée maximale en une série (secondes).
  final int? duree;

  bool get vide => charge == null && reps == null && duree == null;

  double? valeur(TypeRecord t) => switch (t) {
    TypeRecord.charge => charge,
    TypeRecord.reps => reps?.toDouble(),
    TypeRecord.force => force,
    TypeRecord.duree => duree?.toDouble(),
  };
}

/// La force maximale estimée d'une série (Epley) — de 1 à 12 répétitions.
double? unRm(SerieFaite s) {
  final c = s.charge, r = s.reps;
  if (c == null || c <= 0 || r == null || r < 1 || r > 12) return null;
  return r == 1 ? c : c * (1 + r / 30);
}

class _Suivi {
  double? charge, force;
  int? reps, duree;

  void ajouter(SerieFaite s) {
    final c = s.charge;
    if (c != null && c > 0 && (s.reps ?? 0) > 0) {
      charge = math.max(charge ?? 0, c);
    }
    if (s.reps != null && s.reps! > 0) reps = math.max(reps ?? 0, s.reps!);
    final f = unRm(s);
    if (f != null) force = math.max(force ?? 0, f);
    if (s.secondes != null && s.secondes! > 0) {
      duree = math.max(duree ?? 0, s.secondes!);
    }
  }

  Records get records =>
      Records(charge: charge, reps: reps, force: force, duree: duree);
}

/// Les records de [exercice] sur [journal].
Records recordsDe(String exercice, Iterable<SeanceFaite> journal) {
  final suivi = _Suivi();
  for (final s in journal) {
    for (final e in s.exercices) {
      if (e.exercice != exercice || e.role != RoleLigne.travail) continue;
      e.series.forEach(suivi.ajouter);
    }
  }
  return suivi.records;
}

class RecordBattu {
  const RecordBattu({
    required this.exercice,
    required this.type,
    required this.valeur,
    required this.ancien,
    this.quand,
  });

  final String exercice;
  final TypeRecord type;
  final double valeur;
  final double ancien;
  final DateTime? quand;
}

/// Les records que [seance] bat par rapport à [avant] (il en faut un
/// ancien : la première fois n'est pas un record).
List<RecordBattu> recordsBattus(SeanceFaite seance, List<SeanceFaite> avant) {
  final r = <RecordBattu>[];
  final vus = <String>{};
  for (final e in seance.exercices) {
    if (e.role != RoleLigne.travail || !vus.add(e.exercice)) continue;
    final ancien = recordsDe(e.exercice, avant);
    if (ancien.vide) continue;
    final suivi = _Suivi();
    for (final x in seance.exercices) {
      if (x.exercice == e.exercice && x.role == RoleLigne.travail) {
        x.series.forEach(suivi.ajouter);
      }
    }
    final nouveau = suivi.records;
    for (final t in const [
      TypeRecord.charge,
      TypeRecord.force,
      TypeRecord.reps,
      TypeRecord.duree,
    ]) {
      final a = ancien.valeur(t), n = nouveau.valeur(t);
      if (a == null || n == null || n <= a + 1e-9) continue;
      // La force estimée ne compte que si la charge n'est pas déjà record.
      if (t == TypeRecord.force &&
          r.any(
            (x) => x.exercice == e.exercice && x.type == TypeRecord.charge,
          )) {
        continue;
      }
      r.add(
        RecordBattu(
          exercice: e.exercice,
          type: t,
          valeur: n,
          ancien: a,
          quand: seance.debut,
        ),
      );
    }
  }
  return r;
}

// ═══ Calories ═══════════════════════════════════════════════════════════════

/// Les calories d'un effort : MET × poids (kg) × heures.
int calories(double met, double poids, int secondes) =>
    (met * poids * secondes / 3600).round();

/// Le MET moyen d'une séance guidée : chaque ligne pèse son temps estimé.
double metSeance(List<LigneSeance> lignes) {
  var poids = 0.0, somme = 0.0;
  for (final l in lignes) {
    final e = Catalogue.de(l.exercice);
    if (e == null) continue;
    final t = l.series * (_effortSerie(l, e) + l.repos);
    poids += t;
    somme += t * e.depense;
  }
  return poids == 0 ? StyleSport.musculation.met : somme / poids;
}

/// Le MET d'une sortie selon sa vitesse (compendium d'Ainsworth).
double metCardio(String activite, double? kmh) {
  final e = Catalogue.de(activite);
  final defaut = e?.depense ?? StyleSport.cardio.met;
  if (kmh == null || kmh <= 0) return defaut;
  return switch (activite) {
    'course' ||
    'footing' ||
    'sprints' ||
    'course_sur_place' => math.max(6, kmh * 1.0),
    'marche' || 'marche_rapide' || 'marche_cote' || 'randonnee' =>
      kmh < 4
          ? 3
          : kmh < 5.5
          ? 3.8
          : 5,
    'velo' || 'velo_interieur' =>
      kmh < 16
          ? 4
          : kmh < 19
          ? 6.8
          : kmh < 22
          ? 8
          : 10,
    _ => defaut,
  };
}

/// Le style dominant d'une séance (celui qui pèse le plus de séries).
StyleSport styleDominant(List<ExerciceFait> exercices) {
  final poids = <StyleSport, int>{};
  for (final f in exercices) {
    if (f.role != RoleLigne.travail) continue;
    final e = Catalogue.de(f.exercice);
    if (e == null) continue;
    final s = e.style == StyleSport.poidsDuCorps
        ? StyleSport.poidsDuCorps
        : e.style;
    poids[s] = (poids[s] ?? 0) + math.max(1, f.series.length);
  }
  if (poids.isEmpty) return StyleSport.mobilite;
  return poids.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

// ═══ Récupération ═══════════════════════════════════════════════════════════

/// Les muscles en RÉCUPÉRATION à [maintenant] : travaillés lourdement (au
/// moins trois séries de musculation ou de poids du corps où ils sont
/// principaux) dans une séance finie il y a moins de 48 h — et jusqu'à
/// quand.
Map<Muscle, DateTime> enRecuperation(
  List<SeanceFaite> journal,
  DateTime maintenant,
) {
  final r = <Muscle, DateTime>{};
  for (final s in journal.reversed) {
    final fin = s.fin;
    if (fin.isBefore(maintenant.subtract(const Duration(hours: 48)))) break;
    if (fin.isAfter(maintenant.add(const Duration(minutes: 1)))) continue;
    final series = <Muscle, int>{};
    for (final f in s.exercices) {
      if (f.role != RoleLigne.travail) continue;
      final e = Catalogue.de(f.exercice);
      if (e == null) continue;
      if (e.style != StyleSport.musculation &&
          e.style != StyleSport.poidsDuCorps) {
        continue;
      }
      for (final m in e.principaux) {
        series[m] = (series[m] ?? 0) + f.series.length;
      }
    }
    final jusqua = fin.add(const Duration(hours: 48));
    for (final e in series.entries) {
      if (e.value < 3) continue;
      final avant = r[e.key];
      if (avant == null || jusqua.isAfter(avant)) r[e.key] = jusqua;
    }
  }
  return r;
}

// ═══ La semaine ═════════════════════════════════════════════════════════════

/// Minutes par jour de la semaine de [aujourdhui] (lundi → dimanche ;
/// `null` : jour à venir), séances et calories.
({List<int?> minutes, int seances, int kcal, int index}) semaineDe(
  List<SeanceFaite> journal,
  DateTime aujourdhui,
) {
  final lundi = lundiDe(aujourdhui);
  final index = joursEntre(lundi, aujourdhui);
  final minutes = <int?>[for (var i = 0; i < 7; i++) i > index ? null : 0];
  var seances = 0, kcal = 0;
  for (final s in journal) {
    final j = joursEntre(lundi, s.debut);
    if (j < 0 || j > index) continue;
    minutes[j] = (minutes[j] ?? 0) + s.minutes;
    seances++;
    kcal += s.kcal;
  }
  return (minutes: minutes, seances: seances, kcal: kcal, index: index);
}

/// Les semaines d'affilée avec au moins une séance, en remontant depuis
/// celle de [aujourdhui] (une semaine en cours sans séance ne casse rien).
int serieSemaines(List<SeanceFaite> journal, DateTime aujourdhui) {
  final lundi = lundiDe(aujourdhui);
  final semaines = <int>{
    for (final s in journal)
      if (!s.debut.isAfter(plusJours(lundi, 7)))
        joursEntre(lundiDe(s.debut), lundi) ~/ 7,
  };
  var n = 0;
  var k = semaines.contains(0) ? 0 : 1;
  while (semaines.contains(k)) {
    n++;
    k++;
  }
  return n;
}

// ═══ Programmes : séance du jour, prochaine séance ═════════════════════════

/// A-t-on déjà fait [p] le jour [jour] ?
bool faitLe(Programme p, List<SeanceFaite> journal, DateTime jour) => journal
    .any((s) => s.programmeId == p.id && jourDe(s.debut) == jourDe(jour));

/// La séance du jour : un programme prévu aujourd'hui (le plus tôt d'abord ;
/// ceux déjà faits après).
Programme? seanceDuJour(
  List<Programme> programmes,
  List<SeanceFaite> journal,
  DateTime aujourdhui,
) {
  final prevus =
      [
        for (final p in programmes)
          if (p.prevuLe(aujourdhui)) p,
      ]..sort((a, b) {
        final fa = faitLe(a, journal, aujourdhui) ? 1 : 0;
        final fb = faitLe(b, journal, aujourdhui) ? 1 : 0;
        if (fa != fb) return fa.compareTo(fb);
        return (a.heure ?? 1440).compareTo(b.heure ?? 1440);
      });
  return prevus.isEmpty ? null : prevus.first;
}

/// La prochaine séance prévue à partir de [maintenant] (sept jours au
/// plus) et son moment ; celle d'aujourd'hui compte tant qu'elle n'est pas
/// faite.
(Programme, DateTime)? prochaineSeance(
  List<Programme> programmes,
  List<SeanceFaite> journal,
  DateTime maintenant,
) {
  (Programme, DateTime)? meilleure;
  for (var d = 0; d <= 7; d++) {
    final jour = plusJours(jourDe(maintenant), d);
    for (final p in programmes) {
      if (!p.prevuLe(jour)) continue;
      if (d == 0 && faitLe(p, journal, jour)) continue;
      final h = p.heure ?? 18 * 60;
      final quand = DateTime(jour.year, jour.month, jour.day, h ~/ 60, h % 60);
      if (d > 0 && quand.isBefore(maintenant)) continue;
      if (meilleure == null || quand.isBefore(meilleure.$2)) {
        meilleure = (p, quand);
      }
    }
    if (meilleure != null) return meilleure;
  }
  return null;
}

// ═══ Statistiques sur 30 jours ══════════════════════════════════════════════

class Stats30 {
  const Stats30({
    required this.minutes,
    required this.seances,
    required this.parStyle,
    required this.kcal,
    required this.minutesAvant,
    required this.seancesAvant,
    required this.kcalAvant,
    required this.seriesMuscles,
    required this.dernierTravail,
    required this.records,
    required this.debut,
  });

  /// Minutes et séances par jour, du plus ancien à aujourd'hui (30).
  final List<int> minutes;
  final List<int> seances;
  final Map<StyleSport, int> parStyle;
  final int kcal;

  /// Les 30 jours d'avant.
  final int minutesAvant, seancesAvant, kcalAvant;

  /// Séries de travail par muscle (principal : 1, secondaire : ½).
  final Map<Muscle, double> seriesMuscles;

  /// Le dernier jour où chaque muscle a été travaillé (tout le journal).
  final Map<Muscle, DateTime> dernierTravail;

  /// Les records battus sur la période, du plus récent au plus ancien.
  final List<RecordBattu> records;

  /// Le premier des 30 jours.
  final DateTime debut;

  int get totalMinutes => minutes.fold(0, (s, x) => s + x);
  int get totalSeances => seances.fold(0, (s, x) => s + x);
  int get joursActifs => seances.where((x) => x > 0).length;
}

/// Les muscles suivis par les statistiques (les « négligés »).
const List<Muscle> musclesSuivis = [
  Muscle.pectoraux,
  Muscle.dos,
  Muscle.epaules,
  Muscle.biceps,
  Muscle.triceps,
  Muscle.abdos,
  Muscle.fessiers,
  Muscle.quadriceps,
  Muscle.ischios,
  Muscle.mollets,
];

Stats30 stats30(List<SeanceFaite> journal, DateTime aujourdhui) {
  final auj = jourDe(aujourdhui);
  final debut = plusJours(auj, -29);
  final debutAvant = plusJours(debut, -30);
  final minutes = List.filled(30, 0);
  final seances = List.filled(30, 0);
  final parStyle = <StyleSport, int>{};
  final muscles = <Muscle, double>{};
  final dernier = <Muscle, DateTime>{};
  final records = <RecordBattu>[];
  var kcal = 0, minutesAvant = 0, seancesAvant = 0, kcalAvant = 0;

  final suivis = <String, _Suivi>{};
  for (final s in journal) {
    final j = joursEntre(debut, s.debut);
    final dans = j >= 0 && j < 30;
    if (dans) {
      // Les records : comparés à tout ce qui précède.
      final vus = <String>{};
      for (final f in s.exercices) {
        if (f.role != RoleLigne.travail || !vus.add(f.exercice)) continue;
        final avant = suivis[f.exercice]?.records;
        if (avant == null || avant.vide) continue;
        final t = _Suivi();
        for (final x in s.exercices) {
          if (x.exercice == f.exercice && x.role == RoleLigne.travail) {
            x.series.forEach(t.ajouter);
          }
        }
        final n = t.records;
        for (final type in const [
          TypeRecord.charge,
          TypeRecord.reps,
          TypeRecord.duree,
        ]) {
          final a = avant.valeur(type), v = n.valeur(type);
          if (a != null && v != null && v > a + 1e-9) {
            records.add(
              RecordBattu(
                exercice: f.exercice,
                type: type,
                valeur: v,
                ancien: a,
                quand: s.debut,
              ),
            );
          }
        }
      }
      minutes[j] += s.minutes;
      seances[j]++;
      parStyle[s.style] = (parStyle[s.style] ?? 0) + s.minutes;
      kcal += s.kcal;
    } else if (!s.debut.isBefore(debutAvant) && s.debut.isBefore(debut)) {
      minutesAvant += s.minutes;
      seancesAvant++;
      kcalAvant += s.kcal;
    }
    for (final f in s.exercices) {
      final e = Catalogue.de(f.exercice);
      if (e == null) continue;
      if (f.role == RoleLigne.travail) {
        final t = suivis.putIfAbsent(f.exercice, _Suivi.new);
        f.series.forEach(t.ajouter);
      }
      if (f.role != RoleLigne.travail || e.style == StyleSport.mobilite) {
        continue;
      }
      for (final m in e.principaux) {
        dernier[m] = s.debut;
        if (dans) muscles[m] = (muscles[m] ?? 0) + f.series.length;
      }
      for (final m in e.secondaires) {
        dernier[m] = s.debut;
        if (dans) muscles[m] = (muscles[m] ?? 0) + f.series.length / 2;
      }
    }
    // Une sortie de cardio fait travailler les jambes.
    final a = s.activite == null ? null : Catalogue.de(s.activite!);
    if (a != null) {
      for (final m in a.principaux) {
        dernier[m] = s.debut;
        if (dans) muscles[m] = (muscles[m] ?? 0) + 2;
      }
    }
  }
  return Stats30(
    minutes: minutes,
    seances: seances,
    parStyle: parStyle,
    kcal: kcal,
    minutesAvant: minutesAvant,
    seancesAvant: seancesAvant,
    kcalAvant: kcalAvant,
    seriesMuscles: muscles,
    dernierTravail: dernier,
    records: records.reversed.toList(),
    debut: debut,
  );
}

/// Les muscles négligés : rien depuis au moins [seuil] jours (ou jamais),
/// le plus ancien d'abord — (muscle, jours ; `null` = jamais).
List<(Muscle, int?)> musclesNegliges(
  Stats30 stats,
  DateTime aujourdhui, {
  int seuil = 7,
}) {
  final r = <(Muscle, int?)>[];
  for (final m in musclesSuivis) {
    final d = stats.dernierTravail[m];
    final jours = d == null ? null : joursEntre(d, aujourdhui);
    if (jours == null || jours >= seuil) r.add((m, jours));
  }
  r.sort((a, b) => (b.$2 ?? 9999).compareTo(a.$2 ?? 9999));
  return r;
}

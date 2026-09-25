// lib/modele/sports/sport.dart
//
// Les SPORTS vivants : ce que l'utilisateur déclare (son profil : matériel,
// objectif, niveau), ce qu'il prépare (ses SÉANCES enregistrées — les
// « programmes », prévues certains jours à une heure), ce qu'il fait (le
// JOURNAL : chaque séance faite, série par série, ou chaque sortie de
// course, marche, vélo), ses MESURES (poids, tour de taille), ses DÉFIS et
// ses programmes de course en cours.
//
// Tout se lit avec tolérance (`depuisJson`) : un champ absent ou abîmé prend
// sa valeur par défaut, une ligne illisible est ignorée — jamais d'échec au
// démarrage (règle des habitudes).

import 'exercices.dart';

/// Version du document des sports.
const int kVersionSport = 1;

/// Un nombre, ou `null` s'il n'en est pas un (lecture tolérante).
num? _n(Object? v) => v is num ? v : null;

/// Un texte, ou `null`.
String? _t(Object? v) => v is String ? v : null;

// ═══ Le profil ══════════════════════════════════════════════════════════════

/// L'objectif d'entraînement : il fixe le DOSAGE (répétitions et repos).
enum Objectif {
  force(4, 6, 150),
  volume(8, 12, 75),
  endurance(15, 20, 40);

  const Objectif(this.repsMin, this.repsMax, this.repos);

  /// La plage de répétitions visée.
  final int repsMin, repsMax;

  /// Le repos entre deux séries, en secondes.
  final int repos;
}

class ProfilSportif {
  const ProfilSportif({
    this.materiel = const {Materiel.halteres},
    this.objectif = Objectif.volume,
    this.niveau = Niveau.intermediaire,
    this.poids,
    this.objectifSemaine = 240,
    this.objectifJour = 60,
    this.enchainements = false,
    this.lienHabitude = true,
    this.materielDeclare = false,
  });

  /// Le matériel qu'on a sous la main (déclaré une fois).
  final Set<Materiel> materiel;
  final Objectif objectif;
  final Niveau niveau;

  /// Le poids du corps (kg) : pour les calories. `null` : 70 par défaut,
  /// ou la dernière mesure.
  final double? poids;

  /// Minutes visées par semaine, par jour.
  final int objectifSemaine, objectifJour;

  /// Enchaîner deux exercices opposés sans repos (gain de temps).
  final bool enchainements;

  /// Enregistrer une séance coche l'habitude « Entraînement ».
  final bool lienHabitude;

  /// Le matériel a été déclaré (sinon, la banque le demande une fois).
  final bool materielDeclare;

  ProfilSportif copierAvec({
    Set<Materiel>? materiel,
    Objectif? objectif,
    Niveau? niveau,
    double? Function()? poids,
    int? objectifSemaine,
    int? objectifJour,
    bool? enchainements,
    bool? lienHabitude,
    bool? materielDeclare,
  }) => ProfilSportif(
    materiel: materiel ?? this.materiel,
    objectif: objectif ?? this.objectif,
    niveau: niveau ?? this.niveau,
    poids: poids == null ? this.poids : poids(),
    objectifSemaine: objectifSemaine ?? this.objectifSemaine,
    objectifJour: objectifJour ?? this.objectifJour,
    enchainements: enchainements ?? this.enchainements,
    lienHabitude: lienHabitude ?? this.lienHabitude,
    materielDeclare: materielDeclare ?? this.materielDeclare,
  );

  Map<String, dynamic> versJson() => {
    'materiel': [for (final m in materiel) m.name],
    'objectif': objectif.name,
    'niveau': niveau.name,
    'poids': ?poids,
    'objectifSemaine': objectifSemaine,
    'objectifJour': objectifJour,
    'enchainements': enchainements,
    'lienHabitude': lienHabitude,
    'materielDeclare': materielDeclare,
  };

  static ProfilSportif depuisJson(Object? j) {
    if (j is! Map) return const ProfilSportif();
    const defaut = ProfilSportif();
    return ProfilSportif(
      materiel: j['materiel'] is List
          ? {
              for (final m in j['materiel'] as List)
                ?Materiel.values.asNameMap()[m],
            }
          : defaut.materiel,
      objectif: Objectif.values.asNameMap()[j['objectif']] ?? defaut.objectif,
      niveau: Niveau.values.asNameMap()[j['niveau']] ?? defaut.niveau,
      poids: _n(j['poids'])?.toDouble(),
      objectifSemaine:
          _n(j['objectifSemaine'])?.toInt() ?? defaut.objectifSemaine,
      objectifJour: _n(j['objectifJour'])?.toInt() ?? defaut.objectifJour,
      enchainements: j['enchainements'] == true,
      lienHabitude: j['lienHabitude'] != false,
      materielDeclare: j['materielDeclare'] == true,
    );
  }
}

// ═══ Une séance préparée ════════════════════════════════════════════════════

/// Le rôle d'une ligne dans la séance.
enum RoleLigne { echauffement, travail, retourCalme }

/// Une ligne d'une séance : un exercice et son dosage.
class LigneSeance {
  const LigneSeance({
    required this.exercice,
    this.series = 3,
    this.reps,
    this.secondes,
    this.charge,
    this.repos = 75,
    this.role = RoleLigne.travail,
    this.groupe,
  });

  /// L'identifiant de l'exercice (`Catalogue`).
  final String exercice;
  final int series;

  /// Répétitions visées (exercice en répétitions)…
  final int? reps;

  /// …ou durée d'une série (exercice en durée), en secondes.
  final int? secondes;

  /// La charge, en kilos (`null` : poids du corps, ou pas encore connue).
  final double? charge;

  /// Le repos après chaque série (après la PAIRE dans un enchaînement).
  final int repos;
  final RoleLigne role;

  /// Deux lignes du même groupe s'enchaînent sans repos (A1 / A2).
  final int? groupe;

  bool get enDuree => secondes != null;

  LigneSeance copierAvec({
    int? series,
    int? Function()? reps,
    int? Function()? secondes,
    double? Function()? charge,
    int? repos,
    RoleLigne? role,
    int? Function()? groupe,
  }) => LigneSeance(
    exercice: exercice,
    series: series ?? this.series,
    reps: reps == null ? this.reps : reps(),
    secondes: secondes == null ? this.secondes : secondes(),
    charge: charge == null ? this.charge : charge(),
    repos: repos ?? this.repos,
    role: role ?? this.role,
    groupe: groupe == null ? this.groupe : groupe(),
  );

  Map<String, dynamic> versJson() => {
    'exercice': exercice,
    'series': series,
    'reps': ?reps,
    'secondes': ?secondes,
    'charge': ?charge,
    'repos': repos,
    if (role != RoleLigne.travail) 'role': role.name,
    'groupe': ?groupe,
  };

  static LigneSeance? depuisJson(Object? j) {
    if (j is! Map) return null;
    final exercice = j['exercice'];
    if (exercice is! String || exercice.isEmpty) return null;
    return LigneSeance(
      exercice: exercice,
      series: (_n(j['series'])?.toInt() ?? 3).clamp(1, 20),
      reps: _n(j['reps'])?.toInt(),
      secondes: _n(j['secondes'])?.toInt(),
      charge: _n(j['charge'])?.toDouble(),
      repos: _n(j['repos'])?.toInt() ?? 75,
      role: RoleLigne.values.asNameMap()[j['role']] ?? RoleLigne.travail,
      groupe: _n(j['groupe'])?.toInt(),
    );
  }
}

/// Une séance ENREGISTRÉE (un « programme ») : ses lignes, et les jours où
/// elle est prévue — elle devient alors la « Séance du jour », avec un
/// rappel à son heure si on le veut.
class Programme {
  const Programme({
    required this.id,
    required this.nom,
    required this.lignes,
    this.objectif = Objectif.volume,
    this.jours = const {},
    this.heure,
    this.rappel = false,
    required this.creeLe,
  });

  final String id;
  final String nom;
  final List<LigneSeance> lignes;
  final Objectif objectif;

  /// Jours prévus (1 = lundi … 7 = dimanche) ; vide : à la demande.
  final Set<int> jours;

  /// L'heure prévue, en minutes depuis minuit.
  final int? heure;
  final bool rappel;
  final DateTime creeLe;

  List<LigneSeance> get travail => [
    for (final l in lignes)
      if (l.role == RoleLigne.travail) l,
  ];

  bool prevuLe(DateTime jour) => jours.contains(jour.weekday);

  Programme copierAvec({
    String? nom,
    List<LigneSeance>? lignes,
    Objectif? objectif,
    Set<int>? jours,
    int? Function()? heure,
    bool? rappel,
  }) => Programme(
    id: id,
    nom: nom ?? this.nom,
    lignes: lignes ?? this.lignes,
    objectif: objectif ?? this.objectif,
    jours: jours ?? this.jours,
    heure: heure == null ? this.heure : heure(),
    rappel: rappel ?? this.rappel,
    creeLe: creeLe,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'lignes': [for (final l in lignes) l.versJson()],
    'objectif': objectif.name,
    if (jours.isNotEmpty) 'jours': (jours.toList()..sort()),
    'heure': ?heure,
    if (rappel) 'rappel': true,
    'creeLe': creeLe.toIso8601String(),
  };

  static Programme? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    return Programme(
      id: id,
      nom: _t(j['nom']) ?? '',
      lignes: [
        if (j['lignes'] is List)
          for (final l in j['lignes'] as List) ?LigneSeance.depuisJson(l),
      ],
      objectif: Objectif.values.asNameMap()[j['objectif']] ?? Objectif.volume,
      jours: {
        if (j['jours'] is List)
          for (final e in j['jours'] as List)
            if (e is num && e >= 1 && e <= 7) e.toInt(),
      },
      heure: _n(j['heure'])?.toInt(),
      rappel: j['rappel'] == true,
      creeLe: DateTime.tryParse('${j['creeLe']}') ?? DateTime(2026, 9, 24),
    );
  }
}

// ═══ Le journal ═════════════════════════════════════════════════════════════

/// Le ressenti d'une série (facultatif).
enum Ressenti { facile, correct, difficile, echec }

class SerieFaite {
  const SerieFaite({this.reps, this.secondes, this.charge, this.ressenti});

  final int? reps;
  final int? secondes;
  final double? charge;
  final Ressenti? ressenti;

  /// Le volume soulevé (répétitions × charge).
  double get volume => (reps ?? 0) * (charge ?? 0);

  Map<String, dynamic> versJson() => {
    'reps': ?reps,
    'secondes': ?secondes,
    'charge': ?charge,
    if (ressenti != null) 'ressenti': ressenti!.name,
  };

  static SerieFaite? depuisJson(Object? j) {
    if (j is! Map) return null;
    return SerieFaite(
      reps: _n(j['reps'])?.toInt(),
      secondes: _n(j['secondes'])?.toInt(),
      charge: _n(j['charge'])?.toDouble(),
      ressenti: Ressenti.values.asNameMap()[j['ressenti']],
    );
  }
}

class ExerciceFait {
  const ExerciceFait({
    required this.exercice,
    required this.series,
    this.role = RoleLigne.travail,
    this.cibleReps,
  });

  final String exercice;
  final List<SerieFaite> series;
  final RoleLigne role;

  /// Les répétitions visées ce jour-là (la progression compare).
  final int? cibleReps;

  double get volume => series.fold(0.0, (s, x) => s + x.volume);

  Map<String, dynamic> versJson() => {
    'exercice': exercice,
    'series': [for (final s in series) s.versJson()],
    if (role != RoleLigne.travail) 'role': role.name,
    'cibleReps': ?cibleReps,
  };

  static ExerciceFait? depuisJson(Object? j) {
    if (j is! Map) return null;
    final exercice = j['exercice'];
    if (exercice is! String || exercice.isEmpty) return null;
    return ExerciceFait(
      exercice: exercice,
      series: [
        if (j['series'] is List)
          for (final s in j['series'] as List) ?SerieFaite.depuisJson(s),
      ],
      role: RoleLigne.values.asNameMap()[j['role']] ?? RoleLigne.travail,
      cibleReps: _n(j['cibleReps'])?.toInt(),
    );
  }
}

/// Une séance FAITE : guidée (exercices série par série), express, défi,
/// ou une sortie de cardio (course, marche, vélo : durée, distance).
class SeanceFaite {
  const SeanceFaite({
    required this.id,
    required this.nom,
    required this.debut,
    required this.dureeSec,
    required this.style,
    this.exercices = const [],
    this.kcal = 0,
    this.ressenti,
    this.note = '',
    this.programmeId,
    this.activite,
    this.distanceKm,
    this.defi,
    this.programmeCardio,
    this.etape,
  });

  final String id;
  final String nom;
  final DateTime debut;
  final int dureeSec;

  /// Le style dominant (la répartition des statistiques).
  final StyleSport style;
  final List<ExerciceFait> exercices;
  final int kcal;

  /// Le ressenti global, de 1 (facile) à 5 (épuisant).
  final int? ressenti;
  final String note;

  /// La séance enregistrée d'où elle vient.
  final String? programmeId;

  /// Une sortie de cardio : l'exercice de la banque (« course », « marche »,
  /// « velo »…) et la distance parcourue.
  final String? activite;
  final double? distanceKm;

  /// Le défi, ou le programme de course, et l'étape qu'elle a validée.
  final String? defi;
  final String? programmeCardio;
  final int? etape;

  int get minutes => (dureeSec / 60).round();

  DateTime get fin => debut.add(Duration(seconds: dureeSec));

  double get volume => exercices.fold(0.0, (s, e) => s + e.volume);

  int get nombreSeries => exercices
      .where((e) => e.role == RoleLigne.travail)
      .fold(0, (s, e) => s + e.series.length);

  /// L'allure (min/km), pour une sortie à pied.
  Duration? get allure {
    final d = distanceKm;
    if (d == null || d <= 0.05) return null;
    return Duration(seconds: (dureeSec / d).round());
  }

  /// La vitesse moyenne (km/h).
  double? get vitesse {
    final d = distanceKm;
    if (d == null || dureeSec <= 0) return null;
    return d / (dureeSec / 3600);
  }

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'debut': debut.toIso8601String(),
    'dureeSec': dureeSec,
    'style': style.name,
    if (exercices.isNotEmpty)
      'exercices': [for (final e in exercices) e.versJson()],
    'kcal': kcal,
    'ressenti': ?ressenti,
    if (note.isNotEmpty) 'note': note,
    'programmeId': ?programmeId,
    'activite': ?activite,
    'distanceKm': ?distanceKm,
    'defi': ?defi,
    'programmeCardio': ?programmeCardio,
    'etape': ?etape,
  };

  static SeanceFaite? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final debut = DateTime.tryParse('${j['debut']}');
    if (id is! String || id.isEmpty || debut == null) return null;
    return SeanceFaite(
      id: id,
      nom: _t(j['nom']) ?? '',
      debut: debut,
      dureeSec: (_n(j['dureeSec'])?.toInt() ?? 0).clamp(0, 86400),
      style:
          StyleSport.values.asNameMap()[j['style']] ?? StyleSport.musculation,
      exercices: [
        if (j['exercices'] is List)
          for (final e in j['exercices'] as List) ?ExerciceFait.depuisJson(e),
      ],
      kcal: _n(j['kcal'])?.toInt() ?? 0,
      ressenti: _n(j['ressenti'])?.toInt(),
      note: _t(j['note']) ?? '',
      programmeId: _t(j['programmeId']),
      activite: _t(j['activite']),
      distanceKm: _n(j['distanceKm'])?.toDouble(),
      defi: _t(j['defi']),
      programmeCardio: _t(j['programmeCardio']),
      etape: _n(j['etape'])?.toInt(),
    );
  }
}

// ═══ Mesures, défis, programmes de course ═══════════════════════════════════

/// Une mesure du corps (facultative).
class MesureCorps {
  const MesureCorps({
    required this.id,
    required this.date,
    this.poids,
    this.tourTaille,
  });

  final String id;
  final DateTime date;

  /// Kilos.
  final double? poids;

  /// Centimètres.
  final double? tourTaille;

  Map<String, dynamic> versJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'poids': ?poids,
    'tourTaille': ?tourTaille,
  };

  static MesureCorps? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final date = DateTime.tryParse('${j['date']}');
    if (id is! String || date == null) return null;
    return MesureCorps(
      id: id,
      date: date,
      poids: _n(j['poids'])?.toDouble(),
      tourTaille: _n(j['tourTaille'])?.toDouble(),
    );
  }
}

/// Un défi de 4 semaines suivi, ou un programme de course : son début et
/// les étapes validées.
class Suivi {
  const Suivi({required this.id, required this.debut, this.faites = const {}});

  /// L'identifiant du défi ou du programme (`defis.dart`).
  final String id;
  final DateTime debut;
  final Set<int> faites;

  Suivi copierAvec({Set<int>? faites}) =>
      Suivi(id: id, debut: debut, faites: faites ?? this.faites);

  Map<String, dynamic> versJson() => {
    'id': id,
    'debut': debut.toIso8601String(),
    if (faites.isNotEmpty) 'faites': (faites.toList()..sort()),
  };

  static Suivi? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final debut = DateTime.tryParse('${j['debut']}');
    if (id is! String || debut == null) return null;
    return Suivi(
      id: id,
      debut: debut,
      faites: {
        if (j['faites'] is List)
          for (final e in j['faites'] as List)
            if (e is num) e.toInt(),
      },
    );
  }
}

// ═══ L'état ═════════════════════════════════════════════════════════════════

class EtatSport {
  const EtatSport({
    this.profil = const ProfilSportif(),
    this.programmes = const [],
    this.journal = const [],
    this.mesures = const [],
    this.defis = const [],
    this.courses = const [],
  });

  final ProfilSportif profil;
  final List<Programme> programmes;

  /// Les séances faites, de la plus ancienne à la plus récente.
  final List<SeanceFaite> journal;

  /// Les mesures, de la plus ancienne à la plus récente.
  final List<MesureCorps> mesures;

  /// Les défis suivis (un à la fois par défi).
  final List<Suivi> defis;

  /// Les programmes de course suivis.
  final List<Suivi> courses;

  Programme? programme(String id) {
    for (final p in programmes) {
      if (p.id == id) return p;
    }
    return null;
  }

  Suivi? defi(String id) {
    for (final d in defis) {
      if (d.id == id) return d;
    }
    return null;
  }

  Suivi? course(String id) {
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Le poids du corps pour les calories : la dernière mesure, sinon le
  /// profil, sinon 70 kg.
  double get poidsCorps {
    for (final m in mesures.reversed) {
      if (m.poids != null) return m.poids!;
    }
    return profil.poids ?? 70;
  }

  EtatSport copierAvec({
    ProfilSportif? profil,
    List<Programme>? programmes,
    List<SeanceFaite>? journal,
    List<MesureCorps>? mesures,
    List<Suivi>? defis,
    List<Suivi>? courses,
  }) => EtatSport(
    profil: profil ?? this.profil,
    programmes: programmes ?? this.programmes,
    journal: journal ?? this.journal,
    mesures: mesures ?? this.mesures,
    defis: defis ?? this.defis,
    courses: courses ?? this.courses,
  );

  /// Le document du dépôt : trois tables (`programmesSport`,
  /// `journalSport`, `mesuresSport`) et des réglages.
  Map<String, dynamic> versDocument() => {
    'versionSport': kVersionSport,
    'programmesSport': [for (final p in programmes) p.versJson()],
    'journalSport': [for (final s in journal) s.versJson()],
    'mesuresSport': [for (final m in mesures) m.versJson()],
    'profilSport': profil.versJson(),
    'defisSport': [for (final d in defis) d.versJson()],
    'coursesSport': [for (final c in courses) c.versJson()],
  };

  static EtatSport depuisDocument(Map<String, dynamic> document) {
    List<T> liste<T>(String cle, T? Function(Object?) lire) => [
      if (document[cle] is List)
        for (final j in document[cle] as List) ?lire(j),
    ];
    return EtatSport(
      profil: ProfilSportif.depuisJson(document['profilSport']),
      programmes: liste('programmesSport', Programme.depuisJson)
        ..sort((a, b) => a.creeLe.compareTo(b.creeLe)),
      journal: liste('journalSport', SeanceFaite.depuisJson)
        ..sort((a, b) => a.debut.compareTo(b.debut)),
      mesures: liste('mesuresSport', MesureCorps.depuisJson)
        ..sort((a, b) => a.date.compareTo(b.date)),
      defis: liste('defisSport', Suivi.depuisJson),
      courses: liste('coursesSport', Suivi.depuisJson),
    );
  }
}

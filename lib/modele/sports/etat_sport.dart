// lib/modele/sports/etat_sport.dart
//
// L'état des SPORTS (Riverpod) et sa PERSISTANCE : chaque changement est
// écrit dans le dépôt SQLite (`depot.dart`) — trois tables
// (`programmesSport`, `journalSport`, `mesuresSport`) et des réglages
// (profil, défis, programmes de course suivis).
//
// Premier lancement : la base n'a pas de sports, on y pose UNE fois le
// profil (le matériel de l'utilisateur : des haltères) et la séance de la
// maquette, « Haut du corps », refaite avec des haltères, prévue lundi et
// jeudi à 18 h (sans rappel, sans historique). Sans dépôt (tests,
// captures), c'est la DÉMONSTRATION : deux mois de séances qui retombent sur
// la maquette (cette semaine : 45, 0, 60 et 42 minutes — 147 min, 3 séances,
// 1 180 kcal —, 5 semaines d'affilée).
//
// Enregistrer une séance coche l'habitude « Entraînement » (si le profil le
// veut) et valide l'étape du défi ou du programme de course qu'elle suit.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/dates.dart';
import '../calculs_habitudes.dart';
import '../depot.dart';
import '../etat_habitudes.dart';
import '../etat_sante.dart';
import 'calculs_sport.dart';
import 'catalogue.dart';
import 'exercices.dart';
import 'sport.dart';

final sportProvider = NotifierProvider<SportNotifier, EtatSport>(
  SportNotifier.new,
);

/// Ce que l'enregistrement d'une séance vient de faire.
class ResultatSeance {
  const ResultatSeance({
    required this.records,
    this.habitudeCochee,
    this.etapeValidee = false,
  });

  final List<RecordBattu> records;

  /// Le nom de l'habitude cochée du même coup.
  final String? habitudeCochee;

  /// Une étape de défi ou de programme de course validée.
  final bool etapeValidee;
}

class SportNotifier extends Notifier<EtatSport> {
  Depot? _depot;
  int _compteur = 0;

  @override
  EtatSport build() {
    final auj = ref.read(aujourdhuiProvider);
    final depot = ref.watch(depotProvider);
    _depot = depot;
    if (depot == null) return GraineSport.demonstration(auj);
    try {
      final document = depot.lire();
      if (document != null && document.containsKey('versionSport')) {
        return EtatSport.depuisDocument(document);
      }
    } catch (_) {
      return GraineSport.premierLancement(auj);
    }
    final graine = GraineSport.premierLancement(auj);
    try {
      depot.ecrire(graine.versDocument());
    } catch (_) {}
    return graine;
  }

  /// Un identifiant neuf (« sea-1727…-3 »).
  String nouvelId(String prefixe) =>
      '$prefixe-${DateTime.now().microsecondsSinceEpoch}-${++_compteur}';

  void _muter(EtatSport nouvel) {
    state = nouvel;
    try {
      _depot?.ecrire(nouvel.versDocument());
    } catch (_) {}
  }

  // ── Le profil ─────────────────────────────────────────────────────────────

  void modifierProfil(ProfilSportif p) => _muter(state.copierAvec(profil: p));

  // ── Les séances enregistrées ──────────────────────────────────────────────

  /// Ajoute [p], ou la remplace si elle existe déjà.
  void enregistrerProgramme(Programme p) {
    final existe = state.programmes.any((x) => x.id == p.id);
    _muter(
      state.copierAvec(
        programmes: existe
            ? [for (final x in state.programmes) x.id == p.id ? p : x]
            : [...state.programmes, p],
      ),
    );
  }

  void supprimerProgramme(String id) => _muter(
    state.copierAvec(
      programmes: [
        for (final p in state.programmes)
          if (p.id != id) p,
      ],
    ),
  );

  // ── Le journal ────────────────────────────────────────────────────────────

  /// Enregistre une séance faite : records battus, étape de défi ou de
  /// course validée, habitude « Entraînement » cochée.
  ResultatSeance enregistrerSeance(SeanceFaite s) {
    final avant = state.journal;
    final records = recordsBattus(s, avant);
    var etat = state.copierAvec(
      journal: [...avant, s]..sort((a, b) => a.debut.compareTo(b.debut)),
    );
    var etape = false;
    final e = s.etape;
    if (e != null && s.defi != null) {
      final d = etat.defi(s.defi!);
      if (d != null) {
        etape = true;
        etat = etat.copierAvec(
          defis: [
            for (final x in etat.defis)
              x.id == d.id ? x.copierAvec(faites: {...x.faites, e}) : x,
          ],
        );
      }
    }
    if (e != null && s.programmeCardio != null) {
      final c = etat.course(s.programmeCardio!);
      if (c != null) {
        etape = true;
        etat = etat.copierAvec(
          courses: [
            for (final x in etat.courses)
              x.id == c.id ? x.copierAvec(faites: {...x.faites, e}) : x,
          ],
        );
      }
    }
    _muter(etat);
    return ResultatSeance(
      records: records,
      habitudeCochee: state.profil.lienHabitude ? _cocherHabitude(s) : null,
      etapeValidee: etape,
    );
  }

  /// L'habitude « Entraînement » du jour de [s], cochée si elle ne l'est
  /// pas encore ; son nom, ou `null`.
  String? _cocherHabitude(SeanceFaite s) {
    try {
      final habitudes = ref.read(habitudesProvider);
      String simple(String t) => t
          .toLowerCase()
          .replaceAll(RegExp('[îï]'), 'i')
          .replaceAll(RegExp('[éèê]'), 'e');
      final h =
          habitudes.parId('hab-entrainement') ??
          habitudes.aConstruire
              .where(
                (h) =>
                    simple(h.nom).contains('entrain') ||
                    simple(h.nom).contains('sport'),
              )
              .firstOrNull;
      if (h == null || h.aLiberer) return null;
      final jour = jourDe(s.debut);
      if (estFaite(h, jour)) return null;
      ref.read(habitudesProvider.notifier).basculer(h.id, jour);
      return h.nom;
    } catch (_) {
      return null;
    }
  }

  void supprimerSeance(String id) => _muter(
    state.copierAvec(
      journal: [
        for (final s in state.journal)
          if (s.id != id) s,
      ],
    ),
  );

  // ── Mesures ───────────────────────────────────────────────────────────────

  void ajouterMesure(MesureCorps m) => _muter(
    state.copierAvec(
      mesures: [...state.mesures, m]..sort((a, b) => a.date.compareTo(b.date)),
    ),
  );

  void supprimerMesure(String id) => _muter(
    state.copierAvec(
      mesures: [
        for (final m in state.mesures)
          if (m.id != id) m,
      ],
    ),
  );

  // ── Défis et programmes de course ─────────────────────────────────────────

  void commencerDefi(String id, DateTime debut) => _muter(
    state.copierAvec(
      defis: [
        for (final d in state.defis)
          if (d.id != id) d,
        Suivi(id: id, debut: jourDe(debut)),
      ],
    ),
  );

  void abandonnerDefi(String id) => _muter(
    state.copierAvec(
      defis: [
        for (final d in state.defis)
          if (d.id != id) d,
      ],
    ),
  );

  void commencerCourse(String id, DateTime debut) => _muter(
    state.copierAvec(
      courses: [
        for (final c in state.courses)
          if (c.id != id) c,
        Suivi(id: id, debut: jourDe(debut)),
      ],
    ),
  );

  void abandonnerCourse(String id) => _muter(
    state.copierAvec(
      courses: [
        for (final c in state.courses)
          if (c.id != id) c,
      ],
    ),
  );
}

// ═══ La graine ══════════════════════════════════════════════════════════════

abstract final class GraineSport {
  /// Le premier lancement : le matériel de l'utilisateur (des haltères,
  /// à confirmer une fois) et « Haut du corps » aux haltères, lundi et
  /// jeudi à 18 h.
  static EtatSport premierLancement(DateTime aujourdhui) {
    const objectif = Objectif.volume;
    return EtatSport(
      profil: const ProfilSportif(),
      programmes: [
        Programme(
          id: 'prog-haut-du-corps',
          nom: 'Haut du corps',
          objectif: objectif,
          jours: const {1, 4},
          heure: 18 * 60,
          creeLe: jourDe(aujourdhui),
          lignes: construireSeance(const [
            'developpe_sol',
            'rowing_un_bras',
            'developpe_epaules',
            'rowing_penche',
            'curl',
            'extension_triceps',
          ], objectif: objectif),
        ),
      ],
    );
  }

  /// La séance de la maquette : développé couché 4 × 8 à 60 kg, tractions
  /// 4 × 6, développé militaire 3 × 10 à 30 kg, rowing haltère 3 × 12 à
  /// 22 kg.
  static List<LigneSeance> get _hautMaquette {
    const travail = [
      LigneSeance(
        exercice: 'developpe_couche_barre',
        series: 4,
        reps: 8,
        charge: 60,
        repos: 120,
      ),
      LigneSeance(exercice: 'traction', series: 4, reps: 6, repos: 120),
      LigneSeance(
        exercice: 'developpe_militaire',
        series: 3,
        reps: 10,
        charge: 30,
        repos: 90,
      ),
      LigneSeance(
        exercice: 'rowing_un_bras',
        series: 3,
        reps: 12,
        charge: 22,
        repos: 75,
      ),
    ];
    return [
      ...echauffement(travail.map((l) => l.exercice)),
      ...travail,
      ...retourAuCalme(travail),
    ];
  }

  /// La démonstration (tests, captures).
  static EtatSport demonstration(DateTime aujourdhui) {
    final auj = jourDe(aujourdhui);
    DateTime a(int jours, int h, [int m = 0]) {
      final j = plusJours(auj, -jours);
      return DateTime(j.year, j.month, j.day, h, m);
    }

    final journal = <SeanceFaite>[];
    var n = 0;
    String id() => 'demo-${++n}';

    SerieFaite r(int reps, [double? charge]) =>
        SerieFaite(reps: reps, charge: charge);

    // Le haut du corps : les charges montent doucement (records).
    SeanceFaite haut(int jours, int progres, int minutes, {int? kcal}) {
      final dc = (55 + progres * 2.5).clamp(55, 60).toDouble();
      final dm = (27.5 + progres * 1.25).clamp(27.5, 30).toDouble();
      final rw = (20 + progres).clamp(20, 22).toDouble();
      return SeanceFaite(
        id: id(),
        nom: 'Haut du corps',
        programmeId: 'prog-haut-du-corps',
        debut: a(jours, 18, 5),
        dureeSec: minutes * 60,
        style: StyleSport.musculation,
        kcal: kcal ?? minutes * 8,
        ressenti: 3,
        exercices: [
          ExerciceFait(
            exercice: 'developpe_couche_barre',
            cibleReps: 8,
            series: [r(8, dc), r(8, dc), r(8, dc), r(7, dc)],
          ),
          ExerciceFait(
            exercice: 'traction',
            cibleReps: 6,
            series: [r(6), r(6), r(5), r(5)],
          ),
          ExerciceFait(
            exercice: 'developpe_militaire',
            cibleReps: 10,
            series: [r(10, dm), r(10, dm), r(9, dm)],
          ),
          ExerciceFait(
            exercice: 'rowing_un_bras',
            cibleReps: 12,
            series: [r(12, rw), r(12, rw), r(12, rw)],
          ),
        ],
      );
    }

    SeanceFaite bas(int jours, int progres, int minutes, {int? kcal}) {
      final sq = (70 + progres * 2.5).clamp(70, 80).toDouble();
      final sr = (60 + progres * 2.5).clamp(60, 65).toDouble();
      return SeanceFaite(
        id: id(),
        nom: 'Bas du corps',
        debut: a(jours, 18, 10),
        dureeSec: minutes * 60,
        style: StyleSport.musculation,
        kcal: kcal ?? minutes * 8,
        ressenti: 4,
        exercices: [
          ExerciceFait(
            exercice: 'squat_barre',
            cibleReps: 8,
            series: [r(8, sq), r(8, sq), r(8, sq), r(8, sq)],
          ),
          ExerciceFait(
            exercice: 'souleve_roumain_barre',
            cibleReps: 10,
            series: [r(10, sr), r(10, sr), r(10, sr)],
          ),
          ExerciceFait(
            exercice: 'fente_halteres',
            cibleReps: 10,
            series: [r(10, 14), r(10, 14), r(10, 14)],
          ),
          const ExerciceFait(
            exercice: 'planche',
            series: [
              SerieFaite(secondes: 45),
              SerieFaite(secondes: 45),
              SerieFaite(secondes: 50),
            ],
          ),
        ],
      );
    }

    SeanceFaite course(
      int jours,
      int minutes,
      double km, {
      int h = 7,
      int? kcal,
    }) => SeanceFaite(
      id: id(),
      nom: 'Course',
      debut: a(jours, h, 10),
      dureeSec: minutes * 60,
      style: StyleSport.cardio,
      activite: 'course',
      distanceKm: km,
      kcal: kcal ?? minutes * 8,
      ressenti: 3,
    );

    SeanceFaite mobilite(int jours, int minutes) => SeanceFaite(
      id: id(),
      nom: 'Mobilité et gainage',
      debut: a(jours, 19, 30),
      dureeSec: minutes * 60,
      style: StyleSport.gainage,
      kcal: minutes * 8,
      ressenti: 2,
      exercices: const [
        ExerciceFait(
          exercice: 'planche',
          series: [SerieFaite(secondes: 60), SerieFaite(secondes: 60)],
        ),
        ExerciceFait(
          exercice: 'dead_bug',
          series: [SerieFaite(reps: 12), SerieFaite(reps: 12)],
        ),
        ExerciceFait(
          exercice: 'pigeon',
          role: RoleLigne.retourCalme,
          series: [SerieFaite(secondes: 60)],
        ),
      ],
    );

    // Deux mois, plus anciens d'abord. La cinquième semaine avant celle-ci
    // est vide (la série de semaines de la maquette : 5).
    final lundi = lundiDe(auj);
    final avantLundi = joursEntre(lundi, auj);
    int jd(int semaine, int jourSemaine) =>
        avantLundi + semaine * 7 - (jourSemaine - 1);
    var progres = 0;
    for (var sem = 8; sem >= 1; sem--) {
      if (sem == 5) continue;
      journal
        ..add(haut(jd(sem, 1), progres, 48))
        ..add(course(jd(sem, 3), 32, 5.1))
        ..add(bas(jd(sem, 4), progres, 58));
      if (sem.isEven) journal.add(mobilite(jd(sem, 6), 30));
      progres++;
    }
    // La semaine de la maquette (un jeudi) : dimanche dernier 35 min,
    // vendredi 50 ; lundi 45, mardi rien, mercredi 60, aujourd'hui 42.
    journal
      ..add(haut(jd(1, 5), progres, 50))
      ..add(mobilite(jd(1, 7), 35))
      ..add(haut(jd(0, 1), progres + 1, 45, kcal: 360))
      ..add(bas(jd(0, 3), progres + 1, 60, kcal: 480))
      ..add(course(0, 42, 6.8, h: 6, kcal: 340));
    journal.sort((x, y) => x.debut.compareTo(y.debut));

    return EtatSport(
      profil: const ProfilSportif(
        materiel: {
          Materiel.halteres,
          Materiel.barre,
          Materiel.banc,
          Materiel.barreTraction,
        },
        poids: 72,
        materielDeclare: true,
      ),
      programmes: [
        Programme(
          id: 'prog-haut-du-corps',
          nom: 'Haut du corps',
          jours: const {1, 4},
          heure: 18 * 60,
          creeLe: plusJours(auj, -60),
          lignes: _hautMaquette,
        ),
        Programme(
          id: 'prog-bas-du-corps',
          nom: 'Bas du corps',
          jours: const {3},
          heure: 18 * 60,
          creeLe: plusJours(auj, -60),
          lignes: construireSeance(const [
            'squat_barre',
            'souleve_roumain_barre',
            'fente_halteres',
            'planche',
          ], objectif: Objectif.volume),
        ),
      ],
      journal: journal,
      mesures: [
        for (var k = 8; k >= 0; k--)
          MesureCorps(
            id: 'mes-$k',
            date: a(k * 7, 7),
            poids: 74.6 - (8 - k) * 0.3,
            tourTaille: k % 2 == 0 ? 84 - (8 - k) * 0.25 : null,
          ),
      ],
      defis: [
        Suivi(
          id: 'pompes100',
          debut: plusJours(auj, -10),
          faites: const {0, 1, 2, 3},
        ),
      ],
    );
  }

  /// Vérifie qu'un identifiant d'exercice existe (les graines n'en
  /// inventent pas).
  static bool connu(String id) => Catalogue.de(id) != null;
}

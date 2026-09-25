// lib/modele/sports/plans.dart
//
// Ce qui se suit TEL QUEL, sans rien construire :
// - les INTERVALLES (fractionné) : échauffement, répétitions effort /
//   récupération, retour au calme — le minuteur les annonce ;
// - les PROGRAMMES DE COURSE progressifs (« Courir 30 minutes en
//   8 semaines », marche active, vélo), trois séances par semaine ;
// - les DÉFIS de 4 semaines (100 pompes, 150 squats, 3 minutes de
//   gainage, 5 km, 50 burpees), douze séances qui montent peu à peu ;
// - les ROUTINES EXPRESS de 5 minutes (réveil, bureau, avant de dormir).
//
// Le contenu est de la donnée, en français.

import 'dart:math' as math;

// ═══ Intervalles ════════════════════════════════════════════════════════════

enum Phase { echauffement, effort, recuperation, retourCalme }

class Intervalle {
  const Intervalle(this.phase, this.secondes);

  final Phase phase;
  final int secondes;
}

class PlanIntervalles {
  const PlanIntervalles({
    required this.nom,
    required this.etapes,
    this.activite = 'course',
  });

  /// [repetitions] fois effort / récupération, entre un échauffement et un
  /// retour au calme (en secondes ; 0 : sans).
  factory PlanIntervalles.repete({
    required String nom,
    required int repetitions,
    required int effort,
    required int recuperation,
    int echauffement = 300,
    int retourCalme = 300,
    String activite = 'course',
  }) => PlanIntervalles(
    nom: nom,
    activite: activite,
    etapes: [
      if (echauffement > 0) Intervalle(Phase.echauffement, echauffement),
      for (var i = 0; i < repetitions; i++) ...[
        Intervalle(Phase.effort, effort),
        if (recuperation > 0 && i < repetitions - 1)
          Intervalle(Phase.recuperation, recuperation),
      ],
      if (retourCalme > 0) Intervalle(Phase.retourCalme, retourCalme),
    ],
  );

  final String nom;
  final List<Intervalle> etapes;

  /// L'exercice de la banque (« course », « marche », « velo »…).
  final String activite;

  int get total => etapes.fold(0, (s, e) => s + e.secondes);

  int get repetitions => etapes.where((e) => e.phase == Phase.effort).length;

  /// Minutes d'effort (hors échauffement et retour au calme).
  int get effort => etapes
      .where((e) => e.phase == Phase.effort)
      .fold(0, (s, e) => s + e.secondes);
}

/// Les fractionnés prêts à lancer.
abstract final class Fractionnes {
  static final List<PlanIntervalles> tous = [
    PlanIntervalles.repete(
      nom: '8\u00a0×\u00a01\u00a0min vite, 1\u00a0min lent',
      repetitions: 8,
      effort: 60,
      recuperation: 60,
    ),
    PlanIntervalles.repete(
      nom: 'Tabata\u00a0: 8\u00a0×\u00a020\u00a0s, 10\u00a0s',
      repetitions: 8,
      effort: 20,
      recuperation: 10,
      echauffement: 180,
      retourCalme: 120,
    ),
    PlanIntervalles.repete(
      nom: '10\u00a0×\u00a030\u00a0s, 30\u00a0s',
      repetitions: 10,
      effort: 30,
      recuperation: 30,
    ),
    PlanIntervalles.repete(
      nom: '5\u00a0×\u00a03\u00a0min, 2\u00a0min',
      repetitions: 5,
      effort: 180,
      recuperation: 120,
    ),
    const PlanIntervalles(
      nom: 'Pyramide 1-2-3-2-1',
      etapes: [
        Intervalle(Phase.echauffement, 300),
        Intervalle(Phase.effort, 60),
        Intervalle(Phase.recuperation, 60),
        Intervalle(Phase.effort, 120),
        Intervalle(Phase.recuperation, 60),
        Intervalle(Phase.effort, 180),
        Intervalle(Phase.recuperation, 90),
        Intervalle(Phase.effort, 120),
        Intervalle(Phase.recuperation, 60),
        Intervalle(Phase.effort, 60),
        Intervalle(Phase.retourCalme, 300),
      ],
    ),
  ];
}

// ═══ Programmes de course, marche, vélo ═════════════════════════════════════

class ProgrammeCourse {
  const ProgrammeCourse({
    required this.id,
    required this.nom,
    required this.resume,
    required this.activite,
    required this.seances,
  });

  final String id;
  final String nom;
  final String resume;
  final String activite;

  /// Trois séances par semaine.
  final List<PlanIntervalles> seances;

  int get semaines => (seances.length / 3).ceil();
}

/// Une séance de course : 5 min de marche, les blocs, 5 min de marche.
/// Chaque bloc : (minutes de course, minutes de marche).
PlanIntervalles _course(String nom, List<(double, double)> blocs) =>
    PlanIntervalles(
      nom: nom,
      etapes: [
        const Intervalle(Phase.echauffement, 300),
        for (var i = 0; i < blocs.length; i++) ...[
          Intervalle(Phase.effort, (blocs[i].$1 * 60).round()),
          if (blocs[i].$2 > 0 && i < blocs.length - 1)
            Intervalle(Phase.recuperation, (blocs[i].$2 * 60).round()),
        ],
        const Intervalle(Phase.retourCalme, 300),
      ],
    );

List<(double, double)> _fois(int n, double course, double marche) => [
  for (var i = 0; i < n; i++) (course, marche),
];

abstract final class ProgrammesCourse {
  static final List<ProgrammeCourse> tous = [
    ProgrammeCourse(
      id: 'courir30',
      nom: 'Courir 30\u00a0minutes en 8\u00a0semaines',
      resume:
          "De la marche à 30\u00a0minutes de course sans t'arrêter, trois fois "
          'par semaine.',
      activite: 'course',
      seances: [
        for (var i = 0; i < 3; i++) _course('Semaine 1', _fois(8, 1, 1.5)),
        for (var i = 0; i < 3; i++) _course('Semaine 2', _fois(6, 1.5, 2)),
        for (var i = 0; i < 3; i++)
          _course('Semaine 3', [(1.5, 1.5), (3, 3), (1.5, 1.5), (3, 3)]),
        for (var i = 0; i < 3; i++)
          _course('Semaine 4', [(3, 1.5), (5, 2.5), (3, 1.5), (5, 0)]),
        _course('Semaine 5', _fois(3, 5, 3)),
        _course('Semaine 5', _fois(2, 8, 5)),
        _course('Semaine 5', [(20, 0)]),
        _course('Semaine 6', [(5, 3), (8, 3), (5, 0)]),
        _course('Semaine 6', [(10, 3), (10, 0)]),
        _course('Semaine 6', [(22, 0)]),
        for (var i = 0; i < 3; i++) _course('Semaine 7', [(25, 0)]),
        _course('Semaine 8', [(28, 0)]),
        _course('Semaine 8', [(28, 0)]),
        _course('Semaine 8', [(30, 0)]),
      ],
    ),
    ProgrammeCourse(
      id: 'marche45',
      nom: 'Marche active\u00a0: 45\u00a0minutes en 4\u00a0semaines',
      resume:
          'Marcher vite, de plus en plus longtemps, avec des accélérations.',
      activite: 'marche_rapide',
      seances: [
        for (var s = 0; s < 4; s++)
          for (var i = 0; i < 3; i++)
            PlanIntervalles.repete(
              nom: 'Semaine ${s + 1}',
              activite: 'marche_rapide',
              repetitions: 2 + s,
              effort: 300 + s * 60,
              recuperation: 180,
              echauffement: 300,
              retourCalme: 180,
            ),
      ],
    ),
    ProgrammeCourse(
      id: 'velo60',
      nom: 'Vélo\u00a0: 1 heure en 6\u00a0semaines',
      resume: 'De 30\u00a0minutes à une heure de pédalage, avec des relances.',
      activite: 'velo',
      seances: [
        for (var s = 0; s < 6; s++)
          for (var i = 0; i < 3; i++)
            PlanIntervalles.repete(
              nom: 'Semaine ${s + 1}',
              activite: 'velo',
              repetitions: 3 + s ~/ 2,
              effort: (20 + s * 6) * 60 ~/ (3 + s ~/ 2),
              recuperation: 120,
              echauffement: 300,
              retourCalme: 300,
            ),
      ],
    ),
  ];

  static ProgrammeCourse? de(String id) {
    for (final p in tous) {
      if (p.id == id) return p;
    }
    return null;
  }
}

// ═══ Défis de 4 semaines ════════════════════════════════════════════════════

class Defi {
  const Defi({
    required this.id,
    required this.nom,
    required this.but,
    required this.exercice,
    this.series = const [],
    this.courses = const [],
  });

  final String id;
  final String nom;

  /// « 100 pompes d’affilée ou presque, en fin de 4ᵉ semaine ».
  final String but;

  /// L'exercice (la figure, le mode de mesure).
  final String exercice;

  /// Les douze séances : leurs séries (répétitions, ou secondes).
  final List<List<int>> series;

  /// Pour un défi de course : les douze sorties.
  final List<PlanIntervalles> courses;

  int get etapes => courses.isNotEmpty ? courses.length : series.length;

  bool get deCourse => courses.isNotEmpty;
}

/// Un total réparti en cinq séries décroissantes (24 %, 22 %, 20 %…).
List<int> _repartir(int total, [int n = 5]) {
  const parts = [0.24, 0.22, 0.2, 0.18, 0.16];
  final r = [for (var i = 0; i < n; i++) (total * parts[i]).round()];
  r[0] += total - r.fold(0, (s, x) => s + x);
  return r;
}

/// Douze totaux de [debut] à [fin], le dernier étant le défi lui-même.
List<List<int>> _progression(int debut, int fin, {List<int>? finale}) => [
  for (var i = 0; i < 11; i++)
    _repartir((debut + (fin * 0.9 - debut) * i / 10).round()),
  finale ?? _repartir(fin),
];

abstract final class Defis {
  static final List<Defi> tous = [
    Defi(
      id: 'pompes100',
      nom: '100 pompes',
      but: '100 pompes en une séance, en cinq séries au plus.',
      exercice: 'pompe',
      series: _progression(40, 100, finale: [30, 25, 20, 15, 10]),
    ),
    Defi(
      id: 'squats150',
      nom: '150 squats',
      but: '150 squats en une séance.',
      exercice: 'squat',
      series: _progression(60, 150, finale: [40, 35, 30, 25, 20]),
    ),
    const Defi(
      id: 'gainage3',
      nom: 'Gainage 3\u00a0minutes',
      but: "Tenir la planche 3\u00a0minutes d'affilée.",
      exercice: 'planche',
      series: [
        [30, 30, 30],
        [35, 35, 35],
        [40, 40, 40],
        [45, 45, 45],
        [60, 60],
        [70, 60],
        [80, 60],
        [90, 60],
        [120, 60],
        [140, 60],
        [160],
        [180],
      ],
    ),
    Defi(
      id: 'course5km',
      nom: 'Courir 5\u00a0km',
      but: "Courir 5\u00a0km sans t'arrêter.",
      exercice: 'course',
      courses: [
        _course('Sortie 1', _fois(6, 3, 1)),
        _course('Sortie 2', _fois(5, 4, 1)),
        _course('Sortie 3', _fois(4, 5, 1)),
        _course('Sortie 4', _fois(3, 7, 1)),
        _course('Sortie 5', _fois(3, 8, 1)),
        _course('Sortie 6', _fois(2, 12, 2)),
        _course('Sortie 7', _fois(2, 14, 2)),
        _course('Sortie 8', [(20, 0)]),
        _course('Sortie 9', _fois(2, 15, 1)),
        _course('Sortie 10', [(25, 0)]),
        _course('Sortie 11', [(28, 0)]),
        _course('5\u00a0km', [(35, 0)]),
      ],
    ),
    Defi(
      id: 'burpees50',
      nom: '50 burpees',
      but: "50 burpees en une séance, sans t'arrêter plus de 30\u00a0secondes.",
      exercice: 'burpee',
      series: _progression(20, 50, finale: [15, 12, 10, 8, 5]),
    ),
  ];

  static Defi? de(String id) {
    for (final d in tous) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// La séance [i] (0..11) tombe le jour : trois par semaine (lundi,
  /// mercredi, vendredi de chaque semaine depuis le début).
  static int jourDe(int i) => (i ~/ 3) * 7 + const [0, 2, 4][i % 3];

  /// Le total d'une séance.
  static int total(List<int> series) => series.fold(0, (s, x) => s + x);

  /// Le record visé (la plus grosse série de la dernière séance).
  static int vise(Defi d) =>
      d.series.isEmpty ? 0 : d.series.last.fold(0, math.max);
}

// ═══ Routines express (5 minutes) ═══════════════════════════════════════════

class Routine {
  const Routine({
    required this.id,
    required this.nom,
    required this.resume,
    required this.etapes,
  });

  final String id;
  final String nom;
  final String resume;

  /// (exercice, secondes).
  final List<(String, int)> etapes;

  int get total => etapes.fold(0, (s, e) => s + e.$2);
}

abstract final class Routines {
  static const List<Routine> tous = [
    Routine(
      id: 'reveil',
      nom: 'Réveil',
      resume: 'Déplier le corps et lancer le cœur, en douceur.',
      etapes: [
        ('cercles_bras', 40),
        ('rotation_hanches', 40),
        ('chat_vache', 45),
        ('fente_basse_rotation', 60),
        ('squat', 40),
        ('jumping_jack', 30),
        ('flexion_avant', 40),
      ],
    ),
    Routine(
      id: 'bureau',
      nom: 'Pause bureau',
      resume: 'Relâcher les épaules et le dos, réveiller les jambes.',
      etapes: [
        ('haussements_epaules', 40),
        ('etirement_epaule', 40),
        ('etirement_pectoraux', 40),
        ('flexion_laterale', 40),
        ('etirement_triceps', 40),
        ('squat_chaise', 40),
        ('etirement_quadriceps', 40),
        ('flexion_avant', 30),
      ],
    ),
    Routine(
      id: 'dormir',
      nom: 'Avant de dormir',
      resume: 'Ralentir, étirer le dos, respirer.',
      etapes: [
        ('posture_enfant', 60),
        ('chat_vache', 40),
        ('genoux_poitrine', 45),
        ('torsion_couchee', 60),
        ('jambes_mur', 60),
        ('respiration_ventrale', 60),
      ],
    ),
  ];

  static Routine? de(String id) {
    for (final r in tous) {
      if (r.id == id) return r;
    }
    return null;
  }
}

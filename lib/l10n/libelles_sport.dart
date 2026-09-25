// lib/l10n/libelles_sport.dart
//
// Les libellés des SPORTS : chaque énumération du modèle dans la langue de
// l'app, et les formats propres à l'entraînement (kilos, kilomètres, allure,
// durées de séance). Le contenu de la banque (noms, étapes) reste en
// français : c'est de la donnée.

import '../modele/sports/calculs_sport.dart';
import '../modele/sports/exercices.dart';
import '../modele/sports/muscles.dart';
import '../modele/sports/plans.dart';
import '../modele/sports/sport.dart';
import 'traductions.dart';

extension LibelleStyle on StyleSport {
  String libelle(AppLocalizations tr) => switch (this) {
    StyleSport.musculation => tr.styleMusculation,
    StyleSport.poidsDuCorps => tr.stylePoidsDuCorps,
    StyleSport.gainage => tr.styleGainage,
    StyleSport.hiit => tr.styleHiit,
    StyleSport.mobilite => tr.styleMobilite,
    StyleSport.cardio => tr.styleCardio,
  };
}

extension LibelleMateriel on Materiel {
  String libelle(AppLocalizations tr) => switch (this) {
    Materiel.halteres => tr.materielHalteres,
    Materiel.barre => tr.materielBarre,
    Materiel.kettlebell => tr.materielKettlebell,
    Materiel.elastique => tr.materielElastique,
    Materiel.barreTraction => tr.materielBarreTraction,
    Materiel.banc => tr.materielBanc,
    Materiel.chaise => tr.materielChaise,
    Materiel.corde => tr.materielCorde,
    Materiel.velo => tr.materielVelo,
  };
}

extension LibelleNiveau on Niveau {
  String libelle(AppLocalizations tr) => switch (this) {
    Niveau.debutant => tr.niveauDebutant,
    Niveau.intermediaire => tr.niveauIntermediaire,
    Niveau.avance => tr.niveauAvance,
  };
}

extension LibelleMuscle on Muscle {
  String libelle(AppLocalizations tr) => switch (this) {
    Muscle.pectoraux => tr.musclePectoraux,
    Muscle.dos => tr.muscleDos,
    Muscle.trapezes => tr.muscleTrapezes,
    Muscle.epaules => tr.muscleEpaules,
    Muscle.biceps => tr.muscleBiceps,
    Muscle.triceps => tr.muscleTriceps,
    Muscle.avantBras => tr.muscleAvantBras,
    Muscle.abdos => tr.muscleAbdos,
    Muscle.obliques => tr.muscleObliques,
    Muscle.lombaires => tr.muscleLombaires,
    Muscle.fessiers => tr.muscleFessiers,
    Muscle.quadriceps => tr.muscleQuadriceps,
    Muscle.ischios => tr.muscleIschios,
    Muscle.adducteurs => tr.muscleAdducteurs,
    Muscle.mollets => tr.muscleMollets,
  };
}

extension LibelleObjectif on Objectif {
  String libelle(AppLocalizations tr) => switch (this) {
    Objectif.force => tr.objectifForce,
    Objectif.volume => tr.objectifVolume,
    Objectif.endurance => tr.objectifEndurance,
  };

  String detail(AppLocalizations tr) => switch (this) {
    Objectif.force => tr.objectifForceDetail,
    Objectif.volume => tr.objectifVolumeDetail,
    Objectif.endurance => tr.objectifEnduranceDetail,
  };
}

extension LibelleRessenti on Ressenti {
  String libelle(AppLocalizations tr) => switch (this) {
    Ressenti.facile => tr.ressentiFacile,
    Ressenti.correct => tr.ressentiCorrect,
    Ressenti.difficile => tr.ressentiDifficile,
    Ressenti.echec => tr.ressentiEchec,
  };
}

/// L'effort ressenti d'une séance (1 à 5).
String libelleEffort(AppLocalizations tr, int n) => switch (n) {
  1 => tr.effort1,
  2 => tr.effort2,
  3 => tr.effort3,
  4 => tr.effort4,
  _ => tr.effort5,
};

extension LibellePhase on Phase {
  String libelle(AppLocalizations tr) => switch (this) {
    Phase.echauffement => tr.phaseEchauffement,
    Phase.effort => tr.phaseEffort,
    Phase.recuperation => tr.phaseRecuperation,
    Phase.retourCalme => tr.phaseRetourCalme,
  };
}

extension LibelleRole on RoleLigne {
  String libelle(AppLocalizations tr) => switch (this) {
    RoleLigne.echauffement => tr.echauffement,
    RoleLigne.travail => tr.roleSeance,
    RoleLigne.retourCalme => tr.retourAuCalme,
  };
}

extension LibelleRecord on TypeRecord {
  String libelle(AppLocalizations tr) => switch (this) {
    TypeRecord.charge => tr.recordCharge,
    TypeRecord.reps => tr.recordReps,
    TypeRecord.force => tr.recordForce,
    TypeRecord.duree => tr.recordDuree,
  };
}

extension LibelleProgres on Progres {
  String libelle(AppLocalizations tr) => switch (this) {
    Progres.premiereFois => tr.progresPremiereFois,
    Progres.pareil => tr.progresPareil,
    Progres.repDePlus => tr.progresRepDePlus,
    Progres.plusDeCharge => tr.progresPlusDeCharge,
    Progres.plusLong => tr.progresPlusLong,
  };
}

/// Les formats de l'entraînement.
extension FormatsSport on Formats {
  /// « 57,5 kg ».
  String kg(double x, AppLocalizations tr) => tr.kgValeur(decimal(x));

  /// « 6,8 km ».
  String km(double x, AppLocalizations tr) => tr.kmValeur(decimal(x));

  /// « 84 cm ».
  String cm(double x, AppLocalizations tr) => tr.cmValeur(decimal(x));

  /// Une durée de séance : « 42 min », « 1 h 05 ».
  String dureeSeance(int secondes) {
    final m = (secondes / 60).round();
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${(m % 60).toString().padLeft(2, '0')}';
  }

  /// Un temps de minuteur, heures comprises : « 4:05 », « 1:02:30 ».
  String chrono(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }

  /// Un repos ou une série en durée : « 45 s », « 1 min 30 », « 2 min ».
  String secondes(int s) {
    if (s < 60) return '$s s';
    final r = s % 60;
    return r == 0
        ? '${s ~/ 60} min'
        : '${s ~/ 60} min ${r.toString().padLeft(2, '0')}';
  }

  /// Le dosage d'une ligne : « 4 × 8 · 60 kg », « 3 × 45 s ».
  String dosage(LigneSeance l, AppLocalizations tr) {
    final base = l.secondes != null
        ? tr.dosageSecondes(l.series, l.secondes!)
        : tr.dosageReps(l.series, l.reps ?? 0);
    final c = l.charge;
    return c == null || c <= 0 ? base : '$base · ${kg(c, tr)}';
  }

  /// Une fois faite : « 8, 8, 8, 7 · 60 kg » ou « 45 s, 45 s ».
  String series(ExerciceFait f, AppLocalizations tr) {
    if (f.series.isEmpty) return '';
    if (f.series.every((s) => s.secondes != null && s.reps == null)) {
      return f.series.map((s) => secondes(s.secondes!)).join(', ');
    }
    final reps = f.series.map((s) => '${s.reps ?? 0}').join(', ');
    final c = chargeDeTravail(f);
    return c == null ? reps : '$reps · ${kg(c, tr)}';
  }

  /// Un record : « 62,5 kg », « 15 répétitions », « 1 min 30 ».
  String record(TypeRecord t, double v, AppLocalizations tr) => switch (t) {
    TypeRecord.charge ||
    TypeRecord.force => kg((v * 2).roundToDouble() / 2, tr),
    TypeRecord.reps => '${v.round()} ${tr.repetitions.toLowerCase()}',
    TypeRecord.duree => secondes(v.round()),
  };
}

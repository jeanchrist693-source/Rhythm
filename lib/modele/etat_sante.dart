// lib/modele/etat_sante.dart
//
// L'état de Rhythm (Riverpod) : aujourd'hui, et la SEMAINE de sport — vivante
// depuis le journal des Sports (`sports/etat_sport.dart`). Les habitudes
// vivent dans `etat_habitudes.dart`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sports/calculs_sport.dart';
import 'sports/etat_sport.dart';

/// Maintenant (le jour ET l'heure : « Bonjour » / « Bonsoir », le mot du
/// jour des habitudes). Rafraîchi au retour dans l'app et quand la tranche
/// de la journée change (`systeme/synchro.dart`) ; fixé par les tests et les
/// captures.
final aujourdhuiProvider = Provider<DateTime>((ref) => DateTime.now());

/// L'heure EXACTE, lue à la demande (compteurs de libération, envie notée,
/// minuteurs des séances). Remplacée par les tests et les captures.
final horlogeProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// La semaine d'entraînement, du lundi au dimanche.
class SemaineSport {
  const SemaineSport({
    required this.minutes,
    required this.aujourdhui,
    required this.seances,
    required this.calories,
    required this.serie,
    required this.objectifJour,
    required this.objectifSemaine,
  });

  /// Minutes par jour, lundi → dimanche ; `null` = jour à venir.
  final List<int?> minutes;

  /// Index d'aujourd'hui (0 = lundi).
  final int aujourdhui;
  final int seances;

  /// Calories dépensées cette semaine.
  final int calories;

  /// Semaines d'affilée avec au moins une séance.
  final int serie;
  final int objectifJour;
  final int objectifSemaine;

  int get total => minutes.fold(0, (s, m) => s + (m ?? 0));
  int get minutesAujourdhui => minutes[aujourdhui] ?? 0;
}

final semaineSportProvider = Provider<SemaineSport>((ref) {
  final auj = ref.watch(aujourdhuiProvider);
  final etat = ref.watch(sportProvider);
  final s = semaineDe(etat.journal, auj);
  return SemaineSport(
    minutes: s.minutes,
    aujourdhui: s.index,
    seances: s.seances,
    calories: s.kcal,
    serie: serieSemaines(etat.journal, auj),
    objectifJour: etat.profil.objectifJour,
    objectifSemaine: etat.profil.objectifSemaine,
  );
});

// lib/modele/alimentation/bilan_semaine.dart
//
// Le BILAN DE LA SEMAINE (palier 4) : les CHIFFRES, calculés sur le
// téléphone — l'IA ne fait que les commenter (`ia_alimentation.dart`).
// Sept jours, aujourd'hui compris ; les moyennes se font sur les journées
// NOTÉES (au moins 2 aliments et 1 000 kcal : `journeeNotee`), pour ne pas
// prendre un jour oublié pour un jeûne. Les repères de Santé Canada pour
// les fibres (25 g) et le sodium (2 300 mg, limite) ; le reste, les
// objectifs du jour (`besoinsDu`). Une ENTRÉE RAPIDE ne dit que ses
// calories et ses macros : si elles pèsent plus du quart des calories, les
// fibres et le sodium sont inconnus (pas nuls) — ni montrés ni commentés.

import '../../utils/dates.dart';
import '../sports/sport.dart';
import 'alimentation.dart';
import 'calculs_alimentation.dart';
import 'courses.dart';
import 'nutriments.dart';

/// Les repères du bilan (adultes) : fibres visées, sodium à ne pas
/// dépasser.
const double kFibresVisees = 25;
const double kSodiumLimite = 2300;

class BilanSemaine {
  const BilanSemaine({
    required this.debut,
    required this.fin,
    required this.joursNotes,
    required this.moyenne,
    required this.kcalVisees,
    required this.proteinesVisees,
    required this.verresMoyens,
    required this.verresVises,
    required this.seances,
    required this.frequents,
    required this.jetes,
    this.microsConnus = true,
  });

  /// Le premier et le dernier jour (aujourd'hui).
  final DateTime debut, fin;

  /// Les journées notées, sur 7.
  final int joursNotes;

  /// Par journée notée.
  final Nutriments moyenne;
  final int kcalVisees, proteinesVisees;

  /// Par jour, sur les 7.
  final double verresMoyens;
  final int verresVises;

  /// Les séances faites.
  final int seances;

  /// Les aliments qui reviennent le plus (nom, fois), au plus cinq.
  final List<(String, int)> frequents;

  /// Les aliments jetés.
  final List<String> jetes;

  /// Les fibres et le sodium veulent dire quelque chose (peu d'entrées
  /// rapides, qui ne les disent pas).
  final bool microsConnus;

  /// Assez de journées notées pour un bilan qui veut dire quelque chose.
  bool get suffisant => joursNotes >= 3;

  /// La même semaine, pour savoir si un bilan gardé est encore le bon.
  String get cle => '${cleJour(fin)}-$joursNotes-${moyenne.kcal.round()}';
}

BilanSemaine bilanDeLaSemaine({
  required List<EntreeJournal> journal,
  required Map<int, int> eau,
  required Besoins besoins,
  required List<SeanceFaite> seances,
  required List<Sortie> sorties,
  required DateTime aujourdhui,
}) {
  final fin = jourDe(aujourdhui);
  final debut = plusJours(fin, -6);
  bool dansLaSemaine(DateTime d) =>
      !jourDe(d).isBefore(debut) && !jourDe(d).isAfter(fin);

  final parJour = <DateTime, List<EntreeJournal>>{};
  for (final e in journal) {
    if (dansLaSemaine(e.jour)) (parJour[e.jour] ??= []).add(e);
  }
  final notes = [
    for (final l in parJour.values)
      if (journeeNotee(l)) l,
  ];
  final somme = Nutriments.somme(notes.map(totalDe));
  final rapides = Nutriments.somme([
    for (final l in notes)
      for (final e in l)
        if (e.source == SourceEntree.rapide) e.nutriments,
  ]).kcal;
  final moyenne = notes.isEmpty ? Nutriments.zero : somme * (1 / notes.length);

  var verres = 0;
  for (var i = 0; i < 7; i++) {
    verres += eau[cleJour(plusJours(debut, i))] ?? 0;
  }

  final fois = <String, int>{};
  final noms = <String, String>{};
  for (final l in parJour.values) {
    for (final e in l) {
      final cle = e.nom.toLowerCase();
      fois[cle] = (fois[cle] ?? 0) + 1;
      noms[cle] ??= e.nom;
    }
  }
  final frequents = [
    for (final e in fois.entries)
      if (e.value >= 2) (noms[e.key]!, e.value),
  ]..sort((a, b) => b.$2.compareTo(a.$2));

  return BilanSemaine(
    debut: debut,
    fin: fin,
    joursNotes: notes.length,
    moyenne: moyenne,
    kcalVisees: besoins.kcal,
    proteinesVisees: besoins.proteines,
    verresMoyens: verres / 7,
    verresVises: besoins.verres,
    seances: seances.where((s) => dansLaSemaine(s.debut)).length,
    frequents: frequents.take(5).toList(),
    jetes: [
      for (final s in sorties)
        if (s.jete && dansLaSemaine(s.date)) s.nom,
    ],
    microsConnus: somme.kcal > 0 && rapides <= somme.kcal / 4,
  );
}

// lib/utils/dates.dart
//
// Jours calendaires. Toujours `plusJours` pour se déplacer dans le
// calendrier, jamais `Duration(days:)` : au changement d'heure, un jour ne
// dure pas 24 h (convention de Studio / Flow).

DateTime jourDe(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime plusJours(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Le lundi de la semaine de [d].
DateTime lundiDe(DateTime d) => plusJours(jourDe(d), 1 - d.weekday);

/// Nombre de jours de [a] à [b] (dates calendaires, changement d'heure
/// sans effet).
int joursEntre(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Numéro de semaine ISO 8601 (la semaine 1 contient le premier jeudi de
/// l'année) : « Semaine 39 ».
int numeroSemaine(DateTime d) {
  final jeudi = DateTime.utc(d.year, d.month, d.day + 4 - d.weekday);
  return jeudi.difference(DateTime.utc(jeudi.year)).inDays ~/ 7 + 1;
}

/// Le même instant [n] jours plus tard, à la même heure de la journée
/// (un palier de libération tombe à l'heure où la période a commencé).
DateTime plusJoursInstant(DateTime d, int n) =>
    DateTime(d.year, d.month, d.day + n, d.hour, d.minute, d.second);

/// Clé d'un jour pour la base : 20260924 (compacte, triable, sans heure).
int cleJour(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// Le jour (minuit) d'une clé [cleJour].
DateTime jourDeCle(int cle) =>
    DateTime(cle ~/ 10000, (cle ~/ 100) % 100, cle % 100);

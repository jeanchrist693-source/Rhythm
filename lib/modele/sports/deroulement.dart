// lib/modele/sports/deroulement.dart
//
// Le DÉROULÉ d'une séance guidée, en fonctions pures : la suite des étapes
// (une étape = une série d'une ligne) et le repos après chacune. Deux lignes
// d'une même paire (A1 / A2) ALTERNENT leurs séries, sans repos entre A1 et
// A2 — le repos vient après la paire.

import 'sport.dart';

/// Une série d'une ligne : la [ligne] (indice) et la [serie] (0 = la
/// première).
class Etape {
  const Etape(this.ligne, this.serie);

  final int ligne;
  final int serie;

  @override
  bool operator ==(Object other) =>
      other is Etape && other.ligne == ligne && other.serie == serie;

  @override
  int get hashCode => Object.hash(ligne, serie);

  @override
  String toString() => 'Etape($ligne, $serie)';
}

/// Les étapes de la séance, dans l'ordre.
List<Etape> etapesDe(List<LigneSeance> lignes) {
  final r = <Etape>[];
  var i = 0;
  while (i < lignes.length) {
    final a = lignes[i];
    final g = a.groupe;
    if (g != null && i + 1 < lignes.length && lignes[i + 1].groupe == g) {
      final b = lignes[i + 1];
      final n = a.series > b.series ? a.series : b.series;
      for (var s = 0; s < n; s++) {
        if (s < a.series) r.add(Etape(i, s));
        if (s < b.series) r.add(Etape(i + 1, s));
      }
      i += 2;
      continue;
    }
    for (var s = 0; s < a.series; s++) {
      r.add(Etape(i, s));
    }
    i++;
  }
  return r;
}

/// Le repos après l'étape [k] (secondes) : celui de sa ligne — 15 s entre
/// les deux exercices d'une paire, rien après la dernière étape.
int reposApres(List<Etape> etapes, int k, List<LigneSeance> lignes) {
  if (k >= etapes.length - 1) return 0;
  return lignes[etapes[k].ligne].repos;
}

/// L'étape qui suit [k] en sautant les lignes [passees] (« Passer
/// l'exercice ») ; `etapes.length` : c'est fini.
int suivante(List<Etape> etapes, int k, Set<int> passees) {
  var j = k + 1;
  while (j < etapes.length && passees.contains(etapes[j].ligne)) {
    j++;
  }
  return j;
}

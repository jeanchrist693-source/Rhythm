// lib/modele/alimentation/expressions.dart
//
// Reconnaître un aliment dans un nom tapé à la main : les MOTS simplifiés
// (minuscules, sans accents, au singulier) et les EXPRESSIONS d'un
// dictionnaire (« beurre d arachide », « pomme de terre »). Sert au guide
// de conservation, aux taxes et aux rayons.
//
// Règles : chaque mot du nom doit COMMENCER par celui de l'expression sans
// le dépasser de plus d'un pluriel (« pate » ne trouve pas « patate ») ; un
// mot de 3 lettres ou moins doit être le même (« ail » ne trouve pas
// « aile », « the » ne trouve pas « thon »). Parmi plusieurs expressions :
// la plus LONGUE gagne ; à égalité, la plus à DROITE (« fromage cottage »
// → cottage) ; puis la plus longue en lettres.

import 'base_aliments.dart' show motsDe, singulier;

/// Les mots de [texte], simplifiés et au singulier.
List<String> motsSimplifies(String texte) => [
  for (final m in motsDe(texte)) singulier(m),
];

/// Où [expression] se trouve dans [mots] : (longueur en mots, position), ou
/// `null`.
(int, int)? trouverExpression(List<String> mots, String expression) {
  // L'expression passe au singulier comme le nom (« ananas » → « anana »
  // des deux côtés).
  final e = [for (final m in expression.split(' ')) singulier(m)];
  for (var i = 0; i + e.length <= mots.length; i++) {
    var ok = true;
    for (var k = 0; k < e.length; k++) {
      final m = mots[i + k], x = e[k];
      final different = x.length <= 3
          ? m != x
          : !m.startsWith(x) || m.length > x.length + 1;
      if (different) {
        ok = false;
        break;
      }
    }
    if (ok) return (e.length, i);
  }
  return null;
}

/// La valeur de [dictionnaire] dont une expression répond le mieux à
/// [mots] ; `null` si aucune.
T? meilleureExpression<T>(
  List<String> mots,
  Iterable<(T, List<String>)> dictionnaire,
) {
  T? meilleur;
  var longueur = 0, position = -1, caracteres = 0;
  for (final (valeur, expressions) in dictionnaire) {
    for (final e in expressions) {
      final t = trouverExpression(mots, e);
      if (t == null) continue;
      final (n, i) = t;
      final mieux =
          n > longueur ||
          (n == longueur &&
              (i > position || (i == position && e.length > caracteres)));
      if (mieux) {
        meilleur = valeur;
        longueur = n;
        position = i;
        caracteres = e.length;
      }
    }
  }
  return meilleur;
}

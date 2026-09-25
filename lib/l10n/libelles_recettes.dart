// lib/l10n/libelles_recettes.dart
//
// Les libellés des RECETTES : le tri du livre, et les formats — fractions
// de cuisine (« 1 ½ », « ¾ »), durées (« 35 min », « 1 h 15 »), portions
// (« 1,5 portion » / « 1.5 servings »), la quantité d'un ingrédient
// (« 2 × 1 moyen », « 500 ml », « 600 g »).

import '../modele/alimentation/calculs_recettes.dart';
import '../modele/alimentation/courses.dart';
import '../modele/alimentation/recettes.dart';
import 'libelles_courses.dart';
import 'traductions.dart';

extension LibelleTriRecettes on TriRecettes {
  String libelle(AppLocalizations tr) => switch (this) {
    TriRecettes.recentes => tr.triRecentes,
    TriRecettes.alphabetique => tr.triAlphabetique,
    TriRecettes.proteines => tr.triProteines,
    TriRecettes.calories => tr.triCalories,
    TriRecettes.rapides => tr.triRapides,
  };
}

const _fractions = [(0.25, '¼'), (0.5, '½'), (0.75, '¾')];

extension FormatsRecettes on Formats {
  bool get _fr => langue == 'fr';

  /// Une fraction de cuisine : « ½ », « 1 ½ », « ¾ », sinon un décimal.
  String fraction(double n) {
    final entier = n.floor();
    final reste = n - entier;
    for (final (part, glyphe) in _fractions) {
      if ((reste - part).abs() < 0.01) {
        return entier == 0 ? glyphe : '$entier $glyphe';
      }
    }
    if (reste < 0.01) return '$entier';
    return decimal((n * 100).round() / 100);
  }

  /// « 35 min », « 1 h », « 1 h 15 ».
  String minutes(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60, r = m % 60;
    return r == 0 ? '$h h' : '$h h ${r.toString().padLeft(2, '0')}';
  }

  /// « 1 portion », « 1 ½ portion », « 3 portions » / « 1 serving »…
  String portions(double n, AppLocalizations tr) {
    final singulier = _fr ? n < 2 : (n - 1).abs() < 0.001;
    final x = fraction(n);
    return singulier ? tr.portionUne(x) : tr.portionsPlusieurs(x);
  }

  /// La quantité d'un ingrédient : « 2 × 1 moyen », « 500 ml », « 600 g »,
  /// « 1 boîte » ; vide si on ne la connaît pas.
  String quantiteIngredient(Ingredient i, AppLocalizations tr) {
    final m = i.mesure, n = i.nombre;
    if (m != null && n != null && mesureUnitaire(m)) {
      final c = mesureCourte(m);
      return (n - 1).abs() < 0.001 ? c : '${fraction(n)} × $c';
    }
    final q = quantiteDe(i);
    if (q == null) return '';
    // Les unités se disent en fractions de cuisine (« ½ »).
    if (q.unite == Unite.unite) return fraction(q.valeur);
    return quantite(Quantite((q.valeur * 10).round() / 10, q.unite), tr);
  }
}

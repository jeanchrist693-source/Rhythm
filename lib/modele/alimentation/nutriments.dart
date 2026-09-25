// lib/modele/alimentation/nutriments.dart
//
// Ce qu'un aliment apporte : l'énergie (kcal), les trois macronutriments
// (g), et quatre repères (fibres, sucres, gras saturés en g ; sodium en mg).
// Une valeur inconnue vaut 0 dans les sommes. Pour 100 g dans la base
// (`base_aliments.dart`), pour une portion dans un produit, pour la quantité
// mangée dans le journal.

class Nutriments {
  const Nutriments({
    this.kcal = 0,
    this.proteines = 0,
    this.glucides = 0,
    this.lipides = 0,
    this.fibres = 0,
    this.sucres = 0,
    this.sodium = 0,
    this.satures = 0,
  });

  static const Nutriments zero = Nutriments();

  final double kcal;
  final double proteines;
  final double glucides;
  final double lipides;
  final double fibres;
  final double sucres;

  /// Milligrammes.
  final double sodium;
  final double satures;

  Nutriments operator +(Nutriments o) => Nutriments(
    kcal: kcal + o.kcal,
    proteines: proteines + o.proteines,
    glucides: glucides + o.glucides,
    lipides: lipides + o.lipides,
    fibres: fibres + o.fibres,
    sucres: sucres + o.sucres,
    sodium: sodium + o.sodium,
    satures: satures + o.satures,
  );

  Nutriments operator *(double k) => Nutriments(
    kcal: kcal * k,
    proteines: proteines * k,
    glucides: glucides * k,
    lipides: lipides * k,
    fibres: fibres * k,
    sucres: sucres * k,
    sodium: sodium * k,
    satures: satures * k,
  );

  static Nutriments somme(Iterable<Nutriments> liste) =>
      liste.fold(zero, (s, n) => s + n);

  Map<String, dynamic> versJson() => {
    'kcal': _arrondi(kcal),
    if (proteines != 0) 'p': _arrondi(proteines),
    if (glucides != 0) 'g': _arrondi(glucides),
    if (lipides != 0) 'l': _arrondi(lipides),
    if (fibres != 0) 'fib': _arrondi(fibres),
    if (sucres != 0) 'suc': _arrondi(sucres),
    if (sodium != 0) 'na': _arrondi(sodium),
    if (satures != 0) 'sat': _arrondi(satures),
  };

  /// Lecture TOLÉRANTE : une valeur absente ou illisible vaut 0.
  static Nutriments depuisJson(Object? j) {
    if (j is! Map) return zero;
    double v(String cle) {
      final x = j[cle];
      return x is num && x.isFinite && x >= 0 ? x.toDouble() : 0;
    }

    return Nutriments(
      kcal: v('kcal'),
      proteines: v('p'),
      glucides: v('g'),
      lipides: v('l'),
      fibres: v('fib'),
      sucres: v('suc'),
      sodium: v('na'),
      satures: v('sat'),
    );
  }

  static double _arrondi(double x) => (x * 10).round() / 10;

  @override
  bool operator ==(Object other) =>
      other is Nutriments &&
      other.kcal == kcal &&
      other.proteines == proteines &&
      other.glucides == glucides &&
      other.lipides == lipides &&
      other.fibres == fibres &&
      other.sucres == sucres &&
      other.sodium == sodium &&
      other.satures == satures;

  @override
  int get hashCode => Object.hash(
    kcal,
    proteines,
    glucides,
    lipides,
    fibres,
    sucres,
    sodium,
    satures,
  );

  @override
  String toString() =>
      'Nutriments($kcal kcal, P $proteines, G $glucides, L $lipides)';
}

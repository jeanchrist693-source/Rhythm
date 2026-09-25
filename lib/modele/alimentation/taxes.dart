// lib/modele/alimentation/taxes.dart
//
// Les TAXES DU QUÉBEC à l'épicerie, pour ne plus avoir de surprise à la
// caisse.
//
// - Deux taxes : la TPS (fédérale, 5 % depuis le 1er janvier 2008) et la
//   TVQ (9,975 % depuis le 1er janvier 2013), calculées chacune sur le prix
//   avant taxes. Le BARÈME est DATÉ : un changement annoncé s'applique seul
//   le jour venu ([baremeAu]).
// - TROIS statuts pour un article : DÉTAXÉ (les aliments de base : fruits,
//   légumes, viandes, produits laitiers, pain, céréales…), TPS SEULEMENT
//   (depuis le 15 juillet 2026, plus de TVQ sur : barres et mélanges
//   granola, noix et graines salées, pâtisseries à l'unité — moins de 230 g
//   ou paquet de moins de 6 —, desserts glacés de moins de 500 g, coupes de
//   dessert de moins de 425 g, plateaux de fruits ou de légumes coupés,
//   papier hygiénique, mouchoirs), TPS + TVQ (boissons gazeuses, bonbons,
//   chocolat, croustilles, alcool, produits d'entretien et d'hygiène…).
// - L'utilisateur APPLIQUE le statut lui-même (sa demande) : l'app le
//   propose d'après le nom ([suggererStatut] : des mots-clés, puis le
//   rayon) et dit pourquoi.
// - La CONSIGNE (10 ¢, 25 ¢ pour le verre de 500 ml et plus) n'est pas
//   taxée ; elle s'ajoute au total à part.
// - À la CAISSE ([Caisse.de]) : la TPS sur tout ce qui y est soumis, la TVQ
//   sur ce qui y est soumis, chacune arrondie au cent.
//
// Sources : Revenu Québec (produits alimentaires de base), RECYC-QUÉBEC
// (consigne), annonce du 15 juillet 2026.

import 'expressions.dart';

/// Le statut d'un article à la caisse.
enum StatutTaxe {
  /// 0 % : un aliment de base.
  detaxe,

  /// TPS seulement (5 %).
  tps,

  /// TPS + TVQ (14,975 %).
  tpsTvq;

  bool get avecTps => this != StatutTaxe.detaxe;
  bool get avecTvq => this == StatutTaxe.tpsTvq;
}

/// Des taux en vigueur à partir d'une date.
class Bareme {
  const Bareme({required this.depuis, required this.tps, required this.tvq});

  final DateTime depuis;
  final double tps;
  final double tvq;

  Map<String, dynamic> versJson() => {
    'depuis': depuis.toIso8601String().substring(0, 10),
    'tps': tps,
    'tvq': tvq,
  };

  static Bareme? depuisJson(Object? j) {
    if (j is! Map) return null;
    final d = j['depuis'] is String ? DateTime.tryParse(j['depuis']) : null;
    final tps = j['tps'], tvq = j['tvq'];
    // Un taux invraisemblable est refusé (un fichier abîmé ne doit pas
    // fausser la caisse).
    if (d == null || tps is! num || tvq is! num) return null;
    if (tps < 0 || tps > 0.2 || tvq < 0 || tvq > 0.2) return null;
    return Bareme(depuis: d, tps: tps.toDouble(), tvq: tvq.toDouble());
  }
}

/// Les barèmes connus, du plus ancien au plus récent.
final List<Bareme> kBaremesQuebec = [
  Bareme(depuis: DateTime(2013), tps: 0.05, tvq: 0.09975),
];

/// La date des règles embarquées (ce qui est détaxé ou non).
final DateTime kReglesDepuis = DateTime(2026, 7, 15);

/// Le barème en vigueur [jour] parmi [baremes] (les embarqués, et ceux
/// reçus en ligne s'il y en a).
Bareme baremeAu(DateTime jour, [List<Bareme>? baremes]) {
  final liste = [...(baremes ?? kBaremesQuebec)]
    ..sort((a, b) => a.depuis.compareTo(b.depuis));
  var b = liste.first;
  for (final x in liste) {
    if (!x.depuis.isAfter(jour)) b = x;
  }
  return b;
}

// ═══ La suggestion du statut ════════════════════════════════════════════════

/// Pourquoi ce statut est proposé (l'écran le dit en une phrase).
enum RaisonTaxe {
  /// Un aliment de base.
  base,

  /// Grignotines, bonbons, chocolat, boissons gazeuses…
  grignotines,

  /// Alcool.
  alcool,

  /// Plus de TVQ depuis le 15 juillet 2026.
  tvqAbolie,

  /// À l'unité : TPS seulement ; par 6 et plus : détaxé.
  alUnite,

  /// Produits d'entretien, d'hygiène : non alimentaires.
  nonAlimentaire,

  /// Protections menstruelles : détaxées.
  hygieneDetaxee,
}

class Suggestion {
  const Suggestion(this.statut, this.raison);

  final StatutTaxe statut;
  final RaisonTaxe raison;
}

/// Une règle : des expressions (mots simplifiés, au singulier) → un statut.
class _Regle {
  const _Regle(this.expressions, this.statut, this.raison);

  final List<String> expressions;
  final StatutTaxe statut;
  final RaisonTaxe raison;
}

// L'ordre compte : la première règle qui répond gagne (« barre tendre »
// avant « barre de chocolat », « papier hygiénique » avant « hygiène »).
const List<_Regle> _regles = [
  _Regle(
    [
      'papier hygienique',
      'papier de toilette',
      'mouchoir',
      'kleenex',
      'granola',
      'barre tendre',
      'melange montagnard',
      'melange du randonneur',
      'noix salee',
      'arachide salee',
      'amande salee',
      'pistache',
      'graine de tournesol',
      'plateau de fruit',
      'plateau de legume',
      'salade de fruit',
      'coupe de pouding',
      'pouding',
      'jello',
      'barre glacee',
      'batonnet glace',
      'cornet',
      'sandwich a la creme glacee',
      'popsicle',
      'mister freeze',
    ],
    StatutTaxe.tps,
    RaisonTaxe.tvqAbolie,
  ),
  _Regle(
    ['muffin', 'beigne', 'croissant', 'danoise', 'brownie', 'chausson'],
    StatutTaxe.tps,
    RaisonTaxe.alUnite,
  ),
  _Regle(
    ['biere', 'vin', 'cidre', 'alcool', 'vodka', 'rhum', 'gin', 'whisky'],
    StatutTaxe.tpsTvq,
    RaisonTaxe.alcool,
  ),
  _Regle(
    [
      'croustille',
      'chips',
      'nacho',
      'bretzel',
      'mais souffle',
      'popcorn',
      'crotte de fromage',
      'bonbon',
      'chocolat',
      'gomme',
      'jujube',
      'reglisse',
      'guimauve',
      'friandise',
      'boisson gazeuse',
      'liqueur',
      'cola',
      'soda',
      'eau petillante',
      'boisson energisante',
      'boisson aux fruit',
      'cocktail',
      'punch',
    ],
    StatutTaxe.tpsTvq,
    RaisonTaxe.grignotines,
  ),
  _Regle(
    ['serviette hygienique', 'tampon', 'coupe menstruelle', 'protege dessous'],
    StatutTaxe.detaxe,
    RaisonTaxe.hygieneDetaxee,
  ),
];

/// « Chocolat noir » mais pas « lait au chocolat » (un aliment de base) :
/// ces expressions l'emportent et restent détaxées.
const List<String> _exceptionsDetaxees = [
  'cereale',
  'yogourt',
  'gruau',
  'boisson de soya',
  'boisson d amande',
  'lait au chocolat',
  'lait chocolate',
  'pepite de chocolat',
  'poudre de cacao',
  'jus',
  'eau de source',
];

bool _contient(List<String> mots, String expression) =>
    trouverExpression(mots, expression) != null;

/// Le statut proposé pour [nom], sinon celui du rayon ([parDefaut]).
Suggestion suggererStatut(
  String nom,
  StatutTaxe parDefaut, {
  bool nonAlimentaire = false,
}) {
  final mots = motsSimplifies(nom);
  if (_exceptionsDetaxees.any((e) => _contient(mots, e))) {
    return const Suggestion(StatutTaxe.detaxe, RaisonTaxe.base);
  }
  for (final r in _regles) {
    if (r.expressions.any((e) => _contient(mots, e))) {
      return Suggestion(r.statut, r.raison);
    }
  }
  if (nonAlimentaire) {
    return const Suggestion(StatutTaxe.tpsTvq, RaisonTaxe.nonAlimentaire);
  }
  return Suggestion(
    parDefaut,
    parDefaut == StatutTaxe.detaxe ? RaisonTaxe.base : RaisonTaxe.grignotines,
  );
}

/// La consigne proposée pour [nom] (canettes et bouteilles de boisson).
double consigneSuggeree(String nom) {
  final mots = motsSimplifies(nom);
  const dix = [
    'canette',
    'boisson gazeuse',
    'liqueur',
    'cola',
    'soda',
    'biere',
    'eau petillante',
    'boisson energisante',
    'bouteille d eau',
  ];
  return dix.any((e) => _contient(mots, e)) ? 0.10 : 0;
}

// ═══ La caisse ══════════════════════════════════════════════════════════════

/// Une ligne à passer à la caisse.
typedef LigneCaisse = ({double prix, StatutTaxe statut, double consigne});

class Caisse {
  const Caisse({
    required this.sousTotal,
    required this.tps,
    required this.tvq,
    required this.consigne,
  });

  static const vide = Caisse(sousTotal: 0, tps: 0, tvq: 0, consigne: 0);

  final double sousTotal;
  final double tps;
  final double tvq;
  final double consigne;

  double get taxes => _cents(tps + tvq);
  double get total => _cents(sousTotal + tps + tvq + consigne);

  /// Le passage à la caisse : chaque taxe sur ce qui y est soumis,
  /// arrondie au cent.
  static Caisse de(Iterable<LigneCaisse> lignes, Bareme bareme) {
    var sousTotal = 0.0, soumisTps = 0.0, soumisTvq = 0.0, consigne = 0.0;
    for (final l in lignes) {
      sousTotal += l.prix;
      if (l.statut.avecTps) soumisTps += l.prix;
      if (l.statut.avecTvq) soumisTvq += l.prix;
      consigne += l.consigne;
    }
    return Caisse(
      sousTotal: _cents(sousTotal),
      tps: _cents(soumisTps * bareme.tps),
      tvq: _cents(soumisTvq * bareme.tvq),
      consigne: _cents(consigne),
    );
  }

  /// Le prix d'une ligne taxes comprises (sans la consigne).
  static double avecTaxes(double prix, StatutTaxe statut, Bareme bareme) =>
      _cents(
        prix *
            (1 +
                (statut.avecTps ? bareme.tps : 0) +
                (statut.avecTvq ? bareme.tvq : 0)),
      );

  Map<String, dynamic> versJson() => {
    'st': sousTotal,
    'tps': tps,
    'tvq': tvq,
    if (consigne > 0) 'consigne': consigne,
  };

  static Caisse? depuisJson(Object? j) {
    if (j is! Map) return null;
    double? v(String c) => j[c] is num ? (j[c] as num).toDouble() : null;
    final st = v('st'), tps = v('tps'), tvq = v('tvq');
    if (st == null || tps == null || tvq == null) return null;
    return Caisse(
      sousTotal: st,
      tps: tps,
      tvq: tvq,
      consigne: v('consigne') ?? 0,
    );
  }
}

double _cents(double x) => (x * 100).round() / 100;

// ═══ La mise à jour en ligne (en attente) ═══════════════════════════════════

/// Un petit fichier public (JSON) qui peut ajouter des barèmes :
/// `{"baremes": [{"depuis": "2027-01-01", "tps": 0.05, "tvq": 0.09975}]}`.
/// VIDE tant qu'il n'est pas hébergé : aucune requête réseau (Rhythm n'a pas
/// encore la permission INTERNET).
const String kUrlBaremes = '';

/// Les barèmes lus dans un document reçu (les invraisemblables sautés).
List<Bareme> baremesDepuis(Object? document) => [
  if (document is Map && document['baremes'] is List)
    for (final b in document['baremes'] as List) ?Bareme.depuisJson(b),
];

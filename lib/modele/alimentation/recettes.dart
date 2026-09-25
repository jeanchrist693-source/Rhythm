// lib/modele/alimentation/recettes.dart
//
// Les types des RECETTES (palier 3 de l'Alimentation) :
// - [Ingredient] : un aliment de la base du FCÉN, un de mes produits ou un
//   ingrédient LIBRE (sel, épices : sans valeur nutritive), sa quantité
//   (« 2 × 1 moyen », « 250 ml », « 600 g ») et ce qu'elle apporte — FIGÉ à
//   la saisie, comme le journal : la recette se lit sans la base ;
// - [Recette] : ses moments (déjeuner, dîner, collation, souper — plusieurs
//   à la fois), ce qu'elle donne (portions), ses ingrédients, ses étapes
//   (les minuteurs y sont repérés : `calculs_recettes.dart`), ses temps, sa
//   région (la cuisine d'où elle vient), si elle se congèle, les jours où
//   elle a été cuisinée ;
// - [RepasPrevu] : un repas de la PLANIFICATION — une recette, un de mes
//   produits (une collation achetée) ou « autre chose » (« Souper chez
//   maman »), un jour, un moment, des portions ;
// - [ReglagesRecettes] : les portions d'un repas prévu (le foyer), le
//   rappel de décongélation (la veille, à l'heure choisie), le tri du livre ;
// - [EtatRecettes] et son document pour le dépôt (deux tables —
//   `recettesAlim`, `planAlim` — et les réglages).
// Lecture TOLÉRANTE partout (aucun `as` forcé).

import '../../utils/dates.dart';
import '../modeles.dart';
import 'courses.dart';
import 'nutriments.dart';

/// Change quand le format du document change.
const int kVersionRecettes = 1;

T? _enumeration<T extends Enum>(List<T> valeurs, Object? v) {
  for (final x in valeurs) {
    if (x.name == v) return x;
  }
  return null;
}

double? _d(Object? v) => v is num && v.isFinite ? v.toDouble() : null;

int? _i(Object? v) => v is num && v.isFinite ? v.round() : null;

String? _texte(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

// ═══ L'ingrédient ═══════════════════════════════════════════════════════════

/// D'où vient un ingrédient.
enum SourceIngredient { base, produit, libre }

class Ingredient {
  const Ingredient({
    required this.nom,
    this.source = SourceIngredient.libre,
    this.code,
    this.produitId,
    this.grammes,
    this.nombre,
    this.mesure,
    this.quantite,
    this.nutriments = Nutriments.zero,
  });

  /// Le nom sur la recette, cherché au garde-manger et sur la liste
  /// (« Oignon »).
  final String nom;
  final SourceIngredient source;

  /// Le code du FCÉN (base).
  final int? code;

  /// Le produit (produit).
  final String? produitId;

  /// La quantité en grammes, quand on la connaît.
  final double? grammes;

  /// Le nombre de [mesure] : 2 × « 1 moyen », 1,5 × « 250 ml ».
  final double? nombre;
  final String? mesure;

  /// La quantité d'un ingrédient libre (« 1 boîte », « 2 »).
  final Quantite? quantite;

  /// Ce que la quantité apporte, figé à la saisie.
  final Nutriments nutriments;

  /// Sans valeur nutritive (libre).
  bool get libre => source == SourceIngredient.libre;

  /// Le même ingrédient pour [facteur] fois la recette.
  Ingredient fois(double facteur) => facteur == 1
      ? this
      : Ingredient(
          nom: nom,
          source: source,
          code: code,
          produitId: produitId,
          grammes: grammes == null ? null : grammes! * facteur,
          nombre: nombre == null ? null : nombre! * facteur,
          mesure: mesure,
          quantite: quantite == null
              ? null
              : Quantite(quantite!.valeur * facteur, quantite!.unite),
          nutriments: nutriments * facteur,
        );

  Map<String, dynamic> versJson() => {
    'nom': nom,
    'source': source.name,
    'code': ?code,
    'produit': ?produitId,
    'g': ?grammes,
    'n': ?nombre,
    'mesure': ?mesure,
    'q': ?quantite?.versJson(),
    if (source != SourceIngredient.libre) 'nut': nutriments.versJson(),
  };

  static Ingredient? depuisJson(Object? j) {
    if (j is! Map) return null;
    final nom = _texte(j['nom']);
    if (nom == null) return null;
    final g = _d(j['g']), n = _d(j['n']);
    return Ingredient(
      nom: nom,
      source:
          _enumeration(SourceIngredient.values, j['source']) ??
          SourceIngredient.libre,
      code: _i(j['code']),
      produitId: _texte(j['produit']),
      grammes: g != null && g > 0 ? g : null,
      nombre: n != null && n > 0 ? n : null,
      mesure: _texte(j['mesure']),
      quantite: Quantite.depuisJson(j['q']),
      nutriments: Nutriments.depuisJson(j['nut']),
    );
  }
}

// ═══ La recette ═════════════════════════════════════════════════════════════

/// Des régions (cuisines) proposées au formulaire — et, au palier 4, au
/// générateur de recettes. Une donnée, en français.
const List<String> kRegionsCulinaires = [
  'Québécoise',
  'Haïtienne',
  'Française',
  'Italienne',
  'Méditerranéenne',
  'Libanaise',
  'Marocaine',
  'Ouest-africaine',
  'Mexicaine',
  'Indienne',
  'Chinoise',
  'Japonaise',
  'Thaïlandaise',
  'Vietnamienne',
];

class Recette {
  const Recette({
    required this.id,
    required this.nom,
    required this.creee,
    this.moments = const {},
    this.portions = 4,
    this.ingredients = const [],
    this.etapes = const [],
    this.preparation,
    this.cuisson,
    this.region,
    this.note,
    this.seCongele = false,
    this.cuisinee = const [],
  });

  final String id;
  final String nom;
  final DateTime creee;

  /// Les moments où elle se mange (vide : n'importe quand).
  final Set<MomentRepas> moments;

  /// Ce qu'elle donne.
  final int portions;
  final List<Ingredient> ingredients;

  /// Une étape par entrée.
  final List<String> etapes;

  /// Minutes.
  final int? preparation, cuisson;

  /// La cuisine d'où elle vient (« Québécoise »).
  final String? region;
  final String? note;

  /// Les restes se congèlent bien (cuisine en lot).
  final bool seCongele;

  /// Les jours où elle a été cuisinée, du plus ancien au plus récent.
  final List<DateTime> cuisinee;

  /// Ce que toute la recette apporte.
  Nutriments get total =>
      Nutriments.somme(ingredients.map((i) => i.nutriments));

  /// Ce qu'une portion apporte.
  Nutriments get parPortion => total * (1 / (portions <= 0 ? 1 : portions));

  /// Préparation + cuisson ; `null` si ni l'une ni l'autre n'est connue.
  int? get dureeTotale => preparation == null && cuisson == null
      ? null
      : (preparation ?? 0) + (cuisson ?? 0);

  DateTime? get derniereFois => cuisinee.isEmpty ? null : cuisinee.last;

  bool pour(MomentRepas m) => moments.isEmpty || moments.contains(m);

  Recette copierAvec({
    String? nom,
    Set<MomentRepas>? moments,
    int? portions,
    List<Ingredient>? ingredients,
    List<String>? etapes,
    int? Function()? preparation,
    int? Function()? cuisson,
    String? Function()? region,
    String? Function()? note,
    bool? seCongele,
    List<DateTime>? cuisinee,
  }) => Recette(
    id: id,
    nom: nom ?? this.nom,
    creee: creee,
    moments: moments ?? this.moments,
    portions: portions ?? this.portions,
    ingredients: ingredients ?? this.ingredients,
    etapes: etapes ?? this.etapes,
    preparation: preparation == null ? this.preparation : preparation(),
    cuisson: cuisson == null ? this.cuisson : cuisson(),
    region: region == null ? this.region : region(),
    note: note == null ? this.note : note(),
    seCongele: seCongele ?? this.seCongele,
    cuisinee: cuisinee ?? this.cuisinee,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'creee': creee.toIso8601String(),
    if (moments.isNotEmpty)
      'moments': [
        for (final m in MomentRepas.values)
          if (moments.contains(m)) m.name,
      ],
    'portions': portions,
    'ingredients': [for (final i in ingredients) i.versJson()],
    if (etapes.isNotEmpty) 'etapes': etapes,
    'prep': ?preparation,
    'cuisson': ?cuisson,
    'region': ?region,
    'note': ?note,
    if (seCongele) 'congele': true,
    if (cuisinee.isNotEmpty) 'cuisinee': [for (final d in cuisinee) cleJour(d)],
  };

  static Recette? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], nom = _texte(j['nom']);
    if (id is! String || nom == null) return null;
    final portions = _i(j['portions']);
    int? minutes(String c) {
      final v = _i(j[c]);
      return v != null && v > 0 ? v : null;
    }

    return Recette(
      id: id,
      nom: nom,
      creee: DateTime.tryParse('${j['creee']}') ?? DateTime(2026),
      moments: {
        if (j['moments'] is List)
          for (final m in j['moments'] as List)
            ?_enumeration(MomentRepas.values, m),
      },
      portions: portions != null && portions > 0 ? portions : 4,
      ingredients: [
        if (j['ingredients'] is List)
          for (final i in j['ingredients'] as List) ?Ingredient.depuisJson(i),
      ],
      etapes: [
        if (j['etapes'] is List)
          for (final e in j['etapes'] as List)
            if (e is String && e.trim().isNotEmpty) e,
      ],
      preparation: minutes('prep'),
      cuisson: minutes('cuisson'),
      region: _texte(j['region']),
      note: _texte(j['note']),
      seCongele: j['congele'] == true,
      cuisinee: [
        if (j['cuisinee'] is List)
          for (final c in j['cuisinee'] as List)
            if (c is num) jourDeCle(c.toInt()),
      ]..sort(),
    );
  }
}

// ═══ La planification ═══════════════════════════════════════════════════════

/// Un repas de la semaine : une recette, un produit ou autre chose.
class RepasPrevu {
  const RepasPrevu({
    required this.id,
    required this.jour,
    required this.moment,
    this.recetteId,
    this.produitId,
    this.libre,
    this.portions = 1,
  });

  final String id;

  /// Le jour (minuit).
  final DateTime jour;
  final MomentRepas moment;
  final String? recetteId;
  final String? produitId;

  /// « Souper chez maman », « Restaurant ».
  final String? libre;

  /// Les portions prévues (celles d'une recette, d'un produit).
  final double portions;

  RepasPrevu copierAvec({
    DateTime? jour,
    MomentRepas? moment,
    double? portions,
  }) => RepasPrevu(
    id: id,
    jour: jour ?? this.jour,
    moment: moment ?? this.moment,
    recetteId: recetteId,
    produitId: produitId,
    libre: libre,
    portions: portions ?? this.portions,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'jour': cleJour(jour),
    'moment': moment.name,
    'recette': ?recetteId,
    'produit': ?produitId,
    'libre': ?libre,
    'portions': portions,
  };

  static RepasPrevu? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], jour = j['jour'];
    final moment = _enumeration(MomentRepas.values, j['moment']);
    if (id is! String || jour is! num || moment == null) return null;
    final recette = _texte(j['recette']);
    final produit = _texte(j['produit']);
    final libre = _texte(j['libre']);
    if (recette == null && produit == null && libre == null) return null;
    final p = _d(j['portions']);
    return RepasPrevu(
      id: id,
      jour: jourDeCle(jour.toInt()),
      moment: moment,
      recetteId: recette,
      produitId: produit,
      libre: libre,
      portions: p != null && p > 0 ? p : 1,
    );
  }
}

// ═══ Les réglages ═══════════════════════════════════════════════════════════

/// Le tri du livre de recettes.
enum TriRecettes { recentes, alphabetique, proteines, calories, rapides }

class ReglagesRecettes {
  const ReglagesRecettes({
    this.personnes = 1,
    this.rappelsDecongelation = true,
    this.heureDecongelation = 20 * 60,
    this.tri = TriRecettes.recentes,
  });

  /// Les portions d'un repas prévu, par défaut (le foyer).
  final int personnes;

  /// La veille d'un repas prévu, un rappel pour sortir du congélateur ce
  /// qu'il demande.
  final bool rappelsDecongelation;

  /// Minutes depuis minuit.
  final int heureDecongelation;
  final TriRecettes tri;

  ReglagesRecettes copierAvec({
    int? personnes,
    bool? rappelsDecongelation,
    int? heureDecongelation,
    TriRecettes? tri,
  }) => ReglagesRecettes(
    personnes: personnes ?? this.personnes,
    rappelsDecongelation: rappelsDecongelation ?? this.rappelsDecongelation,
    heureDecongelation: heureDecongelation ?? this.heureDecongelation,
    tri: tri ?? this.tri,
  );

  Map<String, dynamic> versJson() => {
    'personnes': personnes,
    'decongelation': rappelsDecongelation,
    'heure': heureDecongelation,
    'tri': tri.name,
  };

  static ReglagesRecettes depuisJson(Object? j) {
    if (j is! Map) return const ReglagesRecettes();
    final p = _i(j['personnes']);
    final h = _i(j['heure']);
    return ReglagesRecettes(
      personnes: p != null && p > 0 && p <= 12 ? p : 1,
      rappelsDecongelation: j['decongelation'] != false,
      heureDecongelation: h != null && h >= 0 && h < 1440 ? h : 20 * 60,
      tri: _enumeration(TriRecettes.values, j['tri']) ?? TriRecettes.recentes,
    );
  }
}

// ═══ L'état ═════════════════════════════════════════════════════════════════

class EtatRecettes {
  const EtatRecettes({
    this.recettes = const [],
    this.plan = const [],
    this.reglages = const ReglagesRecettes(),
  });

  final List<Recette> recettes;

  /// Les repas prévus, par jour puis par moment.
  final List<RepasPrevu> plan;
  final ReglagesRecettes reglages;

  Recette? recette(String? id) {
    if (id == null) return null;
    for (final r in recettes) {
      if (r.id == id) return r;
    }
    return null;
  }

  RepasPrevu? prevu(String id) {
    for (final p in plan) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Les repas prévus [jour] (et à [moment]).
  List<RepasPrevu> prevusLe(DateTime jour, [MomentRepas? moment]) {
    final j = jourDe(jour);
    return [
      for (final p in plan)
        if (p.jour == j && (moment == null || p.moment == moment)) p,
    ];
  }

  EtatRecettes copierAvec({
    List<Recette>? recettes,
    List<RepasPrevu>? plan,
    ReglagesRecettes? reglages,
  }) => EtatRecettes(
    recettes: recettes ?? this.recettes,
    plan: plan ?? this.plan,
    reglages: reglages ?? this.reglages,
  );

  Map<String, dynamic> versDocument() => {
    'versionRecettes': kVersionRecettes,
    'recettesAlim': [for (final r in recettes) r.versJson()],
    'planAlim': [for (final p in plan) p.versJson()],
    'reglagesRecettes': reglages.versJson(),
  };

  static EtatRecettes depuisDocument(Map<String, dynamic> document) {
    List<T> liste<T>(String cle, T? Function(Object?) lire) => [
      if (document[cle] is List)
        for (final j in document[cle] as List) ?lire(j),
    ];
    return EtatRecettes(
      recettes: liste('recettesAlim', Recette.depuisJson)
        ..sort((a, b) => a.creee.compareTo(b.creee)),
      plan: liste('planAlim', RepasPrevu.depuisJson)
        ..sort((a, b) {
          final d = a.jour.compareTo(b.jour);
          return d != 0 ? d : a.moment.index.compareTo(b.moment.index);
        }),
      reglages: ReglagesRecettes.depuisJson(document['reglagesRecettes']),
    );
  }
}

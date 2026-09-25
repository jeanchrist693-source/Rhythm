// lib/modele/alimentation/correspondance.dart
//
// Ce que l'IA PROPOSE (palier 4 de l'Alimentation) devient de la donnée de
// Rhythm, CHIFFRÉE SUR LE TÉLÉPHONE : l'IA ne donne jamais de calories ni de
// macros — elle nomme les aliments, leur quantité et des MOTS-CLÉS pour la
// base ; chaque aliment est cherché dans le FCÉN (`base_aliments.dart`) et
// ce qu'il apporte vient de la base, comme un ingrédient choisi à la main.
//
// - [IngredientPropose] : « Oignon », 1 unité (gros), 150 g estimés, mots-
//   clés « oignon cru » ; ou LIBRE (sel, poivre, épices, eau : sans valeur
//   nutritive) ;
// - [correspondre] : l'aliment de la base (recherche tolérante : un mot que
//   la base ne connaît pas est laissé de côté, puis les derniers mots
//   tombent tant que rien ne répond) et la QUANTITÉ — une portion du FCÉN
//   quand elle existe (« 2 × 1 gousse », « 1½ × 250 ml » : la densité de
//   la base, pas celle de l'IA), sinon les grammes estimés ; un aliment
//   introuvable devient un ingrédient libre, signalé ([Correspondance.horsBase]) ;
// - [RecetteProposee] : une recette entière (générée ou importée) → une
//   [Recette] du livre, sa région et ses moments vérifiés.
// Lecture TOLÉRANTE partout : un champ absent ou faux est ignoré, jamais
// l'app.

import 'dart:math' as math;

import '../../ia/texte_ia.dart';
import '../modeles.dart';
import 'alimentation.dart';
import 'base_aliments.dart';
import 'calculs_recettes.dart';
import 'courses.dart';
import 'nutriments.dart';
import 'recettes.dart';

double? _nombre(Object? v) {
  if (v is num && v.isFinite && v > 0) return v.toDouble();
  if (v is String) {
    final x = double.tryParse(v.replaceAll(',', '.').trim());
    if (x != null && x.isFinite && x > 0) return x;
  }
  return null;
}

String _majuscule(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ═══ L'ingrédient proposé ═══════════════════════════════════════════════════

/// L'unité d'une quantité proposée : l'IA convertit les cuillères et les
/// tasses en millilitres, les boîtes en ml ou en grammes.
enum UniteProposee { g, ml, unite }

class IngredientPropose {
  const IngredientPropose({
    required this.nom,
    this.quantite,
    this.unite,
    this.taille,
    this.grammes,
    this.recherche,
    this.kcal,
    this.libre = false,
  });

  /// Le nom sur la recette (« Oignon »).
  final String nom;
  final double? quantite;
  final UniteProposee? unite;

  /// Pour une unité : « gros », « moyen », « gousse », « tranche »…
  final String? taille;

  /// Le poids estimé par l'IA : le repli quand la base n'a pas de portion.
  final double? grammes;

  /// Les mots-clés pour la base, en français (« riz blanc cru »).
  final String? recherche;

  /// Les calories estimées par l'IA : JAMAIS affichées ni gardées — elles
  /// départagent seulement les aliments de la base (le bouillon « prêt à
  /// servir » plutôt que « déshydraté »).
  final double? kcal;

  /// Sans valeur nutritive (sel, poivre, épices, eau).
  final bool libre;

  static IngredientPropose? depuisJson(Object? j, {bool francais = true}) {
    if (j is! Map) return null;
    final nom = texteIa(j['nom'], francais: francais);
    if (nom.isEmpty) return null;
    var q = _nombre(j['quantite']);
    UniteProposee? unite;
    switch (motsDe('${j['unite'] ?? ''}').join(' ')) {
      case 'g' || 'gr' || 'gramme' || 'grammes':
        unite = UniteProposee.g;
      case 'kg':
        unite = UniteProposee.g;
        if (q != null) q *= 1000;
      case 'ml' || 'millilitre' || 'millilitres':
        unite = UniteProposee.ml;
      case 'l' || 'litre' || 'litres':
        unite = UniteProposee.ml;
        if (q != null) q *= 1000;
      case 'c a soupe' || 'c soupe' || 'cuillere a soupe' || 'tbsp':
        unite = UniteProposee.ml;
        if (q != null) q *= 15;
      case 'c a the' || 'c the' || 'cuillere a the' || 'tsp':
        unite = UniteProposee.ml;
        if (q != null) q *= 5;
      case 'tasse' || 'tasses' || 'cup' || 'cups':
        unite = UniteProposee.ml;
        if (q != null) q *= 250;
      case 'unite' || 'unites' || 'u' || 'piece' || 'pieces' || 'unit':
        unite = UniteProposee.unite;
    }
    final taille = texteIa(j['taille'], francais: true);
    final recherche = texteIa(j['fcen'] ?? j['recherche'], francais: true);
    return IngredientPropose(
      nom: _majuscule(nom),
      quantite: q,
      unite: unite,
      taille: taille.isEmpty ? null : taille.toLowerCase(),
      grammes: _nombre(j['grammes']),
      recherche: recherche.isEmpty ? null : recherche,
      kcal: _nombre(j['kcal']),
      libre: j['libre'] == true,
    );
  }

  Map<String, dynamic> versJson() => {
    'nom': nom,
    'quantite': ?quantite,
    'unite': ?unite?.name,
    'taille': ?taille,
    'grammes': ?grammes,
    'fcen': ?recherche,
    'kcal': ?kcal,
    if (libre) 'libre': true,
  };
}

// ═══ Trouver l'aliment dans la base ═════════════════════════════════════════

/// Un mot de recherche que la base connaît (il commence un mot d'au moins
/// un aliment) ; mémorisé par base.
final Expando<Map<String, bool>> _vocabulaires = Expando();

bool _connu(BaseAliments base, String mot) =>
    (_vocabulaires[base] ??= {})[mot] ??= base.aliments.any(
      (a) => a.mots.any((w) => w.startsWith(mot)),
    );

/// Les aliments de la base qui peuvent être [p], les meilleurs d'abord.
///
/// La recherche du journal exige TOUS les mots ; ici, un mot manquant
/// coûte sans exclure (« haricots noirs conserve » : la base n'a que des
/// haricots noirs bouillis). La note : les mots du NOM (ce qu'est
/// l'aliment) comptent plus que les autres mots-clés (son état) ; un
/// aliment dont la première partie du nom est entièrement décrite passe
/// devant (« Haricots noirs, bouillis » avant « Haricots à oeil noir,
/// conserve ») ; puis la note de la recherche (aliments courants, déjà
/// mangés, crus, sans marque…).
List<AlimentBase> candidatsPour(
  BaseAliments base,
  IngredientPropose p, {
  Map<int, int> frequents = const {},
  int max = 12,
}) {
  List<String> connus(String? texte) => [
    if (texte != null)
      for (final m in motsRecherche(texte))
        if (_connu(base, m)) m,
  ];
  final identite = connus(p.nom);
  final cles = connus(p.recherche);
  final tous = {...identite, ...cles};
  if (tous.isEmpty) return const [];
  final notes = <(AlimentBase, double)>[];
  for (final a in base.aliments) {
    final trouves = [
      for (final m in tous)
        if (a.mots.any((w) => w.startsWith(m))) m,
    ];
    if (trouves.isEmpty) continue;
    var s = 0.0;
    for (final m in identite) {
      s += trouves.contains(m) ? 40 : -60;
    }
    for (final m in cles) {
      if (trouves.contains(m)) s += 30;
    }
    // Ce qu'est l'aliment (« Haricots noirs ») : combien de ses mots la
    // proposition dit.
    final tete = [
      for (final m in a.tete)
        if (m.isNotEmpty) singulier(m),
    ];
    if (tete.isNotEmpty) {
      s += 60 * tete.where(tous.contains).length / tete.length;
    }
    s += (BaseAliments.note(a, trouves, frequents[a.code] ?? 0) ?? 0) / 2;
    notes.add((a, s));
  }
  notes.sort((x, y) {
    final d = y.$2.compareTo(x.$2);
    return d != 0 ? d : x.$1.nom.length.compareTo(y.$1.nom.length);
  });
  return [for (final (a, _) in notes.take(max)) a];
}

// ═══ La quantité ════════════════════════════════════════════════════════════

/// Les millilitres d'une portion du FCÉN : « 250 ml » ; avec [exacte] à
/// faux, aussi « 60 ml haché ».
double? _mlDe(String libelle, {bool exacte = true}) {
  final m = RegExp(
    exacte ? r'^(\d+(?:[.,]\d+)?) ?ml$' : r'^(\d+(?:[.,]\d+)?) ?ml\b',
  ).firstMatch(libelle.trim());
  final ml = m == null ? null : double.tryParse(m[1]!.replaceAll(',', '.'));
  return ml != null && ml > 0 ? ml : null;
}

String _texteNombre(double x) {
  final arrondi = (x * 10).round() / 10;
  return arrondi == arrondi.roundToDouble() ? '${arrondi.round()}' : '$arrondi';
}

/// La quantité d'un aliment de la base : (grammes, nombre, mesure).
({double grammes, double? nombre, String? mesure})? quantiteDans(
  AlimentBase a,
  IngredientPropose p,
) {
  final q = p.quantite;
  switch (p.unite) {
    case UniteProposee.g when q != null:
      return (grammes: q, nombre: null, mesure: null);
    case UniteProposee.ml when q != null:
      // Les portions « N ml » du FCÉN : la densité de la base. Une portion
      // qui se compte en quarts (« 1½ × 250 ml ») est gardée telle quelle ;
      // sinon « 1 × 100 ml ».
      final enMl = [
        for (final x in a.portions)
          if (_mlDe(x.libelle) case final ml?) (x, ml),
      ];
      final densite = [
        for (final x in a.portions)
          if (_mlDe(x.libelle, exacte: false) case final ml?) x.grammes / ml,
      ].firstOrNull;
      final grammes = densite != null ? q * densite : (p.grammes ?? q);
      (Portion, double)? choisie;
      for (final (x, ml) in enMl) {
        final n = q / ml;
        final quarts = n * 4;
        if (n >= 0.25 &&
            n <= 12 &&
            (quarts - quarts.round()).abs() < 0.02 &&
            (choisie == null || ml > choisie.$2)) {
          choisie = (x, ml);
        }
      }
      if (choisie != null) {
        return (
          grammes: grammes,
          nombre: q / choisie.$2,
          mesure: choisie.$1.libelle,
        );
      }
      return (grammes: grammes, nombre: 1, mesure: '${_texteNombre(q)} ml');
    case UniteProposee.unite when q != null:
      bool compte(Portion x) =>
          x.libelle.startsWith('1 ') &&
          !x.libelle.contains('ml') &&
          !RegExp(r'^1 ?g$').hasMatch(x.libelle);
      final comptes = a.portions.where(compte).toList();
      final t = p.taille == null ? const <String>[] : motsRecherche(p.taille!);
      Portion? portion;
      if (t.isNotEmpty) {
        portion = comptes
            .where((x) => t.every((m) => motsRecherche(x.libelle).contains(m)))
            .firstOrNull;
      }
      portion ??= comptes.where((x) => x.libelle.contains('moyen')).firstOrNull;
      portion ??= comptes.firstOrNull;
      if (portion != null) {
        return (
          grammes: q * portion.grammes,
          nombre: q,
          mesure: portion.libelle,
        );
      }
      final g = p.grammes;
      if (g == null) return null;
      // Sans portion comptée dans la base : l'estimation de l'IA, comptée
      // quand même si l'on sait quoi (« 2 × 1 tranche »).
      return p.taille == null
          ? (grammes: g, nombre: null, mesure: null)
          : (grammes: g, nombre: q, mesure: '1 ${p.taille}');
    default:
      final g = p.grammes;
      return g == null ? null : (grammes: g, nombre: null, mesure: null);
  }
}

// ═══ La correspondance ══════════════════════════════════════════════════════

class Correspondance {
  const Correspondance(this.propose, this.ingredient, this.aliment);

  final IngredientPropose propose;

  /// L'ingrédient tel qu'il entre dans la recette.
  final Ingredient ingredient;

  /// L'aliment de la base ; `null` : libre.
  final AlimentBase? aliment;

  /// Un aliment que la base n'a pas trouvé (ou sans quantité lisible) :
  /// gardé sans valeur nutritive, à préciser à la main.
  bool get horsBase => aliment == null && !propose.libre;

  Nutriments get nutriments => ingredient.nutriments;
}

/// [p] cherché dans la [base] : un ingrédient chiffré par la base, sinon
/// libre.
Correspondance correspondre(
  IngredientPropose p,
  BaseAliments base, {
  Map<int, int> frequents = const {},
}) {
  Correspondance libre() => Correspondance(
    p,
    Ingredient(
      nom: p.nom,
      quantite: switch (p.unite) {
        _ when p.quantite == null => null,
        UniteProposee.g => Quantite(p.quantite!, Unite.g),
        UniteProposee.ml => Quantite(p.quantite!, Unite.ml),
        _ => Quantite(p.quantite!),
      },
    ),
    null,
  );
  if (p.libre) return libre();
  // Le premier candidat qui donne une quantité lisible et, si l'IA a estimé
  // les calories, des calories vraisemblables (à 50 kcal près, ou du simple
  // au double) ; sinon, le plus proche en calories.
  (AlimentBase, ({double grammes, double? nombre, String? mesure}))? choisi;
  var ecartChoisi = double.infinity;
  for (final a in candidatsPour(base, p, frequents: frequents)) {
    final q = quantiteDans(a, p);
    if (q == null || q.grammes <= 0) continue;
    final estime = p.kcal;
    if (estime == null) {
      choisi = (a, q);
      break;
    }
    final kcal = a.pour(q.grammes).kcal;
    if ((kcal - estime).abs() <= 50 ||
        (kcal >= estime / 2 && kcal <= estime * 2)) {
      choisi = (a, q);
      break;
    }
    // Sinon, le plus proche — s'il reste du même ordre (du tiers au
    // triple) : un bouillon ne devient jamais du poulet haché.
    final ecart = (math.log(math.max(kcal, 1) / math.max(estime, 1))).abs();
    if ((ecart < math.log(3) || (kcal - estime).abs() <= 100) &&
        ecart < ecartChoisi) {
      ecartChoisi = ecart;
      choisi = (a, q);
    }
  }
  if (choisi == null) return libre();
  final (a, q) = choisi;
  return Correspondance(
    p,
    Ingredient(
      nom: p.nom,
      source: SourceIngredient.base,
      code: a.code,
      grammes: q.grammes,
      nombre: q.nombre,
      mesure: q.mesure,
      nutriments: a.pour(q.grammes),
    ),
    a,
  );
}

/// L'entrée du journal d'un aliment trouvé dans la base.
EntreeJournal entreeDeCorrespondance(
  Correspondance c, {
  required String id,
  required DateTime jour,
  required MomentRepas moment,
  required DateTime ajoutee,
}) {
  final i = c.ingredient;
  return EntreeJournal(
    id: id,
    jour: jour,
    moment: moment,
    nom: i.nom,
    source: SourceEntree.base,
    code: i.code,
    grammes: i.grammes,
    portions: i.mesure == null ? null : i.nombre,
    portion: i.mesure,
    nutriments: i.nutriments,
    ajoutee: ajoutee,
  );
}

// ═══ Les moments et les régions ═════════════════════════════════════════════

/// Un moment écrit par l'IA (« dejeuner », « souper », « lunch »…).
MomentRepas? momentDe(Object? v) => switch (motsDe('$v').join(' ')) {
  'dejeuner' || 'petit dejeuner' || 'breakfast' => MomentRepas.dejeuner,
  'diner' || 'lunch' => MomentRepas.diner,
  'collation' || 'snack' || 'gouter' => MomentRepas.collation,
  'souper' || 'dinner' || 'supper' => MomentRepas.souper,
  _ => null,
};

Set<MomentRepas> momentsDe(Object? v) => {
  if (v is List)
    for (final x in v) ?momentDe(x)
  else
    ?momentDe(v),
};

/// La région d'une recette proposée, sous son nom de la liste
/// (`kRegionsCulinaires`) : une cuisine (« Sénégalaise ») ou une grande
/// région. Hors de la liste, ou hors de la région [choisie] : la région
/// choisie (ou rien).
String? regionDe(Object? v, {String? choisie}) {
  final r = texteIa(v);
  if (r.isNotEmpty) {
    for (final g in kRegionsCulinaires) {
      final cuisine = g.cuisines.where((c) => memeRegion(c, r)).firstOrNull;
      final nom = cuisine ?? (memeRegion(g.nom, r) ? g.nom : null);
      if (nom != null && (choisie == null || dansLaRegion(nom, choisie))) {
        return nom;
      }
    }
  }
  return choisie;
}

// ═══ La recette proposée ════════════════════════════════════════════════════

class RecetteProposee {
  const RecetteProposee({
    required this.nom,
    this.description,
    this.region,
    this.moments = const {},
    this.portions = 4,
    this.preparation,
    this.cuisson,
    this.seCongele = false,
    this.ingredients = const [],
    this.etapes = const [],
    this.note,
  });

  final String nom;

  /// Une phrase (« Riz rouge au poisson, le plat national du Sénégal. »).
  final String? description;
  final String? region;
  final Set<MomentRepas> moments;
  final int portions;
  final int? preparation, cuisson;
  final bool seCongele;
  final List<IngredientPropose> ingredients;
  final List<String> etapes;
  final String? note;

  /// Lue d'une réponse ; `null` sans nom ou sans ingrédient. La région est
  /// vérifiée ([regionDe]) ; [moment] (celui demandé) est toujours parmi
  /// les moments.
  static RecetteProposee? depuisJson(
    Object? j, {
    bool francais = true,
    String? region,
    MomentRepas? moment,
  }) {
    if (j is! Map) return null;
    final nom = texteIa(j['nom'], francais: francais);
    final ingredients = [
      if (j['ingredients'] is List)
        for (final i in j['ingredients'] as List)
          ?IngredientPropose.depuisJson(i, francais: francais),
    ];
    if (nom.isEmpty || ingredients.isEmpty) return null;
    int? minutes(String cle) {
      final v = _nombre(j[cle]);
      return v == null ? null : math.min(v.round(), 24 * 60);
    }

    final portions = _nombre(j['portions'])?.round() ?? 4;
    final description = texteIa(j['description'], francais: francais);
    final note = texteIa(j['note'], francais: francais);
    return RecetteProposee(
      nom: _majuscule(nom),
      description: description.isEmpty ? null : description,
      region: regionDe(j['region'], choisie: region),
      moments: {...momentsDe(j['moments']), ?moment},
      portions: portions.clamp(1, 24),
      preparation: minutes('preparation'),
      cuisson: minutes('cuisson'),
      seCongele: j['congele'] == true || j['se_congele'] == true,
      ingredients: ingredients,
      etapes: textesIa(j['etapes'], francais: francais),
      note: note.isEmpty ? null : note,
    );
  }

  /// Chaque ingrédient cherché dans la base.
  List<Correspondance> correspondances(
    BaseAliments base, {
    Map<int, int> frequents = const {},
  }) => [
    for (final i in ingredients) correspondre(i, base, frequents: frequents),
  ];

  /// La recette pour le livre.
  Recette versRecette(
    List<Correspondance> ingredients, {
    required String id,
    required DateTime creee,
  }) => Recette(
    id: id,
    nom: nom,
    creee: creee,
    moments: moments,
    portions: portions,
    ingredients: [for (final c in ingredients) c.ingredient],
    etapes: etapes,
    preparation: preparation,
    cuisson: cuisson,
    region: region,
    note: [?description, ?note].join('\n').trim().isEmpty
        ? null
        : [?description, ?note].join('\n'),
    seCongele: seCongele,
  );
}

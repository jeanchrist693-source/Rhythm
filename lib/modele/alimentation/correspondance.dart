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
      libre: j['libre'] == true || _sansValeur(nom),
    );
  }

  static const _motsEau = {
    'eau', 'water', 'bouillante', 'bouillant', 'froide', 'froid', 'chaude', //
    'chaud', 'tiede', 'glacee', 'robinet', 'filtree', 'boiling', 'cold', //
    'hot', 'warm', 'ice', 'tap',
  };

  /// Sans valeur nutritive, même oublié par l'IA : l'eau (la base n'a que
  /// des eaux aromatisées ou vitaminées à lui faire correspondre), la
  /// poudre à pâte et le bicarbonate (la base n'a que des biscuits).
  static bool _sansValeur(String nom) {
    final m = motsRecherche(nom);
    if ((m.contains('eau') || m.contains('water')) &&
        m.every(_motsEau.contains)) {
      return true;
    }
    return const {
      'poudre pate', 'bicarbonate', 'bicarbonate soude', //
      'bicarbonate sodium', 'levure chimique', 'baking powder', 'baking soda',
    }.contains(m.join(' '));
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

/// Le mot [w] d'un aliment de la base EST le mot proposé [m] (au
/// singulier) — au pluriel ou au féminin près (« crue », « oignons »,
/// « choux ») ; pas un autre mot qui commence pareil : « pois » n'est pas
/// « poisson », « ail » pas « aile », « lait » pas « laitue ». (La
/// recherche du journal, elle, prend les débuts de mots : on y tape.)
bool _meme(String w, String m) {
  if (w == m) return true;
  if (m == 'pate' || m.endsWith('s') || m.endsWith('x')) return false;
  if (m.length <= 3) return w == '${m}s';
  return w == '${m}s' || w == '${m}x' || w == '${m}e' || w == '${m}es';
}

/// Ce que l'IA écrit et que le FCÉN dit autrement (mots de recherche, au
/// singulier) : les pois jaunes d'une soupe aux pois sont des pois cassés,
/// un riz basmati un riz blanc à grain long, la pâte d'arachide du beurre
/// d'arachides, la courge butternut une courge d'hiver musquée, les
/// haricots verts des haricots italiens, le chou vert (d'ici) du chou. Dans
/// l'ordre : un mot, puis les expressions qui le contiennent.
const _synonymes = {
  'curry': 'cari',
  'yaourt': 'yogourt',
  'soja': 'soya',
  'caesar': 'cesar',
  'sauce cesar': 'vinaigrette cesar',
  'pois jaune': 'pois casse',
  'riz basmati': 'riz blanc long',
  'riz jasmin': 'riz blanc long',
  'beurre cacahuete': 'beurre arachide',
  'cacahuete': 'arachide',
  'pate arachide': 'beurre arachide',
  'courge butternut': 'courge hiver musquee',
  'butternut': 'musquee',
  'haricot vert': 'haricot italien vert',
  'haricot jaune': 'haricot italien jaune',
  'chou vert': 'chou',
  'chou blanc': 'chou',
  'kale': 'chou vert frise',
  'tortilla ble': 'tortilla farine',
  'coco rapee': 'coco dessechee',
  'coco seche': 'coco dessechee',
  'poulet entier': 'poulet griller viande peau',
  'moutarde dijon': 'sauce moutarde brune',
  'moutarde ancienne': 'sauce moutarde brune',
  'moutarde jaune': 'sauce moutarde jaune',
  'vermicelle riz': 'nouille riz',
  'lait evapore': 'lait concentre',
  'baguette': 'pain francais',
  'bbq': 'barbecue',
  'polenta': 'semoule mais',
  'germe soya': 'germe haricot mungo',
  'feuille nori': 'algue nori',
  'braiser': 'ragout',
  'concentre tomate': 'pate tomate',
  'dressing': 'vinaigrette',
};

/// Les mots de recherche (sans mots vides, au singulier) — sauf « pâtes »,
/// qui reste au pluriel : les PÂTES alimentaires ne sont pas une PÂTE
/// (d'arachide, de tomate, de cari, à pizza) ; un PÂTÉ (sans accents, le
/// même mot) devient « pateviande » ; ce qui suit « sans » ou « non » est
/// laissé de côté (et retenu : [_niesDans]) ; « partiellement écrémé » n'est pas
/// « écrémé » (un seul mot, « partiellementecreme »).
({List<String> mots, List<String> nies}) _lire(String texte) {
  final mots = <String>[], nies = <String>[];
  var nie = false, partiel = false;
  for (final m in motsDe(_pates(texte))) {
    if (m == 'sans' || m == 'non') {
      nie = true;
      continue;
    }
    if (m == 'partiellement') {
      partiel = true;
      continue;
    }
    final x = motsRecherche(m);
    if (x.isEmpty) continue; // un mot vide
    final w = m == 'pates' ? m : x.first;
    if (nie) {
      nies.add(_racine(w));
      nie = false;
    } else {
      mots.add(partiel ? 'partiellement$w' : w);
    }
    partiel = false;
  }
  return (mots: mots, nies: nies);
}

List<String> _normaliser(String texte) => _lire(texte).mots;

/// Ce qu'on retire, sous un seul mot : « non salé » = « sans sel », « non
/// sucrée » = « sans sucre ».
String _racine(String m) => switch (m) {
  'sale' || 'salee' => 'sel',
  'sucree' || 'sucre' => 'sucre',
  _ => m,
};

/// Ce que la proposition dit ne PAS vouloir (« poulet cuisse sans peau »).
List<String> _niesDans(IngredientPropose p) => [
  ..._lire(p.nom).nies,
  if (p.recherche case final r?) ..._lire(r).nies,
];

final _pate = RegExp(
  r'p[âa]t[ée]s?(?![a-zàâäéèêëîïôöùûüç])',
  caseSensitive: false,
);

String _pates(String texte) => texte.replaceAllMapped(
  _pate,
  (m) => m[0]!.toLowerCase().contains('é') ? 'pateviande' : m[0]!,
);

List<String> _mots(String? texte) {
  if (texte == null) return const [];
  var t = ' ${_normaliser(texte).join(' ')} ';
  for (final e in _synonymes.entries) {
    t = t.replaceAll(' ${e.key} ', ' ${e.value} ');
  }
  return [
    for (final m in t.split(' '))
      if (m.isNotEmpty) m,
  ];
}

/// Les ingrédients de base d'une recette, sous leur forme la plus courante
/// (le riz blanc à grain long sec, les pâtes enrichies sèches, la poitrine
/// de poulet sans la peau crue) : ils passent devant les variantes.
const _ingredientsCourants = {4471, 4515, 841};

/// Un produit AROMATISÉ ou en mélange (« Riz, saveur de fromage, mélange
/// sec », « poitrine (glacé au miel) ») : il ne passe devant que si la
/// proposition le demande.
const _aromatises = {
  'saveur', 'saveurs', 'aromatise', 'aromatisee', 'aromatises', 'melange', //
  'assaisonne', 'assaisonnee', 'assaisonnes', 'farci', 'farcie', 'glace', //
  'chocolat', 'vanille', 'caramel', 'erable', 'miel', 'sucree', 'sucrees',
};

/// L'état CRU au sens strict (le FCÉN dit « sec » pour les grains : des
/// raisins secs ne sont pas des raisins crus, ni l'inverse).
const _crusStricts = {'cru', 'crue', 'crus', 'crues'};

/// Une partie de la plante (« Betterave, feuilles », « Pois, germés »,
/// « Épices, graines de moutarde ») : seulement si on l'a demandée.
const _parties = {'feuille', 'germe', 'germee', 'fleur', 'graine', 'pelure'};

/// Une version ALLÉGÉE (« Fromage à la crème, sans gras », « bouillon,
/// réduit en sodium », « bière, légère ») : seulement si on l'a demandée.
const _allegements = {
  'hypocalorique', 'reduit', 'reduite', 'leger', 'legere', 'allege', //
  'allegee', 'dietetique', 'ecreme', 'ecremee',
};
const _retraits = {'gras', 'sel', 'lactose', 'gluten'};
const _legers = {..._allegements, '0', 'light'};

/// Une TRANSFORMATION (« Tomate, conserve, broyée », « riz étuvé »,
/// « betteraves marinées ») : seulement si on l'a demandée.
const _transformes = {
  'broye',
  'broyee',
  'etuve',
  'etuvee',
  'marine',
  'marinee',
  'barre',
  'chapon',
  'soyeux',
  'soyeu', // « soyeux » au singulier
};

/// Les premières parties du FCÉN qui ne disent pas ce qu'est l'aliment
/// (« Épices, cannelle » : de la cannelle ; « Boisson alcoolisée, vin » :
/// du vin — pas du vinaigre) ; en mots de recherche.
const _prefixesVagues = {
  'epice', 'confiserie', 'graine', 'bonbon', 'jus', 'soupe', //
  'huile vegetale', //
  'boisson alcoolisee', //
  'boisson base plante', 'agent levage', 'produit base tomate',
};

/// L'état CRU — que le FCÉN dit « sec » pour les grains, les pâtes et les
/// légumineuses (« Grains céréaliers, riz blanc, grain long, ordinaire,
/// sec ») ; l'IA écrit « riz blanc cru » : c'est le même.
const _crus = {
  'cru', 'crue', 'crus', 'crues', 'sec', 'secs', 'seche', //
  'seches',
};

/// L'état CUIT.
const _cuits = {
  'cuit', 'cuite', 'cuits', 'cuites', 'bouilli', 'bouillie', 'bouillis', //
  'bouillies', 'grille', 'grillee', 'grilles', 'grillees', 'roti', //
  'rotie', 'rotis', 'roties', 'saute', 'sautee', 'sautes', 'sautees', //
  'braise', 'braisee', 'poche', 'pochee', 'four', 'vapeur',
};

/// Ce que dit le NOM d'un ingrédient sans dire ce qu'il est (« Oignon
/// haché », « Épinards frais ») : ces mots ne comptent que dans les
/// mots-clés — un oignon haché est un oignon cru, pas « Oignon, congelé,
/// haché ».
const _preparations = {
  'hache', 'hachee', 'emince', 'eminee', 'tranche', 'tranchee', 'coupe', //
  'coupee', 'cube', 'rape', 'rapee', 'pele', 'pelee', 'broye', 'broyee', //
  'concasse', 'concassee', 'fin', 'fine', 'finement', 'frais', 'fraiche', //
  'morceau', 'julienne', 'moyen', 'moyenne', 'lamelle', 'rondelle', //
  'quartier', 'egoutte', 'egouttee', 'rince', 'rincee', 'pret', 'servir', //
  'branche', 'gousse', 'tige', 'brin', 'botte', 'pincee', 'boite', 'epi', //
  'moulu', 'moulue', 'entier', 'entiere',
};

/// Un nom qui ne dit presque rien sans son complément (« Pâte à pizza »,
/// « Sauce César », « Huile d'olive ») : l'aliment doit porter les deux —
/// la pâte d'amandes n'est pas une pâte à pizza (que la base n'a pas).
const _tetesVagues = {
  'pate', 'sauce', 'jus', 'soupe', 'huile', 'lait', 'farine', 'bouillon', //
  'poudre', 'creme', 'beurre', 'sirop', 'pain', 'feuille',
};

/// Un nom de PRODUIT (« Confiture de fraises », « Yogourt aux fraises ») :
/// l'aliment doit au moins être ce produit — pas des fraises en poudre.
const _tetesProduits = {
  'confiture', 'gelee', 'compote', 'yogourt', 'fromage', 'biscuit', //
  'gateau', 'muffin', 'tarte', 'barre', 'cereale', 'vinaigrette', //
  'trempette', 'tartinade', 'marmelade', 'galette', 'craquelin', //
  'croustille', 'boisson',
};

/// Un mot de recherche que la base connaît (un mot d'au moins un
/// aliment) ; mémorisé par base.
final Expando<Map<String, bool>> _vocabulaires = Expando();

bool _connu(BaseAliments base, String mot) =>
    (_vocabulaires[base] ??= {})[mot] ??= base.aliments.any(
      (a) => _motsDe(a).any((w) => _meme(w, mot)),
    );

/// Ce qu'est l'aliment (« riz blanc » dans « Grains céréaliers, riz blanc,
/// cuit ») : ses mots de recherche, sans ce qui est entre parenthèses (une
/// précision : « Pâtes (spaghetti, macaroni) » sont des pâtes).
List<String> _teteDe(AlimentBase a) {
  final i = a.nom.indexOf('(');
  final avant = i < 0 ? null : motsDe(a.nom.substring(0, i)).toSet();
  final pate = _pates(a.nom).contains('pateviande');
  final t = _normaliser(
    [
      for (final m in a.tete)
        if ((avant == null || avant.contains(m)) && m != 'griller')
          pate && m == 'pate' ? 'pateviande' : m,
    ].join(' '),
  );
  final parties = a.nom.split(',');
  if (parties.length > 1 && _prefixesVagues.contains(t.join(' '))) {
    return _normaliser(parties[1]);
  }
  return t;
}

/// Ce que le NOM de la proposition dit de l'aliment : ses mots que la base
/// connaît, sans l'état ni la préparation.
List<String> _identite(BaseAliments base, IngredientPropose p) => [
  for (final m in _mots(p.nom))
    if (!_crus.contains(m) && !_preparations.contains(m) && _connu(base, m)) m,
];

/// La composition d'un aliment entre parenthèses (« Sauce, arachides
/// (faite à partir de beurre d'arachides, eau et sauce soya) ») : elle ne
/// dit pas ce qu'il est — ce n'est pas de la sauce soya.
final _composition = RegExp(
  r'\((fait|faite|faits|faites)\b[^)]*\)',
  caseSensitive: false,
);

/// Les mots d'un aliment qu'il EST : pas ce qu'il est « sans » (« Poulet,
/// conserve, sans bouillon » n'est pas du bouillon ; ce qu'il est sans :
/// [_niesDe]) ; sa composition entre parenthèses laissée de côté ;
/// « partiellement écrémé » en un mot ; mémorisés.
final Expando<List<String>> _positifs = Expando();
final Expando<List<String>> _niesBase = Expando();

List<String> _motsDe(AlimentBase a) => _positifs[a] ??= () {
  final r = <String>[], nies = <String>[];
  var nie = false, partiel = false;
  String? avant;
  final mots = motsDe(_pates(a.nom.replaceAll(_composition, ' ')));
  for (final w in mots) {
    final prec = avant;
    avant = w;
    if (w == 'sans' || w == 'non') {
      nie = true;
    } else if (w == 'sec' && prec == 'a') {
      r.add('asec'); // « rôties à sec » : pas un état
    } else if (w == 'partiellement') {
      partiel = true;
    } else if (motsRecherche(w).isEmpty) {
      r.add(w); // un mot vide
    } else if (nie) {
      nies.add(_racine(singulier(w)));
      nie = false;
    } else {
      r.add(partiel ? 'partiellement$w' : w);
      partiel = false;
    }
  }
  _niesBase[a] = nies;
  return r;
}();

List<String> _niesDe(AlimentBase a) {
  _motsDe(a);
  return _niesBase[a]!;
}

/// Ce qu'un aliment a « avec » lui (« Tomate, rouge, mûre, conserve avec
/// piments verts » : piment ; l'eau ne compte pas) ; mémorisé.
final Expando<List<String>> _ajouts = Expando();

/// Les mots d'un aliment hors de ses parenthèses ; mémorisés.
final Expando<List<String>> _dehors = Expando();

List<String> _horsParentheses(AlimentBase a) =>
    _dehors[a] ??= motsDe(_pates(a.nom.replaceAll(RegExp(r'\([^)]*\)'), ' ')));

List<String> _avecDe(BaseAliments base, AlimentBase a) => _ajouts[a] ??= () {
  final mots = _horsParentheses(a);
  final aliments = _tetesDeLaBase(base);
  return [
    for (final (i, w) in mots.indexed)
      if (w == 'avec' || w == 'au' || w == 'aux')
        for (final x
            in mots
                .skip(i + 1)
                .takeWhile((x) => x != 'sans' && x != 'avec')
                .take(w == 'avec' ? 3 : 2))
          if (motsRecherche(x) case [
            final m,
          ] when m != 'eau' && aliments.contains(m))
            m,
  ];
}();

/// Les mots qui commencent ce qu'est un aliment de la base (« canneberge »,
/// « poulet », « miel ») : ce qui est un aliment ; mémorisés par base.
final Expando<Set<String>> _tetes = Expando();

Set<String> _tetesDeLaBase(BaseAliments base) => _tetes[base] ??= {
  for (final a in base.aliments)
    if (_teteDe(a) case [final m, ...]) m,
};

/// L'identité d'une proposition ; si son nom est inconnu de la base (une
/// marque : « Pepsi »), celle de ses mots-clés — s'ils sont TOUS connus
/// (« boisson cola »), sinon aucune (« fromage mascarpone » : la base n'a
/// pas de mascarpone).
List<String> _identiteOuMotsCles(BaseAliments base, IngredientPropose p) {
  final nom = _identite(base, p);
  if (nom.isNotEmpty) return nom;
  final cles = [
    for (final m in _mots(p.recherche))
      if (!_crus.contains(m) && !_preparations.contains(m)) m,
  ];
  return cles.isNotEmpty && cles.every((m) => _connu(base, m))
      ? cles
      : const [];
}

bool _porte(AlimentBase a, List<String> mots) =>
    mots.every((m) => _motsDe(a).any((w) => _meme(w, m)));

/// Les aliments de la base qui peuvent être [p], les meilleurs d'abord.
///
/// La recherche du journal exige TOUS les mots ; ici, un mot manquant
/// coûte sans exclure (« haricots noirs conserve » : la base n'a que des
/// haricots noirs bouillis). La note : les mots du NOM (ce qu'est
/// l'aliment) comptent plus que les autres mots-clés (son état) ; un
/// aliment dont la première partie du nom est entièrement décrite passe
/// devant (« Haricots noirs, bouillis » avant « Haricots à oeil noir,
/// conserve ») ; l'ÉTAT demandé (cru — ou sec —, cuit) compte, et
/// l'état contraire coûte cher (le riz d'une recette est cru : pas « riz
/// blanc, cuit à la vapeur ») ; puis la note de la recherche (aliments
/// courants, déjà mangés, crus, sans marque…). Un aliment dont la
/// proposition ne dit pas ce qu'il est (« Curry en poudre », mot que la
/// base ne connaît pas) n'a pas de candidat : « Tomate, poudre » n'en est
/// pas un.
List<AlimentBase> candidatsPour(
  BaseAliments base,
  IngredientPropose p, {
  Map<int, int> frequents = const {},
  int max = 12,
}) {
  final nom = _mots(p.nom), recherche = _mots(p.recherche);
  if ((nom.isEmpty || !_connu(base, nom.first)) &&
      (recherche.isEmpty || !_connu(base, recherche.first))) {
    return const [];
  }
  final proposes = {...nom, ...recherche};
  final cru = proposes.any(_crus.contains);
  final cuit = proposes.any(_cuits.contains);
  final veutCru = proposes.any(_crusStricts.contains);
  final veutSec = proposes.any(
    (m) => _crus.contains(m) && !_crusStricts.contains(m),
  );
  final nies = _niesDans(p);
  final leger = nies.isNotEmpty || proposes.any(_legers.contains);
  final parties = proposes.any(_parties.contains);
  final identite = _identiteOuMotsCles(base, p);
  if (identite.isEmpty &&
      nom.any((m) => !_crus.contains(m) && !_preparations.contains(m))) {
    return const [];
  }
  final cles = [
    for (final m in recherche)
      if (!_crus.contains(m) && _connu(base, m)) m,
  ];
  final tous = {...identite, ...cles};
  if (tous.isEmpty) return const [];
  final notes = <(AlimentBase, double)>[];
  for (final a in base.aliments) {
    final trouves = [
      for (final m in tous)
        if (_motsDe(a).any((w) => _meme(w, m))) m,
    ];
    if (trouves.isEmpty) continue;
    // Au moins la moitié de ce que le nom dit : « Pâte de cari rouge »
    // n'est ni « Épices, cari, poudre » ni une pâte de tomate.
    final dits = identite.where(trouves.contains).length;
    if (dits * 2 < identite.length) continue;
    if (identite.length >= 2 &&
        _tetesVagues.contains(identite.first) &&
        !(trouves.contains(identite[0]) && trouves.contains(identite[1]))) {
      continue;
    }
    if (_tetesProduits.contains(identite.firstOrNull) &&
        !trouves.contains(identite.first)) {
      continue;
    }
    var s = 0.0;
    for (final m in identite) {
      s += trouves.contains(m) ? 40 : -60;
    }
    for (final m in cles) {
      if (trouves.contains(m)) s += 30;
    }
    final mots = _motsDe(a);
    final aCruStrict = mots.any(_crusStricts.contains);
    final aSec = mots.any(
      (w) => _crus.contains(w) && !_crusStricts.contains(w),
    );
    final aCru = aCruStrict || aSec;
    final aCuit = mots.any(_cuits.contains);
    if (cru) {
      final exact = (veutCru && aCruStrict) || (veutSec && aSec);
      s += exact ? 30 : (aCru ? 15 : (aCuit ? -100 : -40));
    }
    if (cuit && aCru && !aCuit) s -= 60;
    if (mots.any(_aromatises.contains) && !proposes.any(_aromatises.contains)) {
      s -= 40;
    }
    if (!parties &&
        _horsParentheses(a).any((w) => _parties.contains(singulier(w)))) {
      s -= 40;
    }
    if (!leger &&
        (mots.any(_allegements.contains) ||
            _niesDe(a).any(_retraits.contains))) {
      s -= 25;
    }
    if (mots.any((w) => _transformes.contains(singulier(w))) &&
        !proposes.any(_transformes.contains)) {
      s -= 20;
    }
    if (nies.any((m) => mots.any((w) => _meme(w, m)))) s -= 40;
    if (_ingredientsCourants.contains(a.code)) s += 30;
    if (_avecDe(base, a).any((m) => !proposes.contains(m))) s -= 30;
    // Ce que l'aliment est SANS et que la proposition veut (« thé glacé
    // sucré » : pas « non sucré »).
    if (_niesDe(a).any(proposes.contains)) s -= 40;
    // … et ce qu'il est sans, comme demandé (« beurre non salé » : « Beurre,
    // sans sel »).
    if (_niesDe(a).any(nies.contains)) s += 30;
    // Ce qu'est l'aliment (« Haricots noirs ») : combien de ses mots la
    // proposition dit.
    final tete = _teteDe(a);
    if (tete.isNotEmpty) {
      s += 60 * tete.where(proposes.contains).length / tete.length;
    }
    s +=
        (BaseAliments.note(a, trouves, frequents[a.code] ?? 0, egal: _meme) ??
            0) /
        2;
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
  // Une quantité en g ou en ml bien plus petite que le poids estimé : l'IA
  // a gardé le nombre de la recette sans le convertir (« 2 » ml pour 2
  // tasses, 500 g estimés) — le poids estimé fait foi.
  final g = p.grammes;
  if (q != null &&
      g != null &&
      q * 3 < g &&
      (p.unite == UniteProposee.g || p.unite == UniteProposee.ml)) {
    return (grammes: g, nombre: null, mesure: null);
  }
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
          !x.libelle.startsWith('1 portion') &&
          !x.libelle.contains('ml') &&
          !RegExp(r'^1 ?g$').hasMatch(x.libelle);
      final comptes = a.portions.where(compte).toList();
      final entiers = [
        for (final x in comptes)
          if (!_partie.hasMatch(x.libelle)) x,
      ];
      final t = p.taille == null ? const <String>[] : motsRecherche(p.taille!);
      Portion? portion;
      if (t.isNotEmpty) {
        portion = comptes
            .where((x) => t.every((m) => motsRecherche(x.libelle).contains(m)))
            .firstOrNull;
      }
      // La taille demandée que la base n'a pas (« 1 moyen » : elle n'a que
      // « 1 gros ») : le poids estimé, compté quand même (« 2 × 1 moyen »).
      if (portion == null && t.isNotEmpty && g != null) {
        return (grammes: g, nombre: q, mesure: '1 ${p.taille}');
      }
      // Sinon l'aliment ENTIER — jamais une partie qu'on n'a pas demandée
      // (« 1 tranche moyenne » pour « 1 oignon »).
      portion ??= entiers.where((x) => x.libelle.contains('moyen')).firstOrNull;
      portion ??= entiers.firstOrNull;
      if (portion == null && g == null) portion = comptes.firstOrNull;
      if (portion != null) {
        return (
          grammes: q * portion.grammes,
          nombre: q,
          mesure: portion.libelle,
        );
      }
      if (g == null) return null;
      // Sans portion comptée dans la base : l'estimation de l'IA, comptée
      // quand même si l'on sait quoi (« 2 × 1 tranche »).
      return p.taille == null
          ? (grammes: g, nombre: null, mesure: null)
          : (grammes: g, nombre: q, mesure: '1 ${p.taille}');
    default:
      return g == null ? null : (grammes: g, nombre: null, mesure: null);
  }
}

/// Une PARTIE d'un aliment dans les portions du FCÉN (« 1 tranche
/// moyenne », « 1 grosse feuille », « 1 gousse ») : elle ne compte un
/// aliment que si l'IA l'a demandée (sa « taille »).
final _partie = RegExp(
  r'^1 (grosses? |petites? |moyennes? )?(gousses?|tranches?|feuilles?|'
  r'branches?|brins?|tiges?|fleurettes?|pinc[ée]es?|rondelles?|anneaux?|'
  r'quartiers?|morceaux?|lani[èe]res?|lamelles?|cubes?|bouch[ée]es?)\b',
);

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
  // au double : l'estimation de l'IA est approximative) ; sinon, le plus proche en calories ; sinon le premier, si
  // la proposition dit tout ce qu'il est — l'estimation de l'IA peut être
  // fausse (2 tasses de pois cassés secs « 170 kcal » : 1 500 dans la
  // base), la base fait foi. Les calories départagent des variantes du
  // MÊME aliment (le bouillon prêt à servir ou déshydraté, la poitrine
  // avec ou sans la peau) : quand le premier porte tout le nom proposé (et
  // l'état cru demandé), une variante a la même tête que lui et le porte
  // aussi — ni des petits pois pour des pois cassés, ni la soupe aux pois
  // cassés pour des pois secs, ni des haricots à oeil noir pour des
  // haricots noirs.
  (AlimentBase, ({double grammes, double? nombre, String? mesure}))? choisi;
  var ecartChoisi = double.infinity;
  final candidats = candidatsPour(base, p, frequents: frequents);
  final identite = _identiteOuMotsCles(base, p);
  final cru = [..._mots(p.nom), ..._mots(p.recherche)].any(_crus.contains);
  bool porte(AlimentBase a) =>
      _porte(a, identite) && (!cru || _motsDe(a).any(_crus.contains));
  final premier = candidats.firstOrNull;
  final tete = premier == null ? '' : _teteDe(premier).join(' ');
  final proposes = {..._mots(p.nom), ..._mots(p.recherche)};
  final fort =
      premier != null &&
      porte(premier) &&
      tete.isNotEmpty &&
      _teteDe(premier).every(proposes.contains);
  final variantes = fort
      ? [
          for (final a in candidats)
            if (porte(a) && _teteDe(a).join(' ') == tete) a,
        ]
      : candidats;
  for (final a in variantes) {
    final q = quantiteDans(a, p);
    if (q == null || q.grammes <= 0) continue;
    final estime = p.kcal;
    if (estime == null) {
      choisi = (a, q);
      break;
    }
    final kcal = a.pour(q.grammes).kcal;
    if (((kcal - estime).abs() <= 50 &&
            kcal >= estime / 3 &&
            kcal <= estime * 3) ||
        (kcal >= estime / 2 && kcal <= estime * 2)) {
      choisi = (a, q);
      break;
    }
    // Sinon, le plus proche — s'il reste du même ordre (du tiers au
    // triple) : un bouillon ne devient jamais du poulet haché.
    final ecart = (math.log(math.max(kcal, 1) / math.max(estime, 1))).abs();
    if (ecart < math.log(3) && ecart < ecartChoisi) {
      ecartChoisi = ecart;
      choisi = (a, q);
    }
  }
  if (choisi == null && candidats.isNotEmpty) {
    final a = candidats.first;
    final q = quantiteDans(a, p);
    final tete = _teteDe(a);
    if (q != null &&
        q.grammes > 0 &&
        tete.isNotEmpty &&
        tete.every(proposes.contains) &&
        _porte(a, identite)) {
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

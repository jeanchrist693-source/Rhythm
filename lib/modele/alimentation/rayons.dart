// lib/modele/alimentation/rayons.dart
//
// Le RAYON d'un article tapé à la main (« Bananes » → fruits, « Savon à
// vaisselle » → entretien) : un dictionnaire d'expressions (le plus
// long / le plus à droite gagne, `expressions.dart`), puis, s'il ne
// reconnaît rien, le groupe du FCÉN de l'aliment le plus proche.
//
// Et la SAISIE d'un article : « 2 kg poulet », « poulet 2 kg », « 6 œufs »,
// « lait x2 », « 500 g de bœuf haché » → le nom et la quantité.

import 'base_aliments.dart';
import 'courses.dart';
import 'expressions.dart';

const Map<Rayon, List<String>> _dictionnaire = {
  Rayon.fruits: [
    'fruit', 'pomme', 'banane', 'orange', 'clementine', 'mandarine', //
    'citron', 'lime', 'pamplemousse', 'fraise', 'framboise', 'bleuet', //
    'mure', 'cerise', 'raisin', 'poire', 'peche', 'nectarine', 'prune', //
    'abricot', 'kiwi', 'mangue', 'ananas', 'melon', 'cantaloup', //
    'pasteque', 'avocat', 'canneberge', 'grenade', 'papaye', 'datte', //
    'rhubarbe', 'petit fruit', 'raisin sec',
  ],
  Rayon.legumes: [
    'legume', 'tomate', 'laitue', 'salade', 'romaine', 'mesclun', //
    'roquette', 'epinard', 'kale', 'chou', 'brocoli', 'chou fleur', //
    'carotte', 'celeri', 'concombre', 'courgette', 'courge', 'citrouille', //
    'poivron', 'piment', 'oignon', 'ail', 'echalote', 'poireau', //
    'pomme de terre', 'patate', 'patate douce', 'champignon', //
    'haricot vert', 'haricot jaune', 'asperge', 'betterave', 'navet', //
    'rutabaga', 'panais', 'radis', 'aubergine', 'mais en epi', 'gingembre', //
    'persil', 'coriandre', 'basilic', 'menthe', 'aneth', 'ciboulette', //
    'fine herbe', 'germe', 'pois mange tout', 'bok choy', 'plateau de legume',
  ],
  Rayon.viandes: [
    'viande', 'poulet', 'dinde', 'boeuf', 'porc', 'veau', 'agneau', //
    'jambon', 'bacon', 'saucisse', 'steak', 'bifteck', 'cotelette', //
    'filet mignon', 'roti', 'charcuterie', 'salami', 'pepperoni', 'creton', //
    'smoked meat', 'hache', 'viande hachee', 'cuisse', 'pilon', 'poitrine', //
    'saucisson', 'prosciutto', 'pastrami', 'bavette', 'surlonge',
  ],
  Rayon.poissons: [
    'poisson', 'saumon', 'truite', 'morue', 'tilapia', 'aiglefin', //
    'crevette', 'petoncle', 'moule', 'homard', 'crabe', 'sushi', 'sole', //
    'goberge', 'fletan', 'dore', 'steak de thon', 'fruit de mer', //
    'saumon fume',
  ],
  Rayon.laitiers: [
    'lait', 'yogourt', 'yaourt', 'fromage', 'beurre', 'creme', 'oeuf', //
    'cheddar', 'mozzarella', 'cottage', 'feta', 'parmesan', 'kefir', //
    'margarine', 'boisson de soya', 'boisson d amande', 'boisson d avoine', //
    'lait d amande', 'creme sure', 'ricotta', 'brie', 'skyr', 'lait vegetal',
  ],
  Rayon.boulangerie: [
    'pain', 'baguette', 'bagel', 'croissant', 'muffin', 'tortilla', //
    'pita', 'brioche', 'gateau', 'tarte', 'beigne', 'naan', 'pain hamburger',
    'pain hot dog', 'muffin anglais', 'danoise', 'chausson',
  ],
  Rayon.cereales: [
    'cereale', 'gruau', 'avoine', 'riz', 'pate', 'spaghetti', 'macaroni', //
    'penne', 'fusilli', 'nouille', 'quinoa', 'couscous', 'boulgour', //
    'orge', 'lasagne', 'vermicelle', 'muesli', 'cereale a dejeuner',
  ],
  Rayon.legumineuses: [
    'legumineuse', 'lentille', 'pois chiche', 'haricot noir', //
    'haricot rouge', 'haricot blanc', 'tofu', 'tempeh', 'edamame', 'noix', //
    'amande', 'arachide', 'cajou', 'pacane', 'noisette', 'pistache', //
    'graine', 'hummus', 'houmous', 'pois casse',
  ],
  Rayon.conserves: [
    'conserve', 'soupe', 'bouillon', 'tomate en conserve', 'tomate en de', //
    'pate de tomate', 'sauce tomate', 'sauce a spaghetti', 'thon', //
    'sardine', 'feve au lard', 'mais en grain', 'lait de coco', //
    'tomate broyee', 'passata',
  ],
  Rayon.condiments: [
    'ketchup', 'moutarde', 'mayonnaise', 'vinaigrette', 'huile', //
    'vinaigre', 'sauce soya', 'sauce', 'relish', 'cornichon', 'olive', //
    'confiture', 'miel', 'sirop', 'sirop d erable', 'beurre d arachide', //
    'tartinade', 'salsa', 'nutella', 'sriracha', 'tahini',
  ],
  Rayon.epices: [
    'epice', 'sel', 'poivre', 'cannelle', 'cumin', 'paprika', 'origan', //
    'farine', 'sucre', 'cassonade', 'poudre a pate', 'bicarbonate', //
    'levure', 'cacao', 'vanille', 'fecule', 'curcuma', 'cari', //
    'pepite de chocolat', 'chocolat a cuisson', 'sucre a glacer', //
    'assaisonnement', 'clou de girofle', 'girofle', 'muscade', 'laurier', //
    'thym', 'piment de cayenne', 'herbes de provence', 'gingembre moulu',
  ],
  Rayon.collations: [
    'croustille', 'chips', 'biscuit', 'craquelin', 'chocolat', 'bonbon', //
    'barre', 'barre tendre', 'mais souffle', 'popcorn', 'bretzel', //
    'gomme', 'jujube', 'reglisse', 'guimauve', 'galette de riz', 'nacho',
    'melange montagnard', 'pouding', 'compote',
  ],
  Rayon.boissons: [
    'jus', 'eau', 'cafe', 'the', 'tisane', 'boisson', 'boisson gazeuse', //
    'liqueur', 'biere', 'vin', 'kombucha', 'cidre', 'eau petillante', //
    'cola', 'boisson energisante',
  ],
  Rayon.surgeles: [
    'surgele', 'congele', 'creme glacee', 'pizza surgelee', 'frite', //
    'sorbet', 'glace', 'popsicle', 'legume surgele', 'fruit surgele', //
    'repas surgele',
  ],
  Rayon.entretien: [
    'savon a vaisselle', 'detergent', 'nettoyant', 'eau de javel', //
    'essuie tout', 'papier essuie tout', 'sac poubelle', 'sac a ordure', //
    'sac a dechet', 'eponge', 'lingette', 'papier aluminium', //
    'pellicule plastique', 'assouplissant', 'lave vaisselle', //
    'savon a lessive', 'sac de congelation', 'sac ziploc', 'papier parchemin',
  ],
  Rayon.hygiene: [
    'papier hygienique', 'papier de toilette', 'mouchoir', 'shampoing', //
    'shampooing', 'revitalisant', 'savon', 'dentifrice', 'brosse a dent', //
    'deodorant', 'rasoir', 'serviette hygienique', 'tampon', 'couche', //
    'creme solaire', 'soie dentaire', 'lotion', 'pansement', 'medicament', //
    'tylenol', 'advil', 'vitamine', 'coton tige', 'rince bouche',
  ],
};

/// Les groupes du FCÉN → un rayon (quand le dictionnaire ne sait pas).
Rayon? rayonDuGroupe(int groupe) => switch (groupe) {
  1 => Rayon.laitiers,
  2 => Rayon.epices,
  4 => Rayon.condiments,
  5 || 7 || 10 || 13 || 17 => Rayon.viandes,
  6 => Rayon.conserves,
  8 || 20 => Rayon.cereales,
  9 => Rayon.fruits,
  11 => Rayon.legumes,
  12 || 16 => Rayon.legumineuses,
  14 => Rayon.boissons,
  15 => Rayon.poissons,
  18 => Rayon.boulangerie,
  19 || 25 => Rayon.collations,
  _ => null,
};

/// Le rayon d'un article tapé : le dictionnaire, puis la base (si elle est
/// chargée), sinon « autre ».
Rayon rayonDe(String nom, [BaseAliments? base]) {
  final r = meilleureExpression(motsSimplifies(nom), [
    for (final e in _dictionnaire.entries) (e.key, e.value),
  ]);
  if (r != null) return r;
  final a = base?.rechercher(nom, max: 1);
  if (a != null && a.isNotEmpty) {
    final g = rayonDuGroupe(a.first.groupe);
    if (g != null) return g;
  }
  return Rayon.autre;
}

// ═══ La saisie ══════════════════════════════════════════════════════════════

Unite? _unite(String? u) {
  if (u == null) return null;
  final x = u.toLowerCase().replaceAll('.', '');
  return switch (x) {
    'kg' || 'kilo' || 'kilos' => Unite.kg,
    'g' || 'gr' || 'grammes' || 'gramme' => Unite.g,
    'lb' || 'lbs' || 'livre' || 'livres' => Unite.lb,
    'ml' => Unite.ml,
    'l' || 'litre' || 'litres' => Unite.l,
    'paquet' ||
    'paquets' ||
    'pqt' ||
    'boite' ||
    'boites' ||
    'boîte' ||
    'boîtes' ||
    'sac' ||
    'sacs' => Unite.paquet,
    'x' || '×' => Unite.unite,
    _ => null,
  };
}

double? _nombre(String s) => switch (s) {
  '½' => 0.5,
  '¼' => 0.25,
  '¾' => 0.75,
  _ => double.tryParse(s.replaceAll(',', '.')),
};

const _motifUnite =
    r'(kg|kilos?|g|gr|grammes?|lbs?|livres?|ml|l|litres?|paquets?|pqt|bo[iî]tes?|sacs?|x|×)';
final _devant = RegExp(
  '^(\\d+(?:[.,]\\d+)?|½|¼|¾)(?:\\s*$_motifUnite\\.?(?=\\s|\$))?\\s+(?:de\\s+|d[\'’]\\s*)?(.+)\$',
  caseSensitive: false,
);
final _derriere = RegExp(
  '^(.+?)\\s+(?:x\\s*)?(\\d+(?:[.,]\\d+)?|½|¼|¾)\\s*$_motifUnite?\\.?\$',
  caseSensitive: false,
);

/// « 2 kg poulet » → (« Poulet », 2 kg) ; « lait x2 » → (« Lait », 2).
(String, Quantite?) lireSaisie(String texte) {
  var t = texte.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return ('', null);
  String nom = t;
  Quantite? q;
  final d = _devant.firstMatch(t);
  final f = _derriere.firstMatch(t);
  if (d != null && d.group(3)!.trim().isNotEmpty) {
    final n = _nombre(d.group(1)!);
    if (n != null && n > 0) {
      q = Quantite(n, _unite(d.group(2)) ?? Unite.unite);
      nom = d.group(3)!.trim();
    }
  } else if (f != null) {
    final n = _nombre(f.group(2)!);
    if (n != null && n > 0) {
      q = Quantite(n, _unite(f.group(3)) ?? Unite.unite);
      nom = f.group(1)!.trim();
    }
  }
  // « lait x2 » : le « x » collé au nom.
  final x = RegExp(r'^(.+?)\s*[x×](\d+)$', caseSensitive: false).firstMatch(t);
  if (q == null && x != null) {
    q = Quantite(double.parse(x.group(2)!));
    nom = x.group(1)!.trim();
  }
  if (nom.isEmpty) nom = t;
  return (nom[0].toUpperCase() + nom.substring(1), q);
}

/// La clé d'un nom, pour reconnaître le même article (« Bananes » =
/// « banane ») : mots simplifiés, sans mots vides, au singulier.
String cleArticle(String nom) => motsRecherche(nom).join(' ');

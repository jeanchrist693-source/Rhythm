// lib/modele/alimentation/conservation.dart
//
// Le GUIDE DE CONSERVATION, hors ligne : pour un aliment rangé, OÙ il se
// garde le mieux, COMBIEN de temps (au frigo à 4 °C, au congélateur à
// −18 °C, à l'armoire ou sur le comptoir ; après ouverture) et COMMENT.
//
// Les durées viennent du THERMOGUIDE du MAPAQ (« Frais c'est meilleur ! »,
// durée d'entreposage des aliments périssables et moins périssables) ; les
// aliments qu'il ne cite pas (banane, avocat, agrumes, pain tranché…)
// suivent les repères usuels. La date proposée prend la durée la plus
// COURTE (prudence) ; l'utilisateur la corrige d'après l'emballage.
//
// Un aliment se reconnaît par des EXPRESSIONS (mots simplifiés, au
// singulier) : la plus longue qui répond gagne (« beurre d'arachide »
// avant « beurre », « pomme de terre » avant « pomme »). Sans rien de
// reconnu : un repère général du rayon.

import 'courses.dart';
import 'expressions.dart';

const int _s = 7, _m = 30, _a = 365;

/// Une durée de conservation, en jours (du plus prudent au plus long).
typedef Duree = (int, int);

class Conservation {
  const Conservation(
    this.expressions,
    this.rayon,
    this.ideal,
    this.conseil, {
    this.frigo,
    this.congelo,
    this.ambiant,
    this.ouvert,
  });

  /// Mots simplifiés, au singulier (« beurre d arachide »).
  final List<String> expressions;
  final Rayon rayon;

  /// Là où il se garde le mieux.
  final Emplacement ideal;
  final String conseil;

  final Duree? frigo;
  final Duree? congelo;

  /// À l'armoire ou sur le comptoir.
  final Duree? ambiant;

  /// Une fois ouvert (au frigo, sauf mention).
  final Duree? ouvert;

  /// La durée à [e] ; `null` : ne s'y garde pas (ou pas de repère).
  Duree? dureeA(Emplacement e) => switch (e) {
    Emplacement.frigo => frigo,
    Emplacement.congelateur => congelo,
    Emplacement.armoire || Emplacement.comptoir => ambiant,
  };
}

// ═══ Le guide ═══════════════════════════════════════════════════════════════

const _f = Emplacement.frigo,
    _c = Emplacement.congelateur,
    _ar = Emplacement.armoire,
    _co = Emplacement.comptoir;

const List<Conservation> kGuideConservation = [
  // ── Viandes ───────────────────────────────────────────────────────────────
  Conservation(
    [
      'viande hachee', 'boeuf hache', 'porc hache', 'poulet hache', //
      'dinde hachee', 'veau hache', 'hache', 'cube de boeuf', //
      'boeuf en cube', 'fondue chinoise', 'viande a fondue',
    ],
    Rayon.viandes,
    _f,
    'Au bas du frigo, sur une assiette (le jus ne coule sur rien). À cuisiner '
    'en 1 ou 2 jours, sinon au congélateur, à plat, en portions.',
    frigo: (1, 2),
    congelo: (3 * _m, 4 * _m),
  ),
  Conservation(
    ['poulet entier', 'dinde entiere', 'volaille entiere'],
    Rayon.viandes,
    _f,
    'Au bas du frigo, dans un plat. Entière, elle se garde 10 à 12 mois au '
    'congélateur.',
    frigo: (1, 3),
    congelo: (10 * _m, 12 * _m),
  ),
  Conservation(
    [
      'poulet', 'dinde', 'volaille', 'poitrine', 'cuisse', 'pilon', //
      'haut de cuisse', 'aile de poulet', 'lanieres de poulet',
    ],
    Rayon.viandes,
    _f,
    'Au bas du frigo, loin de ce qui se mange cru. Cuit dans les 2 jours ou '
    'congelé en portions (6 à 9 mois).',
    frigo: (1, 2),
    congelo: (6 * _m, 9 * _m),
  ),
  Conservation(
    ['poulet roti', 'poulet cuit', 'dinde cuite', 'volaille cuite'],
    Rayon.viandes,
    _f,
    'Au frigo dans les 2 heures, désossé, dans un contenant fermé : 3 à 4 '
    'jours (1 à 2 avec une sauce).',
    frigo: (3, 4),
    congelo: (1 * _m, 3 * _m),
  ),
  Conservation(
    [
      'steak', 'bifteck', 'roti de boeuf', 'boeuf', 'contre filet', //
      'faux filet', 'surlonge', 'bavette', 'entrecote',
    ],
    Rayon.viandes,
    _f,
    'Au bas du frigo, dans son emballage. Pour congeler : bien emballé, sans '
    'air (6 à 12 mois).',
    frigo: (3, 5),
    congelo: (6 * _m, 12 * _m),
  ),
  Conservation(
    ['cotelette', 'roti de porc', 'filet de porc', 'longe', 'porc', 'epaule'],
    Rayon.viandes,
    _f,
    'Au bas du frigo. Au congélateur, bien emballé : 4 à 6 mois.',
    frigo: (3, 5),
    congelo: (4 * _m, 6 * _m),
  ),
  Conservation(
    ['agneau', 'gigot'],
    Rayon.viandes,
    _f,
    'Au bas du frigo ; au congélateur 6 à 9 mois.',
    frigo: (3, 5),
    congelo: (6 * _m, 9 * _m),
  ),
  Conservation(
    ['veau', 'escalope'],
    Rayon.viandes,
    _f,
    'Au bas du frigo ; au congélateur 4 à 8 mois.',
    frigo: (3, 5),
    congelo: (4 * _m, 8 * _m),
  ),
  Conservation(
    ['saucisse', 'merguez', 'chorizo frais'],
    Rayon.viandes,
    _f,
    'Fraîches, elles ne se gardent que 1 à 2 jours : sinon, au congélateur '
    '(2 à 3 mois).',
    frigo: (1, 2),
    congelo: (2 * _m, 3 * _m),
  ),
  Conservation(
    ['saucisson', 'pepperoni', 'salami sec'],
    Rayon.viandes,
    _f,
    'Entier, au frigo 2 à 3 semaines ; une fois tranché, quelques jours, '
    'bien emballé.',
    frigo: (2 * _s, 3 * _s),
  ),
  Conservation(
    ['jambon'],
    Rayon.viandes,
    _f,
    'Tranché : 3 à 5 jours au frigo, bien refermé ; entier et cuit : 7 à 10 '
    'jours.',
    frigo: (3, 5),
    congelo: (1 * _m, 2 * _m),
    ouvert: (3, 5),
  ),
  Conservation(
    ['bacon'],
    Rayon.viandes,
    _f,
    'Ouvert : 7 jours au frigo, bien refermé. Il se congèle en portions.',
    frigo: (7, 7),
    congelo: (1 * _m, 2 * _m),
    ouvert: (7, 7),
  ),
  Conservation(
    [
      'charcuterie', 'viande froide', 'smoked meat', 'mortadelle', //
      'salami', 'viande fumee', 'dinde tranchee', 'poulet tranche', //
      'pastrami', 'prosciutto',
    ],
    Rayon.viandes,
    _f,
    'Fermée, fie-toi à la date de l\'emballage (5 à 6 jours). Ouverte : 3 '
    'jours, bien refermée.',
    frigo: (5, 6),
    congelo: (1 * _m, 2 * _m),
    ouvert: (3, 3),
  ),
  Conservation(
    ['creton'],
    Rayon.viandes,
    _f,
    'Au frigo, couvert : 3 à 5 jours.',
    frigo: (3, 5),
    congelo: (1 * _m, 2 * _m),
  ),
  Conservation(
    ['foie', 'abat', 'rognon', 'coeur de boeuf'],
    Rayon.viandes,
    _f,
    'Très périssables : 1 à 2 jours au frigo, sinon au congélateur.',
    frigo: (1, 2),
    congelo: (3 * _m, 4 * _m),
  ),
  // ── Poissons et fruits de mer ─────────────────────────────────────────────
  Conservation(
    ['saumon', 'truite', 'maquereau', 'sardine fraiche', 'hareng', 'omble'],
    Rayon.poissons,
    _f,
    'Sur la tablette du bas (la plus froide), bien emballé : 1 à 2 jours. '
    'Gras, il rancit vite au congélateur (2 mois).',
    frigo: (1, 2),
    congelo: (2 * _m, 2 * _m),
  ),
  Conservation(
    [
      'tilapia', 'morue', 'aiglefin', 'sole', 'goberge', 'dore', //
      'perchaude', 'fletan', 'poisson blanc', 'poisson', 'filet de poisson',
    ],
    Rayon.poissons,
    _f,
    'Sur la tablette du bas, bien emballé : 2 à 3 jours. Au congélateur : 6 '
    'mois.',
    frigo: (2, 3),
    congelo: (6 * _m, 6 * _m),
  ),
  Conservation(
    ['crevette'],
    Rayon.poissons,
    _f,
    'Crues ou cuites : 1 à 2 jours au frigo. Surgelées, décongèle-les au '
    'frigo la veille (ou sous l\'eau froide).',
    frigo: (1, 2),
    congelo: (2 * _m, 4 * _m),
  ),
  Conservation(
    ['petoncle'],
    Rayon.poissons,
    _f,
    '1 à 2 jours au frigo ; 3 mois au congélateur.',
    frigo: (1, 2),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['moule', 'palourde'],
    Rayon.poissons,
    _f,
    'Vivantes : au frigo dans un contenant aéré, sous un linge humide — '
    'jamais dans l\'eau ni dans un sac fermé.',
    frigo: (2, 3),
  ),
  Conservation(
    ['huitre'],
    Rayon.poissons,
    _f,
    'Vivantes, dans leur écaille : au frigo, contenant aéré, côté bombé en '
    'dessous.',
    frigo: (2 * _s, 3 * _s),
  ),
  Conservation(
    ['crabe', 'homard'],
    Rayon.poissons,
    _f,
    'Cuit : 1 à 2 jours au frigo ; 1 mois au congélateur.',
    frigo: (1, 2),
    congelo: (1 * _m, 1 * _m),
  ),
  Conservation(
    ['saumon fume', 'poisson fume', 'truite fumee'],
    Rayon.poissons,
    _f,
    'Ouvert : 3 à 4 jours au frigo, bien emballé.',
    frigo: (3, 4),
    congelo: (2 * _m, 2 * _m),
    ouvert: (3, 4),
  ),
  Conservation(
    [
      'thon en conserve', 'conserve de thon', 'saumon en conserve', //
      'sardine en conserve', 'thon', 'sardine',
    ],
    Rayon.conserves,
    _ar,
    'Un an à l\'armoire. Ouverte : transvide dans un contenant fermé, au '
    'frigo, 3 à 4 jours.',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (3, 4),
  ),
  // ── Œufs et produits laitiers ─────────────────────────────────────────────
  Conservation(
    ['oeuf'],
    Rayon.laitiers,
    _f,
    'Au frigo, dans leur boîte, sur une tablette — pas dans la porte (trop '
    'de variations de température). Ne les lave pas.',
    frigo: (4 * _s, 1 * _m),
  ),
  Conservation(
    ['oeuf dur', 'oeuf cuit', 'oeuf a la coque'],
    Rayon.laitiers,
    _f,
    'Au frigo, dans leur coquille : une semaine.',
    frigo: (7, 7),
  ),
  Conservation(
    ['lait', 'lait ecreme', 'lait entier', 'lait de vache'],
    Rayon.laitiers,
    _f,
    'Au fond du frigo, pas dans la porte. Fie-toi à la date « meilleur '
    'avant » ; ouvert : 3 à 5 jours. Il se congèle (6 semaines ; secoue-le '
    'après).',
    frigo: (7, 10),
    congelo: (6 * _s, 6 * _s),
    ouvert: (3, 5),
  ),
  Conservation(
    [
      'lait vegetal', 'boisson de soya', 'boisson d amande', //
      'boisson d avoine', 'lait d amande', 'lait de soya', 'lait d avoine', //
      'boisson vegetale',
    ],
    Rayon.laitiers,
    _f,
    'Réfrigérée à l\'achat : au frigo. En boîte longue conservation : à '
    'l\'armoire, puis 7 à 10 jours au frigo une fois ouverte.',
    frigo: (7, 10),
    ambiant: (3 * _m, 6 * _m),
    ouvert: (7, 10),
  ),
  Conservation(
    [
      'creme', 'creme a cuisson', 'creme sure', 'creme fraiche', //
      'creme a fouetter', 'creme de table',
    ],
    Rayon.laitiers,
    _f,
    'Au fond du frigo. Ouverte : 3 à 5 jours ; elle se congèle pour cuisiner '
    '(1 mois).',
    frigo: (3, 5),
    congelo: (1 * _m, 1 * _m),
    ouvert: (3, 5),
  ),
  Conservation(
    ['yogourt', 'yaourt', 'kefir', 'skyr'],
    Rayon.laitiers,
    _f,
    'Au frigo : fermé, 2 à 3 semaines. Entamé, referme-le bien et finis-le '
    'dans quelques jours.',
    frigo: (2 * _s, 3 * _s),
    congelo: (1 * _m, 1 * _m),
    ouvert: (3, 5),
  ),
  Conservation(
    ['beurre', 'margarine'],
    Rayon.laitiers,
    _f,
    'Au frigo, bien emballé (il prend les odeurs) : 3 semaines une fois '
    'ouvert. Salé, il se congèle un an.',
    frigo: (3 * _s, 3 * _s),
    congelo: (3 * _m, 1 * _a),
  ),
  Conservation(
    [
      'fromage', 'cheddar', 'mozzarella', 'gouda', 'suisse', 'emmental', //
      'parmesan', 'fromage en bloc', 'fromage a pate ferme', 'fromage rape', //
      'oka', 'havarti', 'provolone',
    ],
    Rayon.laitiers,
    _f,
    'Emballé dans du papier ciré puis dans un sac : il respire sans sécher '
    '(5 semaines). Il se congèle râpé ou en bloc (6 mois).',
    frigo: (5 * _s, 5 * _s),
    congelo: (6 * _m, 6 * _m),
  ),
  Conservation(
    ['brie', 'camembert', 'fromage a pate molle', 'fromage fin'],
    Rayon.laitiers,
    _f,
    'Dans son papier, dans le bac du frigo : 3 à 4 semaines. Sors-le 30 '
    'minutes avant de le servir.',
    frigo: (3 * _s, 4 * _s),
  ),
  Conservation(
    ['cottage', 'ricotta', 'fromage frais', 'quark', 'mascarpone'],
    Rayon.laitiers,
    _f,
    'Au frigo, couvercle fermé : 3 à 5 jours une fois ouvert.',
    frigo: (3, 5),
    ouvert: (3, 5),
  ),
  Conservation(
    ['fromage a la creme', 'fromage a tartiner', 'fromage fondu', 'feta'],
    Rayon.laitiers,
    _f,
    'Au frigo, bien refermé : 3 à 4 semaines.',
    frigo: (3 * _s, 4 * _s),
  ),
  Conservation(
    ['fromage bleu', 'roquefort', 'gorgonzola'],
    Rayon.laitiers,
    _f,
    'Au frigo, bien emballé à part (il parfume tout) : une semaine.',
    frigo: (7, 7),
  ),
  Conservation(
    ['creme glacee', 'sorbet', 'yogourt glace', 'dessert glace'],
    Rayon.surgeles,
    _c,
    'Au fond du congélateur (pas dans la porte), couvercle bien fermé : 3 '
    'mois.',
    congelo: (3 * _m, 3 * _m),
  ),
  // ── Fruits ────────────────────────────────────────────────────────────────
  Conservation(
    ['banane'],
    Rayon.fruits,
    _co,
    'Sur le comptoir, LOIN des autres fruits : elle dégage de l\'éthylène et '
    'les fait mûrir. Trop mûre ? Pelée, au congélateur pour les smoothies '
    'et les muffins.',
    ambiant: (2, 5),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['avocat'],
    Rayon.fruits,
    _co,
    'Sur le comptoir jusqu\'à ce qu\'il cède sous le doigt, puis au frigo (2 '
    'à 3 jours). Pour le faire mûrir vite : dans un sac de papier avec '
    'une banane.',
    ambiant: (2, 5),
    frigo: (2, 3),
  ),
  Conservation(
    ['pomme', 'pomme mcintosh', 'pomme cortland', 'pomme honeycrisp'],
    Rayon.fruits,
    _f,
    'Au frigo, dans le tiroir, à l\'écart des légumes (elle dégage de '
    'l\'éthylène). À l\'automne, celles du Québec se gardent des mois.',
    frigo: (2 * _s, 6 * _m),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    [
      'poire', 'peche', 'nectarine', 'prune', 'abricot', 'kiwi', 'mangue', //
      'papaye', 'kaki',
    ],
    Rayon.fruits,
    _co,
    'Sur le comptoir jusqu\'à maturité, puis au frigo quelques jours.',
    ambiant: (2, 4),
    frigo: (3, 5),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    [
      'orange', 'clementine', 'mandarine', 'pamplemousse', 'citron', //
      'lime', 'agrume',
    ],
    Rayon.fruits,
    _f,
    'Une semaine sur le comptoir ; au frigo, 2 à 3 semaines. Le zeste se '
    'congèle.',
    frigo: (2 * _s, 3 * _s),
    ambiant: (7, 7),
  ),
  Conservation(
    [
      'fraise', 'framboise', 'mure', 'bleuet', 'petit fruit', 'cerise', //
      'camerise', 'gadelle',
    ],
    Rayon.fruits,
    _f,
    'Au frigo, dans leur contenant, SANS les laver (l\'humidité les fait '
    'moisir) : lave-les juste avant de les manger. Au congélateur : '
    'étalés sur une plaque, puis en sac.',
    frigo: (3, 5),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['canneberge'],
    Rayon.fruits,
    _f,
    'Au frigo : 2 semaines. Elles se congèlent telles quelles, un an.',
    frigo: (2 * _s, 2 * _s),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['raisin'],
    Rayon.fruits,
    _f,
    'Au frigo, non lavés, sur la grappe : 5 jours. Congelés, une friandise '
    'd\'été.',
    frigo: (5, 5),
  ),
  Conservation(
    [
      'raisin sec', 'fruit seche', 'abricot seche', 'datte', //
      'canneberge sechee', 'pruneau', 'figue sechee',
    ],
    Rayon.fruits,
    _ar,
    'Dans un contenant hermétique, à l\'abri de la chaleur : un an.',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['melon', 'cantaloup', 'melon d eau', 'pasteque', 'melon miel'],
    Rayon.fruits,
    _co,
    'Entier, sur le comptoir ; coupé, au frigo sous pellicule : 4 jours.',
    ambiant: (3, 5),
    frigo: (4, 4),
  ),
  Conservation(
    ['ananas'],
    Rayon.fruits,
    _co,
    'Entier, 2 à 3 jours sur le comptoir, tête en bas ; coupé, au frigo 3 à '
    '5 jours.',
    ambiant: (2, 3),
    frigo: (3, 5),
  ),
  Conservation(
    ['rhubarbe'],
    Rayon.fruits,
    _f,
    'Au frigo, dans un sac : 4 jours. Coupée, elle se congèle un an.',
    frigo: (4, 4),
    congelo: (1 * _a, 1 * _a),
  ),
  // ── Légumes ───────────────────────────────────────────────────────────────
  Conservation(
    ['tomate', 'tomate cerise', 'tomate raisin'],
    Rayon.legumes,
    _co,
    'Sur le comptoir, le pédoncule en bas, jusqu\'à ce qu\'elle soit mûre : '
    'le frigo lui fait perdre son goût. Très mûre, au frigo quelques '
    'jours.',
    ambiant: (3, 5),
    frigo: (7, 7),
  ),
  Conservation(
    ['pomme de terre', 'patate', 'grelot'],
    Rayon.legumes,
    _ar,
    'Dans un endroit frais, sombre et aéré (un sac de papier) — JAMAIS au '
    'frigo (elle devient sucrée) et loin des oignons (ils la font germer).',
    ambiant: (7, 3 * _s),
  ),
  Conservation(
    ['patate douce'],
    Rayon.legumes,
    _ar,
    'Au frais et au sec, pas au frigo (le froid durcit son cœur).',
    ambiant: (7, 2 * _s),
  ),
  Conservation(
    ['oignon', 'echalote francaise', 'oignon rouge', 'oignon jaune'],
    Rayon.legumes,
    _ar,
    'Au frais, au sec et à l\'air (pas dans un sac de plastique), loin des '
    'pommes de terre. Coupé : au frigo, dans un contenant fermé.',
    ambiant: (2 * _s, 4 * _s),
    ouvert: (7, 7),
  ),
  Conservation(
    ['oignon vert', 'echalote', 'ciboule'],
    Rayon.legumes,
    _f,
    'Au frigo, dans un sac, ou les racines dans un verre d\'eau : une '
    'semaine.',
    frigo: (7, 7),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['ail'],
    Rayon.legumes,
    _ar,
    'Au sec, à l\'air, à la température de la pièce. Les gousses pelées : '
    'au frigo quelques jours, ou congelées.',
    ambiant: (1 * _m, 3 * _m),
  ),
  Conservation(
    ['carotte', 'carotte nouvelle'],
    Rayon.legumes,
    _f,
    'Au frigo, sans les fanes (elles la dessèchent), dans un sac percé. Les '
    'carottes nouvelles : 2 semaines.',
    frigo: (3 * _s, 3 * _m),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['celeri'],
    Rayon.legumes,
    _f,
    'Au frigo, enroulé dans un linge humide ou du papier d\'aluminium : il '
    'reste croquant.',
    frigo: (2 * _s, 2 * _s),
  ),
  Conservation(
    ['brocoli', 'chou fleur', 'chou de bruxelles'],
    Rayon.legumes,
    _f,
    'Au frigo, dans le tiroir, non lavé, dans un sac ouvert. Blanchi 3 '
    'minutes, il se congèle un an.',
    frigo: (5, 6),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['chou', 'chou rouge', 'chou vert', 'chou nappa', 'bok choy'],
    Rayon.legumes,
    _f,
    'Entier, au frigo : 2 semaines. Entamé, emballé serré.',
    frigo: (2 * _s, 2 * _s),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    [
      'laitue', 'salade', 'romaine', 'mesclun', 'roquette', 'epinard', //
      'bebe epinard', 'kale', 'chou frise', 'bette a carde',
    ],
    Rayon.legumes,
    _f,
    'Au frigo, dans le tiroir, avec un essuie-tout dans le contenant pour '
    'boire l\'humidité. En sac entamé : 3 à 5 jours.',
    frigo: (4, 7),
    ouvert: (3, 5),
  ),
  Conservation(
    ['concombre'],
    Rayon.legumes,
    _f,
    'Au frigo, loin des tomates, bananes et pommes (l\'éthylène le fait '
    'jaunir) : une semaine.',
    frigo: (7, 7),
  ),
  Conservation(
    ['courgette', 'zucchini', 'courge d ete'],
    Rayon.legumes,
    _f,
    'Au frigo, dans le tiroir : une semaine.',
    frigo: (7, 7),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    [
      'courge', 'citrouille', 'courge musquee', 'butternut', //
      'courge spaghetti', 'courge poivree',
    ],
    Rayon.legumes,
    _ar,
    'Entière, au frais et au sec (en chambre froide : 6 mois). Coupée, au '
    'frigo, emballée : 5 jours.',
    ambiant: (7, 6 * _m),
    ouvert: (5, 5),
  ),
  Conservation(
    ['poivron', 'piment'],
    Rayon.legumes,
    _f,
    'Au frigo, dans le tiroir : une semaine. Coupé en lanières, il se '
    'congèle tel quel.',
    frigo: (7, 7),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['champignon'],
    Rayon.legumes,
    _f,
    'Au frigo dans un sac de papier (le plastique les fait suinter). '
    'Brosse-les plutôt que de les laver.',
    frigo: (5, 5),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['haricot vert', 'haricot jaune', 'feve verte'],
    Rayon.legumes,
    _f,
    'Au frigo, dans un sac : 5 à 6 jours. Blanchis, ils se congèlent un an.',
    frigo: (5, 6),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['asperge'],
    Rayon.legumes,
    _f,
    'Debout dans un verre avec un peu d\'eau, au frigo, comme un bouquet : 4 '
    'jours.',
    frigo: (4, 4),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['mais en epi', 'epi de mais', 'mais frais'],
    Rayon.legumes,
    _f,
    'Au frigo, dans ses feuilles : 2 à 3 jours (il perd vite son sucre).',
    frigo: (2, 3),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['betterave'],
    Rayon.legumes,
    _f,
    'Au frigo, sans les feuilles : 3 semaines.',
    frigo: (3 * _s, 3 * _s),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['navet', 'rutabaga', 'panais', 'celeri rave'],
    Rayon.legumes,
    _f,
    'Au frigo, dans le tiroir : une semaine à un mois.',
    frigo: (7, 1 * _m),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['radis'],
    Rayon.legumes,
    _f,
    'Au frigo, sans les fanes : une semaine.',
    frigo: (7, 7),
  ),
  Conservation(
    ['poireau'],
    Rayon.legumes,
    _f,
    'Au frigo, entier : 2 semaines.',
    frigo: (2 * _s, 2 * _s),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['aubergine'],
    Rayon.legumes,
    _f,
    'Au frigo, dans le tiroir : une semaine.',
    frigo: (7, 7),
  ),
  Conservation(
    ['pois mange tout', 'pois sucre', 'petit pois frais'],
    Rayon.legumes,
    _f,
    'Au frigo : 2 jours.',
    frigo: (2, 2),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['germe', 'feve germee', 'luzerne'],
    Rayon.legumes,
    _f,
    'Au frigo : 3 jours au plus. Mange-les cuits si tu es enceinte.',
    frigo: (3, 3),
  ),
  Conservation(
    [
      'fine herbe', 'persil', 'coriandre', 'basilic', 'menthe', 'aneth', //
      'ciboulette', 'thym frais', 'romarin frais',
    ],
    Rayon.legumes,
    _f,
    'Les tiges dans un verre d\'eau, comme un bouquet (le basilic, lui, sur '
    'le comptoir). Hachées dans des bacs à glaçons avec un peu d\'huile : '
    'prêtes à cuisiner.',
    frigo: (4, 7),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['gingembre'],
    Rayon.legumes,
    _f,
    'Au frigo, non pelé, dans un sac. Congelé, il se râpe sans le '
    'décongeler.',
    frigo: (3 * _s, 1 * _m),
    congelo: (6 * _m, 6 * _m),
  ),
  Conservation(
    ['surgele', 'congele', 'legume surgele', 'fruit surgele', 'fruit congele'],
    Rayon.surgeles,
    _c,
    'Au congélateur, sac bien refermé (sans air). Ne recongèle pas ce qui a '
    'décongelé.',
    congelo: (8 * _m, 12 * _m),
  ),
  // ── Boulangerie, céréales ─────────────────────────────────────────────────
  Conservation(
    [
      'pain', 'pain tranche', 'pain de mie', 'pain blanc', 'bagel', //
      'pita', 'tortilla', 'muffin anglais', 'pain hamburger', 'pain hot dog',
      'pain naan',
    ],
    Rayon.boulangerie,
    _ar,
    'À l\'armoire, dans son sac bien fermé — JAMAIS au frigo : il y rassit '
    'plus vite. Congelé tranché, tu sors juste ce qu\'il faut.',
    ambiant: (5, 7),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['baguette', 'pain croute', 'pain artisanal', 'ciabatta'],
    Rayon.boulangerie,
    _co,
    'Dans un sac de papier, sur le comptoir : 1 à 2 jours. Congelée, 10 '
    'minutes au four la font revivre.',
    ambiant: (1, 2),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['gateau a la creme', 'patisserie', 'tarte a la creme', 'eclair'],
    Rayon.boulangerie,
    _f,
    'Avec de la crème ou des œufs : au frigo, 3 à 4 jours.',
    frigo: (3, 4),
    congelo: (1 * _m, 1 * _m),
  ),
  Conservation(
    ['muffin', 'gateau', 'carre', 'croissant', 'beigne', 'tarte aux fruit'],
    Rayon.boulangerie,
    _ar,
    'Dans une boîte fermée : quelques jours. Ils se congèlent très bien.',
    ambiant: (3, 7),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['cereale', 'cereale a dejeuner', 'granola', 'muesli'],
    Rayon.cereales,
    _ar,
    'Le sac intérieur bien roulé ou un contenant hermétique : elles restent '
    'croquantes.',
    ambiant: (6 * _m, 8 * _m),
  ),
  Conservation(
    ['gruau', 'flocon d avoine', 'avoine'],
    Rayon.cereales,
    _ar,
    'Dans un contenant hermétique, au sec : 6 à 10 mois.',
    ambiant: (6 * _m, 10 * _m),
  ),
  Conservation(
    [
      'pate', 'spaghetti', 'macaroni', 'penne', 'fusilli', 'nouille', //
      'linguine', 'lasagne seche', 'vermicelle',
    ],
    Rayon.cereales,
    _ar,
    'Sèches : un an à l\'armoire, dans un contenant fermé (6 mois pour les '
    'pâtes aux œufs).',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['pate cuite', 'pate fraiche', 'gnocchi'],
    Rayon.cereales,
    _f,
    'Cuites, sans sauce : 3 à 5 jours au frigo ; 3 mois congelées.',
    frigo: (3, 5),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['riz', 'quinoa', 'couscous', 'boulgour', 'orge', 'millet'],
    Rayon.cereales,
    _ar,
    'Secs : un an, dans un contenant hermétique, au sec.',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['riz cuit', 'quinoa cuit', 'couscous cuit'],
    Rayon.cereales,
    _f,
    'Au frigo dans l\'heure, en contenant fermé : 5 à 6 jours. Il se congèle '
    'en portions (6 mois).',
    frigo: (5, 6),
    congelo: (6 * _m, 8 * _m),
  ),
  Conservation(
    ['farine'],
    Rayon.epices,
    _ar,
    'Contenant hermétique, au sec (à l\'abri des mites alimentaires). La '
    'farine de blé entier rancit plus vite : au frigo ou au congélateur.',
    ambiant: (1 * _a, 2 * _a),
  ),
  Conservation(
    ['sucre', 'cassonade', 'sucre a glacer'],
    Rayon.epices,
    _ar,
    'Contenant fermé, au sec : il se garde des années. Cassonade durcie ? '
    'Une tranche de pain dans le pot.',
    ambiant: (2 * _a, 2 * _a),
  ),
  Conservation(
    ['poudre a pate', 'bicarbonate', 'levure', 'fecule'],
    Rayon.epices,
    _ar,
    'Au sec, bien fermé : un an.',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['craquelin', 'biscotte', 'galette de riz'],
    Rayon.collations,
    _ar,
    'Le sac bien refermé, au sec : 6 mois.',
    ambiant: (6 * _m, 6 * _m),
    ouvert: (2 * _s, 3 * _s),
  ),
  // ── Légumineuses, tofu, noix ──────────────────────────────────────────────
  Conservation(
    [
      'lentille seche', 'pois chiche sec', 'haricot sec', //
      'legumineuse seche', 'pois casse',
    ],
    Rayon.legumineuses,
    _ar,
    'Sèches : un an dans un contenant hermétique.',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    [
      'lentille', 'pois chiche', 'haricot noir', 'haricot rouge', //
      'legumineuse', 'feve', 'haricot blanc', 'edamame',
    ],
    Rayon.legumineuses,
    _ar,
    'En conserve : un an à l\'armoire. Ouverte, transvide dans un contenant, '
    'au frigo : 3 à 5 jours (cuites maison : 5 jours).',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (3, 5),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['tofu'],
    Rayon.legumineuses,
    _f,
    'Ouvert, couvert d\'eau fraîche changée chaque jour, au frigo : 6 à 7 '
    'jours. Congelé, il devient plus spongieux (parfait pour mariner).',
    frigo: (6, 7),
    congelo: (1 * _m, 2 * _m),
    ouvert: (6, 7),
  ),
  Conservation(
    ['hummus', 'houmous', 'trempette'],
    Rayon.legumineuses,
    _f,
    'Au frigo ; ouvert, 5 à 7 jours, sans y tremper les doigts.',
    frigo: (5, 7),
    ouvert: (5, 7),
  ),
  Conservation(
    [
      'noix', 'amande', 'noix de grenoble', 'pacane', 'noisette', 'cajou', //
      'arachide', 'pistache',
    ],
    Rayon.legumineuses,
    _ar,
    'À l\'abri de la chaleur ; décortiquées, elles rancissent : au frigo ou '
    'au congélateur pour les garder longtemps.',
    ambiant: (3 * _m, 6 * _m),
    frigo: (6 * _m, 1 * _a),
    congelo: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['beurre d arachide', 'beurre d amande', 'beurre de noix', 'tahini'],
    Rayon.condiments,
    _ar,
    'À l\'armoire, 2 mois une fois ouvert. Le naturel (l\'huile se sépare) : '
    'au frigo après ouverture.',
    ambiant: (2 * _m, 2 * _m),
    ouvert: (2 * _m, 2 * _m),
  ),
  Conservation(
    ['graine', 'graine de lin', 'graine de chia', 'graine de citrouille'],
    Rayon.legumineuses,
    _ar,
    'Au sec, bien fermé. Le lin moulu rancit vite : au frigo.',
    ambiant: (6 * _m, 1 * _a),
  ),
  // ── Conserves, condiments ─────────────────────────────────────────────────
  Conservation(
    [
      'conserve', 'en conserve', 'soupe en conserve', 'tomate en conserve', //
      'boite de conserve', 'tomate en de', 'pate de tomate', 'mais en grain',
    ],
    Rayon.conserves,
    _ar,
    'Un an à l\'armoire. Ouverte, jamais dans la boîte : transvide dans un '
    'contenant fermé, au frigo (3 à 4 jours).',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (3, 4),
  ),
  Conservation(
    [
      'ketchup', 'relish', 'marinade', 'cornichon', 'olive', 'sauce soya', //
      'sauce bbq', 'sauce piquante', 'sauce worcestershire', 'sriracha', //
      'sauce hoisin', 'salsa',
    ],
    Rayon.condiments,
    _ar,
    'Fermé : à l\'armoire. Ouvert : au frigo, jusqu\'à un an.',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (6 * _m, 1 * _a),
  ),
  Conservation(
    ['moutarde', 'dijon'],
    Rayon.condiments,
    _ar,
    'Fermée : à l\'armoire. Ouverte : au frigo, 9 mois à un an.',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (9 * _m, 1 * _a),
  ),
  Conservation(
    ['mayonnaise', 'mayo', 'vinaigrette', 'sauce a salade', 'aioli'],
    Rayon.condiments,
    _ar,
    'Fermée : à l\'armoire. Ouverte : au frigo, 2 mois (maison : quelques '
    'jours).',
    ambiant: (6 * _m, 1 * _a),
    ouvert: (2 * _m, 2 * _m),
  ),
  Conservation(
    ['confiture', 'gelee', 'marmelade', 'tartinade', 'nutella'],
    Rayon.condiments,
    _ar,
    'Fermée : un an à l\'armoire. Ouverte : au frigo (la tartinade au '
    'chocolat, elle, reste à l\'armoire).',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (1 * _m, 2 * _m),
  ),
  Conservation(
    ['sirop d erable', 'sirop'],
    Rayon.condiments,
    _ar,
    'Fermé : un an au frais. Ouvert : AU FRIGO (il peut moisir), jusqu\'à un '
    'an ; il se congèle même.',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['miel'],
    Rayon.condiments,
    _ar,
    'À l\'armoire, jamais au frigo (il cristallise). Cristallisé ? Un bain '
    'd\'eau tiède.',
    ambiant: (18 * _m, 18 * _m),
  ),
  Conservation(
    ['huile', 'huile d olive', 'huile vegetale', 'huile de canola'],
    Rayon.condiments,
    _ar,
    'À l\'abri de la lumière et de la chaleur (pas à côté du four) : un an. '
    'Les huiles de lin, de noix ou pressées à froid : au frigo.',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['vinaigre'],
    Rayon.condiments,
    _ar,
    'À l\'armoire : il se garde des années.',
    ambiant: (2 * _a, 2 * _a),
  ),
  Conservation(
    [
      'epice', 'fine herbe sechee', 'cannelle', 'cumin', 'paprika', //
      'origan', 'poivre', 'curcuma', 'cari', 'muscade', 'sel',
    ],
    Rayon.epices,
    _ar,
    'Au sec, bien fermées, loin du four : elles perdent leur goût en un an.',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['cafe', 'cafe moulu', 'cafe en grain'],
    Rayon.boissons,
    _ar,
    'Moulu : un mois une fois ouvert, dans un contenant hermétique, à l\'abri '
    'de la lumière (pas au frigo : il prend l\'humidité et les odeurs).',
    ambiant: (1 * _m, 3 * _m),
    ouvert: (1 * _m, 1 * _m),
  ),
  Conservation(
    ['cafe instantane'],
    Rayon.boissons,
    _ar,
    'Bien fermé, au sec : un an.',
    ambiant: (1 * _a, 1 * _a),
  ),
  Conservation(
    ['the', 'tisane'],
    Rayon.boissons,
    _ar,
    'Dans une boîte fermée, loin des odeurs fortes : 2 ans.',
    ambiant: (2 * _a, 2 * _a),
  ),
  Conservation(
    ['cacao', 'poudre de cacao', 'chocolat a cuisson', 'pepite de chocolat'],
    Rayon.epices,
    _ar,
    'Au frais et au sec : 7 à 12 mois.',
    ambiant: (7 * _m, 10 * _m),
  ),
  // ── Boissons ──────────────────────────────────────────────────────────────
  Conservation(
    ['jus', 'jus d orange', 'jus de pomme', 'jus de legume'],
    Rayon.boissons,
    _f,
    'Réfrigéré : au frigo. En boîte : à l\'armoire jusqu\'à l\'ouverture, '
    'puis 7 à 10 jours au frigo.',
    frigo: (7, 10),
    ouvert: (7, 10),
  ),
  Conservation(
    ['boisson gazeuse', 'liqueur', 'eau petillante', 'eau', 'kombucha'],
    Rayon.boissons,
    _ar,
    'Au frais, à l\'abri de la lumière ; ouverte, au frigo, bien bouchée.',
    ambiant: (6 * _m, 1 * _a),
  ),
  Conservation(
    ['biere', 'vin', 'cidre'],
    Rayon.boissons,
    _ar,
    'Au frais et à l\'abri de la lumière. Le vin ouvert, rebouché, au '
    'frigo : 3 à 5 jours.',
    ambiant: (6 * _m, 1 * _a),
    ouvert: (3, 5),
  ),
  // ── Collations ────────────────────────────────────────────────────────────
  Conservation(
    ['croustille', 'chips', 'nacho', 'mais souffle', 'popcorn', 'bretzel'],
    Rayon.collations,
    _ar,
    'Ouvert, bien refermé (une pince) : une semaine avant de ramollir.',
    ambiant: (2 * _m, 3 * _m),
    ouvert: (7, 7),
  ),
  Conservation(
    ['chocolat', 'bonbon', 'barre de chocolat', 'jujube'],
    Rayon.collations,
    _ar,
    'Au frais et au sec — pas au frigo : le chocolat y blanchit.',
    ambiant: (6 * _m, 1 * _a),
  ),
  Conservation(
    ['barre tendre', 'barre granola', 'barre proteinee'],
    Rayon.collations,
    _ar,
    'À l\'armoire, dans leur boîte : quelques mois.',
    ambiant: (3 * _m, 6 * _m),
  ),
  Conservation(
    ['biscuit'],
    Rayon.collations,
    _ar,
    'Le sac bien fermé ou une boîte en métal : ils restent croquants.',
    ambiant: (2 * _m, 6 * _m),
    ouvert: (2 * _s, 3 * _s),
  ),
  // ── Prêt-à-manger, restes ─────────────────────────────────────────────────
  Conservation(
    [
      'reste', 'mets cuisine', 'plat cuisine', 'ragout', 'casserole', //
      'lasagne', 'pate chinois', 'chili', 'mijote', 'cari maison',
    ],
    Rayon.autre,
    _f,
    'Au frigo dans les 2 heures, en contenants peu profonds : 3 à 4 jours. '
    'Congelés : 3 mois (étiquette avec la date).',
    frigo: (3, 4),
    congelo: (3 * _m, 4 * _m),
  ),
  Conservation(
    ['sandwich', 'wrap', 'sous marin'],
    Rayon.autre,
    _f,
    'Au frigo : 1 à 2 jours.',
    frigo: (1, 2),
    congelo: (6 * _s, 6 * _s),
  ),
  Conservation(
    ['soupe', 'potage', 'bouillon', 'creme de legume'],
    Rayon.conserves,
    _f,
    'Maison : 3 jours au frigo, 2 à 3 mois congelée (laisse de l\'espace '
    'dans le contenant : elle gonfle).',
    frigo: (3, 3),
    congelo: (2 * _m, 3 * _m),
  ),
  Conservation(
    ['sauce a spaghetti', 'sauce a la viande', 'sauce bolognaise'],
    Rayon.conserves,
    _f,
    'Maison : 3 à 5 jours au frigo, 4 à 6 mois congelée.',
    frigo: (3, 5),
    congelo: (4 * _m, 6 * _m),
    ambiant: (1 * _a, 1 * _a),
    ouvert: (3, 5),
  ),
  Conservation(
    ['feve au lard', 'binerie'],
    Rayon.conserves,
    _f,
    'Cuites : 3 à 4 jours au frigo, 6 à 10 mois congelées.',
    frigo: (3, 4),
    congelo: (6 * _m, 10 * _m),
  ),
  Conservation(
    [
      'quiche',
      'pate a la viande',
      'tourtiere',
      'pate au poulet',
      'pate au saumon',
    ],
    Rayon.autre,
    _f,
    'Au frigo : 2 à 3 jours ; congelée : 3 mois.',
    frigo: (2, 3),
    congelo: (3 * _m, 3 * _m),
  ),
  Conservation(
    ['repas surgele', 'pizza surgelee', 'pizza congelee', 'mets congele'],
    Rayon.surgeles,
    _c,
    'Au congélateur : 3 à 4 mois.',
    congelo: (3 * _m, 4 * _m),
  ),
  Conservation(
    ['pizza'],
    Rayon.autre,
    _f,
    'Les restes : au frigo 3 à 4 jours, dans un contenant fermé.',
    frigo: (3, 4),
    congelo: (2 * _m, 2 * _m),
  ),
  Conservation(
    ['sushi', 'poke', 'tartare', 'ceviche'],
    Rayon.poissons,
    _f,
    'Le jour même : le poisson cru ne se garde pas.',
    frigo: (1, 1),
  ),
];

/// Les repères généraux d'un rayon, quand l'aliment n'est pas au guide.
Conservation conservationDuRayon(Rayon r) => switch (r) {
  Rayon.fruits => const Conservation(
    [],
    Rayon.fruits,
    _f,
    'Au frigo, dans le tiroir à fruits, non lavés jusqu\'au moment de les '
    'manger.',
    frigo: (5, 7),
    ambiant: (3, 5),
  ),
  Rayon.legumes => const Conservation(
    [],
    Rayon.legumes,
    _f,
    'Au frigo, dans le tiroir à légumes, dans un sac percé.',
    frigo: (5, 7),
  ),
  Rayon.viandes => const Conservation(
    [],
    Rayon.viandes,
    _f,
    'Au bas du frigo, sur une assiette : 1 à 2 jours, sinon au congélateur.',
    frigo: (1, 2),
    congelo: (3 * _m, 4 * _m),
  ),
  Rayon.poissons => const Conservation(
    [],
    Rayon.poissons,
    _f,
    'Sur la tablette du bas du frigo : 1 à 2 jours, sinon au congélateur.',
    frigo: (1, 2),
    congelo: (2 * _m, 3 * _m),
  ),
  Rayon.laitiers => const Conservation(
    [],
    Rayon.laitiers,
    _f,
    'Au fond du frigo, jamais dans la porte ; fie-toi à la date de '
    'l\'emballage.',
    frigo: (7, 10),
  ),
  Rayon.boulangerie => const Conservation(
    [],
    Rayon.boulangerie,
    _ar,
    'À l\'armoire, bien emballé ; le surplus au congélateur.',
    ambiant: (3, 7),
    congelo: (3 * _m, 3 * _m),
  ),
  Rayon.cereales || Rayon.legumineuses || Rayon.epices => Conservation(
    const [],
    r,
    _ar,
    'Au sec, dans un contenant hermétique, à l\'abri de la chaleur.',
    ambiant: (6 * _m, 1 * _a),
  ),
  Rayon.conserves => const Conservation(
    [],
    Rayon.conserves,
    _ar,
    'À l\'armoire ; ouvert, transvidé dans un contenant, au frigo.',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (3, 4),
  ),
  Rayon.condiments => const Conservation(
    [],
    Rayon.condiments,
    _ar,
    'Fermé : à l\'armoire. Ouvert : au frigo le plus souvent (regarde '
    'l\'étiquette).',
    ambiant: (1 * _a, 1 * _a),
    ouvert: (1 * _m, 6 * _m),
  ),
  Rayon.collations => const Conservation(
    [],
    Rayon.collations,
    _ar,
    'À l\'armoire, bien refermé après ouverture.',
    ambiant: (2 * _m, 6 * _m),
  ),
  Rayon.boissons => const Conservation(
    [],
    Rayon.boissons,
    _ar,
    'Au frais, à l\'abri de la lumière ; ouvert, au frigo.',
    ambiant: (6 * _m, 1 * _a),
    ouvert: (5, 7),
  ),
  Rayon.surgeles => const Conservation(
    [],
    Rayon.surgeles,
    _c,
    'Au congélateur, bien fermé ; ne recongèle pas ce qui a décongelé.',
    congelo: (6 * _m, 12 * _m),
  ),
  Rayon.entretien ||
  Rayon.hygiene ||
  Rayon.autre => Conservation(const [], r, _ar, 'À l\'armoire.'),
};

// ═══ Reconnaître un aliment ═════════════════════════════════════════════════

/// Le repère du guide pour [nom] ; `null` s'il n'y est pas
/// (`expressions.dart` : la plus longue expression gagne, puis la plus à
/// droite — « fromage cottage » → le cottage).
Conservation? guideDe(String nom) => meilleureExpression(motsSimplifies(nom), [
  for (final g in kGuideConservation) (g, g.expressions),
]);

/// Le repère de [nom] : le guide, sinon celui du [rayon].
Conservation conservationDe(String nom, Rayon rayon) =>
    guideDe(nom) ?? conservationDuRayon(rayon);

/// La date proposée pour un aliment rangé [depuis] à [emplacement] (la
/// durée la plus courte : prudence) ; `null` sans repère.
DateTime? peremptionProposee(
  Conservation g,
  Emplacement emplacement,
  DateTime depuis,
) {
  final d = g.dureeA(emplacement);
  if (d == null) return null;
  return DateTime(depuis.year, depuis.month, depuis.day + d.$1);
}

/// Ouvert [le] : la date ne peut que raccourcir.
DateTime? peremptionApresOuverture(
  Conservation g,
  DateTime? actuelle,
  DateTime le,
) {
  final d = g.ouvert;
  if (d == null) return actuelle;
  final ouverte = DateTime(le.year, le.month, le.day + d.$1);
  return actuelle == null || ouverte.isBefore(actuelle) ? ouverte : actuelle;
}

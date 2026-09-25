// lib/modele/alimentation/courses.dart
//
// Les types des ACHATS (palier 2 de l'Alimentation) :
// - [Rayon] : les catégories préintégrées (la liste se trie par rayon, dans
//   l'ordre du magasin ; le garde-manger se range par rayon) — chacune a
//   son emplacement et son statut de taxe par défaut ;
// - [Emplacement] : frigo, congélateur, armoire, comptoir ; un [Lieu]
//   AJOUTÉ (lot 5 : « Congélateur du sous-sol », « Cave ») porte un nom et
//   suit les règles de son genre (l'un des quatre) ;
// - [Quantite] : une valeur et son unité (« 2 kg », « 3 ») ;
// - [ArticleListe] : une ligne de la liste de courses — ses quantités
//   (fusionnées : « 2 + 150 g »), son rayon, d'où elle vient (« pour :
//   chili »), et, une fois au magasin, sa [LignePanier] (prix, poids, taxe,
//   consigne) ;
// - [Achat] : une épicerie terminée (magasin, lignes, taxes, total) —
//   l'historique des prix en vient ;
// - [ArticleGardeManger] : un aliment rangé (où, jusqu'à quand, ouvert le,
//   prix payé, essentiel à racheter) — ou les RESTES d'une recette (en
//   portions) ;
// - [Sortie] : un aliment fini ou jeté (le compteur de gaspillage) ;
// - [ReglagesCourses] : budget du mois, magasins, ordre des rayons,
//   rappels de péremption, lieux ajoutés.
// Lecture TOLÉRANTE partout.

import '../../utils/dates.dart';
import 'conservation.dart';
import 'taxes.dart';

// ═══ Rayons, emplacements, unités ═══════════════════════════════════════════

enum Emplacement { frigo, congelateur, armoire, comptoir }

enum Rayon {
  fruits(Emplacement.frigo, StatutTaxe.detaxe),
  legumes(Emplacement.frigo, StatutTaxe.detaxe),
  viandes(Emplacement.frigo, StatutTaxe.detaxe),
  poissons(Emplacement.frigo, StatutTaxe.detaxe),
  laitiers(Emplacement.frigo, StatutTaxe.detaxe),
  boulangerie(Emplacement.armoire, StatutTaxe.detaxe),
  cereales(Emplacement.armoire, StatutTaxe.detaxe),
  legumineuses(Emplacement.armoire, StatutTaxe.detaxe),
  conserves(Emplacement.armoire, StatutTaxe.detaxe),
  condiments(Emplacement.armoire, StatutTaxe.detaxe),
  epices(Emplacement.armoire, StatutTaxe.detaxe),
  collations(Emplacement.armoire, StatutTaxe.tpsTvq),
  boissons(Emplacement.armoire, StatutTaxe.detaxe),
  surgeles(Emplacement.congelateur, StatutTaxe.detaxe),
  entretien(null, StatutTaxe.tpsTvq),
  hygiene(null, StatutTaxe.tpsTvq),
  autre(Emplacement.armoire, StatutTaxe.detaxe);

  const Rayon(this.emplacement, this.taxe);

  /// Où il se range d'ordinaire ; `null` : pas au garde-manger (entretien,
  /// hygiène).
  final Emplacement? emplacement;

  /// Le statut de taxe le plus courant du rayon (les mots du nom
  /// l'affinent : `taxes.dart`).
  final StatutTaxe taxe;

  bool get alimentaire => emplacement != null;
}

enum Unite {
  unite,
  g,
  kg,
  lb,
  ml,
  l,
  paquet;

  /// Le symbole affiché (« kg ») ; `null` pour une unité (« 3 »).
  String? get symbole => switch (this) {
    Unite.unite => null,
    Unite.g => 'g',
    Unite.kg => 'kg',
    Unite.lb => 'lb',
    Unite.ml => 'ml',
    Unite.l => 'L',
    Unite.paquet => null,
  };

  /// La famille : les quantités d'une même famille s'additionnent.
  FamilleUnite get famille => switch (this) {
    Unite.g || Unite.kg || Unite.lb => FamilleUnite.masse,
    Unite.ml || Unite.l => FamilleUnite.volume,
    Unite.unite => FamilleUnite.compte,
    Unite.paquet => FamilleUnite.paquet,
  };

  /// Vers l'unité de base de la famille (g, ml, 1).
  double get facteur => switch (this) {
    Unite.kg => 1000,
    Unite.lb => 453.592,
    Unite.l => 1000,
    _ => 1,
  };
}

enum FamilleUnite { masse, volume, compte, paquet }

class Quantite {
  const Quantite(this.valeur, [this.unite = Unite.unite]);

  final double valeur;
  final Unite unite;

  /// En unité de base (g, ml, nombre).
  double get base => valeur * unite.facteur;

  /// La somme de deux quantités de la même famille, dans l'unité la plus
  /// lisible (1 500 g → 1,5 kg ; les livres restent des livres).
  Quantite plus(Quantite o) {
    assert(unite.famille == o.unite.famille);
    if (unite == o.unite) return Quantite(valeur + o.valeur, unite);
    final total = base + o.base;
    return Quantite.lisible(total, unite.famille);
  }

  static Quantite lisible(
    double base,
    FamilleUnite famille,
  ) => switch (famille) {
    FamilleUnite.masse =>
      base >= 1000 ? Quantite(base / 1000, Unite.kg) : Quantite(base, Unite.g),
    FamilleUnite.volume =>
      base >= 1000 ? Quantite(base / 1000, Unite.l) : Quantite(base, Unite.ml),
    FamilleUnite.compte => Quantite(base),
    FamilleUnite.paquet => Quantite(base, Unite.paquet),
  };

  Map<String, dynamic> versJson() => {'v': valeur, 'u': unite.name};

  static Quantite? depuisJson(Object? j) {
    if (j is! Map) return null;
    final v = j['v'];
    if (v is! num || v <= 0) return null;
    var u = Unite.unite;
    for (final x in Unite.values) {
      if (x.name == j['u']) u = x;
    }
    return Quantite(v.toDouble(), u);
  }

  @override
  bool operator ==(Object other) =>
      other is Quantite && other.valeur == valeur && other.unite == unite;

  @override
  int get hashCode => Object.hash(valeur, unite);

  @override
  String toString() => '$valeur ${unite.name}';
}

/// Ajoute [q] à [liste] : dans la quantité de la même famille, sinon à la
/// suite (« 2 + 150 g »).
List<Quantite> additionner(List<Quantite> liste, Quantite q) {
  final i = liste.indexWhere((x) => x.unite.famille == q.unite.famille);
  if (i < 0) return [...liste, q];
  return [for (final (k, x) in liste.indexed) k == i ? x.plus(q) : x];
}

T? _enumeration<T extends Enum>(List<T> valeurs, Object? v) {
  for (final x in valeurs) {
    if (x.name == v) return x;
  }
  return null;
}

double? _d(Object? v) => v is num && v.isFinite ? v.toDouble() : null;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

// ═══ La liste ═══════════════════════════════════════════════════════════════

/// Ce qu'un article est devenu au magasin : dans le panier, à ce prix.
class LignePanier {
  const LignePanier({
    required this.prixUnitaire,
    required this.nombre,
    required this.statut,
    this.auPoids = false,
    this.livres = false,
    this.consigneUnitaire = 0,
  });

  /// Le prix d'une unité — ou d'un kilo (d'une livre) si [auPoids].
  final double prixUnitaire;

  /// Le nombre d'unités — ou le poids en kg (en lb) si [auPoids].
  final double nombre;
  final bool auPoids;

  /// Au poids : prix et poids en livres (l'affichage des épiceries).
  final bool livres;
  final StatutTaxe statut;

  /// La consigne d'un contenant (0, 0,10, 0,25 $).
  final double consigneUnitaire;

  /// Le prix de la ligne, avant taxes.
  double get prix => _cents(prixUnitaire * nombre);

  /// La consigne de la ligne (un contenant par unité).
  double get consigne => auPoids ? 0 : _cents(consigneUnitaire * nombre);

  /// Le prix comparable : au kilo si au poids, sinon à l'unité.
  double get prixComparable =>
      auPoids && livres ? prixUnitaire / 0.453592 : prixUnitaire;

  LignePanier copierAvec({
    double? prixUnitaire,
    double? nombre,
    bool? auPoids,
    bool? livres,
    StatutTaxe? statut,
    double? consigneUnitaire,
  }) => LignePanier(
    prixUnitaire: prixUnitaire ?? this.prixUnitaire,
    nombre: nombre ?? this.nombre,
    auPoids: auPoids ?? this.auPoids,
    livres: livres ?? this.livres,
    statut: statut ?? this.statut,
    consigneUnitaire: consigneUnitaire ?? this.consigneUnitaire,
  );

  Map<String, dynamic> versJson() => {
    'pu': prixUnitaire,
    'n': nombre,
    if (auPoids) 'poids': true,
    if (livres) 'lb': true,
    'taxe': statut.name,
    if (consigneUnitaire > 0) 'consigne': consigneUnitaire,
  };

  static LignePanier? depuisJson(Object? j) {
    if (j is! Map) return null;
    final pu = _d(j['pu']), n = _d(j['n']);
    if (pu == null || pu < 0 || n == null || n <= 0) return null;
    return LignePanier(
      prixUnitaire: pu,
      nombre: n,
      auPoids: j['poids'] == true,
      livres: j['lb'] == true,
      statut: _enumeration(StatutTaxe.values, j['taxe']) ?? StatutTaxe.detaxe,
      consigneUnitaire: (_d(j['consigne']) ?? 0).clamp(0, 1).toDouble(),
    );
  }
}

double _cents(double x) => (x * 100).round() / 100;

class ArticleListe {
  const ArticleListe({
    required this.id,
    required this.nom,
    required this.rayon,
    required this.ajoute,
    this.quantites = const [],
    this.origines = const [],
    this.note,
    this.panier,
  });

  final String id;
  final String nom;
  final Rayon rayon;
  final DateTime ajoute;
  final List<Quantite> quantites;

  /// D'où il vient : « Chili », « Réassort »… (pour : chili, omelette).
  final List<String> origines;
  final String? note;

  /// Au magasin : dans le panier, à ce prix ; `null` : pas encore pris.
  final LignePanier? panier;

  bool get auPanier => panier != null;

  ArticleListe copierAvec({
    String? nom,
    Rayon? rayon,
    List<Quantite>? quantites,
    List<String>? origines,
    String? Function()? note,
    LignePanier? Function()? panier,
  }) => ArticleListe(
    id: id,
    nom: nom ?? this.nom,
    rayon: rayon ?? this.rayon,
    ajoute: ajoute,
    quantites: quantites ?? this.quantites,
    origines: origines ?? this.origines,
    note: note == null ? this.note : note(),
    panier: panier == null ? this.panier : panier(),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'rayon': rayon.name,
    'ajoute': ajoute.toIso8601String(),
    if (quantites.isNotEmpty) 'q': [for (final q in quantites) q.versJson()],
    if (origines.isNotEmpty) 'origines': origines,
    'note': ?note,
    'panier': ?panier?.versJson(),
  };

  static ArticleListe? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], nom = j['nom'];
    if (id is! String || nom is! String || nom.trim().isEmpty) return null;
    return ArticleListe(
      id: id,
      nom: nom,
      rayon: _enumeration(Rayon.values, j['rayon']) ?? Rayon.autre,
      ajoute: _date(j['ajoute']) ?? DateTime(2026),
      quantites: [
        if (j['q'] is List)
          for (final q in j['q'] as List) ?Quantite.depuisJson(q),
      ],
      origines: [
        if (j['origines'] is List)
          for (final o in j['origines'] as List)
            if (o is String) o,
      ],
      note: j['note'] is String ? j['note'] as String : null,
      panier: LignePanier.depuisJson(j['panier']),
    );
  }
}

// ═══ Les achats ═════════════════════════════════════════════════════════════

class LigneAchat {
  const LigneAchat({
    required this.nom,
    required this.rayon,
    required this.panier,
    this.quantites = const [],
  });

  final String nom;
  final Rayon rayon;
  final LignePanier panier;
  final List<Quantite> quantites;

  Map<String, dynamic> versJson() => {
    'nom': nom,
    'rayon': rayon.name,
    'panier': panier.versJson(),
    if (quantites.isNotEmpty) 'q': [for (final q in quantites) q.versJson()],
  };

  static LigneAchat? depuisJson(Object? j) {
    if (j is! Map || j['nom'] is! String) return null;
    final p = LignePanier.depuisJson(j['panier']);
    if (p == null) return null;
    return LigneAchat(
      nom: j['nom'] as String,
      rayon: _enumeration(Rayon.values, j['rayon']) ?? Rayon.autre,
      panier: p,
      quantites: [
        if (j['q'] is List)
          for (final q in j['q'] as List) ?Quantite.depuisJson(q),
      ],
    );
  }
}

/// Une épicerie terminée. Les montants sont FIGÉS (le barème peut changer).
class Achat {
  const Achat({
    required this.id,
    required this.date,
    required this.lignes,
    required this.caisse,
    this.magasin,
  });

  final String id;
  final DateTime date;
  final String? magasin;
  final List<LigneAchat> lignes;
  final Caisse caisse;

  Map<String, dynamic> versJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'magasin': ?magasin,
    'lignes': [for (final l in lignes) l.versJson()],
    'caisse': caisse.versJson(),
  };

  static Achat? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], date = _date(j['date']);
    if (id is! String || date == null) return null;
    final caisse = Caisse.depuisJson(j['caisse']);
    if (caisse == null) return null;
    return Achat(
      id: id,
      date: date,
      magasin: j['magasin'] is String ? j['magasin'] as String : null,
      lignes: [
        if (j['lignes'] is List)
          for (final l in j['lignes'] as List) ?LigneAchat.depuisJson(l),
      ],
      caisse: caisse,
    );
  }
}

// ═══ Le garde-manger ════════════════════════════════════════════════════════

class ArticleGardeManger {
  const ArticleGardeManger({
    required this.id,
    required this.nom,
    required this.emplacement,
    required this.rayon,
    required this.entre,
    this.quantite,
    this.peremption,
    this.ouvertLe,
    this.prix,
    this.magasin,
    this.essentiel = false,
    this.recetteId,
    this.lieuId,
  });

  final String id;
  final String nom;

  /// Le genre de l'endroit (ses règles de conservation) — celui du [lieuId]
  /// s'il y en a un.
  final Emplacement emplacement;
  final Rayon rayon;

  /// Le lieu ajouté où il est rangé (« Congélateur du sous-sol ») ; `null` :
  /// l'[emplacement] lui-même.
  final String? lieuId;

  /// Rangé le (acheté, ou ajouté).
  final DateTime entre;
  final Quantite? quantite;

  /// À consommer avant (le jour) ; `null` : pas de date.
  final DateTime? peremption;
  final DateTime? ouvertLe;

  /// Payé, taxes comprises (consigne à part).
  final double? prix;
  final String? magasin;

  /// Fini, il revient seul sur la liste (réassort).
  final bool essentiel;

  /// Les restes de cette recette : [quantite] compte des portions.
  final String? recetteId;

  bool get restes => recetteId != null;

  ArticleGardeManger copierAvec({
    String? nom,
    Emplacement? emplacement,
    Rayon? rayon,
    Quantite? Function()? quantite,
    DateTime? Function()? peremption,
    DateTime? Function()? ouvertLe,
    double? Function()? prix,
    bool? essentiel,
    String? Function()? lieuId,
  }) => ArticleGardeManger(
    id: id,
    nom: nom ?? this.nom,
    emplacement: emplacement ?? this.emplacement,
    rayon: rayon ?? this.rayon,
    entre: entre,
    quantite: quantite == null ? this.quantite : quantite(),
    peremption: peremption == null ? this.peremption : peremption(),
    ouvertLe: ouvertLe == null ? this.ouvertLe : ouvertLe(),
    prix: prix == null ? this.prix : prix(),
    magasin: magasin,
    essentiel: essentiel ?? this.essentiel,
    recetteId: recetteId,
    lieuId: lieuId == null ? this.lieuId : lieuId(),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'ou': emplacement.name,
    'rayon': rayon.name,
    'entre': entre.toIso8601String(),
    'q': ?quantite?.versJson(),
    'peremption': ?peremption?.toIso8601String(),
    'ouvert': ?ouvertLe?.toIso8601String(),
    'prix': ?prix,
    'magasin': ?magasin,
    if (essentiel) 'essentiel': true,
    'recette': ?recetteId,
    'lieu': ?lieuId,
  };

  static ArticleGardeManger? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], nom = j['nom'];
    if (id is! String || nom is! String || nom.trim().isEmpty) return null;
    return ArticleGardeManger(
      id: id,
      nom: nom,
      emplacement:
          _enumeration(Emplacement.values, j['ou']) ?? Emplacement.armoire,
      rayon: _enumeration(Rayon.values, j['rayon']) ?? Rayon.autre,
      entre: _date(j['entre']) ?? DateTime(2026),
      quantite: Quantite.depuisJson(j['q']),
      peremption: _date(j['peremption']),
      ouvertLe: _date(j['ouvert']),
      prix: _d(j['prix']),
      magasin: j['magasin'] is String ? j['magasin'] as String : null,
      essentiel: j['essentiel'] == true,
      recetteId: j['recette'] is String ? j['recette'] as String : null,
      lieuId: j['lieu'] is String ? j['lieu'] as String : null,
    );
  }
}

/// Un emplacement AJOUTÉ : un nom (« Congélateur du sous-sol », « Cave »)
/// et le [genre] dont il suit les règles de conservation.
class Lieu {
  const Lieu({required this.id, required this.nom, required this.genre});

  final String id;
  final String nom;
  final Emplacement genre;

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'genre': genre.name,
  };

  static Lieu? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], nom = j['nom'];
    final genre = _enumeration(Emplacement.values, j['genre']);
    if (id is! String || nom is! String || nom.trim().isEmpty) return null;
    if (genre == null) return null;
    return Lieu(id: id, nom: nom.trim(), genre: genre);
  }
}

/// Un aliment sorti du garde-manger : fini, ou jeté (avec ce qu'il valait).
class Sortie {
  const Sortie({
    required this.id,
    required this.date,
    required this.nom,
    required this.rayon,
    required this.jete,
    this.valeur = 0,
  });

  final String id;
  final DateTime date;
  final String nom;
  final Rayon rayon;
  final bool jete;

  /// Ce que la part jetée avait coûté.
  final double valeur;

  Map<String, dynamic> versJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'nom': nom,
    'rayon': rayon.name,
    if (jete) 'jete': true,
    if (valeur > 0) 'valeur': valeur,
  };

  static Sortie? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], nom = j['nom'], date = _date(j['date']);
    if (id is! String || nom is! String || date == null) return null;
    return Sortie(
      id: id,
      date: date,
      nom: nom,
      rayon: _enumeration(Rayon.values, j['rayon']) ?? Rayon.autre,
      jete: j['jete'] == true,
      valeur: (_d(j['valeur']) ?? 0).clamp(0, 100000).toDouble(),
    );
  }
}

// ═══ Les réglages ═══════════════════════════════════════════════════════════

const List<String> kMagasinsParDefaut = [
  'IGA',
  'Maxi',
  'Metro',
  'Super C',
  'Provigo',
  'Costco',
  'Walmart',
];

class ReglagesCourses {
  const ReglagesCourses({
    this.budgetMois,
    this.magasins = kMagasinsParDefaut,
    this.magasin,
    this.ordreRayons = Rayon.values,
    this.rappelsPeremption = true,
    this.heureRappel = 9 * 60,
    this.lieux = const [],
    this.baremesEnLigne = const [],
    this.baremesVerifies,
  });

  /// Les emplacements ajoutés, dans l'ordre où on les a ajoutés.
  final List<Lieu> lieux;

  /// Les barèmes reçus du fichier en ligne (`kUrlBaremes`), et quand il a
  /// été lu pour la dernière fois.
  final List<Bareme> baremesEnLigne;
  final DateTime? baremesVerifies;

  /// Les barèmes à appliquer : les embarqués, et ceux reçus en ligne.
  List<Bareme> get baremes => baremesEnLigne.isEmpty
      ? kBaremesQuebec
      : [...kBaremesQuebec, ...baremesEnLigne];

  Lieu? lieu(String? id) {
    if (id == null) return null;
    for (final l in lieux) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Le budget d'épicerie du mois ($) ; `null` : aucun.
  final double? budgetMois;
  final List<String> magasins;

  /// Le magasin choisi la dernière fois.
  final String? magasin;

  /// L'ordre des rayons (celui du magasin).
  final List<Rayon> ordreRayons;
  final bool rappelsPeremption;

  /// Minutes depuis minuit.
  final int heureRappel;

  ReglagesCourses copierAvec({
    double? Function()? budgetMois,
    List<String>? magasins,
    String? Function()? magasin,
    List<Rayon>? ordreRayons,
    bool? rappelsPeremption,
    int? heureRappel,
    List<Lieu>? lieux,
    List<Bareme>? baremesEnLigne,
    DateTime? baremesVerifies,
  }) => ReglagesCourses(
    budgetMois: budgetMois == null ? this.budgetMois : budgetMois(),
    magasins: magasins ?? this.magasins,
    magasin: magasin == null ? this.magasin : magasin(),
    ordreRayons: ordreRayons ?? this.ordreRayons,
    rappelsPeremption: rappelsPeremption ?? this.rappelsPeremption,
    heureRappel: heureRappel ?? this.heureRappel,
    lieux: lieux ?? this.lieux,
    baremesEnLigne: baremesEnLigne ?? this.baremesEnLigne,
    baremesVerifies: baremesVerifies ?? this.baremesVerifies,
  );

  Map<String, dynamic> versJson() => {
    'budget': ?budgetMois,
    'magasins': magasins,
    'magasin': ?magasin,
    'rayons': [for (final r in ordreRayons) r.name],
    'rappels': rappelsPeremption,
    'heure': heureRappel,
    if (lieux.isNotEmpty) 'lieux': [for (final l in lieux) l.versJson()],
    if (baremesEnLigne.isNotEmpty)
      'baremes': [for (final b in baremesEnLigne) b.versJson()],
    if (baremesVerifies case final v?) 'baremesVerifies': cleJour(v),
  };

  static ReglagesCourses depuisJson(Object? j) {
    if (j is! Map) return const ReglagesCourses();
    final ordre = <Rayon>[
      if (j['rayons'] is List)
        for (final r in j['rayons'] as List) ?_enumeration(Rayon.values, r),
    ];
    // Un rayon ajouté plus tard se place à la fin.
    for (final r in Rayon.values) {
      if (!ordre.contains(r)) ordre.add(r);
    }
    final budget = _d(j['budget']);
    final heure = j['heure'];
    return ReglagesCourses(
      budgetMois: budget != null && budget > 0 ? budget : null,
      magasins: j['magasins'] is List
          ? [
              for (final m in j['magasins'] as List)
                if (m is String && m.trim().isNotEmpty) m,
            ]
          : kMagasinsParDefaut,
      magasin: j['magasin'] is String ? j['magasin'] as String : null,
      ordreRayons: ordre.toSet().toList(),
      rappelsPeremption: j['rappels'] != false,
      heureRappel: heure is num && heure >= 0 && heure < 1440
          ? heure.toInt()
          : 9 * 60,
      lieux: [
        if (j['lieux'] is List)
          for (final l in j['lieux'] as List) ?Lieu.depuisJson(l),
      ],
      baremesEnLigne: baremesDepuis(j),
      baremesVerifies: j['baremesVerifies'] is int
          ? jourDeCle(j['baremesVerifies'] as int)
          : null,
    );
  }
}

// ═══ L'état ═════════════════════════════════════════════════════════════════

const int kVersionCourses = 1;

class EtatCourses {
  const EtatCourses({
    this.liste = const [],
    this.gardeManger = const [],
    this.achats = const [],
    this.sorties = const [],
    this.reglages = const ReglagesCourses(),
    this.conservations = const {},
  });

  final List<ArticleListe> liste;
  final List<ArticleGardeManger> gardeManger;

  /// Du plus ancien au plus récent.
  final List<Achat> achats;
  final List<Sortie> sorties;
  final ReglagesCourses reglages;

  /// Les repères de conservation APPRIS de l'IA pour des aliments hors du
  /// guide, par clé (`cleConservation`).
  final Map<String, Conservation> conservations;

  ArticleListe? article(String id) {
    for (final a in liste) {
      if (a.id == id) return a;
    }
    return null;
  }

  ArticleGardeManger? enReserve(String id) {
    for (final a in gardeManger) {
      if (a.id == id) return a;
    }
    return null;
  }

  EtatCourses copierAvec({
    List<ArticleListe>? liste,
    List<ArticleGardeManger>? gardeManger,
    List<Achat>? achats,
    List<Sortie>? sorties,
    ReglagesCourses? reglages,
    Map<String, Conservation>? conservations,
  }) => EtatCourses(
    liste: liste ?? this.liste,
    gardeManger: gardeManger ?? this.gardeManger,
    achats: achats ?? this.achats,
    sorties: sorties ?? this.sorties,
    reglages: reglages ?? this.reglages,
    conservations: conservations ?? this.conservations,
  );

  Map<String, dynamic> versDocument() => {
    'versionCourses': kVersionCourses,
    'listeCourses': [for (final a in liste) a.versJson()],
    'gardeManger': [for (final a in gardeManger) a.versJson()],
    'achatsAlim': [for (final a in achats) a.versJson()],
    'sortiesAlim': [for (final s in sorties) s.versJson()],
    'conservationIa': [for (final c in conservations.values) c.versJson()],
    'reglagesCourses': reglages.versJson(),
  };

  static EtatCourses depuisDocument(Map<String, dynamic> document) {
    List<T> liste<T>(String cle, T? Function(Object?) lire) => [
      if (document[cle] is List)
        for (final j in document[cle] as List) ?lire(j),
    ];
    return EtatCourses(
      liste: liste('listeCourses', ArticleListe.depuisJson)
        ..sort((a, b) => a.ajoute.compareTo(b.ajoute)),
      gardeManger: liste('gardeManger', ArticleGardeManger.depuisJson),
      achats: liste('achatsAlim', Achat.depuisJson)
        ..sort((a, b) => a.date.compareTo(b.date)),
      sorties: liste('sortiesAlim', Sortie.depuisJson)
        ..sort((a, b) => a.date.compareTo(b.date)),
      reglages: ReglagesCourses.depuisJson(document['reglagesCourses']),
      conservations: {
        for (final c in liste('conservationIa', Conservation.depuisJson))
          c.expressions.first: c,
      },
    );
  }
}

// lib/modele/alimentation/calculs_recettes.dart
//
// Les RÈGLES des recettes, pures et testées :
// - les ÉTAPES d'un texte (une par ligne, sans numéro) et les MINUTEURS
//   repérés dans une étape (« 5 minutes », « 20 à 25 min » → 20 min,
//   « 1 h 30 », « une demi-heure ») ;
// - la QUANTITÉ d'un ingrédient pour la liste et le garde-manger (« 250 ml »
//   reste des millilitres, « 2 × 1 moyen » se compte, sinon les grammes) ;
// - les BESOINS de recettes pour la liste de courses : additionnés par
//   aliment, MOINS le garde-manger et ce qui est déjà sur la liste (même
//   famille d'unités ; un stock sans quantité, ou compté autrement,
//   couvre) — l'eau n'y va jamais ; ce qui est d'habitude au PLACARD
//   (huile, sauces, épices, en petite quantité) est « à vérifier », pas
//   coché d'emblée ;
// - la SEMAINE : les recettes prévues sur 7 jours, leurs portions, moins les
//   RESTES déjà au frigo, en LOTS d'une demi-recette (3 portions d'une
//   recette de 4 → une recette) ; les ingrédients PARTAGÉS (à préparer en
//   une fois : cuisine en lot) ;
// - le DÉCOMPTE du garde-manger après la cuisine (ce qu'il en restera) ;
// - les RESTES (jusqu'à quand : 3 jours au frigo, 3 mois au congélateur —
//   Thermoguide) ; la DÉCONGÉLATION (ce qu'un repas prévu demande et qui
//   n'est qu'au congélateur) ;
// - les RÉGIONS : une cuisine et sa grande région (« Sénégalaise » est en
//   « Afrique de l'Ouest ») ;
// - le LIVRE : la recherche, le tri ; le lien avec le JOURNAL.

import '../../utils/dates.dart';
import '../modeles.dart';
import 'alimentation.dart';
import 'base_aliments.dart' show motsDe, motsRecherche, simplifier;
import 'calculs_courses.dart';
import 'conservation.dart';
import 'courses.dart';
import 'rayons.dart';
import 'recettes.dart';

// ═══ Les étapes ═════════════════════════════════════════════════════════════

final _numero = RegExp(
  r'^\s*(?:(?:[ée]tape|step)\s*\d+\s*[:.)\-–]?|\d+\s*[.)\-–:]|[-•*–])\s*',
  caseSensitive: false,
);

/// Les étapes d'un texte : une par ligne, sans numéro (« 1. », « 2) »,
/// « - », « • », « Étape 3 : »), sans ligne vide.
List<String> lireEtapes(String texte) => [
  for (final l in texte.split('\n'))
    if (l.replaceFirst(_numero, '').trim() case final e when e.isNotEmpty) e,
];

// ═══ Les minuteurs ══════════════════════════════════════════════════════════

/// Un minuteur repéré dans une étape : où il est écrit et sa durée.
class RepereMinuteur {
  const RepereMinuteur(this.debut, this.fin, this.duree);

  final int debut, fin;
  final Duration duree;

  @override
  String toString() => 'RepereMinuteur($debut, $fin, $duree)';
}

const _nb = r'(\d+(?:[.,]\d+)?)';
const _intervalle = r'(?:\s*(?:à|a|-|–|to)\s*\d+(?:[.,]\d+)?)?';
const _finMot = r'(?![a-zà-ÿ])';

final _heures = RegExp(
  '(?<![\\d.,])$_nb$_intervalle\\s*(?:heures?|hours?|hrs?|h)$_finMot'
  '(?:\\s*(?:et\\s+)?(\\d{1,2})(?!\\d)(?:\\s*(?:minutes?|min|mn)$_finMot)?)?',
  caseSensitive: false,
);
final _minutes = RegExp(
  '(?<![\\d.,])$_nb$_intervalle\\s*(?:minutes?|min|mn)$_finMot',
  caseSensitive: false,
);
final _secondes = RegExp(
  '(?<![\\d.,])$_nb$_intervalle\\s*(?:secondes?|seconds?|sec|s)$_finMot',
  caseSensitive: false,
);
final _enMots = RegExp(
  r'\b(?:une?\s+heure\s+et\s+demie|une?\s+demi-heure|une?\s+heure|une?\s+minute|'
  r'half\s+an\s+hour|an\s+hour|one\s+hour|one\s+minute|a\s+minute)(?![a-zà-ÿ])',
  caseSensitive: false,
);

double _nombre(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

/// Les minuteurs d'une étape, dans l'ordre du texte. Un intervalle
/// (« 20 à 25 minutes ») prend la plus courte : on vérifie tôt.
List<RepereMinuteur> minuteursDans(String etape) {
  final trouves = <RepereMinuteur>[];
  void ajouter(Match m, Duration d) {
    if (d.inSeconds <= 0 || d > const Duration(hours: 24)) return;
    trouves.add(RepereMinuteur(m.start, m.end, d));
  }

  for (final m in _heures.allMatches(etape)) {
    final h = _nombre(m.group(1)!);
    final min = m.group(2) == null ? 0 : int.parse(m.group(2)!);
    ajouter(m, Duration(seconds: (h * 3600).round() + min * 60));
  }
  for (final m in _minutes.allMatches(etape)) {
    ajouter(m, Duration(seconds: (_nombre(m.group(1)!) * 60).round()));
  }
  for (final m in _secondes.allMatches(etape)) {
    ajouter(m, Duration(seconds: _nombre(m.group(1)!).round()));
  }
  for (final m in _enMots.allMatches(etape)) {
    final t = simplifier(m.group(0)!);
    final d = t.contains('demie')
        ? const Duration(minutes: 90)
        : t.contains('demi') || t.contains('half')
        ? const Duration(minutes: 30)
        : t.contains('heure') || t.contains('hour')
        ? const Duration(hours: 1)
        : const Duration(minutes: 1);
    ajouter(m, d);
  }
  // Le plus tôt d'abord ; à égalité, le plus long (« 1 h 30 » plutôt que
  // « 30 ») ; les chevauchements tombent.
  trouves.sort((a, b) {
    final d = a.debut.compareTo(b.debut);
    return d != 0 ? d : b.fin.compareTo(a.fin);
  });
  final resultat = <RepereMinuteur>[];
  for (final r in trouves) {
    if (resultat.isNotEmpty && r.debut < resultat.last.fin) continue;
    resultat.add(r);
  }
  return resultat;
}

// ═══ Les quantités ══════════════════════════════════════════════════════════

final _ml = RegExp(r'^(\d+(?:[.,]\d+)?)\s*ml$', caseSensitive: false);
final _g = RegExp(r'^(\d+(?:[.,]\d+)?)\s*g$', caseSensitive: false);

/// Une mesure sans ses précisions : « 1 moyen (18cm à 20cm long) » →
/// « 1 moyen ».
String mesureCourte(String mesure) {
  final t = mesure.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  return t.isEmpty ? mesure : t;
}

/// Les millilitres d'une mesure (« 250 ml ») ; `null` sinon.
double? mlDe(String mesure) {
  final m = _ml.firstMatch(mesureCourte(mesure));
  return m == null ? null : _nombre(m.group(1)!);
}

/// Les grammes d'une mesure (« 175 g ») ; `null` sinon.
double? gDe(String mesure) {
  final m = _g.firstMatch(mesureCourte(mesure));
  return m == null ? null : _nombre(m.group(1)!);
}

/// Une PARTIE d'un aliment (« 1 gousse » d'ail, « 1 tranche » de pain) :
/// elle se compte dans la recette, pas au magasin.
final _partie = RegExp(
  r'^1 (gousses?|tranches?|feuilles?|branches?|brins?|tiges?|fleurettes?|pinc[ée]es?)\b',
  caseSensitive: false,
);

/// Une mesure qui se COMPTE (« 1 moyen », « 1 gousse », « 1 cannette ») :
/// « 1 » puis des mots, sans autre nombre.
bool mesureUnitaire(String mesure) {
  final c = mesureCourte(mesure);
  return c.startsWith('1 ') &&
      mlDe(c) == null &&
      gDe(c) == null &&
      !RegExp(r'\d').hasMatch(c.substring(2));
}

/// La quantité d'un ingrédient, pour la liste et le garde-manger ; `null`
/// si on ne la connaît pas (« sel et poivre »). Une partie d'aliment
/// (« 2 gousses » d'ail) se dit en grammes : on n'achète pas 2 têtes d'ail.
Quantite? quantiteDe(Ingredient i) {
  final q = i.quantite;
  if (q != null) return q;
  final m = i.mesure, n = i.nombre;
  if (m != null && n != null) {
    final ml = mlDe(m);
    if (ml != null) return Quantite.lisible(ml * n, FamilleUnite.volume);
    final g = gDe(m);
    if (g != null) return Quantite.lisible(g * n, FamilleUnite.masse);
    final partie = _partie.hasMatch(mesureCourte(m)) && i.grammes != null;
    if (mesureUnitaire(m) && !partie) return Quantite(n);
  }
  final g = i.grammes;
  return g == null ? null : Quantite.lisible(g, FamilleUnite.masse);
}

// ═══ Les besoins (la liste de courses) ══════════════════════════════════════

/// Ce qui ne va jamais sur la liste (le robinet).
const Set<String> kJamaisALaListe = {
  'eau',
  'eau chaude',
  'eau froide',
  'eau bouillante',
  'eau salee',
  'glace',
  'glacon',
};

/// Ce qu'on a toujours sous la main : proposé, jamais coché d'emblée.
const Set<String> kDeBase = {'sel', 'poivre', 'sel poivre', 'sel et poivre'};

/// D'habitude au PLACARD (huile, sauces, épices) quand la recette en
/// demande peu : à vérifier plutôt qu'à acheter d'office.
bool auPlacard(String nom, List<Quantite> requis) {
  if (kDeBase.contains(cleArticle(nom))) return true;
  final r = rayonDe(nom);
  if (r != Rayon.condiments && r != Rayon.epices) return false;
  return requis.every(
    (q) =>
        q.unite.famille == FamilleUnite.compte ? q.valeur <= 1 : q.base <= 125,
  );
}

/// Un aliment que des recettes demandent, et ce qu'il faut en acheter.
class Besoin {
  const Besoin({
    required this.nom,
    required this.requis,
    required this.origines,
    required this.enStock,
    required this.surLaListe,
    required this.aAcheter,
    required this.aProposer,
    this.aVerifier = false,
  });

  final String nom;

  /// Ce que les recettes demandent, par famille d'unités.
  final List<Quantite> requis;

  /// Les recettes qui le demandent.
  final List<String> origines;
  final List<ArticleGardeManger> enStock;
  final List<ArticleListe> surLaListe;

  /// Ce qui manque (vide : couvert, ou quantité inconnue).
  final List<Quantite> aAcheter;

  /// Coché d'emblée : il en manque.
  final bool aProposer;

  /// D'habitude au placard, pas suivi au garde-manger : à vérifier.
  final bool aVerifier;
}

/// Une quantité pour les courses : arrondie au-dessus, lisible.
Quantite arrondiCourses(Quantite q) => _arrondi(q.base, q.unite.famille);

/// Arrondi au-dessus, lisible : les unités entières, les grammes et les
/// millilitres à 5 près (375 ml reste 375 ml).
Quantite _arrondi(double base, FamilleUnite famille) => switch (famille) {
  FamilleUnite.masse || FamilleUnite.volume => Quantite.lisible(
    ((base - 1e-9) / 5).ceil() * 5.0,
    famille,
  ),
  _ => Quantite.lisible((base - 1e-9).ceil().toDouble(), famille),
};

/// Ce qui manque de [requis] (en unité de base), d'après [quantites] déjà
/// là (stock ou liste) : 0 ou moins si c'est couvert — une quantité
/// inconnue ou comptée autrement couvre.
double _manque(Quantite requis, List<Quantite?> quantites) {
  var reste = requis.base;
  for (final q in quantites) {
    // Sans quantité, ou comptée autrement (un paquet de riz pour 250 ml) :
    // on considère que ça couvre.
    if (q == null || q.unite.famille != requis.unite.famille) return 0;
    reste -= q.base;
  }
  return reste;
}

/// Les besoins de [recettes] (chacune × son facteur), dans l'ordre où ils
/// apparaissent, moins [gardeManger] et [liste].
List<Besoin> besoinsDe(
  List<(Recette, double)> recettes, {
  required List<ArticleGardeManger> gardeManger,
  required List<ArticleListe> liste,
}) {
  final ordre = <String>[];
  final noms = <String, String>{};
  final requis = <String, List<Quantite>>{};
  final origines = <String, List<String>>{};
  for (final (r, facteur) in recettes) {
    if (facteur <= 0) continue;
    for (final i in r.ingredients) {
      final cle = cleArticle(i.nom);
      if (cle.isEmpty || kJamaisALaListe.contains(cle)) continue;
      if (!noms.containsKey(cle)) {
        ordre.add(cle);
        noms[cle] = i.nom;
        requis[cle] = [];
        origines[cle] = [];
      }
      final q = quantiteDe(i.fois(facteur));
      if (q != null) requis[cle] = additionner(requis[cle]!, q);
      if (!origines[cle]!.contains(r.nom)) origines[cle]!.add(r.nom);
    }
  }
  final stock = [
    for (final a in gardeManger)
      if (!a.restes) a,
  ];
  return [
    for (final cle in ordre)
      () {
        final nom = noms[cle]!;
        final enStock = [
          for (final a in stock)
            if (memeAliment(nom, a.nom)) a,
        ];
        final surLaListe = [
          for (final a in liste)
            if (memeAliment(nom, a.nom)) a,
        ];
        final aAcheter = <Quantite>[];
        for (final q in requis[cle]!) {
          final deja = <Quantite?>[for (final a in enStock) a.quantite];
          for (final a in surLaListe) {
            final memes = a.quantites.where(
              (x) => x.unite.famille == q.unite.famille,
            );
            // Sur la liste sans quantité comparable : ça couvre.
            deja.addAll(memes.isEmpty ? [null] : memes);
          }
          final manque = _manque(q, deja);
          if (manque > 1e-6) aAcheter.add(_arrondi(manque, q.unite.famille));
        }
        final sansQuantite = requis[cle]!.isEmpty;
        final aVerifier =
            enStock.isEmpty &&
            surLaListe.isEmpty &&
            auPlacard(nom, requis[cle]!);
        return Besoin(
          nom: nom,
          requis: requis[cle]!,
          origines: origines[cle]!,
          enStock: enStock,
          surLaListe: surLaListe,
          aAcheter: aAcheter,
          aVerifier: aVerifier,
          aProposer:
              !aVerifier &&
              (sansQuantite
                  ? enStock.isEmpty && surLaListe.isEmpty
                  : aAcheter.isNotEmpty),
        );
      }(),
  ];
}

// ═══ La semaine, la cuisine en lot ══════════════════════════════════════════

/// Les portions de restes d'une recette au garde-manger.
double portionsEnRestes(List<ArticleGardeManger> gardeManger, String id) =>
    gardeManger
        .where((a) => a.recetteId == id)
        .fold(0.0, (s, a) => s + (a.quantite?.valeur ?? 0));

/// Combien de fois cuisiner [recette] pour [portions] : par demi-recette,
/// au-dessus (3 portions d'une recette de 4 → 1 ; 5 → 1,5).
double lotsPour(Recette recette, double portions) {
  if (portions <= 0) return 0;
  final p = recette.portions <= 0 ? 1 : recette.portions;
  return ((portions / p * 2) - 1e-9).ceil() / 2;
}

/// Une recette prévue dans la semaine : ses repas, ce qu'il faut cuisiner.
class RecetteDeLaSemaine {
  const RecetteDeLaSemaine({
    required this.recette,
    required this.repas,
    required this.restes,
  });

  final Recette recette;

  /// Les repas prévus (pas encore notés), du plus tôt au plus tard.
  final List<RepasPrevu> repas;

  /// Les portions déjà en restes.
  final double restes;

  double get portions => repas.fold(0.0, (s, p) => s + p.portions);

  /// Les portions à cuisiner (les restes servent d'abord).
  double get aCuisiner => (portions - restes) < 0 ? 0 : portions - restes;

  double get lots => lotsPour(recette, aCuisiner);
}

/// Le repas prévu a-t-il été noté au journal ? Une entrée de sa recette
/// (de son produit) ce jour-là à ce moment — pour « autre chose », une
/// entrée quelconque.
bool prevuNote(RepasPrevu p, List<EntreeJournal> journal) {
  for (final e in journal) {
    if (e.jour != p.jour || e.moment != p.moment) continue;
    if (p.recetteId != null && e.recetteId == p.recetteId) return true;
    if (p.produitId != null && e.produitId == p.produitId) return true;
    if (p.libre != null) return true;
  }
  return false;
}

/// Les recettes prévues de [debut] à [debut] + [jours] − 1, pas encore
/// notées : la plus tôt prévue d'abord.
List<RecetteDeLaSemaine> recettesDeLaSemaine(
  EtatRecettes etat, {
  required DateTime debut,
  required List<EntreeJournal> journal,
  required List<ArticleGardeManger> gardeManger,
  int jours = 7,
}) {
  final d = jourDe(debut);
  final fin = plusJours(d, jours);
  final parRecette = <String, List<RepasPrevu>>{};
  for (final p in etat.plan) {
    final id = p.recetteId;
    if (id == null || p.jour.isBefore(d) || !p.jour.isBefore(fin)) continue;
    if (etat.recette(id) == null || prevuNote(p, journal)) continue;
    parRecette.putIfAbsent(id, () => []).add(p);
  }
  return [
    for (final e in parRecette.entries)
      RecetteDeLaSemaine(
        recette: etat.recette(e.key)!,
        repas: e.value
          ..sort((a, b) {
            final x = a.jour.compareTo(b.jour);
            return x != 0 ? x : a.moment.index.compareTo(b.moment.index);
          }),
        restes: portionsEnRestes(gardeManger, e.key),
      ),
  ]..sort((a, b) {
    final x = a.repas.first.jour.compareTo(b.repas.first.jour);
    return x != 0
        ? x
        : a.repas.first.moment.index.compareTo(b.repas.first.moment.index);
  });
}

/// Les rayons dont les aliments se préparent d'avance (laver, couper,
/// cuire) : la cuisine en lot les regroupe.
const Set<Rayon> _aPreparer = {
  Rayon.fruits,
  Rayon.legumes,
  Rayon.viandes,
  Rayon.poissons,
  Rayon.cereales,
  Rayon.legumineuses,
};

/// Les ingrédients que plusieurs recettes partagent (à préparer en une
/// fois) : le nom et les recettes, le plus partagé d'abord.
List<(String, List<String>)> ingredientsPartages(List<Recette> recettes) {
  final noms = <String, String>{};
  final dans = <String, List<String>>{};
  for (final r in recettes) {
    for (final i in r.ingredients) {
      final cle = cleArticle(i.nom);
      if (cle.isEmpty || kDeBase.contains(cle)) continue;
      if (kJamaisALaListe.contains(cle)) continue;
      if (!_aPreparer.contains(rayonDe(i.nom))) continue;
      noms.putIfAbsent(cle, () => i.nom);
      final l = dans.putIfAbsent(cle, () => []);
      if (!l.contains(r.nom)) l.add(r.nom);
    }
  }
  final partages = [
    for (final e in dans.entries)
      if (e.value.length >= 2) (noms[e.key]!, e.value),
  ]..sort((a, b) => b.$2.length.compareTo(a.$2.length));
  return partages;
}

// ═══ Le garde-manger, après la cuisine ══════════════════════════════════════

/// Ce qu'une recette cuisinée prend à un aliment du garde-manger.
class Decompte {
  const Decompte({
    required this.article,
    required this.calcule,
    this.utilise,
    this.reste,
  });

  final ArticleGardeManger article;

  /// On sait ce qu'il en restera ; sinon, c'est à la personne de dire s'il
  /// est fini.
  final bool calcule;
  final Quantite? utilise;

  /// Ce qu'il en restera, dans l'unité de l'article.
  final Quantite? reste;

  /// Plus rien après la recette (ou « fini » choisi).
  bool get fini => !calcule || (reste?.valeur ?? 0) <= 1e-6;
}

/// Ce que des ingrédients (déjà à la bonne échelle) prennent au
/// garde-manger : l'aliment qui répond, le plus pressé d'abord ; les restes
/// n'y comptent pas.
List<Decompte> decompteGardeManger(
  List<Ingredient> ingredients,
  List<ArticleGardeManger> gardeManger,
) {
  final ordre = <String>[];
  final articles = <String, ArticleGardeManger>{};
  final utilise = <String, Quantite?>{};
  final calculable = <String, bool>{};
  for (final i in ingredients) {
    final q = quantiteDe(i);
    final candidats = [
      for (final a in gardeManger)
        if (!a.restes && memeAliment(i.nom, a.nom)) a,
    ]..sort(_parEcheance);
    if (candidats.isEmpty) continue;
    final a =
        candidats
            .where(
              (x) => q != null && x.quantite?.unite.famille == q.unite.famille,
            )
            .firstOrNull ??
        candidats.first;
    if (!articles.containsKey(a.id)) {
      ordre.add(a.id);
      articles[a.id] = a;
      calculable[a.id] = true;
    }
    final meme = q != null && a.quantite?.unite.famille == q.unite.famille;
    if (!meme) {
      calculable[a.id] = false;
      continue;
    }
    final avant = utilise[a.id];
    utilise[a.id] = avant == null ? q : avant.plus(q);
  }
  return [
    for (final id in ordre)
      () {
        final a = articles[id]!;
        final u = utilise[id];
        if (calculable[id] != true || u == null || a.quantite == null) {
          return Decompte(article: a, calcule: false);
        }
        final q = a.quantite!;
        final reste = (q.base - u.base) / q.unite.facteur;
        return Decompte(
          article: a,
          calcule: true,
          utilise: u,
          reste: Quantite(reste <= 1e-6 ? 0 : _deux(reste), q.unite),
        );
      }(),
  ];
}

double _deux(double x) => (x * 100).round() / 100;

int _parEcheance(ArticleGardeManger a, ArticleGardeManger b) {
  final pa = a.peremption, pb = b.peremption;
  if (pa == null && pb == null) return 0;
  if (pa == null) return 1;
  if (pb == null) return -1;
  return pa.compareTo(pb);
}

// ═══ Les restes, la décongélation ═══════════════════════════════════════════

/// Les restes rangés [le] à [ou] : jusqu'à quand (Thermoguide : 3 à 4
/// jours au frigo, 3 à 4 mois au congélateur — la durée la plus courte).
DateTime? restesJusquau(DateTime le, Emplacement ou) => peremptionProposee(
  guideDe('reste') ?? conservationDuRayon(Rayon.autre),
  ou,
  jourDe(le),
);

/// Les restes d'une recette au garde-manger, le plus pressé d'abord.
List<ArticleGardeManger> restesDe(
  List<ArticleGardeManger> gardeManger,
  String recetteId,
) => [
  for (final a in gardeManger)
    if (a.recetteId == recetteId) a,
]..sort(_parEcheance);

/// Ce que [recette] demande et qui n'est QU'au congélateur (rien au frigo
/// ni à l'armoire) — à sortir la veille.
List<ArticleGardeManger> aDecongelerPour(
  Recette recette,
  List<ArticleGardeManger> gardeManger,
) {
  final resultat = <ArticleGardeManger>[];
  for (final i in recette.ingredients) {
    final l = [
      for (final a in gardeManger)
        if (!a.restes && memeAliment(i.nom, a.nom)) a,
    ];
    if (l.isEmpty || l.any((a) => a.emplacement != Emplacement.congelateur)) {
      continue;
    }
    final a = (l..sort(_parEcheance)).first;
    if (!resultat.any((x) => x.id == a.id)) resultat.add(a);
  }
  return resultat;
}

/// Un repas prévu qui demande de décongeler.
class Decongelation {
  const Decongelation({
    required this.repas,
    required this.recette,
    required this.articles,
  });

  final RepasPrevu repas;
  final Recette recette;
  final List<ArticleGardeManger> articles;
}

/// Les repas prévus [jour] qui demandent de sortir quelque chose du
/// congélateur la veille : ses ingrédients — ou ses restes, s'ils suffisent
/// et ne sont qu'au congélateur.
List<Decongelation> decongelationsDu(
  DateTime jour,
  EtatRecettes etat,
  List<ArticleGardeManger> gardeManger,
) {
  final resultat = <Decongelation>[];
  for (final p in etat.prevusLe(jour)) {
    final r = etat.recette(p.recetteId);
    if (r == null) continue;
    final restes = restesDe(gardeManger, r.id);
    final List<ArticleGardeManger> articles;
    if (portionsEnRestes(gardeManger, r.id) >= p.portions) {
      articles = restes.every((a) => a.emplacement == Emplacement.congelateur)
          ? [restes.first]
          : const [];
    } else {
      articles = aDecongelerPour(r, gardeManger);
    }
    if (articles.isNotEmpty) {
      resultat.add(Decongelation(repas: p, recette: r, articles: articles));
    }
  }
  return resultat;
}

// ═══ Les régions ════════════════════════════════════════════════════════════

/// Deux noms de région, à la casse et aux accents près.
bool memeRegion(String a, String b) =>
    motsDe(a).join(' ') == motsDe(b).join(' ');

/// La grande région de [region] : elle-même (« Afrique de l'Ouest ») ou
/// celle d'une de ses cuisines (« Sénégalaise ») ; `null` pour une région à
/// soi (« Créole »).
RegionCulinaire? grandeRegionDe(String? region) {
  if (region == null) return null;
  for (final g in kRegionsCulinaires) {
    if (memeRegion(g.nom, region) ||
        g.cuisines.any((c) => memeRegion(c, region))) {
      return g;
    }
  }
  return null;
}

/// La région d'une recette entre-t-elle dans [filtre] : la même, ou une
/// cuisine de la grande région [filtre] (« Sénégalaise » est en « Afrique
/// de l'Ouest ») ?
bool dansLaRegion(String? region, String filtre) {
  if (region == null) return false;
  if (memeRegion(region, filtre)) return true;
  final g = grandeRegionDe(region);
  return g != null && memeRegion(g.nom, filtre);
}

// ═══ Le livre ═══════════════════════════════════════════════════════════════

/// La recette répond-elle à [requete] (son nom, sa région — et sa grande
/// région : « afrique » trouve le thiéboudienne sénégalais —, ses
/// ingrédients) ?
bool recetteRepond(Recette r, String requete) {
  final q = motsRecherche(requete);
  if (q.isEmpty) return true;
  final mots = motsRecherche(
    [
      r.nom,
      r.region ?? '',
      grandeRegionDe(r.region)?.nom ?? '',
      for (final i in r.ingredients) i.nom,
    ].join(' '),
  );
  return q.every((m) => mots.any((w) => w.startsWith(m)));
}

/// Le livre trié.
List<Recette> trierRecettes(List<Recette> recettes, TriRecettes tri) {
  DateTime recente(Recette r) {
    final d = r.derniereFois;
    return d != null && d.isAfter(r.creee) ? d : r.creee;
  }

  int nom(Recette a, Recette b) =>
      simplifier(a.nom).compareTo(simplifier(b.nom));
  final l = [...recettes];
  l.sort(
    (a, b) => switch (tri) {
      TriRecettes.recentes => recente(b).compareTo(recente(a)),
      TriRecettes.alphabetique => nom(a, b),
      TriRecettes.proteines => b.parPortion.proteines.compareTo(
        a.parPortion.proteines,
      ),
      TriRecettes.calories => a.parPortion.kcal.compareTo(b.parPortion.kcal),
      TriRecettes.rapides => (a.dureeTotale ?? 9999).compareTo(
        b.dureeTotale ?? 9999,
      ),
    },
  );
  return l;
}

/// Les recettes pour [moment] d'abord (celles cuisinées le plus récemment),
/// puis les autres.
List<Recette> recettesPour(MomentRepas moment, List<Recette> recettes) {
  final tries = trierRecettes(recettes, TriRecettes.recentes);
  return [
    ...tries.where((r) => r.moments.contains(moment)),
    ...tries.where((r) => !r.moments.contains(moment)),
  ];
}

/// L'entrée du journal de [portions] de [recette] (sa valeur par portion,
/// figée).
EntreeJournal entreeDeRecette({
  required String id,
  required Recette recette,
  required double portions,
  required DateTime jour,
  required MomentRepas moment,
  required DateTime ajoutee,
}) => EntreeJournal(
  id: id,
  jour: jourDe(jour),
  moment: moment,
  nom: recette.nom,
  source: SourceEntree.recette,
  recetteId: recette.id,
  portions: portions,
  portion: kPortionRecette,
  nutriments: recette.parPortion * portions,
  ajoutee: ajoutee,
);

/// Le libellé de portion d'une entrée de recette (clé, pas un texte : les
/// écrans disent « 1 portion », « 2 portions »).
const String kPortionRecette = 'portion';

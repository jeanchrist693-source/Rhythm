// lib/modele/alimentation/calculs_courses.dart
//
// Les RÈGLES des achats, pures et testées :
// - la FUSION : un même article (même clé : « Bananes » = « banane »)
//   n'apparaît qu'une fois — les quantités s'additionnent (2 + 1 = 3 ;
//   500 g + 1 kg = 1,5 kg ; « 2 + 150 g » si les familles diffèrent) et les
//   origines se cumulent (« pour : chili, omelette ») ;
// - « DÉJÀ AU GARDE-MANGER » : ce qu'on a déjà d'un article ;
// - la CAISSE du panier et l'ESTIMATION de la liste (d'après les derniers
//   prix payés) ;
// - l'HISTORIQUE DES PRIX d'un article (par magasin, le meilleur) ;
// - le MOIS : dépensé (budget), gaspillé ;
// - À CONSOMMER BIENTÔT (3 jours) et le rangement proposé d'un achat.

import '../../utils/dates.dart';
import 'conservation.dart';
import 'courses.dart';
import 'rayons.dart';
import 'taxes.dart';

// ═══ La liste ═══════════════════════════════════════════════════════════════

/// Ajoute [nom] (et [quantite]) à [liste] : FUSIONNÉ avec le même article
/// s'il y est déjà (et pas encore au panier). Rend la nouvelle liste et
/// l'article (nouveau ou fusionné). [origines] : d'où il vient en plus de
/// [origine] (les recettes de la semaine).
(List<ArticleListe>, ArticleListe, bool fusionne) ajouterALaListe(
  List<ArticleListe> liste, {
  required String id,
  required String nom,
  required Rayon rayon,
  required DateTime maintenant,
  Quantite? quantite,
  String? origine,
  List<String> origines = const [],
}) {
  final toutes = [?origine, ...origines];
  final cle = cleArticle(nom);
  final i = liste.indexWhere(
    (a) => !a.auPanier && cleArticle(a.nom) == cle && cle.isNotEmpty,
  );
  if (i >= 0) {
    final a = liste[i];
    final fusionne = a.copierAvec(
      quantites: quantite == null
          ? (a.quantites.isEmpty ? a.quantites : _plusUn(a.quantites))
          : additionner(a.quantites, quantite),
      origines: [
        ...a.origines,
        for (final o in toutes)
          if (!a.origines.contains(o)) o,
      ],
    );
    return (
      [for (final (k, x) in liste.indexed) k == i ? fusionne : x],
      fusionne,
      true,
    );
  }
  final nouvel = ArticleListe(
    id: id,
    nom: nom,
    rayon: rayon,
    ajoute: maintenant,
    quantites: quantite == null ? const [] : [quantite],
    origines: toutes.toSet().toList(),
  );
  return ([...liste, nouvel], nouvel, false);
}

/// Sans quantité précisée, « encore un » s'il était compté à l'unité.
List<Quantite> _plusUn(List<Quantite> q) {
  final i = q.indexWhere((x) => x.unite == Unite.unite);
  return i < 0 ? q : additionner(q, const Quantite(1));
}

/// La liste par rayon, dans l'ordre du magasin ; dans un rayon, l'ordre
/// d'ajout.
List<(Rayon, List<ArticleListe>)> parRayon(
  List<ArticleListe> liste,
  List<Rayon> ordre,
) => [
  for (final r in ordre)
    if (liste.any((a) => a.rayon == r))
      (
        r,
        [
          for (final a in liste)
            if (a.rayon == r) a,
        ],
      ),
];

/// Les articles du garde-manger qui répondent à [nom] (même clé, ou l'une
/// contenue dans l'autre : « lait » ↔ « lait 2 % »).
List<ArticleGardeManger> dejaAuGardeManger(
  List<ArticleGardeManger> gardeManger,
  String nom,
) {
  final cle = cleArticle(nom).split(' ').where((m) => m.isNotEmpty).toSet();
  if (cle.isEmpty) return const [];
  return [
    for (final a in gardeManger)
      if (_recouvre(cle, cleArticle(a.nom).split(' ').toSet())) a,
  ];
}

/// Deux noms désignent-ils le même aliment (même clé, ou l'une contenue
/// dans l'autre : « lait » ↔ « lait 2 % ») — et pas deux rayons différents
/// (« beurre » n'est pas du « beurre d'arachide ») ?
bool memeAliment(String a, String b) {
  final x = cleArticle(a).split(' ').where((m) => m.isNotEmpty).toSet();
  if (x.isEmpty) return false;
  final y = cleArticle(b).split(' ').where((m) => m.isNotEmpty).toSet();
  if (!_recouvre(x, y)) return false;
  final ra = rayonDe(a), rb = rayonDe(b);
  return ra == rb || ra == Rayon.autre || rb == Rayon.autre;
}

bool _recouvre(Set<String> a, Set<String> b) {
  if (b.isEmpty) return false;
  return a.length <= b.length ? b.containsAll(a) : a.containsAll(b);
}

// ═══ La caisse, l'estimation ════════════════════════════════════════════════

/// Le panier en cours à la caisse.
Caisse caisseDuPanier(List<ArticleListe> liste, Bareme bareme) => Caisse.de([
  for (final a in liste)
    if (a.panier case final p?)
      (prix: p.prix, statut: p.statut, consigne: p.consigne),
], bareme);

/// Le dernier passage d'un article (clé) à la caisse.
LigneAchat? dernierAchat(List<Achat> achats, String nom) {
  final cle = cleArticle(nom);
  for (final a in achats.reversed) {
    for (final l in a.lignes) {
      if (cleArticle(l.nom) == cle) return l;
    }
  }
  return null;
}

/// Ce que la liste devrait coûter, taxes comprises, d'après les derniers
/// prix payés ; et combien d'articles ont un prix connu.
({double total, int connus}) estimationListe(
  List<ArticleListe> liste,
  List<Achat> achats,
  Bareme bareme,
) {
  var total = 0.0, connus = 0;
  for (final a in liste) {
    final p = a.panier;
    if (p != null) {
      total += Caisse.avecTaxes(p.prix, p.statut, bareme) + p.consigne;
      connus++;
      continue;
    }
    final l = dernierAchat(achats, a.nom);
    if (l == null) continue;
    total +=
        Caisse.avecTaxes(l.panier.prix, l.panier.statut, bareme) +
        l.panier.consigne;
    connus++;
  }
  return (total: (total * 100).round() / 100, connus: connus);
}

// ═══ L'historique des prix ══════════════════════════════════════════════════

class PrixVu {
  const PrixVu({
    required this.date,
    required this.magasin,
    required this.prix,
    required this.auPoids,
  });

  final DateTime date;
  final String? magasin;

  /// Au kilo si [auPoids], sinon à l'unité.
  final double prix;
  final bool auPoids;
}

/// Les prix vus pour [nom], du plus récent au plus ancien.
List<PrixVu> historiquePrix(List<Achat> achats, String nom) {
  final cle = cleArticle(nom);
  return [
    for (final a in achats.reversed)
      for (final l in a.lignes)
        if (cleArticle(l.nom) == cle)
          PrixVu(
            date: a.date,
            magasin: a.magasin,
            prix: l.panier.prixComparable,
            auPoids: l.panier.auPoids,
          ),
  ];
}

/// Le meilleur prix vu (dans la même façon de compter que le dernier).
PrixVu? meilleurPrix(List<PrixVu> historique) {
  if (historique.isEmpty) return null;
  final mode = historique.first.auPoids;
  PrixVu? m;
  for (final p in historique) {
    if (p.auPoids != mode) continue;
    if (m == null || p.prix < m.prix) m = p;
  }
  return m;
}

// ═══ Le mois ════════════════════════════════════════════════════════════════

bool _duMois(DateTime d, DateTime mois) =>
    d.year == mois.year && d.month == mois.month;

/// Dépensé en épicerie ce mois-ci (totaux à la caisse).
double depenseDuMois(List<Achat> achats, DateTime maintenant) => [
  for (final a in achats)
    if (_duMois(a.date, maintenant)) a.caisse.total,
].fold(0.0, (s, x) => s + x);

/// Jeté ce mois-ci : la valeur et le nombre d'aliments.
({double valeur, int nombre}) gaspillageDuMois(
  List<Sortie> sorties,
  DateTime maintenant,
) {
  var v = 0.0, n = 0;
  for (final s in sorties) {
    if (!s.jete || !_duMois(s.date, maintenant)) continue;
    v += s.valeur;
    n++;
  }
  return (valeur: (v * 100).round() / 100, nombre: n);
}

// ═══ Le garde-manger ════════════════════════════════════════════════════════

/// Jours avant la date (0 = aujourd'hui, négatif = passée) ; `null` sans
/// date.
int? joursRestants(ArticleGardeManger a, DateTime aujourdhui) {
  final p = a.peremption;
  return p == null ? null : joursEntre(jourDe(aujourdhui), p);
}

/// À consommer d'ici [jours] jours (passés compris), le plus urgent d'abord.
List<ArticleGardeManger> aConsommerBientot(
  List<ArticleGardeManger> gardeManger,
  DateTime aujourdhui, {
  int jours = 3,
}) {
  final l = [
    for (final a in gardeManger)
      if ((joursRestants(a, aujourdhui) ?? 999) <= jours) a,
  ]..sort((a, b) => a.peremption!.compareTo(b.peremption!));
  return l;
}

/// Le rangement proposé d'une ligne d'achat : où (le guide, sinon le
/// rayon), jusqu'à quand, au prix payé taxes comprises. `null` pour ce qui
/// ne va pas au garde-manger (entretien, hygiène).
ArticleGardeManger? rangementPropose(
  LigneAchat l, {
  required String id,
  required DateTime date,
  required Bareme bareme,
  String? magasin,
}) {
  if (!l.rayon.alimentaire) return null;
  final g = conservationDe(l.nom, l.rayon);
  final ou = g.expressions.isEmpty
      ? (l.rayon.emplacement ?? Emplacement.armoire)
      : g.ideal;
  return ArticleGardeManger(
    id: id,
    nom: l.nom,
    emplacement: ou,
    rayon: l.rayon,
    entre: date,
    quantite: l.quantites.isEmpty ? null : l.quantites.first,
    peremption: peremptionProposee(g, ou, date),
    prix: Caisse.avecTaxes(l.panier.prix, l.panier.statut, bareme),
    magasin: magasin,
  );
}

/// Le repère de conservation d'un aliment rangé : celui des RESTES pour
/// les restes d'une recette (« Saumon (restes) » n'est plus du saumon cru),
/// sinon le guide.
Conservation conservationDArticle(ArticleGardeManger a) => a.restes
    ? (guideDe('reste') ?? conservationDuRayon(Rayon.autre))
    : conservationDe(a.nom, a.rayon);

/// Déplacé à [ou] [le] : la date suit le guide (au congélateur, elle
/// s'allonge ; décongelé au frigo, 1 à 2 jours).
DateTime? peremptionApresDeplacement(
  ArticleGardeManger a,
  Emplacement ou,
  DateTime le,
) {
  final g = conservationDArticle(a);
  if (a.emplacement == Emplacement.congelateur && ou == Emplacement.frigo) {
    // Décongelé : à cuisiner vite.
    final d = g.frigo?.$1 ?? 2;
    return DateTime(le.year, le.month, le.day + (d < 2 ? d : 2));
  }
  return peremptionProposee(g, ou, le) ?? a.peremption;
}

/// Les HABITUELS : ce qu'on achète le plus souvent (au moins deux fois),
/// qui n'est pas déjà sur la liste — du plus fréquent au moins fréquent.
List<(String, Rayon)> habituels(
  List<Achat> achats,
  List<ArticleListe> liste, {
  int max = 8,
}) {
  final surLaListe = {for (final a in liste) cleArticle(a.nom)};
  final compte = <String, (String, Rayon, int, DateTime)>{};
  for (final a in achats) {
    for (final l in a.lignes) {
      final cle = cleArticle(l.nom);
      if (cle.isEmpty || surLaListe.contains(cle)) continue;
      final avant = compte[cle];
      compte[cle] = (l.nom, l.rayon, (avant?.$3 ?? 0) + 1, a.date);
    }
  }
  final tries = compte.values.where((x) => x.$3 >= 2).toList()
    ..sort((a, b) {
      final d = b.$3.compareTo(a.$3);
      return d != 0 ? d : b.$4.compareTo(a.$4);
    });
  return [for (final x in tries.take(max)) (x.$1, x.$2)];
}

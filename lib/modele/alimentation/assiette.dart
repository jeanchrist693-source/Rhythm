// lib/modele/alimentation/assiette.dart
//
// L'ASSIETTE du Guide alimentaire canadien (Santé Canada, 2019) : la MOITIÉ
// en légumes et fruits, un QUART en aliments protéinés, un QUART en
// aliments à grains entiers — et l'eau pour boisson.
//
// Chaque aliment du journal est rangé dans l'une des trois parts d'après son
// groupe du FCÉN et son nom, ou HORS de l'assiette :
// - À LIMITER : sucreries, grignotines, boissons sucrées ou alcoolisées,
//   jus, restauration rapide, pâtisseries (les aliments hautement
//   transformés du Guide) ;
// - NEUTRE : ce qui ne compte pas — matières grasses, épices, sauces, eau,
//   café, thé, lait à boire (les boissons ne sont pas dans l'assiette) ;
// - NON RÉPARTI : ce dont on ne sait pas ce qu'il contient (une entrée
//   rapide, un plat composé du FCÉN, une recette effacée).
// Une RECETTE se répartit ingrédient par ingrédient (la part mangée) ; un
// de MES PRODUITS se range comme l'aliment de la base le plus proche.
//
// La mesure : le POIDS, pour approcher la place dans l'assiette ; les
// grains et légumineuses SECS comptent pour leur poids cuit (× 2,5). Une
// estimation, pas un avis médical. Fonctions pures, testées.

import 'alimentation.dart';
import 'base_aliments.dart';
import 'recettes.dart';

/// Où va un aliment ; [vise] = sa part de l'assiette (les trois premières).
enum CategorieAssiette {
  legumesFruits(0.5),
  proteines(0.25),
  grains(0.25),
  aLimiter(null),
  neutre(null),
  nonReparti(null);

  const CategorieAssiette(this.vise);

  final double? vise;

  bool get dansLAssiette => vise != null;

  /// Les trois parts de l'assiette, dans l'ordre du Guide.
  static const parts = [legumesFruits, proteines, grains];
}

/// Les grains et légumineuses secs gonflent à la cuisson.
const double kFacteurCuisson = 2.5;

/// En dessous (en grammes), l'assiette ne dit encore rien.
const double kAssietteMinimum = 100;

// ═══ Ranger un aliment ══════════════════════════════════════════════════════

/// Les mots d'un nom, simplifiés et au singulier.
Set<String> _mots(String nom) => {for (final m in motsDe(nom)) singulier(m)};

bool _un(Set<String> mots, Set<String> cherches) => mots.any(cherches.contains);

const _sucre = {'sucre', 'sucree'};
const _pourBoire = {'eau', 'cafe', 'the', 'tisane', 'infusion', 'espresso'};
const _vegetales = {'soya', 'soja', 'amande', 'avoine', 'riz', 'plante'};
const _condiments = {'ketchup', 'catsup', 'sauce', 'relish', 'salsa'};
const _patisseries = {
  'gateau', 'biscuit', 'beigne', 'beignet', 'tarte', 'tartelette', //
  'patisserie', 'croissant', 'brioche', 'danoise', 'brownie', 'chausson', //
  'glace', 'glacage', 'strudel', 'gaufrette', 'cornet', 'carre', //
  'barre', 'muffin', 'baklava', 'eclair', 'shortcake', 'cupcake',
};
const _grainsEntiers = {
  'entier', 'entiere', 'complet', 'complete', 'avoine', 'gruau', 'brun', //
  'sauvage', 'quinoa', 'orge', 'sarrasin', 'boulgour', 'bulgur', 'son', //
  'millet', 'epeautre', 'kamut', 'amarante', 'teff',
};

/// La catégorie d'un aliment du FCÉN (son groupe et son nom).
CategorieAssiette categorieDe(int groupe, String nom) {
  final m = _mots(nom);
  final mots = motsDe(nom);
  final premier = mots.isEmpty ? '' : singulier(mots.first);
  final aBoire =
      premier == 'lait' || premier == 'boisson' || m.contains('boisson');
  switch (groupe) {
    case 1: // Produits laitiers et œufs.
      if (_un(m, {'glace', 'glacee', 'pouding', 'chocolat', 'dessert'}) ||
          _un(m, _sucre)) {
        return CategorieAssiette.aLimiter;
      }
      if (_un(m, {'beurre', 'creme', 'margarine'})) {
        return CategorieAssiette.neutre;
      }
      if (aBoire && !m.contains('poudre')) return CategorieAssiette.neutre;
      return CategorieAssiette.proteines;
    case 2 || 4: // Épices, matières grasses.
      return CategorieAssiette.neutre;
    case 5 || 7 || 10 || 13 || 15 || 17: // Volailles, viandes, poissons.
      return CategorieAssiette.proteines;
    case 12 || 16: // Noix et graines, légumineuses.
      return aBoire ? CategorieAssiette.neutre : CategorieAssiette.proteines;
    case 6: // Soupes, sauces.
      return _un(m, {'sauce', 'bouillon', 'gravy', 'fond'})
          ? CategorieAssiette.neutre
          : CategorieAssiette.nonReparti;
    case 8 || 20: // Céréales, grains, pâtes.
      return CategorieAssiette.grains;
    case 9: // Fruits (et leurs jus).
      return _un(m, {'jus', 'nectar', 'boisson', 'cocktail', 'limonade'})
          ? CategorieAssiette.aLimiter
          : CategorieAssiette.legumesFruits;
    case 11: // Légumes.
      if (_un(m, {'frite', 'croustille'})) return CategorieAssiette.aLimiter;
      if (premier == 'jus' || _un(m, _condiments)) {
        return CategorieAssiette.neutre;
      }
      return CategorieAssiette.legumesFruits;
    case 14: // Boissons : l'eau, le café, le thé, les boissons végétales.
      final vegetale = premier == 'boisson' && _un(m, _vegetales);
      return (_pourBoire.contains(premier) || vegetale) && !_un(m, _sucre)
          ? CategorieAssiette.neutre
          : CategorieAssiette.aLimiter;
    case 18: // Boulangerie.
      if (mots.contains('anglais')) return CategorieAssiette.grains;
      return _un(m, _patisseries)
          ? CategorieAssiette.aLimiter
          : CategorieAssiette.grains;
    case 19 || 21 || 25: // Sucreries, restauration rapide, grignotines.
      return CategorieAssiette.aLimiter;
    default: // Plats composés : on ne sait pas.
      return CategorieAssiette.nonReparti;
  }
}

/// Un grain ENTIER (« riz brun », « pain de blé entier », « gruau »).
bool grainEntier(String nom) => _un(_mots(nom), _grainsEntiers);

/// Le poids dans l'assiette de [grammes] de cet aliment : les grains et
/// légumineuses secs (ou crus) comptent pour leur poids cuit.
double grammesAssiette(int groupe, String nom, double grammes) {
  if (groupe != 8 && groupe != 16 && groupe != 20) return grammes;
  final m = _mots(nom);
  final sec = _un(m, {'sec', 'seche', 'cru', 'crue', 'deshydrate'});
  final cuit = _un(m, {'cuit', 'cuite', 'bouilli', 'bouillie', 'prepare'});
  return sec && !cuit ? grammes * kFacteurCuisson : grammes;
}

// ═══ L'assiette ═════════════════════════════════════════════════════════════

/// Un aliment dans l'assiette : son nom, sa catégorie, son poids (dans
/// l'assiette : cuit), s'il est un grain entier ; [recette] : la recette
/// d'où vient l'ingrédient.
class ElementAssiette {
  const ElementAssiette({
    required this.nom,
    required this.categorie,
    this.grammes = 0,
    this.entier = false,
    this.recette,
  });

  final String nom;
  final CategorieAssiette categorie;
  final double grammes;
  final bool entier;
  final String? recette;
}

/// Ce que l'assiette conseille, dans l'ordre où l'on regarde.
enum ConseilAssiette {
  /// Trop peu pour juger.
  vide,
  plusDeLegumesFruits,
  plusDeProteines,
  plusDeGrains,
  moinsALimiter,
  grainsEntiers,
  equilibree,
}

class Assiette {
  const Assiette(this.elements);

  final List<ElementAssiette> elements;

  double grammesDe(CategorieAssiette c) => elements
      .where((e) => e.categorie == c)
      .fold(0.0, (s, e) => s + e.grammes);

  /// Le poids des trois parts.
  double get total =>
      CategorieAssiette.parts.fold(0.0, (s, c) => s + grammesDe(c));

  /// La part de [c] dans l'assiette (0 → 1).
  double partDe(CategorieAssiette c) {
    final t = total;
    return t <= 0 ? 0 : grammesDe(c) / t;
  }

  /// La part atteinte de ce que vise le Guide (1 = la part visée).
  double atteinteDe(CategorieAssiette c) =>
      c.vise == null ? 0 : partDe(c) / c.vise!;

  /// La part des grains entiers parmi les grains ; `null` sans grains.
  double? get partEntiers {
    final g = grammesDe(CategorieAssiette.grains);
    if (g <= 0) return null;
    final e = elements
        .where((x) => x.categorie == CategorieAssiette.grains && x.entier)
        .fold(0.0, (s, x) => s + x.grammes);
    return e / g;
  }

  /// La part de ce qui est à limiter, parmi ce qui a été mangé (assiette +
  /// à limiter).
  double get partALimiter {
    final l = grammesDe(CategorieAssiette.aLimiter);
    final t = total + l;
    return t <= 0 ? 0 : l / t;
  }

  /// Les aliments qu'on n'a pas pu ranger.
  int get nonReparties =>
      elements.where((e) => e.categorie == CategorieAssiette.nonReparti).length;

  bool get lisible => total >= kAssietteMinimum;

  ConseilAssiette get conseil {
    if (!lisible) return ConseilAssiette.vide;
    // La part la plus loin de ce que vise le Guide.
    var pire = CategorieAssiette.legumesFruits;
    for (final c in CategorieAssiette.parts) {
      if (atteinteDe(c) < atteinteDe(pire)) pire = c;
    }
    ConseilAssiette plusDe() => switch (pire) {
      CategorieAssiette.proteines => ConseilAssiette.plusDeProteines,
      CategorieAssiette.grains => ConseilAssiette.plusDeGrains,
      _ => ConseilAssiette.plusDeLegumesFruits,
    };
    if (atteinteDe(pire) < 0.6) return plusDe();
    if (partALimiter > 0.25) return ConseilAssiette.moinsALimiter;
    if (atteinteDe(pire) < 0.8) return plusDe();
    final entiers = partEntiers;
    if (entiers != null && entiers < 0.5) return ConseilAssiette.grainsEntiers;
    return ConseilAssiette.equilibree;
  }
}

/// Un aliment de la base, rangé.
ElementAssiette _deLaBase(
  AlimentBase a,
  String nom,
  double grammes, {
  String? recette,
}) {
  final c = categorieDe(a.groupe, a.nom);
  return ElementAssiette(
    nom: nom,
    categorie: c,
    grammes: grammesAssiette(a.groupe, a.nom, grammes),
    entier: c == CategorieAssiette.grains && grainEntier(a.nom),
    recette: recette,
  );
}

/// L'aliment de la base le plus proche d'un nom de produit : le nom entier,
/// puis sans ses derniers mots (« Yogourt grec nature 2 % » → « yogourt
/// grec »), jusqu'au premier.
AlimentBase? procheDe(BaseAliments base, String nom) {
  final mots = motsRecherche(nom);
  for (var n = mots.length; n > 0; n--) {
    final r = base.rechercher(mots.take(n).join(' '), max: 1);
    if (r.isNotEmpty) return r.first;
  }
  return null;
}

/// Un produit : rangé comme l'aliment de la base le plus proche de son nom.
ElementAssiette _duProduit(
  BaseAliments base,
  Produit? p,
  String nom,
  double? grammes, {
  String? recette,
}) {
  final proche = procheDe(base, p?.nom ?? nom);
  if (proche == null || grammes == null || grammes <= 0) {
    return ElementAssiette(
      nom: nom,
      categorie: CategorieAssiette.nonReparti,
      recette: recette,
    );
  }
  return _deLaBase(proche, nom, grammes, recette: recette);
}

/// Les aliments de [entrees], rangés.
List<ElementAssiette> elementsDe(
  Iterable<EntreeJournal> entrees, {
  required BaseAliments base,
  required List<Produit> produits,
  required List<Recette> recettes,
}) {
  Produit? produit(String? id) {
    for (final p in produits) {
      if (p.id == id) return p;
    }
    return null;
  }

  Recette? recette(String? id) {
    for (final r in recettes) {
      if (r.id == id) return r;
    }
    return null;
  }

  ElementAssiette inconnu(EntreeJournal e) =>
      ElementAssiette(nom: e.nom, categorie: CategorieAssiette.nonReparti);

  final elements = <ElementAssiette>[];
  for (final e in entrees) {
    switch (e.source) {
      case SourceEntree.base:
        final a = e.code == null ? null : base.parCode(e.code!);
        final g = e.grammes;
        elements.add(
          a == null || g == null || g <= 0
              ? inconnu(e)
              : _deLaBase(a, e.nom, g),
        );
      case SourceEntree.produit:
        final p = produit(e.produitId);
        final g =
            e.grammes ??
            (p?.grammesPortion == null || e.portions == null
                ? null
                : p!.grammesPortion! * e.portions!);
        elements.add(_duProduit(base, p, e.nom, g));
      case SourceEntree.rapide:
        elements.add(inconnu(e));
      case SourceEntree.recette:
        final r = recette(e.recetteId);
        // La part mangée : les portions, sinon les calories.
        double? part;
        if (r != null && e.portions != null && r.portions > 0) {
          part = e.portions! / r.portions;
        } else if (r != null && r.total.kcal > 0) {
          part = e.nutriments.kcal / r.total.kcal;
        }
        if (r == null || part == null || part <= 0) {
          elements.add(inconnu(e));
          continue;
        }
        for (final i in r.ingredients) {
          final g = i.grammes;
          if (i.libre || g == null || g <= 0) continue;
          final a = i.code == null ? null : base.parCode(i.code!);
          elements.add(
            a != null
                ? _deLaBase(a, i.nom, g * part, recette: r.nom)
                : _duProduit(
                    base,
                    produit(i.produitId),
                    i.nom,
                    g * part,
                    recette: r.nom,
                  ),
          );
        }
    }
  }
  return elements;
}

/// L'assiette de [entrees] (une journée, une semaine).
Assiette assietteDe(
  Iterable<EntreeJournal> entrees, {
  required BaseAliments base,
  required List<Produit> produits,
  required List<Recette> recettes,
}) => Assiette(
  elementsDe(entrees, base: base, produits: produits, recettes: recettes),
);

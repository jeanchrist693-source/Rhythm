// lib/modele/alimentation/alimentation.dart
//
// Les types de l'ALIMENTATION :
// - [ProfilNutrition] : ce qu'il faut pour calculer les besoins (sexe, âge,
//   taille ; le poids vient des Mesures des Sports), l'activité hors sport,
//   l'objectif (perdre, maintenir, prendre du poids) et son rythme, les
//   réglages (séances comptées, ajustement automatique, objectifs fixés à
//   la main, verres d'eau, lien avec l'habitude de l'eau) ;
// - [EntreeJournal] : un aliment mangé — d'où il vient (la base du FCÉN, un
//   produit, une entrée rapide, une recette), combien, ce qu'il apporte
//   (FIGÉ au moment de la saisie : le journal ne bouge pas si la base
//   change) ;
// - [Produit] : « Mes produits », un aliment acheté dont on a recopié le
//   tableau de la valeur nutritive (par portion) ;
// - [EtatAlimentation] : le tout, et son document pour le dépôt (trois
//   tables — `journalAlim`, `produitsAlim`, `eauAlim` — et le profil).
// Lecture TOLÉRANTE partout (aucun `as` forcé) : une ligne abîmée est
// sautée, jamais l'app.

import '../../utils/dates.dart';
import '../modeles.dart';
import 'nutriments.dart';

/// Change quand le format du document change.
const int kVersionAlim = 1;

enum Sexe { homme, femme }

/// L'activité au quotidien, HORS SPORT (les séances s'ajoutent à part) :
/// le facteur appliqué au métabolisme de base.
enum ActiviteQuotidienne {
  sedentaire(1.2),
  debout(1.35),
  physique(1.55);

  const ActiviteQuotidienne(this.facteur);
  final double facteur;
}

enum ObjectifPoids { perdre, maintenir, prendre }

/// Des objectifs fixés à la main (ils remplacent le calcul).
class ObjectifsManuels {
  const ObjectifsManuels({
    required this.kcal,
    required this.proteines,
    required this.glucides,
    required this.lipides,
  });

  final int kcal, proteines, glucides, lipides;

  Map<String, dynamic> versJson() => {
    'kcal': kcal,
    'p': proteines,
    'g': glucides,
    'l': lipides,
  };

  static ObjectifsManuels? depuisJson(Object? j) {
    if (j is! Map) return null;
    int? v(String c) => j[c] is num ? (j[c] as num).round() : null;
    final kcal = v('kcal'), p = v('p'), g = v('g'), l = v('l');
    if (kcal == null || p == null || g == null || l == null || kcal <= 0) {
      return null;
    }
    return ObjectifsManuels(kcal: kcal, proteines: p, glucides: g, lipides: l);
  }
}

class ProfilNutrition {
  const ProfilNutrition({
    this.sexe,
    this.anneeNaissance,
    this.taille,
    this.activite = ActiviteQuotidienne.sedentaire,
    this.objectif = ObjectifPoids.maintenir,
    this.rythme = 0.25,
    this.compterSeances = true,
    this.ajustementAuto = true,
    this.manuels,
    this.verresEau,
    this.lienHabitudeEau = true,
  });

  final Sexe? sexe;
  final int? anneeNaissance;

  /// Centimètres.
  final double? taille;
  final ActiviteQuotidienne activite;
  final ObjectifPoids objectif;

  /// Kilos par semaine (perdre ou prendre) : 0,25 ou 0,5.
  final double rythme;

  /// Les calories des séances (moyenne de 14 jours) s'ajoutent aux besoins.
  final bool compterSeances;

  /// Corriger les besoins d'après la courbe de poids réelle.
  final bool ajustementAuto;

  /// Objectifs fixés à la main ; `null` = calculés.
  final ObjectifsManuels? manuels;

  /// Verres de 250 ml visés ; `null` = calculé (poids, séance du jour).
  final int? verresEau;

  /// Atteindre l'objectif d'eau coche l'habitude de l'eau.
  final bool lienHabitudeEau;

  /// Assez pour un calcul juste (sinon : une estimation).
  bool get complet => sexe != null && anneeNaissance != null && taille != null;

  ProfilNutrition copierAvec({
    Sexe? Function()? sexe,
    int? Function()? anneeNaissance,
    double? Function()? taille,
    ActiviteQuotidienne? activite,
    ObjectifPoids? objectif,
    double? rythme,
    bool? compterSeances,
    bool? ajustementAuto,
    ObjectifsManuels? Function()? manuels,
    int? Function()? verresEau,
    bool? lienHabitudeEau,
  }) => ProfilNutrition(
    sexe: sexe == null ? this.sexe : sexe(),
    anneeNaissance: anneeNaissance == null
        ? this.anneeNaissance
        : anneeNaissance(),
    taille: taille == null ? this.taille : taille(),
    activite: activite ?? this.activite,
    objectif: objectif ?? this.objectif,
    rythme: rythme ?? this.rythme,
    compterSeances: compterSeances ?? this.compterSeances,
    ajustementAuto: ajustementAuto ?? this.ajustementAuto,
    manuels: manuels == null ? this.manuels : manuels(),
    verresEau: verresEau == null ? this.verresEau : verresEau(),
    lienHabitudeEau: lienHabitudeEau ?? this.lienHabitudeEau,
  );

  Map<String, dynamic> versJson() => {
    'sexe': ?sexe?.name,
    'naissance': ?anneeNaissance,
    'taille': ?taille,
    'activite': activite.name,
    'objectif': objectif.name,
    'rythme': rythme,
    'seances': compterSeances,
    'ajustement': ajustementAuto,
    'manuels': ?manuels?.versJson(),
    'eau': ?verresEau,
    'lienEau': lienHabitudeEau,
  };

  static ProfilNutrition depuisJson(Object? j) {
    if (j is! Map) return const ProfilNutrition();
    T? enumeration<T extends Enum>(List<T> valeurs, Object? v) {
      for (final x in valeurs) {
        if (x.name == v) return x;
      }
      return null;
    }

    final naissance = j['naissance'];
    final taille = j['taille'];
    final rythme = j['rythme'];
    final eau = j['eau'];
    return ProfilNutrition(
      sexe: enumeration(Sexe.values, j['sexe']),
      anneeNaissance: naissance is num ? naissance.toInt() : null,
      taille: taille is num && taille > 0 ? taille.toDouble() : null,
      activite:
          enumeration(ActiviteQuotidienne.values, j['activite']) ??
          ActiviteQuotidienne.sedentaire,
      objectif:
          enumeration(ObjectifPoids.values, j['objectif']) ??
          ObjectifPoids.maintenir,
      rythme: rythme is num && rythme > 0 ? rythme.toDouble() : 0.25,
      compterSeances: j['seances'] != false,
      ajustementAuto: j['ajustement'] != false,
      manuels: ObjectifsManuels.depuisJson(j['manuels']),
      verresEau: eau is num && eau > 0 ? eau.toInt() : null,
      lienHabitudeEau: j['lienEau'] != false,
    );
  }
}

/// D'où vient un aliment du journal.
enum SourceEntree { base, produit, rapide, recette }

class EntreeJournal {
  const EntreeJournal({
    required this.id,
    required this.jour,
    required this.moment,
    required this.nom,
    required this.source,
    required this.nutriments,
    required this.ajoutee,
    this.code,
    this.produitId,
    this.recetteId,
    this.grammes,
    this.portions,
    this.portion,
  });

  final String id;

  /// Le jour (minuit).
  final DateTime jour;
  final MomentRepas moment;
  final String nom;
  final SourceEntree source;

  /// Le code du FCÉN (source : la base).
  final int? code;

  /// Le produit (source : un produit).
  final String? produitId;

  /// La recette (source : une recette ; [portions] de la recette).
  final String? recetteId;

  /// La quantité en grammes, si on la connaît.
  final double? grammes;

  /// Le nombre de portions (« 1,5 × 1 moyen »), avec leur [portion].
  final double? portions;
  final String? portion;

  /// Ce que la quantité apporte, figé à la saisie.
  final Nutriments nutriments;
  final DateTime ajoutee;

  /// L'identité de l'aliment, pour les récents (« base:1704 »).
  String get cleSource => switch (source) {
    SourceEntree.base => 'base:$code',
    SourceEntree.produit => 'produit:$produitId',
    SourceEntree.rapide => 'rapide:${nom.toLowerCase()}',
    SourceEntree.recette => 'recette:$recetteId',
  };

  /// La même entrée pour une autre quantité : les nutriments suivent la
  /// règle de trois (ni la base ni le produit ne sont nécessaires).
  EntreeJournal avecQuantite({double? grammes, double? portions}) {
    final double facteur;
    if (grammes != null && this.grammes != null && this.grammes! > 0) {
      facteur = grammes / this.grammes!;
    } else if (portions != null &&
        this.portions != null &&
        this.portions! > 0) {
      facteur = portions / this.portions!;
    } else {
      facteur = 1;
    }
    return EntreeJournal(
      id: id,
      jour: jour,
      moment: moment,
      nom: nom,
      source: source,
      code: code,
      produitId: produitId,
      recetteId: recetteId,
      grammes:
          grammes ?? (this.grammes == null ? null : this.grammes! * facteur),
      portions:
          portions ?? (this.portions == null ? null : this.portions! * facteur),
      portion: portion,
      nutriments: nutriments * facteur,
      ajoutee: ajoutee,
    );
  }

  /// Copiée vers un autre jour ou un autre moment (« Comme hier »).
  EntreeJournal copiee({
    required String id,
    DateTime? jour,
    MomentRepas? moment,
    required DateTime ajoutee,
  }) => EntreeJournal(
    id: id,
    jour: jour ?? this.jour,
    moment: moment ?? this.moment,
    nom: nom,
    source: source,
    code: code,
    produitId: produitId,
    recetteId: recetteId,
    grammes: grammes,
    portions: portions,
    portion: portion,
    nutriments: nutriments,
    ajoutee: ajoutee,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'jour': cleJour(jour),
    'moment': moment.name,
    'nom': nom,
    'source': source.name,
    'code': ?code,
    'produit': ?produitId,
    'recette': ?recetteId,
    'g': ?grammes,
    'portions': ?portions,
    'portion': ?portion,
    'n': nutriments.versJson(),
    'ajoutee': ajoutee.toIso8601String(),
  };

  static EntreeJournal? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], nom = j['nom'], jour = j['jour'];
    if (id is! String || nom is! String || jour is! num) return null;
    MomentRepas? moment;
    for (final m in MomentRepas.values) {
      if (m.name == j['moment']) moment = m;
    }
    SourceEntree? source;
    for (final s in SourceEntree.values) {
      if (s.name == j['source']) source = s;
    }
    if (moment == null || source == null) return null;
    double? d(String c) => j[c] is num ? (j[c] as num).toDouble() : null;
    final code = j['code'];
    final produit = j['produit'];
    final recette = j['recette'];
    final portion = j['portion'];
    return EntreeJournal(
      id: id,
      jour: jourDeCle(jour.toInt()),
      moment: moment,
      nom: nom,
      source: source,
      code: code is num ? code.toInt() : null,
      produitId: produit is String ? produit : null,
      recetteId: recette is String ? recette : null,
      grammes: d('g'),
      portions: d('portions'),
      portion: portion is String ? portion : null,
      nutriments: Nutriments.depuisJson(j['n']),
      ajoutee: DateTime.tryParse('${j['ajoutee']}') ?? jourDeCle(jour.toInt()),
    );
  }
}

/// Un produit acheté : son tableau de la valeur nutritive, pour UNE portion.
class Produit {
  const Produit({
    required this.id,
    required this.nom,
    required this.portion,
    required this.parPortion,
    this.marque,
    this.grammesPortion,
    this.codeBarres,
  });

  final String id;
  final String nom;
  final String? marque;

  /// Son code-barres (EAN-13 ou EAN-8, `normaliserCode`) : scanné de
  /// nouveau, le produit est retrouvé sans réseau.
  final String? codeBarres;

  /// « 1 barre (40 g) », « 175 g ».
  final String portion;
  final double? grammesPortion;
  final Nutriments parPortion;

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'marque': ?marque,
    'portion': portion,
    'g': ?grammesPortion,
    'code': ?codeBarres,
    'n': parPortion.versJson(),
  };

  static Produit? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], nom = j['nom'], portion = j['portion'];
    if (id is! String || nom is! String) return null;
    final marque = j['marque'], g = j['g'], code = j['code'];
    return Produit(
      id: id,
      nom: nom,
      marque: marque is String && marque.isNotEmpty ? marque : null,
      portion: portion is String && portion.isNotEmpty ? portion : '1',
      grammesPortion: g is num && g > 0 ? g.toDouble() : null,
      codeBarres: code is String && code.isNotEmpty ? code : null,
      parPortion: Nutriments.depuisJson(j['n']),
    );
  }
}

// ═══ L'état ═════════════════════════════════════════════════════════════════

class EtatAlimentation {
  const EtatAlimentation({
    this.profil = const ProfilNutrition(),
    this.journal = const [],
    this.produits = const [],
    this.eau = const {},
  });

  final ProfilNutrition profil;

  /// Tout ce qui a été mangé, du plus ancien au plus récent.
  final List<EntreeJournal> journal;
  final List<Produit> produits;

  /// Verres d'eau bus, par jour (`cleJour`).
  final Map<int, int> eau;

  List<EntreeJournal> entreesDu(DateTime jour, [MomentRepas? moment]) {
    final j = jourDe(jour);
    return [
      for (final e in journal)
        if (e.jour == j && (moment == null || e.moment == moment)) e,
    ];
  }

  int eauDu(DateTime jour) => eau[cleJour(jour)] ?? 0;

  Produit? produit(String id) {
    for (final p in produits) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Le produit de ce code-barres (normalisé), s'il est déjà enregistré.
  Produit? produitDuCode(String code) {
    for (final p in produits) {
      if (p.codeBarres == code) return p;
    }
    return null;
  }

  EntreeJournal? entree(String id) {
    for (final e in journal) {
      if (e.id == id) return e;
    }
    return null;
  }

  EtatAlimentation copierAvec({
    ProfilNutrition? profil,
    List<EntreeJournal>? journal,
    List<Produit>? produits,
    Map<int, int>? eau,
  }) => EtatAlimentation(
    profil: profil ?? this.profil,
    journal: journal ?? this.journal,
    produits: produits ?? this.produits,
    eau: eau ?? this.eau,
  );

  Map<String, dynamic> versDocument() => {
    'versionAlim': kVersionAlim,
    'journalAlim': [for (final e in journal) e.versJson()],
    'produitsAlim': [for (final p in produits) p.versJson()],
    'eauAlim': [
      for (final e in eau.entries)
        if (e.value > 0) {'id': '${e.key}', 'verres': e.value},
    ],
    'profilAlim': profil.versJson(),
  };

  static EtatAlimentation depuisDocument(Map<String, dynamic> document) {
    List<T> liste<T>(String cle, T? Function(Object?) lire) => [
      if (document[cle] is List)
        for (final j in document[cle] as List) ?lire(j),
    ];
    final eau = <int, int>{};
    if (document['eauAlim'] is List) {
      for (final j in document['eauAlim'] as List) {
        if (j is! Map) continue;
        final cle = int.tryParse('${j['id']}');
        final v = j['verres'];
        if (cle != null && v is num && v > 0) eau[cle] = v.toInt();
      }
    }
    return EtatAlimentation(
      profil: ProfilNutrition.depuisJson(document['profilAlim']),
      journal: liste('journalAlim', EntreeJournal.depuisJson)
        ..sort((a, b) => a.ajoutee.compareTo(b.ajoutee)),
      produits: liste('produitsAlim', Produit.depuisJson),
      eau: eau,
    );
  }
}

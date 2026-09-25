// lib/modele/alimentation/base_aliments.dart
//
// La BASE D'ALIMENTS de Rhythm, hors ligne : le Fichier canadien sur les
// éléments nutritifs (FCÉN 2026, Santé Canada — Licence du gouvernement
// ouvert – Canada), réduit par `tool/extraire_fcen.py` à
// `assets/donnees/fcen.txt` : 5 894 aliments, leur nom français, huit
// nutriments pour 100 g et les portions du FCÉN (« 1 moyen », « 250 ml »).
//
// La RECHERCHE est tolérante (accents, majuscules, pluriels, mots vides :
// « oeufs » trouve « Oeuf, poule… », « beurre d'arachide » trouve
// « Beurre d'arachides… ») et CLASSE : ce que l'on a déjà mangé d'abord, puis
// les noms qui commencent par le mot cherché, courts, sans marque ; les
// fruits et légumes crus, les céréales cuites passent devant.
//
// Lue une fois, dans un isolat (`baseAlimentsProvider`) ; les tests la lisent
// directement (`BaseAliments.analyser`).

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nutriments.dart';

/// Une portion du FCÉN : « 1 moyen (18cm à 20cm long) » = 118 g.
class Portion {
  const Portion(this.libelle, this.grammes);

  final String libelle;
  final double grammes;
}

class AlimentBase {
  AlimentBase({
    required this.code,
    required this.groupe,
    required this.nom,
    required this.pour100g,
    required this.portions,
  }) : mots = motsDe(nom),
       _tete = _teteDe(nom),
       _debut = _debutDe(nom),
       _segments = ','.allMatches(nom).length + 1,
       _marque = _aUneMarque(nom);

  /// Le code du FCÉN.
  final int code;

  /// Le groupe du FCÉN (9 = fruits, 11 = légumes, 20 = céréales…).
  final int groupe;
  final String nom;
  final Nutriments pour100g;
  final List<Portion> portions;

  /// Les mots du nom, simplifiés (sans accents, minuscules).
  final List<String> mots;

  /// Les mots de la première partie du nom (« Pomme » dans « Pomme, crue »).
  final List<String> _tete;

  /// Où commence vraiment le nom : après un préfixe générique du FCÉN
  /// (« Grains céréaliers, riz blanc » : au mot 2).
  final int _debut;
  final int _segments;
  final bool _marque;

  /// Ce qu'apportent [grammes] de cet aliment.
  Nutriments pour(double grammes) => pour100g * (grammes / 100);

  /// Les premières parties du FCÉN qui ne disent rien de l'aliment.
  static const _generiques = {
    'grains cerealiers',
    'poisson',
    'crustaces',
    'mollusques',
    'noix',
    'cereale',
    'cereales',
    'charcuterie',
  };

  static List<String> _parties(String nom) => nom.split(',');

  static bool _generique(String nom) =>
      _generiques.contains(motsDe(_parties(nom).first).join(' '));

  static List<String> _teteDe(String nom) {
    final p = _parties(nom);
    return motsDe(_generique(nom) && p.length > 1 ? p[1] : p.first);
  }

  static int _debutDe(String nom) =>
      _generique(nom) ? motsDe(_parties(nom).first).length : 0;

  /// Une marque après la première partie du nom (« …, Quaker ») : ces
  /// produits passent après les aliments génériques.
  static bool _aUneMarque(String nom) {
    final parties = nom.split(',');
    for (final p in parties.skip(1)) {
      final t = p.trim();
      if (t.isEmpty) continue;
      final c = t.codeUnitAt(0);
      // Majuscule (A–Z ou accentuée) en tête d'une partie : une marque.
      if ((c >= 65 && c <= 90) || (c >= 0xC0 && c <= 0xDE)) return true;
    }
    return false;
  }
}

/// Les aliments COURANTS (codes du FCÉN) : la forme qu'on mange le plus
/// souvent passe devant (« poulet » → la poitrine rôtie, pas les pieds
/// bouillis ; « riz » → le riz blanc cuit).
const Set<int> kAlimentsCourants = {
  // Viandes, poissons, œufs.
  842, 2683, 2687, 1932, 3158, 3052, 3081, 3195, 3212, 125, 130, 133,
  // Produits laitiers, matières grasses.
  61, 6961, 7469, 119, 111, 107, 118, 422, 6289,
  // Céréales, pains.
  4523, 4497, 4464, 4517, 5917, 4066, 4067, 3671, 4049, 1414, 4421,
  // Fruits.
  1696, 1704, 1616, 1749, 1705, 1511, 1619,
  // Légumes.
  2374, 2375, 2380, 2460, 2419, 2506, 2242, 2213, 2401, 2484, 2413, 2116,
  2363,
  // Légumineuses, tofu, noix.
  3393, 7060, 3377, 4911, 2536, 3362, 2590,
  // Sucres ; charcuterie.
  4294, 4318, 1148,
};

/// Les mots d'ici : « gruau » au Québec, c'est le gruau d'avoine (pas de
/// sarrasin).
const Map<String, int> kAliasQuebec = {'gruau': 1414};

/// Les groupes du FCÉN utiles au classement.
abstract final class GroupesFcen {
  static const fruits = 9;
  static const legumes = 11;
  static const legumineuses = 16;
  static const cereales = 20;
  static const pretsAManger = 21;
  static const metsComposes = 22;
}

// ═══ Simplification du texte ════════════════════════════════════════════════

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'î': 'i', 'ï': 'i', 'í': 'i', //
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o', //
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u', //
  'ç': 'c', 'ñ': 'n', 'ÿ': 'y',
};

/// Minuscules, sans accents, « œ » → « oe » ; tout ce qui n'est pas une
/// lettre ou un chiffre devient une espace.
String simplifier(String texte) {
  final b = StringBuffer();
  for (final r in texte.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    if (c == 'œ') {
      b.write('oe');
    } else if (c == 'æ') {
      b.write('ae');
    } else if (_accents.containsKey(c)) {
      b.write(_accents[c]);
    } else if ((r >= 97 && r <= 122) || (r >= 48 && r <= 57)) {
      b.write(c);
    } else {
      b.write(' ');
    }
  }
  return b.toString();
}

/// Les mots d'un texte simplifié.
List<String> motsDe(String texte) => [
  for (final m in simplifier(texte).split(' '))
    if (m.isNotEmpty) m,
];

const _motsVides = {
  'de', 'd', 'du', 'des', 'la', 'le', 'les', 'l', 'a', 'au', 'aux', //
  'et', 'en', 'un', 'une', 'avec', 'sans', 'pour', 'sur',
};

/// Des mots en -s qui ne sont pas des pluriels (« pois », « maïs »).
const _invariables = {
  'pois', 'mais', 'radis', 'anis', 'cassis', 'ananas', 'jus', 'gras', //
  'gros', 'frais', 'dos', 'bois', 'fois',
};

/// Un mot au singulier : « oeufs » → « oeuf », « gateaux » → « gateau » ;
/// « noix », « riz », « jus », « pois », « maïs » ne bougent pas.
String singulier(String m) {
  if (m.length <= 3 || _invariables.contains(m)) return m;
  if (m.endsWith('s')) return m.substring(0, m.length - 1);
  if (m.endsWith('aux') || m.endsWith('eux') || m.endsWith('oux')) {
    return m.substring(0, m.length - 1);
  }
  return m;
}

/// Les mots d'une recherche : sans mots vides, au singulier (« oeufs » →
/// « oeuf », « tomates » → « tomate »).
List<String> motsRecherche(String requete) => [
  for (final m in motsDe(requete))
    if (!_motsVides.contains(m)) singulier(m),
];

// ═══ La base ════════════════════════════════════════════════════════════════

class BaseAliments {
  BaseAliments(this.aliments)
    : _parCode = {for (final a in aliments) a.code: a};

  final List<AlimentBase> aliments;
  final Map<int, AlimentBase> _parCode;

  AlimentBase? parCode(int code) => _parCode[code];

  /// Lit `fcen.txt` (format décrit dans `tool/extraire_fcen.py`). Une ligne
  /// illisible est sautée.
  static BaseAliments analyser(String texte) {
    final mesures = <String, String>{};
    final aliments = <AlimentBase>[];
    double? n(String s) => s.isEmpty ? null : double.tryParse(s);
    for (final ligne in texte.split('\n')) {
      if (ligne.isEmpty || ligne.startsWith('#')) continue;
      final c = ligne.split('\t');
      if (c[0] == 'M' && c.length >= 3) {
        mesures[c[1]] = c[2];
      } else if (c[0] == 'A' && c.length >= 13) {
        final code = int.tryParse(c[1]);
        final groupe = int.tryParse(c[2]);
        final kcal = n(c[4]);
        if (code == null || groupe == null || kcal == null) continue;
        final portions = <Portion>[];
        if (c[12].isNotEmpty) {
          for (final p in c[12].split(',')) {
            final i = p.indexOf(':');
            if (i <= 0) continue;
            final libelle = mesures[p.substring(0, i)];
            final g = double.tryParse(p.substring(i + 1));
            if (libelle != null && g != null && g > 0) {
              portions.add(Portion(libelle, g));
            }
          }
        }
        aliments.add(
          AlimentBase(
            code: code,
            groupe: groupe,
            nom: c[3],
            pour100g: Nutriments(
              kcal: kcal,
              proteines: n(c[5]) ?? 0,
              glucides: n(c[6]) ?? 0,
              lipides: n(c[7]) ?? 0,
              fibres: n(c[8]) ?? 0,
              sucres: n(c[9]) ?? 0,
              sodium: n(c[10]) ?? 0,
              satures: n(c[11]) ?? 0,
            ),
            portions: portions,
          ),
        );
      }
    }
    return BaseAliments(aliments);
  }

  /// Les aliments qui répondent à [requete], les meilleurs d'abord.
  /// [frequents] : code → nombre de fois mangé (ils passent devant).
  List<AlimentBase> rechercher(
    String requete, {
    Map<int, int> frequents = const {},
    int max = 40,
  }) {
    final q = motsRecherche(requete);
    if (q.isEmpty) return const [];
    final notes = <(AlimentBase, double)>[];
    for (final a in aliments) {
      final s = note(a, q, frequents[a.code] ?? 0);
      if (s != null) notes.add((a, s));
    }
    notes.sort((x, y) {
      final d = y.$2.compareTo(x.$2);
      return d != 0 ? d : x.$1.nom.length.compareTo(y.$1.nom.length);
    });
    return [for (final (a, _) in notes.take(max)) a];
  }

  /// La note d'un aliment pour les mots [q] ; `null` s'il ne répond pas
  /// (chaque mot doit commencer un mot du nom).
  static double? note(AlimentBase a, List<String> q, int frequence) {
    var s = 0.0;
    for (final (i, m) in q.indexed) {
      final j = a.mots.indexWhere((w) => w.startsWith(m));
      if (j < 0) return null;
      if (i == 0 && j == a._debut) s += 50;
      if (j < 3) s += 6;
      if (a.mots[j] == m) s += 8;
    }
    // La première partie du nom EST ce qu'on cherche (« pomme » →
    // « Pomme, crue » avant « Pomme cannelle, crue » et « Pommette ») ; à
    // moitié pendant la frappe (« pom »).
    if (a._tete.length == q.length) {
      var exacte = true, debut = true;
      for (var i = 0; i < q.length; i++) {
        if (a._tete[i] != q[i]) exacte = false;
        if (!a._tete[i].startsWith(q[i])) debut = false;
      }
      if (exacte) {
        s += 15;
      } else if (debut) {
        s += 5;
      }
    }
    s -= a._segments * 4;
    s -= a.nom.length / 10;
    if (a._marque) s -= 15;
    if (a.groupe == GroupesFcen.pretsAManger ||
        a.groupe == GroupesFcen.metsComposes) {
      s -= 8;
    }
    final crus = a.mots.contains('cru') || a.mots.contains('crue');
    if (crus &&
        (a.groupe == GroupesFcen.fruits || a.groupe == GroupesFcen.legumes)) {
      s += 10;
    }
    final cuit = a.mots.contains('cuit') || a.mots.contains('cuite');
    if (cuit &&
        (a.groupe == GroupesFcen.cereales ||
            a.groupe == GroupesFcen.legumineuses)) {
      s += 8;
    }
    if (kAlimentsCourants.contains(a.code)) s += 35;
    if (kAliasQuebec[q.first] == a.code) s += 60;
    if (frequence > 0) s += 100 + frequence * 5;
    return s;
  }
}

/// La base, lue une fois (dans un isolat : le fichier fait 740 Ko).
final baseAlimentsProvider = FutureProvider<BaseAliments>((ref) async {
  final texte = await rootBundle.loadString('assets/donnees/fcen.txt');
  return compute(BaseAliments.analyser, texte);
});

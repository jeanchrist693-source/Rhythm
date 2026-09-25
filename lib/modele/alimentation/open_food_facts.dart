// lib/modele/alimentation/open_food_facts.dart
//
// Un CODE-BARRES scanné → un produit de « Mes produits », rempli par OPEN
// FOOD FACTS (la base libre et collaborative des produits emballés, Licence
// ODbL) : son nom, sa marque, la portion de l'emballage et le tableau de la
// valeur nutritive. Pur et tolérant : la réponse est lue telle quelle, un
// champ absent ou faux est ignoré, et rien n'est inventé — une valeur
// absente reste vide, à recopier de l'étiquette.
//
// - [normaliserCode] : les chiffres seulement, la CLÉ DE CONTRÔLE vérifiée
//   (un code mal lu ou mal tapé ne part pas en ligne) ; un UPC-A (12
//   chiffres, l'Amérique du Nord) ou un UPC-E (8, compressé) devient l'EAN-13
//   qui désigne le même produit — un seul code par produit ;
// - [brouillonDepuisOff] : la réponse de l'API (v2) → un brouillon de
//   [Produit] (sans identifiant, pas encore enregistré), ou `null` si Open
//   Food Facts ne connaît pas le produit.

import 'alimentation.dart';
import 'nutriments.dart';

/// Les chiffres d'un code-barres, contrôlés et ramenés à un seul format
/// (EAN-13, ou EAN-8) ; `null` si ce n'est pas un code-barres de produit
/// valide. [upcE] : la caméra a lu un UPC-E (8 chiffres, comme un EAN-8 —
/// il est déplié d'abord).
String? normaliserCode(String brut, {bool upcE = false}) {
  final c = brut.replaceAll(RegExp(r'\D'), '');
  switch (c.length) {
    case 8:
      final upcA = _upcEVersUpcA(c);
      final deplie = upcA != null && _cleValide(upcA) ? '0$upcA' : null;
      if (upcE && deplie != null) return deplie;
      return _cleValide(c) ? c : deplie; // EAN-8, sinon UPC-E
    case 12: // UPC-A
      return _cleValide(c) ? '0$c' : null;
    case 13: // EAN-13
      return _cleValide(c) ? c : null;
    case 14: // GTIN-14 d'un seul article : un 0 devant l'EAN-13
      return c.startsWith('0') && _cleValide(c) ? c.substring(1) : null;
  }
  return null;
}

/// La clé de contrôle GS1 (le dernier chiffre) : de droite à gauche, les
/// chiffres pèsent 3, 1, 3, 1… ; la somme avec la clé tombe sur une dizaine.
bool _cleValide(String c) {
  var somme = 0;
  for (var i = c.length - 2, poids = 3; i >= 0; i--, poids = 4 - poids) {
    somme += (c.codeUnitAt(i) - 48) * poids;
  }
  return (somme + c.codeUnitAt(c.length - 1) - 48) % 10 == 0;
}

/// Un UPC-E (8 chiffres : système 0 ou 1, six chiffres, la clé) déplié en
/// UPC-A (12), ou `null`.
String? _upcEVersUpcA(String e) {
  if (e[0] != '0' && e[0] != '1') return null;
  final d = e.substring(1, 7), cle = e[7];
  final dernier = d.codeUnitAt(5) - 48;
  final String corps;
  if (dernier <= 2) {
    corps = '${d.substring(0, 2)}${d[5]}0000${d.substring(2, 5)}';
  } else if (dernier == 3) {
    corps = '${d.substring(0, 3)}00000${d.substring(3, 5)}';
  } else if (dernier == 4) {
    corps = '${d.substring(0, 4)}00000${d[4]}';
  } else {
    corps = '${d.substring(0, 5)}0000${d[5]}';
  }
  return '${e[0]}$corps$cle';
}

/// Le code lisible, par groupes (« 0 12345 67890 5 », « 1234 5670 »).
String codeLisible(String code) => switch (code.length) {
  13 => '${code[0]} ${code.substring(1, 7)} ${code.substring(7)}',
  8 => '${code.substring(0, 4)} ${code.substring(4)}',
  _ => code,
};

/// Ce qu'Open Food Facts sait d'un produit, prêt à être vérifié.
class BrouillonOff {
  const BrouillonOff({required this.produit, required this.valeursConnues});

  /// Le produit (sans identifiant), avec son code-barres.
  final Produit produit;

  /// Faux : Open Food Facts n'a pas la valeur nutritive (à recopier de
  /// l'étiquette).
  final bool valeursConnues;
}

/// Les champs demandés à l'API (rien de plus ne revient).
const String kChampsOff =
    'code,product_name,product_name_fr,product_name_en,generic_name,'
    'generic_name_fr,brands,serving_size,serving_quantity,'
    'serving_quantity_unit,nutriments';

/// La réponse de l'API v2 (`{"status": 1, "product": {…}}`) lue ; `null` :
/// produit inconnu (ou réponse vide).
BrouillonOff? brouillonDepuisOff(Object? reponse, {required String code}) {
  if (reponse is! Map) return null;
  final p = reponse['product'];
  if (reponse['status'] == 0 || p is! Map || p.isEmpty) return null;

  final nom = _premierTexte([
    p['product_name_fr'],
    p['product_name'],
    p['product_name_en'],
    p['generic_name_fr'],
    p['generic_name'],
  ]);
  final marques = _texte(p['brands']);
  final marque = marques.split(',').first.trim();

  final n = p['nutriments'] is Map ? p['nutriments'] as Map : const {};
  double? val(String cle) => _nombre(n[cle]);

  // La portion de l'emballage, si elle est donnée ; sinon 100 g (ou 100 ml).
  final qte = _nombre(p['serving_quantity']);
  final unite = _texte(p['serving_quantity_unit']).toLowerCase() == 'ml'
      ? 'ml'
      : 'g';
  final parPortion = qte != null && qte > 0 && qte <= 2000;
  final grammes = parPortion ? qte : 100.0;
  final taille = _texte(p['serving_size']);
  final libelle = parPortion
      ? (taille.isNotEmpty ? taille : '${_court(qte)} $unite')
      : '100 $unite';

  /// Un nutriment pour la portion : celui de la portion s'il est donné,
  /// sinon celui des 100 g à la règle de trois.
  double? pour(String base) {
    if (parPortion) {
      final s = val('${base}_serving');
      if (s != null) return s;
    }
    final c = val('${base}_100g');
    return c == null ? null : c * grammes / 100;
  }

  var kcal = pour('energy-kcal');
  if (kcal == null) {
    final kj = pour('energy-kj') ?? pour('energy');
    if (kj != null) kcal = kj / 4.184;
  }
  var sodium = pour('sodium');
  if (sodium == null) {
    final sel = pour('salt');
    if (sel != null) sodium = sel / 2.5;
  }

  return BrouillonOff(
    produit: Produit(
      id: '',
      nom: nom,
      marque: marque.isEmpty ? null : marque,
      portion: libelle,
      grammesPortion: grammes,
      codeBarres: code,
      parPortion: Nutriments(
        kcal: _arrondi(kcal ?? 0, 0),
        lipides: _arrondi(pour('fat') ?? 0, 1),
        satures: _arrondi(pour('saturated-fat') ?? 0, 1),
        glucides: _arrondi(pour('carbohydrates') ?? 0, 1),
        fibres: _arrondi(pour('fiber') ?? 0, 1),
        sucres: _arrondi(pour('sugars') ?? 0, 1),
        proteines: _arrondi(pour('proteins') ?? 0, 1),
        // Open Food Facts donne le sodium en grammes.
        sodium: _arrondi((sodium ?? 0) * 1000, 0),
      ),
    ),
    valeursConnues: kcal != null,
  );
}

String _texte(Object? v) =>
    v is String ? v.replaceAll(RegExp(r'\s+'), ' ').trim() : '';

String _premierTexte(List<Object?> v) {
  for (final x in v) {
    final t = _texte(x);
    if (t.isNotEmpty) return t;
  }
  return '';
}

double? _nombre(Object? v) {
  final x = v is num
      ? v.toDouble()
      : (v is String ? double.tryParse(v.replaceAll(',', '.')) : null);
  return x == null || !x.isFinite || x < 0 ? null : x;
}

double _arrondi(double x, int decimales) {
  final f = decimales == 0 ? 1 : 10;
  return (x * f).round() / f;
}

String _court(double x) =>
    x == x.roundToDouble() ? '${x.round()}' : '$x'.replaceAll('.', ',');

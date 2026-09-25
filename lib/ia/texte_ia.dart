// lib/ia/texte_ia.dart
//
// Un texte venu de l'IA, rendu PROPRE pour Rhythm avant d'être affiché ou
// gardé (une recette générée devient de la donnée comme les autres) :
// - sans Markdown (gras, titres, puces « - » → « • ») ni emoji ;
// - apostrophes DROITES (le contenu de Rhythm les emploie partout) ;
// - les glyphes absents de DM Sans et de Bricolage remplacés (« ≈ » →
//   « env. », « → », « ≥ », « ≤ », « ✓ ») : sinon, un carré vide ;
// - les espaces fines (U+202F, U+2009 — absentes des polices) deviennent
//   des insécables U+00A0 ;
// - en français : insécable avant « ? ! ; : », dans « … », entre un nombre
//   et son unité (« 20 minutes », « 250 ml », « 190 °C »).

/// Le texte de [v] (une chaîne de la réponse), nettoyé ; '' sinon.
String texteIa(Object? v, {bool francais = true}) {
  if (v is! String) return '';
  var s = v.trim();
  if (s.isEmpty) return s;

  // Les espaces fines (absentes des polices) → insécable ; le trait
  // insécable (absent) → trait d'union.
  s = s
      .replaceAll(RegExp('[    ]'), ' ')
      .replaceAll('‑', '-')
      .replaceAll(RegExp('[‘’ʼ]'), "'");

  // Markdown.
  s = s
      .replaceAll('**', '')
      .replaceAll('__', '')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ');

  // Les glyphes absents.
  s = s
      .replaceAll(RegExp(r'\s*→\s*'), ' — ')
      .replaceAll(RegExp(r'≈\s*'), francais ? 'env. ' : 'about ')
      .replaceAll(RegExp(r'≥\s*'), francais ? 'au moins ' : 'at least ')
      .replaceAll(RegExp(r'≤\s*'), francais ? 'au plus ' : 'at most ')
      .replaceAll(RegExp('[✓✔✦★✨]\\s*'), '')
      // Emoji et pictogrammes (plans supplémentaires, symboles divers).
      .replaceAll(
        RegExp(
          r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]\s?',
          unicode: true,
        ),
        '',
      );

  if (francais) {
    // Guillemets anglais → français.
    s = s
        .replaceAll(RegExp(r'“\s*'), '« ')
        .replaceAll(RegExp(r'\s*”'), ' »')
        .replaceAll(RegExp(r'«[  ]*'), '« ')
        .replaceAll(RegExp(r'[  ]*»'), ' »');
    // Insécable avant la ponctuation haute (pas « 18:30 », pas « http:// »).
    s = s.replaceAllMapped(
      RegExp(r'([^\s ]) ?([?!;:])(?=\s|$)', multiLine: true),
      (m) => '${m[1]} ${m[2]}',
    );
    // Un nombre et son unité.
    s = s.replaceAllMapped(
      RegExp(
        r'(\d) (?=(?:g|kg|mg|ml|mL|cl|l|L|min|minutes?|h|heures?|s|secondes?'
        r'|°C|°F|°|kcal|cal|%|\$|portions?|jours?|mois|semaines?|ans?|cm|mm|'
        r'tasses?|c\.|gousses?|tranches?)(?![\p{L}\d]))',
        unicode: true,
      ),
      (m) => '${m[1]} ',
    );
  }
  return s.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
}

/// Une liste de textes (les étapes, les pistes) : chacun nettoyé, les vides
/// retirés, la numérotation enlevée (« 1. », « Étape 2 : »).
List<String> textesIa(Object? v, {bool francais = true}) => [
  if (v is List)
    for (final x in v)
      if (texteIa(x, francais: francais) case final t when t.isNotEmpty)
        t.replaceFirst(
          RegExp(
            r'^(?:(?:é|e)tape\s*)?\d{1,2}\s*[.):\-–]\s*',
            caseSensitive: false,
          ),
          '',
        ),
];

// lib/widgets/chemin_svg.dart
//
// Lit l'attribut `d` d'un chemin SVG et en fait un `Path`. Les pictogrammes
// et les mascottes de Rhythm sont dessinés À PARTIR DES TRACÉS DE LA
// MAQUETTE, recopiés tels quels (grille 24 des pictos, 150 × 120 des
// mascottes) : rien n'est « à peu près ».
//
// Commandes : M L H V C S Q T A Z, absolues et relatives, répétitions
// implicites comprises (« m80 22 4 4 8-8 » = un déplacement puis deux
// traits). Les drapeaux d'un arc doivent être séparés par des espaces (c'est
// le cas de tous les tracés de la maquette).

import 'dart:ui';

final Map<String, Path> _deja = {};

/// Le `Path` du tracé [d] (mis en cache : les tracés sont constants).
Path cheminSvg(String d) => _deja.putIfAbsent(d, () => _lire(d));

final RegExp _jeton = RegExp(
  r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);

Path _lire(String d) {
  final jetons = [for (final m in _jeton.allMatches(d)) m.group(0)!];
  final chemin = Path();
  var i = 0;
  var commande = '';
  // Point courant, début du sous-chemin, derniers points de contrôle.
  var x = 0.0, y = 0.0, debutX = 0.0, debutY = 0.0;
  double? cubiqueX, cubiqueY, quadX, quadY;

  bool estCommande(String j) => j.length == 1 && RegExp('[A-Za-z]').hasMatch(j);
  double nombre() => double.parse(jetons[i++]);

  while (i < jetons.length) {
    if (estCommande(jetons[i])) {
      commande = jetons[i++];
    } else if (commande.isEmpty || commande == 'Z' || commande == 'z') {
      // Des nombres sans commande : tracé invalide (sinon boucle sans fin).
      throw FormatException('Nombre sans commande dans le tracé', d);
    }
    final relatif = commande == commande.toLowerCase();
    final ox = relatif ? x : 0.0;
    final oy = relatif ? y : 0.0;
    var garderCubique = false;
    var garderQuad = false;

    switch (commande.toUpperCase()) {
      case 'M':
        x = ox + nombre();
        y = oy + nombre();
        chemin.moveTo(x, y);
        debutX = x;
        debutY = y;
        // Les paires suivantes sont des traits (implicites).
        commande = relatif ? 'l' : 'L';
      case 'L':
        x = ox + nombre();
        y = oy + nombre();
        chemin.lineTo(x, y);
      case 'H':
        x = ox + nombre();
        chemin.lineTo(x, y);
      case 'V':
        y = oy + nombre();
        chemin.lineTo(x, y);
      case 'C':
        final x1 = ox + nombre(), y1 = oy + nombre();
        final x2 = ox + nombre(), y2 = oy + nombre();
        x = ox + nombre();
        y = oy + nombre();
        chemin.cubicTo(x1, y1, x2, y2, x, y);
        (cubiqueX, cubiqueY, garderCubique) = (x2, y2, true);
      case 'S':
        final x1 = cubiqueX == null ? x : 2 * x - cubiqueX;
        final y1 = cubiqueY == null ? y : 2 * y - cubiqueY;
        final x2 = ox + nombre(), y2 = oy + nombre();
        x = ox + nombre();
        y = oy + nombre();
        chemin.cubicTo(x1, y1, x2, y2, x, y);
        (cubiqueX, cubiqueY, garderCubique) = (x2, y2, true);
      case 'Q':
        final x1 = ox + nombre(), y1 = oy + nombre();
        x = ox + nombre();
        y = oy + nombre();
        chemin.quadraticBezierTo(x1, y1, x, y);
        (quadX, quadY, garderQuad) = (x1, y1, true);
      case 'T':
        final x1 = quadX == null ? x : 2 * x - quadX;
        final y1 = quadY == null ? y : 2 * y - quadY;
        x = ox + nombre();
        y = oy + nombre();
        chemin.quadraticBezierTo(x1, y1, x, y);
        (quadX, quadY, garderQuad) = (x1, y1, true);
      case 'A':
        final rx = nombre(), ry = nombre(), rotation = nombre();
        final grandArc = nombre() != 0, sensHoraire = nombre() != 0;
        x = ox + nombre();
        y = oy + nombre();
        chemin.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: grandArc,
          clockwise: sensHoraire,
        );
      case 'Z':
        chemin.close();
        x = debutX;
        y = debutY;
      default:
        throw FormatException('Commande SVG inconnue « $commande »', d);
    }
    // Le reflet de S / T ne vaut que juste après une courbe du même type.
    if (!garderCubique) cubiqueX = cubiqueY = null;
    if (!garderQuad) quadX = quadY = null;
  }
  return chemin;
}

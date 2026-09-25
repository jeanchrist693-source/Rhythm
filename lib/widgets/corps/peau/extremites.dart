// lib/widgets/corps/peau/extremites.dart
//
// Les EXTRÉMITÉS : les mains et les pieds (chaussés).

part of '../peau3.dart';

extension _Extremites on Peau3 {
  /// Une main en deux volumes (la paume et les doigts repliés, le pouce) :
  /// les petites figures.
  void _mainSimple(Squelette3 s, Membre3 b, double cote, int partie) {
    final dAvant = (b.bout - b.milieu).unite;
    final axe = (b.extremite - b.bout).unite;
    var paume = _Membres._avantBras(s, dAvant).sansComposante(axe);
    paume = paume.norme < 1e-3 ? s.avantEpaules.sansComposante(axe) : paume;
    paume = paume.unite;
    final largeur = axe.cross(paume).unite * -cote;
    _ellipsoide(
      b.bout + axe * 0.032,
      axe * 0.034,
      largeur * 0.021,
      paume * 0.014,
      _peau,
      fonduVers: -1,
      partie: partie,
    );
    _ellipsoide(
      b.bout + largeur * 0.017 + paume * 0.01 + axe * 0.022,
      (axe + largeur * 0.4).unite * 0.016,
      largeur * 0.009,
      paume * 0.009,
      _peau,
      trait: 0,
      petit: true,
      partie: partie,
    );
  }

  /// La CHAUSSURE, une basket : balayée du talon aux orteils — le
  /// contrefort du talon, le col autour de la cheville, le laçage sur le
  /// cou-de-pied, le bout arrondi ; dessous, la semelle intermédiaire
  /// blanche et la semelle d'usure grise. Sur la pointe (planche, pompe,
  /// fente), l'avant du pied se PLIE à la base des orteils et reste à plat
  /// sur le sol au lieu de le traverser.
  void _chaussure3(Membre3 j, V3 talon, int partie) {
    final f = (j.extremite - talon).unite;
    final haut = (j.bout - talon).sansComposante(f).unite;
    final lat = f.cross(haut).unite;
    // La longueur d'un vrai pied chaussé (≈ 26 cm) : le talon, les orteils.
    final debut = talon - f * 0.007, bout = j.extremite + f * 0.004;
    final longueur = (bout - debut).norme;
    // (u, demi-largeur, hauteur de l'empeigne, échelle de la section)
    const profil = [
      (0.0, 0.015, 0.02, 0.0),
      (0.03, 0.017, 0.03, 0.72),
      (0.08, 0.02, 0.041, 0.94),
      (0.16, 0.022, 0.047, 1.0),
      (0.26, 0.023, 0.046, 1.0),
      (0.36, 0.0245, 0.038, 1.0),
      (0.46, 0.026, 0.033, 1.0),
      (0.56, 0.027, 0.029, 1.0),
      (0.66, 0.0278, 0.025, 1.0),
      (0.74, 0.028, 0.022, 1.0),
      (0.82, 0.027, 0.0205, 1.0),
      (0.9, 0.0245, 0.019, 0.97),
      (0.96, 0.02, 0.016, 0.84),
      (1.0, 0.011, 0.011, 0.0),
    ];
    // La plante : l'avant du pied se plie ici.
    const uPli = 0.7;
    final pli = debut + f * (uPli * longueur);
    var angle = 0.0;
    if (pli.y > kSol - 0.035 && f.y > 0.03) {
      // L'angle qui ramène l'avant du pied à plat (bornée : les orteils ne
      // se plient pas au-delà).
      angle = math.atan2(f.y, math.max(1e-3, -haut.y)).clamp(0.0, rad(68));
    }
    final axe = f.cross(haut).unite;
    // La section : l'empeigne (un arc), puis la semelle (intermédiaire,
    // puis d'usure).
    const arc = 12;
    const semelle = [
      (-1.0, -0.001),
      (-0.97, -0.0055),
      (-0.9, -0.0075),
      (-0.3, -0.008),
      (0.3, -0.008),
      (0.9, -0.0075),
      (0.97, -0.0055),
      (1.0, -0.001),
    ];
    const cols = arc + 1 + 8;
    final g = _Grille(profil.length, cols);
    g.teindre(_chaussure.couleur);
    for (var i = 0; i < profil.length; i++) {
      final (u, w, hh, e) = profil[i];
      var base = debut + f * (u * longueur);
      var h = haut, l = lat;
      if (angle > 0 && u > uPli - 0.08) {
        final a = angle * _lisse(uPli - 0.08, uPli + 0.1, u);
        base = pli + (base - pli).tourne(axe, a);
        h = h.tourne(axe, a);
        l = l.tourne(axe, a);
      }
      for (var k = 0; k < cols; k++) {
        final (x, y) = k <= arc
            ? (
                math.cos(math.pi * k / arc),
                hh * math.pow(math.sin(math.pi * k / arc), 0.8).toDouble(),
              )
            : semelle[k - arc - 1];
        final q = i * cols + k;
        g.poser(q, base + (l * (x * w) + h * (y + 0.0015)) * e);
        // Le laçage : une bande plus grise sur le cou-de-pied, des lacets.
        if (k > 3 && k < arc - 3 && u > 0.3 && u < 0.7) {
          final lacet = (u * 36).floor().isEven;
          g.meler(q, lacet ? 0xFF8F9098 : 0xFFC6C7CF, 0.8);
        }
        // Le col, rembourré, un peu plus sombre ; le contrefort.
        if (u < 0.3 && k > 2 && k < arc - 2 && y > hh * 0.85) {
          g.meler(q, 0xFFA9AAB3, 0.6);
        }
        // Le liseré de la semelle intermédiaire.
        if (k <= arc && y < 0.004) g.meler(q, 0xFFF6F6F8, 0.7);
      }
    }
    for (var i = 0; i < profil.length - 1; i++) {
      for (var k = arc; k < cols; k++) {
        g.matiere[i * cols + k] = 1;
      }
    }
    _emettre(g, const [_chaussure, _semelle], partie: partie);
  }
}

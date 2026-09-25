// lib/widgets/scene_ouverture.dart
//
// La scène d'ouverture de Rhythm, une fois par lancement. Sur le noir OLED,
// le logo se compose EN MESURE :
//
//   1. le décompte — « 1, 2, 3, 4 » : les quatre capsules naissent l'une
//      après l'autre, chacune d'un point qui éclot (léger rebond) ;
//   2. chaque point S'ÉTIRE aussitôt à sa hauteur, avec le ressort d'une
//      barre d'égaliseur — le logo est posé ;
//   3. le POULS : un double battement (« boum-boum », le second plus doux)
//      parcourt les capsules de gauche à droite. C'est le rythme — et la
//      santé ;
//   4. « Rhythm » monte en fondu sous le logo, PENDANT que les dernières
//      capsules s'étirent (jamais après une pause : c'est le recouvrement
//      qui fait la coulée — leçon MyTV) ;
//   5. un instant immobile, puis tout s'efface en grandissant légèrement
//      pendant que l'accueil entre dessous (signal [SceneOuverture.ouvert],
//      écouté par la coquille).
//
// Pourquoi dans Flutter et pas dans l'écran de démarrage d'Android (leçon
// de Studio, 23 septembre 2026) : lancé depuis l'icône, Samsung agrandit
// l'icône PAR-DESSUS le splash, et Android coupe l'animation d'un splash à
// 1 s. Le splash système est donc un simple noir (le zoom de l'icône s'y
// fond) et la scène attend la fin du zoom avant de commencer.
//
// Toutes les durées sont ci-dessous, en un seul endroit.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/rhythm_couleurs.dart';
import '../theme/rhythm_typo.dart';
import 'logo_rhythm.dart';

class SceneOuverture extends StatefulWidget {
  const SceneOuverture({super.key});

  /// Noir, le temps que le zoom d'ouverture de l'icône se termine.
  static const int attenteMs = 400;

  /// Le décompte : d'une capsule à la suivante.
  static const int pasBarreMs = 110;

  /// Un point éclot.
  static const int naissanceMs = 260;

  /// Il commence à s'étirer avant d'avoir fini d'éclore (recouvrement)…
  static const int departEtirementMs = 160;

  /// …et atteint sa hauteur.
  static const int etirementMs = 460;

  /// Le pouls : d'une capsule à la suivante…
  static const int pasPulsationMs = 60;

  /// …et la durée du double battement sur une capsule.
  static const int pulsationMs = 520;

  /// « Rhythm » monte (le geste de MyTV : courbe en S, 900 ms)…
  static const int motMs = 900;

  /// …à partir d'ici, quand la troisième capsule s'étire encore.
  static const int debutMotMs = attenteMs + 700;

  /// Le logo complet reste immobile.
  static const int maintienMs = 250;

  /// Il s'efface pendant que l'accueil entre.
  static const int sortieMs = 450;

  static const int _debutPulsation =
      attenteMs + 3 * pasBarreMs + departEtirementMs + etirementMs;
  static const int _debutSortie =
      _debutPulsation + 3 * pasPulsationMs + pulsationMs + maintienMs;
  static const int _totalMs = _debutSortie + sortieMs;

  /// Côté du carré du logo.
  static const double cadreLogo = 124;

  /// Vrai quand l'accueil peut entrer (le logo commence à s'effacer).
  static final ValueNotifier<bool> ouvert = ValueNotifier(false);

  static bool _active = false;

  /// La scène joue (appelé par `main`). Faux dans les tests : l'app y entre
  /// tout de suite.
  static bool get active => _active;
  static void activer() => _active = true;

  /// Bancs d'essai : rejouer la scène comme au premier lancement.
  @visibleForTesting
  static void reinitialiser({bool active = false}) {
    _active = active;
    ouvert.value = false;
  }

  @override
  State<SceneOuverture> createState() => _SceneOuvertureState();
}

class _SceneOuvertureState extends State<SceneOuverture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: SceneOuverture._totalMs),
  );
  bool _finie = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!SceneOuverture.ouvert.value &&
          _c.value * SceneOuverture._totalMs >= SceneOuverture._debutSortie) {
        SceneOuverture.ouvert.value = true;
      }
    });
    _c.addStatusListener((statut) {
      if (statut == AnimationStatus.completed && mounted) {
        setState(() => _finie = true);
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Avancement (0 → 1) d'une phase qui commence à [debut] et dure [duree].
  static double _phase(double t, int debut, int duree) =>
      ((t - debut) / duree).clamp(0.0, 1.0);

  /// Une bosse sur [debut, fin] (fractions de la pulsation) : attaque
  /// vive, retombée plus lente — un battement, pas une vague.
  static double _bosse(double u, double debut, double fin) {
    if (u <= debut || u >= fin) return 0;
    final x = (u - debut) / (fin - debut);
    return x < 0.35
        ? Curves.easeOutCubic.transform(x / 0.35)
        : 1 - Curves.easeInOutCubic.transform((x - 0.35) / 0.65);
  }

  /// (largeur, hauteur) de chaque capsule à l'instant [t] (ms).
  static List<(double, double)> _capsules(double t) => [
    for (var i = 0; i < 4; i++) _capsule(t, i),
  ];

  static (double, double) _capsule(double t, int i) {
    final debut = SceneOuverture.attenteMs + i * SceneOuverture.pasBarreMs;
    final naissance = Curves.easeOutBack.transform(
      _phase(t, debut, SceneOuverture.naissanceMs),
    );
    if (naissance <= 0) return (0, 0);
    final etirement = Curves.easeOutBack.transform(
      _phase(
        t,
        debut + SceneOuverture.departEtirementMs,
        SceneOuverture.etirementMs,
      ),
    );
    final u = _phase(
      t,
      SceneOuverture._debutPulsation + i * SceneOuverture.pasPulsationMs,
      SceneOuverture.pulsationMs,
    );
    final pouls = 1 + 0.22 * _bosse(u, 0, 0.42) + 0.12 * _bosse(u, 0.46, 0.9);
    final largeur = LogoRhythm.largeurBarre * naissance;
    final hauteur =
        (largeur + (LogoRhythm.hauteurs[i] - largeur) * etirement) * pouls;
    return (largeur, math.max(hauteur, largeur));
  }

  @override
  Widget build(BuildContext context) {
    if (_finie) return const SizedBox.shrink();
    // Posée au-dessus du Navigator (`MaterialApp.builder`), hors de tout
    // `Material` : sans celui-ci, « Rhythm » hériterait du style d'erreur
    // (souligné double jaune).
    return Material(type: MaterialType.transparency, child: _scene());
  }

  Widget _scene() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * SceneOuverture._totalMs;
        final mot = Curves.easeInOutCubic.transform(
          _phase(t, SceneOuverture.debutMotMs, SceneOuverture.motMs),
        );
        final sortie = Curves.easeOutCubic.transform(
          _phase(t, SceneOuverture._debutSortie, SceneOuverture.sortieMs),
        );
        return AbsorbPointer(
          // Rien ne se touche sous la scène, jusqu'à sa sortie.
          absorbing: sortie < 0.5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: RhythmCouleurs.fond.withValues(alpha: 1 - sortie),
              ),
              Center(
                child: Opacity(
                  opacity: 1 - sortie,
                  child: Transform.scale(
                    scale: 1 + 0.06 * sortie,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            size: const Size.square(SceneOuverture.cadreLogo),
                            painter: PeintreLogo(_capsules(t)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: mot,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - mot)),
                            child: Transform.scale(
                              scale: 0.96 + 0.04 * mot,
                              child: Text(
                                'Rhythm',
                                style: RhythmTypo.titre(40),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

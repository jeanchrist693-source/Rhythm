// lib/widgets/barre_navigation.dart
//
// La barre du bas de la maquette : une CAPSULE de verre FLOTTANTE (20 des
// bords, 68 de haut, coins 34) — dégradé blanc 16 → 7 %, bord 18 %, reflet
// sous le bord haut, ombre noire 60 % autour, et le contenu qui défile
// dessous flouté (28) et saturé (160 %). C'est le SEUL verre flouté de l'app.
//
// Cinq destinations. L'active est une capsule blanche 14 % avec pictogramme
// ET libellé ; les autres, un pictogramme seul (secondaire). D'une
// destination à l'autre, la capsule se déplie ici et se replie là
// (300 ms) : les voisines glissent, rien ne saute.
//
// À l'étroit (« Alimentation » sur un écran de 384), les destinations
// inactives cèdent la place qu'il faut — comme `flex-shrink` dans la
// maquette.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/rhythm_couleurs.dart';
import '../theme/rhythm_mesures.dart';
import '../theme/rhythm_typo.dart';
import 'pictos.dart';
import 'pression_echelle.dart';
import 'surfaces.dart';

class DestinationNav {
  const DestinationNav({required this.picto, required this.libelle});

  final Picto picto;
  final String libelle;
}

class BarreNavigation extends StatefulWidget {
  const BarreNavigation({
    super.key,
    required this.destinations,
    required this.index,
    required this.onChange,
    required this.libelle,
  });

  final List<DestinationNav> destinations;
  final int index;
  final ValueChanged<int> onChange;

  /// « Navigation principale » (lecteur d'écran).
  final String libelle;

  @override
  State<BarreNavigation> createState() => _BarreNavigationState();
}

class _BarreNavigationState extends State<BarreNavigation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: RhythmDurees.basculeBarre,
    value: 1,
  );

  /// La destination qui se replie pendant la bascule.
  int _ancien = -1;

  /// Largeur des libellés (mesurée une fois par taille de texte).
  final Map<String, double> _largeurs = {};
  TextScaler? _echelleTexte;

  static const double _cote = 48;
  static const double _marge = 16;
  static const double _ecart = 8;

  static TextStyle get _style => RhythmTypo.texte(14, poids: 600);

  /// `saturate(160%)` (matrice des Filter Effects du W3C).
  static const double _s = 1.6;
  static const ColorFilter _saturation = ColorFilter.matrix([
    0.213 + 0.787 * _s, 0.715 - 0.715 * _s, 0.072 - 0.072 * _s, 0, 0, //
    0.213 - 0.213 * _s, 0.715 + 0.285 * _s, 0.072 - 0.072 * _s, 0, 0, //
    0.213 - 0.213 * _s, 0.715 - 0.715 * _s, 0.072 + 0.928 * _s, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final echelle = MediaQuery.textScalerOf(context);
    if (echelle != _echelleTexte) {
      _echelleTexte = echelle;
      _largeurs.clear();
    }
  }

  @override
  void didUpdateWidget(BarreNavigation ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.index != widget.index) {
      _ancien = ancien.index;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _largeurLibelle(String libelle) => _largeurs.putIfAbsent(libelle, () {
    final mesure = TextPainter(
      text: TextSpan(text: libelle, style: _style),
      textDirection: TextDirection.ltr,
      textScaler: _echelleTexte ?? TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final largeur = mesure.width;
    mesure.dispose();
    return largeur;
  });

  /// 0 = pictogramme seul, 1 = capsule active.
  double _activite(int i) {
    final v = Curves.easeOutCubic.transform(_c.value);
    if (i == widget.index) return v;
    if (i == _ancien) return 1 - v;
    return 0;
  }

  Widget _rangee(double disponible) {
    final n = widget.destinations.length;
    final activites = [for (var i = 0; i < n; i++) _activite(i)];
    final largeurs = [
      for (var i = 0; i < n; i++)
        _cote +
            (_marge +
                    20 +
                    _ecart +
                    _largeurLibelle(widget.destinations[i].libelle) +
                    _marge -
                    _cote) *
                activites[i],
    ];
    // Trop large : les destinations inactives rétrécissent (au prorata de
    // leur part inactive), jamais la capsule active.
    final exces = largeurs.fold(0.0, (s, l) => s + l) - disponible;
    if (exces > 0) {
      final parts = [for (final a in activites) _cote * (1 - a)];
      final total = parts.fold(0.0, (s, p) => s + p);
      if (total > 0) {
        for (var i = 0; i < n; i++) {
          largeurs[i] -= exces * parts[i] / total;
        }
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < n; i++)
          SizedBox(
            width: largeurs[i],
            height: _cote,
            child: _Onglet(
              destination: widget.destinations[i],
              activite: activites[i],
              actif: i == widget.index,
              style: _style,
              onTap: () {
                if (i == widget.index) return;
                HapticFeedback.selectionClick();
                widget.onChange(i);
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rayon = BorderRadius.circular(RhythmRayons.barre);
    return Semantics(
      container: true,
      label: widget.libelle,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          RhythmEspaces.retraitBarre,
          0,
          RhythmEspaces.retraitBarre,
          RhythmEspaces.basBarre(context),
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomPaint(
              painter: const _OmbreExterieure(),
              child: ClipRRect(
                borderRadius: rayon,
                child: BackdropFilter(
                  filter: ui.ImageFilter.compose(
                    outer: _saturation,
                    inner: ui.ImageFilter.blur(
                      sigmaX: RhythmEspaces.flouBarre,
                      sigmaY: RhythmEspaces.flouBarre,
                    ),
                  ),
                  child: CustomPaint(
                    painter: const PeintreVerre(
                      rayon: RhythmRayons.barre,
                      angle: 180,
                      couleurs: RhythmCouleurs.degradeBarre,
                      arrets: [0, 1],
                    ),
                    child: SizedBox(
                      height: RhythmEspaces.hauteurBarre,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: LayoutBuilder(
                          builder: (context, contraintes) => AnimatedBuilder(
                            animation: _c,
                            builder: (_, _) => _rangee(contraintes.maxWidth),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({
    required this.destination,
    required this.activite,
    required this.actif,
    required this.style,
    required this.onTap,
  });

  final DestinationNav destination;
  final double activite;
  final bool actif;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = activite;
    return Semantics(
      button: true,
      selected: actif,
      label: destination.libelle,
      excludeSemantics: true,
      child: PressionEchelle(
        onTap: onTap,
        echelle: 0.92,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: RhythmCouleurs.ongletActif.withValues(
              alpha: RhythmCouleurs.ongletActif.a * a,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRect(
            // Largeur minimale nulle : sinon la rangée hérite de la largeur
            // de la capsule et se cale à gauche au lieu d'être centrée.
            child: OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PictoRhythm(
                    destination.picto,
                    taille: 22 - 2 * a,
                    couleur: Color.lerp(
                      RhythmCouleurs.texte64,
                      RhythmCouleurs.texte,
                      a,
                    )!,
                  ),
                  SizedBox(width: 8 * a),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: a,
                      child: Opacity(
                        opacity: a,
                        child: Text(
                          destination.libelle,
                          maxLines: 1,
                          softWrap: false,
                          style: style,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `box-shadow: 0 10px 30px rgba(0,0,0,.6)` : comme en CSS, l'ombre n'est
/// peinte qu'AUTOUR de la capsule — jamais sous le verre, qu'elle
/// assombrirait.
class _OmbreExterieure extends CustomPainter {
  const _OmbreExterieure();

  @override
  void paint(Canvas canvas, Size size) {
    final capsule = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(RhythmRayons.barre),
    );
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect((Offset.zero & size).inflate(60))
        ..addRRect(capsule),
    );
    canvas.drawRRect(
      capsule.shift(const Offset(0, 10)),
      Paint()
        ..color = RhythmCouleurs.ombreBarre
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OmbreExterieure ancien) => false;
}

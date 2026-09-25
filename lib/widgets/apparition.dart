// lib/widgets/apparition.dart
//
// Un bloc de l'entrée de l'accueil : fondu + montée, sur son intervalle de
// la partition (`EntreeAccueil`). Rien n'est recréé à chaque image : la
// courbe est évaluée dans le builder (une `CurvedAnimation` construite dans
// `build` accrocherait un écouteur de plus à chaque reconstruction).

import 'package:flutter/widgets.dart';

class Apparition extends StatelessWidget {
  const Apparition({
    super.key,
    required this.animation,
    required this.intervalle,
    required this.montee,
    required this.child,
  });

  final Animation<double> animation;
  final Interval intervalle;

  /// Distance parcourue vers le haut, en pixels.
  final double montee;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      // ⚠️ Toujours la même forme d'arbre : rendre l'enfant nu une fois
      // arrivé recréerait tout son sous-arbre (états perdus).
      builder: (_, enfant) {
        final v = intervalle.transform(animation.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, montee * (1 - v)),
            child: enfant,
          ),
        );
      },
    );
  }
}

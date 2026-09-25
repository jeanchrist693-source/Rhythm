// lib/widgets/pression_echelle.dart (repris tel quel de Studio / Net Worth)
//
// Retour tactile universel : léger rétrécissement à la pression, sans ripple.
//
// ⚠️ Deux exigences de l'utilisateur, apprises sur l'appareil :
// 1. La sensation doit exister sur un TOUCHER BREF, pas seulement quand on
//    maintient. Un `GestureDetector.onTapDown` n'est annoncé qu'après
//    l'arbitrage des gestes (~100 ms, ou au relâchement dans un défilement) :
//    sur un tap rapide, l'enfoncement et le relâchement arrivaient ensemble
//    et rien n'était visible. On écoute donc le `Listener` (pointeur brut,
//    immédiat — repris du dock de MyTV) et l'animation joue TOUJOURS le creux
//    complet avant de remonter, quelle que soit la durée de l'appui.
// 2. Relâcher dès qu'un glissement commence, sinon l'élément reste enfoncé
//    alors que le doigt est parti faire défiler la liste.

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';

class PressionEchelle extends StatefulWidget {
  const PressionEchelle({
    super.key,
    this.onTap,
    this.onLongPress,
    this.echelle = 0.97,
    this.child,
    this.constructeur,
  }) : assert(
         child != null || constructeur != null,
         'Fournir child ou constructeur',
       );

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double echelle;
  final Widget? child;
  final Widget Function(BuildContext context, bool enfonce)? constructeur;

  @override
  State<PressionEchelle> createState() => _PressionEchelleState();
}

class _PressionEchelleState extends State<PressionEchelle>
    with SingleTickerProviderStateMixin {
  /// Creux : 90 ms à l'aller, remontée un peu plus longue (140 ms).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 140),
  );
  late final Animation<double> _echelle = Tween<double>(
    begin: 1,
    end: widget.echelle,
  ).chain(CurveTween(curve: Curves.easeOut)).animate(_c);

  Offset? _depart;
  bool _enfonce = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _actif => widget.onTap != null || widget.onLongPress != null;

  void _appuyer(PointerDownEvent e) {
    if (!_actif) return;
    _depart = e.position;
    _enfonce = true;
    _c.forward();
  }

  /// Joue la fin du creux s'il n'est pas terminé, PUIS remonte : c'est ce qui
  /// rend un tap bref perceptible.
  Future<void> _relacher() async {
    if (!_enfonce) return;
    _enfonce = false;
    if (_c.status == AnimationStatus.forward) {
      try {
        await _c.forward().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (mounted) _c.reverse();
  }

  void _bouger(PointerMoveEvent e) {
    if (!_enfonce || _depart == null) return;
    if ((e.position - _depart!).distance > kTouchSlop) _relacher();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _appuyer,
      onPointerMove: _bouger,
      onPointerUp: (_) => _relacher(),
      onPointerCancel: (_) => _relacher(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, enfant) => Transform.scale(
            scale: _echelle.value,
            child: widget.constructeur?.call(context, _c.value > 0.5) ?? enfant,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

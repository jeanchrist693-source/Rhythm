// lib/widgets/toast.dart
//
// Un message bref au-dessus de la barre de navigation (overlay RACINE) :
// « Bientôt disponible » sur les boutons de la maquette qui ne mènent encore
// nulle part. Fondu d'entrée, quelques instants, fondu de sortie ; un seul à
// la fois (le suivant remplace le précédent). Version courte du toast de
// Studio.

import 'package:flutter/material.dart';

import '../theme/rhythm_couleurs.dart';
import '../theme/rhythm_mesures.dart';
import '../theme/rhythm_typo.dart';

OverlayEntry? _courant;

void montrerToast(BuildContext context, String message) {
  final precedent = _courant;
  _courant = null;
  if (precedent != null && precedent.mounted) precedent.remove();
  late final OverlayEntry entree;
  entree = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      onFin: () {
        if (identical(_courant, entree)) _courant = null;
        if (entree.mounted) entree.remove();
      },
    ),
  );
  _courant = entree;
  Overlay.of(context, rootOverlay: true).insert(entree);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.onFin});

  final String message;
  final VoidCallback onFin;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onFin);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: RhythmEspaces.marge,
      right: RhythmEspaces.marge,
      bottom: RhythmEspaces.basBarre(context) + RhythmEspaces.hauteurBarre + 12,
      // L'overlay racine n'est dans aucun `Material` : sans celui-ci, le
      // texte hériterait du style d'erreur (souligné double jaune).
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, enfant) {
                final t = _c.value;
                final v = t < 0.12
                    ? Curves.easeOutCubic.transform(t / 0.12)
                    : t > 0.86
                    ? 1 - Curves.easeInCubic.transform((t - 0.86) / 0.14)
                    : 1.0;
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - v)),
                    child: enfant,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF0222226),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: RhythmCouleurs.bordVerre),
                ),
                child: Text(
                  widget.message,
                  style: RhythmTypo.texte(14, poids: 500),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

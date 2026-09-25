// lib/widgets/suivi_clavier.dart (repris tel quel de Studio)
//
// Garde le champ focalisé VISIBLE au-dessus du clavier, avec une montée et
// une descente lisses — le `ScrollClavierMixin` de Flow, validé sur le
// S26 Ultra (One UI), repris à l'identique (seuls les noms changent).
//
// Pourquoi pas le comportement natif (`resizeToAvoidBottomInset: true`) :
// le viewport rétrécit en continu pendant l'animation du clavier, et le
// framework ne ramène le champ qu'à des événements DISCRETS — sur One UI,
// il « saute » à la fin (leçon de Flow, session 48). Ici le formulaire ne se
// redimensionne jamais : le champ est suivi image par image (`jumpTo`) et
// reste collé au-dessus du clavier pendant qu'il monte.
//
// Usage :
//   class _XState extends ConsumerState<X>
//       with WidgetsBindingObserver, SuiviClavierMixin<X> {
//     initState : surveillerClavier(_focus) (un par champ) ;
//     dispose   : libererClavier() ;
//     build     : PageSecondaire(controleur: defilementClavier,
//                   basSupplementaire: paddingBasClavier, …)
//   }

import 'dart:math' as math;

import 'package:flutter/material.dart';

mixin SuiviClavierMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  /// Contrôleur à brancher sur la liste défilante du formulaire.
  final ScrollController defilementClavier = ScrollController();

  final List<FocusNode> _focuses = [];
  bool _observe = false;
  static const double _margeBas = 60;

  // Padding bas (clavier) : suit le clavier à la MONTÉE, reste GELÉ pendant
  // la redescente, puis retombe à 0 — à ajouter en bas de la liste à la
  // place de `MediaQuery.viewInsetsOf(context).bottom`.
  double _padCourant = 0;
  double get paddingBasClavier => _padCourant;

  void _poserPad(double v) {
    if (!mounted) return;
    setState(() => _padCourant = v);
  }

  double _hMax = 0;
  double? _offsetAvant;
  double _hFrais = 0;
  bool _descente = false;

  /// Enregistre un champ à garder visible (en `initState`).
  void surveillerClavier(FocusNode focus) {
    focus.addListener(_surFocus);
    _focuses.add(focus);
    if (!_observe) {
      WidgetsBinding.instance.addObserver(this);
      _observe = true;
    }
  }

  /// À appeler en `dispose` (les FocusNode restent à la State).
  void libererClavier() {
    for (final f in _focuses) {
      f.removeListener(_surFocus);
    }
    if (_observe) WidgetsBinding.instance.removeObserver(this);
    defilementClavier.dispose();
  }

  FocusNode? get _focusActif {
    for (final f in _focuses) {
      if (f.hasFocus) return f;
    }
    return null;
  }

  void _surFocus() {
    final f = _focusActif;
    if (f != null) {
      if (_offsetAvant == null && defilementClavier.hasClients) {
        _offsetAvant = defilementClavier.offset;
      }
      // Clavier DÉJÀ ouvert (champ suivant) : aucune métrique ne bougera.
      if (MediaQuery.viewInsetsOf(context).bottom > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _remonter());
      }
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _remonter();
      });
    } else {
      // Différé d'une frame : un AUTRE champ prend peut-être le focus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _focusActif != null) return;
        _fermer();
      });
    }
  }

  /// Amène le champ focalisé au-dessus du clavier, en douceur.
  void _remonter() {
    if (!mounted) return;
    final ctx = _focusActif?.context;
    if (ctx == null) return;
    final h = MediaQuery.viewInsetsOf(context).bottom;
    if (h <= 0 || !defilementClavier.hasClients) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      return;
    }
    final rb = ctx.findRenderObject() as RenderBox?;
    if (rb == null || !rb.attached) return;
    final basAVoir =
        rb.localToGlobal(Offset.zero).dy + rb.size.height + _margeBas;
    final basVisible = MediaQuery.sizeOf(context).height - h;
    final depasse = basAVoir - basVisible;
    if (depasse <= 0) return;
    final cible = (defilementClavier.offset + depasse).clamp(
      0.0,
      defilementClavier.position.maxScrollExtent,
    );
    defilementClavier.animateTo(
      cible,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _fermer() {
    if (!mounted) return;
    _descente = false;
    _hFrais = 0;
    if (!defilementClavier.hasClients) {
      _poserPad(0);
      _offsetAvant = null;
      _hMax = 0;
      return;
    }
    // Padding gelé : la redescente glisse sans être « clampée ».
    _poserPad(_hMax > _padCourant ? _hMax : _padCourant);
    final cible = (_offsetAvant ?? 0).clamp(
      0.0,
      defilementClavier.position.maxScrollExtent,
    );
    defilementClavier.animateTo(
      cible,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 290), () {
      if (!mounted || _focusActif != null) return;
      _poserPad(0);
      _offsetAvant = null;
      _hMax = 0;
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    // Fermeture par la flèche du clavier (focus gardé) : MediaQuery a une
    // frame de retard ici, on vérifie à la frame suivante.
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifierFermeture());

    final f = _focusActif;
    if (f == null) return;
    final h = MediaQuery.viewInsetsOf(context).bottom;
    if (h > _hMax) _hMax = h;
    double croissance = 0;
    if (h > _padCourant) {
      // Posé en UNE fois, généreusement : pas de setState par frame.
      final estime = math.max(
        h + _margeBas + 24,
        MediaQuery.sizeOf(context).height * 0.55,
      );
      croissance = estime - _padCourant;
      _poserPad(estime);
    }
    if (_descente) return;

    final ctx = f.context;
    if (ctx == null || !defilementClavier.hasClients) return;
    final rb = ctx.findRenderObject() as RenderBox?;
    if (rb == null || !rb.attached) return;
    final basAVoir =
        rb.localToGlobal(Offset.zero).dy + rb.size.height + _margeBas;
    final basVisible = MediaQuery.sizeOf(context).height - h;
    final depasse = basAVoir - basVisible;
    if (depasse <= 0) return;
    // `maxScrollExtent` date de la frame précédente : on l'étend du padding
    // qui vient d'être posé (sinon montée en marches d'escalier).
    final maxEtendu = defilementClavier.position.maxScrollExtent + croissance;
    defilementClavier.jumpTo(
      (defilementClavier.offset + depasse).clamp(0.0, maxEtendu),
    );
  }

  void _verifierFermeture() {
    if (!mounted) return;
    final h = MediaQuery.viewInsetsOf(context).bottom;
    final diminue = h < _hFrais - 2;
    _hFrais = h;
    if (_descente || _focusActif == null || _padCourant <= 0) return;
    final seFerme = h <= 0 || (diminue && h < _hMax * 0.75);
    if (!seFerme) return;
    _descente = true;
    if (defilementClavier.hasClients) {
      final cible = (_offsetAvant ?? 0).clamp(
        0.0,
        defilementClavier.position.maxScrollExtent,
      );
      defilementClavier.animateTo(
        cible,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _descente = false;
      if (_focusActif == null || MediaQuery.viewInsetsOf(context).bottom <= 0) {
        _poserPad(0);
        _hMax = 0;
        _hFrais = 0;
      }
    });
  }
}

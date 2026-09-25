// lib/ecrans/alimentation/ia/pieces_ia.dart
//
// Les pièces partagées de l'ASSISTANT (palier 4), dans le langage de
// Rhythm (filets, capsules ; ni cartes ni lueurs) :
// - [AppelIa] : l'appel en cours, son erreur, un seul à la fois ; la
//   réponse arrivée, la page descend jusqu'à elle ([AppelIa.montrer]) ;
// - [AttenteIa] : pendant que l'IA répond, les quatre capsules du logo
//   battent comme un égaliseur (immobiles si le système réduit les
//   animations) et une phrase dit ce qui se prépare ;
// - [ErreurIaBloc] : ce qui n'a pas marché (pas de connexion, limite
//   gratuite atteinte…) et « Réessayer » ;
// - [MentionIa] : d'où viennent les idées et les chiffres, ce qui part ;
// - [LigneCorrespondance] : un aliment proposé, sa quantité et ses calories
//   CALCULÉES par la base (« hors de la base » sinon) ;
// - [messageErreurIa].

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ia/service_ia.dart';
import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/correspondance.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/logo_rhythm.dart';
import '../../../widgets/pictos.dart';
import '../courses/pieces_courses.dart';

/// Ce qu'une erreur de l'IA veut dire pour l'utilisateur.
String messageErreurIa(AppLocalizations tr, Object? e) => switch (e) {
  ExceptionIa(erreur: ErreurIa.quota) => tr.iaErrQuota,
  ExceptionIa(erreur: ErreurIa.surcharge) => tr.iaErrSurcharge,
  ExceptionIa(erreur: ErreurIa.nonAutorise) => tr.iaErrNonAutorise,
  ExceptionIa(erreur: ErreurIa.modeleIndisponible) => tr.iaErrModele,
  ExceptionIa(erreur: ErreurIa.reseau) => tr.iaErrReseau,
  ExceptionIa(erreur: ErreurIa.sansCle) => tr.iaErrSansCle,
  _ => tr.iaErrIllisible,
};

/// Un appel à l'IA depuis un écran : un seul à la fois ; l'erreur gardée
/// pour l'afficher.
mixin AppelIa<W extends StatefulWidget> on State<W> {
  bool enCours = false;
  Object? erreur;

  /// [f] lancée ; son résultat, ou `null` (erreur, écran fermé, appel déjà
  /// en cours).
  Future<R?> appeler<R>(Future<R> Function() f) async {
    if (enCours) return null;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      enCours = true;
      erreur = null;
    });
    try {
      final r = await f();
      if (!mounted) return null;
      setState(() => enCours = false);
      return r;
    } catch (e) {
      if (mounted) {
        setState(() {
          enCours = false;
          erreur = e;
        });
      }
      return null;
    }
  }

  /// La page descend jusqu'à [cle] (la réponse, sous le bouton) — une fois
  /// le clavier refermé : son suivi (`SuiviClavierMixin`) ramène d'abord la
  /// page où elle était.
  void montrer(GlobalKey cle) {
    Future.delayed(const Duration(milliseconds: 320), () {
      final c = cle.currentContext;
      if (!mounted || c == null || !c.mounted) return;
      Scrollable.ensureVisible(
        c,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

/// Pendant que l'IA répond : les quatre capsules du logo qui battent, et
/// [message].
class AttenteIa extends StatefulWidget {
  const AttenteIa({super.key, required this.message});

  final String message;

  @override
  State<AttenteIa> createState() => _AttenteIaState();
}

class _AttenteIaState extends State<AttenteIa>
    with SingleTickerProviderStateMixin {
  late final _horloge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _horloge.stop();
    } else if (!_horloge.isAnimating) {
      _horloge.repeat();
    }
  }

  @override
  void dispose() {
    _horloge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: widget.message,
    child: ExcludeSemantics(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 36,
            child: AnimatedBuilder(
              animation: _horloge,
              builder: (context, _) {
                final t = _horloge.value;
                return CustomPaint(
                  painter: PeintreLogo([
                    for (var i = 0; i < 4; i++)
                      (
                        LogoRhythm.largeurBarre,
                        LogoRhythm.hauteurs[i] *
                            (0.55 +
                                0.45 *
                                    (0.5 +
                                        0.5 *
                                            math.sin(
                                              2 * math.pi * (t - i * 0.17),
                                            ))),
                      ),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.message,
              style: RhythmTypo.texte(15, couleur: RhythmCouleurs.texte72),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Ce qui n'a pas marché, et « Réessayer ».
class ErreurIaBloc extends StatelessWidget {
  const ErreurIaBloc({super.key, required this.erreur, this.onReessayer});

  final Object? erreur;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          messageErreurIa(tr, erreur),
          style: RhythmTypo.texte(14, couleur: RhythmCouleurs.corail),
        ),
        if (onReessayer != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: BoutonCapsule(
              picto: Picto.repete,
              libelle: tr.reessayer,
              onTap: onReessayer!,
            ),
          ),
        ],
      ],
    );
  }
}

/// D'où viennent les idées, d'où viennent les chiffres, ce qui part.
class MentionIa extends StatelessWidget {
  const MentionIa({super.key});

  @override
  Widget build(BuildContext context) => Text(
    context.tr.mentionIa,
    style: RhythmTypo.texte(11, couleur: RhythmCouleurs.texte40),
  );
}

/// Un aliment proposé : sa quantité, ses calories calculées par la base ;
/// « hors de la base » (sans valeur nutritive) s'il n'a pas été trouvé.
class LigneCorrespondance extends StatelessWidget {
  const LigneCorrespondance({
    super.key,
    required this.correspondance,
    this.filet = true,
    this.coche,
    this.onTap,
  });

  final Correspondance correspondance;
  final bool filet;
  final bool? coche;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final c = correspondance;
    final i = c.ingredient;
    return LigneCourse(
      filet: filet,
      nom: i.nom,
      detail: [
        f.quantiteIngredient(i, tr),
        if (c.horsBase) tr.horsDeLaBase,
      ].where((s) => s.isNotEmpty).join(' · '),
      detailCouleur: c.horsBase ? RhythmCouleurs.corail : null,
      valeur: c.aliment == null ? null : f.kcalDe(i.nutriments.kcal, tr),
      coche: coche,
      onTap: onTap,
    );
  }
}

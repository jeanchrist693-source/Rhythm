// lib/ecrans/alimentation/recettes/cuisine_ecran.dart
//
// LE MODE CUISINE : l'écran reste ALLUMÉ ; les portions s'ajustent (les
// quantités suivent) ; la MISE EN PLACE se coche ingrédient par ingrédient
// (toute cochée, elle se replie en une ligne : l'étape remonte) ; puis les
// ÉTAPES une à une, en grand (lisibles de loin) ; « Précédente » /
// « Suivante » sont FIXES en bas de l'écran (une étape plus longue ou sans
// minuteur ne les déplace plus sous le doigt) ; les durées écrites dans une
// étape sont soulignées : un toucher lance le MINUTEUR (plusieurs à la
// fois — le riz pendant que le poulet dore), posés en bas, au-dessus des
// boutons, avec ce qu'il reste ; à la fin, une vibration
// forte et un mot (et une notification si l'app est passée derrière). La
// liste de toutes les étapes permet de sauter à l'une d'elles. « C'est
// prêt » cède la place au bilan (`pret_ecran.dart`).
//
// Le temps se lit à l'horloge (`horlogeProvider`), jamais en comptant des
// images.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../systeme/ecran_allume.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/pression_echelle.dart';
import '../../../widgets/toast.dart';
import '../courses/pieces_courses.dart';
import 'pieces_recettes.dart';
import 'pret_ecran.dart';

class CuisineEcran extends ConsumerStatefulWidget {
  const CuisineEcran({
    super.key,
    required this.recette,
    required this.portions,
    required this.retour,
    this.moment,
  });

  final Recette recette;
  final int portions;
  final String retour;

  /// Le moment où l'on mangera (un repas prévu) ; sinon, d'après l'heure.
  final MomentRepas? moment;

  @override
  ConsumerState<CuisineEcran> createState() => _CuisineEcranState();
}

class _CuisineEcranState extends ConsumerState<CuisineEcran> {
  late int _portions = widget.portions;
  final Set<int> _coches = {};

  /// Toute cochée, la mise en place se replie ; « Revoir » la rouvre.
  bool _revoir = false;
  int _etape = 0;
  Timer? _horloge;

  /// Le bloc de l'étape en cours (la page le ramène à l'écran).
  final _cleEtape = GlobalKey();

  @override
  void initState() {
    super.initState();
    garderEcranAllume(true);
    _horloge = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _verifier(),
    );
  }

  @override
  void dispose() {
    garderEcranAllume(false);
    _horloge?.cancel();
    super.dispose();
  }

  /// Un minuteur arrivé au bout : il sonne (une fois) ; ceux qui tournent
  /// rafraîchissent l'écran.
  void _verifier() {
    if (!mounted) return;
    final minuteurs = ref.read(minuteursProvider);
    if (minuteurs.isEmpty) return;
    final maintenant = ref.read(horlogeProvider)();
    for (final m in minuteurs) {
      if (!m.sonne && !m.fin.isAfter(maintenant)) {
        ref.read(minuteursProvider.notifier).sonner(m.id);
        _alerter(m);
      }
    }
    setState(() {});
  }

  Future<void> _alerter(MinuteurCuisine m) async {
    montrerToast(context, context.tr.minuteurSonne(m.libelle));
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  void _lancer(RepereMinuteur r, int etape) {
    final tr = context.tr;
    final f = context.formats;
    ref
        .read(minuteursProvider.notifier)
        .demarrer(
          tr.minuteurLibelle(
            widget.recette.nom,
            etape + 1,
            f.minutes(r.duree.inMinutes),
          ),
          r.duree,
        );
    HapticFeedback.selectionClick();
    montrerToast(context, tr.minuteurLance(_duree(r.duree)));
  }

  String _duree(Duration d) => d.inMinutes >= 1
      ? context.formats.minutes(d.inMinutes)
      : context.tr.secondes(d.inSeconds);

  void _allerA(int etape) {
    HapticFeedback.selectionClick();
    setState(() => _etape = etape);
    WidgetsBinding.instance.addPostFrameCallback((_) => _montrerEtape());
  }

  /// L'étape change alors qu'elle est hors de l'écran (sous la mise en
  /// place, au-dessus de la liste des étapes) : la page défile jusqu'à elle.
  void _montrerEtape() {
    final bloc = _cleEtape.currentContext;
    final boite = bloc?.findRenderObject();
    if (!mounted || bloc == null || boite is! RenderBox || !boite.attached) {
      return;
    }
    final haut = boite.localToGlobal(Offset.zero).dy;
    final marges = MediaQuery.viewPaddingOf(context);
    final limite =
        MediaQuery.sizeOf(context).height -
        marges.bottom -
        hauteurBarreCuisine(ref.read(minuteursProvider).length);
    if (haut >= marges.top && haut + boite.size.height <= limite) return;
    Scrollable.ensureVisible(
      bloc,
      alignment: 0.12,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _pret() {
    HapticFeedback.mediumImpact();
    remplacerEcran(
      context,
      PretEcran(
        recette: widget.recette,
        portions: _portions,
        moment: widget.moment,
        retour: widget.retour,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final r = widget.recette;
    final facteur = _portions / r.portions;
    final ingredients = [for (final i in r.ingredients) i.fois(facteur)];
    final minuteurs = ref.watch(minuteursProvider);
    final maintenant = ref.read(horlogeProvider)();
    final etapes = r.etapes;
    final derniere = _etape >= etapes.length - 1;
    final etape = _etape;

    final page = PageSecondaire(
      retour: widget.retour,
      basSupplementaire: hauteurBarreCuisine(minuteurs.length),
      enfants: [
        TitreSecondaire(
          titre: r.nom,
          surtitre: Text(
            tr.modeCuisine,
            style: RhythmTypo.texte(
              14,
              poids: 600,
              couleur: RhythmCouleurs.peche,
            ),
          ),
        ),
        LigneReglage(
          libelle: tr.pourCombien,
          droite: CompteurRhythm(
            valeur: _portions,
            min: 1,
            max: 48,
            largeurValeur: 104,
            affichage: (p) => f.portions(p.toDouble(), tr),
            onChanged: (p) => setState(() => _portions = p),
          ),
        ),
        if (ingredients.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(
                tr.miseEnPlace(_coches.length, ingredients.length),
                couleur: _coches.length == ingredients.length
                    ? RhythmCouleurs.menthe
                    : null,
                droite: _coches.length == ingredients.length && !_revoir
                    ? Puce(
                        libelle: tr.revoir,
                        choisie: false,
                        onTap: () => setState(() => _revoir = true),
                      )
                    : null,
              ),
              if (_coches.length < ingredients.length || _revoir)
                for (final (i, ing) in ingredients.indexed)
                  LigneCourse(
                    filet: i > 0,
                    coche: _coches.contains(i),
                    nom: ing.nom,
                    detail: f.quantiteIngredient(ing, tr),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(
                        () => _coches.contains(i)
                            ? _coches.remove(i)
                            : _coches.add(i),
                      );
                    },
                  ),
            ],
          ),
        if (etapes.isEmpty)
          Text(tr.sansEtapes, style: RhythmTypo.detail)
        else
          Column(
            key: _cleEtape,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(
                tr.etapeSur(_etape + 1, etapes.length),
                couleur: RhythmCouleurs.peche,
              ),
              // L'étape ENTIÈRE — son texte ET ses minuteurs — change d'un
              // seul fondu, et la hauteur du bloc glisse vers la nouvelle
              // PENDANT ce fondu : le minuteur ne disparaît plus avant le
              // texte, et ce qui suit (la liste des étapes) glisse au lieu
              // de sauter à la fin.
              AnimatedSize(
                duration: _dureeEtape,
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: _dureeEtape,
                  // En fondu ENCHAÎNÉ : l'ancienne étape s'efface dans la
                  // première moitié, la nouvelle paraît dans la seconde —
                  // jamais deux textes l'un sur l'autre.
                  switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
                  switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
                  // Seule la nouvelle étape donne sa taille ; l'ancienne
                  // s'efface par-dessus, sans retenir la hauteur.
                  layoutBuilder: (actuel, precedents) => Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topLeft,
                    children: [
                      for (final p in precedents)
                        Positioned(top: 0, left: 0, right: 0, child: p),
                      ?actuel,
                    ],
                  ),
                  child: _Etape(
                    key: ValueKey(_etape),
                    texte: etapes[_etape],
                    duree: _duree,
                    onMinuteur: (m) => _lancer(m, etape),
                  ),
                ),
              ),
            ],
          ),
        if (etapes.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.toutesLesEtapes),
              for (final (i, e) in etapes.indexed) ...[
                if (i > 0) const Filet(),
                Semantics(
                  button: true,
                  selected: i == _etape,
                  child: PressionEchelle(
                    echelle: 0.98,
                    onTap: () => _allerA(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${i + 1}',
                              style: RhythmTypo.titre(
                                15,
                                couleur: i == _etape
                                    ? RhythmCouleurs.peche
                                    : RhythmCouleurs.texte40,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TexteEtape(
                              texte: e,
                              maxLignes: 2,
                              style: RhythmTypo.texte(
                                14,
                                couleur: i == _etape
                                    ? RhythmCouleurs.texte
                                    : i < _etape
                                    ? RhythmCouleurs.texte40
                                    : RhythmCouleurs.texte72,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (!derniere) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: BoutonCapsule(
                    picto: Picto.coche,
                    libelle: tr.cestPret,
                    onTap: _pret,
                  ),
                ),
              ],
            ],
          ),
      ],
    );

    // Le bouton principal : « Suivante », puis « C'est prêt » à la dernière
    // étape (ou d'emblée, sans étapes).
    final principal = BoutonPlein(
      libelle: derniere ? tr.cestPret : tr.suivante,
      hauteur: 48,
      fleche: !derniere,
      onTap: derniere ? _pret : () => _allerA(_etape + 1),
    );

    // « Précédente » et « Suivante » restent en bas de l'écran, à la même
    // place d'une étape à l'autre : une étape plus longue, ou sans minuteur,
    // ne les fait plus sauter sous le doigt. « Précédente » est toujours là
    // (éteinte à la première étape) : « Suivante » ne change pas de largeur.
    return Stack(
      children: [
        page,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BarreCuisine(
            minuteurs: minuteurs,
            maintenant: maintenant,
            onPlus: (id) {
              HapticFeedback.selectionClick();
              ref.read(minuteursProvider.notifier).ajouterMinute(id);
            },
            onArreter: (id) {
              HapticFeedback.selectionClick();
              ref.read(minuteursProvider.notifier).arreter(id);
            },
            pied: etapes.isEmpty
                ? principal
                : Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          enabled: _etape > 0,
                          child: IgnorePointer(
                            ignoring: _etape == 0,
                            child: AnimatedOpacity(
                              opacity: _etape > 0 ? 1 : 0.3,
                              duration: const Duration(milliseconds: 160),
                              child: BoutonContour(
                                libelle: tr.precedente,
                                hauteur: 48,
                                onTap: () => _allerA(_etape - 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: principal),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Un changement d'étape : le fondu et la hauteur, ensemble.
const Duration _dureeEtape = Duration(milliseconds: 300);

/// Une étape du mode cuisine : son texte en grand (les durées soulignées,
/// touchables), puis un bouton par minuteur — un seul bloc, qui entre et
/// sort d'un seul fondu.
class _Etape extends StatelessWidget {
  const _Etape({
    super.key,
    required this.texte,
    required this.duree,
    required this.onMinuteur,
  });

  final String texte;

  /// « 5 min », « 30 s ».
  final String Function(Duration) duree;
  final ValueChanged<RepereMinuteur> onMinuteur;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final reperes = minuteursDans(texte);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TexteEtape(
          texte: texte,
          style: RhythmTypo.titre(
            23,
            poids: 500,
            espacement: -0.01,
            hauteur: 1.3,
          ),
          onMinuteur: onMinuteur,
        ),
        if (reperes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final m in reperes)
                BoutonCapsule(
                  picto: Picto.chrono,
                  libelle: tr.lancerMinuteur(duree(m.duree)),
                  onTap: () => onMinuteur(m),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

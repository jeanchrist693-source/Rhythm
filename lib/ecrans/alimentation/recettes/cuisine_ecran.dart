// lib/ecrans/alimentation/recettes/cuisine_ecran.dart
//
// LE MODE CUISINE : l'écran reste ALLUMÉ ; les portions s'ajustent (les
// quantités suivent) ; la MISE EN PLACE se coche ingrédient par ingrédient
// (toute cochée, elle se replie en une ligne : l'étape remonte) ; puis les
// ÉTAPES une à une, en grand (lisibles de loin), « Précédente » /
// « Suivante » ; les durées écrites dans une étape sont soulignées : un
// toucher lance le MINUTEUR (plusieurs à la fois — le riz pendant que le
// poulet dore), posés en bas avec ce qu'il reste ; à la fin, une vibration
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

    final page = PageSecondaire(
      retour: widget.retour,
      basSupplementaire: hauteurBarreMinuteurs(minuteurs.length),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr.sansEtapes, style: RhythmTypo.detail),
              const SizedBox(height: 16),
              BoutonPlein(
                libelle: tr.cestPret,
                largeurPleine: true,
                hauteur: 52,
                taillePolice: 15,
                onTap: _pret,
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(
                tr.etapeSur(_etape + 1, etapes.length),
                couleur: RhythmCouleurs.peche,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                layoutBuilder: (actuel, precedents) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...precedents, ?actuel],
                ),
                child: TexteEtape(
                  key: ValueKey(_etape),
                  texte: etapes[_etape],
                  style: RhythmTypo.titre(
                    23,
                    poids: 500,
                    espacement: -0.01,
                    hauteur: 1.3,
                  ),
                  onMinuteur: (m) => _lancer(m, _etape),
                ),
              ),
              if (minuteursDans(etapes[_etape]) case final reperes
                  when reperes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in reperes)
                      BoutonCapsule(
                        picto: Picto.chrono,
                        libelle: tr.lancerMinuteur(_duree(m.duree)),
                        onTap: () => _lancer(m, _etape),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  if (_etape > 0) ...[
                    Expanded(
                      child: BoutonContour(
                        libelle: tr.precedente,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _etape--);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: BoutonPlein(
                      libelle: derniere ? tr.cestPret : tr.suivante,
                      hauteur: 48,
                      fleche: !derniere,
                      onTap: derniere
                          ? _pret
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _etape++);
                            },
                    ),
                  ),
                ],
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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _etape = i);
                    },
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

    return Stack(
      children: [
        page,
        if (minuteurs.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BarreMinuteurs(
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
            ),
          ),
      ],
    );
  }
}

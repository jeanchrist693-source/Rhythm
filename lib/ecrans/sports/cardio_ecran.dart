// lib/ecrans/sports/cardio_ecran.dart
//
// COURSE, MARCHE, VÉLO : une autre logique que la musculation.
// - Séance CHRONOMÉTRÉE (pause, reprise) ; à la fin, la distance (Rhythm ne
//   suit pas le GPS : on la note), l'allure ou la vitesse, l'effort
//   ressenti, les calories (MET selon la vitesse) ;
// - FRACTIONNÉ : un plan d'intervalles (échauffement, vite / lent, retour
//   au calme) annoncé par des SIGNAUX — vibration forte à chaque changement,
//   un petit clic aux trois dernières secondes.
// Une séance d'un programme de course ou d'un défi valide son étape.
//
// Le temps se lit à l'horloge : l'écran éteint, la séance continue.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/etat_sante.dart';
import '../../modele/sports/calculs_sport.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/plans.dart';
import '../../modele/sports/sport.dart';
import '../../systeme/ecran_allume.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_mesures.dart';
import '../../theme/rhythm_theme.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/toast.dart';
import 'pieces_sports.dart';

/// La couleur d'une phase.
Color couleurPhase(Phase p) => switch (p) {
  Phase.echauffement || Phase.retourCalme => RhythmCouleurs.menthe,
  Phase.effort => RhythmCouleurs.corail,
  Phase.recuperation => RhythmCouleurs.ciel,
};

class CardioEcran extends ConsumerStatefulWidget {
  const CardioEcran({
    super.key,
    required this.activite,
    required this.retour,
    this.plan,
    this.programmeCourse,
    this.defi,
    this.etape,
  });

  /// L'exercice de la banque (« course », « marche », « velo »…).
  final String activite;
  final String retour;

  /// Un fractionné (sinon : chrono libre).
  final PlanIntervalles? plan;

  /// Le programme de course, ou le défi, et l'étape que la sortie valide.
  final String? programmeCourse;
  final String? defi;
  final int? etape;

  @override
  ConsumerState<CardioEcran> createState() => _CardioEcranState();
}

class _CardioEcranState extends ConsumerState<CardioEcran> {
  late final DateTime Function() _maintenant = ref.read(horlogeProvider);
  DateTime? _debut;
  DateTime? _pauseDepuis;
  Duration _pauses = Duration.zero;
  bool _fini = false;
  Duration _total = Duration.zero;
  int _phaseAnnoncee = -1;
  int _dernierBip = -1;
  Timer? _horloge;
  bool _confirmation = false;

  final TextEditingController _distance = TextEditingController();
  int? _effort;
  final TextEditingController _note = TextEditingController();

  ExerciceSport? get _exercice => Catalogue.de(widget.activite);

  @override
  void initState() {
    super.initState();
    _distance.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    garderEcranAllume(false);
    _horloge?.cancel();
    _distance.dispose();
    _note.dispose();
    super.dispose();
  }

  Duration get _ecoule {
    final d = _debut;
    if (d == null) return Duration.zero;
    final fin = _pauseDepuis ?? _maintenant();
    return fin.difference(d) - _pauses;
  }

  void _demarrer() {
    HapticFeedback.heavyImpact();
    setState(() => _debut = _maintenant());
    _horloge = Timer.periodic(const Duration(milliseconds: 200), (_) => _tic());
    garderEcranAllume(true);
  }

  void _pause() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_pauseDepuis == null) {
        _pauseDepuis = _maintenant();
      } else {
        _pauses += _maintenant().difference(_pauseDepuis!);
        _pauseDepuis = null;
      }
    });
  }

  void _terminer() {
    _horloge?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _total = _ecoule;
      _fini = true;
      _confirmation = false;
    });
  }

  /// La phase en cours du fractionné : (indice, secondes restantes).
  (int, double)? _phase() {
    final plan = widget.plan;
    if (plan == null) return null;
    var t = _ecoule.inMilliseconds / 1000;
    for (var i = 0; i < plan.etapes.length; i++) {
      final d = plan.etapes[i].secondes.toDouble();
      if (t < d) return (i, d - t);
      t -= d;
    }
    return (plan.etapes.length, 0);
  }

  void _tic() {
    if (!mounted || _fini) return;
    final p = _phase();
    if (p != null && _pauseDepuis == null) {
      final (i, reste) = p;
      if (i >= widget.plan!.etapes.length) {
        _signalChangement();
        _terminer();
        return;
      }
      if (i != _phaseAnnoncee) {
        if (_phaseAnnoncee >= 0) _signalChangement();
        _phaseAnnoncee = i;
        _dernierBip = -1;
      }
      final s = reste.ceil();
      if (s <= 3 && s >= 1 && s != _dernierBip) {
        _dernierBip = s;
        HapticFeedback.selectionClick();
      }
    }
    setState(() {});
  }

  Future<void> _signalChangement() async {
    for (var i = 0; i < 2; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
  }

  double? get _km {
    final t = _distance.text.trim().replaceAll(',', '.');
    final v = double.tryParse(t);
    return v == null || v <= 0 ? null : v;
  }

  SeanceFaite _seance(String id) {
    final etat = ref.read(sportProvider);
    final secondes = math.max(60, _total.inSeconds);
    final km = _km;
    final kmh = km == null ? null : km / (secondes / 3600);
    return SeanceFaite(
      id: id,
      nom: widget.plan?.nom ?? _exercice?.nom ?? widget.activite,
      debut: _debut ?? _maintenant(),
      dureeSec: secondes,
      style: StyleSport.cardio,
      activite: widget.activite,
      distanceKm: km,
      kcal: calories(
        metCardio(widget.activite, kmh),
        etat.poidsCorps,
        secondes,
      ),
      ressenti: _effort,
      note: _note.text.trim(),
      programmeCardio: widget.programmeCourse,
      defi: widget.defi,
      etape: widget.etape,
    );
  }

  void _enregistrer() {
    final tr = context.tr;
    final notifier = ref.read(sportProvider.notifier);
    final r = notifier.enregistrerSeance(_seance(notifier.nouvelId('sea')));
    HapticFeedback.heavyImpact();
    montrerToast(
      context,
      r.habitudeCochee != null
          ? tr.toastSeanceHabitude(r.habitudeCochee!)
          : r.etapeValidee
          ? tr.toastEtapeValidee
          : tr.toastSeanceEnregistree,
    );
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }

  void _quitter() =>
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _debut == null,
      onPopInvokedWithResult: (sorti, _) {
        if (!sorti) setState(() => _confirmation = !_confirmation);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: RhythmTheme.barresSysteme,
        child: Scaffold(
          backgroundColor: RhythmCouleurs.fond,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(child: _fini ? _resume() : _enCours()),
              if (_confirmation) Positioned.fill(child: _confirmer()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _enCours() {
    final tr = context.tr;
    final f = context.formats;
    final e = _exercice;
    final plan = widget.plan;
    final phase = _phase();
    final ecoule = _ecoule;
    final demarre = _debut != null;
    final enPause = _pauseDepuis != null;

    Phase? p;
    double resteP = 0;
    int totalP = 1;
    if (plan != null && phase != null && phase.$1 < plan.etapes.length) {
      p = plan.etapes[phase.$1].phase;
      resteP = phase.$2;
      totalP = plan.etapes[phase.$1].secondes;
    }
    final efforts =
        plan?.etapes.where((x) => x.phase == Phase.effort).length ?? 0;
    final numero = plan == null || phase == null
        ? 0
        : plan.etapes
              .take(math.min(phase.$1 + 1, plan.etapes.length))
              .where((x) => x.phase == Phase.effort)
              .length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RhythmEspaces.marge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  BoutonPicto(
                    picto: demarre ? Picto.croix : Picto.retour,
                    libelle: tr.arreterSeance,
                    onTap: () => demarre
                        ? setState(() => _confirmation = true)
                        : Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      plan?.nom ?? e?.nom ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RhythmTypo.texte(15, poids: 600),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final anneau = math.min(250.0, c.maxHeight * 0.46);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (e != null)
                        Center(
                          child: FigureDe(
                            e,
                            taille: math.min(150, c.maxHeight * 0.22),
                            animer: demarre && !enPause,
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (p != null)
                        Text(
                          p.libelle(tr).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: RhythmTypo.titre(22, couleur: couleurPhase(p)),
                        )
                      else
                        Text(
                          demarre
                              ? (enPause ? tr.enPause : tr.enCours)
                              : (e?.nom ?? ''),
                          textAlign: TextAlign.center,
                          style: RhythmTypo.texte(
                            15,
                            poids: 600,
                            couleur: RhythmCouleurs.texte64,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Center(
                        child: AnneauMinuteur(
                          taille: anneau,
                          progression: p != null
                              ? resteP / totalP
                              : (ecoule.inMilliseconds % 60000) / 60000,
                          couleur: p != null
                              ? couleurPhase(p)
                              : RhythmCouleurs.corail,
                          centre: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p != null
                                    ? f.chrono(Duration(seconds: resteP.ceil()))
                                    : f.chrono(ecoule),
                                style: RhythmTypo.titre(anneau * 0.22),
                              ),
                              if (p != null)
                                Text(
                                  f.chrono(ecoule),
                                  style: RhythmTypo.texte(
                                    15,
                                    couleur: RhythmCouleurs.texte64,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (plan != null && efforts > 0)
                        Text(
                          tr.intervalleSur(numero, efforts),
                          textAlign: TextAlign.center,
                          style: RhythmTypo.detail,
                        ),
                      if (!demarre) ...[
                        const SizedBox(height: 8),
                        Text(
                          tr.pasDeGps,
                          textAlign: TextAlign.center,
                          style: RhythmTypo.petit,
                        ),
                      ],
                      const Spacer(),
                      if (!demarre)
                        BoutonPlein(
                          libelle: tr.demarrerActivite,
                          largeurPleine: true,
                          hauteur: 56,
                          taillePolice: 16,
                          onTap: _demarrer,
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: BoutonCapsule(
                                picto: enPause ? Picto.lecture : Picto.pause,
                                libelle: enPause ? tr.reprendre : tr.pause,
                                hauteur: 56,
                                onTap: _pause,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BoutonCapsule(
                                picto: Picto.stop,
                                libelle: tr.terminer,
                                plein: true,
                                hauteur: 56,
                                onTap: _terminer,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmer() {
    final tr = context.tr;
    return GestureDetector(
      onTap: () => setState(() => _confirmation = false),
      child: ColoredBox(
        color: const Color(0xE6000000),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(RhythmEspaces.marge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr.arreterSeance,
                  style: RhythmTypo.titre(26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                BoutonPlein(
                  libelle: tr.reprendre,
                  largeurPleine: true,
                  hauteur: 52,
                  taillePolice: 15,
                  onTap: () => setState(() => _confirmation = false),
                ),
                if (!_fini) ...[
                  const SizedBox(height: 12),
                  BoutonCapsule(
                    picto: Picto.coche,
                    libelle: tr.garderCeQuiEstFait,
                    hauteur: 52,
                    onTap: _terminer,
                  ),
                ],
                const SizedBox(height: 12),
                PressionEchelle(
                  onTap: _quitter,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      tr.abandonnerSeance,
                      textAlign: TextAlign.center,
                      style: RhythmTypo.texte(
                        15,
                        poids: 600,
                        couleur: RhythmCouleurs.corail,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resume() {
    final tr = context.tr;
    final f = context.formats;
    final s = _seance('apercu');
    final aPied =
        widget.activite != 'velo' && widget.activite != 'velo_interieur';
    return PageSecondaire(
      retour: s.nom,
      onRetour: () => setState(() => _confirmation = true),
      enfants: [
        TitreSecondaire(
          titre: tr.seanceTerminee,
          surtitre: Text(s.nom, style: RhythmTypo.surtitre),
        ),
        RangeeFilets(
          cases: [
            StatSport(
              libelle: tr.duree,
              valeur: f.chrono(Duration(seconds: s.dureeSec)),
              couleur: RhythmCouleurs.corail,
            ),
            if (aPied)
              StatSport(
                libelle: tr.allure,
                valeur: s.allure == null
                    ? '—'
                    : tr.allureValeur(f.chrono(s.allure!)),
              )
            else
              StatSport(
                libelle: tr.vitesse,
                valeur: s.vitesse == null
                    ? '—'
                    : tr.vitesseValeur(
                        f.decimal((s.vitesse! * 10).round() / 10),
                      ),
              ),
            StatSport(
              libelle: tr.calories,
              valeur: f.entier(s.kcal),
              couleur: RhythmCouleurs.peche,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.distance),
            ChampRhythm(
              controleur: _distance,
              indice: tr.indiceKm,
              clavier: const TextInputType.numberWithOptions(decimal: true),
              formateurs: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                LengthLimitingTextInputFormatter(6),
              ],
              suffixe: 'km',
              actionClavier: TextInputAction.done,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.effortRessenti),
            PucesChoix<int>(
              options: [for (var n = 1; n <= 5; n++) (n, libelleEffort(tr, n))],
              valeur: _effort,
              onChanged: (n) => setState(() => _effort = n),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.note),
            ChampRhythm(
              controleur: _note,
              indice: tr.indiceNote,
              lignes: 3,
              majuscules: TextCapitalization.sentences,
            ),
          ],
        ),
        BoutonPlein(
          libelle: tr.enregistrer,
          largeurPleine: true,
          hauteur: 54,
          taillePolice: 16,
          onTap: _enregistrer,
        ),
      ],
    );
  }
}

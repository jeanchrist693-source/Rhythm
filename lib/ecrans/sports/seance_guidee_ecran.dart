// lib/ecrans/sports/seance_guidee_ecran.dart
//
// « COMMENCER » : la séance GUIDÉE, série par série.
//
// - L'exercice en cours avec son corps en mouvement, « Série 2 sur 4 », les
//   répétitions et la charge DÉJÀ REMPLIES — celles de la dernière fois, ou
//   la PROGRESSION proposée (une répétition de plus, un peu plus de charge) ;
// - « Série faite » lance le REPOS (anneau qui se vide, +15 s, passer), avec
//   une vibration à la fin ; pendant le repos, on note son ressenti ;
// - un exercice en durée (gainage, échauffement) se minute ; l'échauffement
//   et le retour au calme s'enchaînent seuls, comme les routines express ;
// - les deux exercices d'une paire alternent sans repos entre eux ;
// - un RECORD battu s'annonce tout de suite ;
// - à la fin, le RÉSUMÉ (durée, volume, calories, records), le ressenti, une
//   note — puis la séance s'enregistre et fait vivre le haut de l'écran
//   Sports (et coche l'habitude « Entraînement »).
//
// Le temps se lit à l'horloge (`horlogeProvider`), jamais en comptant des
// images : l'app mise en arrière-plan retrouve le bon repos.

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
import '../../modele/sports/deroulement.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/sport.dart';
import '../../systeme/ecran_allume.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_mesures.dart';
import '../../theme/rhythm_theme.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/jauges.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/toast.dart';
import 'pieces_sports.dart';

enum _Moment { effort, repos, fin }

class SeanceGuideeEcran extends ConsumerStatefulWidget {
  const SeanceGuideeEcran({
    super.key,
    required this.lignes,
    required this.nom,
    this.programmeId,
    this.objectif = Objectif.volume,
    this.automatique = false,
    this.cibles = const {},
    this.defi,
    this.etape,
    this.style,
  });

  final List<LigneSeance> lignes;
  final String nom;
  final String? programmeId;
  final Objectif objectif;

  /// Une routine : chaque étape minutée s'enchaîne seule.
  final bool automatique;

  /// Les répétitions visées série par série (un défi) : ligne → cibles.
  final Map<int, List<int>> cibles;

  /// Le défi et l'étape que cette séance valide.
  final String? defi;
  final int? etape;

  /// Le style à enregistrer (sinon, le style dominant).
  final StyleSport? style;

  @override
  ConsumerState<SeanceGuideeEcran> createState() => _SeanceGuideeEcranState();
}

class _SeanceGuideeEcranState extends ConsumerState<SeanceGuideeEcran> {
  late final List<Etape> _etapes = etapesDe(widget.lignes);
  late final DateTime Function() _maintenant = ref.read(horlogeProvider);
  late final DateTime _debut = _maintenant();
  DateTime? _fin;

  _Moment _moment = _Moment.effort;
  int _k = 0;
  int _suivante = 0;
  final Set<int> _passees = {};

  /// Les séries faites, par ligne.
  final Map<int, List<SerieFaite>> _faites = {};

  // L'effort en cours.
  int _reps = 10;
  int _chargeDemi = 0;
  DateTime? _debutEffort;

  // Le repos en cours.
  DateTime? _finRepos;
  int _dureeRepos = 0;
  int? _ligneRepos;
  bool _pret = false;
  int _dernierBip = -1;
  bool _coteChange = false;

  // Les propositions (progression) et les records d'avant.
  final Map<int, Proposition> _propositions = {};
  final Map<String, Records> _recordsAvant = {};
  final Map<String, Records> _recordsSeance = {};
  final Set<String> _annonces = {};

  bool _confirmation = false;
  int? _ressentiGlobal;
  final TextEditingController _note = TextEditingController();
  Timer? _horloge;

  @override
  void initState() {
    super.initState();
    final journal = ref.read(sportProvider).journal;
    for (final (i, l) in widget.lignes.indexed) {
      if (l.role != RoleLigne.travail) continue;
      final e = Catalogue.de(l.exercice);
      if (e == null) continue;
      _propositions[i] = proposer(l, e, journal, widget.objectif);
      _recordsAvant[e.id] ??= recordsDe(e.id, journal);
    }
    _entrer(0, auto: false);
    _horloge = Timer.periodic(const Duration(milliseconds: 200), (_) => _tic());
    garderEcranAllume(true);
  }

  @override
  void dispose() {
    garderEcranAllume(false);
    _horloge?.cancel();
    _note.dispose();
    super.dispose();
  }

  LigneSeance get _ligne => widget.lignes[_etapes[_k].ligne];
  ExerciceSport? get _exercice => Catalogue.de(_ligne.exercice);

  // ── Le déroulé ───────────────────────────────────────────────────────────

  /// Entre dans l'étape [k] ; [auto] : un exercice minuté démarre seul.
  void _entrer(int k, {required bool auto}) {
    if (k >= _etapes.length) {
      _terminer();
      return;
    }
    final etape = _etapes[k];
    final l = widget.lignes[etape.ligne];
    final avant = _faites[etape.ligne];
    final p = _propositions[etape.ligne];
    final cibles = widget.cibles[etape.ligne];
    setState(() {
      _k = k;
      _moment = _Moment.effort;
      _finRepos = null;
      _pret = false;
      if (cibles != null && etape.serie < cibles.length) {
        _reps = cibles[etape.serie];
      } else if (avant != null && avant.isNotEmpty) {
        _reps = avant.last.reps ?? _reps;
      } else {
        _reps = p?.reps ?? l.reps ?? 10;
      }
      final charge = (avant != null && avant.isNotEmpty)
          ? avant.last.charge
          : (p?.charge ?? l.charge);
      _chargeDemi = ((charge ?? 0) * 2).round();
      final minute = l.enDuree;
      final seul = widget.automatique || l.role != RoleLigne.travail;
      _debutEffort = minute && auto && seul ? _maintenant() : null;
      _dernierBip = -1;
      _coteChange = false;
    });
  }

  int get _secondesVisees => _secondesDe(_etapes[_k]);

  int _secondesDe(Etape etape) {
    final l = widget.lignes[etape.ligne];
    final cibles = widget.cibles[etape.ligne];
    if (cibles != null && etape.serie < cibles.length) {
      return cibles[etape.serie];
    }
    final p = _propositions[etape.ligne];
    return p?.secondes ?? l.secondes ?? 30;
  }

  void _tic() {
    if (!mounted || _moment == _Moment.fin) return;
    final now = _maintenant();
    if (_moment == _Moment.effort && _debutEffort != null) {
      final ecoule = now.difference(_debutEffort!).inMilliseconds / 1000;
      final reste = (_secondesVisees - ecoule).ceil();
      _bip(reste);
      // Un exercice « de chaque côté » : on change à mi-temps.
      if ((_exercice?.parCote ?? false) &&
          !_coteChange &&
          ecoule >= _secondesVisees / 2) {
        _coteChange = true;
        HapticFeedback.heavyImpact();
      }
      if (ecoule >= _secondesVisees) {
        _vibrerFin();
        _finirSerie();
        return;
      }
    } else if (_moment == _Moment.repos && _finRepos != null) {
      final reste = (_finRepos!.difference(now).inMilliseconds / 1000).ceil();
      _bip(reste);
      if (!now.isBefore(_finRepos!)) {
        _vibrerFin();
        _entrer(_suivante, auto: true);
        return;
      }
    }
    setState(() {});
  }

  /// 3, 2, 1 : un petit clic par seconde.
  void _bip(int reste) {
    if (reste <= 3 && reste >= 1 && reste != _dernierBip) {
      _dernierBip = reste;
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _vibrerFin() async {
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }
  }

  void _demarrer() {
    HapticFeedback.mediumImpact();
    setState(() => _debutEffort = _maintenant());
  }

  /// La série en cours est faite : on la note, on annonce un record, on
  /// part au repos.
  void _finirSerie() {
    final etape = _etapes[_k];
    final l = _ligne;
    final e = _exercice;
    final charge = (e?.charge ?? false) && _chargeDemi > 0
        ? _chargeDemi / 2
        : null;
    final SerieFaite serie;
    if (l.enDuree) {
      final debut = _debutEffort;
      final ecoule = debut == null
          ? _secondesVisees
          : _maintenant().difference(debut).inSeconds;
      serie = SerieFaite(
        secondes: math.min(math.max(ecoule, 1), _secondesVisees),
        charge: charge,
      );
    } else {
      serie = SerieFaite(reps: _reps, charge: charge);
    }
    (_faites[etape.ligne] ??= []).add(serie);
    if (l.role == RoleLigne.travail && e != null) _annoncerRecord(e, serie);
    HapticFeedback.mediumImpact();

    final j = suivante(_etapes, _k, _passees);
    if (j >= _etapes.length) {
      _terminer();
      return;
    }
    final repos = reposApres(_etapes, _k, widget.lignes);
    final suivanteLigne = widget.lignes[_etapes[j].ligne];
    final auto =
        suivanteLigne.enDuree &&
        (widget.automatique || suivanteLigne.role != RoleLigne.travail);
    // Avant un exercice minuté qui démarre seul : cinq secondes pour se
    // mettre en place.
    final attente = repos > 0 ? repos : (auto ? 5 : 0);
    if (attente == 0) {
      _entrer(j, auto: false);
      return;
    }
    setState(() {
      _moment = _Moment.repos;
      _suivante = j;
      _dureeRepos = attente;
      _finRepos = _maintenant().add(Duration(seconds: attente));
      _ligneRepos = l.role == RoleLigne.travail ? etape.ligne : null;
      _pret = widget.automatique || repos == 0 || l.role != RoleLigne.travail;
      _debutEffort = null;
      _dernierBip = -1;
    });
  }

  void _annoncerRecord(ExerciceSport e, SerieFaite s) {
    final avant = _recordsAvant[e.id];
    if (avant == null || avant.vide) return;
    final seance = _recordsSeance[e.id] ?? const Records();
    final tr = context.tr;
    final f = context.formats;
    String? message;
    final c = s.charge;
    if (c != null &&
        (s.reps ?? 0) > 0 &&
        c > (avant.charge ?? double.infinity) &&
        c > (seance.charge ?? 0) &&
        _annonces.add('${e.id}-c-$c')) {
      message = f.record(TypeRecord.charge, c, tr);
    } else if (s.reps != null &&
        s.reps! > (avant.reps ?? 1 << 30) &&
        s.reps! > (seance.reps ?? 0) &&
        _annonces.add('${e.id}-r-${s.reps}')) {
      message = f.record(TypeRecord.reps, s.reps!.toDouble(), tr);
    } else if (s.secondes != null &&
        s.secondes! > (avant.duree ?? 1 << 30) &&
        s.secondes! > (seance.duree ?? 0) &&
        _annonces.add('${e.id}-d-${s.secondes}')) {
      message = f.record(TypeRecord.duree, s.secondes!.toDouble(), tr);
    }
    _recordsSeance[e.id] = Records(
      charge: math.max(seance.charge ?? 0, c ?? 0),
      reps: math.max(seance.reps ?? 0, s.reps ?? 0),
      duree: math.max(seance.duree ?? 0, s.secondes ?? 0),
    );
    if (message != null) {
      HapticFeedback.heavyImpact();
      montrerToast(context, tr.toastRecord('${e.nom} · $message'));
    }
  }

  void _passerExercice() {
    HapticFeedback.selectionClick();
    _passees.add(_etapes[_k].ligne);
    _entrer(suivante(_etapes, _k, _passees), auto: false);
  }

  void _noterRessenti(Ressenti r) {
    final ligne = _ligneRepos;
    final series = ligne == null ? null : _faites[ligne];
    if (series == null || series.isEmpty) return;
    HapticFeedback.selectionClick();
    final d = series.last;
    setState(
      () => series[series.length - 1] = SerieFaite(
        reps: d.reps,
        secondes: d.secondes,
        charge: d.charge,
        ressenti: d.ressenti == r ? null : r,
      ),
    );
  }

  void _terminer() {
    _horloge?.cancel();
    setState(() {
      _moment = _Moment.fin;
      _fin = _maintenant();
      _confirmation = false;
    });
  }

  // ── L'enregistrement ─────────────────────────────────────────────────────

  SeanceFaite _seance(String id) {
    final etat = ref.read(sportProvider);
    final exercices = <ExerciceFait>[
      for (final (i, l) in widget.lignes.indexed)
        if (_faites[i] case final s? when s.isNotEmpty)
          ExerciceFait(
            exercice: l.exercice,
            series: s,
            role: l.role,
            cibleReps: l.reps,
          ),
    ];
    final fin = _fin ?? _maintenant();
    final duree = math.max(60, fin.difference(_debut).inSeconds);
    final faites = [
      for (final (i, l) in widget.lignes.indexed)
        if (_faites[i]?.isNotEmpty ?? false) l,
    ];
    return SeanceFaite(
      id: id,
      nom: widget.nom,
      debut: _debut,
      dureeSec: duree,
      style: widget.style ?? styleDominant(exercices),
      exercices: exercices,
      kcal: calories(metSeance(faites), etat.poidsCorps, duree),
      ressenti: _ressentiGlobal,
      note: _note.text.trim(),
      programmeId: widget.programmeId,
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

  // ── L'écran ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
              Positioned.fill(
                child: _moment == _Moment.fin ? _resume() : _enCours(),
              ),
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
    final ecoule = _maintenant().difference(_debut);
    final etape = _etapes[_k];
    final l = _ligne;
    final travail = [
      for (final (i, x) in widget.lignes.indexed)
        if (x.role == RoleLigne.travail) i,
    ];
    final avancee = _k / math.max(1, _etapes.length);

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
                    picto: Picto.croix,
                    libelle: tr.arreterSeance,
                    onTap: () => setState(() => _confirmation = true),
                  ),
                  Expanded(
                    child: Text(
                      widget.nom,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RhythmTypo.texte(15, poids: 600),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      f.chrono(ecoule),
                      textAlign: TextAlign.right,
                      style: RhythmTypo.texte(
                        14,
                        couleur: RhythmCouleurs.texte64,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Jauge(
              progression: avancee,
              couleur: RhythmCouleurs.corail,
              hauteur: 3,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  l.role.libelle(tr).toUpperCase(),
                  style: RhythmTypo.texte(
                    12,
                    poids: 600,
                    couleur: l.role == RoleLigne.travail
                        ? RhythmCouleurs.corail
                        : RhythmCouleurs.menthe,
                    espacement: 0.06,
                  ),
                ),
                const Spacer(),
                if (l.role == RoleLigne.travail && travail.isNotEmpty)
                  Text(
                    tr.exerciceSur(
                      travail.indexOf(etape.ligne) + 1,
                      travail.length,
                    ),
                    style: RhythmTypo.petit,
                  ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _moment == _Moment.repos
                    ? _vueRepos(key: const ValueKey('repos'))
                    : _vueEffort(key: ValueKey('effort-$_k')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vueEffort({Key? key}) {
    final tr = context.tr;
    final f = context.formats;
    final etape = _etapes[_k];
    final l = _ligne;
    final e = _exercice;
    if (e == null) return SizedBox(key: key);
    final p = _propositions[etape.ligne];
    final avant = l.role == RoleLigne.travail
        ? derniereFois(e.id, ref.read(sportProvider).journal)
        : null;
    final g = l.groupe;
    final paire = g == null
        ? null
        : widget.lignes.where((x) => x.groupe == g && x != l).firstOrNull;
    final minute = l.enDuree;
    final enCours = _debutEffort != null;

    return LayoutBuilder(
      key: key,
      builder: (context, c) {
        final figure = math.min(280.0, c.maxHeight * 0.36);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FigureDe(
                e,
                taille: c.maxWidth,
                hauteurMax: figure,
                cadree: true,
                animer: true,
              ),
            ),
            Text(
              e.nom,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: RhythmTypo.titre(24, hauteur: 1.15),
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (l.series > 1) tr.serieSur(etape.serie + 1, l.series),
                if (e.parCote)
                  minute && _coteChange ? tr.changeDeCote : tr.chaqueCote,
                if (paire != null)
                  '${tr.enchaine} · ${Catalogue.de(paire.exercice)?.nom ?? ''}',
              ].join(' · '),
              textAlign: TextAlign.center,
              style: RhythmTypo.texte(
                15,
                poids: 500,
                couleur: RhythmCouleurs.corail,
              ),
            ),
            if (p != null && l.role == RoleLigne.travail) ...[
              const SizedBox(height: 6),
              Text(
                avant == null
                    ? p.progres.libelle(tr)
                    : '${p.progres.libelle(tr)} · ${f.series(avant, tr)}',
                textAlign: TextAlign.center,
                style: RhythmTypo.texte(
                  13,
                  couleur:
                      p.progres == Progres.repDePlus ||
                          p.progres == Progres.plusDeCharge ||
                          p.progres == Progres.plusLong
                      ? RhythmCouleurs.menthe
                      : RhythmCouleurs.texte64,
                ),
              ),
            ],
            const Spacer(),
            if (minute)
              _Minute(
                reste: enCours
                    ? math.max(
                        0,
                        _secondesVisees -
                            _maintenant()
                                    .difference(_debutEffort!)
                                    .inMilliseconds /
                                1000,
                      )
                    : _secondesVisees.toDouble(),
                total: _secondesVisees,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _Reglage(
                      libelle: tr.repetitions,
                      compteur: CompteurRhythm(
                        valeur: _reps,
                        min: 0,
                        max: 100,
                        affichage: (v) => '$v',
                        largeurValeur: 48,
                        onChanged: (v) => setState(() => _reps = v),
                      ),
                    ),
                  ),
                  if (e.charge)
                    Expanded(
                      child: _Reglage(
                        libelle: tr.charge,
                        compteur: CompteurRhythm(
                          valeur: _chargeDemi,
                          min: 0,
                          max: 600,
                          pas: (pasDeCharge(e) * 2).round(),
                          affichage: (v) => v == 0 ? '—' : f.kg(v / 2, tr),
                          largeurValeur: 70,
                          onChanged: (v) => setState(() => _chargeDemi = v),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 18),
            BoutonPlein(
              libelle: minute
                  ? (enCours ? tr.cestFait : tr.demarrer)
                  : tr.serieFaite,
              largeurPleine: true,
              hauteur: 56,
              taillePolice: 16,
              onTap: minute && !enCours ? _demarrer : _finirSerie,
            ),
            Center(
              child: PressionEchelle(
                onTap: _passerExercice,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  child: Text(
                    tr.passerExercice,
                    style: RhythmTypo.texte(
                      14,
                      poids: 500,
                      couleur: RhythmCouleurs.texte64,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _vueRepos({Key? key}) {
    final tr = context.tr;
    final f = context.formats;
    final reste = _finRepos == null
        ? Duration.zero
        : _finRepos!.difference(_maintenant());
    final secondes = math.max(0, (reste.inMilliseconds / 1000).ceil());
    final etape = _etapes[_suivante];
    final l = widget.lignes[etape.ligne];
    final e = Catalogue.de(l.exercice);
    final derniere = _ligneRepos == null ? null : _faites[_ligneRepos!]?.last;
    final p = _propositions[etape.ligne];

    return LayoutBuilder(
      key: key,
      builder: (context, c) {
        final anneau = math.min(230.0, c.maxHeight * 0.4);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: AnneauMinuteur(
                taille: anneau,
                progression: _dureeRepos == 0
                    ? 0
                    : reste.inMilliseconds / (_dureeRepos * 1000),
                couleur: _pret ? RhythmCouleurs.menthe : RhythmCouleurs.ciel,
                centre: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.chrono(Duration(seconds: secondes)),
                      style: RhythmTypo.titre(anneau * 0.24),
                    ),
                    Text(
                      _pret ? tr.pret : tr.repos,
                      style: RhythmTypo.texte(
                        14,
                        couleur: RhythmCouleurs.texte64,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BoutonContour(
                  libelle: tr.plusQuinze,
                  onTap: () => setState(() {
                    _finRepos = _finRepos?.add(const Duration(seconds: 15));
                    _dureeRepos += 15;
                  }),
                ),
                const SizedBox(width: 12),
                BoutonContour(
                  libelle: tr.passer,
                  onTap: () => _entrer(_suivante, auto: true),
                ),
              ],
            ),
            if (derniere != null && !_pret) ...[
              const SizedBox(height: 22),
              Text(tr.commentCetait, style: RhythmTypo.detail),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in Ressenti.values)
                    Puce(
                      libelle: r.libelle(tr),
                      choisie: derniere.ressenti == r,
                      couleur: r == Ressenti.echec
                          ? RhythmCouleurs.corail
                          : RhythmCouleurs.blanc,
                      onTap: () => _noterRessenti(r),
                    ),
                ],
              ),
            ],
            const Spacer(),
            if (e != null) ...[
              Text(
                tr.aSuivre.toUpperCase(),
                style: RhythmTypo.texte(
                  12,
                  poids: 600,
                  couleur: RhythmCouleurs.texte64,
                  espacement: 0.06,
                ),
              ),
              LigneExercice(
                exercice: e,
                filet: false,
                detail: [
                  if (l.series > 1) tr.serieSur(etape.serie + 1, l.series),
                  if (l.enDuree)
                    f.secondes(_secondesDe(etape))
                  else
                    '${widget.cibles[etape.ligne]?.elementAtOrNull(etape.serie) ?? p?.reps ?? l.reps ?? 10} '
                        '${tr.repetitions.toLowerCase()}',
                ].join(' · '),
              ),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
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
                if (_moment != _Moment.fin && _faites.isNotEmpty) ...[
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
    final journal = ref.read(sportProvider).journal;
    final s = _seance('apercu');
    final records = recordsBattus(s, journal);
    return PageSecondaire(
      retour: widget.nom,
      onRetour: () => setState(() => _confirmation = true),
      enfants: [
        TitreSecondaire(
          titre: tr.seanceTerminee,
          surtitre: Text(widget.nom, style: RhythmTypo.surtitre),
        ),
        RangeeFilets(
          cases: [
            StatSport(
              libelle: tr.duree,
              valeur: f.dureeSeance(s.dureeSec),
              couleur: RhythmCouleurs.corail,
            ),
            if (s.volume > 0)
              StatSport(
                libelle: tr.volume,
                valeur: f.kg(s.volume.roundToDouble(), tr),
              )
            else
              StatSport(libelle: tr.seriesFaites, valeur: '${s.nombreSeries}'),
            StatSport(
              libelle: tr.calories,
              valeur: f.entier(s.kcal),
              couleur: RhythmCouleurs.peche,
            ),
          ],
        ),
        if (records.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.recordsBattus, couleur: RhythmCouleurs.menthe),
              for (final (i, r) in records.indexed) ...[
                if (i > 0) const Filet(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      const PictoRhythm(
                        Picto.trophee,
                        taille: 20,
                        couleur: RhythmCouleurs.menthe,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Catalogue.de(r.exercice)?.nom ?? '',
                              style: RhythmTypo.texte(15, poids: 500),
                            ),
                            Text(r.type.libelle(tr), style: RhythmTypo.petit),
                          ],
                        ),
                      ),
                      Text(
                        f.record(r.type, r.valeur, tr),
                        style: RhythmTypo.titre(
                          18,
                          couleur: RhythmCouleurs.menthe,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.ressentiGlobal),
            PucesChoix<int>(
              options: [for (var n = 1; n <= 5; n++) (n, libelleEffort(tr, n))],
              valeur: _ressentiGlobal,
              onChanged: (n) => setState(() => _ressentiGlobal = n),
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

class _Reglage extends StatelessWidget {
  const _Reglage({required this.libelle, required this.compteur});

  final String libelle;
  final Widget compteur;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(libelle, style: RhythmTypo.petit),
      const SizedBox(height: 6),
      compteur,
    ],
  );
}

/// Un exercice en durée : le temps qui reste, en grand, et sa jauge.
class _Minute extends StatelessWidget {
  const _Minute({required this.reste, required this.total});

  final double reste;
  final int total;

  @override
  Widget build(BuildContext context) {
    final f = context.formats;
    return Column(
      children: [
        Text(
          f.chrono(Duration(seconds: reste.ceil())),
          style: RhythmTypo.titre(52),
        ),
        const SizedBox(height: 8),
        Jauge(
          progression: total == 0 ? 0 : reste / total,
          couleur: RhythmCouleurs.menthe,
          hauteur: 5,
        ),
      ],
    );
  }
}

// lib/ecrans/sports/apercu_ecran.dart
//
// L'APERÇU d'une séance avant de la lancer (ou d'une séance enregistrée) :
// la durée estimée, les séries par muscle ; l'échauffement adapté aux
// articulations sollicitées, la séance rangée selon l'effort (les paires
// d'exercices enchaînés marquées A1 / A2), le retour au calme qui étire les
// muscles travaillés. TOUT SE RETOUCHE AU DOIGT : toucher une ligne ouvre
// ses réglages (séries, répétitions ou durée, charge, repos), la maintenir
// la déplace. L'échauffement et le retour au calme suivent les exercices.
//
// En bas : l'enregistrer comme séance (nom, jours prévus, heure, rappel) —
// elle devient alors la « Séance du jour » ces jours-là.

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
import '../../modele/sports/muscles.dart';
import '../../modele/sports/sport.dart';
import '../../navigation/transitions.dart';
import '../../systeme/synchro.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/jauges.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';
import 'banque_ecran.dart';
import 'exercice_ecran.dart';
import 'pieces_sports.dart';
import 'seance_guidee_ecran.dart';

class ApercuEcran extends ConsumerStatefulWidget {
  const ApercuEcran({
    super.key,
    required this.lignes,
    required this.objectif,
    required this.retour,
    this.programme,
    this.nomPropose = '',
  });

  final List<LigneSeance> lignes;
  final Objectif objectif;
  final String retour;

  /// La séance enregistrée qu'on regarde (sinon, une nouvelle).
  final Programme? programme;
  final String nomPropose;

  @override
  ConsumerState<ApercuEcran> createState() => _ApercuEcranState();
}

class _ApercuEcranState extends ConsumerState<ApercuEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ApercuEcran> {
  late List<LigneSeance> _travail = [
    for (final l in widget.lignes)
      if (l.role == RoleLigne.travail) l,
  ];
  int? _ouverte;
  late final TextEditingController _nom = TextEditingController(
    text: widget.programme?.nom ?? '',
  );
  final FocusNode _focusNom = FocusNode();
  late Set<int> _jours = {...?widget.programme?.jours};
  late int _heure = widget.programme?.heure ?? 18 * 60;
  late bool _rappel = widget.programme?.rappel ?? false;

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focusNom);
  }

  @override
  void dispose() {
    libererClavier();
    _nom.dispose();
    _focusNom.dispose();
    super.dispose();
  }

  List<LigneSeance> get _echauffement =>
      echauffement(_travail.map((l) => l.exercice));

  List<LigneSeance> get _calme => retourAuCalme(_travail);

  List<LigneSeance> get _toutes => [..._echauffement, ..._travail, ..._calme];

  /// Après un déplacement ou un retrait : une paire dont les deux lignes ne
  /// se suivent plus redevient deux exercices simples.
  void _reparerPaires() {
    for (var i = 0; i < _travail.length; i++) {
      final g = _travail[i].groupe;
      if (g == null) continue;
      final avec = [
        for (var k = 0; k < _travail.length; k++)
          if (_travail[k].groupe == g) k,
      ];
      if (avec.length == 2 && avec[1] == avec[0] + 1) continue;
      for (final k in avec) {
        final e = Catalogue.de(_travail[k].exercice);
        _travail[k] = _travail[k].copierAvec(
          groupe: () => null,
          repos: e == null ? 75 : doser(e, widget.objectif).repos,
        );
      }
    }
  }

  void _modifier(int i, LigneSeance l) => setState(() => _travail[i] = l);

  void _retirer(int i) => setState(() {
    _travail.removeAt(i);
    _ouverte = null;
    _reparerPaires();
  });

  Future<void> _ajouter() async {
    final tr = context.tr;
    final r = await pousserEcran<List<String>>(
      context,
      BanqueEcran(
        retour: tr.apercu,
        selection: [for (final l in _travail) l.exercice],
      ),
    );
    if (r == null || !mounted) return;
    final journal = ref.read(sportProvider).journal;
    setState(() {
      final gardes = [
        for (final l in _travail)
          if (r.contains(l.exercice)) l,
      ];
      final nouveaux = [
        for (final id in r)
          if (!gardes.any((l) => l.exercice == id))
            if (Catalogue.de(id) case final e?)
              doser(e, widget.objectif).copierAvec(
                charge: () {
                  final avant = derniereFois(id, journal);
                  return avant == null ? null : chargeDeTravail(avant);
                },
              ),
      ];
      _travail = [...gardes, ...organiser(nouveaux)];
      _reparerPaires();
    });
  }

  void _commencer() {
    pousserEcran(
      context,
      SeanceGuideeEcran(
        lignes: _toutes,
        nom: _nom.text.trim().isEmpty
            ? (widget.programme?.nom ?? widget.nomPropose)
            : _nom.text.trim(),
        programmeId: widget.programme?.id,
        objectif: widget.objectif,
      ),
    );
  }

  void _enregistrer() {
    final tr = context.tr;
    if (_travail.isEmpty) {
      montrerToast(context, tr.choisirUnExercice);
      return;
    }
    final notifier = ref.read(sportProvider.notifier);
    final nom = _nom.text.trim().isEmpty
        ? (widget.nomPropose.isEmpty ? tr.nouvelleSeance : widget.nomPropose)
        : _nom.text.trim();
    final p = Programme(
      id: widget.programme?.id ?? notifier.nouvelId('prog'),
      nom: nom,
      lignes: _toutes,
      objectif: widget.objectif,
      jours: _jours,
      heure: _jours.isEmpty ? null : _heure,
      rappel: _rappel && _jours.isNotEmpty,
      creeLe: widget.programme?.creeLe ?? jourDe(ref.read(aujourdhuiProvider)),
    );
    notifier.enregistrerProgramme(p);
    HapticFeedback.mediumImpact();
    montrerToast(context, tr.toastSeanceEnregistreeProgramme);
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final toutes = _toutes;
    final duree = dureeEstimee(toutes);
    final series = seriesParMuscle(_travail);
    final totalSeries = _travail.fold(0, (s, l) => s + l.series);
    final autorisation = ref.watch(autorisationNotifsProvider);

    // Les lettres des paires : A, B, C… dans l'ordre de la séance.
    final lettres = <int, String>{};
    for (final l in _travail) {
      final g = l.groupe;
      if (g != null && !lettres.containsKey(g)) {
        lettres[g] = String.fromCharCode(65 + lettres.length);
      }
    }

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: widget.programme?.nom ?? tr.apercu,
          surtitre: Text(
            '${widget.objectif.libelle(tr)} · ${widget.objectif.detail(tr)}',
            style: RhythmTypo.surtitre,
          ),
        ),
        RangeeFilets(
          cases: [
            StatSport(
              libelle: tr.dureeEstimee,
              valeur: tr.environMinutes((duree.inSeconds / 60).round()),
              couleur: RhythmCouleurs.corail,
            ),
            StatSport(libelle: tr.exercicesCourt, valeur: '${_travail.length}'),
            StatSport(libelle: tr.series, valeur: '$totalSeries'),
          ],
        ),
        BoutonPlein(
          libelle: tr.commencer,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 16,
          fleche: true,
          onTap: _commencer,
        ),
        if (series.isNotEmpty) _SeriesParMuscle(series: series),
        _Bloc(
          titre: tr.echauffement,
          detail: f.dureeSeance(dureeEstimee(_echauffement).inSeconds),
          lignes: _echauffement,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.roleSeance, couleur: RhythmCouleurs.corail),
            Text(tr.retouchesAide, style: RhythmTypo.petit),
            const SizedBox(height: 6),
            _ListeTravail(
              lignes: _travail,
              ouverte: _ouverte,
              lettres: lettres,
              objectif: widget.objectif,
              onOuvrir: (i) =>
                  setState(() => _ouverte = _ouverte == i ? null : i),
              onModifier: _modifier,
              onRetirer: _retirer,
              onReordonner: (ancien, nouveau) => setState(() {
                _travail.insert(nouveau, _travail.removeAt(ancien));
                _ouverte = null;
                _reparerPaires();
              }),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: BoutonCapsule(
                picto: Picto.plus,
                libelle: tr.ajouterUnExercice,
                onTap: _ajouter,
              ),
            ),
          ],
        ),
        _Bloc(
          titre: tr.retourAuCalme,
          detail: f.dureeSeance(dureeEstimee(_calme).inSeconds),
          lignes: _calme,
        ),
        // ── Enregistrer ──────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.enregistrerLaSeance),
            EtiquetteChamp(tr.champNom),
            ChampRhythm(
              controleur: _nom,
              focus: _focusNom,
              indice: widget.nomPropose.isEmpty
                  ? tr.indiceNomSeance
                  : widget.nomPropose,
              majuscules: TextCapitalization.sentences,
              actionClavier: TextInputAction.done,
            ),
            const SizedBox(height: 22),
            EtiquetteChamp(
              tr.joursPrevus,
              droite: Text(
                _jours.isEmpty ? tr.aLaDemande : f.joursPrevus(_jours, tr),
                style: RhythmTypo.petit,
              ),
            ),
            SelecteurJours(
              libelles: [for (var j = 1; j <= 7; j++) f.jourCourt(j)],
              jours: _jours,
              onChanged: (j) => setState(() => _jours = j),
            ),
            const SizedBox(height: 8),
            Text(tr.joursPrevusAide, style: RhythmTypo.petit),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _jours.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        EtiquetteChamp(tr.heure),
                        RouletteHeure(
                          minutes: _heure,
                          separateur: tr.separateurHeure,
                          onChanged: (m) => setState(() => _heure = m),
                        ),
                        LigneReglage(
                          libelle: tr.meLeRappeler,
                          droite: Interrupteur(
                            valeur: _rappel,
                            onChanged: (v) {
                              setState(() => _rappel = v);
                              if (v) assurerAutorisation(ref);
                            },
                          ),
                        ),
                        if (_rappel && autorisation == false)
                          Text(
                            tr.autorisationRefusee,
                            style: RhythmTypo.texte(
                              13,
                              couleur: RhythmCouleurs.corail,
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 22),
            BoutonPlein(
              libelle: tr.enregistrer,
              largeurPleine: true,
              hauteur: 50,
              taillePolice: 15,
              onTap: _enregistrer,
            ),
            if (widget.programme != null) ...[
              const SizedBox(height: 14),
              BoutonSuppression(
                libelle: tr.supprimerSeance,
                confirmation: tr.toucherPourSupprimer,
                onConfirme: () {
                  ref
                      .read(sportProvider.notifier)
                      .supprimerProgramme(widget.programme!.id);
                  retirerEcran(context);
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Les séries par muscle : une jauge par muscle, du plus travaillé au moins.
class _SeriesParMuscle extends StatelessWidget {
  const _SeriesParMuscle({required this.series});

  final Map<Muscle, double> series;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final tries = series.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = tries.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.seriesParMuscle),
        for (final e in tries.take(8))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    e.key.libelle(tr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RhythmTypo.texte(14),
                  ),
                ),
                Expanded(
                  child: Jauge(
                    progression: e.value / max,
                    couleur: RhythmCouleurs.corail,
                    hauteur: 5,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    f.decimal(e.value),
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
      ],
    );
  }
}

/// L'échauffement ou le retour au calme : des lignes simples, minutées.
class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.titre,
    required this.detail,
    required this.lignes,
  });

  final String titre;
  final String detail;
  final List<LigneSeance> lignes;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(titre, droite: Text(detail, style: RhythmTypo.petit)),
        for (final (i, l) in lignes.indexed)
          if (Catalogue.de(l.exercice) case final e?)
            LigneExercice(
              exercice: e,
              filet: i > 0,
              detail: e.parCote
                  ? tr.parCoteDuree(f.secondes((l.secondes ?? 40) ~/ 2))
                  : f.secondes(l.secondes ?? 40),
              onTap: () => pousserEcran(
                context,
                ExerciceEcran(id: e.id, retour: tr.apercu),
              ),
            ),
      ],
    );
  }
}

/// Les lignes de travail : touchées, elles s'ouvrent ; maintenues, elles se
/// déplacent.
class _ListeTravail extends StatelessWidget {
  const _ListeTravail({
    required this.lignes,
    required this.ouverte,
    required this.lettres,
    required this.objectif,
    required this.onOuvrir,
    required this.onModifier,
    required this.onRetirer,
    required this.onReordonner,
  });

  final List<LigneSeance> lignes;
  final int? ouverte;
  final Map<int, String> lettres;
  final Objectif objectif;
  final ValueChanged<int> onOuvrir;
  final void Function(int, LigneSeance) onModifier;
  final ValueChanged<int> onRetirer;
  final void Function(int, int) onReordonner;

  Widget _ligne(BuildContext context, int i) {
    final tr = context.tr;
    final f = context.formats;
    final l = lignes[i];
    final e = Catalogue.de(l.exercice);
    if (e == null) return const SizedBox.shrink();
    final g = l.groupe;
    final rang = g == null
        ? null
        : '${lettres[g]}${lignes.indexWhere((x) => x.groupe == g) == i ? 1 : 2} · ${tr.enchaine}';
    return Column(
      children: [
        LigneExercice(
          exercice: e,
          filet: i > 0,
          surtitre: rang,
          detail: '${f.dosage(l, tr)} · ${tr.reposDe(f.secondes(l.repos))}',
          onTap: () => onOuvrir(i),
          droite: AnimatedRotation(
            turns: ouverte == i ? 0.25 : 0,
            duration: const Duration(milliseconds: 180),
            child: const PictoRhythm(
              Picto.chevron,
              taille: 18,
              couleur: RhythmCouleurs.texte40,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: ouverte == i
              ? _Editeur(
                  ligne: l,
                  exercice: e,
                  onChanged: (n) => onModifier(i, n),
                  onRetirer: () => onRetirer(i),
                  onFiche: () => pousserEcran(
                    context,
                    ExerciceEcran(id: e.id, retour: tr.apercu),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (lignes.length < 2) {
      return Column(
        children: [for (var i = 0; i < lignes.length; i++) _ligne(context, i)],
      );
    }
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorderItem: (ancien, nouveau) {
        if (nouveau != ancien) onReordonner(ancien, nouveau);
      },
      proxyDecorator: (enfant, _, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, _) => Transform.scale(
          scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
          child: Material(
            type: MaterialType.transparency,
            child: ColoredBox(color: RhythmCouleurs.fond, child: enfant),
          ),
        ),
      ),
      children: [
        for (var i = 0; i < lignes.length; i++)
          ReorderableDelayedDragStartListener(
            key: ValueKey('${lignes[i].exercice}-$i'),
            index: i,
            child: _ligne(context, i),
          ),
      ],
    );
  }
}

/// Les réglages d'une ligne : séries, répétitions ou durée, charge, repos.
class _Editeur extends StatelessWidget {
  const _Editeur({
    required this.ligne,
    required this.exercice,
    required this.onChanged,
    required this.onRetirer,
    required this.onFiche,
  });

  final LigneSeance ligne;
  final ExerciceSport exercice;
  final ValueChanged<LigneSeance> onChanged;
  final VoidCallback onRetirer;
  final VoidCallback onFiche;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final l = ligne;
    final pas = (pasDeCharge(exercice) * 2).round();
    Widget reglage(String libelle, Widget compteur) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(libelle, style: RhythmTypo.texte(15))),
          compteur,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 68, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          reglage(
            tr.series,
            CompteurRhythm(
              valeur: l.series,
              min: 1,
              max: 10,
              affichage: (v) => '$v',
              largeurValeur: 56,
              onChanged: (v) => onChanged(l.copierAvec(series: v)),
            ),
          ),
          if (l.enDuree)
            reglage(
              tr.dureeSerie,
              CompteurRhythm(
                valeur: l.secondes!,
                min: 5,
                max: 600,
                pas: 5,
                affichage: f.secondes,
                largeurValeur: 72,
                onChanged: (v) => onChanged(l.copierAvec(secondes: () => v)),
              ),
            )
          else
            reglage(
              tr.repetitions,
              CompteurRhythm(
                valeur: l.reps ?? 10,
                min: 1,
                max: 60,
                affichage: (v) => '$v',
                largeurValeur: 56,
                onChanged: (v) => onChanged(l.copierAvec(reps: () => v)),
              ),
            ),
          if (exercice.charge)
            reglage(
              tr.charge,
              CompteurRhythm(
                valeur: ((l.charge ?? 0) * 2).round(),
                min: 0,
                max: 600,
                pas: pas,
                affichage: (v) => v == 0 ? '—' : f.kg(v / 2, tr),
                largeurValeur: 84,
                onChanged: (v) => onChanged(
                  l.copierAvec(charge: () => v == 0 ? null : v / 2),
                ),
              ),
            ),
          reglage(
            tr.repos,
            CompteurRhythm(
              valeur: l.repos,
              min: 0,
              max: 300,
              pas: 15,
              affichage: f.secondes,
              largeurValeur: 72,
              onChanged: (v) => onChanged(l.copierAvec(repos: v)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              PressionEchelle(
                onTap: onFiche,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    exercice.nom,
                    style: RhythmTypo.texte(
                      14,
                      poids: 500,
                      couleur: RhythmCouleurs.texte64,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PressionEchelle(
                onTap: onRetirer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Text(
                    tr.retirer,
                    style: RhythmTypo.texte(
                      14,
                      poids: 600,
                      couleur: RhythmCouleurs.corail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

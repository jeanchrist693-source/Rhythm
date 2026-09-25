// lib/ecrans/sports/plans_ecran.dart
//
// Ce qui se SUIT tel quel :
// - le FRACTIONNÉ : des plans prêts à lancer (8 × 1 min, Tabata…) ou le
//   sien (répétitions, effort, récupération), en course, marche ou vélo ;
// - les PROGRAMMES PROGRESSIFS (« Courir 30 minutes en 8 semaines ») : la
//   prochaine séance, l'avancée ;
// - les DÉFIS DE 4 SEMAINES : douze séances qui montent peu à peu, la
//   prochaine à lancer, les faites cochées.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/etat_sante.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/plans.dart';
import '../../modele/sports/sport.dart';
import '../../navigation/transitions.dart';
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
import 'cardio_ecran.dart';
import 'pieces_sports.dart';
import 'seance_guidee_ecran.dart';

/// « 8 répétitions · 26 min au total ».
String resumePlan(PlanIntervalles p, AppLocalizations tr) =>
    tr.intervallesResume(p.repetitions, (p.total / 60).round());

// ═══ Fractionné ═════════════════════════════════════════════════════════════

class FractionneEcran extends StatefulWidget {
  const FractionneEcran({super.key, required this.retour});

  final String retour;

  @override
  State<FractionneEcran> createState() => _FractionneEcranState();
}

class _FractionneEcranState extends State<FractionneEcran> {
  String _activite = 'course';
  int _repetitions = 8;
  int _effort = 60;
  int _recup = 60;
  int _echauffement = 300;
  int _retour = 300;

  void _lancer(PlanIntervalles p) => pousserEcran(
    context,
    CardioEcran(
      activite: _activite,
      retour: context.tr.activiteFractionne,
      plan: PlanIntervalles(nom: p.nom, etapes: p.etapes, activite: _activite),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final perso = PlanIntervalles.repete(
      nom: tr.monFractionne,
      repetitions: _repetitions,
      effort: _effort,
      recuperation: _recup,
      echauffement: _echauffement,
      retourCalme: _retour,
      activite: _activite,
    );
    Widget reglage(String libelle, Widget compteur) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(libelle, style: RhythmTypo.texte(15))),
          compteur,
        ],
      ),
    );
    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(titre: tr.activiteFractionne),
        Segments2<String>(
          options: [
            ('course', tr.activiteCourse),
            ('marche_rapide', tr.activiteMarche),
            ('velo', tr.activiteVelo),
          ],
          valeur: _activite,
          onChanged: (a) => setState(() => _activite = a),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.fractionnesPrets),
            for (final (i, p) in Fractionnes.tous.indexed) ...[
              if (i > 0) const Filet(),
              PressionEchelle(
                echelle: 0.98,
                onTap: () => _lancer(p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      const PictoCercle(Picto.eclair),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nom,
                              style: RhythmTypo.texte(15, poids: 600),
                            ),
                            const SizedBox(height: 2),
                            Text(resumePlan(p, tr), style: RhythmTypo.petit),
                          ],
                        ),
                      ),
                      const PictoRhythm(
                        Picto.lecture,
                        taille: 20,
                        couleur: RhythmCouleurs.corail,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.personnaliser),
            reglage(
              tr.repetitionsIntervalles,
              CompteurRhythm(
                valeur: _repetitions,
                min: 1,
                max: 30,
                affichage: (v) => '$v',
                largeurValeur: 56,
                onChanged: (v) => setState(() => _repetitions = v),
              ),
            ),
            reglage(
              tr.effortIntervalle,
              CompteurRhythm(
                valeur: _effort,
                min: 10,
                max: 1200,
                pas: 10,
                affichage: f.secondes,
                largeurValeur: 80,
                onChanged: (v) => setState(() => _effort = v),
              ),
            ),
            reglage(
              tr.recuperationIntervalle,
              CompteurRhythm(
                valeur: _recup,
                min: 0,
                max: 600,
                pas: 10,
                affichage: f.secondes,
                largeurValeur: 80,
                onChanged: (v) => setState(() => _recup = v),
              ),
            ),
            reglage(
              tr.echauffement,
              CompteurRhythm(
                valeur: _echauffement,
                min: 0,
                max: 1200,
                pas: 60,
                affichage: f.secondes,
                largeurValeur: 80,
                onChanged: (v) => setState(() => _echauffement = v),
              ),
            ),
            reglage(
              tr.retourAuCalme,
              CompteurRhythm(
                valeur: _retour,
                min: 0,
                max: 1200,
                pas: 60,
                affichage: f.secondes,
                largeurValeur: 80,
                onChanged: (v) => setState(() => _retour = v),
              ),
            ),
            const SizedBox(height: 8),
            Text(resumePlan(perso, tr), style: RhythmTypo.detail),
            const SizedBox(height: 14),
            BoutonPlein(
              libelle: tr.lancer,
              largeurPleine: true,
              hauteur: 50,
              taillePolice: 15,
              onTap: () => _lancer(perso),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══ Programmes progressifs ═════════════════════════════════════════════════

class ProgrammesCourseEcran extends ConsumerWidget {
  const ProgrammesCourseEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(sportProvider);
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: tr.programmesProgressifs),
        for (final p in ProgrammesCourse.tous)
          _BlocProgramme(
            programme: p,
            suivi: etat.course(p.id),
            f: f,
            onCommencer: () => ref
                .read(sportProvider.notifier)
                .commencerCourse(p.id, ref.read(aujourdhuiProvider)),
            onArreter: () =>
                ref.read(sportProvider.notifier).abandonnerCourse(p.id),
            onLancer: (i) => pousserEcran(
              context,
              CardioEcran(
                activite: p.activite,
                retour: tr.programmesProgressifs,
                plan: p.seances[i],
                programmeCourse: p.id,
                etape: i,
              ),
            ),
          ),
      ],
    );
  }
}

class _BlocProgramme extends StatelessWidget {
  const _BlocProgramme({
    required this.programme,
    required this.suivi,
    required this.f,
    required this.onCommencer,
    required this.onArreter,
    required this.onLancer,
  });

  final ProgrammeCourse programme;
  final Suivi? suivi;
  final Formats f;
  final VoidCallback onCommencer;
  final VoidCallback onArreter;
  final ValueChanged<int> onLancer;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final p = programme;
    final s = suivi;
    final faites = s?.faites.length ?? 0;
    final prochaine = s == null
        ? null
        : List.generate(
            p.seances.length,
            (i) => i,
          ).where((i) => !s.faites.contains(i)).firstOrNull;
    final e = Catalogue.de(p.activite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (e != null) FigureDe(e, taille: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nom, style: RhythmTypo.texte(17, poids: 600)),
                  const SizedBox(height: 2),
                  Text(
                    '${tr.nSemaines(p.semaines)} · ${tr.troisParSemaine}',
                    style: RhythmTypo.petit,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(p.resume, style: RhythmTypo.detail),
        const SizedBox(height: 12),
        if (s == null)
          Align(
            alignment: Alignment.centerLeft,
            child: BoutonCapsule(
              picto: Picto.lecture,
              libelle: tr.commencerProgramme,
              onTap: onCommencer,
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  tr.enCoursDepuis(f.dateCourte(s.debut)),
                  style: RhythmTypo.petit,
                ),
              ),
              Text(
                tr.etapesFaites(faites, p.seances.length),
                style: RhythmTypo.texte(13, couleur: RhythmCouleurs.corail),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Jauge(
            progression: faites / p.seances.length,
            couleur: RhythmCouleurs.corail,
            hauteur: 5,
          ),
          const SizedBox(height: 12),
          if (prochaine == null)
            Text(tr.programmeTermine, style: RhythmTypo.texte(15, poids: 600))
          else
            PressionEchelle(
              echelle: 0.98,
              onTap: () => onLancer(prochaine),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr.prochaineEtape, style: RhythmTypo.petit),
                        const SizedBox(height: 2),
                        Text(
                          '${tr.seanceNumero(prochaine + 1, p.seances.length)} · '
                          '${p.seances[prochaine].nom}',
                          style: RhythmTypo.texte(15, poids: 600),
                        ),
                        Text(
                          resumePlan(p.seances[prochaine], tr),
                          style: RhythmTypo.petit,
                        ),
                      ],
                    ),
                  ),
                  BoutonPlein(
                    libelle: tr.commencer,
                    onTap: () => onLancer(prochaine),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: BoutonSuppression(
              libelle: tr.arreterProgramme,
              confirmation: tr.toucherPourConfirmer,
              onConfirme: onArreter,
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Filet(),
      ],
    );
  }
}

// ═══ Défis ══════════════════════════════════════════════════════════════════

class DefisEcran extends ConsumerWidget {
  const DefisEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final etat = ref.watch(sportProvider);
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: tr.defisTitre),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, d) in Defis.tous.indexed)
              if (Catalogue.de(d.exercice) case final e?)
                LigneExercice(
                  exercice: e,
                  filet: i > 0,
                  titre: d.nom,
                  detail: etat.defi(d.id) == null
                      ? d.but
                      : tr.etapesFaites(
                          etat.defi(d.id)!.faites.length,
                          d.etapes,
                        ),
                  droite: etat.defi(d.id) == null
                      ? null
                      : Text(
                          tr.defiEnCours,
                          style: RhythmTypo.texte(
                            12,
                            poids: 600,
                            couleur: RhythmCouleurs.corail,
                          ),
                        ),
                  onTap: () => pousserEcran(
                    context,
                    DefiEcran(id: d.id, retour: tr.defisTitre),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class DefiEcran extends ConsumerWidget {
  const DefiEcran({super.key, required this.id, required this.retour});

  final String id;
  final String retour;

  void _lancer(BuildContext context, Defi d, int i) {
    final e = Catalogue.de(d.exercice)!;
    if (d.deCourse) {
      pousserEcran(
        context,
        CardioEcran(
          activite: d.exercice,
          retour: d.nom,
          plan: d.courses[i],
          defi: d.id,
          etape: i,
        ),
      );
      return;
    }
    final series = d.series[i];
    final ligne = LigneSeance(
      exercice: d.exercice,
      series: series.length,
      reps: e.enDuree ? null : series.fold<int>(0, math.max),
      secondes: e.enDuree ? series.fold<int>(0, math.max) : null,
      repos: 60,
    );
    pousserEcran(
      context,
      SeanceGuideeEcran(
        lignes: [
          LigneSeance(
            exercice: 'jumping_jack',
            series: 1,
            secondes: 60,
            repos: 10,
            role: RoleLigne.echauffement,
          ),
          ligne,
        ],
        cibles: {1: series},
        nom: d.nom,
        defi: d.id,
        etape: i,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final d = Defis.de(id);
    if (d == null) return PageSecondaire(retour: retour, enfants: const []);
    final e = Catalogue.de(d.exercice);
    final suivi = ref.watch(sportProvider.select((s) => s.defi(id)));
    final prochaine = suivi == null
        ? null
        : List.generate(
            d.etapes,
            (i) => i,
          ).where((i) => !suivi.faites.contains(i)).firstOrNull;
    return PageSecondaire(
      retour: retour,
      enfants: [
        if (e != null)
          Center(
            child: FigureDe(
              e,
              taille: 320,
              hauteurMax: 220,
              cadree: true,
              animer: true,
            ),
          ),
        TitreSecondaire(
          titre: d.nom,
          surtitre: Text(tr.defisTitre, style: RhythmTypo.surtitre),
        ),
        Text(d.but, style: RhythmTypo.texte(16)),
        if (suivi == null)
          BoutonPlein(
            libelle: tr.releverDefi,
            largeurPleine: true,
            hauteur: 50,
            taillePolice: 15,
            onTap: () => ref
                .read(sportProvider.notifier)
                .commencerDefi(d.id, ref.read(aujourdhuiProvider)),
          )
        else if (prochaine == null)
          Row(
            children: [
              const PictoRhythm(
                Picto.trophee,
                taille: 26,
                couleur: RhythmCouleurs.menthe,
              ),
              const SizedBox(width: 12),
              Text(
                tr.defiReleve,
                style: RhythmTypo.titre(22, couleur: RhythmCouleurs.menthe),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Jauge(
                progression: suivi.faites.length / d.etapes,
                couleur: RhythmCouleurs.corail,
                hauteur: 5,
              ),
              const SizedBox(height: 14),
              BoutonPlein(
                libelle:
                    '${tr.commencer} · ${tr.seanceNumero(prochaine + 1, d.etapes)}',
                largeurPleine: true,
                hauteur: 50,
                taillePolice: 15,
                onTap: () => _lancer(context, d, prochaine),
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < d.etapes; i++) ...[
              if (i > 0) const Filet(),
              _LigneEtape(
                numero: i + 1,
                total: d.etapes,
                detail: d.deCourse
                    ? resumePlan(d.courses[i], tr)
                    : _detailSeries(d.series[i], e?.enDuree ?? false, f, tr),
                date: suivi == null
                    ? null
                    : tr.prevueLe(
                        f.dateCourte(plusJours(suivi.debut, Defis.jourDe(i))),
                      ),
                faite: suivi?.faites.contains(i) ?? false,
                prochaine: i == prochaine,
                onTap: suivi == null ? null : () => _lancer(context, d, i),
              ),
            ],
          ],
        ),
        if (suivi != null)
          Align(
            alignment: Alignment.centerLeft,
            child: BoutonSuppression(
              libelle: tr.abandonnerDefi,
              confirmation: tr.toucherPourConfirmer,
              onConfirme: () =>
                  ref.read(sportProvider.notifier).abandonnerDefi(d.id),
            ),
          ),
      ],
    );
  }

  static String _detailSeries(
    List<int> series,
    bool enDuree,
    Formats f,
    AppLocalizations tr,
  ) {
    final liste = series.map((s) => enDuree ? f.secondes(s) : '$s').join(' · ');
    return enDuree ? liste : '$liste  (${tr.auTotal(Defis.total(series))})';
  }
}

class _LigneEtape extends StatelessWidget {
  const _LigneEtape({
    required this.numero,
    required this.total,
    required this.detail,
    required this.date,
    required this.faite,
    required this.prochaine,
    this.onTap,
  });

  final int numero;
  final int total;
  final String detail;
  final String? date;
  final bool faite;
  final bool prochaine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final ligne = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: faite ? RhythmCouleurs.menthe : null,
              border: faite
                  ? null
                  : Border.all(
                      color: prochaine
                          ? RhythmCouleurs.corail
                          : RhythmCouleurs.cocheVide,
                      width: 1.5,
                    ),
            ),
            child: faite
                ? const PictoRhythm(
                    Picto.coche,
                    taille: 16,
                    epaisseur: 2.6,
                    couleur: RhythmCouleurs.noir,
                  )
                : Text(
                    '$numero',
                    style: RhythmTypo.texte(
                      12,
                      poids: 600,
                      couleur: prochaine
                          ? RhythmCouleurs.corail
                          : RhythmCouleurs.texte64,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.seanceNumero(numero, total),
                  style: RhythmTypo.texte(15, poids: prochaine ? 600 : 500),
                ),
                const SizedBox(height: 2),
                Text(detail, style: RhythmTypo.petit),
                if (date != null && !faite)
                  Text(date!, style: RhythmTypo.petit),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return ligne;
    return PressionEchelle(onTap: onTap, echelle: 0.98, child: ligne);
  }
}

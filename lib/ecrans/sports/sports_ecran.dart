// lib/ecrans/sports/sports_ecran.dart
//
// Sports (maquette « Sports »), sans cartes (`filets.dart`). Le HAUT reste
// celui de la maquette, désormais VIVANT (le journal) : la semaine —
// minutes, objectif, sept barres du lundi au dimanche (aujourd'hui en
// blanc) —, trois statistiques (séances, calories, série de semaines).
// Puis :
// - la SÉANCE DU JOUR (une séance enregistrée prévue aujourd'hui) et
//   « Commencer » — sinon, la prochaine ;
// - « Créer une séance », la banque, les statistiques ;
// - les muscles EN RÉCUPÉRATION ;
// - COURSE, MARCHE, VÉLO, FRACTIONNÉ, et le programme progressif en cours ;
// - MES SÉANCES ; les DÉFIS ; les ROUTINES EXPRESS de 5 minutes ;
// - le JOURNAL (les trois dernières) ; les mesures ; matériel et objectifs.
// Le coureur court en haut à droite.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/etat_sante.dart';
import '../../modele/sports/calculs_sport.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/muscles.dart';
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
import '../../widgets/mascottes.dart';
import '../../widgets/page_rhythm.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import 'apercu_ecran.dart';
import 'banque_ecran.dart';
import 'cardio_ecran.dart';
import 'constructeur_ecran.dart';
import 'exercice_ecran.dart';
import 'journal_ecran.dart';
import 'mesures_ecran.dart';
import 'pieces_sports.dart';
import 'plans_ecran.dart';
import 'profil_sport_ecran.dart';
import 'seance_guidee_ecran.dart';
import 'stats_ecran.dart';

class SportsEcran extends ConsumerWidget {
  const SportsEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final aujourdhui = ref.watch(aujourdhuiProvider);
    final semaine = ref.watch(semaineSportProvider);
    final etat = ref.watch(sportProvider);
    final jour = seanceDuJour(etat.programmes, etat.journal, aujourdhui);
    final prochaine = jour == null
        ? prochaineSeance(etat.programmes, etat.journal, aujourdhui)
        : null;
    final recuperation = enRecuperation(etat.journal, aujourdhui);
    final retour = tr.navSports;

    return PageRhythm(
      blocs: [
        EnTete(
          surtitre: Surtitre(tr.semaineNumero(numeroSemaine(aujourdhui))),
          titre: tr.navSports,
          mascotte: Mascotte.sports,
        ),
        _Semaine(semaine: semaine, lundi: lundiDe(aujourdhui)),
        RangeeFilets(
          cases: [
            _Statistique(
              libelle: tr.seances,
              valeur: '${semaine.seances}',
              couleur: RhythmCouleurs.blanc,
            ),
            _Statistique(
              libelle: tr.calories,
              valeur: f.entier(semaine.calories),
              couleur: RhythmCouleurs.corail,
            ),
            _Statistique(
              libelle: tr.serie,
              valeur: tr.semainesCourt(semaine.serie),
              couleur: RhythmCouleurs.menthe,
            ),
          ],
        ),
        if (jour != null)
          _SeanceDuJour(
            programme: jour,
            faite: faitLe(jour, etat.journal, aujourdhui),
          )
        else
          _RienDePrevu(prochaine: prochaine),
        _Actions(retour: retour),
        if (recuperation.isNotEmpty)
          _Recuperation(recuperation: recuperation, maintenant: aujourdhui),
        _Cardio(etat: etat, retour: retour),
        _MesSeances(programmes: etat.programmes, retour: retour),
        _Defis(etat: etat, retour: retour),
        _Routines(retour: retour),
        _Journal(journal: etat.journal, retour: retour),
        _Reglages(etat: etat, retour: retour),
      ],
    );
  }
}

class _Semaine extends StatelessWidget {
  const _Semaine({required this.semaine, required this.lundi});

  final SemaineSport semaine;
  final DateTime lundi;

  /// Hauteur d'une barre à l'objectif du jour (la maquette : 60 min → 76).
  static const double _hauteurObjectif = 76;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    // Échelle : l'objectif du jour, ou le plus gros jour s'il le dépasse.
    final reference = math.max(
      semaine.objectifJour,
      semaine.minutes.fold(0, (m, j) => math.max(m, j ?? 0)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${semaine.total}', style: RhythmTypo.titre(40)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      tr.minCetteSemaine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RhythmTypo.texte(
                        14,
                        couleur: RhythmCouleurs.texte64,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tr.objectifSemaine(semaine.objectifSemaine),
              style: RhythmTypo.texte(13, couleur: RhythmCouleurs.corail),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _Barre(
                  minutes: semaine.minutes[i],
                  aujourdhui: i == semaine.aujourdhui,
                  hauteurMax: _hauteurObjectif,
                  reference: reference,
                  initiale: f.initialeJour(plusJours(lundi, i)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Une colonne du graphique : la barre (26 de large, coins 8) posée sur le
/// bas d'une colonne de 104, l'initiale du jour dessous.
class _Barre extends StatelessWidget {
  const _Barre({
    required this.minutes,
    required this.aujourdhui,
    required this.hauteurMax,
    required this.reference,
    required this.initiale,
  });

  /// `null` : jour à venir.
  final int? minutes;
  final bool aujourdhui;
  final double hauteurMax;
  final int reference;
  final String initiale;

  @override
  Widget build(BuildContext context) {
    final m = minutes ?? 0;
    final pleine = m > 0;
    return SizedBox(
      height: 104,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 26,
            height: pleine ? math.max(6, m / reference * hauteurMax) : 6,
            decoration: BoxDecoration(
              color: !pleine
                  ? RhythmCouleurs.piste
                  : aujourdhui
                  ? RhythmCouleurs.blanc
                  : RhythmCouleurs.corail,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            initiale,
            style: RhythmTypo.texte(
              12,
              poids: aujourdhui ? 600 : 400,
              couleur: aujourdhui
                  ? RhythmCouleurs.texte
                  : RhythmCouleurs.texte64,
            ),
          ),
        ],
      ),
    );
  }
}

class _Statistique extends StatelessWidget {
  const _Statistique({
    required this.libelle,
    required this.valeur,
    required this.couleur,
  });

  final String libelle;
  final String valeur;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(libelle, style: RhythmTypo.petit),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          valeur,
          maxLines: 1,
          style: RhythmTypo.titre(22, couleur: couleur),
        ),
      ),
    ],
  );
}

/// La séance du jour : son heure, son nom, « Commencer », ses exercices.
class _SeanceDuJour extends StatelessWidget {
  const _SeanceDuJour({required this.programme, required this.faite});

  final Programme programme;
  final bool faite;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final p = programme;
    final h = p.heure;
    final travail = p.travail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PressionEchelle(
                echelle: 0.98,
                onTap: () => pousserEcran(
                  context,
                  ApercuEcran(
                    lignes: p.lignes,
                    objectif: p.objectif,
                    programme: p,
                    retour: tr.navSports,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h == null
                          ? tr.seanceDuJourTitre
                          : tr.seanceDuJour(f.heureMinutes(h)),
                      style: RhythmTypo.petit,
                    ),
                    const SizedBox(height: 2),
                    Text(p.nom, style: RhythmTypo.titreCarte),
                    if (faite) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const PictoRhythm(
                            Picto.coche,
                            taille: 14,
                            epaisseur: 2.4,
                            couleur: RhythmCouleurs.menthe,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr.seanceFaiteAujourdhui,
                            style: RhythmTypo.texte(
                              12,
                              poids: 600,
                              couleur: RhythmCouleurs.menthe,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            BoutonPlein(
              libelle: tr.commencer,
              onTap: () => pousserEcran(
                context,
                SeanceGuideeEcran(
                  lignes: p.lignes,
                  nom: p.nom,
                  programmeId: p.id,
                  objectif: p.objectif,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final (i, l) in travail.take(6).indexed)
          if (Catalogue.de(l.exercice) case final e?)
            LigneExercice(
              exercice: e,
              detail: f.dosage(l, tr),
              filet: true,
              onTap: () => pousserEcran(
                context,
                ExerciceEcran(id: e.id, retour: tr.navSports),
              ),
              droite: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: RhythmCouleurs.corail, width: 1.5),
                ),
                child: Text(
                  '${i + 1}',
                  style: RhythmTypo.texte(12, couleur: RhythmCouleurs.corail),
                ),
              ),
            ),
      ],
    );
  }
}

class _RienDePrevu extends StatelessWidget {
  const _RienDePrevu({required this.prochaine});

  final (Programme, DateTime)? prochaine;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final p = prochaine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.seanceDuJourTitre, style: RhythmTypo.petit),
        const SizedBox(height: 2),
        Text(tr.rienDePrevu, style: RhythmTypo.titreCarte),
        if (p != null) ...[
          const SizedBox(height: 4),
          PressionEchelle(
            echelle: 0.98,
            onTap: () => pousserEcran(
              context,
              ApercuEcran(
                lignes: p.$1.lignes,
                objectif: p.$1.objectif,
                programme: p.$1,
                retour: tr.navSports,
              ),
            ),
            child: Text(
              tr.prochaineLe(
                p.$1.nom,
                '${f.jourCourt(p.$2.weekday)} '
                '${f.heure(p.$2.hour, p.$2.minute)}',
              ),
              style: RhythmTypo.texte(14, couleur: RhythmCouleurs.corail),
            ),
          ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoutonCapsule(
          picto: Picto.plus,
          libelle: tr.creerSeance,
          plein: true,
          onTap: () => pousserEcran(context, ConstructeurEcran(retour: retour)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BoutonCapsule(
                picto: Picto.recherche,
                libelle: tr.exercicesCourt,
                onTap: () => pousserEcran(context, BanqueEcran(retour: retour)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BoutonCapsule(
                picto: Picto.graphique,
                libelle: tr.statistiques,
                onTap: () => pousserEcran(context, StatsEcran(retour: retour)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Recuperation extends StatelessWidget {
  const _Recuperation({required this.recuperation, required this.maintenant});

  final Map<Muscle, DateTime> recuperation;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final fin = recuperation.values.reduce((a, b) => a.isAfter(b) ? a : b);
    final muscles = recuperation.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.enRecuperation, couleur: RhythmCouleurs.ciel),
        Text(
          '${_phrase(muscles.map((m) => m.libelle(tr)))} · '
          '${tr.encoreDuree(f.duree(fin.difference(maintenant)))}',
          style: RhythmTypo.texte(15, poids: 500),
        ),
        const SizedBox(height: 4),
        Text(tr.recuperationAide, style: RhythmTypo.petit),
      ],
    );
  }
}

class _Cardio extends StatelessWidget {
  const _Cardio({required this.etat, required this.retour});

  final EtatSport etat;
  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    Widget tuile(Picto picto, String libelle, VoidCallback onTap) => Semantics(
      button: true,
      child: PressionEchelle(
        onTap: onTap,
        child: Column(
          children: [
            PictoCercle(picto, taille: 48),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                libelle,
                maxLines: 1,
                style: RhythmTypo.texte(13, poids: 500),
              ),
            ),
          ],
        ),
      ),
    );
    void cardio(String activite) =>
        pousserEcran(context, CardioEcran(activite: activite, retour: retour));
    // Le programme de course en cours, s'il y en a un.
    Widget? enCours;
    for (final s in etat.courses) {
      final p = ProgrammesCourse.de(s.id);
      if (p == null) continue;
      final i = List.generate(
        p.seances.length,
        (i) => i,
      ).where((i) => !s.faites.contains(i)).firstOrNull;
      enCours = PressionEchelle(
        echelle: 0.98,
        onTap: () => pousserEcran(
          context,
          i == null
              ? ProgrammesCourseEcran(retour: retour)
              : CardioEcran(
                  activite: p.activite,
                  retour: retour,
                  plan: p.seances[i],
                  programmeCourse: p.id,
                  etape: i,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p.nom, style: RhythmTypo.texte(15, poids: 600)),
            const SizedBox(height: 2),
            Text(
              i == null
                  ? tr.programmeTermine
                  : '${tr.seanceNumero(i + 1, p.seances.length)} · '
                        '${p.seances[i].nom} · ${resumePlan(p.seances[i], tr)}',
              style: RhythmTypo.petit,
            ),
            const SizedBox(height: 8),
            Jauge(
              progression: s.faites.length / p.seances.length,
              couleur: RhythmCouleurs.corail,
              hauteur: 4,
            ),
          ],
        ),
      );
      break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.coursesTitre),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: tuile(
                Picto.chrono,
                tr.activiteCourse,
                () => cardio('course'),
              ),
            ),
            Expanded(
              child: tuile(
                Picto.traces,
                tr.activiteMarche,
                () => cardio('marche_rapide'),
              ),
            ),
            Expanded(
              child: tuile(Picto.velo, tr.activiteVelo, () => cardio('velo')),
            ),
            Expanded(
              child: tuile(
                Picto.eclair,
                tr.activiteFractionne,
                () => pousserEcran(context, FractionneEcran(retour: retour)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (enCours != null) ...[
          const Filet(),
          const SizedBox(height: 12),
          enCours,
        ],
        if (enCours == null)
          LigneReglage(
            libelle: tr.programmesProgressifs,
            detail: ProgrammesCourse.tous.first.nom,
            onTap: () =>
                pousserEcran(context, ProgrammesCourseEcran(retour: retour)),
          ),
      ],
    );
  }
}

class _MesSeances extends StatelessWidget {
  const _MesSeances({required this.programmes, required this.retour});

  final List<Programme> programmes;
  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.mesSeances),
        if (programmes.isEmpty)
          Text(tr.aucuneSeanceEnregistree, style: RhythmTypo.detail),
        for (final (i, p) in programmes.indexed) ...[
          if (i > 0) const Filet(),
          LigneReglage(
            libelle: p.nom,
            detail: [
              p.jours.isEmpty ? tr.aLaDemande : f.joursPrevus(p.jours, tr),
              if (p.heure != null && p.jours.isNotEmpty)
                f.heureMinutes(p.heure!),
              tr.resumeSeance(
                p.travail.length,
                (dureeEstimee(p.lignes).inSeconds / 60).round(),
              ),
            ].join(' · '),
            onTap: () => pousserEcran(
              context,
              ApercuEcran(
                lignes: p.lignes,
                objectif: p.objectif,
                programme: p,
                retour: retour,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Defis extends StatelessWidget {
  const _Defis({required this.etat, required this.retour});

  final EtatSport etat;
  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final enCours = [
      for (final s in etat.defis)
        if (Defis.de(s.id) case final d?) (d, s),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.defisTitre),
        for (final (d, s) in enCours) ...[
          PressionEchelle(
            echelle: 0.98,
            onTap: () =>
                pousserEcran(context, DefiEcran(id: d.id, retour: retour)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.nom,
                          style: RhythmTypo.texte(15, poids: 600),
                        ),
                      ),
                      Text(
                        s.faites.length >= d.etapes
                            ? tr.defiReleve
                            : tr.etapesFaites(s.faites.length, d.etapes),
                        style: RhythmTypo.texte(
                          13,
                          couleur: RhythmCouleurs.corail,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Jauge(
                    progression: s.faites.length / d.etapes,
                    couleur: RhythmCouleurs.corail,
                    hauteur: 4,
                  ),
                ],
              ),
            ),
          ),
          const Filet(),
        ],
        LigneReglage(
          libelle: tr.voirLesDefis,
          detail: Defis.tous.map((d) => d.nom).take(3).join(' · '),
          onTap: () => pousserEcran(context, DefisEcran(retour: retour)),
        ),
      ],
    );
  }
}

class _Routines extends StatelessWidget {
  const _Routines({required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.routinesExpress),
        for (final (i, r) in Routines.tous.indexed) ...[
          if (i > 0) const Filet(),
          LigneReglage(
            gauche: PictoCercle(switch (r.id) {
              'reveil' => Picto.eclair,
              'bureau' => Picto.corps,
              _ => Picto.vague,
            }, couleur: RhythmCouleurs.menthe),
            libelle: r.nom,
            detail: r.resume,
            valeur: tr.dureeMinutesCourt((r.total / 60).round()),
            onTap: () => pousserEcran(
              context,
              SeanceGuideeEcran(
                nom: r.nom,
                automatique: true,
                style: StyleSport.mobilite,
                lignes: [
                  for (final (id, s) in r.etapes)
                    LigneSeance(exercice: id, series: 1, secondes: s, repos: 5),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Journal extends StatelessWidget {
  const _Journal({required this.journal, required this.retour});

  final List<SeanceFaite> journal;
  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final recentes = journal.reversed.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.journalSport),
        if (recentes.isEmpty) Text(tr.journalVide, style: RhythmTypo.detail),
        for (final (i, s) in recentes.indexed)
          LigneSeanceFaite(
            seance: s,
            filet: i > 0,
            onTap: () => pousserEcran(
              context,
              SeanceFaiteEcran(id: s.id, retour: retour),
            ),
          ),
        if (journal.length > 3) ...[
          const Filet(),
          LigneReglage(
            libelle: tr.toutLeJournal,
            valeur: '${journal.length}',
            onTap: () => pousserEcran(context, JournalEcran(retour: retour)),
          ),
        ],
      ],
    );
  }
}

class _Reglages extends StatelessWidget {
  const _Reglages({required this.etat, required this.retour});

  final EtatSport etat;
  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final dernier = etat.mesures.lastOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Filet(),
        LigneReglage(
          gauche: const PictoCercle(
            Picto.balance,
            couleur: RhythmCouleurs.peche,
          ),
          libelle: tr.mesures,
          detail: dernier == null
              ? null
              : [
                  if (dernier.poids != null) f.kg(dernier.poids!, tr),
                  if (dernier.tourTaille != null) f.cm(dernier.tourTaille!, tr),
                ].join(' · '),
          onTap: () => pousserEcran(context, MesuresEcran(retour: retour)),
        ),
        const Filet(),
        LigneReglage(
          gauche: const PictoCercle(
            Picto.reglages,
            couleur: RhythmCouleurs.texte72,
          ),
          libelle: tr.materielEtObjectifs,
          detail: etat.profil.materiel.isEmpty
              ? tr.sansMateriel
              : etat.profil.materiel.map((m) => m.libelle(tr)).join(', '),
          onTap: () => pousserEcran(context, ProfilSportEcran(retour: retour)),
        ),
      ],
    );
  }
}

/// « Fessiers, quadriceps, ischios » : une énumération dans une phrase.
String _phrase(Iterable<String> mots) {
  final l = mots.toList();
  return [
    for (var i = 0; i < l.length; i++) i == 0 ? l[i] : l[i].toLowerCase(),
  ].join(', ');
}
